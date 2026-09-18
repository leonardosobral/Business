<cfscript>
function mailFail(required string message) { throw(type="AIMail.Validation",message=arguments.message); }
function mailInt(required any value) { return {value=val(arguments.value),cfsqltype="cf_sql_bigint"}; }
function mailBool(required any value) { return {value=arguments.value,cfsqltype="cf_sql_bit"}; }
function mailWire(required any value) {
    if (isStruct(arguments.value)) { var obj=structNew("ordered"); for(var key in arguments.value) {var wireKey=compareNoCase(key,"additionalProperties")==0?"additionalProperties":lCase(key);obj[wireKey]=isNull(arguments.value[key])?"":mailWire(arguments.value[key]);} return obj; }
    if (isArray(arguments.value)) { var arr=[]; for(var item in arguments.value) arrayAppend(arr,mailWire(item)); return arr; }
    return arguments.value;
}
function mailRows(required query q) { var rows=[]; for(var row in arguments.q) arrayAppend(rows,deserializeJSON(row.data&"")); return rows; }
function mailReady() { return agendaDb("SELECT to_regclass('public.tb_ai_mail_config') IS NOT NULL AS ready").ready; }
function mailConfig() { return mailRows(agendaDb("SELECT to_jsonb(c) AS data FROM public.tb_ai_mail_config c WHERE id=1"))[1]; }
function mailAuthorized() {
    var q=agendaDb("SELECT email,scopes FROM public.tb_google_agenda_conexao WHERE id=1");
    return q.recordCount && compareNoCase(q.email,"contato@runnerhub.run")==0 && listFind(q.scopes,"https://www.googleapis.com/auth/gmail.readonly"," ")>0;
}
function mailAudit(required string action,string threadId="",numeric actor=0,string actorName="") {
    agendaDb("INSERT INTO public.tb_ai_mail_audit(thread_id,actor_id,actor_name,action) VALUES(:t,:a,:n,:op)",{t=agendaParam(arguments.threadId),a=mailInt(arguments.actor),n=agendaParam(left(arguments.actorName,200)),op=agendaParam(left(arguments.action,200))});
}
function mailEnqueue(required string threadId,boolean force=false) {
    if (!reFind("^[a-zA-Z0-9_-]{1,100}$",arguments.threadId)) return;
    agendaDb("INSERT INTO public.tb_ai_mail_queue(thread_id,force_analysis) VALUES(:id,:force) ON CONFLICT(thread_id) DO UPDATE SET revision=tb_ai_mail_queue.revision+1,available_at=now(),attempts=0,last_error='',force_analysis=tb_ai_mail_queue.force_analysis OR EXCLUDED.force_analysis",{id=agendaParam(arguments.threadId),force=mailBool(arguments.force)});
}
function mailGoogle(required string path,struct params={},boolean missing=false) {
    var token="";
    lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="30" { token=agendaAccessToken(); }
    var r=agendaHttp("https://gmail.googleapis.com/gmail/v1/users/me"&arguments.path,"GET",arguments.params,{},token);
    if(r.status==401) {
        lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="30" { token=agendaAccessToken(true); }
        r=agendaHttp("https://gmail.googleapis.com/gmail/v1/users/me"&arguments.path,"GET",arguments.params,{},token);
    }
    if(r.status==404 && arguments.missing) return {missing=true};
    if(r.status==403) mailFail("Gmail sem acesso: habilite a Gmail API e autorize a leitura da conta.");
    if(r.status<200 || r.status>=300) mailFail("Consulta Gmail indisponível (HTTP "&r.status&"). Uma nova tentativa será agendada.");
    return r.data;
}
function mailMutation() {
    if(CGI.REQUEST_METHOD!="POST" || !structKeyExists(session,"aiMailCsrf") || !structKeyExists(form,"csrf_token") || compare(form.csrf_token,session.aiMailCsrf)!=0) {
        throw(type="AIMail.Forbidden",message="Sessão expirada. Recarregue a página.");
    }
}
function mailStatus() {
    var cfg=mailConfig();
    var q=agendaDb("SELECT count(*) FILTER(WHERE state<>'resolved' AND source_available AND (relevant OR needs_review))::int AS pending,count(*) FILTER(WHERE state<>'resolved' AND source_available AND priority IN('critical','high'))::int AS urgent,count(*) FILTER(WHERE state<>'resolved' AND source_available AND needs_response)::int AS response,count(*) FILTER(WHERE state<>'resolved' AND source_available AND deadline_at<now())::int AS overdue FROM public.tb_ai_mail_threads");
    var queue=agendaDb("SELECT count(*)::int AS total,count(*) FILTER(WHERE last_error<>'')::int AS errors FROM public.tb_ai_mail_queue");
    var usage=agendaDb("SELECT count(*)::int AS total,coalesce(sum(input_tokens),0) AS input,coalesce(sum(output_tokens),0) AS output FROM public.tb_ai_mail_usage WHERE (created_at AT TIME ZONE 'America/Sao_Paulo')::date=(now() AT TIME ZONE 'America/Sao_Paulo')::date");
    // Reference price checked 2026-09-17. Text only, without cache discounts/RAG fees.
    var cost=agendaDb("SELECT coalesce(sum(CASE WHEN model IN('gpt-4.1-mini','gpt-4.1-mini-2025-04-14') THEN (input_tokens*0.40+output_tokens*1.60)/1000000.0 ELSE 0 END),0) AS usd,count(*) FILTER(WHERE model NOT IN('gpt-4.1-mini','gpt-4.1-mini-2025-04-14') OR status IN('reserved','failed')) AS uncertain FROM public.tb_ai_mail_usage WHERE (created_at AT TIME ZONE 'America/Sao_Paulo')::date=(now() AT TIME ZONE 'America/Sao_Paulo')::date");
    var actors=mailRows(agendaDb("SELECT json_build_object('id',id,'name',name) AS data FROM public.tb_usuarios WHERE is_admin=true ORDER BY name"));
    var jobs=mailRows(agendaDb("SELECT json_build_object('name',nome,'active',ativo,'last_run',last_run_at,'status',last_status) AS data FROM public.tb_cron_jobs WHERE endpoint_url IN ('https://business.roadrunners.run/administracao/ai-mails/jobs/collect.cfm','https://business.roadrunners.run/administracao/ai-mails/jobs/process.cfm') ORDER BY id_cron_job"));
    return mailWire({connected=mailAuthorized(),ai_configured=structKeyExists(application,"vickyKnowledge") && application.vickyKnowledge.configured,config={enabled=cfg.enabled,email=cfg.email,model=cfg.model,initial_days=cfg.initial_days,daily_limit=cfg.daily_limit,retention_days=cfg.retention_days,initial_complete=cfg.initial_complete,collected=cfg.collected,last_sync_at=structKeyExists(cfg,"last_sync_at")?cfg.last_sync_at:"",last_error=cfg.last_error},metrics={pending=q.pending,urgent=q.urgent,response=q.response,overdue=q.overdue},queue={total=queue.total,errors=queue.errors},usage={total=usage.total,input_tokens=usage.input,output_tokens=usage.output,limited=usage.total>=cfg.daily_limit,estimated_usd=val(cost.usd),estimate_incomplete=cost.uncertain>0},actors=actors,jobs=jobs});
}
function mailList(required struct filters) {
    var p={}; var where=" WHERE true ";
    var view=structKeyExists(arguments.filters,"view")?arguments.filters.view:"pending";
    if(view=="review") where&=" AND (NOT t.relevant OR t.needs_review OR NOT t.source_available) ";
    else if(view=="resolved") where&=" AND t.state='resolved' ";
    else if(view=="in_progress") where&=" AND t.state='in_progress' AND t.source_available AND (t.relevant OR t.needs_review) ";
    else where&=" AND t.state<>'resolved' AND t.source_available AND (t.relevant OR t.needs_review) ";
    for(var field in ["priority","category","state"]) if(structKeyExists(arguments.filters,field) && len(arguments.filters[field])) {
        where&=" AND t."&field&"=:"&field; p[field]=agendaParam(left(arguments.filters[field],80));
    }
    if(structKeyExists(arguments.filters,"assignee") && len(arguments.filters.assignee)) {
        if(arguments.filters.assignee=="none") where&=" AND t.assignee_id IS NULL";
        else { where&=" AND t.assignee_id=:assignee"; p.assignee=mailInt(arguments.filters.assignee); }
    }
    if(structKeyExists(arguments.filters,"attention")) {
        if(arguments.filters.attention=="response") where&=" AND t.needs_response";
        if(arguments.filters.attention=="urgent") where&=" AND t.priority IN('critical','high')";
        if(arguments.filters.attention=="overdue") where&=" AND t.deadline_at<now()";
        if(arguments.filters.attention=="action") where&=" AND jsonb_array_length(t.actions)>0";
    }
    if(structKeyExists(arguments.filters,"search") && len(trim(arguments.filters.search))) {where&=" AND (t.subject ILIKE :search OR t.sender ILIKE :search OR t.summary ILIKE :search)"; p.search=agendaParam("%"&left(trim(arguments.filters.search),100)&"%");}
    if(structKeyExists(arguments.filters,"days") && val(arguments.filters.days)>0) {where&=" AND t.last_message_at>=now()-(:days*interval '1 day')";p.days=mailInt(min(365,val(arguments.filters.days)));}
    var count=agendaDb("SELECT count(*) AS total FROM public.tb_ai_mail_threads t"&where,p).total;
    p.offset=mailInt(structKeyExists(arguments.filters,"offset")?max(0,min(100000,val(arguments.filters.offset))):0);
    var rows=mailRows(agendaDb("SELECT to_jsonb(v) AS data FROM (SELECT t.*,EXISTS(SELECT 1 FROM public.tb_ai_mail_queue q WHERE q.thread_id=t.thread_id) AS queued FROM public.tb_ai_mail_threads t"&where&" ORDER BY CASE t.priority WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'informational' THEN 3 ELSE 4 END,t.deadline_at NULLS LAST,t.last_message_at ASC NULLS LAST,t.id LIMIT 30 OFFSET :offset) v",p));
    return {items=rows,total=count};
}
function mailUpdate(required string action,required numeric id,required numeric version,required numeric actor,required string actorName) {
    var thread=agendaDb("SELECT * FROM public.tb_ai_mail_threads WHERE id=:id",{id=mailInt(arguments.id)});
    if(!thread.recordCount) mailFail("Conversa não encontrada.");
    var p={id=mailInt(arguments.id),v=mailInt(arguments.version),actor=mailInt(arguments.actor),name=agendaParam(left(arguments.actorName,200))};
    var sql="";
    if(arguments.action=="resolve") sql="state='resolved',resolved_at=now(),resolved_by=:actor,resolved_inbound_ms=last_inbound_ms";
    else if(arguments.action=="reopen") sql="state='pending',resolved_at=NULL,resolved_by=NULL";
    else if(arguments.action=="assign") {
        var assignee=val(agendaInput("assignee_id",arguments.actor&""));
        if(assignee>0) {
            var user=agendaDb("SELECT id,name FROM public.tb_usuarios WHERE id=:id AND is_admin=true",{id=mailInt(assignee)});
            if(!user.recordCount) mailFail("Selecione um administrador global.");
            p.actor=mailInt(user.id); p.name=agendaParam(user.name);
            sql="assignee_id=:actor,assignee_name=:name,state=CASE WHEN state='pending' THEN 'in_progress' ELSE state END";
        } else sql="assignee_id=NULL,assignee_name=''";
    } else if(arguments.action=="note") { sql="note=:note"; p.note=agendaParam(left(agendaInput("note"),4000)); }
    else if(arguments.action=="classify") {
        var priority=agendaInput("priority"); if(!listFind("critical,high,normal,informational,low",priority)) mailFail("Prioridade inválida.");
        sql="priority=:priority,relevant=:relevant,needs_review=false,manual_priority=true";
        p.priority=agendaParam(priority);p.relevant=mailBool(priority!="low");
    } else if(arguments.action=="reanalyze") sql="needs_review=true";
    else mailFail("Operação inválida.");
    transaction {
        var changed=agendaDb("UPDATE public.tb_ai_mail_threads SET "&sql&",version=version+1,updated_at=now() WHERE id=:id AND version=:v RETURNING thread_id",p);
        if(!changed.recordCount) throw(type="AIMail.Conflict",message="Outro atendente atualizou a conversa. Reabra o detalhe para continuar.");
        mailAudit(arguments.action,changed.thread_id,arguments.actor,arguments.actorName);
        if(arguments.action=="reanalyze") mailEnqueue(changed.thread_id,true);
    }
    return {message="Conversa atualizada."};
}
function mailSafeError(required any error) {
    return listFindNoCase("AIMail.Validation,AIMail.Provider,Agenda.Validation,AIMail.Conflict",arguments.error.type)?left(arguments.error.message,250):"Falha temporária no processamento. Consulte o histórico operacional e tente novamente.";
}
function mailOAuth() {
    var c=agendaConfig(); var state=agendaRandom(); var verifier=agendaRandom()&agendaRandom();
    session.agendaOAuth={state=state,verifier=verifier,actor=val(qPerfil.id),expires=dateAdd("n",10,now()),aiMails=true};
    var challenge=replace(replace(replace(toBase64(binaryDecode(hash(verifier,"SHA-256"),"hex")),"+","-","all"),"/","_","all"),"=","","all");
    var args={"client_id"=c.CLIENT_ID,"redirect_uri"=c.redirectUri,"response_type"="code","scope"=c.scopes&" https://www.googleapis.com/auth/gmail.readonly","include_granted_scopes"="true","access_type"="offline","prompt"="consent select_account","login_hint"=c.email,"state"=state,"code_challenge"=challenge,"code_challenge_method"="S256"};
    var pairs=[];for(var key in args) arrayAppend(pairs,encodeForURL(key)&"="&encodeForURL(args[key]));
    return {url="https://accounts.google.com/o/oauth2/v2/auth?"&arrayToList(pairs,"&")};
}
</cfscript>
