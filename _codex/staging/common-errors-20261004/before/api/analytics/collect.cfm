<cfsetting showdebugoutput="false" requesttimeout="5"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfscript>
try {
    if (CGI.REQUEST_METHOD != "POST") { cfheader(statuscode=405); cfheader(name="Allow",value="POST"); writeOutput('{"error":"method"}'); abort; }
    audienceApplicationConfig=structKeyExists(APPLICATION,"audienceMeasurement") && isStruct(APPLICATION.audienceMeasurement) ? APPLICATION.audienceMeasurement : {};
    audienceControl=createObject("component","services.AudienceRequestControlService").init(audienceApplicationConfig);
    audienceHeaderPreview=getHTTPRequestData(false).headers;
    audienceDecision=audienceControl.evaluate(CGI,audienceHeaderPreview);
    if (!audienceDecision.allowed && audienceDecision.statusCode == 204) {
        cfheader(statuscode=204); abort;
    }
    if (!audienceDecision.allowed) {
        cfheader(statuscode=503); writeOutput('{"error":"disabled"}'); abort;
    }
    lock scope="application" type="exclusive" timeout=1 {
        if (!structKeyExists(APPLICATION,"audienceMeasurementRateLimits") || !isStruct(APPLICATION.audienceMeasurementRateLimits)) APPLICATION.audienceMeasurementRateLimits={};
        audienceRateDecision=audienceControl.consumeRateLimit(APPLICATION.audienceMeasurementRateLimits,audienceDecision,CGI);
    }
    if (!audienceRateDecision.allowed) {
        cfheader(statuscode=429); cfheader(name="Retry-After",value=audienceRateDecision.retryAfter); writeOutput('{"error":"rate_limited"}'); abort;
    }
    audienceSecret=audienceDecision.hostConfig.secret;
    audienceService=createObject("component","services.AudienceMeasurementService").init({"enabled"=true,"secret"=audienceSecret});
    audienceSecret="";
    if (!audienceService.isEnabled()) { cfheader(statuscode=503); writeOutput('{"error":"disabled"}'); abort; }
    if (structKeyExists(CGI,"CONTENT_LENGTH") && isNumeric(CGI.CONTENT_LENGTH) && val(CGI.CONTENT_LENGTH)>65536) { cfheader(statuscode=413); writeOutput('{"error":"size"}'); abort; }
    audienceHttp=getHTTPRequestData();
    // sendBeacon may send text/plain; both forms carry the exact same JSON envelope.
    audienceType=structKeyExists(audienceHttp.headers,"Content-Type") ? lCase(listFirst(audienceHttp.headers["Content-Type"],";")) : "";
    if (!listFind("application/json,text/plain",audienceType)) { cfheader(statuscode=415); writeOutput('{"error":"content_type"}'); abort; }
    audienceBody=isBinary(audienceHttp.content) ? charsetEncode(audienceHttp.content,"UTF-8") : audienceHttp.content;
    if (!isSimpleValue(audienceBody) || len(audienceBody)>65536 || len(charsetDecode(audienceBody,"UTF-8"))>65536) { cfheader(statuscode=413); writeOutput('{"error":"size"}'); abort; }
    try { audiencePayload=deserializeJSON(audienceBody); } catch(any malformedJson) { throw(type="Audience.Invalid",message="Invalid audience request"); }
    if (isNull(audiencePayload) || !isStruct(audiencePayload)) throw(type="Audience.Invalid",message="Invalid audience request");
    audienceBatch=audienceService.validateBatch(audiencePayload,audienceDecision.hostConfig.host,audienceHttp.headers);
    audienceAccepted=audienceService.persist(audienceBatch);
    writeOutput('{"accepted":' & int(audienceAccepted) & '}');
} catch(Audience.Invalid invalidAudienceRequest) {
    cfheader(statuscode=400); writeOutput('{"error":"invalid"}');
} catch(any unavailableAudience) {
    cfheader(statuscode=503); writeOutput('{"error":"unavailable"}');
}
</cfscript>
