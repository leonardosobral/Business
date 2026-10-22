<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false" requesttimeout="60">
<cfscript>
function geoResponse(required numeric code,required struct payload){cfheader(statuscode=code);cfheader(name="Cache-Control",value="no-store");cfcontent(type="application/json; charset=utf-8",reset=true);writeOutput(serializeJSON(payload));abort;}
if(CGI.request_method NEQ "POST"){cfheader(name="Allow",value="POST");geoResponse(405,{success=false,status="method_not_allowed",message="Use POST com assinatura interna."});}
</cfscript>
<cfinclude template="../../services/geocoding/config.cfm">
<cfscript>
try {
    req=getHttpRequestData();body=toString(req.content);
    auth=new services.geocoding.JobSecurity().verify(CGI.request_method,body,req.headers,VARIABLES.geoConfig.secret);
    if(!auth.allowed)geoResponse(auth.http,{success=false,status=auth.status});
    if(!isJSON(body))geoResponse(400,{success=false,status="invalid_request"});
    input=deserializeJSON(body);
    if(!isStruct(input))geoResponse(400,{success=false,status="invalid_request"});
    for(key in input)if(!listFindNoCase("limit,dryRun",key))geoResponse(400,{success=false,status="invalid_request"});
    batchLimit=structKeyExists(input,"limit") ? input.limit : 5;
    if(!isNumeric(batchLimit) OR val(batchLimit) NEQ int(val(batchLimit)) OR val(batchLimit) LT 1 OR val(batchLimit) GT 5)geoResponse(400,{success=false,status="invalid_limit"});
    if(structKeyExists(input,"dryRun") AND serializeJSON(input.dryRun) NEQ "true" AND serializeJSON(input.dryRun) NEQ "false")geoResponse(400,{success=false,status="invalid_request"});
    if(structKeyExists(input,"dryRun") AND input.dryRun){geoStore=new services.geocoding.Store();geoResponse(200,{success=true,status="dry_run",stats=geoStore.isReady() ? geoStore.overview() : {},provider_calls=0});}
    worker=new services.geocoding.LocationWorker(VARIABLES.geoConfig);response=worker.run(batchLimit);
    geoResponse(worker.responseStatus(response),response);
}catch(any failed){geoResponse(500,{success=false,status="execution_error",message="A geolocalização não pôde ser executada. A fila foi preservada."});}
</cfscript>
