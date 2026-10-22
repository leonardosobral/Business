<cfscript>
// Read-only scope: the five city suggestions from the first geocoding batch.
store=new services.geocoding.Store();policy=new services.geocoding.Policy();items=[];
for(id in [49278,49279,49280,49281,49282]){
    row=store.event(id);item={};
    for(key in row){
        if(listFindNoCase("id_evento,nome_evento,cidade,estado,pais,endereco,data_inicial,data_final,coordenadas,site,site_oficial,site_evento,url,url_evento,url_inscricao,link_inscricao,link_evento,slug,origem,fonte",key))item[key]=policy.text(row,key);
    }
    item.public_url_fields=[];
    for(key in row)if(reFindNoCase("(url|link|site)",key) AND isSimpleValue(row[key]) AND reFindNoCase("^https?://",row[key]))arrayAppend(item.public_url_fields,{field=key,value=left(row[key],700)});
    raw=policy.text(row,"descricao_original");if(!len(raw))raw=policy.text(row,"descricao");
    plain=reReplaceNoCase(raw,"</?(p|div|br|li|h[1-6])\b[^>]*>",chr(10),"all");plain=reReplace(plain,"<[^>]*>"," ","all");
    item.description_excerpt=left(trim(plain),1100);
    item.location_evidence=[];
    for(line in listToArray(plain,chr(10)))if(reFindNoCase("(largada|local|avenida|praça|praca|rua |parque|endereço|endereco|concentra)",line))arrayAppend(item.location_evidence,left(trim(line),700));
    item.description_urls=reMatchNoCase("https?://[^\s<>""']+",raw);
    arrayAppend(items,item);
}
writeOutput(serializeJSON(items) & chr(10));writeOutput("GEO_RESEARCH_FIVE_PASSED");
</cfscript>
