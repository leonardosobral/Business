component output=false {
    public any function init(required any budget,required any transport,string directory="/var/lib/runnerhub/geocoding-batch",any observer=0,any gate=0){variables.budget=budget;variables.transport=transport;variables.directory=directory;variables.observer=isObject(observer) ? observer : new services.openaiUsage.Observer();variables.gate=isObject(gate) ? gate : new services.geocoding.LocationStore();return this;}
    private boolean function enabled(){try{return variables.gate.settings().enabled;}catch(any unavailable){return false;}}
    private struct function paused(){return {ok=false,code="disabled",retryAfter=86400,paid_calls=0};}
    private struct function wire(required struct value){var o=structNew("ordered-casesensitive");for(var k in value){var name=compareNoCase(k,"additionalProperties") EQ 0 ? "additionalProperties" : (compareNoCase(k,"maxItems") EQ 0 ? "maxItems" : lCase(k));o[name]=isStruct(value[k]) ? wire(value[k]) : value[k];}return o;}
    private struct function parsed(required struct response){
        if(val(response.statusCode ?: 0) LT 200 OR val(response.statusCode ?: 0) GTE 300 OR !isSimpleValue(response.fileContent ?: "") OR len(response.fileContent) GT 1000000 OR !isJSON(response.fileContent))throw(message="Batch indisponível.");
        var out=deserializeJSON(response.fileContent);if(!isStruct(out))throw(message="Resposta Batch inválida.");return out;
    }
    private string function identifier(required any id){if(!isSimpleValue(id) OR !reFind("^[A-Za-z0-9_-]{1,100}$",id))throw(message="ID Batch inválido.");return id & "";}
    public struct function submit(required string id,required struct body){
        var record=variables.budget.get(id);if(structIsEmpty(record))throw(message="Reserva obrigatória.");
        if(!enabled())return paused();
        if(record.state NEQ "reserved" AND !(record.state EQ "uploaded" AND len(record.file_id ?: "")))return {ok=false,code="ai_batch_pending",retryAfter=600,paid_calls=0};
        var temporary="";
        try{
            var fileId=record.file_id ?: "";
            if(!len(fileId)){
                if(!directoryExists(variables.directory))throw(message="Diretório privado indisponível.");
                var custom="geo-" & lCase(replace(createUUID(),"-","","all"));
                // Claim durable state BEFORE upload; an unknown result is not resent.
                variables.budget.update(id,{state="uploaded",custom_id=custom});
                temporary=variables.directory & "/" & custom & ".jsonl";fileWrite(temporary,serializeJSON(wire({custom_id=custom,method="POST",url="/v1/responses",body=body})) & chr(10),"utf-8");fileSetAccessMode(temporary,"640");
                if(!enabled()){variables.budget.update(id,{state="reserved"});return paused();}
                var upload=parsed(variables.transport.request("POST","files",{},temporary));fileId=identifier(upload.id);
                variables.budget.update(id,{state="uploaded",file_id=fileId});
            }
            if(!enabled())return paused();
            // Unknown creation outcome is never retried; confirmed upload may resume.
            variables.budget.update(id,{state="uncertain"});
            if(!enabled()){variables.budget.update(id,{state="uploaded"});return paused();}
            var batch=parsed(variables.transport.request("POST","batches",wire({input_file_id=fileId,endpoint="/v1/responses",completion_window="24h"})));
            variables.budget.update(id,{state="submitted",batch_id=identifier(batch.id)});
            return {ok=false,code="ai_batch_pending",retryAfter=600,paid_calls=1};
        }catch(any unavailable){variables.budget.update(id,{state="uncertain",reply={ok=false,code="ai_batch_uncertain",retryAfter=86400}});return {ok=false,code="ai_batch_uncertain",retryAfter=86400,paid_calls=1};}
        finally{if(len(temporary) AND fileExists(temporary))fileDelete(temporary);}
    }
    public struct function poll(required struct record){
        if(!enabled())return paused();
        var current=variables.budget.get(record.id);if((current.state ?: "") EQ "done")return current.reply;
        try{
            variables.budget.update(record.id,{last_poll_ms=createObject("java","java.lang.System").currentTimeMillis()});
            if(!enabled())return paused();
            var status=parsed(variables.transport.request("GET","batches/" & identifier(record.batch_id)));
            if((status.status ?: "") NEQ "completed"){
                if(listFind("failed,expired,cancelled",status.status ?: ""))variables.budget.update(record.id,{state="uncertain",reply={ok=false,code="ai_batch_uncertain",retryAfter=86400}});
                return {ok=false,code="ai_batch_pending",retryAfter=600};
            }
            if(!enabled())return paused();
            var content=variables.transport.request("GET","files/" & identifier(status.output_file_id) & "/content");
            if(val(content.statusCode ?: 0) NEQ 200 OR !isSimpleValue(content.fileContent ?: "") OR len(content.fileContent) GT 1000000)throw(message="Resultado Batch indisponível.");
            var lines=listToArray(trim(content.fileContent),chr(10));
            if(arrayLen(lines) NEQ 1 OR !isJSON(lines[1]))throw(message="Resultado Batch inválido.");
            var result=deserializeJSON(lines[1]);
            if(!isStruct(result) OR (result.custom_id ?: "") NEQ record.custom_id){variables.budget.update(record.id,{state="uncertain"});return {ok=false,code="ai_batch_identity",retryAfter=86400};}
            if(!isStruct(result.response ?: "") OR !isStruct(result.response.body ?: ""))throw(message="Batch sem resposta.");
            var responseBody=result.response.body;var code=val(result.response.status_code ?: 0);
            var reply=new services.geocoding.AIClient().decode(code,serializeJSON(responseBody));
            if(isStruct(responseBody.usage ?: ""))reply.usage=responseBody.usage;
            variables.budget.settle(record.id,reply);
            // Batch is billed at Batch rates even if the nested response says default.
            responseBody.service_tier="batch";
            try{variables.observer.observe("geolocation","batch-extract",record.model,{statusCode=code,fileContent=serializeJSON(wire(responseBody))},0);}catch(any unavailableTelemetry){}
            return reply;
        }catch(any unavailable){return {ok=false,code="ai_batch_pending",retryAfter=600};}
    }
}
