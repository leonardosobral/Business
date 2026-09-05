<cfscript>
function agendaFail(required string message) { throw(type="Agenda.Validation", message=arguments.message); }
function agendaParam(required any value) { return {value=arguments.value, cfsqltype="cf_sql_varchar"}; }
function agendaDb(required string sql, struct params={}) { return queryExecute(arguments.sql, arguments.params, {datasource="runner_dba"}); }
function agendaConfig() {
    if (!structKeyExists(application,"googleCalendar")) agendaFail("Reinicie a aplicação para carregar a configuração da Agenda.");
    var c = application.googleCalendar;
    if (!len(c.CLIENT_ID) || !len(c.CLIENT_SECRET) || !len(c.TOKEN_KEY)) agendaFail("Configure as credenciais e a chave de criptografia da Agenda no servidor.");
    try { if (len(binaryEncode(binaryDecode(c.TOKEN_KEY,"base64"),"hex")) != 64) agendaFail("Chave inválida."); }
    catch (any invalidKey) { agendaFail("RR_GOOGLE_CALENDAR_TOKEN_KEY deve conter 32 bytes aleatórios em Base64."); }
    return c;
}
function agendaReady() {
    var q=agendaDb("SELECT to_regclass('public.tb_google_agenda_conexao') IS NOT NULL AND to_regclass('public.tb_google_agenda_calendarios') IS NOT NULL AND to_regclass('public.tb_google_agenda_cartoes') IS NOT NULL AND to_regclass('public.tb_google_agenda_auditoria') IS NOT NULL AS ready");
    return q.ready;
}
function agendaRandom() { return lCase(hash(generateSecretKey("AES",256),"SHA-256")); }
function agendaRfc3339(required any dateValue) {
    return arguments.dateValue.format(createObject("java","java.time.format.DateTimeFormatter").ofPattern("uuuu-MM-dd'T'HH:mm:ssXXX"));
}
function agendaSeal(required string plaintext) {
    var key=agendaConfig().TOKEN_KEY;
    var encryptionKey=toBase64(binaryDecode(hash(key & ":encryption","SHA-256"),"hex"));
    var ciphertext=encrypt(arguments.plaintext,encryptionKey,"AES/CBC/PKCS5Padding","Base64");
    return ciphertext & "." & hmac(ciphertext,key & ":authentication","HmacSHA256");
}
function agendaUnseal(required string envelope) {
    var key=agendaConfig().TOKEN_KEY;
    var parts=listToArray(arguments.envelope,".");
    if (arrayLen(parts)!=2) agendaFail("Reconecte a conta Google: token inválido.");
    var signature=hmac(parts[1],key & ":authentication","HmacSHA256");
    if (!createObject("java","java.security.MessageDigest").isEqual(charsetDecode(signature,"utf-8"),charsetDecode(parts[2],"utf-8"))) agendaFail("Reconecte a conta Google: chave ou token inválido.");
    return decrypt(parts[1],toBase64(binaryDecode(hash(key & ":encryption","SHA-256"),"hex")),"AES/CBC/PKCS5Padding","Base64");
}
// Only fixed Google endpoints are supplied by server-side callers. Never accept an arbitrary URL.
function agendaHttp(required string endpoint, string method="GET", struct params={}, struct body={}, string token="", string etag="", boolean formBody=false) {
    var address=arguments.endpoint;
    var pairs=[];
    for (var k in arguments.params) arrayAppend(pairs,encodeForURL(k) & "=" & encodeForURL(arguments.params[k] & ""));
    if (!arguments.formBody && arrayLen(pairs)) address &= "?" & arrayToList(pairs,"&");
    var response={};
    cfhttp(url=address,method=arguments.method,result="response",timeout=15,redirect=false,throwonerror=false) {
        cfhttpparam(type="header",name="Accept",value="application/json");
        if (len(arguments.token)) cfhttpparam(type="header",name="Authorization",value="Bearer " & arguments.token);
        if (len(arguments.etag)) cfhttpparam(type="header",name="If-Match",value=arguments.etag);
        if (arguments.formBody) {
            cfhttpparam(type="header",name="Content-Type",value="application/x-www-form-urlencoded");
            cfhttpparam(type="body",value=arrayToList(pairs,"&"));
        } else if (listFind("POST,PATCH,PUT",arguments.method)) {
            cfhttpparam(type="header",name="Content-Type",value="application/json; charset=utf-8");
            cfhttpparam(type="body",value=serializeJSON(arguments.body));
        }
    }
    var raw=structKeyExists(response,"fileContent") ? response.fileContent & "" : "";
    return {status=val(response.statusCode),data=isJSON(raw) ? deserializeJSON(raw) : {}};
}
function agendaAccessToken(boolean force=false) {
    if (!arguments.force && structKeyExists(application,"agendaAccess") && dateCompare(application.agendaAccess.expires, dateAdd("s",60,now())) > 0) return application.agendaAccess.token;
    var c=agendaConfig();
    var q=agendaDb("SELECT refresh_token FROM public.tb_google_agenda_conexao WHERE id=1");
    if (!q.recordCount) agendaFail("Conecte a conta Google para continuar.");
    var r=agendaHttp("https://oauth2.googleapis.com/token","POST",{"client_id"=c.CLIENT_ID,"client_secret"=c.CLIENT_SECRET,"grant_type"="refresh_token","refresh_token"=agendaUnseal(q.refresh_token)}, {}, "", "", true);
    if (r.status!=200 || !structKeyExists(r.data,"access_token")) {
        structDelete(application,"agendaAccess");
        agendaFail("Não foi possível renovar o acesso. Tente novamente ou reconecte a conta Google.");
    }
    application.agendaAccess={token=r.data.access_token,expires=dateAdd("s",val(r.data.expires_in),now())};
    return application.agendaAccess.token;
}
function agendaGoogle(required string path, string method="GET", struct params={}, struct body={}, string etag="", boolean allowConflict=false, boolean allowMissing=false) {
    var r=agendaHttp("https://www.googleapis.com/calendar/v3" & arguments.path,arguments.method,arguments.params,arguments.body,agendaAccessToken(),arguments.etag);
    if (r.status==401) r=agendaHttp("https://www.googleapis.com/calendar/v3" & arguments.path,arguments.method,arguments.params,arguments.body,agendaAccessToken(true),arguments.etag);
    if (r.status==409 && arguments.allowConflict) return {"conflict"=true};
    if ((r.status==404 || r.status==410) && arguments.allowMissing) return {"missing"=true,"deleted"=r.status==410};
    if (r.status==412) agendaFail("Este evento foi alterado no Google. Reabra o compromisso antes de salvar.");
    if (r.status==404 || r.status==410) agendaFail("Evento ou agenda não encontrado. Atualize a visualização.");
    if (r.status==403) agendaFail("O Google negou esta operação. Verifique as permissões da agenda e reconecte se necessário.");
    if (r.status==429 || r.status>=500 || r.status==0) agendaFail("O Google está indisponível ou limitou as consultas. Aguarde e tente novamente.");
    if (r.status<200 || r.status>=300) agendaFail("O Google recusou a operação. Verifique os dados do compromisso.");
    return r.data;
}
function agendaCalendar(required string id) {
    var q=agendaDb("SELECT calendar_id FROM public.tb_google_agenda_calendarios WHERE calendar_id=:id AND ativo=true",{id=agendaParam(arguments.id)});
    if (!q.recordCount) agendaFail("Esta agenda não está habilitada no Business.");
    var c=agendaGoogle("/users/me/calendarList/" & encodeForURL(arguments.id));
    if (!structKeyExists(c,"accessRole") || c.accessRole!="owner") agendaFail("A conta precisa ser proprietária desta agenda.");
    return c;
}
function agendaEventPath(required string calendarId,string eventId="") {
    if (len(arguments.eventId) && !reFind("^[a-zA-Z0-9_-]{1,1024}$",arguments.eventId)) agendaFail("Identificador de evento inválido.");
    return "/calendars/" & encodeForURL(arguments.calendarId) & "/events" & (len(arguments.eventId) ? "/" & encodeForURL(arguments.eventId) : "");
}
function agendaAudit(required string action,string calendarId="",string eventId="") {
    var q=agendaDb("INSERT INTO public.tb_google_agenda_auditoria(id_usuario,acao,calendar_id,event_id) VALUES(:actor,:action,:calendar,:event) RETURNING id",{actor={value=val(qPerfil.id),cfsqltype="cf_sql_integer"},action=agendaParam(arguments.action),calendar=agendaParam(arguments.calendarId),event=agendaParam(arguments.eventId)});
    return q.id;
}
function agendaAuditEnd(required numeric id,required string state) {
    agendaDb("UPDATE public.tb_google_agenda_auditoria SET estado=:state WHERE id=:id",{state=agendaParam(arguments.state),id={value=arguments.id,cfsqltype="cf_sql_bigint"}});
}
function agendaMutation() {
    if (CGI.request_method!="POST" || !structKeyExists(form,"csrf_token") || !structKeyExists(session,"agendaCsrf") || compare(form.csrf_token,session.agendaCsrf)!=0) agendaFail("Sessão de segurança expirada. Recarregue a página.");
}
function agendaInput(required string key,string fallback="") {
    return structKeyExists(form,arguments.key) && isSimpleValue(form[arguments.key]) ? trim(form[arguments.key] & "") : arguments.fallback;
}
function agendaCard(required string id) {
    if (!reFind("^[0-9a-f]{24}$",arguments.id)) agendaFail("Cartão inválido.");
    var r=kanbanTrelloRequest("/cards/" & arguments.id,"GET",{fields="id,idBoard,name,desc,due,url,closed"});
    if (!r.success || !isStruct(r.data) || !structKeyExists(r.data,"idBoard")) agendaFail("Não foi possível consultar o cartão no Trello.");
    var q=agendaDb("SELECT trello_board_id FROM public.tb_trello_quadros WHERE trello_board_id=:board AND ativo=true",{board=agendaParam(r.data.idBoard)});
    if (!q.recordCount) agendaFail("O quadro deste cartão não está autorizado no Business.");
    return r.data;
}
</cfscript>
