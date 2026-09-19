<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="110"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../agenda/includes/service.cfm"/>
<cfinclude template="includes/service.cfm"/>
<cfinclude template="includes/sync.cfm"/>
<cfinclude template="includes/ai.cfm"/>
<cfinclude template="includes/batch.cfm"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    mailMutation();
    if(!mailReady()) mailFail("AI-mails em preparação. A estrutura de dados ainda não foi instalada.");
    varAction=agendaInput("action");result={};
    switch(varAction) {
        case "status": result=mailStatus();break;
        case "list": result=mailList(form);break;
        case "batches": result=mailBatchList(form);break;
        case "batch_detail": result=mailBatchDetail(val(agendaInput("id")));break;
        case "batch_create":
            result=mailBatchCreate(agendaInput("thread_ids"),agendaInput("title"),agendaInput("instruction"),val(qPerfil.id),qPerfil.name);break;
        case "detail":
            rows=mailRows(agendaDb("SELECT to_jsonb(t) AS data FROM public.tb_ai_mail_threads t WHERE id=:id",{id=mailInt(agendaInput("id"))}));
            if(!arrayLen(rows)) mailFail("Conversa não encontrada.");
            history=mailRows(agendaDb("SELECT to_jsonb(a) AS data FROM (SELECT action,actor_name,created_at FROM public.tb_ai_mail_audit WHERE thread_id=:t ORDER BY id DESC LIMIT 30) a",{t=agendaParam(rows[1].thread_id)}));
            result={item=rows[1],history=history};break;
        case "connect":
            lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="10" {result=mailOAuth();}break;
        case "refresh":
            if(!mailAuthorized()) mailFail("Autorize primeiro a leitura do Gmail.");
            agendaDb("UPDATE public.tb_ai_mail_config SET next_attempt_at=now() WHERE id=1");
            agendaDb("UPDATE public.tb_ai_mail_queue SET available_at=now(),attempts=0,last_error='' WHERE lease_until IS NULL OR lease_until<now()");
            agendaDb("UPDATE public.tb_cron_jobs SET next_run_at=now() WHERE endpoint_url IN ('https://business.roadrunners.run/administracao/ai-mails/jobs/collect.cfm','https://business.roadrunners.run/administracao/ai-mails/jobs/process.cfm')");
            result={message="Coleta agendada para a próxima passagem do monitor. A tela será atualizada automaticamente."};break;
        case "settings":
            enabled=agendaInput("enabled")=="true";
            if(enabled && (!mailAuthorized() || agendaInput("consent")!="true")) mailFail("Autorize o Gmail e confirme o processamento das mensagens pela IA.");
            model=trim(agendaInput("model","gpt-4.1-mini"));
            if(!reFind("^[A-Za-z0-9._-]{1,100}$",model)) mailFail("Modelo inválido.");
            daily=val(agendaInput("daily_limit","100"));retention=val(agendaInput("retention_days","90"));
            if(daily<1 || daily>2000 || retention<7 || retention>365) mailFail("Confira os limites das configurações.");
            transaction {
                cfg=mailConfig();
                agendaDb("UPDATE public.tb_ai_mail_config SET enabled=:enabled,model=:model,daily_limit=:daily,retention_days=:retention,consent_at=CASE WHEN :enabled THEN now() ELSE consent_at END,consent_by=CASE WHEN :enabled THEN :actor ELSE consent_by END,next_attempt_at=now(),updated_at=now() WHERE id=1",{enabled=mailBool(enabled),model=agendaParam(model),daily=mailInt(daily),retention=mailInt(retention),actor=mailInt(qPerfil.id)});
                mailAudit(enabled?"monitor_enabled":"monitor_paused","",val(qPerfil.id),qPerfil.name);
            }
            result={message=enabled?"Monitor ativado. A coleta será executada pelo servidor a cada cinco minutos.":"Monitoramento pausado. As decisões existentes foram preservadas."};break;
        case "resolve":case "reopen":case "assign":case "note":case "classify":case "reanalyze":
            result=mailUpdate(varAction,val(agendaInput("id")),val(agendaInput("version")),val(qPerfil.id),qPerfil.name);break;
        case "batch_assign":case "batch_classify":case "batch_note":case "batch_start":case "batch_resolve":case "batch_reopen":
            result=mailBatchUpdate(varAction,val(agendaInput("id")),val(agendaInput("version")),val(qPerfil.id),qPerfil.name);break;
        default: mailFail("Operação não reconhecida.");
    }
    result.success=true;writeOutput(serializeJSON(mailWire(result)));
} catch(any error) {
    cfheader(statuscode=error.type=="AIMail.Conflict"?409:(error.type=="AIMail.Forbidden"?403:400));
    writeOutput(serializeJSON(mailWire({success=false,message=mailSafeError(error)})));
}
</cfscript>
