<cfscript>
fixtureDocs=[{url="https://race.com/regulamento.pdf",sha256=repeatString("a",64),text="Corrida Parque das Flores — 15/11/2026. Largada no Parque das Flores, Avenida das Flores, 123, São Paulo/SP. Retirada de kits na Loja do Corredor, Rua das Palmeiras, 45, Campinas/SP."}];
fixtureSource={nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="São Paulo",estado="SP",pais="BR"};
fixtureReply=new services.geocoding.AIClient(application.vickyKnowledge.apiKey).extract(fixtureSource,fixtureDocs);
if(!fixtureReply.ok)throw(type="Test.Failed",message="OpenAI: " & fixtureReply.code);
fixtureDecision=new services.geocoding.LocationPolicy().validate(fixtureSource,fixtureDocs,fixtureReply.facts);
if(arrayLen(fixtureDecision.targets) NEQ 2 OR !fixtureDecision.targets[1].trusted OR !fixtureDecision.targets[2].trusted)throw(type="Test.Failed",message="Live extraction did not pass evidence policy",detail=serializeJSON({facts=fixtureReply.facts,decision=fixtureDecision}));
writeOutput(serializeJSON({model=fixtureReply.model,usage=fixtureReply.usage,roles=[fixtureDecision.targets[1].role,fixtureDecision.targets[2].role]}));
writeOutput("GEO_AI_LIVE_PASSED");
</cfscript>
