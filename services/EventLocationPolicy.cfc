component output=false {
    variables.regions=new services.geocoding.RegionNames();variables.coordinates=new services.geocoding.Policy();
    private void function invalid(required string message){throw(type="BusinessDelegation.Validation",message=message,errorCode="event_location");}
    private string function text(required struct data,required string field,string fallback=""){
        if(!structKeyExists(data,field) OR isNull(data[field]))return fallback;
        if(!isSimpleValue(data[field]))invalid("Informação de localização inválida.");
        return trim(data[field] & "");
    }
    public array function countries(){
        var locale=createObject("java","java.util.Locale");var pt=locale.forLanguageTag("pt-BR");var out=[];
        for(var code in locale.getISOCountries())arrayAppend(out,{code=code,label=locale.forLanguageTag("und-" & code).getDisplayCountry(pt)});
        var collator=createObject("java","java.text.Collator").getInstance(pt);arraySort(out,function(a,b){return collator.compare(a.label,b.label);});return out;
    }
    public string function currentRegion(required struct event){
        var data={};
        if(structKeyExists(event,"localizacoes") AND !isNull(event.localizacoes)){
            if(isStruct(event.localizacoes))data=event.localizacoes;
            else if(isJSON(event.localizacoes & ""))data=deserializeJSON(event.localizacoes & "");
        }
        if(!isStruct(data))return "";
        if(structKeyExists(data,"administrativo") AND isStruct(data.administrativo) AND text(data.administrativo,"pais") EQ text(event,"pais"))return text(data.administrativo,"estado_nome");
        return "";
    }
    public struct function resolve(required struct posted,required struct current,string datasource="runner_dba"){
        var country=variables.regions.country(text(posted,"pais",text(current,"pais","BR")));
        if(!len(country))invalid("Selecione um país válido.");
        if(structKeyExists(posted,"location_mode") AND text(posted,"location_mode") NEQ (country EQ "BR" ? "br" : "foreign"))invalid("Os campos não correspondem ao país selecionado. Reabra o formulário com JavaScript habilitado antes de salvar.");
        var result={pais=country,cidade=text(posted,"cidade"),estado=uCase(text(posted,"estado")),cod_cidade=0,cod_cidade_null=true,endereco=text(posted,"endereco"),coordenadas=text(posted,"coordenadas"),regionName=""};
        if((len(result.endereco) GT 512 AND result.endereco NEQ text(current,"endereco")) OR (len(result.coordenadas) GT 100 AND result.coordenadas NEQ text(current,"coordenadas")))invalid("Endereço ou coordenadas excedem o tamanho permitido.");
        if(len(result.coordenadas) AND result.coordenadas NEQ text(current,"coordenadas") AND !variables.coordinates.coordinates(result.coordenadas).valid)invalid("Informe as coordenadas no formato latitude, longitude, dentro dos limites válidos.");
        if(country EQ "BR"){
            if(!reFind("^[1-9][0-9]{0,9}$",result.cidade) OR !reFind("^[A-Z]{2}$",result.estado))invalid("Selecione o estado e o município brasileiro.");
            var city=queryExecute("SELECT cod_cidade,nome_cidade,uf FROM tb_cidades WHERE cod_cidade=:city AND uf=:uf",{city={value=result.cidade,cfsqltype="cf_sql_integer"},uf={value=result.estado,cfsqltype="cf_sql_varchar"}},{datasource=datasource});
            if(city.recordCount NEQ 1)invalid("Selecione uma cidade do estado informado.");
            result.cod_cidade=city.cod_cidade[1];result.cidade=city.nome_cidade[1];result.estado=city.uf[1];result.cod_cidade_null=false;
        }else{
            if(!len(result.cidade) OR len(result.cidade) GT 120 OR reFindNoCase("<\s*/?\s*[a-z!]",result.cidade))invalid("Informe a cidade do evento, com até 120 caracteres e sem HTML.");
            if(len(result.estado) AND !reFind("^[A-Z0-9]{1,2}$",result.estado))invalid("A sigla/código da região deve ter até 2 letras ou números. Use o campo de nome completo para a região/província.");
            result.regionName=text(posted,"regiao_internacional",country EQ text(current,"pais") ? currentRegion(current) : "");
            if(len(result.regionName) GT 120 OR reFindNoCase("<\s*/?\s*[a-z!]",result.regionName))invalid("Informe a região/província com até 120 caracteres e sem HTML.");
        }
        return result;
    }
}
