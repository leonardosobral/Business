<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="100"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfscript>
function helpdeskAIReply(required numeric code, required struct payload) {
    cfheader(statuscode=arguments.code,statustext="");
    var serializer=createObject("component","helpdesk.includes.HelpdeskAI");
    writeOutput(serializeJSON(serializer.wire(arguments.payload)));
}
if (CGI.REQUEST_METHOD!="POST") {
    cfheader(name="Allow",value="POST");
    helpdeskAIReply(405,{success=false,message="Use o botão Criar resposta com IA no chamado."}); abort;
}
if (!structKeyExists(REQUEST,"businessIdentity") || !structKeyExists(REQUEST.businessIdentity,"id") || !isNumeric(REQUEST.businessIdentity.id)) {
    helpdeskAIReply(401,{success=false,message="Sua sessão expirou. Entre novamente no Business."}); abort;
}
varAllowed=false;
try {
    qAIAdmin=queryExecute("SELECT is_admin FROM tb_usuarios WHERE id=:id",{id={value=REQUEST.businessIdentity.id,cfsqltype="cf_sql_integer"}},{datasource=structKeyExists(REQUEST,"primaryPgDatasource")?REQUEST.primaryPgDatasource:"runner_dba"});
    varAllowed=qAIAdmin.recordCount && isBoolean(qAIAdmin.is_admin) && qAIAdmin.is_admin;
} catch(any authError) {
    helpdeskAIReply(503,{success=false,message="Não foi possível validar seu acesso. Tente novamente."}); abort;
}
if (!varAllowed) { helpdeskAIReply(403,{success=false,message="Recurso exclusivo dos administradores globais do helpdesk."}); abort; }
if ((structKeyExists(CGI,"HTTP_SEC_FETCH_SITE") && len(CGI.HTTP_SEC_FETCH_SITE) && !listFindNoCase("same-origin,none",CGI.HTTP_SEC_FETCH_SITE))
    || (structKeyExists(CGI,"HTTP_ORIGIN") && len(CGI.HTTP_ORIGIN) && compareNoCase(reReplaceNoCase(CGI.HTTP_ORIGIN,"^https?://([^/]+)$","\1"),CGI.HTTP_HOST)!=0)
    || !structKeyExists(SESSION,"helpdeskAICsrf") || !structKeyExists(FORM,"csrf_token") || !isSimpleValue(FORM.csrf_token) || compare(FORM.csrf_token,SESSION.helpdeskAICsrf)!=0) {
    helpdeskAIReply(403,{success=false,message="A sessão de segurança expirou. Recarregue a página e tente novamente."}); abort;
}
if (!structKeyExists(FORM,"ticket_id") || !isSimpleValue(FORM.ticket_id) || !reFind("^[1-9][0-9]{0,9}$",FORM.ticket_id) || val(FORM.ticket_id)>2147483647
    || (structKeyExists(FORM,"note") && (!isSimpleValue(FORM.note) || len(FORM.note)>1500))) {
    helpdeskAIReply(400,{success=false,message="Chamado ou orientação inválidos (máximo de 1.500 caracteres)."}); abort;
}
// Limite por operador, compartilhado entre sessões. Nenhuma transação do helpdesk.
busy=false; limited=false; lease=createUUID(); actor=REQUEST.businessIdentity.id&"";
lock scope="application" type="exclusive" timeout="3" {
    if (!structKeyExists(APPLICATION,"helpdeskAILimits")) APPLICATION.helpdeskAILimits={};
    for (limitKey in APPLICATION.helpdeskAILimits) if (dateDiff("s",APPLICATION.helpdeskAILimits[limitKey].started,now())>3600 && dateDiff("s",APPLICATION.helpdeskAILimits[limitKey].busy_at,now())>120) structDelete(APPLICATION.helpdeskAILimits,limitKey);
    if (!structKeyExists(APPLICATION.helpdeskAILimits,actor)) APPLICATION.helpdeskAILimits[actor]={started=now(),count=0,busy_at=dateAdd("d",-1,now()),lease=""};
    state=APPLICATION.helpdeskAILimits[actor];
    busy=len(state.lease) && dateDiff("s",state.busy_at,now())<120;
    limited=state.count>=20;
    if (!busy && !limited) { state.count++; state.busy_at=now(); state.lease=lease; }
}
if (busy || limited) {
    cfheader(name="Retry-After",value=busy?"30":"3600");
    helpdeskAIReply(429,{success=false,message=busy?"Já existe uma geração em andamento. Aguarde sua conclusão.":"Limite de 20 gerações por hora atingido. Tente novamente mais tarde."}); abort;
}
try {
    apiKey=structKeyExists(APPLICATION,"vickyKnowledge") && structKeyExists(APPLICATION.vickyKnowledge,"apiKey")?APPLICATION.vickyKnowledge.apiKey&"":"";
    service=createObject("component","helpdesk.includes.HelpdeskAI").init(apiKey);
    result=service.generate(val(FORM.ticket_id),val(actor),structKeyExists(FORM,"note")?trim(FORM.note):"");
    helpdeskAIReply(200,result);
} catch(any error) {
    code=502; message="Não foi possível gerar a resposta. Tente novamente; seu texto foi preservado.";
    if (left(error.type,11)=="HelpdeskAI.") {
        message=error.message;
        if (error.type=="HelpdeskAI.Unavailable") code=503;
        if (error.type=="HelpdeskAI.NotFound") code=404;
        if (error.type=="HelpdeskAI.Invalid") code=400;
        if (error.type=="HelpdeskAI.Changed") code=409;
    }
    writeLog(file="business-helpdesk-ai",type="warning",text="Draft failure type="&left(reReplace(error.type,"[^A-Za-z0-9._-]","","all"),80));
    helpdeskAIReply(code,{success=false,message=message});
} finally {
    lock scope="application" type="exclusive" timeout="3" {
        if (structKeyExists(APPLICATION.helpdeskAILimits,actor) && APPLICATION.helpdeskAILimits[actor].lease==lease) APPLICATION.helpdeskAILimits[actor].lease="";
    }
}
</cfscript>
