component output=false {
    variables.db={datasource="runner_dba"};variables.p=new services.geocoding.EnrichmentPolicy();variables.textPolicy=new services.geocoding.Policy();
    private struct function bind(required any value,string type="cf_sql_varchar"){return {value=value,cfsqltype=type};}
    private struct function row(required query q){for(var r in q)return r;return {};}
    private string function json(required any value,required any store){return serializeJSON(store.lowerKeys(value));}
    private void function writeField(required struct e,required struct destinations,required struct entry,required string actor,required any store,boolean replaceExisting=false){
        var defs=variables.p.definitions();if(!structKeyExists(defs,entry.field) OR !entry.trusted OR !len(entry.value) OR len(entry.value) GT defs[entry.field].max)throw(type="Geocoding.Validation",message="O fato não tem confirmação suficiente.");
        var before=variables.p.current(e,entry.field);if(!replaceExisting AND len(before))throw(type="Geocoding.Validation",message="O campo já foi preenchido; reabra a proposta.");
        if(len(defs[entry.field].column)){
            var value=entry.value;var type="cf_sql_varchar";
            if(listFind("data_inicial,data_final",entry.field)){value=createDate(left(value,4),mid(value,6,2),right(value,2));type="cf_sql_date";}
            // Column is selected exclusively from the server-owned allowlist, never from request text.
            queryExecute("UPDATE public.tb_evento_corridas SET " & defs[entry.field].column & "=:value WHERE id_evento=:id",{value=bind(value,type),id=bind(e.id_evento,"cf_sql_integer")},variables.db);e[entry.field]=value;
        }
        destinations.enriquecimento.fields[entry.field]={value=entry.value,evidence=entry.evidence,confirmed_at=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ssXXX"),actor=actor,origin=replaceExisting ? "human_approved" : "astra_verified"};
        entry.previous=before;entry.status=replaceExisting ? "approved" : "auto_applied";
    }
    private struct function lockWork(required any store,required struct work,boolean requireLease=true){
        var current=row(queryExecute("SELECT *,lease_until>clock_timestamp() AS valid FROM public.tb_evento_geocoding WHERE id=:id FOR UPDATE",{id=bind(work.id,"cf_sql_bigint")},variables.db));
        if(structIsEmpty(current) OR (requireLease AND (current.status NEQ "running" OR !current.valid OR variables.textPolicy.text(current,"lease_token") NEQ work.lease_token)))throw(type="Geocoding.Validation",message="O processamento expirou.");
        var e=store.event(current.id_evento,true);var s=deserializeJSON(current.source_snapshot & "");
        if(!e.exists OR store.sourceHash(store.snapshot(e)) NEQ store.expectedHash(current,s) OR serializeJSON(store.lowerKeys(s.localizacoes)) NEQ serializeJSON(store.lowerKeys(deserializeJSON(e.localizacoes & ""))))throw(type="Geocoding.Validation",message="O cadastro mudou; reabra a proposta.");
        if(structKeyExists(s,"enrichment_native"))for(var field in s.enrichment_native)if(compare(s.enrichment_native[field],variables.p.current(e,field)) NEQ 0)throw(type="Geocoding.Validation",message="Um campo foi alterado durante a análise; reabra a proposta.");
        return {work=current,event=e,source=s};
    }
    private struct function settle(required any store,required struct locked,required struct progress,required struct destinations,required string actor,required string action){
        var current=locked.work;
        queryExecute("UPDATE public.tb_evento_corridas SET localizacoes=CAST(:body AS jsonb) WHERE id_evento=:id",{body=bind(json(destinations,store),"cf_sql_longvarchar"),id=bind(current.id_evento,"cf_sql_integer")},variables.db);
        var fresh=store.snapshot(store.event(current.id_evento));fresh.settled_hash=store.sourceHash(fresh);
        // The unique original work key is immutable, even when a later input repeats an older state.
        queryExecute("UPDATE public.tb_evento_geocoding SET source_values=CAST(:values AS jsonb),source_snapshot=CAST(:source AS jsonb),decision=CAST(:decision AS jsonb),proposal_revision=proposal_revision+1,updated_at=clock_timestamp() WHERE id=:id",{values=bind(serializeJSON(store.sourceValues(fresh)),"cf_sql_longvarchar"),source=bind(json(fresh,store),"cf_sql_longvarchar"),decision=bind(json(progress,store),"cf_sql_longvarchar"),id=bind(current.id,"cf_sql_bigint")},variables.db);
        queryExecute("INSERT INTO public.tb_evento_geocoding_audit(work_id,id_evento,action,actor,source_hash,coordinates_before,coordinates_after,details) VALUES(:work,:event,:action,:actor,:hash,:before,:after,CAST(:body AS jsonb))",{work=bind(current.id,"cf_sql_bigint"),event=bind(current.id_evento,"cf_sql_integer"),action=bind(action),actor=bind(left(actor,64)),hash=bind(current.source_hash),before=bind(locked.source.coordenadas),after=bind(fresh.coordenadas),body=bind(json(progress.enrichment,store),"cf_sql_longvarchar")},variables.db);
        return {work=store.detail(current.id),progress=progress};
    }
    public struct function publish(required any store,required struct work,required struct progress,required string actor){
        if(!structKeyExists(progress,"enrichment") OR (progress.enrichment.published ?: false))return {work=work,progress=progress};
        transaction {
            var locked=lockWork(store,work);var destinations=duplicate(locked.source.localizacoes);var updated=duplicate(progress);
            if(!structKeyExists(destinations,"enriquecimento"))destinations.enriquecimento={version=1,fields={}};
            destinations.enriquecimento.version=1;destinations.enriquecimento.checked_at=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn:ssXXX");destinations.enriquecimento.model=variables.textPolicy.text(progress,"model");
            for(var entry in updated.enrichment.fields)if(entry.trusted AND entry.status EQ "fill"){
                entry.current=variables.p.current(locked.event,entry.field);
                if(!len(entry.current))writeField(locked.event,destinations,entry,actor,store);
                else entry.status=variables.p.equivalent(entry.field,entry.current,entry.value) ? "equivalent" : "needs_review";
            }
            updated.enrichment.published=true;return settle(store,locked,updated,destinations,actor,"event_enriched");
        }
    }
    public struct function review(required any store,required numeric id,required numeric index,required string action,required string actor,required string revision){
        if(!listFind("approve,reject",action) OR int(index) NEQ index)throw(type="Geocoding.Validation",message="Ação inválida.");
        transaction {
            var locked=lockWork(store,{id=id},false);var current=locked.work;variables.textPolicy.requireRevision(current,revision);
            if(!listFind("needs_review,city_suggestion,insufficient_data,auto_applied,approved,pending,error",current.status))throw(type="Geocoding.Validation",message="A proposta não está disponível para revisão.");
            var progress=deserializeJSON(current.decision & "");
            if(!structKeyExists(progress,"enrichment") OR index LT 1 OR index GT arrayLen(progress.enrichment.fields))throw(type="Geocoding.Validation",message="Campo inválido.");
            var entry=progress.enrichment.fields[index];if(entry.status NEQ "needs_review")throw(type="Geocoding.Validation",message="Este campo já foi revisado.");
            var destinations=duplicate(locked.source.localizacoes);
            if(action EQ "approve"){
                if(variables.textPolicy.text(entry.evidence,"event_date") NEQ variables.textPolicy.text(locked.source,"start_date"))throw(type="Geocoding.Validation",message="A edição mudou; reprocesse antes de aceitar este campo.");
                writeField(locked.event,destinations,entry,actor,store,true);
                if(listFind("cidade,estado,pais,endereco,data_inicial,data_final,url_inscricao,url_hotsite,url_regulamento",entry.field)){progress.analysis_complete=false;progress.targets=[];}
            }else entry.status="rejected";
            progress.enrichment.fields[index]=entry;var result=settle(store,locked,progress,destinations,actor,action EQ "approve" ? "field_approved" : "field_rejected");
            var pending=false;for(var field in progress.enrichment.fields)if(field.status EQ "needs_review")pending=true;
            for(var target in progress.targets)if(target.status EQ "needs_review")pending=true;
            var nextStatus=listFind("pending,error",current.status) ? current.status : (pending ? "needs_review" : "approved");
            if(structKeyExists(progress,"analysis_complete") AND !progress.analysis_complete)nextStatus="pending";
            queryExecute("UPDATE public.tb_evento_geocoding SET status=:status,attempts=CASE WHEN :status='pending' THEN 0 ELSE attempts END,next_retry_at=CASE WHEN :status='pending' THEN clock_timestamp() ELSE next_retry_at END WHERE id=:id",{status=bind(nextStatus),id=bind(id,"cf_sql_bigint")},variables.db);
            return {id=id,status=nextStatus};
        }
    }
}
