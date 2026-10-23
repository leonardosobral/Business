<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
VARIABLES.template="/eventos/";VARIABLES.adminIsAdmin=true;VARIABLES.eventoApiTokenParam="";
structDelete(REQUEST,"businessAccessContext");
for(key in listToArray("periodo,preset,busca,regiao,estado,cidade,id_agrega_evento,agregador_tag"))URL[key]="";
URL.id_evento="0";URL.sessao="dados";
qEvento=queryExecute('SELECT * FROM tb_evento_corridas WHERE id_evento=0',[],{datasource="runner_dba"});
savecontent variable="rendered"{include '../eventos/form_edicao.cfm';}
check(find('name="pais"',rendered) AND find('value="editar_evento_basico"',rendered) AND find('Salvar Dados Básicos',rendered),"Creating a new event renders the complete country-aware form through its save button");
writeOutput("GEO_EVENT_LOCATION_NEW_FORM_PASSED");
</cfscript>
