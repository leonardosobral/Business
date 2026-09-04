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
            fields = "id,name,desc,idList,idMembers,labels,due,dueComplete,pos,url,shortUrl,badges,dateLastActivity,closed"
        });
        membersResponse = kanbanTrelloRequest("/boards/" & boardId & "/members", "GET", {fields = "id,fullName,username,avatarUrl"});
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
            "members" = membersResponse.success AND isArray(membersResponse.data) ? membersResponse.data : []
        };
        kanbanApiWrite({"success" = true, "board" = boardPayload});
    }

    if (action EQ "card_comments") {
        boardId = kanbanTrelloId(structKeyExists(URL, "boardId") ? URL.boardId & "" : "");
        cardId = kanbanTrelloId(structKeyExists(URL, "cardId") ? URL.cardId & "" : "");
        mappedBoard = kanbanRequireMappedBoard(boardId);
        kanbanAssertCardOnBoard(cardId, boardId);
        commentsResponse = kanbanTrelloRequest("/cards/" & cardId & "/actions", "GET", {
            filter = "commentCard",
            limit = 50,
            fields = "data,date,idMemberCreator",
            memberCreator = "true",
            memberCreator_fields = "id,fullName,username,avatarUrl"
        });
        if (!commentsResponse.success) {
            kanbanApiWrite({"success" = false, "message" = commentsResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "comments" = isArray(commentsResponse.data) ? commentsResponse.data : []});
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
            pos = "bottom"
        };
        dueValue = kanbanDueValue(kanbanInput("due", 64));
        if (dueValue NEQ "null") {
            params.due = dueValue;
        }
        memberIds = kanbanMemberIds(kanbanInput("member_ids", 1000));
        if (len(memberIds)) {
            params.idMembers = memberIds;
        }
        remoteResponse = kanbanTrelloRequest("/cards", "POST", params);
        cardId = remoteResponse.success AND isStruct(remoteResponse.data) AND structKeyExists(remoteResponse.data, "id") ? remoteResponse.data.id & "" : "";
        kanbanAudit("create_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {"listId" = listId, "name" = cardName}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão criado.", "card" = remoteResponse.data});
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
            dueComplete = kanbanBoolean(kanbanInput("due_complete", 8)) ? "true" : "false",
            idMembers = kanbanMemberIds(kanbanInput("member_ids", 1000))
        };
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
        remoteResponse = kanbanTrelloRequest("/cards/" & cardId, "PUT", {closed = "true"});
        kanbanAudit("archive_card", remoteResponse.success, boardId, cardId, mappedBoardId, remoteResponse.status, {}, remoteResponse.message);
        if (!remoteResponse.success) {
            kanbanApiWrite({"success" = false, "message" = remoteResponse.message}, 424);
        }
        kanbanApiWrite({"success" = true, "message" = "Cartão arquivado."});
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
    responseStatus = findNoCase("Csrf", error.type & "") ? 403
        : (findNoCase("Forbidden", error.type & "") ? 403
        : (findNoCase("Method", error.type & "") ? 405 : 400));
    kanbanApiWrite({"success" = false, "message" = left(error.message & "", 500)}, responseStatus);
}
</cfscript>
