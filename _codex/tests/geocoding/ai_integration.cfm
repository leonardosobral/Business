<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureStore=new services.geocoding.LocationStore();fixturePolicy=new services.geocoding.Policy();fixtureId=2147000001;fixtureOptions={datasource="runner_dba"};
check(fixtureStore.aiReady(),"Additive location migration is ready");
function fixtureCreate(){
 check(!fixtureStore.event(fixtureId).exists,"No real event is replaced");
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
}
function fixtureTarget(string role="evento",string city="São Paulo"){
 return {role=role,trusted=true,status="auto_applied",facts={name="Loja Flores",address="Rua Flores, 123",city=city,state="SP",country="BR"},context={cidade=city,estado="SP",pais="BR"},evidence={url="https://race.com/regulation",excerpt="Evidência literal de fixture",sha256=repeatString("a",64)},query={kind="specific",local="Rua Flores, 123",street="Rua Flores",housenumber="123",autoEligible=true},
 candidate={lat=-23.55,lon=-46.63,city=city,state_code="SP",country_code="br",result_type="building",housenumber="123",street="Rua Flores",rank={confidence=1,confidence_city_level=1,confidence_building_level=1}}};
}
transaction {
 fixtureCreate();fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);
 fixtureInput=deserializeJSON(fixtureWork.source_values & "");check(fixtureInput[12][1],"Regulation NULL is retained in the input fingerprint used by automatic seeding");
 fixtureStore.finish(fixtureWork,{status="auto_applied",targets=[fixtureTarget(),fixtureTarget("kit","Campinas")]},"fixture");
 fixtureEvent=fixtureStore.event(fixtureId);fixtureLocations=deserializeJSON(fixtureEvent.localizacoes & "");
 check(len(fixtureEvent.coordenadas) AND fixtureLocations.evento.cidade EQ "São Paulo" AND fixtureLocations.kit[1].cidade EQ "Campinas","Race and kit persist separately with their own geography");
 check(fixtureStore.sourceHash(fixtureStore.snapshot(fixtureEvent)) EQ fixtureWork.source_hash,"Applying output locations does not change input fingerprint or create a loop");
 fixtureAudit=queryExecute("SELECT count(*) AS n FROM public.tb_evento_geocoding_audit WHERE work_id=:id AND action='auto_applied'",{id={value=fixtureWork.id,cfsqltype="cf_sql_bigint"}},fixtureOptions);check(fixtureAudit.n[1] EQ 1,"Both locations have one atomic permanent audit");
 transaction action="rollback";
}
transaction {
 fixtureCreate();queryExecute("UPDATE public.tb_evento_corridas SET coordenadas='-20,-40' WHERE id_evento=:id",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");check(arrayLen(fixtureIds) EQ 1,"Already geolocated events are researched for kits");fixtureWork=fixtureStore.claim(fixtureIds[1]);
 fixtureStore.finish(fixtureWork,{status="auto_applied",targets=[fixtureTarget(),fixtureTarget("kit","Campinas")]},"fixture");
 check(fixtureStore.event(fixtureId).coordenadas EQ "-20,-40","Existing race coordinates are never overwritten by AI or kit");transaction action="rollback";
}
transaction {
 fixtureCreate();fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);
 queryExecute("UPDATE public.tb_evento_corridas SET localizacoes=CAST(:body AS jsonb) WHERE id_evento=:id",{body={value='{"kit":[{"nome_local":"Manual"}]}',cfsqltype="cf_sql_longvarchar"},id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureResult=fixtureStore.finish(fixtureWork,{status="auto_applied",targets=[fixtureTarget(),fixtureTarget("kit","Campinas")]},"fixture");check(fixtureResult.status EQ "conflict","Concurrent destination edits invalidate the entire publication atomically");transaction action="rollback";
}
transaction {
 fixtureCreate();fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWork=fixtureStore.claim(fixtureIds[1]);fixtureOne=fixtureTarget();fixtureOne.status="city_suggestion";fixtureOne.candidate.result_type="city";
 fixtureStore.finish(fixtureWork,{status="city_suggestion",targets=[fixtureOne]},"fixture");check(!len(fixturePolicy.text(fixtureStore.event(fixtureId),"coordenadas")),"A city remains a suggestion, never a canonical point");transaction action="rollback";
}
transaction {
 fixtureCreate();fixtureLegacy=new services.geocoding.Store();fixtureLegacyIds=fixtureLegacy.enqueue([fixtureId],"fixture");fixtureWork=fixtureLegacy.claim(fixtureLegacyIds[1]);fixtureOne=fixtureTarget();
 fixtureLegacy.finish(fixtureWork,{status="needs_review",candidate=fixtureOne.candidate},"fixture");
 fixtureResult=fixtureStore.review(fixtureWork.id,"approve","fixture","",fixtureLegacy.detail(fixtureWork.id).proposal_revision & "");
 check(fixtureResult.status EQ "approved" AND len(fixtureStore.event(fixtureId).coordenadas),"Version 2 proposals still use the version 2 finalizer after activating the AI store");transaction action="rollback";
}
check(!fixtureStore.event(fixtureId).exists,"All fixture writes rolled back");writeOutput("GEO_AI_INTEGRATION_PASSED");
</cfscript>
