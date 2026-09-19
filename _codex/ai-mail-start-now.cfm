<cfsetting showdebugoutput="false" requesttimeout="180"/>
<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "POST"><cfheader statuscode="404"/><cfabort/></cfif>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfinclude template="../administracao/agenda/includes/service.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/service.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/sync.cfm"/>
<cfinclude template="../administracao/ai-mails/includes/ai.cfm"/>
<cfinclude template="tests/ai-mails-service.cfm"/>
<cfscript>
try {
    action=structKeyExists(url,"action")?url.action:"status";
    if(action=="migrate") {
        agendaDb(fileRead(expandPath("/administracao/ai-mails/ai_mails_schema.sql")));
        result={message="Migração aditiva aplicada."};
    } else if(action=="prepare") {
        transaction {
            agendaDb("UPDATE public.tb_ai_mail_config SET enabled=false,next_attempt_at=now(),updated_at=now() WHERE id=1");
            agendaDb("UPDATE public.tb_cron_jobs SET ativo=false WHERE endpoint_url IN ('https://business.roadrunners.run/administracao/ai-mails/jobs/collect.cfm','https://business.roadrunners.run/administracao/ai-mails/jobs/process.cfm')");
        }
        leases=agendaDb("SELECT count(*) FILTER(WHERE lease_until>now())::int AS queue_active,(SELECT CASE WHEN collector_lease>now() THEN 1 ELSE 0 END FROM public.tb_ai_mail_config WHERE id=1)::int AS collector_active FROM public.tb_ai_mail_queue");
        result={message="Monitor pausado para concluir somente o que já estava em processamento.",queue_active=leases.queue_active,collector_active=leases.collector_active};
    } else if(action=="apply") {
        leases=agendaDb("SELECT count(*) FILTER(WHERE lease_until>now())::int AS queue_active,(SELECT CASE WHEN collector_lease>now() THEN 1 ELSE 0 END FROM public.tb_ai_mail_config WHERE id=1)::int AS collector_active FROM public.tb_ai_mail_queue");
        if(leases.queue_active>0 || leases.collector_active>0) throw(type="AIMail.Conflict",message="Ainda há uma execução iniciada antes do corte. Aguarde e repita.");
        profile=mailGoogle("/profile");cfg=mailConfig();
        if(compareNoCase(profile.emailAddress,cfg.email)!=0) mailFail("A conta conectada não corresponde à caixa configurada.");
        cutoffMs=createObject("java","java.lang.System").currentTimeMillis();
        before=agendaDb("SELECT count(*)::int AS queued FROM public.tb_ai_mail_queue").queued;
        analyzed=agendaDb("SELECT count(*) FILTER(WHERE analyzed_at IS NOT NULL)::int AS analyzed FROM public.tb_ai_mail_threads").analyzed;
        transaction {
            agendaDb("DELETE FROM public.tb_ai_mail_queue");
            agendaDb("UPDATE public.tb_ai_mail_config SET enabled=true,monitor_since_ms=:cutoff,history_id=:history,initial_history=:history,page_token='',initial_query='',initial_complete=true,collected=0,last_sync_at=now(),last_error='',failures=0,next_attempt_at=now(),collector_lease=NULL,collector_token='',updated_at=now() WHERE id=1",{cutoff=mailInt(cutoffMs),history=agendaParam(profile.historyId&"")});
            agendaDb("UPDATE public.tb_cron_jobs SET ativo=true,next_run_at=now() WHERE endpoint_url IN ('https://business.roadrunners.run/administracao/ai-mails/jobs/collect.cfm','https://business.roadrunners.run/administracao/ai-mails/jobs/process.cfm')");
            mailAudit("monitor_rebased_now","",0,"Operação de publicação");
        }
        result={message="Corte aplicado. Somente novas mensagens serão analisadas.",discarded_queue=before,preserved_analyzed=analyzed,monitor_since_ms=cutoffMs,history_id=profile.historyId&""};
    } else if(action=="test") {
        realGoogle=variables.mailGoogle;realAnalyze=variables.mailAnalyze;realAuthorized=variables.mailAuthorized;mode="old";
        variables.mailAuthorized=function(){return true;};
        variables.mailGoogle=function(path,params={},missing=false){
            if(path=="/threads/fixtureold") return {messages=[mailFixtureMessage("oldmsg","Mensagem anterior ao corte.",1700000000000)]};
            if(path=="/threads/fixturenew") {m=mailFixtureMessage("newmsg","Mensagem posterior ao corte.",1700000060000);m.threadId="fixturenew";return {messages=[m]};}
            return {missing=true};
        };
        variables.mailAnalyze=function(context,previous,cfg){var a=duplicate(analysis);a.source_message_id="newmsg";a.warnings=[];a.sources=[];return a;};
        transaction {
            agendaDb("UPDATE public.tb_ai_mail_config SET enabled=true,monitor_since_ms=1700000030000 WHERE id=1");
            agendaDb("DELETE FROM public.tb_ai_mail_queue");
            mailEnqueue("fixtureold");oldResult=mailProcessOne();
            mailAssert(oldResult.processed==0 && !agendaDb("SELECT 1 FROM public.tb_ai_mail_threads WHERE thread_id='fixtureold'").recordCount && !agendaDb("SELECT 1 FROM public.tb_ai_mail_queue WHERE thread_id='fixtureold'").recordCount,"Mensagem anterior ao corte é descartada sem análise");
            mailEnqueue("fixturenew");newResult=mailProcessOne();
            mailAssert(newResult.processed==1 && agendaDb("SELECT 1 FROM public.tb_ai_mail_threads WHERE thread_id='fixturenew' AND analyzed_at IS NOT NULL").recordCount==1,"Mensagem posterior ao corte continua sendo analisada");
            transaction action="rollback";
        }
        variables.mailGoogle=realGoogle;variables.mailAnalyze=realAnalyze;variables.mailAuthorized=realAuthorized;
        result={message="Regressão temporal validada.",tests=mailTests};
    } else {
        cfg=mailConfig();leases=agendaDb("SELECT count(*)::int AS queued,count(*) FILTER(WHERE lease_until>now())::int AS queue_active FROM public.tb_ai_mail_queue");
        jobs=agendaDb("SELECT count(*) FILTER(WHERE ativo)::int AS active FROM public.tb_cron_jobs WHERE endpoint_url IN ('https://business.roadrunners.run/administracao/ai-mails/jobs/collect.cfm','https://business.roadrunners.run/administracao/ai-mails/jobs/process.cfm')");
        batchStats=agendaDb("SELECT count(*)::int AS total,count(*) FILTER(WHERE state='open')::int AS open,count(*) FILTER(WHERE state='in_progress')::int AS in_progress,count(*) FILTER(WHERE state='resolved')::int AS resolved,(SELECT count(*)::int FROM public.tb_ai_mail_batch_items) AS items FROM public.tb_ai_mail_batches");
        result={enabled=cfg.enabled,monitor_since_ms=cfg.monitor_since_ms,history_id=cfg.history_id,queued=leases.queued,queue_active=leases.queue_active,jobs_active=jobs.active,batches={total=batchStats.total,open=batchStats.open,in_progress=batchStats.in_progress,resolved=batchStats.resolved,items=batchStats.items}};
    }
    result.success=true;writeOutput(serializeJSON(mailWire(result)));
} catch(any error) {
    if(isDefined("realGoogle")){variables.mailGoogle=realGoogle;variables.mailAnalyze=realAnalyze;variables.mailAuthorized=realAuthorized;}
    cfheader(statuscode=error.type=="AIMail.Conflict"?409:500);
    writeOutput(serializeJSON(mailWire({success=false,type=error.type,message=mailSafeError(error),detail=error.detail,line=arrayLen(error.tagContext)?error.tagContext[1].line:0})));
}
</cfscript>
