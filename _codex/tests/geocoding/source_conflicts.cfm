<cfscript>
failures=[];
function check(required boolean condition,required string label){writeOutput((condition ? "PASS " : "FAIL ") & label & chr(10));if(!condition)arrayAppend(failures,label);}
reader=new services.geocoding.Sources();policy=new services.geocoding.Policy();
source={nome_evento="Corrida do Parque das Flores",start_date="2026-10-17",cidade="São Paulo",estado="SP",pais="BR",endereco="",descricao="",descricao_original="",catalog_city="",catalog_state=""};
doc={url="https://race.com/prova-2026",sha256=repeatString("e",64),kind="html",title="Corrida do Parque das Flores",text="Corrida do Parque das Flores 17/10/2026" & chr(10) & "Local da largada: Parque da Serra",jsonld=[{"@type"="SportsEvent",name="Corrida do Parque das Flores",startDate="2026-10-17",location={name="Parque das Flores"}}]};
parsed=reader.parseDocument(source,doc);queries=policy.queries(source,parsed);
candidate={lat=-23.5614,lon=-46.6559,city="São Paulo",state_code="SP",country_code="br",result_type="amenity",name="Parque das Flores",rank={confidence=1,confidence_city_level=1}};
check(policy.evaluate(source,queries[1],[candidate]).status NEQ "auto_applied","Visible start venue contradicting JSON-LD prevents automatic coordinates");
source.endereco="Avenida Paulista, 1578";doc.jsonld=[];doc.text="Corrida do Parque das Flores 17/10/2026" & chr(10) & "Local da largada: a definir";
parsed=reader.parseDocument(source,doc);queries=policy.queries(source,parsed);
candidate={lat=-23.5614,lon=-46.6559,city="São Paulo",state_code="SP",country_code="br",result_type="building",street="Avenida Paulista",housenumber="1578",rank={confidence=1,confidence_city_level=1,confidence_building_level=1}};
check(policy.evaluate(source,queries[1],[candidate]).status NEQ "auto_applied","Current official uncertainty overrides a concrete registered address");
if(arrayLen(failures))throw(type="Test.Failed",message=arrayToList(failures,"; "));
writeOutput("GEO_SOURCE_CONFLICTS_PASSED");
</cfscript>
