component output=false {
    variables.p=new services.geocoding.Policy();variables.store=new services.geocoding.Store();
    private struct function readableDocuments(required struct value){for(var doc in value.documents)doc.text=variables.p.readableText(doc.text);return value;}
    public struct function read(required struct source,required numeric deadline) {
        var out={documents=[],diagnostics=[],temporary=false};var urls=[];
        for(var key in ["url_regulamento","url_hotsite","url_inscricao"])if(len(variables.p.text(source,key)) AND !arrayFind(urls,source[key]))arrayAppend(urls,source[key]);
        if(!arrayLen(urls)){out.diagnostics=["no_official_source"];return out;}
        var cacheKey="ai-documents-v1|" & serializeJSON(urls);var cached=variables.store.resourceGet(cacheKey);
        if(cached.found)return readableDocuments(cached.value);
        if(getTickCount()+16000 GT deadline)return {documents=[],diagnostics=["source_time_budget"],deferred=true};
        var robots={};var host="";
        for(var url in urls){host=lCase(reReplaceNoCase(url,"^https?://([^/:]+).*$","\1"));cached=variables.store.resourceGet("robots|" & host);if(cached.found)robots[host]=variables.p.text(cached.value,"text");}
        var output="";var errors="";
        try {
            cfexecute(name="/usr/bin/python3",arguments=["-I",getDirectoryFromPath(getCurrentTemplatePath()) & "source_fetcher.py",toBase64(serializeJSON({urls=urls,robots=robots}),"utf-8")],variable="output",errorVariable="errors",timeout=14);
            var response=deserializeJSON(output);out.diagnostics=response.diagnostics;
            for(host in response.robots)variables.store.resourcePut("robots|" & host,{text=left(response.robots[host],100000)},1);
            for(var doc in response.pages) {
                var text=variables.p.text(doc,"text");
                if(doc.kind EQ "pdf") {
                    try {
                        var info={};var extracted="";var pdf=binaryDecode(doc.pdf,"base64");
                        cfpdf(action="getinfo",source=pdf,name="local.info");
                        cfpdf(action="extracttext",source=pdf,name="local.extracted",type="string",pages="1-" & min(12,info.totalPages));text=extracted;
                    }catch(any noText){arrayAppend(out.diagnostics,"pdf_text_unavailable");continue;}
                }
                // JSON-LD is inert evidence too; its literal representation cannot instruct the client.
                if(structKeyExists(doc,"jsonld") AND arrayLen(doc.jsonld))text &= chr(10) & serializeJSON(doc.jsonld);
                text=variables.p.readableText(text);
                if(len(trim(text)))arrayAppend(out.documents,{url=doc.url,sha256=doc.sha256,kind=doc.kind,title=variables.p.text(doc,"title"),text=left(text,30000)});
            }
        }catch(any unavailable){arrayAppend(out.diagnostics,"source_unavailable");}
        for(var code in out.diagnostics)if(reFind("^(source_unavailable|source_time_budget|source_http_5[0-9][0-9])$",code))out.temporary=true;
        if(!out.temporary)variables.store.resourcePut(cacheKey,out,1);
        return out;
    }
}
