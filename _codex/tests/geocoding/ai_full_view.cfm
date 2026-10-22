<cfinclude template="view.cfm">
<cfscript>
VARIABLES.geoAIReady=true;VARIABLES.geoAIStats={calls=1};VARIABLES.geoConfig={aiModel="gpt-4.1-mini",aiDailyLimit=1000};
VARIABLES.geoTab="revisao";VARIABLES.geoSelected={id=1,id_evento=1,nome_evento="Teste",proposal_revision=1,status="insufficient_data"};VARIABLES.geoDecision={targets=[],model="fixture"};
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find("Interpretação OpenAI",rendered) AND find("Nenhum local confirmado",rendered),"Full page renders the new decision and AI status without nested output errors");
writeOutput("GEO_AI_FULL_VIEW_PASSED");
</cfscript>
