<cfscript>
transaction {
 job=queryExecute("SELECT id_cron_job FROM tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/helpdesk/auto-close.cfm' AND ativo=false AND auth_mode='bearer' AND secret_ref='business_helpdesk_auto_close' FOR UPDATE",{},{datasource='runner_dba'});
 if(job.recordCount NEQ 1)throw(message='Expected exactly one verified inactive job');
 service=createObject('component','services' & '.HelpdeskAutoClose');
 before=queryExecute(service.candidatesSql(false),{limit={value=100,cfsqltype='cf_sql_integer'},message={value=service.message(),cfsqltype='cf_sql_longvarchar'}},{datasource='runner_dba'});
 // Private root-only fixture archive retains pre-close statuses/message ids.
 writeOutput('BEFORE ' & serializeJSON(before) & chr(10));
 queryExecute("UPDATE tb_cron_jobs SET ativo=true,request_body='{""limit"":100}',next_run_at=(now() AT TIME ZONE 'UTC'),data_atualizacao=(now() AT TIME ZONE 'UTC') WHERE id_cron_job=:id",{id={value=job.id_cron_job,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
}
writeOutput('HELPDESK_CLOSE_ACTIVATE_PASSED job=' & job.id_cron_job & ' eligible=' & before.recordCount & '; only scheduler activated, worker not called');
</cfscript>
