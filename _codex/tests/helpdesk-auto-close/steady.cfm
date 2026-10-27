<cfscript>
q=queryExecute("UPDATE tb_cron_jobs SET request_body='{""limit"":50}',data_atualizacao=(now() AT TIME ZONE 'UTC') WHERE endpoint_url='https://business.roadrunners.run/api/helpdesk/auto-close.cfm' AND ativo AND last_status='success' AND request_body::jsonb->>'limit'='100' RETURNING id_cron_job",{},{datasource='runner_dba'});
if(q.recordCount NEQ 1)throw(message='Successful initial cycle required before steady batch');
writeOutput('HELPDESK_CLOSE_STEADY_PASSED batch=50 interval=15min');
</cfscript>
