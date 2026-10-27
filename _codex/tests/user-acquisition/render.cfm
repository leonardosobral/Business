<cfscript>
structClear(FORM);URL.aquisicao_dias="90";URL.busca="__acquisition_fixture_no_user__";URL.status="todos";URL.papel="todos";
qPerfil=queryNew("id,is_admin,is_dev","integer,bit,bit",[{id=1,is_admin=true,is_dev=false}]);
include "../administracao/usuarios/includes/backend.cfm";
savecontent variable="rendered"{include "../administracao/usuarios/home.cfm";}
if(!find('data-user-acquisition',rendered) OR !find('data-days="90"',rendered) OR !find('data-user-list-filters',rendered) OR !find('name="aquisicao_dias" value="90"',rendered))throw(type="Test.Failed",message="Painel e filtros devem manter 90 dias sem mudar a busca.");
if(!find("Aquisição de novos usuários",rendered) OR !find("Novos no período",rendered) OR !find("Valores diários",rendered))throw(type="Test.Failed",message="Métricas, gráfico e tabela acessível precisam renderizar.");
if(VARIABLES.userManagerTotal NEQ 0 OR VARIABLES.userAcquisition.summary.total LTE 0)throw(type="Test.Failed",message="Busca sem resultados não deve zerar aquisição global.");
// All four controls and a safe empty/error state must preserve the manager.
for(days in [7,30,90,365]){
 VARIABLES.userAcquisitionDays=days;VARIABLES.userAcquisition=new services.UserAcquisitionMetrics().load(days);
 savecontent variable="panel"{include "../administracao/usuarios/includes/acquisition.cfm";}
 if(!find('data-days="' & days & '"',panel))throw(type="Test.Failed",message="Período deve estar disponível no HTML.");
}
VARIABLES.userAcquisitionReady=false;
savecontent variable="unavailable"{include "../administracao/usuarios/includes/acquisition.cfm";}
if(!find("temporariamente indisponíveis",unavailable) OR find('data-acquisition-total',unavailable))throw(type="Test.Failed",message="Falha de consulta não deve virar zero ou quebrar listagem.");
writeOutput("USER_ACQUISITION_RENDER_PASSED");
</cfscript>
