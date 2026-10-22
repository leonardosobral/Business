<cfscript>
// Explicit live acceptance: one event whose official source was verified. Not in `all`.
// This invokes the actual Worker/Sources/Geoapify/Store policy, not a hand-entered coordinate.
store=new services.geocoding.Store();policy=new services.geocoding.Policy();event=store.event(49279);
if(!event.exists)throw(type="Test.Failed",message="Acceptance event not found");
if(len(policy.text(event,"coordenadas"))) {
    writeOutput(serializeJSON({status="already_located",id_evento=49279,coordinates=event.coordenadas}) & chr(10));
} else {
    include "/services/geocoding/config.cfm";
    ids=store.enqueue([49279],"deployment_validation");
    if(arrayLen(ids) NEQ 1)throw(type="Test.Failed",message="Acceptance work not queued");
    result=new LiveTargetWorker(VARIABLES.geoConfig,ids[1]).run(1);
    detail=store.detail(ids[1]);
    writeOutput(serializeJSON({result=result,id=ids[1],status=detail.status,coordinates=policy.text(store.event(49279),"coordenadas"),decision=deserializeJSON(detail.decision & "")}) & chr(10));
    if(result.processed NEQ 1 OR result.applied NEQ 1 OR detail.status NEQ "auto_applied")throw(type="Test.Failed",message="Live geocoding did not apply a confirmed venue; current status: " & result.status);
}
writeOutput("GEO_VALIDATE_LIVE_PASSED");
</cfscript>
