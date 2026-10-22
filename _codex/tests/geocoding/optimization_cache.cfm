<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureClient=new services.geocoding.AIClient("fixture-only","gpt-6-astra");
context={nome_evento="Prova Flores",start_date="2026-11-20",cidade="São Paulo",estado="SP",pais="BR"};
docs=[{url="https://example.com/oficial",sha256=repeatString("a",64),text="Prova Flores 2026-11-20 Largada: Avenida Paulista, São Paulo/SP."}];
key=fixtureClient.cacheKey(context,docs,"gpt-6-astra");docs[1].sha256=repeatString("b",64);
check(key EQ fixtureClient.cacheKey(context,docs,"gpt-6-astra"),"Dynamic HTML digest does not invalidate identical extraction input");
docs[1].text &= " Local alterado.";check(key NEQ fixtureClient.cacheKey(context,docs,"gpt-6-astra"),"Changed evidence invalidates extraction cache");
docs[1].text=replace(docs[1].text," Local alterado.","");context.start_date="2026-11-21";
check(key NEQ fixtureClient.cacheKey(context,docs,"gpt-6-astra"),"Changed edition invalidates extraction cache");
context.start_date="2026-11-20";check(key NEQ fixtureClient.cacheKey(context,docs,"gpt-4.1-mini"),"Changed model invalidates extraction cache");
store=new services.geocoding.LocationStore();transaction {
 store.resourcePut("optimization-short-cache",{ok=true},1,120);
 cache=queryExecute("SELECT extract(epoch FROM(expires_at-clock_timestamp())) AS ttl FROM public.tb_geocoding_cache WHERE cache_key=:key",{key={value=lCase(hash("source-v3|optimization-short-cache","SHA-256")),cfsqltype="cf_sql_varchar"}},{datasource="runner_dba"});
 check(cache.ttl[1] GT 100 AND cache.ttl[1] LTE 120,"Transient source cache expires in minutes, not a full day");
 transaction action="rollback";
}
writeOutput("GEO_OPTIMIZATION_CACHE_PASSED");
</cfscript>
