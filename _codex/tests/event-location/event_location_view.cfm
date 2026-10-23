<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
VARIABLES.eventBasicPais="PT";VARIABLES.eventBasicEstado="XX";VARIABLES.eventBasicStateChanged=false;VARIABLES.eventBasicDelegated=false;VARIABLES.eventLocationEditor=new services.EventLocationPolicy();
qEvento=queryNew("pais,estado,cidade,cod_cidade,localizacoes","varchar,varchar,varchar,integer,varchar",[{pais="PT",estado="XX",cidade="Lisbon",localizacoes='{"administrativo":{"pais":"PT","estado_nome":"Lisboa"}}'}]);
qEstados=queryNew("uf","varchar",[{uf="SC"}]);qCidades=queryNew("cod_cidade,nome_cidade","integer,varchar",[{cod_cidade=4205407,nome_cidade="Florianópolis"}]);
exists=fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & '../eventos/includes/event_location_fields.cfm');check(exists,"The event editor renders country-aware location fields");
savecontent variable="rendered" {include '../eventos/includes/event_location_fields.cfm';}
check(find('name="pais"',rendered) AND reFind('value="PT"[^>]*selected',rendered),"The current foreign country is selected instead of defaulting to Brazil");
check(find('name="regiao_internacional"',rendered) AND find('value="Lisboa"',rendered) AND find('value="Lisbon"',rendered),"Existing international city and full subdivision are editable");
check(find('data-event-br-fields',rendered) AND find('data-event-foreign-fields',rendered),"Brazil municipality controls and free international fields have separate accessible panels");
writeOutput("GEO_EVENT_LOCATION_VIEW_PASSED");
</cfscript>
