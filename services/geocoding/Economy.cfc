component output=false {
    public any function init(required struct config,any budget=0,any transport=0,any generationClient=0,any store=0,any astraClient=0,string batchDirectory="/var/lib/runnerhub/geocoding-batch"){
        variables.config=config;variables.policy=new services.geocoding.EconomyPolicy();
        variables.budget=isObject(budget) ? budget : new services.geocoding.AIBudget();
        variables.transport=isObject(transport) ? transport : new services.geocoding.BatchTransport(config.aiKey ?: "");
        variables.client=isObject(generationClient) ? generationClient : new services.geocoding.EconomyAIClient(config.aiKey ?: "",variables.policy.model());
        variables.astraClient=isObject(astraClient) ? astraClient : new services.geocoding.EconomyAIClient(config.aiKey ?: "","gpt-6-astra");
        variables.store=isObject(store) ? store : new services.geocoding.LocationStore();
        variables.batch=new services.geocoding.BatchClient(variables.budget,variables.transport,batchDirectory,0,variables.store);return this;
    }
    private struct function deferred(required string code,numeric seconds=600){return {ok=false,code=code,retryAfter=seconds,paid_calls=0,cache_hits=0};}
    private struct function attempt(required struct context,required array documents,required string model,required string tier,required numeric deadline){
        var body=variables.policy.body(context,documents,model);var id="econ-v1-" & lCase(hash(serializeJSON(body) & "|" & tier,"SHA-256"));
        var previous=variables.budget.get(id);
        if(!structIsEmpty(previous)){
            if(tier EQ "batch" AND (previous.state EQ "reserved" OR (previous.state EQ "uploaded" AND len(previous.file_id ?: ""))))return variables.batch.submit(id,body);
            if(isStruct(previous.reply ?: "") AND structKeyExists(previous.reply,"ok")){var cached=duplicate(previous.reply);cached.paid_calls=0;cached.cache_hits=1;return cached;}
            return deferred(previous.state EQ "submitted" ? "ai_batch_pending" : "ai_request_uncertain",previous.state EQ "submitted" ? 600 : 86400);
        }
        if(!len(variables.config.aiKey ?: ""))return deferred("ai_not_configured",3600);
        var available=variables.store.aiAvailability(variables.config.aiDailyLimit ?: 1000);if(!available.allowed)return deferred(available.reason,available.retryAfter);
        if(getTickCount()+26000 GT deadline)return deferred("time_budget",60);
        // Recheck pause immediately before crossing the cost boundary.
        if(!variables.store.settings().enabled)return deferred("disabled",86400);
        var reserve=variables.budget.reserve(id,model,tier,variables.policy.reserveUSD(body,tier));
        if(!reserve.allowed)return deferred(reserve.reason,3600);
        if(!reserve.created)return deferred("ai_request_uncertain",86400);
        var quota=variables.store.reserveAI(variables.config.aiDailyLimit ?: 1000);
        if(!quota.allowed){variables.budget.update(id,{state="uncertain",reply=deferred(quota.reason,quota.retryAfter)});return deferred(quota.reason,quota.retryAfter);}
        if(tier EQ "batch")return variables.batch.submit(id,body);
        variables.budget.update(id,{state="uncertain"});
        if(!variables.store.settings().enabled)return deferred("disabled",86400);
        var generationClient=model EQ variables.policy.model() ? variables.client : variables.astraClient;
        var reply={};
        try{reply=generationClient.extract(context,documents);}catch(any transportFailure){reply={ok=false,code="ai_unavailable",retryAfter=21600};}
        reply.paid_calls=1;reply.cache_hits=0;variables.budget.settle(id,reply);variables.store.completeAI(reply);return reply;
    }
    public struct function extract(required struct context,required array documents,struct source={},numeric deadline=0){
        if(!variables.store.settings().enabled)return deferred("disabled",86400);
        if(!arrayLen(documents))return deferred("ai_no_evidence",86400);
        if(!deadline)deadline=getTickCount()+45000;
        var tier=variables.policy.historical(source) ? "batch" : "default";
        var reply=attempt(context,documents,variables.policy.model(),tier,deadline);
        if(variables.policy.escalate(reply,documents)){
            var paid=reply.paid_calls ?: 0;var cached=reply.cache_hits ?: 0;
            var escalated=attempt(context,documents,"gpt-6-astra",tier,deadline);escalated.paid_calls=(escalated.paid_calls ?: 0)+paid;escalated.cache_hits=(escalated.cache_hits ?: 0)+cached;return escalated;
        }return reply;
    }
    public numeric function pollPending(required numeric deadline){
        if(!variables.store.settings().enabled OR getTickCount()+26000 GT deadline)return 0;
        var count=0;for(var record in variables.budget.pending(1)){if(!variables.store.settings().enabled)break;variables.batch.poll(record);count++;}return count;
    }
}
