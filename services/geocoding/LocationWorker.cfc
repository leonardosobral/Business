component extends="services.geocoding.Worker" output=false {
    public any function init(required struct config){
        super.init(config);variables.config=config;variables.store=new services.geocoding.LocationStore();variables.policy=new services.geocoding.Policy();variables.locationPolicy=new services.geocoding.LocationPolicy();variables.reader=new services.geocoding.DocumentReader();
        variables.ai=new services.geocoding.AIClient(structKeyExists(config,"aiKey") ? config.aiKey : "",structKeyExists(config,"aiModel") ? config.aiModel : "gpt-6-astra");return this;
    }
    public numeric function responseStatus(required struct summary){if(find("ai_",summary.status) EQ 1)return summary.status EQ "ai_not_configured" ? 503 : 202;return super.responseStatus(summary);}
    public string function safeError(required string code){
        if(listFind("ai_quota_exhausted,ai_rate_limited,ai_cooldown,ai_daily_limit,ai_unavailable,ai_invalid_response,ai_credentials_rejected,ai_refusal",code))return "A interpretação por IA foi adiada (" & code & "). A fila e as etapas concluídas foram preservadas.";
        if(code EQ "ai_not_configured")return "A integração OpenAI não está configurada. Nenhuma localização foi presumida.";return super.safeError(code);
    }
    private struct function cityQuery(required struct context){return {kind="city",local=context.cidade,source="cidade",text=left(context.cidade & ", " & context.estado & ", " & context.pais,300),country=context.pais,autoEligible=false,reason="city_only"};}
    public struct function initialProgress(required struct source,required struct research,required struct reply){
        var enrichmentPolicy=new services.geocoding.EnrichmentPolicy();var enrichment=structKeyExists(reply,"facts") ? enrichmentPolicy.validate(source,research.documents,reply.facts) : {version=1,fields=[]};
        var effective=duplicate(source);for(var field in enrichment.fields)if(field.trusted AND field.status EQ "fill" AND listFind("cidade,estado,pais",field.field))effective[field.field]=field.value;
        var verified=structKeyExists(reply,"facts") ? variables.locationPolicy.validate(effective,research.documents,reply.facts) : {targets=[],diagnostics=research.diagnostics ?: []};
        var p={analysis_complete=true,targets=verified.targets,diagnostics=verified.diagnostics,documents=[],model=reply.model ?: "",usage=reply.usage ?: {},enrichment=enrichment};
        for(var doc in research.documents)arrayAppend(p.documents,{url=doc.url,sha256=doc.sha256,kind=doc.kind ?: "html"});
        for(var t in p.targets){t.status=t.trusted ? "pending" : "insufficient_data";t.candidate={};if(!t.trusted AND t.role EQ "evento" AND len(source.cidade) AND len(source.pais)){t.context={cidade=source.cidade,estado=source.estado,pais=source.pais};t.query=cityQuery(t.context);t.status="pending";}}
        var race=false;for(t in p.targets)if(t.role EQ "evento")race=true;
        if(!race AND len(variables.policy.text(source,"cidade")) AND len(variables.policy.text(source,"pais")))arrayAppend(p.targets,{role="evento",trusted=false,status="pending",facts={},context={cidade=source.cidade,estado=source.estado,pais=source.pais},evidence={},candidate={},reasons=["city_only"],query={kind="city",local=source.cidade,source="cidade",text=left(source.cidade & ", " & source.estado & ", " & source.pais,300),country=source.pais,autoEligible=false,reason="city_only"}});
        return p;
    }
    private struct function lookupLocation(required struct lookup,required numeric deadline){
        if(!variables.store.workerValid(variables.workerToken))return {ok=false,code="batch_expired",retryAfter=60};
        var cached=variables.store.cacheGet(lookup);if(cached.found){variables.cacheHits++;return {ok=true,code="ok",results=cached.results};}
        if(getTickCount()+17000 GT deadline)return {ok=false,code="time_budget",retryAfter=60};
        var reservation=variables.store.reserveCall(variables.store.settings().dailyLimit);
        if(!reservation.allowed AND reservation.reason EQ "pacing"){sleep(min(1100,reservation.waitMs+10));reservation=variables.store.reserveCall(variables.store.settings().dailyLimit);}
        if(!reservation.allowed)return {ok=false,code=reservation.reason,retryAfter=reservation.retryAfter ?: 60};
        variables.calls++;var r=variables.geoClient.search(lookup,variables.config.apiKey);variables.store.completeCall(reservation.token,r.code,r.ok ? 0 : r.retryAfter);if(r.ok)variables.store.cachePut(lookup,r.results);return r;
    }
    private string function outcome(required struct progress){var applied=false;var city=false;var review=false;for(var t in progress.targets){if(listFind("auto_applied,approved",t.status))applied=true;if(t.status EQ "city_suggestion")city=true;if(t.status EQ "needs_review" AND t.trusted AND !structIsEmpty(t.candidate))review=true;}return review ? "needs_review" : (applied ? "auto_applied" : (city ? "city_suggestion" : "insufficient_data"));}
    public struct function run(numeric limit=5){
        var summary={success=false,status="completed",pipeline_version=3,model=variables.config.aiModel ?: "gpt-6-astra",processed=0,applied=0,suggestions=0,review=0,errors=0,calls=0,cache_hits=0,ai_calls=0,ai_cache_hits=0,source_documents=0,enriched_fields=0,field_reviews=0,results=[]};
        if(!variables.store.aiReady()){summary.status="schema_missing";summary.message=safeError(summary.status);return summary;}
        if(!len(variables.config.aiKey ?: "")){summary.status="ai_not_configured";summary.message=safeError(summary.status);return summary;}
        if(!len(fingerprint())){summary.status="not_configured";summary.message=safeError(summary.status);return summary;}
        var settings=variables.store.settings();if(!settings.enabled OR settings.validatedFingerprint NEQ fingerprint()){summary.status=settings.enabled ? "not_validated" : "disabled";summary.message=safeError(summary.status);return summary;}
        var lease=variables.store.acquireWorker();if(!lease.allowed){summary.status="worker_busy";summary.success=true;return summary;}variables.workerToken=lease.token;variables.calls=0;variables.cacheHits=0;
        var deadline=getTickCount()+45000;
        try {
            variables.store.seed(max(1,min(5,int(limit))));
            for(var i=1;i LTE max(1,min(5,int(limit))) AND getTickCount()+3000 LT deadline;i++) {
                if(!variables.store.workerValid(variables.workerToken)){summary.status="batch_expired";break;}
                var work=variables.store.claim();if(structIsEmpty(work))break;
                var phase="source";
                try {
                    var source=deserializeJSON(work.source_snapshot & "");var progress=deserializeJSON(work.decision & "");var research={};var reply={};var held=false;
                    if(!structKeyExists(progress,"analysis_complete") OR !progress.analysis_complete OR !structKeyExists(progress,"enrichment")) {
                        research=variables.reader.read(source,deadline);
                        if(research.deferred ?: false){variables.store.defer(work,60);summary.status="time_budget";break;}
                        summary.source_documents+=arrayLen(research.documents);
                        if(research.temporary ?: false){variables.store.finish(work,{status="error",code="source_unavailable",diagnostics=research.diagnostics},"job");summary.status="provider_unavailable";summary.errors++;break;}
                        if(arrayLen(research.documents)) {
                            var hashes=[];for(var doc in research.documents)arrayAppend(hashes,[doc.url,doc.sha256]);
                            var key="ai-enrichment-prompt-1|" & summary.model & "|" & variables.store.sourceHash(source) & "|" & serializeJSON(hashes);var cached=variables.store.resourceGet(key);
                            if(cached.found){reply=cached.value;summary.ai_cache_hits++;}
                            else {
                                if(getTickCount()+22000 GT deadline){variables.store.defer(work,60);summary.status="time_budget";break;}
                                var reserve=variables.store.reserveAI(variables.config.aiDailyLimit ?: 1000);
                                if(!reserve.allowed){variables.store.defer(work,reserve.retryAfter);summary.status=reserve.reason;break;}
                                phase="openai";summary.ai_calls++;reply=variables.ai.extract({nome_evento=source.nome_evento,start_date=source.start_date,cidade=source.cidade,estado=source.estado,pais=source.pais},research.documents);variables.store.completeAI(reply);
                                phase="ai_cache";if(reply.ok)variables.store.resourcePut(key,reply,7);
                            }
                            if(!reply.ok){
                                summary.status=reply.code;
                                if(listFind("ai_quota_exhausted,ai_rate_limited,ai_credentials_rejected",reply.code))variables.store.defer(work,reply.retryAfter);
                                else {variables.store.finish(work,{status="error",code=reply.code},"job");summary.errors++;}
                                break;
                            }
                        }
                        phase="evidence";progress=initialProgress(source,research,reply);
                        phase="enrichment";var enriched=variables.store.publishEnrichment(work,progress,"job");work=enriched.work;progress=enriched.progress;source=deserializeJSON(work.source_snapshot & "");variables.store.checkpoint(work,progress);
                        for(var fact in progress.enrichment.fields){if(fact.status EQ "auto_applied")summary.enriched_fields++;if(fact.status EQ "needs_review")summary.field_reviews++;}
                    }
                    phase="geocoding";for(var t in progress.targets)if(t.status EQ "pending") {
                        if((t.role EQ "evento" AND len(trim(source.coordenadas))) OR structKeyExists(source.localizacoes,t.role)){t.status="preserved";continue;}
                        if(!t.trusted AND t.query.kind NEQ "city"){t.status="insufficient_data";continue;}
                        while(t.status EQ "pending"){
                        reply=lookupLocation(t.query,deadline);
                        if(!reply.ok){
                            variables.store.checkpoint(work,progress);summary.status=reply.code;
                            if(listFind("time_budget,daily_limit,provider_cooldown,provider_busy,pacing,batch_expired",reply.code))variables.store.defer(work,reply.retryAfter);
                            else {progress.status="error";progress.code=reply.code;variables.store.finish(work,progress,"job");summary.errors++;}
                            held=true;break;
                        }
                        var candidate=variables.policy.evaluate(t.context,t.query,reply.results);
                        if(t.query.kind EQ "specific" AND structIsEmpty(candidate.candidate)) {t.specific_query=duplicate(t.query);t.query=cityQuery(t.context);variables.store.checkpoint(work,progress);continue;}
                        if(t.query.kind EQ "city"){candidate.status=variables.policy.text(candidate.candidate,"result_type") EQ "city" ? "city_suggestion" : "insufficient_data";if(candidate.status EQ "insufficient_data")candidate.candidate={};}
                        t.status=candidate.status;t.candidate=candidate.candidate;t.reasons=candidate.reasons;t.candidates=candidate.candidates;
                        if(!t.trusted AND t.status EQ "auto_applied")t.status="city_suggestion";
                        variables.store.checkpoint(work,progress);
                        }
                        if(held)break;
                    }
                    if(held)break;
                    phase="publication";progress.status=outcome(progress);var result=variables.store.finish(work,progress,"job");arrayAppend(summary.results,result);summary.processed++;
                    if(result.status EQ "auto_applied")summary.applied++;if(result.status EQ "needs_review")summary.review++;if(result.status EQ "city_suggestion")summary.suggestions++;
                }catch(any failed){var diagnostic={phase=phase,type=left(failed.type,64)};if(structKeyExists(failed,"tagContext"))for(var frame in failed.tagContext)if(findNoCase("/services/geocoding/",frame.template)){diagnostic.component=listLast(frame.template,"/");diagnostic.line=frame.line;break;}try{variables.store.finish(work,{status="error",code="execution_error",diagnostic=diagnostic},"job");}catch(any expired){}summary.errors++;summary.status="execution_error";summary.diagnostic=diagnostic;break;}
            }
        }finally{variables.store.releaseWorker(variables.workerToken);}
        summary.calls=variables.calls;summary.cache_hits=variables.cacheHits;summary.success=summary.errors EQ 0;if(summary.status NEQ "completed")summary.message=safeError(summary.status);return summary;
    }
}
