<cfscript>
// One bounded paid interpretation; no Geoapify request or event mutation.
if(!isDefined("fixtureUseRuntime"))fixtureUseRuntime=false;
if(fixtureUseRuntime){
 include "/services/geocoding/config.cfm";
 fixtureAstraClient=createObject("component","services" & ".geocoding.AIClient").init(VARIABLES.geoConfig.aiKey,VARIABLES.geoConfig.aiModel);
}else{
 include "../services/geocoding/config.cfm";
 fixtureAstraClient=new services.geocoding.AIClient(VARIABLES.geoConfig.aiKey,VARIABLES.geoConfig.aiModel);
}
fixtureStore=new services.geocoding.LocationStore();
fixtureReservation=fixtureStore.reserveAI(VARIABLES.geoConfig.aiDailyLimit);
if(!fixtureReservation.allowed)throw(type="Test.Failed",message=fixtureReservation.reason);
fixtureDocs=[{url="https://example.com/regulamento",sha256=repeatString("a",64),text="Corrida Parque das Flores — 15/11/2026. Largada no Parque das Flores, Avenida das Flores, 123, São Paulo/SP. Retirada de kits na Loja do Corredor, Rua das Palmeiras, 45, Campinas/SP."}];
fixtureSource={nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="São Paulo",estado="SP",pais="BR"};
fixtureStart=getTickCount();fixtureReply=fixtureAstraClient.extract(fixtureSource,fixtureDocs);fixtureStore.completeAI(fixtureReply);
if(!fixtureReply.ok)throw(type="Test.Failed",message="OpenAI: " & fixtureReply.code);
if(fixtureReply.model NEQ "gpt-6-astra")throw(type="Test.Failed",message="Unexpected live extraction model");
fixtureDecision=new services.geocoding.LocationPolicy().validate(fixtureSource,fixtureDocs,fixtureReply.facts);
if(arrayLen(fixtureDecision.targets) NEQ 2 OR !fixtureDecision.targets[1].trusted OR !fixtureDecision.targets[2].trusted)throw(type="Test.Failed",message="Live extraction did not preserve independent race and kit evidence");
writeOutput(serializeJSON({runtime=fixtureUseRuntime,model=fixtureReply.model,usage=fixtureReply.usage,duration_ms=getTickCount()-fixtureStart,roles=[fixtureDecision.targets[1].role,fixtureDecision.targets[2].role],event_changes=0,geo_calls=0}));
writeOutput("GEO_AI_ASTRA_LIVE_PASSED");
</cfscript>
