component output=false {
    public string function model(){return "gpt-6.1-sol";}
    public boolean function historical(required struct source){
        var value=len(source.end_date ?: "") ? source.end_date : (len(source.data_final ?: "") ? source.data_final : (source.start_date ?: ""));
        try{return createObject("java","java.time.LocalDate").parse(left(value,10)).isBefore(createObject("java","java.time.LocalDate").now(createObject("java","java.time.ZoneId").of("America/Sao_Paulo")));}catch(any invalid){return false;}
    }
    public array function documents(required array documents){
        var out=[];
        for(var doc in documents){
            if(arrayLen(out) GTE 4)break;
            var text=doc.text & "";var spans=[{start=1,finish=min(len(text),1400)}];var cursor=1;
            for(var n=1;n LTE 5 AND cursor LTE len(text);n++){
                var hit=reFindNoCase("largada|retirada|entrega.{0,12}kit|start.{0,12}(line|location)|race.{0,12}(start|venue)|packet.{0,12}(pickup|collection)|salida|recogida|endereço|address|inscri[çc]|registration|organiza",text,cursor);
                if(!hit)break;arrayAppend(spans,{start=max(1,hit-240),finish=min(len(text),hit+650)});cursor=hit+651;
            }
            arraySort(spans,function(a,b){return a.start-b.start;});var selected="";var last=0;
            for(var span in spans){var start=max(span.start,last+1);if(span.finish GTE start){if(start GT last+1)selected &= chr(10) & "[...]" & chr(10);selected &= mid(text,start,span.finish-start+1);last=span.finish;}}
            arrayAppend(out,{url=doc.url,text=left(selected,5000),sha256=doc.sha256 ?: ""});
        }return out;
    }
    public struct function body(required struct context,required array documents,string model="gpt-6.1-sol"){
        if(!listFind("gpt-6.1-sol,gpt-6-astra",model))throw(type="Geocoding.Economy",message="Modelo não autorizado.");
        var body=new services.geocoding.AIClient().requestBody(context,this.documents(documents),model);
        body.max_output_tokens=model EQ "gpt-6-astra" ? 3000 : 2000;body.service_tier="default";
        var reasoning=structNew("ordered-casesensitive");reasoning["effort"]="low";body.reasoning=reasoning;
        body.instructions &= " Seja conciso: não repita a mesma informação nem citações idênticas; inclua apenas atributos explicitamente comprovados. [...] marca texto omitido, não evidencia continuidade. Nunca combine trechos separados como uma citação literal.";
        return body;
    }
    public numeric function reserveUSD(required struct body,string tier="default"){
        if(!listFind("default,batch",tier) OR !listFind("gpt-6.1-sol,gpt-6-astra",body.model))throw(type="Geocoding.Economy",message="Tarifa não autorizada.");
        // UTF-8 bytes bound token count conservatively; include protocol margin.
        var input=arrayLen(charsetDecode(serializeJSON(body),"utf-8"))+2048;
        if(input GT 70000)throw(type="Geocoding.Economy",message="Pedido acima do limite seguro.");
        var inputRate=body.model EQ "gpt-6-astra" ? 10 : 2;var outputRate=inputRate*5;
        return ceiling((input*inputRate*2.5+body.max_output_tokens*outputRate)*(tier EQ "batch" ? 0.5 : 1))/1000000;
    }
    public boolean function escalate(required struct reply,required array documents){
        if(arrayLen(documents) LT 2)return false;
        if(!reply.ok)return (reply.code ?: "") EQ "ai_invalid_response";
        if(!structKeyExists(reply,"facts") OR !isArray(reply.facts.locations ?: ""))return false;
        if(isArray(reply.facts.attributes ?: ""))for(var attribute in reply.facts.attributes)if((attribute.certainty ?: "") EQ "conflicting")return false;
        var unclear=false;for(var loc in reply.facts.locations){if((loc.certainty ?: "") EQ "conflicting")return false;if((loc.certainty ?: "") EQ "undefined")unclear=true;}
        return unclear AND len(reply.facts.event_name ?: "") AND len(reply.facts.event_date ?: "");
    }
}
