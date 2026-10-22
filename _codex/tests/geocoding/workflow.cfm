<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.Store();options={datasource="runner_dba"};fixtureId=2147000001;
check(!store.event(fixtureId).exists,"Workflow refuses to reuse a real event");
transaction {
    queryExecute("UPDATE public.tb_geocoding_usage_daily SET calls=0 WHERE provider='geoapify' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],options);
    queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,endereco,data_inicial,data_final,ativo,url_hotsite) VALUES(:id,'Corrida do Parque das Flores','São Paulo','SP','BR','',DATE '2026-10-17',DATE '2026-10-17',true,'https://race.com/2026')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
    config=store.settings();config.enabled=true;config.validatedFingerprint=lCase(hash("fixture-only","SHA-256"));
    queryExecute("UPDATE public.tb_geocoding_cache SET response=CAST(:config AS jsonb),cooldown_until=NULL,last_call_at=NULL,provider_lease_token=NULL,provider_lease_until=NULL WHERE cache_key='__control__'",{config={value=serializeJSON(config),cfsqltype="cf_sql_longvarchar"}},options);
    ids=store.enqueue([fixtureId],"fixture");result=new FixtureWorker(ids[1]).run(1);
    check(result.processed EQ 1 AND result.applied EQ 1 AND result.source_documents EQ 1,"Worker carries official-source evidence through geocoding and atomic application: " & serializeJSON(result));
    row=store.detail(ids[1]);decision=deserializeJSON(row.decision & "");
    check(arrayLen(decision.research.evidence) EQ 1 AND decision.research.evidence[1].url EQ "https://race.com/2026","Applied event retains source URL, hash and edition evidence");
    check(store.event(fixtureId).coordenadas EQ "-23.5614000,-46.6559000","Autonomous workflow publishes only the specific confirmed coordinates");
    transaction action="rollback";
}
transaction {
    queryExecute("UPDATE public.tb_geocoding_usage_daily SET calls=0 WHERE provider='geoapify' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],options);
    queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,endereco,data_inicial,data_final,ativo,url_hotsite) VALUES(:id,'Corrida do Parque das Flores','São Paulo','SP','BR','',DATE '2026-10-17',DATE '2026-10-17',true,'https://race.com/2026')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
    config=store.settings();config.enabled=true;config.validatedFingerprint=lCase(hash("fixture-only","SHA-256"));
    queryExecute("UPDATE public.tb_geocoding_cache SET response=CAST(:config AS jsonb),cooldown_until=clock_timestamp()+interval '5 minutes' WHERE cache_key='__control__'",{config={value=serializeJSON(config),cfsqltype="cf_sql_longvarchar"}},options);
    source=new services.geocoding.Policy().snapshot(store.event(fixtureId));research=new FixtureSources().research(source,getTickCount()+30000);
    lookups=new services.geocoding.Policy().queries(source,research);lookups[1].country="BR";
    store.cachePut(lookups[1],new FixtureGeoClient().search(lookups[1],"fixture-only").results);
    ids=store.enqueue([fixtureId],"fixture");result=new FixtureWorker(ids[1]).run(1);
    check(result.applied EQ 1 AND result.calls EQ 0,"A provider cooldown does not block safe cached results");
    transaction action="rollback";
}
transaction {
    queryExecute("UPDATE public.tb_geocoding_usage_daily SET calls=0 WHERE provider='geoapify' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],options);
    queryExecute("INSERT INTO public.tb_evento_corridas(id_evento,nome_evento,cidade,estado,pais,endereco,data_inicial,data_final,ativo,url_hotsite) VALUES(:id,'Corrida do Parque das Flores','São Paulo','SP','BR','',DATE '2026-10-17',DATE '2026-10-17',true,'https://race.com/2026')",{id={value=fixtureId,cfsqltype="cf_sql_integer"}},options);
    config=store.settings();config.enabled=true;config.validatedFingerprint=lCase(hash("fixture-only","SHA-256"));
    queryExecute("UPDATE public.tb_geocoding_cache SET response=CAST(:config AS jsonb),cooldown_until=NULL,last_call_at=NULL,provider_lease_token=NULL,provider_lease_until=NULL WHERE cache_key='__control__'",{config={value=serializeJSON(config),cfsqltype="cf_sql_longvarchar"}},options);
    ids=store.enqueue([fixtureId],"fixture");result=new ReviewFixtureWorker(ids[1]).run(1);
    check(result.review EQ 1 AND result.calls EQ 1 AND !len(store.event(fixtureId).coordenadas),"A specific review candidate does not spend another call on an unusable municipal fallback: " & serializeJSON(result));
    transaction action="rollback";
}
check(!store.event(fixtureId).exists,"Workflow rolls back fixture, cache, quota and coordinates");writeOutput("GEO_WORKFLOW_PASSED");
</cfscript>
