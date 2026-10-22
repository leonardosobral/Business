<cfscript>
fixtureData=queryExecute("SELECT cache_key,response::text AS body FROM public.tb_geocoding_cache WHERE jsonb_exists(response,'FACTS') OR jsonb_exists(response,'facts') ORDER BY updated_at DESC LIMIT 12",[],{datasource="runner_dba"});fixtureOut=[];
for(fixtureRow in fixtureData){fixtureReply=deserializeJSON(fixtureRow.body);arrayAppend(fixtureOut,{cache=fixtureRow.cache_key,name=fixtureReply.facts.event_name,date=fixtureReply.facts.event_date,locations=arrayLen(fixtureReply.facts.locations)});}
fixtureEvents=queryExecute("SELECT e.id_evento,e.nome_evento,to_char(e.data_inicial,'YYYY-MM-DD') AS date FROM public.tb_evento_corridas e WHERE id_evento=48602",[],{datasource="runner_dba"});
fixtureControl=queryExecute("SELECT response::text AS body,greatest(0,ceil(extract(epoch FROM(cooldown_until-clock_timestamp())))) AS seconds FROM public.tb_geocoding_cache WHERE cache_key='__ai_control__'",[],{datasource="runner_dba"});
writeOutput(serializeJSON({cached=fixtureOut,event_name=fixtureEvents.nome_evento[1],event_date=fixtureEvents.date[1],control=deserializeJSON(fixtureControl.body[1]),cooldown=fixtureControl.seconds[1]}));writeOutput("GEO_AI_CACHE_INSPECT_PASSED");
</cfscript>
