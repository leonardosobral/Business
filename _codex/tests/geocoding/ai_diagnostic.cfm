<cfscript>
fixtureAI=new services.geocoding.AIClient(application.vickyKnowledge.apiKey);
fixtureBody=fixtureAI.requestBody({nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="São Paulo",estado="SP",pais="BR"},[{url="https://race.com/",text="Corrida Parque das Flores — 15/11/2026. Largada no Parque das Flores, Avenida das Flores, 123, São Paulo/SP. Retirada de kits na Loja do Corredor, Rua das Palmeiras, 45, Campinas/SP."}],"gpt-4.1-mini");
fixtureHTTP={};fixtureStart=getTickCount();
cfhttp(url="https://api.openai.com/v1/responses",method="POST",result="fixtureHTTP",timeout=20,redirect=false,throwonerror=false,charset="utf-8"){
 cfhttpparam(type="header",name="Authorization",value="Bearer " & application.vickyKnowledge.apiKey);
 cfhttpparam(type="header",name="Content-Type",value="application/json");
 cfhttpparam(type="body",value=serializeJSON(fixtureBody));
}
fixtureReport={status=fixtureHTTP.statusCode,ms=getTickCount()-fixtureStart,isJson=isJSON(fixtureHTTP.fileContent)};
if(fixtureReport.isJson){fixtureJSON=deserializeJSON(fixtureHTTP.fileContent);if(structKeyExists(fixtureJSON,"error") AND isStruct(fixtureJSON.error)){fixtureReport.errorCode=fixtureJSON.error.code ?: "";fixtureReport.parameter=fixtureJSON.error.param ?: "";}else {fixtureReport.decoded=fixtureAI.decode(val(fixtureHTTP.statusCode),fixtureHTTP.fileContent);}}
writeOutput(serializeJSON(fixtureReport));writeOutput("GEO_AI_DIAGNOSTIC_PASSED");
</cfscript>
