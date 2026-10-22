<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
VARIABLES.geoCanAdmin=true;VARIABLES.geoSelected={id=1,id_evento=1,nome_evento="Prova segura",proposal_revision=3,status="needs_review"};
VARIABLES.geoDecision={model="gpt-4.1-mini",targets=[{role="evento",status="city_suggestion",trusted=false,facts={},context={cidade="São Paulo",estado="SP"},candidate={lat=-23.5,lon=-46.6,result_type="city"},evidence={},reasons=["city_only"]},{role="kit",status="needs_review",trusted=true,facts={name="<script>kit</script>",address="Rua Flores, 123",city="Campinas",state="SP"},context={cidade="Campinas",estado="SP",pais="BR"},candidate={lat=-22.9,lon=-47.1,result_type="building"},evidence={url="https://race.com/",excerpt="<script>source</script>"},reasons=["low_confidence"]}]};
VARIABLES.geoPolicy=new services.geocoding.Policy();
VARIABLES.geoDecision.targets[2].candidate.city="Campinas";VARIABLES.geoDecision.targets[2].candidate.state_code="SP";VARIABLES.geoDecision.targets[2].candidate.country_code="br";
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/ai_locations_view.cfm";}
check(find("Local da prova",rendered) AND find("Retirada de kit",rendered),"Race and kit have distinct review panels");
check(!find("<script>",rendered),"Location evidence is always escaped");
check(arrayLen(reMatch('value="approve_target"',rendered)) EQ 1,"Only the specific, evidence-backed kit target can be approved");
check(find('name="target" value="2"',rendered) AND find('name="revision" value="3"',rendered) AND !find('name="reason"',rendered),"Independent target revision is protected without a mandatory justification");
VARIABLES.geoSelected.status="pending";VARIABLES.geoDecision.targets=[];savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/ai_locations_view.cfm";}
check(find("aguardando processamento",rendered) AND !find("Nenhum local confirmado",rendered),"Unprocessed work is not presented as a negative finding");
writeOutput("GEO_AI_VIEW_PASSED");
</cfscript>
