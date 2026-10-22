<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
fixtureWorker=new services.geocoding.LocationWorker({apiKey="fixture",aiKey="fixture",aiModel="gpt-4.1-mini",aiDailyLimit=1000});
fixtureProgress=fixtureWorker.initialProgress({nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="São Paulo",estado="SP",pais="BR"},{documents=[]},{});
check(arrayLen(fixtureProgress.targets) EQ 1 AND fixtureProgress.targets[1].role EQ "evento" AND !fixtureProgress.targets[1].trusted,"No evidence produces only a municipal suggestion target");
fixtureContext={nome_evento="Corrida Parque das Flores",start_date="2026-11-15",cidade="São Paulo",estado="SP",pais="BR"};
fixtureResearch={documents=[{url="https://race.com/",sha256=repeatString("a",64),text="Corrida Parque das Flores 2026-11-15. Largada a definir em São Paulo/SP."}]};
fixtureReply={facts={event_name=fixtureContext.nome_evento,event_date=fixtureContext.start_date,identity_document=1,identity_quote="Corrida Parque das Flores 2026-11-15",locations=[{role="evento",name="a definir",address="",city="São Paulo",state="SP",country="BR",quote="Largada a definir em São Paulo/SP.",document_index=1,certainty="undefined"}]}};
fixtureProgress=fixtureWorker.initialProgress(fixtureContext,fixtureResearch,fixtureReply);check(fixtureProgress.targets[1].status EQ "pending" AND fixtureProgress.targets[1].query.kind EQ "city","Unconfirmed extracted race venue still preserves the registered city as a suggestion");
fixtureP=new services.geocoding.LocationStore();fixtureOptions={datasource="runner_dba"};
transaction {
 queryExecute("DELETE FROM public.tb_geocoding_usage_daily WHERE provider='openai-geolocation' AND usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date",[],fixtureOptions);
 queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response) VALUES('__ai_control__','openai-geolocation','{}'::jsonb) ON CONFLICT(cache_key) DO UPDATE SET cooldown_until=NULL",[],fixtureOptions);
 check(fixtureP.reserveAI(1).allowed AND !fixtureP.reserveAI(1).allowed,"OpenAI daily ceiling is reserved atomically before HTTP");
 fixtureP.completeAI({ok=false,code="ai_quota_exhausted",retryAfter=21600});check(!fixtureP.reserveAI(1000).allowed,"Quota exhaustion activates durable AI cooldown without losing the queue");
 transaction action="rollback";
}
check(fixtureWorker.responseStatus({status="ai_cooldown",errors=0,results=[]}) EQ 202,"AI cooldown is accepted deferred work, not a misleading gateway error");
writeOutput("GEO_AI_WORKFLOW_PASSED");
</cfscript>
