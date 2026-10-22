component output=false {
    variables.states={AC="Acre",AL="Alagoas",AP="Amapá",AM="Amazonas",BA="Bahia",CE="Ceará",DF="Distrito Federal",ES="Espírito Santo",GO="Goiás",MA="Maranhão",MT="Mato Grosso",MS="Mato Grosso do Sul",MG="Minas Gerais",PA="Pará",PB="Paraíba",PR="Paraná",PE="Pernambuco",PI="Piauí",RJ="Rio de Janeiro",RN="Rio Grande do Norte",RS="Rio Grande do Sul",RO="Rondônia",RR="Roraima",SC="Santa Catarina",SP="São Paulo",SE="Sergipe",TO="Tocantins"};
    variables.countries={};
    private string function fold(required string value){var s=createObject("java","java.text.Normalizer").normalize(lCase(trim(value)),createObject("java","java.text.Normalizer$Form").valueOf("NFD"));s=createObject("java","java.lang.String").init(s).replaceAll("\p{M}+","");return trim(reReplace(s,"[^a-z0-9]+"," ","all"));}
    private void function ensureCountries(){
        if(!structIsEmpty(variables.countries))return;
        var locale=createObject("java","java.util.Locale");
        for(var code in locale.getISOCountries()){
            variables.countries[lCase(code)]=code;
            var country=locale.forLanguageTag("und-" & code);
            for(var language in ["pt-BR","en","es"])variables.countries[fold(country.getDisplayCountry(locale.forLanguageTag(language)))]=code;
        }
        for(var alias in ["eua","usa","estados unidos da america","united states of america"])variables.countries[alias]="US";
        variables.countries["uk"]="GB";variables.countries["reino unido"]="GB";
    }
    public string function country(required string value){ensureCountries();var key=fold(value);return structKeyExists(variables.countries,key) ? variables.countries[key] : "";}
    public string function state(required string value){var key=fold(reReplaceNoCase(trim(value),"^BR[-_]",""));if(structKeyExists(variables.states,key))return uCase(key);for(var code in variables.states)if(key EQ fold(variables.states[code]))return code;return uCase(trim(value));}
    private boolean function explicitCode(required string text,required string code,required string labels){
        // Codes need a geographic separator or label, not an ordinary preposition such as "de".
        return reFind("(?:^|[,/(])\s*" & code & "(?=$|[\s.,/);-])",text) GT 0 OR reFindNoCase("\b(?:" & labels & ")\s*[:=-]\s*" & code & "\b",text) GT 0;
    }
    public boolean function hasState(required string text,required string value){
        var code=state(value);if(!structKeyExists(variables.states,code))return false;
        var s=" " & fold(text) & " ";var names=[];
        for(var key in variables.states)arrayAppend(names,{name=fold(variables.states[key]),code=key});
        arraySort(names,function(a,b){return len(b.name)-len(a.name);});
        for(var item in names){
            if(item.code EQ "PA" AND !reFind("Pará|PARÁ|pará",text))continue;
            s=replace(s," " & item.name & " "," __uf_" & item.code & "__ ","all");
        }
        return find("__uf_" & code & "__",s) GT 0 OR explicitCode(text,code,"uf|estado|state");
    }
    public boolean function hasCountry(required string text,required string value){
        ensureCountries();var code=country(value);if(!len(code))return false;var s=" " & fold(text) & " ";var names=[];
        for(var alias in variables.countries)if(len(alias) GT 3)arrayAppend(names,{name=alias,code=variables.countries[alias]});
        arraySort(names,function(a,b){return len(b.name)-len(a.name);});
        for(var item in names)s=replace(s," " & item.name & " "," __country_" & item.code & "__ ","all");
        if(find("__country_" & code & "__",s))return true;
        if(explicitCode(text,code,"país|pais|country"))return true;
        for(var shortName in ["EUA","USA","UK"])if(country(shortName) EQ code AND explicitCode(text,shortName,"país|pais|country"))return true;
        return false;
    }
    public string function evidenceText(required string value){
        var s=" " & fold(value) & " ";
        // Longer names first: Mato Grosso do Sul must not become MT do Sul.
        var names=[];for(var code in variables.states)arrayAppend(names,{name=fold(variables.states[code]),code=lCase(code)});
        arraySort(names,function(a,b){return len(b.name)-len(a.name);});
        for(var item in names)s=replace(s," " & item.name & " "," " & item.code & " ","all");
        return trim(s);
    }
}
