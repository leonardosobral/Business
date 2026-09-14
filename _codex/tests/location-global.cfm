<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') { cfheader(statuscode=404); abort; }
function check(required boolean condition, required string label) {
    if (!arguments.condition) throw(type='LocationGlobalTest',message=arguments.label);
    writeOutput('PASS: ' & arguments.label & chr(10));
}
function resetLocation() {
    for (var key in ['pais','uf','estado','cidade','location_source']) structDelete(COOKIE,key);
    APPLICATION.locationIpCache={};
    APPLICATION.locationIpCacheLastPruneAt=now();
    APPLICATION.location={providerUrl='',providers=[{name='must-not-be-called',url=''}],timeoutSeconds=1,cacheTtlHours=12};
}
testIp='192.0.2.44';
servlet=getPageContext().getHttpServletRequest().getOriginalRequest();
servlet.setRemoteAddr(testIp);servlet.setHeader('CF-Connecting-IP',testIp);
resetLocation();
resolver=new services.LocationResolver();
beforeCookies=serializeJSON(COOKIE);
location=resolver.resolveAvailable();
check(location.uf=='BR' && location.isFallback,'cold request stays unknown');
check(arrayLen(location.debug.providerAttempts)==0,'cold global request never attempts an external provider');
check(structIsEmpty(APPLICATION.locationIpCache),'cold read does not write negative cache');
check(serializeJSON(COOKIE)==beforeCookies,'global read never emits location cookies');

COOKIE.pais='BR';COOKIE.uf='SC';COOKIE.estado='Santa Catarina';COOKIE.cidade='Florianópolis';COOKIE.location_source='primary';
location=resolver.resolveAvailable();
check(location.uf=='SC' && location.debug.cookieHit,'available Brazilian cookie supplies the global location');
REQUEST.LocationContext=location;
audience=new services.AudienceMeasurementService().init({enabled=true,secret=repeatString('x',64)});
context=audience.buildContext({template='/evento/',qEvento=queryNew('id_evento,estado,tag','integer,varchar,varchar',[[12,'AC','prova-acre']])},REQUEST,{HTTP_HOST='roadrunners.run'});
check(context.visitorUf=='SC' && context.contextUf=='AC' && context.marketUf=='AC','event audience receives visitor SC without confusing event/market AC');

resetLocation();
APPLICATION.locationIpCache[testIp]={data={pais='BR',uf='SP',estado='São Paulo',cidade='',source='primary',isFallback=false},expiresAt=dateAdd('h',1,now())};
cacheBefore=serializeJSON(APPLICATION.locationIpCache);
location=resolver.resolveAvailable();
check(location.uf=='SP' && location.debug.cacheHit,'server cache supplies location without a cookie');
check(serializeJSON(APPLICATION.locationIpCache)==cacheBefore,'cache reads do not renew expiry or mutate the source');
APPLICATION.locationIpCache[testIp].expiresAt=dateAdd('s',-1,now());
location=resolver.resolveAvailable();
check(location.uf=='BR' && !location.debug.cacheHit && arrayLen(location.debug.providerAttempts)==0,'expired cache is unknown without a provider retry');
resetLocation();
COOKIE.pais='US';COOKIE.uf='BR';COOKIE.estado='California';COOKIE.location_source='primary';
location=resolver.resolveAvailable();
check(location.pais=='US' && location.uf=='BR','foreign location is not turned into a Brazilian state');
REQUEST.LocationContext=location;
context=audience.buildContext({template='/evento/'},REQUEST,{HTTP_HOST='roadrunners.run'});
check(context.visitorUf=='','foreign or fallback sentinel is not an identified audience UF');

// The extracted production request-start method executes with side-effecting
// authentication/i18n dependencies replaced only at the application boundary.
app=new RequestFixture();
REQUEST.testOrder=[];
structDelete(REQUEST,'LocationContext');
COOKIE.pais='BR';COOKIE.uf='SC';COOKIE.estado='Santa Catarina';
app.onRequestStart('/evento/index.cfm');
check(structKeyExists(REQUEST,'LocationContext') && REQUEST.LocationContext.uf=='SC','request-start populates global location for an event request');
check(REQUEST.testOrder[arrayLen(REQUEST.testOrder)]=='beta','all existing access gates still execute');
REQUEST.testOrder=[];structDelete(REQUEST,'LocationContext');
app.onRequestStart('/api/analytics/collect.cfm');
check(structKeyExists(REQUEST,'LocationContext'),'API request also has the cheap global context');
resetLocation();REQUEST.testOrder=[];structDelete(REQUEST,'LocationContext');
app.onRequestStart('/circuito/index.cfm');
check(!structKeyExists(REQUEST,'LocationContext'),'cold circuit request still reaches its existing full resolver');
writeOutput('LOCATION GLOBAL CONTRACT PASSED' & chr(10));
</cfscript>
