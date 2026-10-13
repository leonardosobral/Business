<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="/administracao/agenda/includes/service.cfm"/>
<cfscript>

function agendaReply(required struct payload,numeric status=200) {
    cfheader(statuscode=arguments.status);
    cfheader(name="Cache-Control",value="no-store");
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}
function agendaDispatch() {
    agendaMutation();
    if (!agendaReady()) agendaFail("Execute administracao/agenda/agenda_schema.sql no banco runner_dba.");
    var action=agendaInput("action");
    var c=agendaConfig();
    var q={}; var r={}; var result={}; var items=[]; var page="";
    if (action=="status") {
        q=agendaDb("SELECT email FROM public.tb_google_agenda_conexao WHERE id=1");
        var calendars=agendaDb("SELECT calendar_id,nome FROM public.tb_google_agenda_calendarios WHERE ativo=true ORDER BY nome");
        for (var row in calendars) arrayAppend(items,{"id"=row.calendar_id,"summary"=row.nome});
        return {"connected"=q.recordCount>0,"email"=c.email,"calendars"=items};
    }
    if (action=="connect") {
        var verifier=agendaRandom() & agendaRandom();
        var state=agendaRandom();
        session.agendaOAuth={state=state,verifier=verifier,actor=val(qPerfil.id),expires=dateAdd("n",10,now())};
        var challenge=replace(replace(replace(toBase64(binaryDecode(hash(verifier,"SHA-256"),"hex")),"+","-","all"),"/","_","all"),"=","","all");
        var scopes=c.scopes;
        var prior=agendaDb("SELECT scopes FROM public.tb_google_agenda_conexao WHERE id=1");
        if(prior.recordCount && listFind(prior.scopes,"https://www.googleapis.com/auth/gmail.readonly"," ")) scopes &= " https://www.googleapis.com/auth/gmail.readonly";
        if(prior.recordCount && listFind(prior.scopes,"https://www.googleapis.com/auth/analytics.readonly"," ")) scopes &= " https://www.googleapis.com/auth/analytics.readonly";
        var args={"client_id"=c.CLIENT_ID,"redirect_uri"=c.redirectUri,"response_type"="code","scope"=scopes,"include_granted_scopes"="true","access_type"="offline","prompt"="consent select_account","login_hint"=c.email,"state"=state,"code_challenge"=challenge,"code_challenge_method"="S256"};
        var pairs=[]; for (var key in args) arrayAppend(pairs,encodeForURL(key) & "=" & encodeForURL(args[key]));
        return {"url"="https://accounts.google.com/o/oauth2/v2/auth?" & arrayToList(pairs,"&")};
    }
    if (action=="disconnect") {
        var audit=agendaAudit(action);
        q=agendaDb("SELECT refresh_token FROM public.tb_google_agenda_conexao WHERE id=1");
        var revoked=true;
        if (q.recordCount) {
            try { r=agendaHttp("https://oauth2.googleapis.com/revoke","POST",{"token"=agendaUnseal(q.refresh_token)}, {}, "", "", true); revoked=r.status==200; }
            catch(any revokeError) { revoked=false; }
        }
        agendaDb("DELETE FROM public.tb_google_agenda_conexao WHERE id=1");
        structDelete(application,"agendaAccess"); structDelete(session,"agendaOAuth");
        agendaAuditEnd(audit,revoked ? "success" : "local_only");
        return {"message"=revoked ? "Conta desconectada." : "Conexão local removida. Remova também o acesso em Conta Google > Segurança > Conexões com apps de terceiros."};
    }
    // All remaining operations require a live, refreshable connection.
    agendaAccessToken();
    if (action=="calendars") {
        do {
            r=agendaGoogle("/users/me/calendarList","GET",{"maxResults"=250,"pageToken"=page});
            if (structKeyExists(r,"items")) for (var calendar in r.items) {
                if (calendar.accessRole=="owner") {
                    q=agendaDb("SELECT ativo FROM public.tb_google_agenda_calendarios WHERE calendar_id=:id",{id=agendaParam(calendar.id)});
                    arrayAppend(items,{"id"=calendar.id,"summary"=calendar.summary,"selected"=q.recordCount>0 && q.ativo});
                }
            }
            page=structKeyExists(r,"nextPageToken") ? r.nextPageToken : "";
        } while(len(page));
        return {"items"=items};
    }
    if (action=="select_calendars") {
        var selected=deserializeJSON(agendaInput("ids","[]"));
        if (!isArray(selected) || arrayLen(selected)>30) agendaFail("Selecione até 30 agendas.");
        var allowed=[];
        for (var id in selected) {
            if (!isSimpleValue(id) || len(id)>1024) agendaFail("Agenda inválida.");
            r=agendaGoogle("/users/me/calendarList/" & encodeForURL(id));
            if (r.accessRole!="owner") agendaFail("Selecione apenas agendas pertencentes à conta.");
            arrayAppend(allowed,r);
        }
        var audit=agendaAudit(action);
        transaction {
            agendaDb("UPDATE public.tb_google_agenda_calendarios SET ativo=false");
            for (var calendar in allowed) agendaDb("INSERT INTO public.tb_google_agenda_calendarios(calendar_id,nome,ativo) VALUES(:id,:name,true) ON CONFLICT(calendar_id) DO UPDATE SET nome=EXCLUDED.nome,ativo=true",{id=agendaParam(calendar.id),name=agendaParam(calendar.summary)});
            agendaAuditEnd(audit,"success");
        }
        return {"message"="Agendas disponíveis atualizadas."};
    }
    if (action=="card") {
        var card=agendaCard(agendaInput("card_id"));
        q=agendaDb("SELECT calendar_id,event_id FROM public.tb_google_agenda_cartoes WHERE card_id=:id",{id=agendaParam(card.id)});
        var link={};
        if (q.recordCount) {
            agendaCalendar(q.calendar_id);
            r=agendaGoogle(agendaEventPath(q.calendar_id,q.event_id),"GET",{}, {}, "",false,true);
            var deleted=(structKeyExists(r,"deleted") && r.deleted) || (structKeyExists(r,"status") && r.status=="cancelled");
            if (deleted) {
                var audit=agendaAudit("unlink_deleted",q.calendar_id,q.event_id);
                agendaDb("DELETE FROM public.tb_google_agenda_cartoes WHERE card_id=:card",{card=agendaParam(card.id)});
                agendaAuditEnd(audit,"success");
            }
            link={"calendarId"=q.calendar_id,"eventId"=deleted || structKeyExists(r,"missing") ? "" : q.event_id};
        }
        return {"card"={"id"=card.id,"name"=card.name,"description"=card.desc,"due"=structKeyExists(card,"due") && !isNull(card.due) ? card.due : "","url"=card.url},"link"=link};
    }
    var calendarId=agendaInput("calendar_id");
    agendaCalendar(calendarId);
    if (action=="events") {
        var from=agendaInput("from"); var until=agendaInput("until");
        if (!reFind("^\d{4}-\d{2}-\d{2}$",from) || !reFind("^\d{4}-\d{2}-\d{2}$",until)) agendaFail("Período inválido.");
        var localDate=createObject("java","java.time.LocalDate");
        var first=localDate.parse(from); var last=localDate.parse(until);
        var days=last.toEpochDay()-first.toEpochDay();
        if (days<1 || days>93) agendaFail("Consulte um período de até 93 dias.");
        var zone=createObject("java","java.time.ZoneId").of("America/Sao_Paulo");
        var params={"timeMin"=agendaRfc3339(first.atStartOfDay(zone)),"timeMax"=agendaRfc3339(last.atStartOfDay(zone)),"singleEvents"="true","orderBy"="startTime","maxResults"=250,"timeZone"="America/Sao_Paulo"};
        do {
            if (len(page)) params["pageToken"]=page;
            r=agendaGoogle(agendaEventPath(calendarId),"GET",params);
            if (structKeyExists(r,"items")) for (var event in r.items) arrayAppend(items,event);
            page=structKeyExists(r,"nextPageToken") ? r.nextPageToken : "";
            if (arrayLen(items)>5000) agendaFail("Muitos eventos neste período. Selecione uma semana.");
        } while(len(page));
        return {"items"=items};
    }
    var eventId=agendaInput("event_id");
    if (action=="event") {
        if (!len(eventId)) agendaFail("Selecione um evento.");
        r=agendaGoogle(agendaEventPath(calendarId,eventId));
        if (agendaInput("scope")=="series" && structKeyExists(r,"recurringEventId")) r=agendaGoogle(agendaEventPath(calendarId,r.recurringEventId));
        return {"event"=r};
    }
    if (!listFind("save,delete",action)) agendaFail("Operação inválida.");
    var current={}; var etag=agendaInput("etag");
    if (len(eventId)) {
        if (!len(etag) || len(etag)>256 || reFind("[\r\n]",etag)) agendaFail("Reabra o evento antes de alterar.");
        current=agendaGoogle(agendaEventPath(calendarId,eventId));
        if (compare(current.etag,etag)!=0) agendaFail("O evento mudou. Reabra-o antes de salvar.");
        if (structKeyExists(current,"eventType") && current.eventType!="default") agendaFail("Edite este tipo especial de evento diretamente no Google.");
    }
    var updates=agendaInput("send_updates");
    if (!listFind("all,none",updates)) agendaFail("Escolha se os participantes devem receber uma notificação.");
    if (action=="delete") {
        if (!len(eventId)) agendaFail("Selecione um evento.");
        var audit=agendaAudit(action,calendarId,eventId);
        try {
            agendaGoogle(agendaEventPath(calendarId,eventId),"DELETE",{"sendUpdates"=updates},{},etag);
            agendaDb("DELETE FROM public.tb_google_agenda_cartoes WHERE calendar_id=:calendar AND event_id=:event",{calendar=agendaParam(calendarId),event=agendaParam(eventId)});
            agendaAuditEnd(audit,"success");
        } catch(any deletionError) { agendaAuditEnd(audit,"failed"); rethrow; }
        return {"message"="Evento excluído."};
    }
    var data=deserializeJSON(agendaInput("event","{}"));
    if (!isStruct(data)) agendaFail("Evento inválido.");
    for (var requiredField in ["summary","description","location","start","end","allDay","attendees","repeat"]) if (!structKeyExists(data,requiredField)) agendaFail("Preencha todos os campos do evento.");
    if (!isSimpleValue(data.summary) || !len(trim(data.summary)) || len(data.summary)>1024 || !isSimpleValue(data.description) || len(data.description)>8000 || !isSimpleValue(data.location) || len(data.location)>1024) agendaFail("Título, descrição ou local inválidos.");
    var body={"summary"=trim(data.summary),"description"=data.description,"location"=data.location};
    var startValue=""; var endValue="";
    if (!isBoolean(data.allDay)) agendaFail("Tipo de data inválido.");
    if (data.allDay) {
        startValue=createObject("java","java.time.LocalDate").parse(data.start);
        endValue=createObject("java","java.time.LocalDate").parse(data.end);
        if (!endValue.isAfter(startValue)) agendaFail("O fim deve ser posterior ao início (data final exclusiva).");
        body["start"]={"date"=startValue.toString()}; body["end"]={"date"=endValue.toString()};
    } else {
        var zone=createObject("java","java.time.ZoneId").of("America/Sao_Paulo");
        startValue=createObject("java","java.time.LocalDateTime").parse(data.start).atZone(zone);
        endValue=createObject("java","java.time.LocalDateTime").parse(data.end).atZone(zone);
        if (!endValue.isAfter(startValue)) agendaFail("O término deve ser posterior ao início.");
        // Preserve an existing series' IANA timezone, so editing its title cannot shift later DST occurrences.
        var startZone=structKeyExists(current,"start") && structKeyExists(current.start,"timeZone") ? current.start.timeZone : "America/Sao_Paulo";
        var endZone=structKeyExists(current,"end") && structKeyExists(current.end,"timeZone") ? current.end.timeZone : startZone;
        body["start"]={"dateTime"=agendaRfc3339(startValue.withZoneSameInstant(createObject("java","java.time.ZoneId").of(startZone))),"timeZone"=startZone};
        body["end"]={"dateTime"=agendaRfc3339(endValue.withZoneSameInstant(createObject("java","java.time.ZoneId").of(endZone))),"timeZone"=endZone};
    }
    if (!isArray(data.attendees) || arrayLen(data.attendees)>100) agendaFail("Informe até 100 participantes.");
    var attendees=[]; var seen={};
    for (var email in data.attendees) {
        if (!isSimpleValue(email) || !isValid("email",email) || len(email)>254) agendaFail("E-mail de participante inválido.");
        if (structKeyExists(seen,lCase(email))) continue;
        seen[lCase(email)]=true;
        var attendee={"email"=lCase(email)};
        if (structKeyExists(current,"attendees")) for(var previous in current.attendees) if (compareNoCase(previous.email,email)==0) attendee=previous;
        arrayAppend(attendees,attendee);
    }
    // An organizer is not an editable guest; retain its entry if a client omits it.
    if (structKeyExists(current,"attendees")) for(var previous in current.attendees) {
        if (structKeyExists(previous,"organizer") && previous.organizer && !structKeyExists(seen,lCase(previous.email))) arrayAppend(attendees,previous);
    }
    if (arrayLen(attendees)>100) agendaFail("Informe até 100 participantes, incluindo o organizador.");
    body["attendees"]=attendees;
    // Optional for legacy clients. Omitting reminders preserves the Google value on updates.
    if (structKeyExists(data,"reminders")) {
        var reminderData=data.reminders;
        if (!isStruct(reminderData) || !structKeyExists(reminderData,"useDefault") || !isBoolean(reminderData.useDefault)) agendaFail("Configuração de lembrete inválida.");
        body["reminders"]={"useDefault"=reminderData.useDefault ? true : false};
        if (!reminderData.useDefault) {
            var overrides=structKeyExists(reminderData,"overrides") ? reminderData.overrides : [];
            if (!isArray(overrides) || arrayLen(overrides)>5) agendaFail("Informe até 5 lembretes.");
            body.reminders["overrides"]=[];
            for (var reminder in overrides) {
                if (!isStruct(reminder) || !structKeyExists(reminder,"method") || !isSimpleValue(reminder.method) || !listFind("popup,email",reminder.method) || !structKeyExists(reminder,"minutes") || !isValid("integer",reminder.minutes) || reminder.minutes<0 || reminder.minutes>40320) agendaFail("Cada lembrete deve usar notificação ou e-mail e ter de 0 a 40.320 minutos.");
                arrayAppend(body.reminders.overrides,{"method"=reminder.method,"minutes"=int(reminder.minutes)});
            }
        }
    }
    if (!len(eventId)) {
        if (!listFind("none,DAILY,WEEKLY,MONTHLY",data.repeat)) agendaFail("Repetição inválida.");
        if (data.repeat!="none") {
            if (!structKeyExists(data,"count") || !isValid("integer",data.count) || data.count<2 || data.count>52) agendaFail("Informe de 2 a 52 ocorrências.");
            body["recurrence"]=["RRULE:FREQ=" & data.repeat & ";COUNT=" & int(data.count)];
        }
    }
    var cardId=agendaInput("card_id"); var card={};
    var requestId=agendaInput("request_id");
    if (!len(eventId)) {
        if (!reFind("^[a-zA-Z0-9-]{16,64}$",requestId)) agendaFail("Reabra o formulário para criar o evento.");
        if (len(cardId)) {
            card=agendaCard(cardId);
            q=agendaDb("SELECT calendar_id,event_id FROM public.tb_google_agenda_cartoes WHERE card_id=:id",{id=agendaParam(cardId)});
            if (q.recordCount && q.calendar_id!=calendarId) agendaFail("Este cartão está vinculado a outra agenda. Abra-o pelo Kanban.");
            requestId="trello-" & cardId;
            body["source"]={"title"="Cartão no Trello","url"=card.url};
        }
        eventId=lCase(hash(c.email & ":" & agendaInput("request_id"),"SHA-256"));
        if (len(cardId) && q.recordCount) eventId=q.event_id;
        body["id"]=eventId;
        body["extendedProperties"]={"private"={"runnerhubRequest"=requestId}};
        if (len(cardId)) body["extendedProperties"]["private"]["runnerhubCard"]=cardId;
    }
    var creating=!structCount(current);
    var audit=agendaAudit(creating ? "create" : "update",calendarId,eventId);
    try {
        if (creating) {
            // Reserve the card link before the remote write: retries use the same event ID even after an uncertain response.
            if (len(cardId)) agendaDb("INSERT INTO public.tb_google_agenda_cartoes(card_id,calendar_id,event_id) VALUES(:card,:calendar,:event) ON CONFLICT(card_id) DO NOTHING",{card=agendaParam(cardId),calendar=agendaParam(calendarId),event=agendaParam(eventId)});
            r=agendaGoogle(agendaEventPath(calendarId),"POST",{"sendUpdates"=updates},body,"",true);
            if (structKeyExists(r,"conflict")) {
                r=agendaGoogle(agendaEventPath(calendarId,eventId));
                if (!structKeyExists(r,"extendedProperties") || !structKeyExists(r.extendedProperties,"private") || !structKeyExists(r.extendedProperties["private"],"runnerhubRequest") || r.extendedProperties["private"].runnerhubRequest!=requestId) agendaFail("Conflito de identificador. Reabra o formulário.");
            }
        } else {
            // GET + conditional PUT preserves unedited fields and replaces date/dateTime objects completely.
            structAppend(current,body,true);
            for (var readOnly in ["kind","etag","id","created","updated","htmlLink","iCalUID","creator","organizer","recurringEventId","originalStartTime","locked","hangoutLink"]) structDelete(current,readOnly);
            r=agendaGoogle(agendaEventPath(calendarId,eventId),"PUT",{"sendUpdates"=updates,"conferenceDataVersion"=1},current,etag);
        }
        agendaAuditEnd(audit,"success");
    } catch(any saveError) { agendaAuditEnd(audit,"failed"); rethrow; }
    return {"event"=r,"message"="Compromisso salvo."};
}
try {
function check(required boolean condition,required string message) { if(!arguments.condition) throw(message=arguments.message); }
function rejects(required any callback, required string expectedText) {
    var rejected=false;
    try { arguments.callback(); } catch(any e) { rejected=findNoCase(arguments.expectedText,e.message)>0; }
    check(rejected,"Expected rejection: " & arguments.expectedText);
}
// These are disposable test credentials. No Google or production database calls are made.
variables.testConfig={CLIENT_ID="test",CLIENT_SECRET="test",TOKEN_KEY=generateSecretKey("AES",256),email="contato@runnerhub.run"};
variables.agendaConfig=function(){return variables.testConfig;};
variables.sealed=agendaSeal("disposable-refresh-token");
check(agendaUnseal(sealed)=="disposable-refresh-token","Token round trip");
check(agendaSeal("disposable-refresh-token")!=sealed,"Encryption must use a fresh IV");
rejects(function(){agendaUnseal("A" & mid(sealed,2,len(sealed)-1));},"inválido");
variables.testConfig.TOKEN_KEY=generateSecretKey("AES",256);
rejects(function(){agendaUnseal(sealed);},"inválido");
check(find("%40",agendaEventPath("owner@example.com","abc_123"))>0,"Calendar ID encoding");
rejects(function(){agendaEventPath("calendar","../other");},"inválido");
// Replace external boundaries, exercising actual dispatch validation and event payload construction.
variables.agendaMutation=function(){};
variables.agendaReady=function(){return true;};
variables.agendaAccessToken=function(boolean force=false){return "test-access";};
variables.agendaCalendar=function(required string id){return {accessRole="owner"};};
variables.agendaAudit=function(required string action,string calendarId="",string eventId=""){return 1;};
variables.agendaAuditEnd=function(required numeric id,required string state){};
variables.agendaInput=function(required string key,string fallback=""){return structKeyExists(variables.input,arguments.key)?variables.input[arguments.key]:arguments.fallback;};
variables.calls=[];
variables.remoteEvent={"id"="existing","etag"='"v1"',"summary"="Original","eventType"="default","start"={"date"="2026-09-05"},"end"={"date"="2026-09-06"},"reminders"={"useDefault"=false,"overrides"=[{"method"="popup","minutes"=30}]},"recurrence"=["RRULE:FREQ=WEEKLY;COUNT=4"]};
variables.agendaGoogle=function(required string path,string method="GET",struct params={},struct body={},string etag="",boolean allowConflict=false,boolean allowMissing=false){
    arrayAppend(variables.calls,duplicate(arguments));
    if(arguments.method=="GET")return duplicate(variables.remoteEvent);
    return {"id"="saved"};
};
variables.input={action="save",calendar_id="calendar",request_id="12345678-1234-1234-1234-123456789012",send_updates="none"};
variables.draft={"summary"="Reunião","description"="Texto","location"="Sala","allDay"=false,"start"="2026-09-05T09:00","end"="2026-09-05T10:00","attendees"=[],"repeat"="WEEKLY","count"=4};
variables.input.event=serializeJSON(variables.draft);
agendaDispatch();
check(variables.calls[1].method=="POST","Creation uses POST");
check(variables.calls[1].body.start.dateTime=="2026-09-05T09:00:00-03:00","RFC3339 seconds and São Paulo offset");
check(variables.calls[1].body.recurrence[1]=="RRULE:FREQ=WEEKLY;COUNT=4","New recurrence");
check(reFind("^[0-9a-f]{64}$",variables.calls[1].body.id)>0,"Stable Google-compatible event ID");
variables.calls=[];variables.input.event_id="existing";variables.input.etag='"v1"';agendaDispatch();
check(variables.calls[2].method=="PUT","Updates replace dates using conditional PUT");
check(variables.calls[2].etag=='"v1"',"If-Match preserved");
check(!structKeyExists(variables.calls[2].body.start,"date"),"Old all-day field removed");
check(variables.calls[2].body.reminders.overrides[1].minutes==30,"Unedited reminders preserved");
check(variables.calls[2].body.recurrence[1]=="RRULE:FREQ=WEEKLY;COUNT=4","Series rule preserved");
variables.remoteEvent.start={"dateTime"="2026-09-05T13:00:00+01:00","timeZone"="Europe/Lisbon"};
variables.remoteEvent.end={"dateTime"="2026-09-05T14:00:00+01:00","timeZone"="Europe/Lisbon"};
variables.calls=[];agendaDispatch();
check(variables.calls[2].body.start.timeZone=="Europe/Lisbon","Existing recurrence timezone is preserved");
check(variables.calls[2].body.start.dateTime=="2026-09-05T13:00:00+01:00","Brasília editor converts back to original timezone");
variables.input.etag='"stale"';
rejects(function(){agendaDispatch();},"evento mudou");
variables.input.etag='"v1"';variables.input.send_updates="";
rejects(function(){agendaDispatch();},"notificação");
variables.input.send_updates="all";variables.draft.end="2026-09-05T08:00";variables.input.event=serializeJSON(variables.draft);
rejects(function(){agendaDispatch();},"posterior");
variables.draft.end="2026-09-05T10:00";variables.draft.attendees=["not-an-email"];variables.input.event=serializeJSON(variables.draft);
rejects(function(){agendaDispatch();},"participante inválido");
variables.remoteEvent.attendees=[{"email"="ana@example.com","displayName"="Ana","responseStatus"="accepted","comment"="Confirmo"},{"email"="host@example.com","organizer"=true,"responseStatus"="accepted"}];
variables.remoteEvent.conferenceData={"entryPoints"=[{"entryPointType"="video","uri"="https://meet.google.com/abc-defg-hij"}],"signature"="existing-signature"};
variables.draft.attendees=["ana@example.com","new@example.com"];
variables.draft.reminders={"useDefault"=false,"overrides"=[{"method"="email","minutes"=45}]};
variables.input.event=serializeJSON(variables.draft);variables.calls=[];agendaDispatch();
check(variables.calls[2].body.attendees[1].responseStatus=="accepted","Actual RSVP preserved");
check(variables.calls[2].body.attendees[1].comment=="Confirmo","Guest metadata preserved");
check(!structKeyExists(variables.calls[2].body.attendees[2],"responseStatus"),"New guest cannot be confirmed by operator");
check(arrayLen(variables.calls[2].body.attendees)==3 && variables.calls[2].body.attendees[3].organizer,"Organizer cannot be removed");
check(variables.calls[2].body.reminders.overrides[1].minutes==45,"Explicit reminder edit applied");
check(variables.calls[2].body.conferenceData.signature=="existing-signature","Meeting data preserved");
variables.draft.reminders.overrides[1].minutes=40321;variables.input.event=serializeJSON(variables.draft);
rejects(function(){agendaDispatch();},"lembrete");
variables.draft.reminders.overrides[1].minutes=1.5;variables.input.event=serializeJSON(variables.draft);
rejects(function(){agendaDispatch();},"lembrete");
variables.draft.reminders.overrides[1].minutes=10;variables.draft.reminders.overrides[1].method="sms";variables.input.event=serializeJSON(variables.draft);
rejects(function(){agendaDispatch();},"lembrete");
variables.draft.reminders={"useDefault"=true};variables.input.event=serializeJSON(variables.draft);variables.calls=[];agendaDispatch();
check(variables.calls[2].body.reminders.useDefault && !structKeyExists(variables.calls[2].body.reminders,"overrides"),"Default reminders replace custom ones");

cfcontent(type="application/json; charset=utf-8",reset=true);writeOutput(serializeJSON({ok=true,engine="Adobe ColdFusion",externalWrites=0}));
} catch(any testError) {cfheader(statuscode=500);cfcontent(type="application/json; charset=utf-8",reset=true);writeOutput(serializeJSON({ok=false,message=testError.message,detail=testError.detail}));}
</cfscript>
