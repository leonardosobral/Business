<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
store=new services.geocoding.Store();options={datasource="runner_dba"};
// Regression: punctuation discarded by the old key could reuse the wrong building.
check(store.cacheKey({kind="specific",text="Rua A, 10/12, SP, BR",country="BR"}) NEQ store.cacheKey({kind="specific",text="Rua A, 10-12, SP, BR",country="BR"}),"Cache never merges different address punctuation");
transaction {
    queryExecute("DELETE FROM public.tb_geocoding_cache WHERE cache_key='__worker__'",[],options);
    lease=store.acquireWorker();check(lease.allowed,"A worker acquires a durable database lease");
    second=store.acquireWorker();check(!second.allowed,"A second worker cannot start while a batch is running");
    check(!store.releaseWorker("not-the-token") AND !store.acquireWorker().allowed,"A stale worker cannot release a newer batch");
    check(store.releaseWorker(lease.token) AND store.acquireWorker().allowed,"A completed batch releases its lease immediately");
    queryExecute("UPDATE public.tb_geocoding_cache SET provider_lease_until=clock_timestamp()-interval '1 second' WHERE cache_key='__worker__'",[],options);
    recovered=store.acquireWorker();check(recovered.allowed AND !store.workerValid(lease.token) AND store.workerValid(recovered.token),"An abandoned batch recovers without validating an old token");
    transaction action="rollback";
}
transaction {
    lookup={kind="city",text="Cache fixture " & createUUID(),country="BR"};
    // Old upserts changed responses without changing query_text. An apparently
    // exact legacy text therefore cannot prove which address supplied its body.
    oldKey=lCase(hash("geoapify-v1|city|br|" & new services.geocoding.Policy().normalize(lookup.text),"SHA-256"));
    queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response,expires_at) VALUES(:key,:text,'[]'::jsonb,clock_timestamp()+interval '1 day')",{key={value=oldKey,cfsqltype="cf_sql_varchar"},text={value=lookup.text,cfsqltype="cf_sql_varchar"}},options);
    queryExecute("UPDATE public.tb_geocoding_cache SET response=CAST(:body AS jsonb) WHERE cache_key=:key",{key={value=oldKey,cfsqltype="cf_sql_varchar"},body={value='[{"name":"A different place from a colliding request"}]',cfsqltype="cf_sql_longvarchar"}},options);
    check(!store.cacheGet(lookup).found,"Unverifiable legacy cache cannot supply even an apparently exact query");
    different=duplicate(lookup);different.text=replace(lookup.text,"Cache fixture","Cache-fixture");
    check(!store.cacheGet(different).found,"Ambiguous legacy key cannot supply a different query");
    store.cachePut(lookup,[]);check(store.cacheGet(lookup).found,"Verified v2 lookups are reused without provider consumption");
    transaction action="rollback";
}
transaction {
    queryExecute("UPDATE public.tb_geocoding_cache SET response=jsonb_set(response,'{dailyLimit}','2000'::jsonb),last_call_at=NULL,cooldown_until=NULL,provider_lease_token=NULL,provider_lease_until=NULL WHERE cache_key='__control__'",[],options);
    queryExecute("INSERT INTO public.tb_geocoding_usage_daily(usage_date,provider,calls) VALUES((clock_timestamp() AT TIME ZONE 'UTC')::date,'geoapify',1999) ON CONFLICT(usage_date,provider) DO UPDATE SET calls=1999",[],options);
    call=store.reserveCall(99999);check(call.allowed AND call.calls EQ 2000,"The 2,000th shared daily consultation can be reserved");
    store.completeCall(call.token,"ok");next=store.reserveCall(99999);
    check(!next.allowed AND next.reason EQ "pacing" AND next.waitMs GT 0,"A completed HTTP call still cannot bypass one-second pacing");
    queryExecute("UPDATE public.tb_geocoding_cache SET last_call_at=NULL WHERE cache_key='__control__'",[],options);
    next=store.reserveCall(99999);check(!next.allowed AND next.reason EQ "daily_limit","No caller can reserve consultation 2,001 even with a larger requested limit");
    transaction action="rollback";
}
writeOutput("GEO_ACCELERATION_PASSED");
</cfscript>
