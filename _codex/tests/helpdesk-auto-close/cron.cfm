<cfscript>
include '../includes/backend/cron_jobs_service.cfm';
APPLICATION.cronJobs={runnerToken='synthetic-scheduler-secret'};
if(cronJobsGetSecret('business_helpdesk_auto_close') NEQ 'synthetic-scheduler-secret')throw(type='Test.Failed',message='Alias do job não resolve identidade já configurada do scheduler');
if(cronJobsGetSecret('business_ai_mails') NEQ 'synthetic-scheduler-secret')throw(type='Test.Failed',message='Alias antigo alterado indevidamente');
writeOutput('HELPDESK_CLOSE_CRON_PASSED');
</cfscript>
