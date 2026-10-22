component output=false {
    variables.p=new services.geocoding.Policy();variables.fields=new services.geocoding.EnrichmentPolicy();
    private struct function bind(required any value,string type="cf_sql_varchar"){return {value=value,cfsqltype=type};}
    private string function reasons(required array codes,required string fallback){
        var labels={conflicting_sources="As fontes apresentam informações diferentes.",multiple_locations="Há mais de um local possível nas fontes.",low_confidence="A localização retornada não atingiu a confiança necessária.",ambiguous_candidates="Mais de um ponto corresponde ao endereço.",geographic_conflict="A cidade, o estado ou o país não corresponde ao cadastro.",catalog_conflict="A cidade informada difere do município vinculado ao evento.",building_not_confirmed="Não foi possível confirmar o imóvel ou número do endereço.",street_conflict="A rua encontrada difere da informada.",venue_name_conflict="O nome do local não foi confirmado.",edition_not_confirmed="A fonte não confirmou a edição correta do evento.",purpose_address_mismatch="Não foi possível confirmar se o endereço é da prova ou da retirada de kits.",evidence_not_reconfirmed="A análise mais recente não confirmou novamente esta informação."};
        var out=[];for(var code in codes)if(structKeyExists(labels,code) AND !arrayFind(out,labels[code]))arrayAppend(out,labels[code]);return arrayLen(out) ? arrayToList(out," ") : fallback;
    }
    public array function tasks(required struct work,required struct decision,required struct current,boolean mayApproveLegacy=false){
        var out=[];if(!listFind("needs_review,city_suggestion,insufficient_data,auto_applied,approved,pending,error",work.status))return out;
        if(structKeyExists(decision,"enrichment") AND isArray(decision.enrichment.fields ?: ""))for(var i=1;i LTE arrayLen(decision.enrichment.fields);i++){
            var field=decision.enrichment.fields[i];if(field.status NEQ "needs_review")continue;
            arrayAppend(out,{key="field-" & i,kind="field",field=field.field,index=i,title=field.label,category="Dados do evento",current=variables.fields.current(current,field.field),proposed=field.value,
                reason=reasons(field.reasons ?: [],field.trusted ? "O cadastro e a informação confirmada na fonte são diferentes. Escolha qual manter." : "Não há evidência suficiente para substituir o cadastro com segurança."),
                canApprove=field.trusted,canReject=true,evidence=field.evidence ?: {},candidate={},approveAction="approve_field",rejectAction="reject_field",
                consequence="Usar a fonte substitui apenas esta informação do evento. Manter cadastro não altera o valor atual."});
        }
        if(structKeyExists(decision,"targets")){
            if(!listFind("needs_review,city_suggestion,insufficient_data",work.status))return out;
            for(var j=1;j LTE arrayLen(decision.targets);j++){
                var target=decision.targets[j];if(target.status NEQ "needs_review")continue;
                var kind=target.role EQ "kit" ? "Retirada de kit" : "Local da prova";
                var old=target.role EQ "evento" ? variables.p.text(current,"endereco") : "";
                if(target.role EQ "evento" AND len(variables.p.text(current,"coordenadas")))old &= chr(10) & current.coordenadas;
                arrayAppend(out,{key="target-" & j,kind="target",index=j,title=kind,category="Prova e kit",current=old,proposed=trim(variables.p.text(target.facts,"name") & chr(10) & variables.p.text(target.facts,"address") & chr(10) & variables.p.text(target.facts,"city") & " / " & variables.p.text(target.facts,"state")),
                    reason=reasons(target.reasons ?: [],"Confira se o ponto do mapa corresponde ao local da edição indicada, e não apenas à cidade."),
                    canApprove=target.trusted AND variables.p.specificCandidate(target.context,target.candidate),canReject=true,evidence=target.evidence ?: {},candidate=target.candidate,
                    approveAction="approve_target",rejectAction="reject_target",consequence="Usar a fonte confirma somente este local. Coordenadas já cadastradas não serão substituídas; prova e kit continuam separados."});
            }
        }else if(work.status EQ "needs_review"){
            arrayAppend(out,{key="legacy-1",kind="legacy",index=1,title="Local da prova",category="Prova e kit",current=variables.p.text(current,"coordenadas"),proposed=structKeyExists(decision,"candidate") ? variables.p.text(decision.candidate,"formatted") : "Ponto não confirmado",
                reason=reasons(decision.reasons ?: [],"Confira se a localização específica corresponde ao evento. Uma cidade aproximada não pode ser aprovada como largada."),
                canApprove=mayApproveLegacy,canReject=true,evidence={},candidate=decision.candidate ?: {},approveAction="approve",rejectAction="reject",consequence="Usar a fonte publica somente o local específico conferido. Manter cadastro descarta a proposta sem mudar as coordenadas."});
        }
        return out;
    }
    public struct function active(required array tasks,string key=""){for(var task in tasks)if(task.key EQ key)return task;return arrayLen(tasks) ? tasks[1] : {};}
    public query function queue(required string search,required string period,required string uf,array skipped=[]){
        var params={search=bind("%" & left(search,100) & "%"),empty=bind(len(trim(search)) ? 0 : 1,"cf_sql_integer"),uf=bind(uf)};
        var filter="(:empty=1 OR e.nome_evento ILIKE :search OR e.cidade ILIKE :search OR e.id_evento::text ILIKE :search) AND (:uf='' OR e.estado=:uf)";
        if(period EQ "proximos")filter &= " AND e.ativo IS TRUE AND e.data_inicial>=CURRENT_DATE";
        if(period EQ "historicos")filter &= " AND e.data_final<CURRENT_DATE";
        if(arrayLen(skipped)){var ids=[];for(var value in skipped)if(isNumeric(value) AND val(value) GT 0)arrayAppend(ids,int(value));if(arrayLen(ids)){filter &= " AND e.id_evento NOT IN (:skipped)";params.skipped={value=arrayToList(ids),list=true,cfsqltype="cf_sql_integer"};}}
        return queryExecute("WITH latest AS(SELECT DISTINCT ON(id_evento) * FROM public.tb_evento_geocoding ORDER BY id_evento,id DESC)
            SELECT g.id AS work_id,e.id_evento,e.nome_evento,e.cidade,e.estado,to_char(e.data_inicial,'DD/MM/YYYY') AS starts,count(*) OVER() AS total
            FROM latest g JOIN public.tb_evento_corridas e USING(id_evento) WHERE " & filter & " AND (
                (g.source_snapshot->>'version'='3' AND (
                    (g.status IN('needs_review','city_suggestion','insufficient_data','auto_applied','approved','pending','error') AND EXISTS(SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(g.decision->'enrichment'->'fields')='array' THEN g.decision->'enrichment'->'fields' ELSE '[]'::jsonb END) f WHERE f->>'status'='needs_review'))
                    OR (g.status IN('needs_review','city_suggestion','insufficient_data') AND EXISTS(SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(g.decision->'targets')='array' THEN g.decision->'targets' ELSE '[]'::jsonb END) t WHERE t->>'status'='needs_review'))))
                OR (COALESCE(g.source_snapshot->>'version',g.source_snapshot->>'VERSION')='2' AND g.status='needs_review'))
            ORDER BY CASE WHEN e.data_inicial>=CURRENT_DATE THEN 0 ELSE 1 END,e.data_inicial,e.id_evento LIMIT 21",params,{datasource="runner_dba",timeout=15});
    }
    public struct function continuation(required any store,required numeric id,required string search,required string period,required string uf,array skipped=[]){
        var work=store.detail(id);
        if(!structIsEmpty(work) AND !arrayFind(skipped,work.id_evento)){
            var pending=tasks(work,deserializeJSON(work.decision & ""),store.event(work.id_evento));
            if(arrayLen(pending))return {id=id,key=pending[1].key};
        }
        var skip=duplicate(skipped);if(!structIsEmpty(work) AND !arrayFind(skip,work.id_evento))arrayAppend(skip,work.id_evento);
        var next=queue(search,period,uf,skip);return {id=next.recordCount ? next.work_id[1] : 0,key=""};
    }
    public boolean function isStale(required any store,required struct work,required struct current){
        var source=deserializeJSON(work.source_snapshot & "");
        if((source.version ?: 0) NEQ 3)return variables.p.sourceHash(variables.p.snapshot(current)) NEQ work.source_hash;
        if(store.sourceHash(store.snapshot(current)) NEQ store.expectedHash(work,source))return true;
        if(structKeyExists(source,"enrichment_native"))for(var field in source.enrichment_native)if(compare(source.enrichment_native[field],variables.fields.current(current,field)) NEQ 0)return true;
        // Match the writer's PostgreSQL JSONB and exact coordinate CAS, not a
        // fragile JSON-string-order comparison or only the source fingerprint.
        var same=queryExecute("SELECT 1 FROM public.tb_evento_corridas WHERE id_evento=:id AND COALESCE(coordenadas,'')=:coords AND localizacoes=CAST(:locations AS jsonb)",
            {id=bind(work.id_evento,"cf_sql_integer"),coords=bind(source.coordenadas),locations=bind(serializeJSON(store.lowerKeys(source.localizacoes)),"cf_sql_longvarchar")},{datasource="runner_dba",timeout=10});
        return same.recordCount NEQ 1;
    }
    public string function link(required string search,required string period,required string uf,numeric id=0,string key=""){
        return "?aba=revisao&periodo=" & encodeForURL(period) & "&busca=" & encodeForURL(search) & "&uf=" & encodeForURL(uf) & (id GT 0 ? "&id=" & int(id) : "") & (len(key) ? "&etapa=" & encodeForURL(key) : "") & "##geo-review-workspace";
    }
}
