<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureStore=new services.geocoding.LocationStore();fixtureId=2147000092;fixtureOptions={datasource="runner_dba"};
transaction {
 check(!fixtureStore.event(fixtureId).exists,"No real event replaced");
 queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,data_inicial,data_final,ativo) VALUES(:id,'Teste isolado Flores','São Paulo','SP','BR',CURRENT_DATE,CURRENT_DATE,true)",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},fixtureOptions);
 fixtureIds=fixtureStore.enqueue([fixtureId],"fixture");fixtureWorker=new FixtureEnrichmentWorker(fixtureIds[1]);fixtureFirst=fixtureWorker.run(1);
 check(fixtureFirst.status EQ "provider_cooldown" AND fixtureWorker.aiCallCount() EQ 1,"One real worker analysis reaches the deferred geocoder stage");
 check(fixtureStore.event(fixtureId).organizador EQ "Associação Flores","Native enrichment is already persisted while Geoapify is unavailable");
 fixtureSnapshot=fixtureStore.snapshot(fixtureStore.event(fixtureId));check(fixtureSnapshot.localizacoes.enriquecimento.fields.horarios_largada.value EQ "5 km às 07:00","Complementary enrichment is visible in the event before geocoding resumes");
 queryExecute("UPDATE public.tb_evento_geocoding SET next_retry_at=clock_timestamp()-interval '1 second' WHERE id=:id",{id={value=fixtureIds[1],cfsqltype="cf_sql_bigint"}},fixtureOptions);
 fixtureSecond=fixtureWorker.run(1);check(fixtureSecond.processed EQ 1 AND fixtureWorker.aiCallCount() EQ 1,"Resuming completes locations without buying another analysis");
 fixtureAudit=queryExecute("SELECT count(*) AS n FROM public.tb_evento_geocoding_audit WHERE work_id=:id AND action='event_enriched'",{id={value=fixtureIds[1],cfsqltype="cf_sql_bigint"}},fixtureOptions);check(fixtureAudit.n[1] EQ 1,"Resuming does not duplicate enrichment audit");
 transaction action="rollback";
}
writeOutput("GEO_ENRICHMENT_WORKFLOW_PASSED");
</cfscript>
