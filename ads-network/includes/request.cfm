<cfscript>
function networkText(required string key) {
    if(!structKeyExists(form,key) OR !isSimpleValue(form[key])) return '';
    return trim(form[key] & '');
}
function networkDeny(numeric code=403) {cfheader(statuscode=code);cfcontent(type='application/json',reset=true);writeOutput('{"status":"unavailable"}');abort;}
networkHeaders=getHTTPRequestData().headers;
networkOrigin=structKeyExists(networkHeaders,'Origin') ? trim(networkHeaders.Origin & '') : '';
if(!reFind('^https://[a-z0-9.-]+$',networkOrigin) OR len(networkOrigin)>255) networkDeny();
networkUa=cgi.http_user_agent ?: '';
if(!len(networkUa) OR reFindNoCase('bot|crawler|spider|slurp|headlesschrome|lighthouse|pagespeed|curl/|wget/|python-|link.?preview|facebookexternalhit|safelinks|proofpoint|urlscan|virustotal|firefox/x',networkUa)) networkDeny();
for(networkHeader in ['Sec-Purpose','Purpose','X-Purpose','X-Moz']) {
    if(structKeyExists(networkHeaders,networkHeader) AND reFindNoCase('prefetch|prerender|preview',networkHeaders[networkHeader])) networkDeny();
}
// A bounded short-lived rate limit; forwarded IP headers are never trusted.
networkRateKey=hash(cgi.remote_addr & ':' & networkOrigin,'SHA-256');
networkMinute=int(getTickCount()/60000);
networkLimited=false;
lock scope='application' type='exclusive' timeout=2 {
    if(!structKeyExists(application,'networkRates') OR application.networkRateMinute!=networkMinute) {application.networkRates={};application.networkRateMinute=networkMinute;}
    if(!structKeyExists(application.networkRates,networkRateKey)) {
        if(structCount(application.networkRates)>=10000) networkLimited=true;
        else application.networkRates[networkRateKey]=0;
    }
    if(!networkLimited) {application.networkRates[networkRateKey]++;networkLimited=application.networkRates[networkRateKey]>600;}
}
if(networkLimited) {cfheader(name='Retry-After',value='60');networkDeny(429);}
networkParams={origin={value=networkOrigin,cfsqltype='cf_sql_varchar'}};
if(listLast(getBaseTemplatePath(),'/')=='serve.cfm') {
    networkSite=networkText('site');networkSpot=networkText('spot');
    if(!reFind('^[a-z][a-z0-9-]{1,49}$',networkSite) OR !reFind('^[a-z][a-z0-9-]{1,49}$',networkSpot)) networkDeny(400);
    networkParams.site={value=networkSite,cfsqltype='cf_sql_varchar'};networkParams.spot={value=networkSpot,cfsqltype='cf_sql_varchar'};
    networkAllowed=queryExecute("SELECT 1 FROM ads.publisher_sites si JOIN ads.publisher_spots sp USING(site_id) WHERE si.site_key=:site AND sp.spot_key=:spot AND si.status='ACTIVE' AND sp.status='ACTIVE' AND :origin=ANY(si.origins)",networkParams,{datasource='runnerhub',timeout=5});
} else {
    networkDelivery=networkText('delivery');networkToken=networkText('token');
    if(!reFind('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',networkDelivery) OR !reFind('^[0-9a-f]{64}$',networkToken)) networkDeny(400);
    networkParams.delivery={value=networkDelivery,cfsqltype='cf_sql_varchar'};networkParams.token={value=networkToken,cfsqltype='cf_sql_varchar'};
    // The canonical wrapper validates the token and exact origin before any write.
    // delivery_payloads is deliberately not readable by the application role.
    networkParams.event={value=listLast(getBaseTemplatePath(),'/')=='viewable.cfm' ? 'VIEWABLE_IMPRESSION' : 'CLICK',cfsqltype='cf_sql_varchar'};
    networkResult=queryExecute("SELECT CAST(ads.publisher_track(CAST(:delivery AS uuid),:token,:origin,:event) AS text) AS payload",networkParams,{datasource='runnerhub',timeout=8});
    networkAllowed={recordCount=networkResult.recordCount};
}
if(!networkAllowed.recordCount) networkDeny();
cfheader(name='Access-Control-Allow-Origin',value=networkOrigin);
cfheader(name='Vary',value='Origin');
cfcontent(type='application/json',reset=true);
</cfscript>
