component extends="services.geocoding.Store" output=false {
    variables.lp=new services.geocoding.Policy();variables.db={datasource="runner_dba"};
    private struct function row(required query q){for(var r in q)return r;return {};}
    private struct function bind(required any v,string type="cf_sql_varchar"){return {value=v,cfsqltype=type};}
    public any function lowerKeys(required any value){
        if(isArray(value)){var a=[];for(var x in value)arrayAppend(a,lowerKeys(x));return a;}
        if(isStruct(value)){var s=structNew("ordered");for(var k in value)s[lCase(k)]=lowerKeys(value[k]);return s;}return value;
    }
    private string function json(required any value){return serializeJSON(lowerKeys(value));}
    public boolean function aiReady(){return super.isReady() AND queryExecute("SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name='localizacoes' AND data_type='jsonb'",[],variables.db).recordCount EQ 1;}
    public boolean function radarReady(){var q=queryExecute("SELECT to_regprocedure('public.rr_parse_event_coordinates(text)') IS NOT NULL AND to_regclass('public.tb_evento_geocoding') IS NOT NULL AND (SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name IN('latitude','longitude','localizacoes'))=3 AS ready",[],variables.db);return q.recordCount EQ 1 AND q.ready[1];}
    public struct function event(required numeric id,boolean locked=false){var e=super.event(id,locked);if(e.exists){var q=queryExecute("SELECT url_regulamento IS NULL AS regulation_null FROM public.tb_evento_corridas WHERE id_evento=:id",{id=bind(id,"cf_sql_integer")},variables.db);if(q.regulation_null[1])arrayAppend(e._sourceNulls,"url_regulamento");}return e;}
    public struct function snapshot(required struct e){var s=variables.lp.snapshot(e);s.version=3;s.url_regulamento=variables.lp.text(e,"url_regulamento");if(arrayFindNoCase(e._sourceNulls,"url_regulamento"))arrayAppend(s.nulls,"url_regulamento");s.localizacoes=structKeyExists(e,"localizacoes") AND !isNull(e.localizacoes) AND isJSON(e.localizacoes & "") ? deserializeJSON(e.localizacoes & "") : {};s.enrichment_version=1;s.enrichment_native=new services.geocoding.EnrichmentPolicy().nativeSnapshot(e);for(var field in s.enrichment_native)if(!structKeyExists(s,field))s[field]=s.enrichment_native[field];return s;}
    public struct function publishEnrichment(required struct work,required struct progress,required string actor){return new services.geocoding.EnrichmentStore().publish(this,work,progress,actor);}
    public struct function reviewField(required numeric id,required numeric index,required string action,required string actor,required string revision){return new services.geocoding.EnrichmentStore().review(this,id,index,action,actor,revision);}
    private string function fieldReviewSql(string alias="g"){return "EXISTS(SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(" & alias & ".decision->'enrichment'->'fields')='array' THEN " & alias & ".decision->'enrichment'->'fields' ELSE '[]'::jsonb END) AS fact WHERE fact->>'status'='needs_review')";}
    public array function sourceValues(required struct s){var a=[];for(var k in listToArray("id_evento,cidade,estado,pais,cod_cidade,endereco,descricao_original,descricao,nome_evento,url_hotsite,url_inscricao,url_regulamento"))arrayAppend(a,[arrayFindNoCase(s.nulls,k) GT 0,s[k]]);arrayAppend(a,[s.catalog_city,s.catalog_state]);arrayAppend(a,[s.start_date,3]);return a;}
    public string function sourceHash(required struct s){return lCase(hash(serializeJSON(sourceValues(s)),"SHA-256"));}
    public string function expectedHash(required struct work,required struct source){return structKeyExists(source,"settled_hash") AND reFind("^[a-f0-9]{64}$",source.settled_hash) ? source.settled_hash : work.source_hash;}
    private string function inputExpression(){var a=[];for(var k in listToArray("id_evento,cidade,estado,pais,cod_cidade,endereco,descricao_original,descricao,nome_evento,url_hotsite,url_inscricao,url_regulamento"))arrayAppend(a,"jsonb_build_array(e." & k & " IS NULL,COALESCE(e." & k & "::text,''))");arrayAppend(a,"jsonb_build_array(COALESCE(c.nome_cidade,''),COALESCE(c.uf,''))");arrayAppend(a,"jsonb_build_array(COALESCE(to_char(e.data_inicial,'YYYY-MM-DD'),''),3)");return "jsonb_build_array(" & arrayToList(a,",") & ")";}
    private void function logAction(required struct w,required string action,required string actor,required struct details,string after=""){
        var s=deserializeJSON(w.source_snapshot & "");queryExecute("INSERT INTO public.tb_evento_geocoding_audit(work_id,id_evento,action,actor,source_hash,coordinates_before,coordinates_after,details) VALUES(:id,:event,:action,:actor,:hash,:before,:after,CAST(:body AS jsonb))",{id=bind(w.id,"cf_sql_bigint"),event=bind(w.id_evento,"cf_sql_integer"),action=bind(action),actor=bind(left(actor,64)),hash=bind(w.source_hash),before=bind(s.coordenadas,"cf_sql_longvarchar"),after=bind(after,"cf_sql_longvarchar"),body=bind(json(details),"cf_sql_longvarchar")},variables.db);
    }
    public array function enqueue(required array ids,required string actor){
        if(arrayLen(ids) GT 20)throw(type="Geocoding.Validation",message="Selecione até 20 eventos.");var out=[];
        for(var value in ids){var id=identifier(value);if(id GT 2147483647)throw(type="Geocoding.Validation",message="Evento inválido.");var e=event(id);if(!e.exists)continue;var s=snapshot(e);
            transaction {var q=queryExecute("INSERT INTO public.tb_evento_geocoding(id_evento,source_hash,source_snapshot,source_values,priority) VALUES(:event,:hash,CAST(:snapshot AS jsonb),CAST(:values AS jsonb),:priority) ON CONFLICT(id_evento,source_hash) DO UPDATE SET status='pending',attempts=0,error_code=NULL,next_retry_at=NULL,lease_token=NULL,lease_until=NULL,source_snapshot=excluded.source_snapshot,decision='{}'::jsonb,proposal_revision=tb_evento_geocoding.proposal_revision+1,updated_at=clock_timestamp() WHERE tb_evento_geocoding.status<>'running' OR tb_evento_geocoding.lease_until<clock_timestamp() RETURNING *",{event=bind(id,"cf_sql_integer"),hash=bind(sourceHash(s)),snapshot=bind(json(s),"cf_sql_longvarchar"),values=bind(serializeJSON(sourceValues(s)),"cf_sql_longvarchar"),priority=bind(isDate(e.data_inicial) AND dateCompare(e.data_inicial,now(),"d") GTE 0 ? 0 : 100,"cf_sql_integer")},variables.db);if(q.recordCount){var w=row(q);arrayAppend(out,w.id);logAction(w,"enqueued",actor,{version=3});}}
        }return out;
    }
    public numeric function seed(numeric limit=5){
        var count=queryExecute("SELECT count(*) AS n FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' AND status IN('pending','running','error') AND attempts<3",[],variables.db);if(count.n[1] GTE 20)return 0;
        return arrayLen(enqueue(selectEvents(limit),"job"));
    }
    public array function selectEvents(numeric limit=5){
        var q=queryExecute("SELECT e.id_evento
            FROM public.tb_evento_corridas e
            LEFT JOIN public.tb_cidades c ON c.cod_cidade=e.cod_cidade
            WHERE (btrim(COALESCE(e.coordenadas,''))='' OR NOT(jsonb_exists(e.localizacoes,'kit')) OR COALESCE(e.localizacoes->'enriquecimento'->>'version','')<>'1')
              AND NOT EXISTS(SELECT 1 FROM public.tb_evento_geocoding g WHERE g.id_evento=e.id_evento AND g.source_values=" & inputExpression() & " AND (g.source_snapshot->>'enrichment_version'='1' OR (g.status IN('pending','running','error') AND g.attempts<3)))
            ORDER BY CASE
                WHEN e.ativo IS TRUE AND btrim(COALESCE(e.coordenadas,''))='' AND e.data_inicial>=CURRENT_DATE AND e.data_inicial<=CURRENT_DATE+interval '30 days' THEN 0
                WHEN e.ativo IS TRUE AND btrim(COALESCE(e.coordenadas,''))='' AND e.data_inicial>CURRENT_DATE+interval '30 days' AND e.data_inicial<=CURRENT_DATE+interval '90 days' THEN 1
                WHEN e.ativo IS TRUE AND btrim(COALESCE(e.coordenadas,''))='' AND e.data_inicial>CURRENT_DATE+interval '90 days' THEN 2
                WHEN e.ativo IS TRUE AND btrim(COALESCE(e.coordenadas,''))='' AND e.data_inicial<CURRENT_DATE AND e.data_final>=CURRENT_DATE THEN 3
                WHEN e.ativo IS TRUE THEN 4
                ELSE 5
            END,
            CASE WHEN e.data_inicial>=CURRENT_DATE THEN e.data_inicial END,
            CASE WHEN e.data_inicial<CURRENT_DATE THEN e.data_inicial END DESC,
            e.id_evento DESC LIMIT :limit",{limit=bind(max(1,min(5,int(limit))),"cf_sql_integer")},variables.db);var ids=[];for(var r in q)arrayAppend(ids,r.id_evento);return ids;
    }
    public struct function claim(numeric id=0){
        transaction {var expired=queryExecute("UPDATE public.tb_evento_geocoding SET status='errors_exhausted',error_code='lease_expired',lease_token=NULL,lease_until=NULL,updated_at=clock_timestamp() WHERE id IN(SELECT id FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' AND status='running' AND lease_until<clock_timestamp() AND attempts>=3 FOR UPDATE SKIP LOCKED LIMIT 20) RETURNING *",[],variables.db);for(var w in expired)logAction(w,"errors_exhausted","job",{reason="lease_expired"});}
        var token=lCase(replace(createUUID(),"-","","all"));return row(queryExecute("UPDATE public.tb_evento_geocoding SET status='running',lease_token=:token,lease_until=clock_timestamp()+interval '10 minutes',attempts=attempts+1,updated_at=clock_timestamp() WHERE id=(SELECT id FROM public.tb_evento_geocoding WHERE source_snapshot->>'version'='3' AND (:id=0 OR id=:id) AND attempts<3 AND ((status IN('pending','error') AND (next_retry_at IS NULL OR next_retry_at<=clock_timestamp())) OR (status='running' AND lease_until<clock_timestamp())) ORDER BY priority,id FOR UPDATE SKIP LOCKED LIMIT 1) RETURNING *",{id=bind(id,"cf_sql_bigint"),token=bind(token)},variables.db));
    }
    public void function checkpoint(required struct work,required struct progress){var q=queryExecute("UPDATE public.tb_evento_geocoding SET decision=CAST(:body AS jsonb),updated_at=clock_timestamp() WHERE id=:id AND status='running' AND lease_token=:token AND lease_until>clock_timestamp() RETURNING id",{body=bind(json(progress),"cf_sql_longvarchar"),id=bind(work.id,"cf_sql_bigint"),token=bind(work.lease_token)},variables.db);if(!q.recordCount)throw(type="Geocoding.Validation",message="O processamento expirou.");}
    private boolean function sameDestinations(required struct work,required struct source){return queryExecute("SELECT 1 FROM public.tb_evento_corridas WHERE id_evento=:id AND COALESCE(coordenadas,'')=:coords AND localizacoes=CAST(:locations AS jsonb)",{id=bind(work.id_evento,"cf_sql_integer"),coords=bind(source.coordenadas),locations=bind(json(source.localizacoes),"cf_sql_longvarchar")},variables.db).recordCount EQ 1;}
    private struct function canonical(required struct target,required string actor){return {nome_local=target.facts.name,cidade=target.facts.city,uf=target.facts.state,pais=target.facts.country,endereco=target.facts.address,coordenadas=variables.lp.coordinates(target.candidate.lat & "," & target.candidate.lon).value,fonte=target.evidence,confirmado_em=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ssXXX"),autor=actor,precisao="local_confirmado"};}
    public struct function finish(required struct work,required struct result,required string actor){
        var decision=duplicate(result);var status=result.status;var after="";
        if(!listFind("auto_applied,approved,needs_review,city_suggestion,insufficient_data,error,errors_exhausted",status))throw(type="Geocoding.Validation",message="Resultado inválido.");
        transaction {
            var current=row(queryExecute("SELECT *,lease_until>clock_timestamp() AS valid FROM public.tb_evento_geocoding WHERE id=:id FOR UPDATE",{id=bind(work.id,"cf_sql_bigint")},variables.db));
            if(structIsEmpty(current) OR current.status NEQ "running" OR !current.valid OR variables.lp.text(current,"lease_token") NEQ work.lease_token)throw(type="Geocoding.Validation",message="O processamento expirou.");
            var e=event(current.id_evento,true);var s=deserializeJSON(current.source_snapshot & "");s.enrichment_version=1;
            if(!e.exists OR sourceHash(snapshot(e)) NEQ expectedHash(current,s) OR !sameDestinations(current,s)){status="conflict";decision={status=status,targets=[],reasons=["source_changed"]};}
            else if(structKeyExists(decision,"targets")) {
                var destinations=duplicate(s.localizacoes);var changed=false;
                for(var t in decision.targets)if(listFind("auto_applied,approved",variables.lp.text(t,"status"))) {
                    if(!t.trusted OR !variables.lp.specificCandidate(t.context,t.candidate))throw(type="Geocoding.Validation",message="O local não tem evidência e precisão suficientes.");
                    var record=canonical(t,actor);
                    if(t.role EQ "evento") {
                        if(len(variables.lp.text(e,"coordenadas")) OR structKeyExists(destinations,"evento")){t.status="preserved";continue;}
                        after=record.coordenadas;destinations.evento=record;changed=true;
                    } else if(t.role EQ "kit") {
                        if(structKeyExists(destinations,"kit")){t.status="preserved";continue;}
                        destinations.kit=[record];changed=true;
                    } else throw(type="Geocoding.Validation",message="Finalidade inválida.");
                }
                if(changed)queryExecute("UPDATE public.tb_evento_corridas SET localizacoes=CAST(:locations AS jsonb),coordenadas=CASE WHEN btrim(COALESCE(coordenadas,''))='' AND :coords<>'' THEN :coords ELSE coordenadas END WHERE id_evento=:id",{locations=bind(json(destinations),"cf_sql_longvarchar"),coords=bind(after),id=bind(current.id_evento,"cf_sql_integer")},variables.db);
                // Subsequent independent target reviews compare against the post-application destination.
                s.localizacoes=destinations;if(len(after))s.coordenadas=after;
            }
            if(structKeyExists(decision,"enrichment") AND listFind("auto_applied,approved,city_suggestion,insufficient_data,needs_review",status))for(var field in decision.enrichment.fields)if(field.status EQ "needs_review")status="needs_review";
            if(status EQ "error" AND current.attempts GTE 3)status="errors_exhausted";decision.status=status;
            queryExecute("UPDATE public.tb_evento_geocoding SET status=:status,source_snapshot=CAST(:snapshot AS jsonb),decision=CAST(:body AS jsonb),error_code=:code,lease_token=NULL,lease_until=NULL,proposal_revision=proposal_revision+1,next_retry_at=CASE WHEN :status='error' THEN clock_timestamp()+interval '30 minutes' ELSE NULL END,updated_at=clock_timestamp() WHERE id=:id",{status=bind(status),snapshot=bind(json(s),"cf_sql_longvarchar"),body=bind(json(decision),"cf_sql_longvarchar"),code=bind(variables.lp.text(decision,"code")),id=bind(current.id,"cf_sql_bigint")},variables.db);
            logAction(current,status,actor,decision,after);
        }return {id=work.id,id_evento=work.id_evento,status=status};
    }
    public struct function reviewTarget(required numeric id,required numeric index,required string action,required string actor,required string revision){
        if(!listFind("approve,reject",action) OR int(index) NEQ index)throw(type="Geocoding.Validation",message="Revisão inválida.");
        transaction {
            var w=row(queryExecute("SELECT * FROM public.tb_evento_geocoding WHERE id=:id FOR UPDATE",{id=bind(id,"cf_sql_bigint")},variables.db));
            if(structIsEmpty(w) OR !listFind("needs_review,city_suggestion,insufficient_data",w.status))throw(type="Geocoding.Validation",message="Proposta indisponível.");variables.lp.requireRevision(w,revision);
            var d=deserializeJSON(w.decision & "");if(!structKeyExists(d,"targets") OR index LT 1 OR index GT arrayLen(d.targets))throw(type="Geocoding.Validation",message="Local inválido.");var t=d.targets[index];
            if(!listFind("needs_review,city_suggestion,insufficient_data",t.status))throw(type="Geocoding.Validation",message="Local já revisado.");
            if(action EQ "approve" AND (!t.trusted OR !variables.lp.specificCandidate(t.context,t.candidate)))throw(type="Geocoding.Validation",message="Cidade ou evidência não confirmada não pode ser aprovada.");
            var source=deserializeJSON(w.source_snapshot & "");var e=event(w.id_evento,true);
            if(!e.exists OR sourceHash(snapshot(e)) NEQ expectedHash(w,source) OR !sameDestinations(w,source))throw(type="Geocoding.Validation",message="O cadastro mudou. Reprocesse a proposta.");
            t.status=action EQ "approve" ? "approved" : "rejected";d.targets[index]=t;d.status="approved";
            for(var pending in d.targets)if(pending.status EQ "needs_review")d.status="needs_review";
            if(action EQ "reject" AND d.status NEQ "needs_review")d.status="insufficient_data";
            w.lease_token=lCase(replace(createUUID(),"-","","all"));queryExecute("UPDATE public.tb_evento_geocoding SET status='running',lease_token=:token,lease_until=clock_timestamp()+interval '10 minutes' WHERE id=:id",{token=bind(w.lease_token),id=bind(id,"cf_sql_bigint")},variables.db);
            var r=finish(w,d,actor);logAction(w,action EQ "approve" ? "location_approved" : "location_rejected",actor,{target=index,role=t.role});return r;
        }
    }
    public struct function review(required numeric id,required string action,required string actor,required string reason,string revision=""){
        var w=detail(id);if(!structIsEmpty(w)){var s=deserializeJSON(w.source_snapshot & "");if((s.version ?: 0) EQ 3)throw(type="Geocoding.Validation",message="Revise cada local nos detalhes da proposta.");}
        // Do not dispatch a v2 decision through this subclass's v3 finish/hash.
        return new services.geocoding.Store().review(id,action,actor,reason,revision);
    }
    public struct function reserveAI(numeric limit=1000){
        queryExecute("INSERT INTO public.tb_geocoding_cache(cache_key,query_text,response) VALUES('__ai_control__','openai-geolocation','{}'::jsonb) ON CONFLICT DO NOTHING",[],variables.db);
        transaction {
            var state=row(queryExecute("SELECT greatest(0,ceil(extract(epoch FROM(cooldown_until-clock_timestamp())))) AS cooldown FROM public.tb_geocoding_cache WHERE cache_key='__ai_control__' FOR UPDATE",[],variables.db));if(state.cooldown GT 0)return {allowed=false,reason="ai_cooldown",retryAfter=state.cooldown};
            var q=queryExecute("INSERT INTO public.tb_geocoding_usage_daily(usage_date,provider,calls) VALUES((clock_timestamp() AT TIME ZONE 'UTC')::date,'openai-geolocation',1) ON CONFLICT(usage_date,provider) DO UPDATE SET calls=tb_geocoding_usage_daily.calls+1 WHERE tb_geocoding_usage_daily.calls<:limit RETURNING calls",{limit=bind(max(1,min(2000,int(limit))),"cf_sql_integer")},variables.db);return {allowed=q.recordCount GT 0,reason=q.recordCount ? "ok" : "ai_daily_limit",retryAfter=3600};
        }
    }
    public void function completeAI(required struct reply){if(!reply.ok)queryExecute("UPDATE public.tb_geocoding_cache SET cooldown_until=clock_timestamp()+:seconds*interval '1 second',response=CAST(:body AS jsonb),updated_at=clock_timestamp() WHERE cache_key='__ai_control__'",{seconds=bind(max(60,min(21600,reply.retryAfter)),"cf_sql_integer"),body=bind(json({code=reply.code}),"cf_sql_longvarchar")},variables.db);}
    public struct function aiStats(){var q=queryExecute("SELECT COALESCE((SELECT calls FROM public.tb_geocoding_usage_daily WHERE usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date AND provider='openai-geolocation'),0) AS calls,(SELECT response->>'code' FROM public.tb_geocoding_cache WHERE cache_key='__ai_control__') AS code",[],variables.db);return row(q);}
    private string function radarQualitySql(){return "WITH eligible_events AS (
        SELECT e.id_evento,e.nome_evento,e.data_inicial,e.data_final,e.cidade,e.estado,e.latitude,e.longitude,
            public.rr_parse_event_coordinates(e.coordenadas) AS legacy_pair,
            public.rr_parse_event_coordinates(e.localizacoes->'evento'->>'coordenadas') AS provenance_pair,
            COALESCE(e.localizacoes->'evento'->>'precisao','') AS provenance_precision,
            COALESCE(g.status,'not_queued') AS geocoding_status,g.updated_at AS geocoding_updated_at
        FROM public.tb_evento_corridas e
        LEFT JOIN LATERAL(SELECT status,updated_at FROM public.tb_evento_geocoding WHERE id_evento=e.id_evento ORDER BY id DESC LIMIT 1)g ON true
        WHERE e.ativo=true AND nullif(btrim(e.tag),'') IS NOT NULL AND e.data_final>=CURRENT_DATE
    ),cross_city_duplicate_coordinates AS (
        SELECT latitude,longitude FROM eligible_events
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
          AND latitude BETWEEN -90.0 AND 90.0 AND longitude BETWEEN -180.0 AND 180.0
        GROUP BY latitude,longitude
        HAVING count(DISTINCT lower(COALESCE(nullif(btrim(cidade),''),'')) || '|' || upper(COALESCE(nullif(btrim(estado),''),'')))>1
    ),classified AS (
        SELECT e.*,
            CASE
                WHEN e.latitude IS NULL OR e.longitude IS NULL OR e.latitude NOT BETWEEN -90.0 AND 90.0 OR e.longitude NOT BETWEEN -180.0 AND 180.0 THEN 'absent'
                WHEN (e.latitude=0 AND e.longitude=0)
                  OR array_length(e.legacy_pair,1) IS DISTINCT FROM 2
                  OR e.latitude IS DISTINCT FROM (e.legacy_pair)[1]
                  OR e.longitude IS DISTINCT FROM (e.legacy_pair)[2]
                  OR (e.provenance_precision='local_confirmado' AND (array_length(e.provenance_pair,1) IS DISTINCT FROM 2 OR e.latitude IS DISTINCT FROM (e.provenance_pair)[1] OR e.longitude IS DISTINCT FROM (e.provenance_pair)[2]))
                  OR duplicate.latitude IS NOT NULL THEN 'suspicious'
                WHEN e.provenance_precision='local_confirmado'
                  AND array_length(e.provenance_pair,1)=2
                  AND e.latitude IS NOT DISTINCT FROM (e.provenance_pair)[1]
                  AND e.longitude IS NOT DISTINCT FROM (e.provenance_pair)[2] THEN 'confirmed'
                ELSE 'legacy'
            END AS quality,
            CASE
                WHEN e.latitude=0 AND e.longitude=0 THEN 'null_island'
                WHEN e.provenance_precision='local_confirmado' AND (array_length(e.provenance_pair,1) IS DISTINCT FROM 2 OR e.latitude IS DISTINCT FROM (e.provenance_pair)[1] OR e.longitude IS DISTINCT FROM (e.provenance_pair)[2]) THEN 'provenance_coordinate_mismatch'
                WHEN duplicate.latitude IS NOT NULL THEN 'cross_city_duplicate_coordinates'
                WHEN array_length(e.legacy_pair,1) IS DISTINCT FROM 2 OR e.latitude IS DISTINCT FROM (e.legacy_pair)[1] OR e.longitude IS DISTINCT FROM (e.legacy_pair)[2] THEN 'text_numeric_mismatch'
                ELSE ''
            END AS review_reason
        FROM eligible_events e
        LEFT JOIN cross_city_duplicate_coordinates duplicate ON duplicate.latitude=e.latitude AND duplicate.longitude=e.longitude
    ) ";}
    public struct function radarCoverage(){return row(queryExecute(radarQualitySql() & "SELECT count(*) AS total,count(*) FILTER(WHERE quality<>'absent') AS mapped,round(100.0*count(*) FILTER(WHERE quality<>'absent')/nullif(count(*),0),2) AS coveragePercent,count(*) FILTER(WHERE quality='confirmed') AS confirmed,count(*) FILTER(WHERE quality='legacy') AS legacy,count(*) FILTER(WHERE quality='suspicious') AS suspicious,count(*) FILTER(WHERE quality='absent') AS absent,count(*) FILTER(WHERE data_inicial<=CURRENT_DATE+interval '30 days') AS next30,count(*) FILTER(WHERE data_inicial>CURRENT_DATE+interval '30 days' AND data_inicial<=CURRENT_DATE+interval '90 days') AS next90,count(*) FILTER(WHERE data_inicial>CURRENT_DATE+interval '90 days') AS later,clock_timestamp() AS measuredAt FROM classified",[],variables.db));}
    public query function radarCoverageByState(){return queryExecute(radarQualitySql() & "SELECT COALESCE(nullif(upper(btrim(estado)),''),'SEM_UF') AS state_code,count(*) AS eligible_total,count(*) FILTER(WHERE quality<>'absent') AS mapped_total,round(100.0*count(*) FILTER(WHERE quality<>'absent')/nullif(count(*),0),2) AS coverage_percent,count(*) FILTER(WHERE quality='confirmed') AS confirmed_total,count(*) FILTER(WHERE quality='legacy') AS legacy_total,count(*) FILTER(WHERE quality='suspicious') AS suspicious_total,count(*) FILTER(WHERE quality='absent') AS absent_total FROM classified GROUP BY COALESCE(nullif(upper(btrim(estado)),''),'SEM_UF') ORDER BY coverage_percent,state_code",[],variables.db);}
    public query function radarCoveragePage(required numeric page,required string search,required string quality,required string horizon,required string uf){
        var safeQuality=listFindNoCase("all,confirmed,legacy,suspicious,absent",quality) ? lCase(quality) : "all";var safeHorizon=listFindNoCase("all,30,90,later",horizon) ? lCase(horizon) : "all";var safeUf=reFind("^[A-Z]{2}$",uCase(uf)) ? uCase(uf) : "";
        var params={offset=bind((max(1,min(9999,int(page)))-1)*20,"cf_sql_integer"),search=bind("%" & left(trim(search),100) & "%"),empty=bind(!len(trim(search)) ? 1 : 0,"cf_sql_integer"),uf=bind(safeUf),quality=bind(safeQuality)};
        var filter="WHERE (:empty=1 OR nome_evento ILIKE :search OR cidade ILIKE :search OR id_evento::text ILIKE :search) AND (:uf='' OR upper(estado)=:uf)";
        if(safeQuality NEQ "all")filter&=" AND quality=:quality";
        if(safeHorizon EQ "30")filter&=" AND data_inicial<=CURRENT_DATE+interval '30 days'";
        if(safeHorizon EQ "90")filter&=" AND data_inicial>CURRENT_DATE+interval '30 days' AND data_inicial<=CURRENT_DATE+interval '90 days'";
        if(safeHorizon EQ "later")filter&=" AND data_inicial>CURRENT_DATE+interval '90 days'";
        return queryExecute(radarQualitySql() & "SELECT id_evento,nome_evento,to_char(data_inicial,'DD/MM/YYYY') AS starts,to_char(data_final,'DD/MM/YYYY') AS ends,cidade,estado,quality,review_reason,geocoding_status,to_char(geocoding_updated_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS changed_at FROM classified " & filter & " ORDER BY data_inicial,lower(nome_evento),id_evento LIMIT 21 OFFSET :offset",params,variables.db);
    }
    public struct function overview(){return row(queryExecute("WITH latest AS(SELECT DISTINCT ON(id_evento) id_evento,status,source_snapshot,decision FROM public.tb_evento_geocoding ORDER BY id_evento,id DESC) SELECT (SELECT count(*) FROM public.tb_evento_corridas WHERE btrim(COALESCE(coordenadas,''))='') AS missing,(SELECT count(*) FROM latest WHERE status IN('pending','running','error')) AS queued,(SELECT count(*) FROM latest WHERE (status='needs_review' OR " & fieldReviewSql("latest") & ") AND COALESCE(source_snapshot->>'version',source_snapshot->>'VERSION') IN('2','3')) AS review,(SELECT count(*) FROM latest WHERE status='city_suggestion') AS suggestions,(SELECT count(*) FROM latest WHERE status IN('auto_applied','approved')) AS applied,(SELECT count(*) FROM latest WHERE status NOT IN('pending','running','error','conflict')) AS analyzed,COALESCE((SELECT calls FROM public.tb_geocoding_usage_daily WHERE usage_date=(clock_timestamp() AT TIME ZONE 'UTC')::date AND provider='geoapify'),0) AS calls",[],variables.db));}
    public query function page(required string tab,required numeric page,required string search,required string status,required string period,required string uf){
        if(tab EQ "historico" OR status EQ "invalid")return super.page(tab,page,search,status,period,uf);
        var params={offset=bind((max(1,min(9999,int(page)))-1)*20,"cf_sql_integer"),search=bind("%" & left(search,100) & "%"),empty=bind(!len(search) ? 1 : 0,"cf_sql_integer"),uf=bind(uf)};
        var filter="(:empty=1 OR e.nome_evento ILIKE :search OR e.cidade ILIKE :search OR e.id_evento::text ILIKE :search) AND (:uf='' OR e.estado=:uf)";
        if(period EQ "proximos")filter &= " AND e.ativo=true AND e.data_inicial>=CURRENT_DATE";if(period EQ "historicos")filter &= " AND e.data_final<CURRENT_DATE";
        if(listFind("revisao,cidades",tab)){filter &= tab EQ "revisao" ? " AND (g.status='needs_review' OR " & fieldReviewSql() & ") AND COALESCE(g.source_snapshot->>'version',g.source_snapshot->>'VERSION') IN('2','3')" : " AND g.status IN('city_suggestion','insufficient_data')";}
        else {filter &= " AND (btrim(COALESCE(e.coordenadas,''))='' OR NOT(jsonb_exists(e.localizacoes,'kit')) OR COALESCE(e.localizacoes->'enriquecimento'->>'version','')<>'1')";if(listFind("pending,running,city_suggestion,needs_review,insufficient_data,error,errors_exhausted,conflict,rejected",status)){filter &= " AND g.status=:status";params.status=bind(status);}}
        return queryExecute("SELECT e.id_evento,e.nome_evento,e.cidade,e.estado,e.endereco,e.coordenadas,COALESCE(g.status,'not_queued') AS status,g.id AS work_id,to_char(e.data_inicial,'DD/MM/YYYY') AS starts,to_char(g.updated_at AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS changed_at FROM public.tb_evento_corridas e LEFT JOIN LATERAL(SELECT * FROM public.tb_evento_geocoding WHERE id_evento=e.id_evento ORDER BY id DESC LIMIT 1)g ON true WHERE " & filter & " ORDER BY CASE WHEN e.data_inicial>=CURRENT_DATE THEN 0 ELSE 1 END,e.data_inicial,e.id_evento LIMIT 21 OFFSET :offset",params,variables.db);
    }
}
