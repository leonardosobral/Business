component output=false {
    variables.options={datasource="runner_dba"};
    variables.policy=new services.geocoding.Policy();
    private struct function first(required query rows) {for(var r in rows)return r;return {};}
    private struct function p(required any value,string type="cf_sql_varchar") {return {value=value,cfsqltype=type};}
    public numeric function identifier(required any value) {
        if(!isSimpleValue(value) OR !reFind("^[1-9][0-9]{0,14}$",trim(value & ""))) throw(type="Geocoding.Validation",message="Identificador inválido.");
        return val(value);
    }
    public boolean function isReady() {
        var q=queryExecute("SELECT to_regclass('public.tb_evento_geocoding') IS NOT NULL AND to_regclass('public.tb_evento_geocoding_audit') IS NOT NULL AND to_regclass('public.tb_geocoding_cache') IS NOT NULL AND to_regclass('public.tb_geocoding_usage_daily') IS NOT NULL AND (SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND ((table_name='tb_evento_geocoding' AND column_name='proposal_revision') OR (table_name='tb_geocoding_cache' AND column_name IN ('provider_lease_token','provider_lease_until'))))=3 AS ready",[],variables.options);
        return q.ready[1];
    }
    public struct function event(required numeric id,boolean locked=false) {
        var flags=[];for(var key in listToArray("id_evento,cidade,estado,pais,cod_cidade,endereco,descricao_original,descricao,coordenadas,nome_evento,url_hotsite,url_inscricao"))arrayAppend(flags,"CASE WHEN e." & key & " IS NULL THEN '" & key & "' END");
        var q=queryExecute("SELECT /* geocoding-locations-v3 */ e.*,to_char(e.data_inicial,'YYYY-MM-DD') AS source_start_date,c.nome_cidade AS catalog_city,c.uf AS catalog_state,array_to_json(array_remove(ARRAY[" & arrayToList(flags,",") & "],NULL))::text AS source_nulls FROM public.tb_evento_corridas e LEFT JOIN public.tb_cidades c ON c.cod_cidade=e.cod_cidade WHERE e.id_evento=:id" & (locked ? " FOR UPDATE OF e" : ""),{id=p(id,"cf_sql_integer")},variables.options);
        var r=first(q);r.exists=q.recordCount GT 0;if(r.exists)r._sourceNulls=deserializeJSON(r.source_nulls);return r;
    }
    private string function sourceExpression() {
        var items=[];var field="";
        for(field in listToArray("id_evento,cidade,estado,pais,cod_cidade,endereco,descricao_original,descricao,coordenadas,nome_evento,url_hotsite,url_inscricao"))
            arrayAppend(items,"jsonb_build_array(e." & field & " IS NULL,COALESCE(e." & field & "::text,''))");
        arrayAppend(items,"jsonb_build_array(COALESCE(c.nome_cidade,''),COALESCE(c.uf,''))");
        arrayAppend(items,"jsonb_build_array(COALESCE(to_char(e.data_inicial,'YYYY-MM-DD'),''),2)");
        return "jsonb_build_array(" & arrayToList(items,",") & ")";
    }
    private void function audit(required struct work,required string action,required string actor,required struct details,string after="") {
        var source=deserializeJSON(work.source_snapshot & "");
        queryExecute("INSERT INTO public.tb_evento_geocoding_audit(work_id,id_evento,action,actor,source_hash,coordinates_before,coordinates_after,details) VALUES(:work,:event,:action,:actor,:hash,:before,:after,CAST(:details AS jsonb))",{
            work=p(work.id,"cf_sql_bigint"),event=p(work.id_evento,"cf_sql_integer"),action=p(action),actor=p(left(actor,64)),hash=p(work.source_hash),
            before={value=source.coordenadas,null=arrayFindNoCase(source.nulls,"coordenadas") GT 0,cfsqltype="cf_sql_longvarchar"},
            after={value=after,null=!len(after),cfsqltype="cf_sql_longvarchar"},details=p(serializeJSON(details),"cf_sql_longvarchar")},variables.options);
    }
    public array function enqueue(required array ids,required string actor) {
        if(arrayLen(ids) GT 20) throw(type="Geocoding.Validation",message="Selecione no máximo 20 eventos por lote.");
        var out=[];var id=0;var e={};var s={};var q="";var priority=100;var work={};
        for(id in ids) {
            id=identifier(id);if(id GT 2147483647)throw(type="Geocoding.Validation",message="Evento inválido.");
            e=event(id);if(!e.exists OR len(trim(variables.policy.text(e,"coordenadas"))))continue;
            s=variables.policy.snapshot(e);priority=isDate(e.data_inicial) AND dateCompare(e.data_inicial,now(),"d") GTE 0 ? 0 : 100;
            transaction {
                q=queryExecute("INSERT INTO public.tb_evento_geocoding(id_evento,source_hash,source_snapshot,source_values,priority) VALUES(:event,:hash,CAST(:snapshot AS jsonb),CAST(:values AS jsonb),:priority) ON CONFLICT(id_evento,source_hash) DO UPDATE SET status='pending',attempts=0,error_code=NULL,next_retry_at=NULL,lease_token=NULL,lease_until=NULL,decision='{}'::jsonb,proposal_revision=tb_evento_geocoding.proposal_revision+1,updated_at=clock_timestamp() WHERE tb_evento_geocoding.status<>'running' OR tb_evento_geocoding.lease_until<clock_timestamp() RETURNING *",{
                    event=p(id,"cf_sql_integer"),hash=p(variables.policy.sourceHash(s)),snapshot=p(serializeJSON(s),"cf_sql_longvarchar"),values=p(serializeJSON(variables.policy.sourceValues(s)),"cf_sql_longvarchar"),priority=p(priority,"cf_sql_integer")},variables.options);
                if(q.recordCount){work=first(q);arrayAppend(out,work.id);audit(work,"enqueued",actor,{reason="current_source"});}
            }
        }
        return out;
    }
    public numeric function seed(numeric limit=5) {
        var count=queryExecute("SELECT count(*) AS total FROM public.tb_evento_geocoding WHERE status IN ('pending','running','error')",[],variables.options);
        if(count.total[1] GTE 20)return 0;
        var rows=queryExecute("SELECT e.id_evento FROM public.tb_evento_corridas e LEFT JOIN public.tb_cidades c ON c.cod_cidade=e.cod_cidade WHERE btrim(COALESCE(e.coordenadas,''))='' AND NOT EXISTS(SELECT 1 FROM public.tb_evento_geocoding g WHERE g.id_evento=e.id_evento AND g.source_values=" & sourceExpression() & ") ORDER BY CASE WHEN e.ativo IS NOT TRUE THEN 3 WHEN e.data_inicial>=CURRENT_DATE THEN 0 WHEN e.data_final>=CURRENT_DATE THEN 1 ELSE 2 END,CASE WHEN e.data_inicial>=CURRENT_DATE THEN e.data_inicial END ASC,e.data_inicial DESC,e.id_evento DESC LIMIT :limit",{limit=p(max(1,min(5,int(limit))),"cf_sql_integer")},variables.options);
        var ids=[];for(var r in rows)arrayAppend(ids,r.id_evento);
        return arrayLen(enqueue(ids,"job"));
    }
    public struct function claim(numeric id=0) {
        transaction {
            var expired=queryExecute("UPDATE public.tb_evento_geocoding SET status='errors_exhausted',error_code='lease_expired',lease_token=NULL,lease_until=NULL,next_retry_at=NULL,updated_at=clock_timestamp(),proposal_revision=proposal_revision+1 WHERE id IN(SELECT id FROM public.tb_evento_geocoding WHERE status='running' AND lease_until<clock_timestamp() AND attempts>=3 ORDER BY id FOR UPDATE SKIP LOCKED LIMIT 20) RETURNING *",[],variables.options);
            for(var work in expired)audit(work,"errors_exhausted","job",{reason="lease_expired"});
        }
        var token=lCase(replace(createUUID(),"-","","all"));
        var q=queryExecute("UPDATE public.tb_evento_geocoding SET status='running',lease_token=:token,lease_until=clock_timestamp()+interval '10 minutes',attempts=attempts+1,updated_at=clock_timestamp() WHERE id=(SELECT id FROM public.tb_evento_geocoding WHERE (:id=0 OR id=:id) AND ((status IN ('pending','error') AND attempts<3 AND (next_retry_at IS NULL OR next_retry_at<=clock_timestamp())) OR (status IN('city_suggestion','insufficient_data') AND attempts<3 AND next_retry_at<=clock_timestamp()) OR (status='running' AND lease_until<clock_timestamp() AND attempts<3)) ORDER BY priority,id FOR UPDATE SKIP LOCKED LIMIT 1) RETURNING *",{id=p(id,"cf_sql_bigint"),token=p(token)},variables.options);
        return first(q);
    }
    public struct function finish(required struct work,required struct result,required string actor) {
        var current={};var e={};var decision=duplicate(result);var status=decision.status;var after="";var params={};
        if(!listFind("auto_applied,approved,city_suggestion,needs_review,insufficient_data,error,errors_exhausted",status))throw(type="Geocoding.Validation",message="Resultado de localização inválido.");
        transaction {
            current=first(queryExecute("SELECT *,lease_until>clock_timestamp() AS lease_valid FROM public.tb_evento_geocoding WHERE id=:id FOR UPDATE",{id=p(work.id,"cf_sql_bigint")},variables.options));
            if(structIsEmpty(current) OR current.status NEQ "running" OR !current.lease_valid OR variables.policy.text(current,"lease_token") NEQ work.lease_token)throw(type="Geocoding.Validation",message="O processamento expirou ou foi assumido por outra execução.");
            e=event(current.id_evento,true);
            if(!e.exists OR variables.policy.sourceHash(variables.policy.snapshot(e)) NEQ current.source_hash OR len(variables.policy.text(e,"coordenadas"))) {status="conflict";decision={status=status,reasons=["source_changed"],candidate={}};}
            else if(listFind("auto_applied,approved",status)) {
                if(!structKeyExists(decision,"candidate") OR !variables.policy.specificCandidate(variables.policy.snapshot(e),decision.candidate))throw(type="Geocoding.Validation",message="A proposta não é um local específico compatível com o evento.");
                after=variables.policy.coordinates(decision.candidate.lat & "," & decision.candidate.lon).value;
                queryExecute("UPDATE public.tb_evento_corridas SET coordenadas=:coords WHERE id_evento=:id AND btrim(COALESCE(coordenadas,''))=''",{coords=p(after),id=p(current.id_evento,"cf_sql_integer")},variables.options);
            }
            if(status EQ "error" AND current.attempts GTE 3)status="errors_exhausted";
            decision.status=status;
            queryExecute("UPDATE public.tb_evento_geocoding SET status=:status,decision=CAST(:decision AS jsonb),error_code=:code,lease_token=NULL,lease_until=NULL,proposal_revision=proposal_revision+1,next_retry_at=CASE WHEN :status='error' THEN clock_timestamp()+CASE WHEN attempts=1 THEN interval '5 minutes' ELSE interval '30 minutes' END WHEN :sourceRetry=1 AND :status IN('city_suggestion','insufficient_data') AND attempts<3 THEN clock_timestamp()+CASE WHEN attempts=1 THEN interval '30 minutes' ELSE interval '6 hours' END ELSE NULL END,updated_at=clock_timestamp() WHERE id=:id",{
                sourceRetry=p(structKeyExists(decision,"sourceRetry") AND decision.sourceRetry ? 1 : 0,"cf_sql_integer"),status=p(status),decision=p(serializeJSON(decision),"cf_sql_longvarchar"),code={value=variables.policy.text(decision,"code"),null=!len(variables.policy.text(decision,"code")),cfsqltype="cf_sql_varchar"},id=p(current.id,"cf_sql_bigint")},variables.options);
            audit(current,status,actor,decision,after);
        }
        return {id=work.id,id_evento=work.id_evento,status=status};
    }
    public void function defer(required struct work,numeric seconds=60) {
        queryExecute("UPDATE public.tb_evento_geocoding SET status='pending',attempts=greatest(0,attempts-1),lease_token=NULL,lease_until=NULL,next_retry_at=clock_timestamp()+:seconds*interval '1 second',updated_at=clock_timestamp() WHERE id=:id AND status='running' AND lease_token=:token",{id=p(work.id,"cf_sql_bigint"),token=p(work.lease_token),seconds=p(max(1,min(86400,seconds)),"cf_sql_integer")},variables.options);
    }
    public struct function settings() {
        var q=queryExecute("SELECT response::text AS config FROM public.tb_geocoding_cache WHERE cache_key='__control__'",[],variables.options);
        if(!q.recordCount)throw(type="Geocoding.Validation",message="Configuração da geolocalização indisponível.");
        return deserializeJSON(q.config[1]);
    }
    public void function saveSettings(required boolean enabled,required numeric limit,required string fingerprint) {
        if(limit LT 1 OR limit GT 3000 OR int(limit) NEQ limit)throw(type="Geocoding.Validation",message="O limite diário deve estar entre 1 e 3.000 chamadas.");
        transaction {
            var row=first(queryExecute("SELECT response::text AS config FROM public.tb_geocoding_cache WHERE cache_key='__control__' FOR UPDATE",[],variables.options));
            var config=deserializeJSON(row.config);
            if(enabled AND (!len(fingerprint) OR config.validatedFingerprint NEQ fingerprint))throw(type="Geocoding.Validation",message="Valide a conexão com a chave atual antes de ativar.");
            config.enabled=enabled;config.dailyLimit=limit;
            queryExecute("UPDATE public.tb_geocoding_cache SET response=CAST(:config AS jsonb),updated_at=clock_timestamp() WHERE cache_key='__control__'",{config=p(serializeJSON(config),"cf_sql_longvarchar")},variables.options);
        }
    }
    public struct function providerState() {
        return first(queryExecute("SELECT greatest(0,ceil(extract(epoch FROM (cooldown_until-clock_timestamp())))) AS cooldown, greatest(0,ceil(extract(epoch FROM (last_call_at+interval '1 second'-clock_timestamp()))*1000)) AS wait_ms FROM public.tb_geocoding_cache WHERE cache_key='__control__'",[],variables.options));
    }
    public struct function acquireWorker() {
        var token=lCase(replace(createUUID(),"-","","all"));
        // A durable token survives requests and pooled JDBC connections. The lease
        // outlives the endpoint's hard 60s timeout; abandoned batches recover safely.
        var q=queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response,provider_lease_token,provider_lease_until) VALUES('__worker__','batch-lease','{}'::jsonb,:token,clock_timestamp()+interval '120 seconds') ON CONFLICT(cache_key) DO UPDATE SET provider_lease_token=excluded.provider_lease_token,provider_lease_until=excluded.provider_lease_until,updated_at=clock_timestamp() WHERE tb_geocoding_cache.provider_lease_until IS NULL OR tb_geocoding_cache.provider_lease_until<=clock_timestamp() RETURNING provider_lease_token",{token=p(token)},variables.options);
        return {allowed=q.recordCount GT 0,token=q.recordCount ? token : ""};
    }
    public boolean function workerValid(required string token) {
        return queryExecute("SELECT 1 FROM public.tb_geocoding_cache WHERE cache_key='__worker__' AND provider_lease_token=:token AND provider_lease_until>clock_timestamp()",{token=p(token)},variables.options).recordCount GT 0;
    }
    public boolean function releaseWorker(required string token) {
        return queryExecute("UPDATE public.tb_geocoding_cache SET provider_lease_token=NULL,provider_lease_until=NULL,updated_at=clock_timestamp() WHERE cache_key='__worker__' AND provider_lease_token=:token RETURNING cache_key",{token=p(token)},variables.options).recordCount GT 0;
    }
    public struct function reserveCall(required numeric limit) {
        var used="";var row={};var settings={};var token=lCase(replace(createUUID(),"-","","all"));
        transaction {
            row=first(queryExecute("SELECT response::text AS config,COALESCE(provider_lease_until>clock_timestamp(),false) AS in_flight,greatest(0,ceil(extract(epoch FROM (cooldown_until-clock_timestamp())))) AS cooldown,greatest(0,ceil(extract(epoch FROM (last_call_at+interval '1 second'-clock_timestamp()))*1000)) AS wait_ms FROM public.tb_geocoding_cache WHERE cache_key='__control__' FOR UPDATE",[],variables.options));
            if(row.cooldown GT 0)return {allowed=false,reason="provider_cooldown",retryAfter=row.cooldown};
            if(row.in_flight)return {allowed=false,reason="provider_busy",retryAfter=30};
            if(row.wait_ms GT 0)return {allowed=false,reason="pacing",waitMs=row.wait_ms};
            settings=deserializeJSON(row.config);
            used=queryExecute("INSERT INTO public.tb_geocoding_usage_daily(usage_date,provider,calls) VALUES((clock_timestamp() AT TIME ZONE 'UTC')::date,'geoapify',1) ON CONFLICT(usage_date,provider) DO UPDATE SET calls=tb_geocoding_usage_daily.calls+1 WHERE tb_geocoding_usage_daily.calls<:limit RETURNING calls",{limit=p(max(1,min(3000,min(settings.dailyLimit,limit))),"cf_sql_integer")},variables.options);
            if(!used.recordCount)return {allowed=false,reason="daily_limit",retryAfter=3600};
            queryExecute("UPDATE public.tb_geocoding_cache SET last_call_at=clock_timestamp(),provider_lease_token=:token,provider_lease_until=clock_timestamp()+interval '30 seconds' WHERE cache_key='__control__'",{token=p(token)},variables.options);
        }
        return {allowed=true,calls=used.calls[1],token=token};
    }
    public boolean function completeCall(required string token,required string code,numeric seconds=0,string fingerprint="") {
        transaction {
            var row=first(queryExecute("SELECT response::text AS config,provider_lease_token,greatest(0,ceil(extract(epoch FROM(cooldown_until-clock_timestamp())))) AS cooldown FROM public.tb_geocoding_cache WHERE cache_key='__control__' FOR UPDATE",[],variables.options));
            // A late response from a previous lease cannot alter a newer call or its cooldown.
            if(variables.policy.text(row,"provider_lease_token") NEQ token)return false;
            var config=deserializeJSON(row.config);
            if(code NEQ "ok")config.blockedReason=left(code,64);
            if(code EQ "ok" AND row.cooldown LTE 0)config.blockedReason="";
            if(code EQ "credentials_rejected")config.validatedFingerprint="";
            if(code EQ "ok" AND len(fingerprint) AND row.cooldown LTE 0){config.validatedFingerprint=fingerprint;config.blockedReason="";}
            queryExecute("UPDATE public.tb_geocoding_cache SET cooldown_until=CASE WHEN :seconds>0 THEN greatest(cooldown_until,clock_timestamp()+:seconds*interval '1 second') ELSE cooldown_until END,response=CAST(:config AS jsonb),provider_lease_token=NULL,provider_lease_until=NULL,updated_at=clock_timestamp() WHERE cache_key='__control__'",{seconds=p(max(0,min(86400,seconds)),"cf_sql_integer"),config=p(serializeJSON(config),"cf_sql_longvarchar")},variables.options);
        }
        return true;
    }
    private string function cacheText(required string value) {return reReplace(lCase(trim(value)),"\s+"," ","all");}
    public string function cacheKey(required struct lookup) {return lCase(hash("geoapify-v2|" & lookup.kind & "|" & lCase(lookup.country) & "|" & cacheText(lookup.text),"SHA-256"));}
    public struct function resourceGet(required string key) {
        var q=queryExecute("SELECT response::text AS body FROM public.tb_geocoding_cache WHERE cache_key=:key AND expires_at>clock_timestamp()",{key=p(lCase(hash("source-v3|" & key,"SHA-256")))},variables.options);
        return q.recordCount ? {found=true,value=deserializeJSON(q.body[1])} : {found=false,value={}};
    }
    public void function resourcePut(required string key,required struct value,numeric days=1) {
        queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response,expires_at) VALUES(:key,'public-source-evidence',CAST(:body AS jsonb),clock_timestamp()+:days*interval '1 day') ON CONFLICT(cache_key) DO UPDATE SET response=excluded.response,expires_at=excluded.expires_at,updated_at=clock_timestamp()",{key=p(lCase(hash("source-v3|" & key,"SHA-256"))),body=p(serializeJSON(value),"cf_sql_longvarchar"),days=p(max(1,min(7,days)),"cf_sql_integer")},variables.options);
    }
    public struct function cacheGet(required struct lookup) {
        var q=queryExecute("SELECT response::text AS body FROM public.tb_geocoding_cache WHERE cache_key=:key AND expires_at>clock_timestamp()",{key=p(cacheKey(lookup))},variables.options);
        // Do not fall back to v1: its punctuation collisions and old upserts
        // cannot prove which query produced an entry, even if query_text matches.
        return q.recordCount ? {found=true,results=deserializeJSON(q.body[1])} : {found=false,results=[]};
    }
    public void function cachePut(required struct lookup,required array results) {
        queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response,expires_at) VALUES(:key,:query,CAST(:body AS jsonb),clock_timestamp()+:days*interval '1 day') ON CONFLICT(cache_key) DO UPDATE SET response=excluded.response,expires_at=excluded.expires_at,updated_at=clock_timestamp()",{key=p(cacheKey(lookup)),query=p(left(lookup.text,500)),body=p(serializeJSON(results),"cf_sql_longvarchar"),days=p(arrayLen(results) ? 90 : 7,"cf_sql_integer")},variables.options);
    }
    public struct function detail(required numeric id) {
        return first(queryExecute("SELECT g.*,e.nome_evento,e.cidade,e.estado,to_char(g.updated_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS changed_at FROM public.tb_evento_geocoding g JOIN public.tb_evento_corridas e ON e.id_evento=g.id_evento WHERE g.id=:id",{id=p(id,"cf_sql_bigint")},variables.options));
    }
    public struct function review(required numeric id,required string action,required string actor,required string reason,string revision="") {
        if(!listFind("approve,reject",action) OR len(reason) GT 1000)throw(type="Geocoding.Validation",message="Revisão inválida. A observação opcional aceita até 1.000 caracteres.");
        var reviewReason=len(trim(reason)) ? trim(reason) : (action EQ "approve" ? "Local específico conferido pelo administrador." : "Sugestão descartada pelo administrador.");
        var work={};var decision={};var e={};var out={};
        transaction {
            work=first(queryExecute("SELECT * FROM public.tb_evento_geocoding WHERE id=:id FOR UPDATE",{id=p(id,"cf_sql_bigint")},variables.options));
            if(structIsEmpty(work) OR !listFind("needs_review,city_suggestion,insufficient_data",work.status))throw(type="Geocoding.Validation",message="Esta proposta não está disponível para revisão.");
            variables.policy.requireRevision(work,revision);
            decision=deserializeJSON(work.decision & "");e=event(work.id_evento,true);
            if(action EQ "approve") {
                if(work.status EQ "city_suggestion" OR !structKeyExists(decision,"candidate") OR !variables.policy.specificCandidate(variables.policy.snapshot(e),decision.candidate))throw(type="Geocoding.Validation",message="Uma cidade ou localização incompatível não pode ser aprovada como local da prova.");
                if(variables.policy.sourceHash(variables.policy.snapshot(e)) NEQ work.source_hash)throw(type="Geocoding.Validation",message="Os dados do evento mudaram. Reprocesse a proposta.");
                work.lease_token=lCase(replace(createUUID(),"-","","all"));
                queryExecute("UPDATE public.tb_evento_geocoding SET status='running',lease_token=:token,lease_until=clock_timestamp()+interval '10 minutes' WHERE id=:id",{token=p(work.lease_token),id=p(id,"cf_sql_bigint")},variables.options);
                decision.status="approved";decision.reviewReason=reviewReason;out=finish(work,decision,actor);
            } else {
                queryExecute("UPDATE public.tb_evento_geocoding SET status='rejected',updated_at=clock_timestamp() WHERE id=:id",{id=p(id,"cf_sql_bigint")},variables.options);
                audit(work,"rejected",actor,{reason=reviewReason});out={id=id,status="rejected"};
            }
        }
        return out;
    }
    public struct function overview() {
        var q=queryExecute("WITH latest AS(SELECT DISTINCT ON(id_evento) id_evento,status,source_snapshot FROM public.tb_evento_geocoding ORDER BY id_evento,id DESC) SELECT (SELECT count(*) FROM public.tb_evento_corridas WHERE btrim(COALESCE(coordenadas,''))='') AS missing,(SELECT count(*) FROM latest WHERE status IN ('pending','running','error')) AS queued,(SELECT count(*) FROM latest WHERE status='needs_review' AND COALESCE(source_snapshot->>'VERSION',source_snapshot->>'version','1')='2') AS review,(SELECT count(*) FROM latest WHERE status='city_suggestion') AS suggestions,(SELECT count(*) FROM latest WHERE status IN ('auto_applied','approved')) AS applied,(SELECT count(*) FROM latest WHERE status NOT IN('pending','running','error','conflict')) AS analyzed,COALESCE((SELECT calls FROM public.tb_geocoding_usage_daily WHERE usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date AND provider='geoapify'),0) AS calls",[],variables.options);
        return first(q);
    }
    public numeric function nextReview(required numeric current,required string tab,required string search,required string period,required string uf) {
        var rows=page(tab,1,search,"todos",period,uf);
        for(var row in rows)if(row.work_id NEQ current)return row.work_id;
        return 0;
    }
    public query function page(required string tab,required numeric page,required string search,required string status,required string period,required string uf) {
        var params={offset=p((max(1,min(9999,int(page)))-1)*20,"cf_sql_integer"),search=p("%" & left(search,100) & "%"),empty=p(!len(search) ? 1 : 0,"cf_sql_integer"),uf=p(uf)};
        var filter="(:empty=1 OR e.nome_evento ILIKE :search OR e.cidade ILIKE :search OR e.id_evento::text ILIKE :search) AND (:uf='' OR e.estado=:uf)";
        if(period EQ "proximos")filter &= " AND e.ativo=true AND e.data_inicial>=CURRENT_DATE";
        if(period EQ "historicos")filter &= " AND e.data_final<CURRENT_DATE";
        if(tab EQ "historico")return queryExecute("SELECT a.id AS audit_id,a.work_id,a.id_evento,e.nome_evento,e.cidade,e.estado,a.action AS status,a.actor,a.coordinates_before,a.coordinates_after,to_char(a.created_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS changed_at FROM public.tb_evento_geocoding_audit a JOIN public.tb_evento_corridas e ON e.id_evento=a.id_evento WHERE " & filter & " ORDER BY a.created_at DESC,a.id DESC LIMIT 21 OFFSET :offset",params,variables.options);
        if(listFind("revisao,cidades",tab))return queryExecute("SELECT g.id AS work_id,e.id_evento,e.nome_evento,e.cidade,e.estado,e.endereco,g.status,to_char(g.updated_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS changed_at FROM public.tb_evento_geocoding g JOIN public.tb_evento_corridas e ON e.id_evento=g.id_evento WHERE g.status " & (tab EQ "revisao" ? "='needs_review' AND COALESCE(g.source_snapshot->>'VERSION',g.source_snapshot->>'version','1')='2'" : " IN ('city_suggestion','insufficient_data')") & " AND NOT EXISTS(SELECT 1 FROM public.tb_evento_geocoding newer WHERE newer.id_evento=g.id_evento AND newer.id>g.id) AND btrim(COALESCE(e.coordenadas,''))='' AND " & filter & " ORDER BY g.updated_at DESC,g.id DESC LIMIT 21 OFFSET :offset",params,variables.options);
        // Never cast malformed legacy coordinates outside a guarded CASE expression.
        var valid="CASE WHEN btrim(COALESCE(e.coordenadas,'')) ~ '^[-+]?[0-9]+([.][0-9]+)?[ ]*,[ ]*[-+]?[0-9]+([.][0-9]+)?$' THEN abs(split_part(e.coordenadas,',',1)::numeric)<=90 AND abs(split_part(e.coordenadas,',',2)::numeric)<=180 AND NOT(split_part(e.coordenadas,',',1)::numeric=0 AND split_part(e.coordenadas,',',2)::numeric=0) ELSE false END";
        filter &= status EQ "invalid" ? " AND btrim(COALESCE(e.coordenadas,''))<>'' AND NOT(" & valid & ")" : " AND btrim(COALESCE(e.coordenadas,''))=''";
        if(listFind("pending,running,city_suggestion,needs_review,insufficient_data,error,errors_exhausted,conflict,rejected",status)){filter &= " AND g.status=:status";params.status=p(status);}
        return queryExecute("SELECT e.id_evento,e.nome_evento,e.cidade,e.estado,e.endereco,e.coordenadas,COALESCE(g.status,'not_queued') AS status,g.id AS work_id,to_char(e.data_inicial,'DD/MM/YYYY') AS starts FROM public.tb_evento_corridas e LEFT JOIN LATERAL(SELECT id,status FROM public.tb_evento_geocoding WHERE id_evento=e.id_evento ORDER BY id DESC LIMIT 1)g ON true WHERE " & filter & " ORDER BY CASE WHEN e.data_inicial>=CURRENT_DATE THEN 0 ELSE 1 END,e.data_inicial,e.id_evento LIMIT 21 OFFSET :offset",params,variables.options);
    }
}
