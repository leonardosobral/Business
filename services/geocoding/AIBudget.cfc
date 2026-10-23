component output=false {
    variables.namespace="geocoding-economy-v1";variables.db={datasource="runner_dba",timeout=10};
    public any function init(string namespace="geocoding-economy-v1"){
        if(!reFind("^[A-Za-z0-9-]{1,100}$",namespace))throw(message="Namespace inválido.");variables.namespace=namespace;return this;
    }
    private struct function bind(required any value){return {value=value,cfsqltype="cf_sql_varchar"};}
    private string function key(required string value){return lCase(hash(variables.namespace & "|" & value,"SHA-256"));}
    private string function today(){return createObject("java","java.time.LocalDate").now(createObject("java","java.time.ZoneId").of("UTC")).toString() & "";}
    private any function wire(required any value){if(isStruct(value)){var o=structNew("ordered-casesensitive");for(var k in value)o[lCase(k)]=wire(value[k]);return o;}if(isArray(value)){var a=[];for(var item in value)arrayAppend(a,wire(item));return a;}return value;}
    private void function guard(){
        queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response,expires_at) VALUES(:id,:namespace,'{}'::jsonb,'infinity') ON CONFLICT DO NOTHING",{id=bind(key("control")),namespace=bind(variables.namespace & "-lock")},variables.db);
        queryExecute("SELECT cache_key FROM public.tb_geocoding_cache WHERE cache_key=:id FOR UPDATE",{id=bind(key("control"))},variables.db);
    }
    public struct function get(required string id){var q=queryExecute("SELECT response::text AS body FROM public.tb_geocoding_cache WHERE cache_key=:id AND query_text=:namespace",{id=bind(key(id)),namespace=bind(variables.namespace)},variables.db);return q.recordCount ? deserializeJSON(q.body[1]) : {};}
    private void function put(required string id,required struct record){
        var body=serializeJSON(wire(record));if(len(body) GT 200000)throw(message="Registro econômico acima do limite.");
        queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response,expires_at) VALUES(:id,:namespace,CAST(:body AS jsonb),'infinity') ON CONFLICT(cache_key) DO UPDATE SET response=excluded.response,expires_at='infinity',updated_at=clock_timestamp()",{id=bind(key(id)),namespace=bind(variables.namespace),body={value=body,cfsqltype="cf_sql_longvarchar"}},variables.db);
    }
    public struct function status(){
        var day=today();var q=queryExecute("SELECT COALESCE(sum(CASE WHEN response->>'state'<>'done' THEN (response->>'reserved_micros')::numeric ELSE 0 END),0) AS held,COALESCE(sum(CASE WHEN response->>'state'='done' AND response->>'settled_day'=:day THEN (response->>'charged_micros')::numeric ELSE 0 END),0) AS daily,COALESCE(sum(CASE WHEN response->>'state'='done' AND left(response->>'settled_day',7)=left(:day,7) THEN (response->>'charged_micros')::numeric ELSE 0 END),0) AS monthly,count(*) FILTER(WHERE response->>'state'='uncertain') AS uncertain,count(*) FILTER(WHERE response->>'state'<>'done' AND response->>'tier'='batch') AS batches,count(*) FILTER(WHERE response->>'breach'='true') AS breaches FROM public.tb_geocoding_cache WHERE query_text=:namespace",{day=bind(day),namespace=bind(variables.namespace)},variables.db);
        var legacy=legacySpend(day);var daily=q.daily[1]+legacy.daily;var monthly=q.monthly[1]+legacy.monthly;
        var captured=queryExecute("SELECT COALESCE(sum((response->>'charged_micros')::numeric),0) AS amount FROM public.tb_geocoding_cache WHERE query_text=:namespace AND response->>'legacy'='true' AND left(response->>'settled_day',7)=left(:day,7)",{namespace=bind(variables.namespace),day=bind(day)},variables.db);
        return {day_limit=2,month_limit=30,day_usd=daily/1000000,month_usd=monthly/1000000,pending_usd=q.held[1]/1000000,legacy_month_usd=(legacy.monthly+captured.amount[1])/1000000,uncertain=q.uncertain[1],batches=q.batches[1],blocked=q.breaches[1] GT 0 OR daily+q.held[1] GTE 2000000 OR monthly+q.held[1] GTE 30000000,day=day};
    }
    public struct function initialize(){
        transaction{
            guard();
            if(variables.namespace EQ "geocoding-economy-v1" AND !structKeyExists(get("legacy-captured"),"captured")){
                for(var row in legacyRows())put("legacy-" & row.day,{id="legacy-" & row.day,state="done",legacy=true,reserved_micros=0,charged_micros=ceiling(row.amount),settled_day=row.day});
                put("legacy-captured",{captured=true,state="done",reserved_micros=0,charged_micros=0,settled_day=today()});
            }
            return status();
        }
    }
    private struct function legacySpend(required string day){
        if(variables.namespace NEQ "geocoding-economy-v1" OR structKeyExists(get("legacy-captured"),"captured"))return {daily=0,monthly=0};
        // Legacy cache is disjoint from the new namespace. Count known historical
        // usage conservatively; rollout must not grant a fresh monthly allowance.
        var total={daily=0,monthly=0};for(var row in legacyRows()){if(row.day EQ day)total.daily+=ceiling(row.amount);if(left(row.day,7) EQ left(day,7))total.monthly+=ceiling(row.amount);}return total;
    }
    private query function legacyRows(){return queryExecute("WITH legacy AS(SELECT to_char(updated_at AT TIME ZONE 'UTC','YYYY-MM-DD') AS day,COALESCE(response->>'model',response->>'MODEL','') AS model,COALESCE(response->'usage',response->'USAGE','{}'::jsonb) AS u FROM public.tb_geocoding_cache WHERE query_text='public-source-evidence' AND (jsonb_exists(response,'facts') OR jsonb_exists(response,'FACTS'))), prices AS(SELECT day,CASE WHEN model LIKE 'gpt-6-astra%' THEN 10 WHEN model LIKE 'gpt-6.1-sol%' THEN 2 WHEN model LIKE 'gpt-4.1-mini%' THEN 0.4 ELSE 10 END AS ir,CASE WHEN model LIKE 'gpt-6-astra%' THEN 50 WHEN model LIKE 'gpt-6.1-sol%' THEN 10 WHEN model LIKE 'gpt-4.1-mini%' THEN 1.6 ELSE 50 END AS outr,u FROM legacy) SELECT day,COALESCE(sum(COALESCE(u->>'input_tokens',u->>'INPUT_TOKENS','0')::numeric*ir*2.5+COALESCE(u->>'output_tokens',u->>'OUTPUT_TOKENS','0')::numeric*outr),0) AS amount FROM prices GROUP BY day",[],variables.db);}
    public struct function reserve(required string id,required string model,required string tier,required numeric usd){
        if(!len(id) OR len(id) GT 200 OR !listFind("gpt-6.1-sol,gpt-6-astra",model) OR !listFind("default,batch",tier) OR usd LTE 0 OR usd GT 2) return {allowed=false,created=false,reason="ai_budget_request"};
        if(variables.namespace EQ "geocoding-economy-v1")this.initialize();
        transaction{
            guard();var previous=get(id);if(!structIsEmpty(previous))return {allowed=true,created=false,record=previous};
            var limits=status();var amount=ceiling(usd*1000000);
            if(limits.blocked OR limits.day_usd*1000000+limits.pending_usd*1000000+amount GT 2000000 OR limits.month_usd*1000000+limits.pending_usd*1000000+amount GT 30000000)return {allowed=false,created=false,reason="ai_budget_limit"};
            var record={id=id,state="reserved",model=model,tier=tier,reserved_micros=amount,created_day=today(),reply={},created_ms=createObject("java","java.lang.System").currentTimeMillis()};put(id,record);return {allowed=true,created=true,record=record};
        }
    }
    public struct function update(required string id,required struct patch){
        transaction{guard();var record=get(id);if(structIsEmpty(record))throw(message="Reserva não encontrada.");
            for(var k in patch){if(!listFindNoCase("state,batch_id,file_id,custom_id,reply,last_poll_ms",k))throw(message="Campo de reserva inválido.");record[lCase(k)]=patch[k];}
            if(!listFind("reserved,uploaded,submitted,uncertain",record.state))throw(message="Estado inválido.");put(id,record);return record;
        }
    }
    public struct function settle(required string id,required struct reply){
        transaction{
            guard();var record=get(id);if(structIsEmpty(record))throw(message="Reserva não encontrada.");if(record.state EQ "done")return record;
            var usage=structKeyExists(reply,"usage") AND isStruct(reply.usage) ? reply.usage : {};
            var meter=new services.openaiUsage.Pricing().meter(usage);record.reply=reply;
            if(meter.known){
                // Charge an upper bound when old usage lacks cache write details.
                var rate=record.model EQ "gpt-6-astra" ? 10 : 2;
                var charge=ceiling((meter.input*rate*2.5+meter.output*rate*5)*(record.tier EQ "batch" ? 0.5 : 1));
                if(charge GT record.reserved_micros){record.breach=true;record.state="uncertain";}else{record.state="done";record.charged_micros=charge;record.settled_day=today();}
            }else record.state="uncertain";
            put(id,record);return record;
        }
    }
    public array function pending(numeric limit=3){
        var q=queryExecute("SELECT response::text AS body FROM public.tb_geocoding_cache WHERE query_text=:namespace AND response->>'state'='submitted' ORDER BY updated_at LIMIT :limit",{namespace=bind(variables.namespace),limit={value=max(1,min(5,int(limit))),cfsqltype="cf_sql_integer"}},variables.db);var out=[];for(var r in q)arrayAppend(out,deserializeJSON(r.body));return out;
    }
}
