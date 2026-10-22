<cfinclude template="../includes/backend/cron_jobs_service.cfm">
<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
endpoint="https://business.roadrunners.run/api/eventos/geolocalizar.cfm";
nextTick=cronJobsNextRunAt(endpoint,1,createDateTime(2026,10,18,14,10,42));
check(dateCompare(nextTick,createDateTime(2026,10,18,14,10,59)) LTE 0 AND dateCompare(nextTick,createDateTime(2026,10,18,14,10,42)) GT 0,"Geolocation is due at the next runner tick despite subsecond web/database clock drift");
check(dateCompare(cronJobsNextRunAt(endpoint,1,createDateTime(2026,10,18,14,10,59)),createDateTime(2026,10,18,14,10,59)) GT 0,"A very late finish never schedules into the past");
check(dateTimeFormat(cronJobsNextRunAt("https://example.com/job",1,createDateTime(2026,10,18,14,10,42)),"yyyy-mm-dd HH:nn:ss") EQ "2026-10-18 14:11:42","Other jobs retain their existing finish-relative cadence");
check(dateTimeFormat(cronJobsNextRunAt(endpoint,5,createDateTime(2026,10,18,14,10,42)),"yyyy-mm-dd HH:nn:ss") EQ "2026-10-18 14:15:42","An explicitly different cadence is not silently overridden");
fixtures=queryNew("id_cron_job,endpoint_url,interval_minutes","integer,varchar,integer",[{id_cron_job=1,endpoint_url="https://example.com/old",interval_minutes=10},{id_cron_job=25,endpoint_url=endpoint,interval_minutes=1},{id_cron_job=26,endpoint_url="https://example.com/new",interval_minutes=1}]);
due=cronJobsPrioritizeDueJobs(fixtures,2);
check(due.recordCount EQ 2 AND due.id_cron_job[1] EQ 25 AND due.id_cron_job[2] EQ 1,"The minute worker cannot wait behind a slow overdue job; remaining jobs preserve oldest-first order");
writeOutput("GEO_SCHEDULE_PASSED");
</cfscript>
