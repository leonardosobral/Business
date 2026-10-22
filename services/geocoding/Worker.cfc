component output=false {
    public any function init(required struct config) {
        variables.config=config;variables.store=new services.geocoding.Store();variables.policy=new services.geocoding.Policy();variables.geoClient=new services.geocoding.GeoapifyClient();variables.sources=new services.geocoding.Sources();return this;
    }
    public string function fingerprint() {return structKeyExists(variables.config,"apiKey") AND len(variables.config.apiKey) ? lCase(hash(variables.config.apiKey,"SHA-256")) : "";}
    public numeric function responseStatus(required struct summary) {
        if(listFind("not_configured,schema_missing,not_validated,credentials_rejected",summary.status))return 503;
        for(var item in summary.results)if(item.status EQ "errors_exhausted")return 500;
        // Accepted means the durable queue will retry, not that coordinates were found.
        if(listFind("provider_timeout,provider_unavailable,rate_limited,provider_cooldown,provider_busy,pacing,daily_limit,time_budget,worker_busy,batch_expired",summary.status))return 202;
        return summary.errors GT 0 ? 500 : 200;
    }
    public string function safeError(required string code) {
        var labels={credentials_rejected="O Geoapify recusou a credencial ou a restrição de IP. Confira a chave no servidor e o IP autorizado.",rate_limited="O Geoapify pediu uma pausa. A fila foi preservada.",provider_unavailable="O Geoapify não respondeu. A fila terá novas tentativas limitadas.",invalid_response="O Geoapify retornou uma resposta inválida.",daily_limit="Limite diário atingido. A fila foi preservada.",provider_cooldown="O fornecedor está em período de espera.",not_configured="Configure a chave Geoapify no servidor.",schema_missing="A migração de geolocalização ainda não foi instalada.",disabled="O preenchimento automático está pausado.",not_validated="Teste a conexão com a chave atual antes de ativar."};
        if(code EQ "provider_timeout")return "A consulta ao Geoapify excedeu o prazo. A fila foi preservada para nova tentativa.";
        return structKeyExists(labels,code) ? labels[code] : "Não foi possível concluir a localização agora.";
    }
    private struct function lookup(required struct query,required numeric deadline) {
        var cached=variables.store.cacheGet(query);var reservation={};var reply={};
        if(!variables.store.workerValid(variables.workerToken))return {ok=false,code="batch_expired",retryAfter=60,results=[]};
        if(cached.found){variables.cacheHits++;return {ok=true,code="ok",results=cached.results,cached=true};}
        if(getTickCount()+17000 GT deadline)return {ok=false,code="time_budget",retryAfter=60,results=[]};
        reservation=variables.store.reserveCall(variables.store.settings().dailyLimit);
        if(!reservation.allowed AND reservation.reason EQ "pacing") {
            sleep(min(1100,reservation.waitMs+10));reservation=variables.store.reserveCall(variables.store.settings().dailyLimit);
        }
        if(!reservation.allowed)return {ok=false,code=reservation.reason,retryAfter=structKeyExists(reservation,"retryAfter") ? reservation.retryAfter : 60,results=[]};
        variables.calls++;
        reply=variables.geoClient.search(query,variables.config.apiKey);
        variables.store.completeCall(reservation.token,reply.code,reply.ok ? 0 : reply.retryAfter);
        if(reply.ok)variables.store.cachePut(query,reply.results);
        reply.cached=false;return reply;
    }
    public struct function testConnection() {
        if(!len(fingerprint()))return {success=false,status="not_configured",message=safeError("not_configured")};
        if(!variables.store.isReady())return {success=false,status="schema_missing",message=safeError("schema_missing")};
        variables.calls=0;
        // A deliberate test always consumes one counted call, not cached data.
        var reserve=variables.store.reserveCall(variables.store.settings().dailyLimit);
        if(!reserve.allowed AND reserve.reason EQ "pacing"){sleep(min(1100,reserve.waitMs+10));reserve=variables.store.reserveCall(variables.store.settings().dailyLimit);}
        if(!reserve.allowed)return {success=false,status=reserve.reason,message=safeError(reserve.reason)};
        var reply=variables.geoClient.search({kind="city",text="São Paulo, SP, BR",country="BR"},variables.config.apiKey);
        if(!reply.ok){variables.store.completeCall(reserve.token,reply.code,reply.retryAfter);return {success=false,status=reply.code,message=safeError(reply.code)};}
        var compatible=false;for(var c in reply.results)if(variables.policy.sameRegion({cidade="São Paulo",estado="SP",pais="BR"},c))compatible=true;
        if(!compatible){variables.store.completeCall(reserve.token,"invalid_response",300);return {success=false,status="invalid_response",message=safeError("invalid_response")};}
        if(!variables.store.completeCall(reserve.token,"ok",0,fingerprint()))return {success=false,status="provider_busy",message=safeError("provider_busy")};
        return {success=true,status="validated",message="Conexão validada. Uma chamada foi contabilizada; nenhum evento foi alterado."};
    }
    public struct function run(numeric limit=5) {
        var summary={success=false,status="not_configured",pipeline_version=2,processed=0,applied=0,suggestions=0,review=0,errors=0,calls=0,cache_hits=0,source_documents=0,results=[]};
        if(!len(fingerprint())){summary.message=safeError(summary.status);return summary;}
        if(!variables.store.isReady()){summary.status="schema_missing";summary.message=safeError(summary.status);return summary;}
        var settings=variables.store.settings();
        if(!settings.enabled OR settings.validatedFingerprint NEQ fingerprint()) {summary.status=settings.enabled ? "not_validated" : "disabled";summary.message=safeError(summary.status);return summary;}
        var lease=variables.store.acquireWorker();
        if(!lease.allowed){summary.success=true;summary.status="worker_busy";summary.message="Outro lote já está em execução. Nenhuma consulta adicional foi feita.";return summary;}
        variables.workerToken=lease.token;
        var deadline=getTickCount()+45000;var work={};var source={};var queries=[];var query={};var reply={};var decision={};var result={};var last={};var deferred=false;
        try {
        variables.calls=0;variables.cacheHits=0;variables.store.seed(max(1,min(5,int(limit))));
        for(var i=1;i LTE max(1,min(5,int(limit))) AND getTickCount()+10000 LT deadline;i++) {
            if(!variables.store.workerValid(variables.workerToken)){summary.status="batch_expired";break;}
            work=variables.store.claim();if(structIsEmpty(work))break;
            try {
                source=deserializeJSON(work.source_snapshot & "");
                if(!structKeyExists(source,"version") OR source.version NEQ 2) {
                    result=variables.store.finish(work,{status="insufficient_data",candidate={},reasons=["pipeline_updated"]},"job");
                    arrayAppend(summary.results,result);summary.processed++;continue;
                }
                var research=variables.sources.research(source,deadline);
                if(structKeyExists(research,"deferred") AND research.deferred){variables.store.defer(work,60);summary.status="time_budget";break;}
                summary.source_documents+=research.documents;
                queries=variables.policy.queries(source,research);
                decision={status="insufficient_data",candidate={},candidates=[],reasons=["no_location_data"]};last={};deferred=false;
                for(query in queries) {
                    // A city cannot improve an existing specific review proposal.
                    // All specific queries still run, preserving conflict detection.
                    if(query.kind EQ "city" AND decision.status EQ "needs_review" AND !structIsEmpty(decision.candidate))break;
                    query.country=source.pais;
                    reply=lookup(query,deadline);
                    if(!reply.ok){last=reply;break;}
                    var candidate=variables.policy.evaluate(source,query,reply.results);candidate.lookup={kind=query.kind,source=query.source,text=query.text};
                    if(candidate.status EQ "auto_applied"){decision=candidate;break;}
                    if(candidate.status EQ "needs_review" AND !structIsEmpty(candidate.candidate))decision=candidate;
                    else if(decision.status EQ "insufficient_data" AND candidate.status EQ "city_suggestion")decision=candidate;
                }
                if(!structIsEmpty(last)) {
                    if(listFind("daily_limit,provider_cooldown,provider_busy,pacing,time_budget,batch_expired",last.code)){variables.store.defer(work,last.retryAfter);summary.status=last.code;deferred=true;}
                    else {decision={status="error",code=last.code,candidate={},reasons=[last.code],httpStatus=structKeyExists(last,"httpStatus") ? last.httpStatus : 0};summary.errors++;}
                }
                // Later items may already be cached even when the provider is paused.
                if(deferred){if(listFind("time_budget,batch_expired",last.code))break;else continue;}
                if(!variables.store.workerValid(variables.workerToken)){variables.store.defer(work,60);summary.status="batch_expired";break;}
                decision.sourceRetry=structKeyExists(research,"temporary") AND research.temporary;
                decision.research=research;structDelete(decision.research,"queries");
                result=variables.store.finish(work,decision,"job");arrayAppend(summary.results,result);summary.processed++;
                if(result.status EQ "auto_applied")summary.applied++;
                if(result.status EQ "city_suggestion")summary.suggestions++;
                if(result.status EQ "needs_review")summary.review++;
                if(!structIsEmpty(last)) {summary.status=last.code;break;}
            } catch(any workFailure) {
                // Avoid exception text, provider content, or connection strings in cron history.
                try {variables.store.finish(work,{status="error",code="execution_error",candidate={},reasons=["execution_error"]},"job");}
                catch(any cannotFinalize) {/* An expired lease is recovered by the next claim; no unbounded attempt reset. */}
                summary.errors++;summary.status="execution_error";break;
            }
        }
        } finally {variables.store.releaseWorker(variables.workerToken);}
        summary.calls=variables.calls;summary.cache_hits=variables.cacheHits;summary.success=summary.errors EQ 0;
        if(summary.status EQ "not_configured")summary.status="completed";
        if(summary.status NEQ "completed")summary.message=safeError(summary.status);
        return summary;
    }
}
