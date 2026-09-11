<!--- Guarded harness only. Optional persistence targets the unique disposable DSN. --->
<cfsetting showdebugoutput="false" requesttimeout="10"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
if (!structKeyExists(REQUEST,"audienceNativeHttpFixtureAuthorized") || !REQUEST.audienceNativeHttpFixtureAuthorized) {
    cfheader(statuscode=403); writeOutput('{"error":"fixture_guard"}'); abort;
}
diagnostic = {"valid"=false,"emptyLabelMatch"=reFind("^[a-zA-Z0-9_.:-]{0,100}$", ""),"frames"=[]};
try {
    diagnosticHttp=getHTTPRequestData();
    diagnosticBody=isBinary(diagnosticHttp.content) ? charsetEncode(diagnosticHttp.content,"UTF-8") : diagnosticHttp.content;
    diagnosticPayload=deserializeJSON(diagnosticBody);
    diagnosticService=createObject("component","services.AudienceMeasurementService").init({"enabled"=true,"secret"="__TEST_TOKEN__"});
    diagnosticBatch=diagnosticService.validateBatch(diagnosticPayload,lCase(CGI.HTTP_HOST),diagnosticHttp.headers);
    diagnostic.valid=true;
    diagnostic["durationJson"]=diagnosticService.flatJson(diagnosticBatch.events[1],"activeMs,visibleMs,maxContinuousMs,ratio");
    if (structKeyExists(URL,"persist") && URL.persist == "1") diagnostic.accepted=diagnosticService.persist(diagnosticBatch);
} catch(any diagnosticFailure) {
    diagnostic["errorType"]=left(diagnosticFailure.type,100);
    // Only synthetic fixture data is used. Never return SQL/parameters/stack variables.
    diagnostic["message"]=left(replace(replace(diagnosticFailure.message,"__TEST_TOKEN__","[redacted]","all"),"__PG_PASSWORD__","[redacted]","all"),200);
    if (structKeyExists(diagnosticFailure,"detail")) diagnostic["detail"]=left(replace(replace(diagnosticFailure.detail,"__TEST_TOKEN__","[redacted]","all"),"__PG_PASSWORD__","[redacted]","all"),400);
    if (structKeyExists(diagnosticFailure,"tagContext")) {
        for (diagnosticFrame in diagnosticFailure.tagContext) {
            arrayAppend(diagnostic.frames,{"template"=listLast(diagnosticFrame.template,"/"),"line"=diagnosticFrame.line});
            if (arrayLen(diagnostic.frames)>=5) break;
        }
    }
}
writeOutput(serializeJSON(diagnostic));
</cfscript>
