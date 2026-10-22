<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureClient=new services.geocoding.AIClient("");fixtureBody=fixtureClient.requestBody({},[]);
check(structKeyExists(fixtureBody.text.format.schema.properties,"attributes"),"One Astra request has independent locations and enrichment attributes");
fixtureProperty=fixtureBody.text.format.schema.properties.attributes;
check(fixtureProperty.type EQ "array" AND fixtureProperty.maxItems EQ 24 AND find('"maxItems":24',serializeJSON(fixtureBody)) AND fixtureBody.max_output_tokens EQ 6000,"Expanded response has explicit bounded fact and token budgets");
check(arrayFind(fixtureProperty.items.properties.field.enum,"organizador") AND arrayFind(fixtureProperty.items.properties.field.enum,"kit_programacao"),"Strict field allowlist covers native data and kit agenda");
fixtureReply={event_name="Flores",event_date="2026-11-15",identity_document=1,identity_quote="Flores",locations=[],attributes=[{field="organizador",value="Flores~NULL~Clube",quote="Organizador: Flores~NULL~Clube",document_index=1,certainty="confirmed"}]};
fixtureWire=replace(serializeJSON(fixtureReply),"~NULL~",'\u0000',"all");fixtureResult=fixtureClient.decode(200,serializeJSON({status="completed",model="gpt-6-astra",output=[{content=[{type="output_text",text=fixtureWire}]}]}));
check(fixtureResult.ok AND fixtureResult.facts.attributes[1].value EQ "Flores Clube","Attribute text is sanitized before JSONB checkpointing");
writeOutput("GEO_ENRICHMENT_CONTRACT_PASSED");
</cfscript>
