component output=false {
    public string function version(){return "2026-10-23-standard-v1";}
    private numeric function count(required any value){
        if(!isSimpleValue(value) OR !isNumeric(value) OR value LT 0 OR value GT 1000000000 OR fix(value) NEQ value)throw(type="OpenAIUsage.Invalid",message="Invalid token count.");
        return value+0;
    }
    public struct function meter(required struct usage){
        var m={known=false,input=0,output=0,cached=0,write30=0,write12=0,reasoning=0,cacheComplete=false};
        try{
            if(!structKeyExists(usage,"input_tokens") OR !structKeyExists(usage,"output_tokens"))return m;
            m.input=count(usage.input_tokens);m.output=count(usage.output_tokens);
            var d=structKeyExists(usage,"input_tokens_details") AND isStruct(usage.input_tokens_details) ? usage.input_tokens_details : {};
            if(structKeyExists(d,"cached_tokens"))m.cached=count(d.cached_tokens);
            var writes=structKeyExists(d,"cache_write_tokens") ? count(d.cache_write_tokens) : 0;
            if(structKeyExists(d,"cache_write_tokens_details") AND isStruct(d.cache_write_tokens_details)){
                m.write30=count(d.cache_write_tokens_details.ttl_30m_tokens);m.write12=count(d.cache_write_tokens_details.ttl_12h_tokens);
                if(m.write30+m.write12 NEQ writes)return m;
                m.cacheComplete=structKeyExists(d,"cached_tokens");
            } else if(writes GT 0){return m;} else {m.cacheComplete=structKeyExists(d,"cached_tokens") AND structKeyExists(d,"cache_write_tokens");}
            if(m.cached+m.write30+m.write12 GT m.input)return m;
            if(structKeyExists(usage,"output_tokens_details") AND isStruct(usage.output_tokens_details) AND structKeyExists(usage.output_tokens_details,"reasoning_tokens"))m.reasoning=count(usage.output_tokens_details.reasoning_tokens);
            if(m.reasoning GT m.output)return m;
            m.known=true;
        }catch(any invalid){}
        return m;
    }
    public struct function estimate(required string model,required struct usage,string tier="default"){
        var m=meter(usage);var out={known=false,usd=0,meter=m,version=version(),reason="usage_missing",partial=true};
        if(!m.known)return out;
        var name=reReplace(lCase(trim(model)),"-\d{4}-\d{2}-\d{2}$","");
        var prices={"gpt-6-astra"=[10,50,1],"gpt-6.1-sol"=[2,10,0.1],"gpt-6-sol"=[2,10,0.2],"gpt-6-luna"=[0.1,0.5,0.01],"gpt-5.6-sol"=[4,20,0.4],"gpt-5.6-terra"=[2,12,0.2],"gpt-5.6-luna"=[0.2,1.2,0.02],"gpt-4.1-mini"=[0.4,1.6,0.1]};
        if(!structKeyExists(prices,name)){out.reason="model_unpriced";return out;}
        var rate=duplicate(prices[name]);var modern=name NEQ "gpt-4.1-mini";
        var mode=len(trim(tier)) ? lCase(trim(tier)) : "default";
        if(!listFind("default,auto,flex,batch,priority,ultrafast",mode)){out.reason="tier_unpriced";return out;}
        if(!modern AND !listFind("default,auto,priority,batch",mode)){out.reason="tier_unpriced";return out;}
        if(mode EQ "ultrafast" AND name NEQ "gpt-6-astra"){out.reason="tier_unpriced";return out;}
        if(m.input GT 272000 AND modern){rate[1]*=2;rate[2]*=1.5;rate[3]*=2;}
        var multiplier=listFind("flex,batch",mode) ? 0.5 : (mode EQ "priority" ? (modern ? 2 : 1.75) : (mode EQ "ultrafast" ? 6 : 1));
        if(!modern AND (m.write30+m.write12) GT 0){out.reason="cache_unpriced";return out;}
        out.usd=((m.input-m.cached-m.write30-m.write12)*rate[1]+m.cached*rate[3]+m.write30*rate[1]*1.25+m.write12*rate[1]*2.5+m.output*rate[2])*multiplier/1000000;
        out.known=true;out.reason="estimated";out.partial=modern AND !m.cacheComplete;
        return out;
    }
}
