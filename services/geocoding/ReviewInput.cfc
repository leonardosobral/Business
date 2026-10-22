component output=false {
    variables.fields=new services.geocoding.EnrichmentPolicy();variables.regions=new services.geocoding.RegionNames();
    public struct function describe(required string field){
        var defs=variables.fields.definitions();if(!structKeyExists(defs,field))throw(type="Geocoding.Validation",message="Este campo não pode ser editado na revisão.");
        var type=listFind("data_inicial,data_final",field) ? "date" : (field EQ "tipo_corrida" ? "select" : (find("url_",field) EQ 1 ? "url" : (!len(defs[field].column) ? "textarea" : "text")));
        return {type=type,max=listFind("estado,pais",field) ? 120 : defs[field].max,label=defs[field].label};
    }
    public string function validate(required string field,required any value,required struct event){
        var spec=describe(field);if(!isSimpleValue(value))throw(type="Geocoding.Validation",message="Informe um texto válido para este campo.");
        var clean=trim(replace(value & "",chr(13),"","all"));
        if(!len(clean) OR len(clean) GT spec.max)throw(type="Geocoding.Validation",message="Preencha " & spec.label & " com até " & spec.max & " caracteres.");
        if(reFindNoCase("<\s*/?\s*[a-z!]|[\x00-\x08\x0B\x0C\x0E-\x1F]",clean))throw(type="Geocoding.Validation",message="Use somente texto, sem código HTML ou caracteres de controle.");
        if(field EQ "pais"){clean=variables.regions.country(clean);if(!len(clean))throw(type="Geocoding.Validation",message="Informe um país válido, pelo nome ou sigla.");}
        if(field EQ "estado"){clean=variables.regions.state(clean);if(!reFind("^[A-Z]{2}$",clean) OR ((!len(event.pais ?: "") OR variables.regions.country(event.pais) EQ "BR") AND !listFind("AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO",clean)))throw(type="Geocoding.Validation",message="Informe um estado válido, pelo nome ou UF.");}
        if(field EQ "tipo_corrida"){clean=lCase(clean);if(!listFind("rua,trail,treino",clean))throw(type="Geocoding.Validation",message="Selecione Rua, Trail ou Treino.");}
        if(spec.type EQ "date"){
            var valid=false;try{valid=reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",clean) AND dateFormat(createDate(val(left(clean,4)),val(mid(clean,6,2)),val(right(clean,2))),"yyyy-mm-dd") EQ clean;}catch(any invalidDate){}
            if(!valid)throw(type="Geocoding.Validation",message="Informe uma data válida.");
            var other=field EQ "data_inicial" ? "data_final" : "data_inicial";
            if(structKeyExists(event,other) AND !isNull(event[other]) AND isDate(event[other])){
                var order=dateCompare(parseDateTime(clean),event[other],"d");
                if((field EQ "data_inicial" AND order GT 0) OR (field EQ "data_final" AND order LT 0))throw(type="Geocoding.Validation",message="A data final não pode ser anterior à data inicial. Confira as duas datas antes de salvar.");
            }
        }
        if(spec.type EQ "url"){
            var valid=false;try{var uri=createObject("java","java.net.URI").init(clean);var host=lCase(uri.getHost() ?: "");valid=uri.getScheme() EQ "https" AND isNull(uri.getRawUserInfo()) AND (uri.getPort() EQ -1 OR uri.getPort() EQ 443) AND reFind("^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,63}$",host) AND !reFind("(?:^|\.)(localhost|local|internal|invalid|test)$",host) AND !reFind("[\s\\]",clean);}catch(any invalidUrl){}
            if(!valid)throw(type="Geocoding.Validation",message="Informe um link HTTPS público válido, sem credenciais ou endereço interno.");
        }
        return clean;
    }
}
