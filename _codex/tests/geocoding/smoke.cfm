<cfinclude template="/services/geocoding/config.cfm">
<cfscript>
// EXPLICIT real-provider smoke mode: at most two counted calls; never writes event data.
store=new services.geocoding.Store();policy=new services.geocoding.Policy();geoClient=new services.geocoding.GeoapifyClient();
if(!store.isReady() OR !len(VARIABLES.geoConfig.apiKey))throw(type="Test.Failed",message="Configure schema and private key first");
source=policy.snapshot({id_evento=1,cidade="São Paulo",estado="SP",pais="BR",endereco="Parque Ibirapuera",descricao="",descricao_original="",coordenadas=""});
queries=policy.queries(source);results=[];
for(lookup in queries){
    reservation=store.reserveCall(store.settings().dailyLimit);
    if(!reservation.allowed AND reservation.reason EQ "pacing"){sleep(min(1100,reservation.waitMs+10));reservation=store.reserveCall(store.settings().dailyLimit);}
    if(!reservation.allowed)throw(type="Test.Failed",message="Provider reservation refused: " & reservation.reason);
    lookup.country="BR";reply=geoClient.search(lookup,VARIABLES.geoConfig.apiKey);
    store.completeCall(reservation.token,reply.code,reply.ok ? 0 : reply.retryAfter);
    if(!reply.ok)throw(type="Test.Failed",message="Safe provider status: " & reply.code);
    decision=policy.evaluate(source,lookup,reply.results);
    arrayAppend(results,{kind=lookup.kind,status=decision.status,reasons=decision.reasons,candidate=decision.candidate});
    if(lookup.kind EQ "city" AND decision.status NEQ "city_suggestion")throw(type="Test.Failed",message="Municipal result must stay a city suggestion");
}
writeOutput(serializeJSON({results=results,stats=store.overview(),provider_calls=arrayLen(results),events_changed=0}) & chr(10));
writeOutput("GEO_SMOKE_PASSED");
</cfscript>
