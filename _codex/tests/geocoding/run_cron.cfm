<cfinclude template="/includes/backend/cron_jobs_service.cfm">
<cfscript>
result=cronJobsRunJob(25,"manual",0);
writeOutput(serializeJSON(result) & chr(10));
if(!result.success AND result.status NEQ "skipped")throw(type="Test.Failed",message="Cron execution did not confirm success");
writeOutput("GEO_RUN_CRON_PASSED");
</cfscript>
