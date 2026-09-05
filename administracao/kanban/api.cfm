<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="45"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="includes/trello_service.cfm"/>

<cfscript>
function kanbanApiWrite(required struct payload, numeric statusCode = 200) {
    cfheader(name = "Cache-Control", value = "no-store, no-cache, must-revalidate, max-age=0");
    cfheader(name = "Pragma", value = "no-cache");
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function kanbanInput(required string key, numeric maxLength = 0, string defaultValue = "") {
    var value = structKeyExists(FORM, arguments.key) ? trim(FORM[arguments.key] & "") : arguments.defaultValue;
    if (arguments.maxLength GT 0) {
        value = left(value, arguments.maxLength);
    }
    return value;
}

function kanbanRequireMutation() {
    var requestMethod = structKeyExists(CGI, "request_method") ? uCase(trim(CGI.request_method & "")) : "GET";
    var postedToken = kanbanInput("csrf_token", 128);
    if (requestMethod NEQ "POST") {
        throw(type = "TrelloKanban.Method", message = "Esta operação exige POST.");
    }
    if (!structKeyExists(SESSION, "trelloKanbanCsrf") OR !len(trim(SESSION.trelloKanbanCsrf & ""))
        OR compare(postedToken, SESSION.trelloKanbanCsrf & "") NEQ 0) {
        throw(type = "TrelloKanban.Csrf", message = "A sessão de segurança expirou. Recarregue a página.");
    }
}

function kanbanSchemaReady() {
    var schemaStatus = queryExecute(
        "SELECT to_regclass('public.tb_trello_quadros') IS NOT NULL
                AND to_regclass('public.tb_trello_auditoria') IS NOT NULL AS ready",
        {},
        {datasource = "runner_dba"}
    );
    return schemaStatus.recordCount AND kanbanBoolean(schemaStatus.ready);
}

function kanbanMappedBoard(required string boardId) {
    return queryExecute(
        "SELECT id_trello_quadro, trello_board_id, departamento, nome_remoto, url, ordem
           FROM public.tb_trello_quadros
          WHERE trello_board_id = :boardId
            AND ativo = true
          LIMIT 1",
        {boardId = {value = kanbanTrelloId(arguments.boardId), cfsqltype = "cf_sql_varchar"}},
        {datasource = "runner_dba"}
    );
}

function kanbanRequireMappedBoard(required string boardId) {
    var board = kanbanMappedBoard(arguments.boardId);
    if (!board.recordCount) {
        throw(type = "TrelloKanban.ForbiddenBoard", message = "Este quadro não está autorizado no Business.");
    }
    return board;
}

function kanbanAssertListOnBoard(required string listId, required string boardId) {
    var normalizedListId = kanbanTrelloId(arguments.listId);
    var response = kanbanTrelloRequest("/lists/" & normalizedListId, "GET", {fields = "id,idBoard,name,closed"});
    if (!response.success) {
        throw(type = "TrelloKanban.Remote", message = response.message);
    }
    if (!isStruct(response.data) OR !structKeyExists(response.data, "idBoard")
        OR compareNoCase(response.data.idBoard & "", arguments.boardId) NEQ 0) {
        throw(type = "TrelloKanban.ForbiddenList", message = "A lista não pertence ao quadro autorizado.");
    }
    if (structKeyExists(response.data, "closed") AND kanbanBoolean(response.data.closed)) {
        throw(type = "TrelloKanban.Validation", message = "A lista selecionada está arquivada.");
    }
    return response.data;
}

function kanbanAssertCardOnBoard(required string cardId, required string boardId) {
    var normalizedCardId = kanbanTrelloId(arguments.cardId);
    var response = kanbanTrelloRequest("/cards/" & normalizedCardId, "GET", {fields = "id,idBoard,idList,name,closed"});
    if (!response.success) {
        throw(type = "TrelloKanban.Remote", message = response.message);
    }
    if (!isStruct(response.data) OR !structKeyExists(response.data, "idBoard")
        OR compareNoCase(response.data.idBoard & "", arguments.boardId) NEQ 0) {
        throw(type = "TrelloKanban.ForbiddenCard", message = "O cartão não pertence ao quadro autorizado.");
    }
    return response.data;
}

function kanbanMemberIds(string rawMemberIds = "") {
    var result = [];
    var memberId = "";
    for (memberId in listToArray(arguments.rawMemberIds)) {
        if (len(trim(memberId))) {
            arrayAppend(result, kanbanTrelloId(memberId));
        }
    }
    return arrayToList(result);
}

function kanbanDueValue(string dueValue = "") {
    var normalized = trim(arguments.dueValue & "");
    if (!len(normalized)) {
        return "null";
    }
    if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(?::[0-9]{2})?(?:\.[0-9]{1,3})?(?:Z|[+-][0-9]{2}:[0-9]{2})?$", normalized)) {
        throw(type = "TrelloKanban.Validation", message = "Prazo inválido.");
    }
    return normalized;
}

function kanbanDateValue(string rawValue = "", string fieldLabel = "Data") {
    var normalized = trim(arguments.rawValue & "");
    if (!len(normalized)) {
        return "null";
    }
    if (!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(?::[0-9]{2})?(?:\.[0-9]{1,3})?(?:Z|[+-][0-9]{2}:[0-9]{2})?$", normalized)) {
        throw(type = "TrelloKanban.Validation", message = arguments.fieldLabel & " inválida.");
    }
    return normalized;
}

function kanbanDueReminderValue(string rawValue = "") {
    var normalized = trim(arguments.rawValue & "");
    if (!len(normalized)) {
        return "-1";
    }
    if (!listFindNoCase("-1,0,5,10,15,60,120,1440,2880", normalized)) {
        throw(type = "TrelloKanban.Validation", message = "Lembrete do item inválido.");
    }
    return normalized;
}

function kanbanIdCsv(string rawIds = "") {
    var uniqueIds = {};
    var result = [];
    var candidate = "";
    var normalized = "";
    for (candidate in listToArray(arguments.rawIds)) {
        if (!len(trim(candidate))) {
            continue;
        }
        normalized = kanbanTrelloId(candidate);
        if (!structKeyExists(uniqueIds, normalized)) {
            uniqueIds[normalized] = true;
            arrayAppend(result, normalized);
        }
    }
    return arrayToList(result);
}

function kanbanAssertIdsOnBoard(required string boardId, required string resource, string rawIds = "") {
    var normalizedIds = kanbanIdCsv(arguments.rawIds);
    var allowedIds = {};
    var response = {};
    var item = {};
    var idValue = "";

    if (!len(normalizedIds)) {
        return "";
    }
    if (arguments.resource EQ "members") {
        response = kanbanTrelloRequest("/boards/" & arguments.boardId & "/members", "GET", {fields = "id"});
    } else if (arguments.resource EQ "labels") {
        response = kanbanTrelloRequest("/boards/" & arguments.boardId & "/labels", "GET", {fields = "id", limit = 1000});
    } else {
        throw(type = "TrelloKanban.Validation", message = "Recurso de quadro inválido.");
    }
    if (!response.success OR !isArray(response.data)) {
        throw(type = "TrelloKanban.Remote", message = response.message);
    }
    for (item in response.data) {
        if (isStruct(item) AND structKeyExists(item, "id")) {
            allowedIds[lCase(item.id & "")] = true;
        }
    }
    for (idValue in listToArray(normalizedIds)) {
        if (!structKeyExists(allowedIds, idValue)) {
            throw(type = "TrelloKanban.ForbiddenResource", message = "Há " & (arguments.resource EQ "members" ? "um responsável" : "uma etiqueta") & " que não pertence ao quadro.");
        }
    }
    return normalizedIds;
}

function kanbanAssertChecklistOnCard(required string checklistId, required string cardId, required string boardId) {
    var normalizedChecklistId = kanbanTrelloId(arguments.checklistId);
    var response = kanbanTrelloRequest("/checklists/" & normalizedChecklistId, "GET", {fields = "id,idBoard,idCard,name,pos"});
    if (!response.success) {
        throw(type = "TrelloKanban.Remote", message = response.message);
    }
    if (!isStruct(response.data)
        OR !structKeyExists(response.data, "idBoard")
        OR !structKeyExists(response.data, "idCard")
        OR compareNoCase(response.data.idBoard & "", arguments.boardId) NEQ 0
        OR compareNoCase(response.data.idCard & "", arguments.cardId) NEQ 0) {
        throw(type = "TrelloKanban.ForbiddenChecklist", message = "O checklist não pertence ao cartão autorizado.");
    }
    return response.data;
}

function kanbanAssertCommentOnCard(required string actionId, required string cardId) {
    var normalizedActionId = kanbanTrelloId(arguments.actionId);
    var response = kanbanTrelloRequest("/actions/" & normalizedActionId, "GET", {fields = "id,type,data"});
    var actionCardId = "";
    if (!response.success) {
        throw(type = "TrelloKanban.Remote", message = response.message);
    }
    if (isStruct(response.data)
        AND structKeyExists(response.data, "data")
        AND isStruct(response.data.data)
        AND structKeyExists(response.data.data, "card")
        AND isStruct(response.data.data.card)
        AND structKeyExists(response.data.data.card, "id")) {
        actionCardId = response.data.data.card.id & "";
    }
    if (!isStruct(response.data)
        OR !structKeyExists(response.data, "type")
        OR compareNoCase(response.data.type & "", "commentCard") NEQ 0
        OR compareNoCase(actionCardId, arguments.cardId) NEQ 0) {
        throw(type = "TrelloKanban.ForbiddenComment", message = "O comentário não pertence ao cartão autorizado.");
    }
    return response.data;
}

function kanbanAssertCustomFieldOnBoard(required string customFieldId, required string boardId) {
    var normalizedFieldId = kanbanTrelloId(arguments.customFieldId);
    var response = kanbanTrelloRequest("/customFields/" & normalizedFieldId, "GET", {});
    if (!response.success) {
        throw(type = "TrelloKanban.Remote", message = response.message);
    }
    if (!isStruct(response.data)
        OR !structKeyExists(response.data, "idModel")
        OR compareNoCase(response.data.idModel & "", arguments.boardId) NEQ 0) {
        throw(type = "TrelloKanban.ForbiddenCustomField", message = "O campo personalizado não pertence ao quadro autorizado.");
    }
    return response.data;
}

function kanbanCoordinates(string latitude = "", string longitude = "") {
    var lat = trim(arguments.latitude & "");
    var lng = trim(arguments.longitude & "");
    if (!len(lat) AND !len(lng)) {
        return "";
    }
    if (!isNumeric(lat) OR !isNumeric(lng) OR val(lat) LT -90 OR val(lat) GT 90 OR val(lng) LT -180 OR val(lng) GT 180) {
        throw(type = "TrelloKanban.Validation", message = "Latitude ou longitude inválida.");
    }
    return lat & "," & lng;
}

function kanbanAttachmentUrl(required string rawUrl) {
    var normalized = trim(arguments.rawUrl & "");
    if (len(normalized) GT 2000 OR !reFindNoCase("^https?://[^[:space:]]+$", normalized)) {
        throw(type = "TrelloKanban.Validation", message = "Informe uma URL HTTP ou HTTPS válida.");
    }
    return normalized;
}

if (!structKeyExists(SESSION, "trelloKanbanCsrf") OR !len(trim(SESSION.trelloKanbanCsrf & ""))) {
    SESSION.trelloKanbanCsrf = lCase(hash(createUUID() & now() & getTickCount() & rand(), "SHA-256"));
}

param name="URL.action" default="list_boards";
action = lCase(trim(URL.action & ""));

try {
    if (!kanbanSchemaReady()) {
        kanbanApiWrite({"success" = false, "schemaReady" = false, "message" = "Execute administracao/kanban/kanban_schema.sql antes de usar o módulo."}, 503);
    }

    if (action EQ "list_boards") {
        boardsQuery = queryExecute(
            "SELECT id_trello_quadro, trello_board_id, departamento, nome_remoto, url, ordem
               FROM public.tb_trello_quadros
              WHERE ativo = true
              ORDER BY ordem, lower(departamento), id_trello_quadro",
            {},
            {datasource = "runner_dba"}
        );
        boards = [];
        for (row in boardsQuery) {
            arrayAppend(boards, {
                "id" = row.trello_board_id & "",
                "mappingId" = val(row.id_trello_quadro),
                "department" = row.departamento & "",
                "name" = row.nome_remoto & "",
                "url" = row.url & "",
                "order" = val(row.ordem)
            });
        }
        kanbanApiWrite({"success" = true, "configured" = kanbanTrelloConfigured(), "boards" = boards});
    }

    if (!kanbanTrelloConfigured()) {
        kanbanApiWrite({"success" = false, "configured" = false, "message" = "Configure RR_TRELLO_API_KEY e RR_TRELLO_API_TOKEN no servidor."}, 503);
    }

    if (action EQ "available_boards") {
        remoteResponse = kanbanTrelloRequest("/members/me/boards", "GET", {
            filter = "open",
            fields = "id,name,url,shortUrl,dateLastActivity,closed"
        });
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        mappedQuery = queryExecute(
            "SELECT trello_board_id, departamento, ativo
               FROM public.tb_trello_quadros",
            {},
            {datasource = "runner_dba"}
        );
        mappedById = {};
        for (mappedRow in mappedQuery) {
            mappedById[lCase(mappedRow.trello_board_id & "")] = {
                "department" = mappedRow.departamento & "",
                "active" = kanbanBoolean(mappedRow.ativo)
            };
        }
        availableBoards = [];
        if (isArray(remoteResponse.data)) {
            for (remoteBoard in remoteResponse.data) {
                remoteId = structKeyExists(remoteBoard, "id") ? lCase(remoteBoard.id & "") : "";
                if (!reFind("^[0-9a-f]{24}$", remoteId)) {
                    continue;
                }
                mapping = structKeyExists(mappedById, remoteId) ? mappedById[remoteId] : {};
                arrayAppend(availableBoards, {
                    "id" = remoteId,
                    "name" = structKeyExists(remoteBoard, "name") ? remoteBoard.name & "" : remoteId,
                    "url" = structKeyExists(remoteBoard, "url") ? remoteBoard.url & "" : "",
                    "mapped" = structKeyExists(mapping, "active") AND mapping.active,
                    "department" = structKeyExists(mapping, "department") ? mapping.department : ""
                });
            }
        }
        kanbanApiWrite({"success" = true, "boards" = availableBoards});
    }

    if (action EQ "board") {
        boardId = kanbanTrelloId(structKeyExists(URL, "boardId") ? URL.boardId & "" : "");
        mappedBoard = kanbanRequireMappedBoard(boardId);
        boardResponse = kanbanTrelloRequest("/boards/" & boardId, "GET", {fields = "id,name,url,shortUrl,dateLastActivity,closed"});
        listsResponse = kanbanTrelloRequest("/boards/" & boardId & "/lists", "GET", {filter = "open", fields = "id,name,pos,closed"});
        cardsResponse = kanbanTrelloRequest("/boards/" & boardId & "/cards", "GET", {
            filter = "open",
            fields = "id,name,desc,idList,idMembers,idLabels,labels,start,due,dueReminder,dueComplete,pos,url,shortUrl,badges,dateLastActivity,closed,subscribed,address,locationName,coordinates,idAttachmentCover,cover"
        });
        membersResponse = kanbanTrelloRequest("/boards/" & boardId & "/members", "GET", {fields = "id,fullName,username,avatarUrl"});
        labelsResponse = kanbanTrelloRequest("/boards/" & boardId & "/labels", "GET", {fields = "id,name,color", limit = 1000});
        if (!boardResponse.success OR !listsResponse.success OR !cardsResponse.success) {
            remoteMessage = !boardResponse.success ? boardResponse.message : (!listsResponse.success ? listsResponse.message : cardsResponse.message);
            kanbanApiWrite({"success" = false, "message" = remoteMessage}, 424);
        }
        boardPayload = {
            "id" = boardId,
            "department" = mappedBoard.departamento & "",
            "name" = structKeyExists(boardResponse.data, "name") ? boardResponse.data.name & "" : mappedBoard.nome_remoto & "",
            "url" = structKeyExists(boardResponse.data, "url") ? boardResponse.data.url & "" : mappedBoard.url & "",
            "lists" = isArray(listsResponse.data) ? listsResponse.data : [],
            "cards" = isArray(cardsResponse.data) ? cardsResponse.data : [],
            "members" = membersResponse.success AND isArray(membersResponse.data) ? membersResponse.data : [],
            "labels" = labelsResponse.success AND isArray(labelsResponse.data) ? labelsResponse.data : []
        };
        kanbanApiWrite({"success" = true, "board" = boardPayload});
    }

    if (action EQ "card_details" OR action EQ "card_comments") {
        boardId = kanbanTrelloId(structKeyExists(URL, "boardId") ? URL.boardId & "" : "");
        cardId = kanbanTrelloId(structKeyExists(URL, "cardId") ? URL.cardId & "" : "");
        mappedBoard = kanbanRequireMappedBoard(boardId);
        kanbanAssertCardOnBoard(cardId, boardId);
        detailsResponse = kanbanTrelloRequest("/cards/" & cardId, "GET", {
            fields = "id,name,desc,idBoard,idList,idMembers,idLabels,labels,start,due,dueReminder,dueComplete,pos,url,shortUrl,badges,dateLastActivity,closed,subscribed,address,locationName,coordinates,idAttachmentCover,cover"
        });
        attachmentsResponse = kanbanTrelloRequest("/cards/" & cardId & "/attachments", "GET", {
            fields = "id,name,url,mimeType,bytes,date,isUpload,previews,pos"
        });
        checklistsResponse = kanbanTrelloRequest("/cards/" & cardId & "/checklists", "GET", {
            checkItems = "all",
            checkItem_fields = "name,state,pos,due,dueReminder,idMember",
            fields = "all"
        });
        actionsResponse = kanbanTrelloRequest("/cards/" & cardId & "/actions", "GET", {
            filter = "all",
            limit = 100,
            fields = "id,type,data,date,idMemberCreator",
            memberCreator = "true",
            memberCreator_fields = "id,fullName,username,avatarUrl"
        });
        customFieldsResponse = kanbanTrelloRequest("/boards/" & boardId & "/customFields", "GET", {});
        customItemsResponse = kanbanTrelloRequest("/cards/" & cardId & "/customFieldItems", "GET", {});
        if (!detailsResponse.success) {
            kanbanApiWrite({"success" = false, "message" = detailsResponse.message}, 424);
        }
        if (action EQ "card_comments") {
            comments = [];
            if (actionsResponse.success AND isArray(actionsResponse.data)) {
                for (commentAction in actionsResponse.data) {
                    if (isStruct(commentAction) AND structKeyExists(commentAction, "type") AND compareNoCase(commentAction.type & "", "commentCard") EQ 0) {
                        arrayAppend(comments, commentAction);
                    }
                }
            }
            kanbanApiWrite({"success" = true, "comments" = comments});
        }
        kanbanApiWrite({
            "success" = true,
            "card" = detailsResponse.data,
            "attachments" = attachmentsResponse.success AND isArray(attachmentsResponse.data) ? attachmentsResponse.data : [],
            "checklists" = checklistsResponse.success AND isArray(checklistsResponse.data) ? checklistsResponse.data : [],
            "actions" = actionsResponse.success AND isArray(actionsResponse.data) ? actionsResponse.data : [],
            "customFields" = customFieldsResponse.success AND isArray(customFieldsResponse.data) ? customFieldsResponse.data : [],
            "customFieldItems" = customItemsResponse.success AND isArray(customItemsResponse.data) ? customItemsResponse.data : [],
            "capabilities" = {
                "attachments" = attachmentsResponse.success,
                "checklists" = checklistsResponse.success,
                "activity" = actionsResponse.success,
                "customFields" = customFieldsResponse.success AND customItemsResponse.success
            }
        });
    }

    if (action EQ "archived_cards") {
        boardId = kanbanTrelloId(structKeyExists(URL, "boardId") ? URL.boardId & "" : "");
        mappedBoard = kanbanRequireMappedBoard(boardId);
        archivedResponse = kanbanTrelloRequest("/boards/" & boardId & "/cards", "GET", {
            filter = "closed",
            fields = "id,name,idList,url,shortUrl,dateLastActivity,closed"
        });
        if (!archivedResponse.success) {
            kanbanApiWrite({"success" = false, "message" = archivedResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "cards" = isArray(archivedResponse.data) ? archivedResponse.data : []});
    }

    if (action EQ "board_lists") {
        boardId = kanbanTrelloId(structKeyExists(URL, "boardId") ? URL.boardId & "" : "");
        mappedBoard = kanbanRequireMappedBoard(boardId);
        boardListsResponse = kanbanTrelloRequest("/boards/" & boardId & "/lists", "GET", {filter = "open", fields = "id,name,pos,closed"});
        if (!boardListsResponse.success) {
            kanbanApiWrite({"success" = false, "message" = boardListsResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "lists" = isArray(boardListsResponse.data) ? boardListsResponse.data : []});
    }

    if (action EQ "save_board") {
        kanbanRequireMutation();
        boardId = kanbanTrelloId(kanbanInput("board_id", 32));
        department = kanbanInput("department", 100);
        orderValue = max(0, min(9999, val(kanbanInput("order", 5, "100"))));
        if (len(department) LT 2) {
            throw(type = "TrelloKanban.Validation", message = "Informe o departamento do quadro.");
        }
        remoteResponse = kanbanTrelloRequest("/boards/" & boardId, "GET", {fields = "id,name,url,closed"});
        if (!remoteResponse.success OR !isStruct(remoteResponse.data)) {
            kanbanAudit("save_board", false, boardId, "", 0, remoteResponse.status, {"department" = department}, remoteResponse.message);
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        if (structKeyExists(remoteResponse.data, "closed") AND kanbanBoolean(remoteResponse.data.closed)) {
            throw(type = "TrelloKanban.Validation", message = "Não é possível mapear um quadro arquivado.");
        }
        transaction {
            queryExecute(
                "UPDATE public.tb_trello_quadros
                    SET ativo = false,
                        id_usuario_alteracao = :actorId,
                        data_atualizacao = now()
                  WHERE lower(btrim(departamento)) = lower(btrim(:department))
                    AND trello_board_id <> :boardId
                    AND ativo = true",
                {
                    actorId = {value = val(qPerfil.id), cfsqltype = "cf_sql_integer"},
                    department = {value = department, cfsqltype = "cf_sql_varchar"},
                    boardId = {value = boardId, cfsqltype = "cf_sql_varchar"}
                },
                {datasource = "runner_dba"}
            );
            queryExecute(
                "INSERT INTO public.tb_trello_quadros
                    (trello_board_id, departamento, nome_remoto, url, ativo, ordem, id_usuario_criacao, id_usuario_alteracao)
                 VALUES
                    (:boardId, :department, :remoteName, :remoteUrl, true, :orderValue, :actorId, :actorId)
                 ON CONFLICT (trello_board_id) DO UPDATE
                    SET departamento = EXCLUDED.departamento,
                        nome_remoto = EXCLUDED.nome_remoto,
                        url = EXCLUDED.url,
                        ativo = true,
                        ordem = EXCLUDED.ordem,
                        id_usuario_alteracao = EXCLUDED.id_usuario_alteracao,
                        data_atualizacao = now()",
                {
                    boardId = {value = boardId, cfsqltype = "cf_sql_varchar"},
                    department = {value = department, cfsqltype = "cf_sql_varchar"},
                    remoteName = {value = left(remoteResponse.data.name & "", 255), cfsqltype = "cf_sql_varchar"},
                    remoteUrl = {value = left(remoteResponse.data.url & "", 500), cfsqltype = "cf_sql_varchar"},
                    orderValue = {value = orderValue, cfsqltype = "cf_sql_integer"},
                    actorId = {value = val(qPerfil.id), cfsqltype = "cf_sql_integer"}
                },
                {datasource = "runner_dba"}
            );
        }
        mappedBoard = kanbanMappedBoard(boardId);
        kanbanAudit("save_board", true, boardId, "", mappedBoard.id_trello_quadro, remoteResponse.status, {"department" = department, "order" = orderValue});
        kanbanApiWrite({"success" = true, "message" = "Quadro vinculado ao departamento."});
    }

    if (action EQ "remove_board") {
        kanbanRequireMutation();
        boardId = kanbanTrelloId(kanbanInput("board_id", 32));
        mappedBoard = kanbanRequireMappedBoard(boardId);
        queryExecute(
            "UPDATE public.tb_trello_quadros
                SET ativo = false,
                    id_usuario_alteracao = :actorId,
                    data_atualizacao = now()
              WHERE id_trello_quadro = :mappedBoardId",
            {
                actorId = {value = val(qPerfil.id), cfsqltype = "cf_sql_integer"},
                mappedBoardId = {value = mappedBoard.id_trello_quadro, cfsqltype = "cf_sql_bigint"}
            },
            {datasource = "runner_dba"}
        );
        kanbanAudit("remove_board", true, boardId, "", mappedBoard.id_trello_quadro, 200, {"department" = mappedBoard.departamento & ""});
        kanbanApiWrite({"success" = true, "message" = "Quadro removido do painel. Ele não foi arquivado no Trello."});
    }

    boardId = kanbanTrelloId(kanbanInput("board_id", 32));
    mappedBoard = kanbanRequireMappedBoard(boardId);
    mappedBoardId = val(mappedBoard.id_trello_quadro);
    kanbanRequireMutation();

    if (action EQ "create_card") {
        listId = kanbanTrelloId(kanbanInput("list_id", 32));
        kanbanAssertListOnBoard(listId, boardId);
        cardName = kanbanInput("name", 512);
        if (!len(cardName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o título do cartão.");
        }
        params = {
            idList = listId,
            name = cardName,
            desc = kanbanInput("desc", 10000),
            pos = "bottom",
            dueComplete = kanbanBoolean(kanbanInput("due_complete", 8)) ? "true" : "false"
        };
        dueValue = kanbanDueValue(kanbanInput("due", 64));
        if (dueValue NEQ "null") {
            params.due = dueValue;
        }
        startValue = kanbanDateValue(kanbanInput("start", 64), "Data inicial");
        if (startValue NEQ "null") {
            params.start = startValue;
        }
        memberIds = kanbanAssertIdsOnBoard(boardId, "members", kanbanInput("member_ids", 1000));
        if (len(memberIds)) {
            params.idMembers = memberIds;
        }
        labelIds = kanbanAssertIdsOnBoard(boardId, "labels", kanbanInput("label_ids", 1000));
        if (len(labelIds)) {
            params.idLabels = labelIds;
        }
        secondaryParams = {
            subscribed = kanbanBoolean(kanbanInput("subscribed", 8)) ? "true" : "false"
        };
        addressValue = kanbanInput("address", 512);
        locationNameValue = kanbanInput("location_name", 256);
        coordinatesValue = kanbanCoordinates(kanbanInput("latitude", 32), kanbanInput("longitude", 32));
        if (len(addressValue)) {
            secondaryParams.address = addressValue;
        }
        if (len(locationNameValue)) {
            secondaryParams.locationName = locationNameValue;
        }
        if (len(coordinatesValue)) {
            secondaryParams.coordinates = coordinatesValue;
        }
        coverColor = lCase(kanbanInput("cover_color", 16, "none"));
        if (!listFindNoCase("none,yellow,orange,red,purple,blue,sky,lime,pink,black,green", coverColor)) {
            throw(type = "TrelloKanban.Validation", message = "Cor de capa inválida.");
        }
        secondaryParams.cover = coverColor EQ "none"
            ? '{"color":null,"idAttachment":null}'
            : '{"color":"' & coverColor & '","size":"normal","brightness":"dark"}';
        remoteResponse = kanbanTrelloRequest("/cards", "POST", params);
        cardId = remoteResponse.success AND isStruct(remoteResponse.data) AND structKeyExists(remoteResponse.data, "id") ? remoteResponse.data.id & "" : "";
        kanbanAudit("create_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"listId" = listId, "name" = cardName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        secondaryResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", secondaryParams);
        kanbanAudit("initialize_card_details", secondaryResponse.success, boardId, cardId, mappedBoardId, secondaryResponse.status, {}, secondaryResponse.message);
        kanbanApiWrite({
            "success" = true,
            "message" = secondaryResponse.success ? "Cartão criado." : "Cartão criado; alguns detalhes opcionais não foram aplicados.",
            "card" = secondaryResponse.success ? secondaryResponse.data : remoteResponse.data,
            "partial" = !secondaryResponse.success
        });
    }

    if (action EQ "update_card") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        listId = kanbanTrelloId(kanbanInput("list_id", 32));
        kanbanAssertListOnBoard(listId, boardId);
        cardName = kanbanInput("name", 512);
        if (!len(cardName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o título do cartão.");
        }
        params = {
            name = cardName,
            desc = kanbanInput("desc", 10000),
            idList = listId,
            due = kanbanDueValue(kanbanInput("due", 64)),
            start = kanbanDateValue(kanbanInput("start", 64), "Data inicial"),
            dueComplete = kanbanBoolean(kanbanInput("due_complete", 8)) ? "true" : "false",
            idMembers = kanbanAssertIdsOnBoard(boardId, "members", kanbanInput("member_ids", 1000)),
            idLabels = kanbanAssertIdsOnBoard(boardId, "labels", kanbanInput("label_ids", 1000)),
            subscribed = kanbanBoolean(kanbanInput("subscribed", 8)) ? "true" : "false"
        };
        addressValue = kanbanInput("address", 512);
        locationNameValue = kanbanInput("location_name", 256);
        coordinatesValue = kanbanCoordinates(kanbanInput("latitude", 32), kanbanInput("longitude", 32));
        if (len(addressValue)) {
            params.address = addressValue;
        }
        if (len(locationNameValue)) {
            params.locationName = locationNameValue;
        }
        if (len(coordinatesValue)) {
            params.coordinates = coordinatesValue;
        }
        coverColor = lCase(kanbanInput("cover_color", 16));
        if (!listFindNoCase("none,attachment,yellow,orange,red,purple,blue,sky,lime,pink,black,green", coverColor)) {
            throw(type = "TrelloKanban.Validation", message = "Cor de capa inválida.");
        }
        if (coverColor EQ "none") {
            params.cover = '{"color":null,"idAttachment":null}';
        } else if (coverColor NEQ "attachment") {
            params.cover = '{"color":"' & coverColor & '","size":"normal","brightness":"dark"}';
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", params);
        kanbanAudit("update_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"listId" = listId, "name" = cardName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão atualizado.", "card" = remoteResponse.data});
    }

    if (action EQ "move_card") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        card = kanbanAssertCardOnBoard(cardId, boardId);
        listId = kanbanTrelloId(kanbanInput("list_id", 32));
        kanbanAssertListOnBoard(listId, boardId);
        position = lCase(kanbanInput("position", 32, "bottom"));
        if (!listFindNoCase("top,bottom", position) AND !isNumeric(position)) {
            position = "bottom";
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", {idList = listId, pos = position});
        kanbanAudit("move_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"fromListId" = card.idList & "", "toListId" = listId, "position" = position}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão movido."});
    }

    if (action EQ "archive_card") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        shouldArchive = kanbanBoolean(kanbanInput("archived", 8, "true"));
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", {closed = shouldArchive ? "true" : "false"});
        kanbanAudit(shouldArchive ? "archive_card" : "restore_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = shouldArchive ? "Cartão arquivado." : "Cartão restaurado."});
    }

    if (action EQ "delete_card") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        card = kanbanAssertCardOnBoard(cardId, boardId);
        if (compare(kanbanInput("confirmation", 32), "EXCLUIR") NEQ 0) {
            throw(type = "TrelloKanban.Validation", message = "Digite EXCLUIR para apagar permanentemente o cartão.");
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "DELETE", {});
        kanbanAudit("delete_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"name" = left(card.name & "", 512)}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão excluído permanentemente."});
    }

    if (action EQ "duplicate_card") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        sourceCard = kanbanAssertCardOnBoard(cardId, boardId);
        listId = kanbanTrelloId(kanbanInput("list_id", 32));
        kanbanAssertListOnBoard(listId, boardId);
        duplicateName = kanbanInput("name", 512, "Cópia de " & (sourceCard.name & ""));
        if (!len(duplicateName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o título da cópia.");
        }
        remoteResponse = kanbanTrelloRequest("/cards", "POST", {
            idList = listId,
            idCardSource = cardId,
            keepFromSource = "all",
            name = duplicateName,
            pos = "bottom"
        });
        newCardId = remoteResponse.success AND isStruct(remoteResponse.data) AND structKeyExists(remoteResponse.data, "id") ? remoteResponse.data.id & "" : "";
        kanbanAudit("duplicate_card", remoteResponse.success, boardId, newCardId, mappedBoardId, remoteResponse.status, {"sourceCardId" = cardId, "listId" = listId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão duplicado.", "card" = remoteResponse.data});
    }

    if (action EQ "transfer_card") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        sourceCard = kanbanAssertCardOnBoard(cardId, boardId);
        targetBoardId = kanbanTrelloId(kanbanInput("target_board_id", 32));
        targetBoard = kanbanRequireMappedBoard(targetBoardId);
        targetListId = kanbanTrelloId(kanbanInput("target_list_id", 32));
        kanbanAssertListOnBoard(targetListId, targetBoardId);
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", {
            idBoard = targetBoardId,
            idList = targetListId,
            pos = "bottom"
        });
        kanbanAudit("transfer_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {
            "sourceListId" = sourceCard.idList & "",
            "targetBoardId" = targetBoardId,
            "targetMappedBoardId" = val(targetBoard.id_trello_quadro),
            "targetListId" = targetListId
        }, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão movido para outro departamento."});
    }

    if (action EQ "create_label") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        labelName = kanbanInput("name", 128);
        labelColor = lCase(kanbanInput("color", 16));
        if (!len(labelName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o nome da etiqueta.");
        }
        if (!listFindNoCase("yellow,purple,blue,red,green,orange,black,sky,pink,lime", labelColor)) {
            throw(type = "TrelloKanban.Validation", message = "Cor de etiqueta inválida.");
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/labels", "POST", {name = labelName, color = labelColor});
        kanbanAudit("create_label", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"name" = labelName, "color" = labelColor}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Etiqueta criada e aplicada.", "label" = remoteResponse.data});
    }

    if (action EQ "create_checklist") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        checklistName = kanbanInput("name", 256);
        if (!len(checklistName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o nome do checklist.");
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/checklists", "POST", {name = checklistName, pos = "bottom"});
        kanbanAudit("create_checklist", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"name" = checklistName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Checklist criado."});
    }

    if (action EQ "update_checklist") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        checklistId = kanbanTrelloId(kanbanInput("checklist_id", 32));
        kanbanAssertChecklistOnCard(checklistId, cardId, boardId);
        checklistName = kanbanInput("name", 256);
        if (!len(checklistName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o nome do checklist.");
        }
        remoteResponse = kanbanTrelloRequest("/checklists/" & checklistId, "PUT", {name = checklistName});
        kanbanAudit("update_checklist", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"checklistId" = checklistId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Checklist renomeado."});
    }

    if (action EQ "delete_checklist") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        checklistId = kanbanTrelloId(kanbanInput("checklist_id", 32));
        kanbanAssertChecklistOnCard(checklistId, cardId, boardId);
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/checklists/" & checklistId, "DELETE", {});
        kanbanAudit("delete_checklist", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"checklistId" = checklistId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Checklist removido."});
    }

    if (action EQ "add_check_item") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        checklistId = kanbanTrelloId(kanbanInput("checklist_id", 32));
        kanbanAssertChecklistOnCard(checklistId, cardId, boardId);
        itemName = kanbanInput("name", 512);
        if (!len(itemName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o texto do item.");
        }
        itemParams = {name = itemName, pos = "bottom", checked = "false"};
        itemDue = kanbanDateValue(kanbanInput("due", 64), "Prazo do item");
        if (itemDue NEQ "null") {
            itemParams.due = itemDue;
        }
        itemReminder = kanbanDueReminderValue(kanbanInput("due_reminder", 8));
        if (itemReminder NEQ "-1") {
            if (itemDue EQ "null") {
                throw(type = "TrelloKanban.Validation", message = "Defina o prazo do item antes de escolher um lembrete.");
            }
            itemParams.dueReminder = itemReminder;
        }
        itemMemberId = kanbanInput("member_id", 32);
        if (len(itemMemberId)) {
            itemParams.idMember = kanbanAssertIdsOnBoard(boardId, "members", itemMemberId);
        }
        remoteResponse = kanbanTrelloRequest("/checklists/" & checklistId & "/checkItems", "POST", itemParams);
        kanbanAudit("add_check_item", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"checklistId" = checklistId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Item adicionado."});
    }

    if (action EQ "update_check_item") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        checklistId = kanbanTrelloId(kanbanInput("checklist_id", 32));
        kanbanAssertChecklistOnCard(checklistId, cardId, boardId);
        checkItemId = kanbanTrelloId(kanbanInput("check_item_id", 32));
        itemParams = {
            state = kanbanBoolean(kanbanInput("complete", 8)) ? "complete" : "incomplete"
        };
        itemName = kanbanInput("name", 512);
        if (len(itemName)) {
            itemParams.name = itemName;
        }
        if (structKeyExists(FORM, "due")) {
            itemParams.due = kanbanDateValue(kanbanInput("due", 64), "Prazo do item");
        }
        if (structKeyExists(FORM, "due_reminder")) {
            itemReminder = kanbanDueReminderValue(kanbanInput("due_reminder", 8));
            if (structKeyExists(itemParams, "due") AND itemParams.due EQ "null" AND itemReminder NEQ "-1") {
                throw(type = "TrelloKanban.Validation", message = "Defina o prazo do item antes de escolher um lembrete.");
            }
            itemParams.dueReminder = itemReminder;
        }
        itemMemberId = kanbanInput("member_id", 32);
        if (len(itemMemberId)) {
            itemParams.idMember = kanbanAssertIdsOnBoard(boardId, "members", itemMemberId);
        } else if (structKeyExists(FORM, "member_id")) {
            itemParams.idMember = "null";
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/checkItem/" & checkItemId, "PUT", itemParams);
        kanbanAudit("update_check_item", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"checklistId" = checklistId, "checkItemId" = checkItemId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Item atualizado."});
    }

    if (action EQ "delete_check_item") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        checklistId = kanbanTrelloId(kanbanInput("checklist_id", 32));
        kanbanAssertChecklistOnCard(checklistId, cardId, boardId);
        checkItemId = kanbanTrelloId(kanbanInput("check_item_id", 32));
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/checkItem/" & checkItemId, "DELETE", {});
        kanbanAudit("delete_check_item", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"checklistId" = checklistId, "checkItemId" = checkItemId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Item removido."});
    }

    if (action EQ "add_attachment_url") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        attachmentUrl = kanbanAttachmentUrl(kanbanInput("url", 2000));
        attachmentName = kanbanInput("name", 256);
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/attachments", "POST", {
            url = attachmentUrl,
            name = len(attachmentName) ? attachmentName : attachmentUrl,
            setCover = kanbanBoolean(kanbanInput("set_cover", 8)) ? "true" : "false"
        });
        kanbanAudit("add_attachment_url", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"name" = attachmentName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Anexo adicionado."});
    }

    if (action EQ "add_attachment_file") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        if (!structKeyExists(FORM, "attachment_file") OR !len(trim(FORM.attachment_file & ""))) {
            throw(type = "TrelloKanban.Validation", message = "Selecione um arquivo.");
        }
        uploadedFilePath = "";
        try {
            uploadResult = fileUpload(getTempDirectory(), "attachment_file", "", "makeUnique");
            uploadedFilePath = uploadResult.serverDirectory & "/" & uploadResult.serverFile;
            if (val(uploadResult.fileSize) LTE 0 OR val(uploadResult.fileSize) GT 10485760) {
                throw(type = "TrelloKanban.Validation", message = "O arquivo deve ter no máximo 10 MB.");
            }
            blockedExtensions = "cfm,cfc,cfml,jsp,php,asp,aspx,exe,dll,com,bat,cmd,sh,ps1,jar,war,html,htm,js,mjs";
            uploadedExtension = lCase(listLast(uploadResult.clientFile & "", "."));
            if (listFindNoCase(blockedExtensions, uploadedExtension)) {
                throw(type = "TrelloKanban.Validation", message = "Este tipo de arquivo não é permitido.");
            }
            uploadMime = len(trim(uploadResult.contentType & ""))
                ? uploadResult.contentType & "/" & uploadResult.contentSubType
                : "application/octet-stream";
            remoteResponse = kanbanTrelloFileRequest(
                "/cards/" & cardId & "/attachments",
                uploadedFilePath,
                left(uploadResult.clientFile & "", 256),
                uploadMime,
                kanbanBoolean(kanbanInput("set_cover", 8))
            );
        } finally {
            if (len(uploadedFilePath) AND fileExists(uploadedFilePath)) {
                fileDelete(uploadedFilePath);
            }
        }
        kanbanAudit("add_attachment_file", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"name" = left(uploadResult.clientFile & "", 256), "bytes" = val(uploadResult.fileSize)}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Arquivo anexado."});
    }

    if (action EQ "delete_attachment") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        attachmentId = kanbanTrelloId(kanbanInput("attachment_id", 32));
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/attachments/" & attachmentId, "DELETE", {});
        kanbanAudit("delete_attachment", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"attachmentId" = attachmentId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Anexo removido."});
    }

    if (action EQ "set_attachment_cover") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        attachmentId = kanbanInput("attachment_id", 32);
        if (len(attachmentId)) {
            attachmentId = kanbanTrelloId(attachmentId);
            attachmentResponse = kanbanTrelloRequest("/cards/" & cardId & "/attachments/" & attachmentId, "GET", {fields = "id"});
            if (!attachmentResponse.success) {
                throw(type = "TrelloKanban.ForbiddenAttachment", message = "O anexo não pertence ao cartão autorizado.");
            }
        } else {
            attachmentId = "null";
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", {idAttachmentCover = attachmentId});
        kanbanAudit("set_attachment_cover", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"attachmentId" = attachmentId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = len(kanbanInput("attachment_id", 32)) ? "Capa atualizada." : "Capa removida."});
    }

    if (action EQ "add_comment") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        commentText = kanbanInput("text", 10000);
        if (!len(commentText)) {
            throw(type = "TrelloKanban.Validation", message = "Escreva um comentário.");
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/actions/comments", "POST", {text = commentText});
        kanbanAudit("add_comment", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"length" = len(commentText)}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Comentário publicado."});
    }

    if (action EQ "update_comment") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        actionId = kanbanTrelloId(kanbanInput("action_id", 32));
        kanbanAssertCommentOnCard(actionId, cardId);
        commentText = kanbanInput("text", 10000);
        if (!len(commentText)) {
            throw(type = "TrelloKanban.Validation", message = "O comentário não pode ficar vazio.");
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/actions/" & actionId & "/comments", "PUT", {text = commentText});
        kanbanAudit("update_comment", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"actionId" = actionId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Comentário atualizado."});
    }

    if (action EQ "delete_comment") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        actionId = kanbanTrelloId(kanbanInput("action_id", 32));
        kanbanAssertCommentOnCard(actionId, cardId);
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/actions/" & actionId & "/comments", "DELETE", {});
        kanbanAudit("delete_comment", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"actionId" = actionId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Comentário removido."});
    }

    if (action EQ "update_custom_field") {
        cardId = kanbanTrelloId(kanbanInput("card_id", 32));
        kanbanAssertCardOnBoard(cardId, boardId);
        customFieldId = kanbanTrelloId(kanbanInput("custom_field_id", 32));
        customField = kanbanAssertCustomFieldOnBoard(customFieldId, boardId);
        fieldType = lCase(customField.type & "");
        if (!listFindNoCase("checkbox,date,list,number,text", fieldType)) {
            throw(type = "TrelloKanban.Validation", message = "Tipo de campo personalizado não suportado pelo Trello.");
        }
        rawFieldValue = kanbanInput("value", 10000);
        clearField = kanbanBoolean(kanbanInput("clear", 8));
        customPayload = {};
        if (clearField) {
            customPayload["value"] = "";
        } else if (fieldType EQ "list") {
            customOptionId = kanbanTrelloId(rawFieldValue);
            customOptionAllowed = false;
            if (structKeyExists(customField, "options") AND isArray(customField.options)) {
                for (customOption in customField.options) {
                    if (isStruct(customOption)
                        AND structKeyExists(customOption, "id")
                        AND compareNoCase(customOption.id & "", customOptionId) EQ 0) {
                        customOptionAllowed = true;
                        break;
                    }
                }
            }
            if (!customOptionAllowed) {
                throw(type = "TrelloKanban.ForbiddenCustomFieldOption", message = "A opção não pertence ao campo personalizado autorizado.");
            }
            customPayload["idValue"] = customOptionId;
        } else if (fieldType EQ "checkbox") {
            customValue = {};
            customValue["checked"] = kanbanBoolean(rawFieldValue) ? "true" : "false";
            customPayload["value"] = customValue;
        } else if (fieldType EQ "date") {
            customValue = {};
            customValue["date"] = kanbanDateValue(rawFieldValue, "Data do campo");
            customPayload["value"] = customValue;
        } else if (fieldType EQ "number") {
            if (!isNumeric(rawFieldValue)) {
                throw(type = "TrelloKanban.Validation", message = "Informe um número válido.");
            }
            customValue = {};
            customValue["number"] = rawFieldValue;
            customPayload["value"] = customValue;
        } else {
            customValue = {};
            customValue["text"] = rawFieldValue;
            customPayload["value"] = customValue;
        }
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId & "/customField/" & customFieldId & "/item", "PUT", customPayload, 20, true);
        kanbanAudit("update_custom_field", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"customFieldId" = customFieldId, "cleared" = clearField}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Campo personalizado atualizado."});
    }

    if (action EQ "create_list") {
        listName = kanbanInput("name", 256);
        if (!len(listName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o nome da lista.");
        }
        remoteResponse = kanbanTrelloRequest("/lists", "POST", {idBoard = boardId, name = listName, pos = "bottom"});
        kanbanAudit("create_list", remoteResponse.success, boardId, "", mappedBoardId, remoteResponse.status, {"name" = listName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Lista criada."});
    }

    if (action EQ "update_list") {
        listId = kanbanTrelloId(kanbanInput("list_id", 32));
        kanbanAssertListOnBoard(listId, boardId);
        listName = kanbanInput("name", 256);
        if (!len(listName)) {
            throw(type = "TrelloKanban.Validation", message = "Informe o nome da lista.");
        }
        remoteResponse = kanbanTrelloRequest("/lists/" & listId, "PUT", {name = listName});
        kanbanAudit("update_list", remoteResponse.success, boardId, "", mappedBoardId, remoteResponse.status, {"listId" = listId, "name" = listName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Lista renomeada."});
    }

    if (action EQ "archive_list") {
        listId = kanbanTrelloId(kanbanInput("list_id", 32));
        kanbanAssertListOnBoard(listId, boardId);
        remoteResponse = kanbanTrelloRequest("/lists/" & listId, "PUT", {closed = "true"});
        kanbanAudit("archive_list", remoteResponse.success, boardId, "", mappedBoardId, remoteResponse.status, {"listId" = listId}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Lista arquivada."});
    }

    kanbanApiWrite({"success" = false, "message" = "Ação não reconhecida."}, 404);
} catch (any error) {
    responseStatus = findNoCase("Remote", error.type & "") ? 424
        : (findNoCase("Csrf", error.type & "") ? 403
        : (findNoCase("Forbidden", error.type & "") ? 403
        : (findNoCase("Method", error.type & "") ? 405 : 400)));
    kanbanApiWrite({"success" = false, "message" = left(error.message & "", 500)}, responseStatus);
}
</cfscript>
