<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
geoWorker=new services.geocoding.Worker({apiKey=""});
result=geoWorker.run();check(!result.success AND result.status EQ "not_configured","Missing credential cannot process events or consume provider budget");
check(geoWorker.safeError("credentials_rejected") NEQ "", "Worker supplies a safe configuration diagnostic");
check(geoWorker.responseStatus({status="provider_timeout",errors=1,results=[{status="error"}]}) EQ 202,"A preserved retry returns accepted JSON rather than a misleading gateway failure");
check(geoWorker.responseStatus({status="execution_error",errors=1,results=[]}) EQ 500,"An internal failure is not disguised as a successful batch");
check(geoWorker.responseStatus({status="provider_timeout",errors=1,results=[{status="errors_exhausted"}]}) EQ 500,"Exhausted attempts remain a visible terminal failure");
failingWorker=new FailureWorker();result=failingWorker.run();counts=failingWorker.counts();
check(counts.finished EQ 1 AND counts.deferred EQ 0 AND result.errors EQ 1,"An unexpected work failure consumes a retry instead of deferring forever");
writeOutput("GEO_WORKER_PASSED");
</cfscript>
