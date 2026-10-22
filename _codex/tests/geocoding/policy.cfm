<cfscript>
function check(required boolean condition,required string label) {if(!condition) throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
function expectDenied(required any fn,required string label){var denied=false;try{fn();}catch(Geocoding.Denied e){denied=true;}check(denied,label);}
policy=new services.geocoding.Policy();
event={id_evento=48091,cidade="São Paulo",estado="SP",pais="BR",cod_cidade="3550308",endereco="Avenida Paulista, 1578",descricao_original="",descricao="",coordenadas=""};
snapshot=policy.snapshot(event);
query=policy.queries(snapshot)[1];
building={lat=-23.5614,lon=-46.6559,city="São Paulo",state_code="SP",country_code="br",result_type="building",housenumber="1578",street="Avenida Paulista",formatted="Avenida Paulista 1578, São Paulo",rank={confidence=1,confidence_city_level=1,confidence_building_level=1},datasource={attribution="© OpenStreetMap contributors"}};
check(policy.evaluate(snapshot,query,[building]).status EQ "auto_applied","Specific matching address is eligible for atomic application");
for(change in [{result_type="street"},{result_type="city"},{city="Campinas"},{state_code="RJ"},{country_code="pt"},{housenumber="1579"},{street="Rua Augusta"},{lat=91},{lon=181},{lat=0,lon=0},{rank={confidence=1}},{rank={confidence=.94,confidence_city_level=1,confidence_building_level=1}}]) {
 candidate=duplicate(building);structAppend(candidate,change,true);
 check(policy.evaluate(snapshot,query,[candidate]).status NEQ "auto_applied","Unsafe result cannot auto-publish: " & serializeJSON(change));
}
candidate=duplicate(building);candidate.lat=-23.5714;candidate.rank.confidence=.98;
check(policy.evaluate(snapshot,query,[building,candidate]).status NEQ "auto_applied","A close score at another location requires review");
candidate=duplicate(building);candidate.result_type="city";
check(policy.evaluate(snapshot,query,[candidate]).status EQ "city_suggestion","City-only coordinate stays a private suggestion");
event.endereco="Parque Ibirapuera";snapshot=policy.snapshot(event);query=policy.queries(snapshot)[1];
poi=duplicate(building);poi.result_type="amenity";poi.name="Parque Ibirapuera";structDelete(poi,"housenumber");
check(policy.evaluate(snapshot,query,[poi]).status EQ "auto_applied","Named venue is usable when exact and geographically confirmed");
poi.name="Parque Villa-Lobos";check(policy.evaluate(snapshot,query,[poi]).status NEQ "auto_applied","Another venue name cannot auto-publish");
event.endereco="Local a definir";event.descricao_original="Largada: Parque Ibirapuera";queries=policy.queries(policy.snapshot(event));
check(arrayLen(queries) EQ 1 AND queries[1].kind EQ "city","Undefined location is not overridden using possibly stale description");
event.endereco="";event.descricao_original="Retirada de kits: Shopping Central";queries=policy.queries(policy.snapshot(event));
check(arrayLen(queries) EQ 1 AND queries[1].kind EQ "city","Kit collection is not a start location");
event.descricao_original="<p>Local da largada: Parque Ibirapuera</p><p>Retirada de kits: Shopping Central</p>";queries=policy.queries(policy.snapshot(event));
check(queries[1].local EQ "Parque Ibirapuera" AND queries[1].autoEligible,"Explicit start location can be extracted from description");
event.descricao="Local da largada: Parque Villa-Lobos";queries=policy.queries(policy.snapshot(event));
check(!queries[1].autoEligible,"Conflicting starts require human review");
event.endereco="Avenida Paulista, 1578";event.descricao_original="";event.descricao="Local da largada: a definir";queries=policy.queries(policy.snapshot(event));
check(!queries[1].autoEligible,"An undefined start in a description blocks a registered address");
event.descricao="Local da largada: aguarde a confirmação";queries=policy.queries(policy.snapshot(event));
check(!queries[1].autoEligible,"Uncertain start statements remain negative evidence");
foreign={id_evento=1,cidade="Springfield",estado="",pais="US",endereco="Main Street, 10",descricao="",descricao_original="",coordenadas=""};
foreignSource=policy.snapshot(foreign);foreignQuery=policy.queries(foreignSource)[1];
foreignBuilding=duplicate(building);foreignBuilding.city="Springfield";foreignBuilding.country_code="us";foreignBuilding.state_code="MA";foreignBuilding.street="Main Street";foreignBuilding.housenumber="10";
check(policy.evaluate(foreignSource,foreignQuery,[foreignBuilding]).status NEQ "auto_applied","A foreign homonym without administrative context cannot auto-publish");
check(!policy.coordinates("0,0").valid AND !policy.coordinates("-91,10").valid AND !policy.coordinates("NaN,10").valid,"Coordinate validation rejects zero and non-finite/out-of-range pairs");
check(policy.coordinates("-23.5614,-46.6559").valid AND policy.coordinates(" ").empty,"Coordinate parser recognizes valid and absent pairs");
expectDenied(function(){policy.authorize(false,false,true,true);},"Account user cannot mutate global tool");
expectDenied(function(){policy.authorize(true,true,true,true);},"Delegated context cannot mutate global tool");
expectDenied(function(){policy.authorize(true,false,false,true);},"GET cannot mutate global tool");
expectDenied(function(){policy.authorize(true,false,true,false);},"CSRF failure denies mutation");
policy.authorize(true,false,true,true);
first=policy.sourceHash(snapshot);snapshot.endereco="Outro local";
check(first NEQ policy.sourceHash(snapshot),"Source changes invalidate proposals");
proposal={proposal_revision=2};denied=false;
try{policy.requireRevision(proposal,"1");}catch(Geocoding.Validation e){denied=true;}
check(denied,"An old review form cannot approve a replacement proposal");
policy.requireRevision(proposal,"2");
check(true,"The displayed proposal revision can be reviewed");
event={id_evento=1,nome_evento="Corrida do Parque das Flores",source_start_date="2026-10-17",url_hotsite="https://race.com/2026",url_inscricao="",cidade="São Paulo",estado="SP",pais="BR",endereco="",descricao="",descricao_original="",coordenadas=""};
before=policy.sourceHash(policy.snapshot(event));event.url_hotsite="https://race.com/2025";
check(before NEQ policy.sourceHash(policy.snapshot(event)),"Changing official source URL invalidates every previous proposal");
before=policy.sourceHash(policy.snapshot(event));event.source_start_date="2026-11-17";
check(before NEQ policy.sourceHash(policy.snapshot(event)),"Changing event date invalidates evidence from an old edition");
source=policy.snapshot(event);
external={kind="specific",local="Parque das Flores",venue="Parque das Flores",street="Avenida das Flores",housenumber="123",source="official_source",text="Parque das Flores, Avenida das Flores, 123, São Paulo, SP, BR",autoEligible=true,reason="specific_location",evidence={url="https://race.com/2026",event_date="2026-11-17",method="event_jsonld"}};
queries=policy.queries(source,{queries=[external]});
check(queries[1].source EQ "official_source" AND queries[1].autoEligible,"Official evidence is geocoded before the municipal fallback");
other=duplicate(external);other.local="Parque da Serra";other.venue="Parque da Serra";other.street="Rua da Serra";
queries=policy.queries(source,{queries=[external,other]});
check(!queries[1].autoEligible AND !queries[2].autoEligible,"Conflicting official locations cannot become automatic just because one geocode is perfect");
other=duplicate(external);other.street="Rua da Serra";
queries=policy.queries(source,{queries=[external,other]});
check(!queries[1].autoEligible,"The same venue name at different streets cannot erase a conflict");
candidate=duplicate(building);candidate.result_type="building";candidate.street="Avenida das Flores";candidate.housenumber="123";
check(policy.evaluate(source,external,[candidate]).status EQ "auto_applied","A named venue can be validated by its independently confirmed street and number");
writeOutput("GEO_POLICY_PASSED" & chr(10));
</cfscript>
