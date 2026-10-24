// Executed only through the short-lived loopback bridge. No production secret is read.
function verifyLive(required boolean condition, required string message) {
    if (!arguments.condition) throw(type="LiveFunnelVerification",message=arguments.message);
}
function verifyUuid() { return lCase(createObject("java","java.util.UUID").randomUUID().toString()); }
verifyService=createObject("component","liveVerifyServices.AudienceMeasurementService").init({"enabled"=true,"secret"=verifyUuid() & verifyUuid()});
verifyHeaders={"Origin"="https://roadrunners.run","Sec-Fetch-Site"="same-origin"};
verifyEvent=verifyService.buildContext({"template"="/evento/","qEvento"=queryNew("id_evento,tag,estado","varchar,varchar,varchar",[{"id_evento"="9999999999","tag"="live-funnel-verification","estado"="SP"}])},{},{"HTTP_HOST"="roadrunners.run"});
verifyCircuit=verifyService.buildContext({"template"="/circuito/","qAgrega"=queryNew("id_agrega_evento,tag","varchar,varchar",[{"id_agrega_evento"="9999999998","tag"="live-funnel-verification"}])},{},{"HTTP_HOST"="roadrunners.run"});
verifyEvent.isInternal=true; verifyCircuit.isInternal=true;
verifyVisitor=verifyUuid(); verifySession=verifyUuid();
function verifyPayload(required struct context,required array events) {
    var signed=verifyService.signContext(arguments.context);
    return {"contextToken"=signed.contextToken,"signature"=signed.signature,"visitorId"=verifyVisitor,"sessionId"=verifySession,
        "source"="internal_test","medium"="verification","campaign"="live_funnel_transaction_test","creative"="rollback",
        "events"=arguments.events};
}
verifyEventPayload=verifyPayload(verifyEvent,[
    {"kind"="content_open","key"="content_open:live_coupon_viewable:9999999999","contentType"="event","contentId"="9999999999","visibleMs"=1000,"maxContinuousMs"=1000,"ratio"=0.5},
    {"kind"="content_open","key"="content_open:live_coupon_copy_attempt:9999999999","contentType"="event","contentId"="9999999999"},
    {"kind"="content_open","key"="content_open:live_coupon_copy_success:9999999999","contentType"="event","contentId"="9999999999"},
    {"kind"="content_open","key"="content_open:live_coupon_copy_error:9999999999","contentType"="event","contentId"="9999999999"},
    {"kind"="outbound_click","key"="outbound_click:live_information:9999999999","contentType"="event","contentId"="9999999999"},
    {"kind"="outbound_click","key"="outbound_click:live_registration:9999999999","contentType"="event","contentId"="9999999999"}
]);
verifyCircuitPayload=verifyPayload(verifyCircuit,[
    {"kind"="content_open","key"="content_open:live_city_select:9999999998:campinas-sp","contentType"="circuit","contentId"="9999999998"},
    {"kind"="content_open","key"="content_open:live_city_select:9999999998:all","contentType"="circuit","contentId"="9999999998"}
]);
verifyExpected={};
for(verifyFixture in verifyEventPayload.events) verifyExpected[verifyFixture.key]=verifyFixture;
for(verifyFixture in verifyCircuitPayload.events) verifyExpected[verifyFixture.key]=verifyFixture;
verifyParameters={"eventPage"={value=verifyEvent.pageViewId,cfsqltype="cf_sql_varchar"},"circuitPage"={value=verifyCircuit.pageViewId,cfsqltype="cf_sql_varchar"}};
verifyWhere=" WHERE page_view_id IN (CAST(:eventPage AS uuid),CAST(:circuitPage AS uuid))";
verifyOptions={datasource="runnerhub",timeout=5};
verifyBefore=queryExecute("SELECT count(*) AS rows FROM audience.events" & verifyWhere,verifyParameters,verifyOptions);
verifyLive(verifyBefore.rows[1]==0,"Fresh test UUIDs unexpectedly already exist");
verifyEventBatch=verifyService.validateBatch(verifyEventPayload,"roadrunners.run",verifyHeaders);
verifyCircuitBatch=verifyService.validateBatch(verifyCircuitPayload,"roadrunners.run",verifyHeaders);
verifyRejections=0;
for (verifyChange in [{"ratio"=0.49},{"visibleMs"=999},{"contentId"="9999999998"},{"kind"="outbound_click"},{"campaignId"="44444444-4444-4444-8444-444444444444"}]) {
    verifyBad=duplicate(verifyEventPayload); structAppend(verifyBad.events[1],verifyChange,true); verifyRejected=false;
    try { verifyService.validateBatch(verifyBad,"roadrunners.run",verifyHeaders); } catch(Audience.Invalid invalidFixture) { verifyRejected=true; }
    verifyLive(verifyRejected,"Published service accepted a malformed coupon exposure"); verifyRejections++;
}
transaction {
    // Same datasource as persist(): never use runner_dba inside this transaction.
    queryExecute("SET LOCAL statement_timeout='5s'",{},verifyOptions);
    queryExecute("SET LOCAL lock_timeout='2s'",{},verifyOptions);
    verifyAcceptedEvent=verifyService.persist(verifyEventBatch);
    verifyAcceptedCircuit=verifyService.persist(verifyCircuitBatch);
    verifyLive(verifyAcceptedEvent==6 && verifyAcceptedCircuit==2,"Real SQL function did not accept all eight fixtures");
    verifyRows=queryExecute("SELECT event_key,event_kind,content_type,content_id,is_internal,environment,site_host,source,medium,campaign,creative,visible_ms,max_continuous_ms,view_ratio,delivery_id,campaign_id,active_ms,slot_key,placement_key,slot_state,(xmin::text=(txid_current() % 4294967296)::text) AS same_transaction FROM audience.events" & verifyWhere & " ORDER BY event_key",verifyParameters,verifyOptions);
    verifyLive(verifyRows.recordCount==8,"Real storage count differs from accepted count");
    verifyKeys=[];
    for(verifyRow in verifyRows) {
        verifyLive(structKeyExists(verifyExpected,verifyRow.event_key),"Storage changed an event key");
        verifyFixture=verifyExpected[verifyRow.event_key];
        verifyLive(verifyRow.event_kind==verifyFixture.kind && verifyRow.content_type==verifyFixture.contentType && verifyRow.content_id==verifyFixture.contentId,"Storage changed event kind or content identity");
        verifyLive(verifyRow.is_internal && verifyRow.same_transaction,"Fixture was not internal or escaped the rollback transaction");
        verifyLive(verifyRow.environment=="prod" && verifyRow.site_host=="roadrunners.run","Signed environment changed during persistence");
        verifyLive(verifyRow.source=="internal_test" && verifyRow.medium=="verification" && verifyRow.campaign=="live_funnel_transaction_test" && verifyRow.creative=="rollback","Session attribution did not survive persistence");
        verifyLive((isNull(verifyRow.delivery_id) || !len(verifyRow.delivery_id & "")) && (isNull(verifyRow.campaign_id) || !len(verifyRow.campaign_id & "")) && verifyRow.active_ms==0 && !len(verifyRow.slot_key) && !len(verifyRow.placement_key) && !len(verifyRow.slot_state),"Fixture polluted Ads or engagement fields");
        if (verifyRow.event_key=="content_open:live_coupon_viewable:9999999999") verifyLive(verifyRow.visible_ms==1000 && verifyRow.max_continuous_ms==1000 && verifyRow.view_ratio==0.5,"Viewability thresholds did not survive persistence");
        arrayAppend(verifyKeys,verifyRow.event_key);
    }
    verifyHashSql="SELECT md5(string_agg(to_jsonb(e)::text,',' ORDER BY event_key)) AS digest FROM audience.events e" & verifyWhere;
    verifyHashBefore=queryExecute(verifyHashSql,verifyParameters,verifyOptions);
    verifyReplayEvent=verifyService.persist(verifyEventBatch); verifyReplayCircuit=verifyService.persist(verifyCircuitBatch);
    verifyAfterReplay=queryExecute("SELECT count(*) AS rows FROM audience.events" & verifyWhere,verifyParameters,verifyOptions);
    verifyHashAfter=queryExecute(verifyHashSql,verifyParameters,verifyOptions);
    verifyLive(verifyAfterReplay.rows[1]==8 && verifyHashBefore.digest[1]==verifyHashAfter.digest[1],"Replay created duplicates or changed stored data");
    // Function counts matched ON CONFLICT updates as accepted; row count/hash prove dedupe.
    transaction action="rollback";
}
verifyAfterRollback=queryExecute("SELECT count(*) AS rows FROM audience.events" & verifyWhere,verifyParameters,verifyOptions);
verifyLive(verifyAfterRollback.rows[1]==0,"Rollback did not remove every synthetic fixture");
report={"verified"=true,"service_validation"=true,"malformed_batches_rejected"=verifyRejections,"real_persistence"=true,
    "event_rows"=6,"circuit_rows"=2,"deduplicated_rows"=8,"replay_accepted"=verifyReplayEvent+verifyReplayCircuit,
    "all_internal"=true,"same_database_transaction"=true,"rows_after_rollback"=verifyAfterRollback.rows[1],
    "page_view_ids"=[verifyEvent.pageViewId,verifyCircuit.pageViewId],"keys"=verifyKeys,
    "public_http_collector_tested"=false,"production_secret_read"=false};
