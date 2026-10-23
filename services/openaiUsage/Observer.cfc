component output=false {
    variables.directory="/var/lib/runnerhub/openai-usage";
    public any function init(string directory="/var/lib/runnerhub/openai-usage"){variables.directory=directory;return this;}
    private string function safe(required any value,string fallback=""){
        if(!isSimpleValue(value))return fallback;
        var text=trim(value & "");
        return len(text) LTE 100 AND reFind("^[A-Za-z0-9][A-Za-z0-9._-]*$",text) AND !findNoCase("sk-",text) ? text : fallback;
    }
    public struct function normalize(required string module,required string operation,required string model,required struct response,numeric durationMs=0){
        if(!structKeyExists(new services.openaiUsage.Catalog().modules(),module))throw(type="OpenAIUsage.Invalid",message="Unknown module.");
        var data={};var raw=structKeyExists(response,"fileContent") AND isSimpleValue(response.fileContent) ? response.fileContent & "" : "";
        if(len(raw) LTE 2097152 AND isJSON(raw))try{var decoded=deserializeJSON(raw);if(isStruct(decoded))data=decoded;}catch(any invalid){}
        var status=structKeyExists(response,"statusCode") AND isSimpleValue(response.statusCode) ? val(response.statusCode) : 0;
        var name=structKeyExists(data,"model") ? safe(data.model,safe(model,"unknown")) : safe(model,"unknown");
        var tier=structKeyExists(data,"service_tier") ? safe(data.service_tier,"unknown") : "default";
        var u=structKeyExists(data,"usage") AND isStruct(data.usage) ? data.usage : {};
        var price=new services.openaiUsage.Pricing().estimate(name,u,tier);var m=price.meter;
        var state=status GTE 200 AND status LT 300 ? "success" : "error";
        if(state EQ "success" AND structKeyExists(data,"status") AND isSimpleValue(data.status)){
            if(listFind("failed,cancelled",data.status))state="error";
            else if(listFind("incomplete,queued,in_progress",data.status))state="incomplete";
        }
        var error="";if(structKeyExists(data,"error") AND isStruct(data.error) AND structKeyExists(data.error,"code"))error=safe(data.error.code);
        if(status EQ 0)error="transport_unknown";
        return {schema_version=1,id=lCase(createUUID()),at_ms=createObject("java","java.lang.System").currentTimeMillis(),module=module,operation=safe(operation,"request"),model=name,tier=tier,http_status=max(0,min(599,status)),status=state,error_code=error,duration_ms=max(0,min(600000,int(durationMs))),response_id=structKeyExists(data,"id") ? safe(data.id) : "",tokens_known=m.known,input_tokens=m.input,output_tokens=m.output,cached_tokens=m.cached,write_30m_tokens=m.write30,write_12h_tokens=m.write12,reasoning_tokens=m.reasoning,cost_known=price.known,estimated_usd=price.usd,partial_cost=price.partial,price_version=price.version,cost_reason=price.reason,source="ledger"};
    }
    private any function wire(required any value){
        if(isStruct(value)){var object=structNew("ordered-casesensitive");for(var key in value)object[lCase(key)]=wire(value[key]);return object;}
        if(isArray(value)){var values=[];for(var item in value)arrayAppend(values,wire(item));return values;}
        return value;
    }
    public boolean function observe(required string module,required string operation,required string model,required struct response,numeric durationMs=0){
        try{
            var event=normalize(module,operation,model,response,durationMs);
            if(!directoryExists(variables.directory))throw(type="OpenAIUsage.Storage",message="Storage unavailable.");
            var line=serializeJSON(wire(event)) & chr(10);
            if(len(line) GT 3000)throw(type="OpenAIUsage.Storage",message="Event too large.");
            var filename=variables.directory & "/" & dateTimeFormat(now(),"yyyy-mm-dd","UTC") & ".jsonl";
            lock name="rr-openai-usage-" & hash(variables.directory) type="exclusive" timeout=2 {fileAppend(filename,line,"utf-8");}
            return true;
        }catch(any unavailable){
            try{writeLog(file="business-openai-observability",type="warning",text="usage_ledger_unavailable");}catch(any loggingUnavailable){}
            return false;
        }
    }
}
