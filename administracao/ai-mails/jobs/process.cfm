<cfinclude template="auth.cfm"/>
<cfinclude template="../includes/ai.cfm"/>
<cfscript>
try {
    started=getTickCount();processed=0;result={};
    for(batchIndex=1;batchIndex<=2;batchIndex++) {
        result=mailProcessOne();processed+=result.processed;
        if(result.status!="ok" || getTickCount()-started>30000) break;
    }
    result.processed=processed;writeOutput(serializeJSON(mailWire(result)));
} catch(any error) {cfheader(statuscode=503);writeOutput(serializeJSON(mailWire({success=false,status="error",errors=1,message=mailSafeError(error)})));}
</cfscript>
