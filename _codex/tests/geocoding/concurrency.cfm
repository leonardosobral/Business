<cfinclude template="/services/geocoding/config.cfm">
<cfscript>
// Holds a real batch lease while an independent signed HTTP request attempts
// dispatch. No event is claimed and no Geoapify call is permitted by this test.
store=new services.geocoding.Store();lease=store.acquireWorker();
if(!lease.allowed)throw(type="Test.Failed",message="Another batch is active; retry concurrency acceptance when idle");
try {
    body='{"limit":1,"dryRun":false}';stamp=dateTimeFormat(now(),"yyyy-mm-dd HH:nn:ss");
    signature=lCase(hmac(stamp & "." & body,VARIABLES.geoConfig.secret,"HmacSHA256"));
    cfhttp(url="https://business.roadrunners.run/api/eventos/geolocalizar.cfm",method="POST",timeout=10,redirect=false,result="reply") {
        cfhttpparam(type="header",name="Content-Type",value="application/json");
        cfhttpparam(type="header",name="X-RR-Handoff-Timestamp",value=stamp);
        cfhttpparam(type="header",name="X-RR-Handoff-Signature",value=signature);
        cfhttpparam(type="body",value=body);
    }
    if(val(reply.statusCode) NEQ 202 OR !isJSON(toString(reply.fileContent)))throw(type="Test.Failed",message="Concurrent HTTP dispatch did not return accepted JSON");
    result=deserializeJSON(toString(reply.fileContent));
    if(result.status NEQ "worker_busy" OR result.calls NEQ 0 OR result.processed NEQ 0)throw(type="Test.Failed",message="Concurrent request was not excluded before processing");
    writeOutput(serializeJSON({http=202,status=result.status,processed=result.processed,calls=result.calls}) & chr(10));
}finally{store.releaseWorker(lease.token);}
writeOutput("GEO_CONCURRENCY_PASSED");
</cfscript>
