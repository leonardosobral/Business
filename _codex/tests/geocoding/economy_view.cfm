<cfinclude template="view.cfm">
<cfscript>
VARIABLES.geoAIReady=true;VARIABLES.geoEconomyBudget={day_usd=0.12,month_usd=44.72,pending_usd=0.01,batches=2,uncertain=1,blocked=true};VARIABLES.geoSettings.enabled=false;VARIABLES.geoTab="configuracoes";
savecontent variable="rendered"{include "../administracao/geolocalizacao/includes/view.cfm";}
check(find("Sol por padrão",rendered) AND find("Astra apenas",rendered) AND find("histórico via Batch",rendered),"Roteamento econômico explícito na interface");
check(find("US$ 2",rendered) AND find("US$ 30",rendered) AND find("Sistema pausado para validação",rendered),"Tetos e pausa visíveis");
check(find("Novas cobranças bloqueadas",rendered) AND !find('id="geo-enabled" name="enabled" value="1" checked',rendered),"Limite bloqueado e controle desmarcado");
writeOutput("GEO_ECONOMY_VIEW_PASSED");
</cfscript>
