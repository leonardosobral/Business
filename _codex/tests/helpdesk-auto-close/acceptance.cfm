<cfscript>
q=queryExecute("SELECT j.id_cron_job,j.ativo,j.interval_minutes,j.last_status,j.last_run_at,r.http_status,r.response_preview FROM tb_cron_jobs j LEFT JOIN LATERAL(SELECT http_status,response_preview FROM tb_cron_job_runs WHERE id_cron_job=j.id_cron_job ORDER BY id_cron_job_run DESC LIMIT 1)r ON true WHERE j.endpoint_url='https://business.roadrunners.run/api/helpdesk/auto-close.cfm'",{},{datasource='runner_dba'});writeOutput('JOB ' & serializeJSON(q));
q=queryExecute("SELECT c.id_chamado,c.status,m.created_at,(m.mensagem=:message) AS automatic FROM tb_helpdesk_chamados c LEFT JOIN LATERAL(SELECT mensagem,created_at FROM tb_helpdesk_mensagens WHERE id_chamado=c.id_chamado AND NOT interno ORDER BY created_at DESC,id_mensagem DESC LIMIT 1)m ON true WHERE c.id_chamado=121",{message={value=createObject('component','services' & '.HelpdeskAutoClose').message(),cfsqltype='cf_sql_longvarchar'}},{datasource='runner_dba'});writeOutput('EXAMPLE ' & serializeJSON(q));
if(createObject('component','services' & '.geocoding.Store').settings().enabled)throw(message='Geolocalização deve permanecer pausada');
writeOutput('HELPDESK_CLOSE_ACCEPTANCE_PASSED');
</cfscript>
