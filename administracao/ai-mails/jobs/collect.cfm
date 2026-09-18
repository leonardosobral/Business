<cfinclude template="auth.cfm"/>
<cfscript>
try {writeOutput(serializeJSON(mailWire(mailCollect())));}
catch(any error) {cfheader(statuscode=503);writeOutput(serializeJSON(mailWire({success=false,status="error",errors=1,message=mailSafeError(error)})));}
</cfscript>
