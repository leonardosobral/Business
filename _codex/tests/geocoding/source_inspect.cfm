<cfscript>
cfdocument(format="PDF",name="local.doc"){writeOutput("<h1>Corrida do Parque das Flores</h1><p>17/10/2026</p><p>Local da largada: Parque das Flores</p>");}
try {
    cfpdf(action="getinfo",source=doc,name="local.info");writeOutput("PDF INFO " & serializeJSON(info) & chr(10));
    cfpdf(action="extracttext",source=doc,name="local.pdfText",type="string",pages="1");writeOutput("PDF TEXT " & left(pdfText,3000) & chr(10));
}catch(any e){writeOutput("PDF FAILURE " & encodeForHTML(e.message & " " & e.detail) & chr(10));}
store=new services.geocoding.Store();e=store.event(49279);out="";
cfexecute(name="/usr/bin/python3",arguments=["-I",getDirectoryFromPath(getCurrentTemplatePath()) & "../services/geocoding/source_fetcher.py",toBase64(serializeJSON({urls=[e.url_hotsite,e.url_inscricao],robots={}}),"utf-8")],variable="out",timeout=14);
data=deserializeJSON(out);
for(page in data.pages)writeOutput(serializeJSON({url=page.url,title=page.title,text=left(page.text,4000),jsonld=page.jsonld}) & chr(10));
writeOutput("GEO_SOURCE_INSPECT_PASSED");
</cfscript>
