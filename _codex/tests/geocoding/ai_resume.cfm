<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureStore=new services.geocoding.LocationStore();fixtureId=2147000001;fixtureOptions={datasource="runner_dba"};
transaction {
 check(!fixtureStore.event(fixtureId).exists,"No real event is replaced");
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWorker=new FixtureAIWorker(fixtureIds[1]);fixtureFirst=fixtureWorker.run(1);
 check(fixtureFirst.status EQ "provider_cooldown" AND fixtureWorker.aiCallCount() EQ 1,"A provider pause defers after one completed AI analysis");
 fixtureProgress=deserializeJSON(fixtureStore.detail(fixtureIds[1]).decision & "");check(fixtureProgress.analysis_complete AND arrayLen(fixtureProgress.targets) EQ 2,"Analysis and independent targets have a durable checkpoint");
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=fixtureIds[1],cfsqltype="cf_sql_bigint"}},fixtureOptions);
 fixtureSecond=fixtureWorker.run(1);check(fixtureSecond.processed EQ 1 AND fixtureWorker.aiCallCount() EQ 1,"Resuming does not repeat AI or lose a completed stage");
 fixtureEvent=fixtureStore.event(fixtureId);fixtureLocations=deserializeJSON(fixtureEvent.localizacoes & "");check(structKeyExists(fixtureLocations,"kit") AND structKeyExists(fixtureLocations,"evento"),"Location publication completes (summary " & serializeJSON(fixtureSecond) & ")");check(fixtureLocations.kit[1].cidade EQ "Campinas" AND fixtureLocations.evento.cidade EQ "São Paulo","End-to-end worker applies each point to the right purpose");
 transaction action="rollback";
}
transaction {
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWorker=new FixtureAIWorker(fixtureIds[1]);fixtureWorker.setTemporarySource(true);fixtureFirst=fixtureWorker.run(1);
 check(fixtureFirst.status EQ "provider_unavailable" AND fixtureWorker.aiCallCount() EQ 0 AND fixtureStore.detail(fixtureIds[1]).status EQ "error","A partial source failure preserves a retry, not a terminal incomplete analysis");
 fixtureWorker.setTemporarySource(false);queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=fixtureIds[1],cfsqltype="cf_sql_bigint"}},fixtureOptions);fixtureSecond=fixtureWorker.run(1);
 check(fixtureWorker.aiCallCount() EQ 1 AND fixtureSecond.status EQ "provider_cooldown","Recovered source completes analysis once and retains the normal geocoder checkpoint");
 transaction action="rollback";
}
transaction {
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Parque Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWorker=new FixtureAIWorker(fixtureIds[1]);fixtureWorker.setMissingSpecific();fixtureResult=fixtureWorker.run(1);
 fixtureProgress=deserializeJSON(fixtureStore.detail(fixtureIds[1]).decision & "");check(fixtureResult.suggestions EQ 1 AND fixtureProgress.targets[1].candidate.result_type EQ "city" AND fixtureProgress.targets[2].candidate.city EQ "Campinas","Unmatched specific addresses fall back to separate private city suggestions");
 check(!len(fixtureStore.event(fixtureId).coordenadas),"Municipal fallback cannot publish a coordinate");transaction action="rollback";
}
writeOutput("GEO_AI_RESUME_PASSED");
</cfscript>
