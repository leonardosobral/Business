<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.LocationStore();db={datasource="runner_dba"};id=2147001201;
transaction {
 check(!store.event(id).exists,"Synthetic event does not replace a real one");
 before=store.overview().applied;
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo,coordenadas) VALUES(:id,'Fixture durable outcome','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true,'-23.56,-46.65')",{id={value=id,cfsqltype="cf_sql_integer"}},db);
 ids=store.enqueue([id],"fixture");
 queryExecute("INSERT INTO public.tb_evento_geocoding_audit(work_id,id_evento,action,actor,source_hash,coordinates_after,details) SELECT id,id_evento,'auto_applied','fixture',source_hash,'-23.56,-46.65','{}'::jsonb FROM public.tb_evento_geocoding WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 queryExecute("UPDATE public.tb_evento_geocoding SET status='insufficient_data' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 check(store.overview().applied EQ before+1,"A newer incomplete analysis cannot remove a persisted filled coordinate");
 queryExecute("UPDATE public.tb_evento_corridas SET coordenadas='' WHERE id_evento=:id",{id={value=id,cfsqltype="cf_sql_integer"}},db);
 queryExecute("UPDATE public.tb_evento_geocoding SET status='approved' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 check(store.overview().applied EQ before,"Field-only approvals and deleted coordinates are not filled locations");
 ids=store.enqueue([id],"fixture");work=store.claim(ids[1]);
 result={status="city_suggestion",analysis_complete=false,retry_after_seconds=3600,analysis_retries=1,code="ai_cooldown",targets=[],enrichment={fields=[],published=true}};
 store.finish(work,result,"fixture");
 check(structIsEmpty(store.claim(ids[1])),"A municipal result cannot be reclaimed before its scheduled research retry");
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=ids[1],cfsqltype="cf_sql_bigint"}},db);
 resumed=store.claim(ids[1]);check(!structIsEmpty(resumed) AND deserializeJSON(resumed.decision).analysis_retries EQ 1,"Scheduled incomplete research resumes without deleting its checkpoint");
 transaction action="rollback";
}
transaction {
 // Quota/cooldown inspection must not consume a reservation.
 usage=store.aiStats().calls;availability=store.aiAvailability(1000);
 check(structKeyExists(availability,"allowed") AND store.aiStats().calls EQ usage,"Provider availability inspection is read-only");
 transaction action="rollback";
}
transaction {
 fixtureIds=[];
 for(index=1;index LTE 21;index++){
  fixtureId=2147001300+index;
  queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Fila isolada','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},db);
  if(index LTE 20)arrayAppend(fixtureIds,fixtureId);
 }
 queuedIds=store.enqueue(fixtureIds,"fixture");
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()+interval '1 day' WHERE id_evento BETWEEN 2147001301 AND 2147001320",[],db);
 seedStore=new OptimizationSeedStore(2147001321);
 check(seedStore.seed(1) EQ 1,"Twenty future retries do not block seeding a new ready event");
 transaction action="rollback";
}
writeOutput("GEO_OPTIMIZATION_STORE_PASSED");
</cfscript>
