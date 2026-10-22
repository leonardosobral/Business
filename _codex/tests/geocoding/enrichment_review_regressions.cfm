<cfscript>
fixtureFailures=[];
function check(required boolean condition,required string label){writeOutput((condition ? "PASS " : "FAIL ") & label & chr(10));if(!condition)arrayAppend(fixtureFailures,label);}
fixtureP=new services.geocoding.EnrichmentPolicy();fixtureRegions=new services.geocoding.RegionNames();
fixtureSource={nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="Florianópolis",estado="SC",pais="BR",organizador="",localizacoes={}};
fixtureIdentity="Corrida Parque das Flores — 15/11/2026";
fixtureDocs=[{url="https://example.com/regulamento",sha256=repeatString("a",64),text=fixtureIdentity & chr(10) & "Organização: Associação Y. Patrocínio: Loja X." & chr(10) & "Corrida Parque das Flores — 15/11/2025. Organizador: Associação Antiga."}];
fixtureFacts={event_name=fixtureSource.nome_evento,event_date=fixtureSource.start_date,identity_document=1,identity_quote=fixtureIdentity,locations=[],attributes=[{field="organizador",value="Loja X",quote="Organização: Associação Y. Patrocínio: Loja X.",document_index=1,certainty="confirmed"}]};
check(!fixtureRegions.hasCountry("Largada no Parque de Flores, Brasil.","DE"),"Country codes cannot be ordinary prepositions");
check(!fixtureRegions.hasState("Largada em Campo Grande, Mato Grosso do Sul.","MT"),"Longest full state name prevents MT versus MS collision");
fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureFacts);check(!fixtureDecision.fields[1].trusted,"Organizer cannot borrow a sponsor from another clause");
fixtureFacts.attributes[1].value="Associação Antiga";fixtureFacts.attributes[1].quote="Corrida Parque das Flores — 15/11/2025. Organizador: Associação Antiga.";
fixtureDecision=fixtureP.validate(fixtureSource,fixtureDocs,fixtureFacts);check(!fixtureDecision.fields[1].trusted,"An old identity in the citation cannot borrow the current page identity");
if(arrayLen(fixtureFailures))throw(type="Test.Failed",message=arrayToList(fixtureFailures,"; "));
writeOutput("GEO_ENRICHMENT_REVIEW_REGRESSIONS_PASSED");
</cfscript>
