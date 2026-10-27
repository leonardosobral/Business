<cfscript>
queryExecute(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & 'install.sql'),{},{datasource='runner_dba'});
q=queryExecute("SELECT id_cron_job,ativo,interval_minutes,auth_mode,secret_ref FROM tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/api/helpdesk/auto-close.cfm'",{},{datasource='runner_dba'});
if(q.recordCount NEQ 1 OR q.ativo OR q.interval_minutes NEQ 15 OR q.auth_mode NEQ 'bearer' OR q.secret_ref NEQ 'business_helpdesk_auto_close')throw(message='Job install mismatch');
writeOutput('HELPDESK_CLOSE_INSTALL_PASSED ' & serializeJSON(q));
</cfscript>
