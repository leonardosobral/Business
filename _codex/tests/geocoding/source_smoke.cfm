<cfscript>
store=new services.geocoding.Store();policy=new services.geocoding.Policy();reader=new services.geocoding.Sources();results=[];
for(id in [49279,49282]) {
    event=store.event(id);before=policy.text(event,"coordenadas");
    research=reader.research(policy.snapshot(event),getTickCount()+30000);
    if(policy.text(store.event(id),"coordenadas") NEQ before)throw(type="Test.Failed",message="Source research changed event coordinates");
    arrayAppend(results,{id_evento=id,documents=research.documents,evidence=research.evidence,diagnostics=research.diagnostics,pages=research.pages,queries=research.queries,cached=structKeyExists(research,"cached")});
}
writeOutput(serializeJSON(results) & chr(10));writeOutput("GEO_SOURCE_SMOKE_PASSED");
</cfscript>
