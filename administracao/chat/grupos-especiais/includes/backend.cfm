<cfscript>
function specialGroupsBusinessApi(required struct payload) {
    var result={success=false,message="Resposta inválida do Road Runners."};
    var dispatch=structKeyExists(APPLICATION,"specialGroups") && isStruct(APPLICATION.specialGroups) ? APPLICATION.specialGroups : {};
    if (!structKeyExists(dispatch,"configured") || !dispatch.configured || !structKeyExists(dispatch,"url") || !len(trim(dispatch.url & "")) || !structKeyExists(dispatch,"secret") || !len(trim(dispatch.secret & ""))) return {success=false,message="Configure RR_CHAT_SPECIAL_GROUPS_SECRET (ou RR_HANDOFF_SECRET) nos dois projetos."};
    var endpoint=trim(dispatch.url & "");
    var body=serializeJSON(arguments.payload);
    var timestamp=dateTimeFormat(now(),"yyyy-mm-dd HH:nn:ss");
    var signature=lCase(hmac(timestamp & "." & body,dispatch.secret,"HmacSHA256"));
    try {
        var request=new http(method="post",url=endpoint,timeout=structKeyExists(dispatch,"timeoutSeconds") ? max(5,val(dispatch.timeoutSeconds)) : 20,throwOnError=false);
        request.addParam(type="header",name="Content-Type",value="application/json; charset=utf-8");
        request.addParam(type="header",name="X-RR-Handoff-Timestamp",value=timestamp);
        request.addParam(type="header",name="X-RR-Handoff-Signature",value=signature);
        request.addParam(type="body",value=body);
        var response=request.send().getPrefix();
        var responseBody=structKeyExists(response,"fileContent") ? trim(toString(response.fileContent)) : "";
        var responseStatus=structKeyExists(response,"statusCode") ? trim(response.statusCode & "") : "";
        if (len(responseBody) && isJSON(responseBody)) result=deserializeJSON(responseBody);
        else if (reFind("^404",responseStatus)) result={success=false,message="Endpoint de grupos especiais não encontrado no Road Runners. Verifique specialGroupsUrl e a publicação da API.",http_status=responseStatus};
        else if (reFind("^401",responseStatus) || reFind("^403",responseStatus)) result={success=false,message="A integração com o Road Runners recusou a autenticação. Confira se o segredo é idêntico nos dois sistemas.",http_status=responseStatus};
        else if (reFind("^5[0-9][0-9]",responseStatus)) result={success=false,message="O Road Runners encontrou um erro interno ao processar a integração. Consulte o log do endpoint de grupos especiais.",http_status=responseStatus};
        else result={success=false,message="O Road Runners retornou uma resposta inválida para a integração.",http_status=responseStatus};
    } catch (any apiError) {
        result={success=false,message=apiError.message,detail=apiError.detail};
    }
    return result;
}

function specialGroupsBoolean(any value) {
    return isBoolean(arguments.value) ? arguments.value : listFindNoCase("1,true,yes,sim,on",arguments.value & "")>0;
}

function specialGroupsMessage(required string code) {
    var messages={
        invalid_special_group_rule="A regra contém um critério ou valor inválido.",
        invalid_special_group_rule_type="O tipo de critério não é permitido.",
        special_group_owner_ineligible="O atleta definido como Dono não atende à regra de participação.",
        special_group_duplicate="Já existe um grupo especial com este nome ou código.",
        special_group_sync_in_progress="Este grupo já possui uma sincronização em andamento.",
        special_groups_not_installed="A migration de grupos especiais ainda não foi aplicada.",
        special_groups_integration_not_configured="A integração assinada de grupos especiais não está configurada.",
        invalid_signature="A assinatura enviada ao Road Runners foi recusada.",
        expired_signature="A assinatura expirou antes de ser processada."
    };
    return structKeyExists(messages,arguments.code) ? messages[arguments.code] : arguments.code;
}

if (!structKeyExists(SESSION,"specialGroupsCsrf") || !len(trim(SESSION.specialGroupsCsrf & ""))) SESSION.specialGroupsCsrf=lCase(hash(createUUID() & now() & getTickCount(),"SHA-256"));
VARIABLES.specialGroupsCsrf=SESSION.specialGroupsCsrf;
VARIABLES.specialGroupsFeedback="";
VARIABLES.specialGroupsFeedbackType="success";
VARIABLES.specialGroupsPreview={};

if (uCase(CGI.REQUEST_METHOD) EQ "POST") {
    try {
        if (!structKeyExists(FORM,"special_groups_csrf") || compare(FORM.special_groups_csrf & "",VARIABLES.specialGroupsCsrf)) throw(type="SpecialGroups.Csrf",message="Sessão expirada. Recarregue a página e tente novamente.");
        VARIABLES.managerAction=structKeyExists(FORM,"manager_action") ? lCase(trim(FORM.manager_action & "")) : "";
        VARIABLES.managerPayload={action=VARIABLES.managerAction,actor_id=val(qPerfil.id)};
        if (VARIABLES.managerAction NEQ "preview") {
            VARIABLES.managerPayload.idempotency_key=structKeyExists(FORM,"manager_request_id") ? lCase(trim(FORM.manager_request_id & "")) : "";
            if (!reFind("^[a-z0-9][a-z0-9._:-]{15,119}$",VARIABLES.managerPayload.idempotency_key)) throw(type="SpecialGroups.Validation",message="Identificador da operação inválido. Recarregue a página.");
        }
        if (listFindNoCase("create,update,preview",VARIABLES.managerAction)) {
            if (!structKeyExists(FORM,"policy_json") || !isJSON(FORM.policy_json & "")) throw(type="SpecialGroups.Validation",message="Defina ao menos um critério de participação válido.");
            VARIABLES.managerPayload.policy=deserializeJSON(FORM.policy_json & "");
            VARIABLES.managerPayload.name=structKeyExists(FORM,"group_name") ? trim(FORM.group_name & "") : "";
            VARIABLES.managerPayload.description=structKeyExists(FORM,"group_description") ? trim(FORM.group_description & "") : "";
            VARIABLES.managerPayload.code=structKeyExists(FORM,"group_code") ? lCase(trim(FORM.group_code & "")) : "";
            VARIABLES.managerPayload.owner_id=structKeyExists(FORM,"owner_id") ? val(FORM.owner_id) : 0;
            VARIABLES.managerPayload.image_path=structKeyExists(FORM,"image_path") ? trim(FORM.image_path & "") : "";
            VARIABLES.managerPayload.invitations_enabled=structKeyExists(FORM,"invitations_enabled") && specialGroupsBoolean(FORM.invitations_enabled);
            if (VARIABLES.managerAction EQ "create") VARIABLES.managerPayload.status=structKeyExists(FORM,"activate_now") && specialGroupsBoolean(FORM.activate_now) ? "active" : "draft";
            if (VARIABLES.managerAction EQ "update") VARIABLES.managerPayload.group_id=structKeyExists(FORM,"group_id") ? val(FORM.group_id) : 0;
        } else if (VARIABLES.managerAction EQ "status") {
            VARIABLES.managerPayload.group_id=structKeyExists(FORM,"group_id") ? val(FORM.group_id) : 0;
            VARIABLES.managerPayload.status=structKeyExists(FORM,"group_status") ? trim(FORM.group_status & "") : "";
        } else if (VARIABLES.managerAction EQ "sync") {
            VARIABLES.managerPayload.group_id=structKeyExists(FORM,"group_id") ? val(FORM.group_id) : 0;
            VARIABLES.managerPayload.dry_run=structKeyExists(FORM,"dry_run") && specialGroupsBoolean(FORM.dry_run);
        } else throw(type="SpecialGroups.Validation",message="Ação inválida.");
        VARIABLES.managerActionResult=specialGroupsBusinessApi(VARIABLES.managerPayload);
        if (!isStruct(VARIABLES.managerActionResult) || !structKeyExists(VARIABLES.managerActionResult,"success") || !VARIABLES.managerActionResult.success) throw(type="SpecialGroups.Remote",message=structKeyExists(VARIABLES.managerActionResult,"message") ? specialGroupsMessage(VARIABLES.managerActionResult.message & "") : "A operação não foi concluída.");
        if (VARIABLES.managerAction EQ "preview") {
            VARIABLES.specialGroupsPreview=VARIABLES.managerActionResult;
            VARIABLES.specialGroupsFeedback="Simulação concluída sem alterar membros.";
        } else {
            VARIABLES.managerSuccessCode=VARIABLES.managerAction EQ "create" ? "created" : (VARIABLES.managerAction EQ "update" ? "updated" : (VARIABLES.managerAction EQ "sync" ? "synced" : "status"));
            location(url="./?ok=" & VARIABLES.managerSuccessCode,addtoken=false);
        }
    } catch (any managerError) {
        VARIABLES.specialGroupsFeedback=managerError.message;
        VARIABLES.specialGroupsFeedbackType="danger";
    }
}

if (structKeyExists(URL,"ok")) {
    if (URL.ok EQ "created") VARIABLES.specialGroupsFeedback="Grupo especial criado com sucesso.";
    else if (URL.ok EQ "updated") VARIABLES.specialGroupsFeedback="Configuração atualizada. Execute uma simulação antes da próxima sincronização.";
    else if (URL.ok EQ "synced") VARIABLES.specialGroupsFeedback="Sincronização concluída.";
    else if (URL.ok EQ "status") VARIABLES.specialGroupsFeedback="Status atualizado.";
}

VARIABLES.specialGroupsData=specialGroupsBusinessApi({action="list",actor_id=val(qPerfil.id)});
VARIABLES.specialGroupsReady=isStruct(VARIABLES.specialGroupsData) && structKeyExists(VARIABLES.specialGroupsData,"success") && VARIABLES.specialGroupsData.success;
VARIABLES.specialGroups=isStruct(VARIABLES.specialGroupsData) && structKeyExists(VARIABLES.specialGroupsData,"groups") && isArray(VARIABLES.specialGroupsData.groups) ? VARIABLES.specialGroupsData.groups : [];
VARIABLES.specialGroupsCatalog=isStruct(VARIABLES.specialGroupsData) && structKeyExists(VARIABLES.specialGroupsData,"catalog") && isArray(VARIABLES.specialGroupsData.catalog) ? VARIABLES.specialGroupsData.catalog : [];
VARIABLES.specialGroupsEdit={};
if (structKeyExists(URL,"editar") && isNumeric(URL.editar)) {
    for (VARIABLES.specialGroupItem in VARIABLES.specialGroups) if (val(VARIABLES.specialGroupItem.id_chat_grupo) EQ val(URL.editar)) { VARIABLES.specialGroupsEdit=VARIABLES.specialGroupItem; break; }
}
VARIABLES.specialGroupsEditing=structCount(VARIABLES.specialGroupsEdit)>0;
if (structKeyExists(VARIABLES,"managerAction") && VARIABLES.managerAction EQ "preview" && structKeyExists(VARIABLES,"managerPayload")) {
    VARIABLES.specialGroupsEdit={
        id_chat_grupo=structKeyExists(VARIABLES.managerPayload,"group_id") ? val(VARIABLES.managerPayload.group_id) : 0,
        nome=VARIABLES.managerPayload.name,
        codigo=VARIABLES.managerPayload.code,
        descricao=VARIABLES.managerPayload.description,
        id_dono=VARIABLES.managerPayload.owner_id,
        path_imagem=VARIABLES.managerPayload.image_path,
        convites_habilitados=VARIABLES.managerPayload.invitations_enabled,
        regra=VARIABLES.managerPayload.policy
    };
    VARIABLES.specialGroupsEditing=VARIABLES.specialGroupsEdit.id_chat_grupo GT 0;
}
</cfscript>
