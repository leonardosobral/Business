component extends="services.geocoding.Worker" output=false {
    public any function init(required struct config){
        super.init(config);variables.config=config;variables.store=new services.geocoding.LocationStore();variables.policy=new services.geocoding.Policy();variables.locationPolicy=new services.geocoding.LocationPolicy();variables.reader=new services.geocoding.DocumentReader();
        variables.ai=new services.geocoding.AIClient(structKeyExists(config,"aiKey") ? config.aiKey : "",structKeyExists(config,"aiModel") ? config.aiModel : "gpt-6-astra");return this;
    }
    public numeric function responseStatus(required struct summary){if(find("ai_",summary.status) EQ 1)return summary.status EQ "ai_not_configured" ? 503 : 202;return super.responseStatus(summary);}
    public string function safeError(required string code){
        if(code EQ "partial_sources")return "As fontes disponíveis foram aproveitadas. As demais serão consultadas novamente, sem perder os dados já confirmados.";
        if(code EQ "provider_unavailable")return "Uma fonte ou fornecedor está temporariamente indisponível. O progresso foi preservado e novas tentativas serão automáticas.";
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
    private struct function retainProgress(required struct previous,required struct progress,required struct source){
        // Never silently discard a proposal or an operator's choice when a temporary source recovers.
        if(structKeyExists(previous,"targets"))for(var old in previous.targets){
            var matched=false;
            for(var target in progress.targets)if(sameLocation(old,target)){
                matched=true;
                if(old.status EQ "rejected"){target.status="rejected";target.candidate={};}
                else if(target.trusted AND old.trusted AND !structIsEmpty(old.candidate) AND serializeJSON(variables.store.lowerKeys(old.query)) EQ serializeJSON(variables.store.lowerKeys(target.query)) AND listFind("needs_review,approved,auto_applied,preserved",old.status)){
                    target.status=old.status;target.candidate=duplicate(old.candidate);
                }
                // Fresh evidence always controls trust, context, reasons and source attribution.
                break;
            }
            if(!matched AND listFind("needs_review,rejected,approved,auto_applied,preserved",old.status)){
                var retained=duplicate(old);
                if(old.status EQ "needs_review"){retained.trusted=false;retained.status="insufficient_data";retained.candidate={};arrayAppend(retained.reasons,"evidence_not_reconfirmed");}
                else if(old.status NEQ "rejected")retained.status="preserved";
                arrayAppend(progress.targets,retained);
            }
        }
        if(structKeyExists(previous,"enrichment"))for(var oldField in previous.enrichment.fields){
            var found=false;for(var field in progress.enrichment.fields)if(oldField.field EQ field.field AND oldField.value EQ field.value){
                found=true;if(oldField.status EQ "rejected")field.status="rejected";
                if(listFind("corrected,superseded",oldField.status) AND structKeyExists(oldField,"manual") AND len(variables.policy.text(oldField.manual,"source_date")) AND variables.policy.text(oldField.manual,"source_date") EQ variables.policy.text(source,"start_date")){field.status=oldField.status;field.manual=duplicate(oldField.manual);}
                break;
            }
            if(!found AND listFind("needs_review,rejected,approved,auto_applied,corrected,superseded",oldField.status)){
                var retainedField=duplicate(oldField);if(oldField.status EQ "needs_review"){retainedField.trusted=false;retainedField.status="unconfirmed";arrayAppend(retainedField.reasons,"evidence_not_reconfirmed");}arrayAppend(progress.enrichment.fields,retainedField);
            }
        }
        return progress;
    }
    private boolean function sameLocation(required struct first,required struct second){
        if(first.role NEQ second.role)return false;
        for(var key in ["name","address","city","state","country"])if(variables.policy.normalize(variables.policy.text(first.facts,key)) NEQ variables.policy.normalize(variables.policy.text(second.facts,key)))return false;
        return true;
    }
    private struct function scheduleResearch(required struct progress,required struct previous,required string code,required numeric seconds){
        progress.analysis_complete=false;progress.analysis_retries=min(30,val(previous.analysis_retries ?: 0)+1);progress.code=code;
        progress.retry_after_seconds=listFind("source_unavailable,partial_sources",code) ? min(604800,21600*(2^min(5,progress.analysis_retries-1))) : max(60,min(86400,seconds));
        return progress;
    }
    private struct function provisional(required struct source,required struct previous,required string code,required numeric seconds){
        var p=structKeyExists(previous,"targets") ? duplicate(previous) : initialProgress(source,{documents=[],diagnostics=[code]},{});
        // No AI analysis happened: do not mark the event as enriched or overwrite its native fields.
        if(!structKeyExists(p,"enrichment"))p.enrichment={version=1,fields=[]};p.enrichment.published=true;
        return scheduleResearch(p,previous,code,seconds);
    }
    private struct function interpret(required struct source,required struct previous,required struct summary,required numeric deadline){
        var availability=len(variables.config.aiKey ?: "") ? variables.store.aiAvailability(variables.config.aiDailyLimit ?: 1000) : {allowed=false,reason="ai_not_configured",retryAfter=3600};
        if(!availability.allowed){summary.status=availability.reason;summary.deferred++;return provisional(source,previous,availability.reason,availability.retryAfter);}
        var research=variables.reader.read(source,deadline);summary.source_documents+=arrayLen(research.documents);
        if(research.deferred ?: false){summary.status="time_budget";summary.deferred++;return provisional(source,previous,"time_budget",60);}
        if((research.temporary ?: false) AND !arrayLen(research.documents)){summary.status="provider_unavailable";summary.errors++;summary.deferred++;return provisional(source,previous,"source_unavailable",21600);}
        var reply={};
        if(arrayLen(research.documents)){
            var context={nome_evento=source.nome_evento,start_date=source.start_date,cidade=source.cidade,estado=source.estado,pais=source.pais};
            var key=new services.geocoding.AIClient().cacheKey(context,research.documents,summary.model);var cached=variables.store.resourceGet(key);
            if(cached.found){reply=cached.value;summary.ai_cache_hits++;}
            else {
                if(getTickCount()+22000 GT deadline){summary.status="time_budget";summary.deferred++;return provisional(source,previous,"time_budget",60);}
                var reservation=variables.store.reserveAI(variables.config.aiDailyLimit ?: 1000);
                if(!reservation.allowed){summary.status=reservation.reason;summary.deferred++;return provisional(source,previous,reservation.reason,reservation.retryAfter);}
                summary.ai_calls++;reply=variables.ai.extract(context,research.documents);variables.store.completeAI(reply);
                if(reply.ok)variables.store.resourcePut(key,reply,7);
            }
            if(!reply.ok){summary.status=reply.code;summary.deferred++;if(!listFind("ai_quota_exhausted,ai_rate_limited,ai_credentials_rejected",reply.code))summary.errors++;return provisional(source,previous,reply.code,reply.retryAfter);}
        }
        var progress=retainProgress(previous,initialProgress(source,research,reply),source);
        if(research.temporary ?: false){summary.status="partial_sources";summary.deferred++;progress=scheduleResearch(progress,previous,"partial_sources",21600);}
        return progress;
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
        var summary={success=false,status="completed",pipeline_version=3,model=variables.config.aiModel ?: "gpt-6-astra",processed=0,applied=0,suggestions=0,review=0,errors=0,calls=0,cache_hits=0,ai_calls=0,ai_cache_hits=0,source_documents=0,enriched_fields=0,field_reviews=0,deferred=0,results=[]};
        if(!variables.store.aiReady()){summary.status="schema_missing";summary.message=safeError(summary.status);return summary;}
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
                        phase="interpretation";progress=interpret(source,progress,summary,deadline);
                        phase="enrichment";var enriched=variables.store.publishEnrichment(work,progress,"job");work=enriched.work;progress=enriched.progress;source=deserializeJSON(work.source_snapshot & "");variables.store.checkpoint(work,progress);
                        for(var fact in progress.enrichment.fields){if(fact.status EQ "auto_applied")summary.enriched_fields++;if(fact.status EQ "needs_review")summary.field_reviews++;}
                    }
                    phase="geocoding";for(var t in progress.targets)if(t.status EQ "pending") {
                        if((t.role EQ "evento" AND len(trim(source.coordenadas))) OR structKeyExists(source.localizacoes,t.role)){t.status="preserved";continue;}
                        if(!t.trusted AND t.query.kind NEQ "city"){t.status="insufficient_data";continue;}
                        while(t.status EQ "pending"){
                        reply=lookupLocation(t.query,deadline);
                        if(!reply.ok){
                            variables.store.checkpoint(work,progress);summary.geocoding_status=reply.code;if(find("ai_",summary.status) NEQ 1)summary.status=reply.code;
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
                    if(held){if(listFind("time_budget,daily_limit,provider_cooldown,provider_busy,pacing,batch_expired",reply.code))break;continue;}
                    phase="publication";progress.status=outcome(progress);var result=variables.store.finish(work,progress,"job");arrayAppend(summary.results,result);summary.processed++;
                    if(result.status EQ "auto_applied")summary.applied++;if(result.status EQ "needs_review")summary.review++;if(result.status EQ "city_suggestion")summary.suggestions++;
                }catch(any failed){var diagnostic={phase=phase,type=left(failed.type,64)};if(structKeyExists(failed,"tagContext"))for(var frame in failed.tagContext)if(findNoCase("/services/geocoding/",frame.template)){diagnostic.component=listLast(frame.template,"/");diagnostic.line=frame.line;break;}try{var durable=variables.store.detail(work.id);var retainedDecision=deserializeJSON(durable.decision & "");retainedDecision.status="error";retainedDecision.code="execution_error";retainedDecision.diagnostic=diagnostic;variables.store.finish(work,retainedDecision,"job");}catch(any expired){}summary.errors++;summary.status="execution_error";summary.diagnostic=diagnostic;}
            }
        }finally{variables.store.releaseWorker(variables.workerToken);}
        summary.calls=variables.calls;summary.cache_hits=variables.cacheHits;summary.success=summary.errors EQ 0;if(summary.status NEQ "completed")summary.message=safeError(summary.status);return summary;
    }
}
