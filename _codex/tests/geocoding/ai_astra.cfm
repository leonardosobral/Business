<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureAstraClient=new services.geocoding.AIClient("");
fixtureAstraBody=fixtureAstraClient.requestBody({nome_evento="Corrida Flores",start_date="2026-11-15"},[{url="https://example.com/regulamento",text="Corrida Flores em 15/11/2026. Largada na Praça das Flores, São Paulo/SP. Retirada de kits na Loja Flores, Campinas/SP."}]);
check(fixtureAstraBody.model EQ "gpt-6-astra","Default location extraction requests the approved Astra model");
check(structKeyExists(fixtureAstraBody,"reasoning") AND fixtureAstraBody.reasoning.effort EQ "low","Astra uses supported bounded low reasoning");
check(!structKeyExists(fixtureAstraBody,"temperature") AND !structKeyExists(fixtureAstraBody,"top_p") AND !structKeyExists(fixtureAstraBody,"tools"),"Astra request excludes incompatible sampling and external tools");
check(!fixtureAstraBody.store AND fixtureAstraBody.max_output_tokens LTE 6000 AND fixtureAstraBody.text.format.strict,"Astra preserves strict extraction, privacy and output budget");
fixtureOldBody=fixtureAstraClient.requestBody({},[],"gpt-4.1-mini");
check(!structKeyExists(fixtureOldBody,"reasoning"),"Explicit non-reasoning fixtures remain compatible");
include "../services/geocoding/config.cfm";
check(VARIABLES.geoConfig.aiModel EQ "gpt-6-astra" AND VARIABLES.geoConfig.aiDailyLimit EQ 1000,"Module configuration selects Astra without raising daily usage");
check(VARIABLES.geoConfig.aiKey EQ APPLICATION.vickyKnowledge.apiKey,"Module keeps the existing integration credential");
writeOutput("GEO_AI_ASTRA_PASSED");
</cfscript>
