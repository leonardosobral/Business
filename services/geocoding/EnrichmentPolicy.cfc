component output=false {
    variables.p=new services.geocoding.Policy();variables.locations=new services.geocoding.LocationPolicy();variables.regions=new services.geocoding.RegionNames();
    public struct function definitions(){
        var out=structNew("ordered");
        var labels={cidade="Cidade da prova",estado="Estado / UF",pais="País",endereco="Endereço da prova",data_inicial="Data inicial",data_final="Data final",organizador="Organizador",tipo_corrida="Tipo de corrida",url_inscricao="Link de inscrição",url_hotsite="Site oficial",url_regulamento="Regulamento",horarios_largada="Horários de largada",modalidades_distancias="Modalidades e distâncias",kit_programacao="Programação da retirada de kits",inscricoes_periodo="Período de inscrições",plataforma_inscricao="Plataforma de inscrição",precos_lotes="Preços, lotes e validade",regras_participacao="Regras de participação",contatos_publicos="Contatos públicos",redes_sociais="Redes sociais oficiais",estrutura="Estrutura e acessibilidade"};
        for(var field in listToArray("cidade,estado,pais,endereco,data_inicial,data_final,organizador,tipo_corrida,url_inscricao,url_hotsite,url_regulamento,horarios_largada,modalidades_distancias,kit_programacao,inscricoes_periodo,plataforma_inscricao,precos_lotes,regras_participacao,contatos_publicos,redes_sociais,estrutura"))out[field]={label=labels[field],column=listFind("cidade,estado,pais,endereco,data_inicial,data_final,organizador,tipo_corrida,url_inscricao,url_hotsite,url_regulamento",field) ? field : "",max=listFind("estado,pais",field) ? 2 : (listFind("cidade,organizador",field) ? 120 : (field EQ "endereco" ? 240 : (find("url_",field) EQ 1 ? 512 : 1800)))};
        return out;
    }
    public struct function nativeSnapshot(required struct e){var out={};for(var field in definitions())if(len(definitions()[field].column))out[field]=current(e,field);return out;}
    public string function current(required struct e,required string field){
        var defs=definitions();if(!structKeyExists(defs,field))return "";
        if(len(defs[field].column)){if(listFind("data_inicial,data_final",field))return structKeyExists(e,field) AND !isNull(e[field]) AND isDate(e[field]) ? dateFormat(e[field],"yyyy-mm-dd") : "";return variables.p.text(e,field);}
        var data=structKeyExists(e,"localizacoes") AND isStruct(e.localizacoes) ? e.localizacoes : (structKeyExists(e,"localizacoes") AND !isNull(e.localizacoes) AND isJSON(e.localizacoes & "") ? deserializeJSON(e.localizacoes & "") : {});
        if(structKeyExists(data,"enriquecimento") AND structKeyExists(data.enriquecimento,"fields") AND structKeyExists(data.enriquecimento.fields,field))return variables.p.text(data.enriquecimento.fields[field],"value");
        if(field EQ "precos_lotes"){if(len(variables.p.text(e,"valor_inscricao")))return variables.p.text(e,"valor_inscricao");var prices=structKeyExists(e,"precos") AND !isNull(e.precos) ? e.precos & "" : "";if(len(prices) AND !listFind("{},[]",prices))return prices;}
        return "";
    }
    public boolean function equivalent(required string field,required string a,required string b){
        if(!len(trim(a)) OR !len(trim(b)))return false;
        if(field EQ "pais")return len(variables.regions.country(a)) AND variables.regions.country(a) EQ variables.regions.country(b);
        if(field EQ "estado")return variables.regions.state(a) EQ variables.regions.state(b);
        if(field EQ "tipo_corrida")return len(canonical(field,a)) AND canonical(field,a) EQ canonical(field,b);
        if(find("url_",field) EQ 1)return compare(reReplace(trim(a),"/$",""),reReplace(trim(b),"/$","")) EQ 0;
        return variables.p.normalize(a) EQ variables.p.normalize(b);
    }
    private string function canonical(required string field,required string value){
        if(field EQ "pais")return variables.regions.country(value);
        if(field EQ "estado")return variables.regions.state(value);
        if(field EQ "tipo_corrida"){var text=variables.p.normalize(value);if(listFind("rua,corrida de rua",text))return "rua";if(listFind("trail,trail run,corrida em trilha,corrida de trilha",text))return "trail";if(listFind("treino,treinamento",text))return "treino";return "";}
        return trim(value);
    }
    private boolean function dateLiteral(required string value,required string quote){
        if(!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",value))return false;
        var y=val(left(value,4));var m=val(mid(value,6,2));var d=val(right(value,2));
        try{if(dateFormat(createDate(y,m,d),"yyyy-mm-dd") NEQ value)return false;}catch(any invalidDate){return false;}
        if(find(value,quote) OR reFind("(^|[^0-9])0?" & d & "\s*[/.-]\s*0?" & m & "\s*[/.-]\s*" & y & "([^0-9]|$)",quote))return true;
        var months=["janeiro","fevereiro","marco","abril","maio","junho","julho","agosto","setembro","outubro","novembro","dezembro"];
        return reFind("\b0?" & d & " (?:de )?" & months[m] & " (?:de )?" & y & "\b",variables.p.normalize(quote)) GT 0;
    }
    private boolean function purpose(required string field,required string quote){
        var s=variables.p.normalize(quote);var patterns={organizador="\b(organizacao|organizador|organizadora|realizacao|realizador)\b",endereco="\b(largada|local da prova|local do evento|local da corrida)\b",cidade="\b(largada|local da prova|local do evento|local da corrida)\b",estado="\b(largada|local da prova|local do evento|local da corrida)\b",pais="\b(largada|local da prova|local do evento|local da corrida)\b",horarios_largada="\blargada",modalidades_distancias="\b(km|quilometros|metros|distancias|modalidades)\b",kit_programacao="\b(kit|kits|expo)\b",inscricoes_periodo="\binscric",plataforma_inscricao="\binscric",precos_lotes="\b(lote|lotes|valor|valores|preco|precos|inscric)\b",regras_participacao="\b(idade|categoria|documento|equipamento|obrigatorio|limite|participa)\b",contatos_publicos="\b(contato|telefone|email|e mail|whatsapp|informacoes)\b",redes_sociais="\b(instagram|facebook|youtube|tiktok|rede|redes)\b",estrutura="\b(hidratacao|guarda volumes|estacionamento|acessibilidade|estrutura|banheiro|apoio)\b",url_inscricao="\binscric",url_hotsite="\b(site|oficial)\b",url_regulamento="\bregulamento\b",tipo_corrida="\b(corrida|trail|treino)\b",data_inicial="\b(data|realizad|acontec|evento|corrida|prova)" ,data_final="\b(ate|termin|encerr|final|dias)"};
        if(!structKeyExists(patterns,field) OR !reFind(patterns[field],s))return false;
        if(listFind("cidade,estado,pais,endereco",field) AND reFind("\b(kit|kits|expo)\b",s) AND !reFind("\blargada e (?:retirada|entrega)\b",s))return false;
        return true;
    }
    private boolean function literalValue(required string field,required string value,required string quote){
        if(field EQ "estado")return variables.regions.hasState(quote,value);
        if(field EQ "pais")return variables.regions.hasCountry(quote,value);
        if(listFind("data_inicial,data_final",field))return dateLiteral(value,quote);
        return find("url_",field) EQ 1 ? find(value,quote) GT 0 : find(variables.p.normalize(value),variables.p.normalize(quote)) GT 0;
    }
    private boolean function valueBound(required string field,required string value,required string quote){
        // Purpose and value must coexist in the same clause, not in separate sponsor/contact paragraphs.
        var clauses=createObject("java","java.lang.String").init(quote).replaceAll("(?i)(?<=[.!?])\s+|[;\r\n]+|,\s*(?=(?:Patrocínio|Patrocinio|Apoio|Realização|Realizacao|Organiza[çc][ãa]o|Contato)\s*:)",chr(10));
        for(var clause in listToArray(clauses,chr(10)))if(purpose(field,clause) AND literalValue(field,value,clause))return true;
        return false;
    }
    public struct function validate(required struct source,required array documents,required struct extracted){
        var out={version=1,fields=[]};var defs=definitions();if(!structKeyExists(extracted,"attributes") OR !isArray(extracted.attributes))return out;
        for(var raw in extracted.attributes){if(arrayLen(out.fields) GTE 24)break;if(!isStruct(raw))continue;var field=variables.p.text(raw,"field");if(!structKeyExists(defs,field))continue;
            var proof=variables.locations.fieldEvidence(source,documents,extracted,raw);var quote=variables.p.text(raw,"quote");var value=canonical(field,variables.p.text(raw,"value"));
            var entry={field=field,label=defs[field].label,value=value,current=current(source,field),trusted=proof.trusted,evidence=proof.evidence,reasons=proof.reasons,status="unconfirmed"};
            if(variables.p.text(raw,"certainty") NEQ "confirmed" OR !len(value) OR len(value) GT defs[field].max OR !purpose(field,quote) OR reFind("\b(a definir|a confirmar|em breve|sujeito a alteracao)\b",variables.p.normalize(quote))){entry.trusted=false;arrayAppend(entry.reasons,"field_not_confirmed");}
            var literal=literalValue(field,find("url_",field) EQ 1 OR listFind("estado,pais,data_inicial,data_final",field) ? value : variables.p.text(raw,"value"),quote);
            if(!literal){entry.trusted=false;arrayAppend(entry.reasons,"fact_not_literal");}
            if(!valueBound(field,find("url_",field) EQ 1 OR listFind("estado,pais,data_inicial,data_final",field) ? value : variables.p.text(raw,"value"),quote)){entry.trusted=false;arrayAppend(entry.reasons,"purpose_value_mismatch");}
            if(listFind("cidade,estado,pais,endereco",field) AND !variables.locations.raceFieldBound(quote,field,value)){entry.trusted=false;arrayAppend(entry.reasons,"purpose_address_mismatch");}
            if(find("url_",field) EQ 1 AND (!reFindNoCase("^https://[a-z0-9][a-z0-9.-]+(?:/[^\s]*)?$",value) OR reFindNoCase("^https://(?:localhost|127\.|10\.|192\.168\.|169\.254\.)",value))){entry.trusted=false;arrayAppend(entry.reasons,"invalid_url");}
            if(listFind("data_inicial,data_final",field) AND !reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",value)){entry.trusted=false;arrayAppend(entry.reasons,"invalid_date");}
            if(listFind("data_inicial,data_final",field) AND (!reFind("\b(evento|prova|corrida)\b",variables.p.normalize(quote)) OR reFind("\b(inscricoes|kit|kits|lote|expo)\b",variables.p.normalize(quote)))){entry.trusted=false;arrayAppend(entry.reasons,"event_date_purpose_missing");}
            if(reFindNoCase("<\s*/?\s*[a-z!]",value)){entry.trusted=false;arrayAppend(entry.reasons,"markup_not_allowed");}
            if(field EQ "precos_lotes" AND (!reFind("[0-9]",value) OR !reFindNoCase("R\$|US\$|EUR|BRL|reais|euros",quote) OR !reFindNoCase("valid|vigencia|até|ate|de [0-9].*a [0-9]",quote))){entry.trusted=false;arrayAppend(entry.reasons,"price_validity_missing");}
            if(listFind("cidade,estado",field) AND len(variables.p.text(source,"catalog_city"))){var expected=field EQ "cidade" ? source.catalog_city : variables.p.text(source,"catalog_state");if(len(expected) AND !equivalent(field,expected,value)){entry.trusted=false;arrayAppend(entry.reasons,"catalog_conflict");}}
            if(entry.trusted)entry.status=!len(entry.current) ? "fill" : (equivalent(field,entry.current,value) ? "equivalent" : "needs_review");
            arrayAppend(out.fields,entry);
        }
        for(var a=1;a LTE arrayLen(out.fields);a++)for(var b=a+1;b LTE arrayLen(out.fields);b++)if(out.fields[a].field EQ out.fields[b].field){
            if(equivalent(out.fields[a].field,out.fields[a].value,out.fields[b].value)){arrayDeleteAt(out.fields,b);b--;}
            else {out.fields[a].trusted=false;out.fields[b].trusted=false;out.fields[a].status="needs_review";out.fields[b].status="needs_review";arrayAppend(out.fields[a].reasons,"conflicting_sources");arrayAppend(out.fields[b].reasons,"conflicting_sources");}
        }
        return out;
    }
}
