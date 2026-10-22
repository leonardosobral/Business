component output=false {
    variables.policy=new services.geocoding.Policy();
    variables.store=new services.geocoding.Store();
    public boolean function nameMatches(required string expected,required string actual) {
        var wanted=[];var matched=0;var token="";var seen={};var actualText=" " & variables.policy.normalize(actual) & " ";
        for(token in listToArray(variables.policy.normalize(expected)," ")) {
            if(len(token) LT 3 OR reFind("^[0-9]+$",token) OR listFind("corrida,caminhada,run,running,trail,maratona,meia,edicao,evento,dos,das,com,para,uma,ano,brasil",token) OR structKeyExists(seen,token))continue;
            seen[token]=true;arrayAppend(wanted,token);if(find(" " & token & " ",actualText))matched++;
        }
        return arrayLen(wanted) GTE 2 AND matched GTE 2 AND matched/arrayLen(wanted) GTE .6;
    }
    private boolean function dateMatches(required struct source,required string value,boolean structured=false) {
        if(!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",variables.policy.text(source,"start_date")))return false;
        if(structured)return left(value,10) EQ source.start_date;
        var y=left(source.start_date,4);var m=val(mid(source.start_date,6,2));var d=val(right(source.start_date,2));
        var months=["janeiro","fevereiro","marco","abril","maio","junho","julho","agosto","setembro","outubro","novembro","dezembro"];
        var abbreviations=["jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez"];
        return reFind("(^|[^0-9])0?" & d & "\s*[/.\-]\s*0?" & m & "\s*[/.\-]\s*" & y & "([^0-9]|$)",value) GT 0
            OR find(source.start_date,value) GT 0 OR reFind("\b0?" & d & "\s+(?:de\s+)?(?:" & months[m] & "|" & abbreviations[m] & ")(?:\s+de)?\s+" & y & "\b",variables.policy.normalize(value)) GT 0;
    }
    private array function eventNodes(required any node,numeric depth=0) {
        var out=[];var item={};var kind="";
        if(depth GT 6)return out;
        if(isArray(node)) {
            for(var i=1;i LTE min(24,arrayLen(node));i++)for(item in eventNodes(node[i],depth+1))arrayAppend(out,item);
        } else if(isStruct(node)) {
            kind=structKeyExists(node,"@type") AND isSimpleValue(node["@type"]) ? node["@type"] : "";
            if(reFindNoCase("(?:^|/)\w*Event$",kind))arrayAppend(out,node);
            if(structKeyExists(node,"@graph"))for(item in eventNodes(node["@graph"],depth+1))arrayAppend(out,item);
            if(structKeyExists(node,"itemListElement"))for(item in eventNodes(node.itemListElement,depth+1))arrayAppend(out,item);
            if(structKeyExists(node,"item"))for(item in eventNodes(node.item,depth+1))arrayAppend(out,item);
        }
        return out;
    }
    private struct function locationQuery(required struct source,required struct document,required string venue,required string address,string city="",string region="",string country="",string method="explicit_start") {
        var localName=left(trim(venue),220);var street=left(trim(address),240);var number="";var found={};var p=variables.policy;
        found=reFindNoCase("^(.+?),\s*([0-9]+[a-z]?)(?:\s+.+)?$",street,1,true);
        if(arrayLen(found.pos) LT 3 OR found.pos[3] EQ 0)found=reFindNoCase("^(.+?)[,\s]+([0-9]+[a-z]?)\s*$",street,1,true);
        if(arrayLen(found.pos) GTE 3 AND found.pos[3] GT 0){number=mid(street,found.pos[3],found.len[3]);street=trim(mid(street,found.pos[2],found.len[2]));}
        var localText=len(localName) ? localName : trim(address);
        if(len(localText) LT 5 OR reFind("\b(kit|kits|a definir|em breve|a confirmar|sujeito a alteracao|nao definido)\b",p.normalize(localText)))return {};
        var geography=(!len(city) OR p.normalize(city) EQ p.normalize(source.cidade)) AND (!len(region) OR p.normalize(region) EQ p.normalize(source.estado))
            AND (!len(country) OR p.normalize(country) EQ p.normalize(source.pais) OR (lCase(source.pais) EQ "br" AND p.normalize(country) EQ "brasil"));
        var evidence={url=document.url,sha256=p.text(document,"sha256"),method=method,excerpt=left(localText & (len(venue) AND len(address) ? " — " & address : ""),700),event_date=source.start_date};
        return {kind="specific",local=localText,venue=localName,street=street,housenumber=number,source="official_source",evidence=evidence,
            text=left(localText & (len(venue) AND len(address) ? ", " & address : "") & ", " & source.cidade & ", " & source.estado & ", " & source.pais,500),
            autoEligible=geography,reason=geography ? "specific_location" : "geographic_conflict"};
    }
    public struct function parseDocument(required struct source,required struct document) {
        var out={queries=[],diagnostics=[]};var p=variables.policy;var nodes=[];var event={};var location={};var address={};var query={};var text=p.text(document,"text");
        if(p.text(document,"kind") EQ "pdf" AND structKeyExists(document,"pdf")) {
            try {
                var pdfData=binaryDecode(document.pdf,"base64");var pdfInfo={};var pdfText="";
                cfpdf(action="getinfo",source=pdfData,name="local.pdfInfo");
                cfpdf(action="extracttext",source=pdfData,name="local.pdfText",type="string",pages="1-" & min(12,pdfInfo.totalPages));
                text=left(pdfText,120000);
                text=reReplaceNoCase(text,"\s+(local da largada|local de largada|local da prova|local do evento|endereço da prova|endereco da prova|largada e chegada|largada)\s*:",chr(10) & "\1:","all");
            } catch(any unavailablePdf){out.diagnostics=["pdf_text_unavailable"];return out;}
        }
        if(structKeyExists(document,"jsonld") AND isArray(document.jsonld))for(var block in document.jsonld)for(event in eventNodes(block))arrayAppend(nodes,event);
        for(event in nodes) {
            if(!nameMatches(p.text(source,"nome_evento"),p.text(event,"name")) OR !dateMatches(source,p.text(event,"startDate"),true))continue;
            if(!structKeyExists(event,"location") OR !isStruct(event.location))continue;
            location=event.location;address=structKeyExists(location,"address") AND isStruct(location.address) ? location.address : {};
            var country=p.text(address,"addressCountry");if(structKeyExists(address,"addressCountry") AND isStruct(address.addressCountry))country=p.text(address.addressCountry,"name");
            query=locationQuery(source,document,p.text(location,"name"),p.text(address,"streetAddress"),p.text(address,"addressLocality"),p.text(address,"addressRegion"),country,"event_jsonld");
            if(!structIsEmpty(query))arrayAppend(out.queries,query);
        }
        // Text is accepted only when the primary document identifies this race and date.
        // JSON-LD of another edition cannot be rescued by dates in a site footer.
        var identityConfirmed=arrayLen(out.queries) GT 0;
        if(!identityConfirmed AND (arrayLen(nodes) OR !nameMatches(p.text(source,"nome_evento"),p.text(document,"title") & " " & left(text,2500)) OR !dateMatches(source,left(text,12000)))) {
            arrayAppend(out.diagnostics,"edition_not_confirmed");return out;
        }
        var lines=listToArray(left(text,40000),chr(10));var previous="";var line="";var place="";
        for(var i=1;i LTE arrayLen(lines);i++) {
            line=trim(lines[i]);
            if(p.normalize(line) EQ "local" AND i+3 LTE arrayLen(lines) AND !reFind("\b(kit|kits|retirada|entrega)\b",p.normalize(previous))) {
                var cityLine=p.normalize(lines[i+3]);
                if(find(p.normalize(source.cidade),cityLine) AND find(p.normalize(source.estado),cityLine)) {
                    query=locationQuery(source,document,trim(lines[i+1]),trim(lines[i+2]),source.cidade,source.estado,source.pais,"official_location_block");
                    if(!structIsEmpty(query) AND len(query.housenumber))arrayAppend(out.queries,query);
                }
            }
            if(reFindNoCase("^\s*(?:local da largada|local de largada|local da prova|local do evento|local|endereço da prova|endereco da prova|largada e chegada|largada)\s*[:\-]",line)) {
                var explicit=reFindNoCase("^(?:local da largada|local de largada|local da prova|endereço da prova|endereco da prova|largada e chegada|largada)\s*[:\-]",line) GT 0;
                if(!explicit AND reFind("\b(kit|kits|retirada|entrega)\b",p.normalize(previous))){previous=right(previous & " " & line,600);continue;}
                place=trim(reReplaceNoCase(line,"^\s*[^:\-]+[:\-]\s*",""));
                if(!len(place) AND i LT arrayLen(lines))place=trim(lines[i+1]);
                if(reFind("\b(a definir|em breve|a confirmar|nao definido|nao confirmado|sujeito a alteracao)\b",p.normalize(place))) {
                    if(!arrayFind(out.diagnostics,"location_undefined"))arrayAppend(out.diagnostics,"location_undefined");
                    previous=right(previous & " " & line,600);continue;
                }
                if(!reFind("^[0-9]{1,2}[:h]",place)) {
                    query=locationQuery(source,document,reFindNoCase("^(?:rua|r\.|avenida|av\.|rodovia|estrada|travessa|alameda)\b",place) ? "" : place,reFindNoCase("^(?:rua|r\.|avenida|av\.|rodovia|estrada|travessa|alameda)\b",place) ? place : "");
                    if(!structIsEmpty(query))arrayAppend(out.queries,query);
                }
            }
            previous=right(previous & " " & line,600);
        }
        if(!arrayLen(out.queries))arrayAppend(out.diagnostics,"start_location_not_explicit");
        return out;
    }
    public struct function research(required struct source,required numeric deadline) {
        var out={version=2,evidence=[],pages=[],queries=[],diagnostics=[],documents=0,checked_at=dateTimeFormat(now(),"yyyy-mm-dd HH:nn:ss")};
        var urls=[];var key="";var url="";var p=variables.policy;
        for(key in ["url_hotsite","url_inscricao"]) {
            url=p.text(source,key);if(len(url) AND !arrayFind(urls,url))arrayAppend(urls,url);
        }
        if(!arrayLen(urls)){out.diagnostics=["no_official_source"];return out;}
        var cacheKey="evidence|parser-2|" & p.sourceHash(source);var cached=variables.store.resourceGet(cacheKey);
        if(cached.found){cached.value.cached=true;return cached.value;}
        if(getTickCount()+16000 GT deadline){out.diagnostics=["source_time_budget"];out.deferred=true;return out;}
        var robots={};var host="";
        for(url in urls) {
            host=lCase(reReplaceNoCase(url,"^https?://([^/:]+).*$","\1"));
            cached=variables.store.resourceGet("robots|" & host);if(cached.found)robots[host]=p.text(cached.value,"text");
        }
        var payload=toBase64(serializeJSON({urls=urls,robots=robots}),"utf-8");var output="";var errors="";var response={};var parsed={};var doc={};var pdfData="";var pdfText="";var pdfInfo={};
        try {
            cfexecute(name="/usr/bin/python3",arguments=["-I",getDirectoryFromPath(getCurrentTemplatePath()) & "source_fetcher.py",payload],variable="output",errorVariable="errors",timeout=14);
            response=deserializeJSON(output);
            if(!isStruct(response) OR !structKeyExists(response,"pages") OR !isArray(response.pages))throw(type="Geocoding.Source",message="invalid_source_response");
            out.diagnostics=response.diagnostics;out.documents=arrayLen(response.pages);
            for(host in response.robots)variables.store.resourcePut("robots|" & host,{text=left(response.robots[host],100000)},1);
            for(doc in response.pages) {
                arrayAppend(out.pages,{url=doc.url,kind=doc.kind,sha256=doc.sha256});
                parsed=parseDocument(source,doc);
                for(var item in parsed.queries){arrayAppend(out.queries,item);arrayAppend(out.evidence,item.evidence);}
                for(var diagnostic in parsed.diagnostics)if(!arrayFind(out.diagnostics,diagnostic))arrayAppend(out.diagnostics,diagnostic);
            }
        }catch(any unavailable){arrayAppend(out.diagnostics,"source_unavailable");}
        out.temporary=false;
        for(var code in out.diagnostics)if(reFind("^(source_unavailable|source_time_budget|source_http_5[0-9][0-9])$",code))out.temporary=true;
        if(!out.temporary)variables.store.resourcePut(cacheKey,out,arrayLen(out.queries) ? 7 : 1);return out;
    }
}
