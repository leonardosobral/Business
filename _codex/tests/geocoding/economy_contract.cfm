<cfscript>
function check(required boolean ok,required string message){if(!ok)throw(type="EconomyTest",message=message);}
include "../services/geocoding/config.cfm";
check(VARIABLES.geoConfig.aiModel EQ "gpt-6.1-sol","Configuração deve selecionar Sol sem alterar a chave.");
workerSource=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../services/geocoding/LocationWorker.cfc");
check(find("variables.economy.extract",workerSource) AND !find("variables.ai.extract",workerSource),"Toda geração deve passar pelo orçamento.");
check(find("variables.economy.pollPending",workerSource),"Resultados Batch devem ser recuperados pela fila.");
clientSource=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../services/geocoding/AIClient.cfc");
check(find("this.requestBody(context,documents,variables.model)",clientSource),"HTTP deve usar o corpo compacto sobrescrito, não o legado.");
writeOutput("GEO_ECONOMY_CONTRACT_PASSED");
</cfscript>
