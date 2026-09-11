<!--- Explicit local-process opt-in; never set this in a web-server environment. --->
<cfset offlineBoundaryEnvironment=createObject("java","java.lang.System").getenv()/>
<cfif NOT offlineBoundaryEnvironment.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS")
    OR offlineBoundaryEnvironment.get("RUNNERHUB_OFFLINE_CFML_TESTS") NEQ "1">
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<!--- Native offline integration: box execute _codex/tests/business-auth-boundary.cfm.
      Set JOSE4J_TEST_JAR for Lucee. Runs the production request boundary/callback
      with only request, SQL, redirect, logging and session-engine adapters.
      No application lifecycle, network request, datasource or real account is used. --->
<cfscript>
boundaryRoot = expandPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../../");
boundaryScratch = getTempDirectory() & "business-auth-boundary-" & createUUID();
directoryCreate(boundaryScratch);
boundaryChecks = 0;
boundaryFailures = [];
boundarySequence = 0;
boundaryJavaPaths = [];
boundaryEnv = createObject("java", "java.lang.System").getenv();
if (boundaryEnv.containsKey("JOSE4J_TEST_JAR")) arrayAppend(boundaryJavaPaths, boundaryEnv.get("JOSE4J_TEST_JAR"));
boundaryMappings = duplicate(getApplicationSettings().mappings);
boundaryMappings["/authBoundaryRoot"] = boundaryRoot;
application action="update" mappings=boundaryMappings javaSettings={loadPaths=boundaryJavaPaths,loadColdFusionClassPath=true};
if (boundaryEnv.containsKey("BUSINESS_AUTH_TEST_PORT")) {
    application action="update" datasources={remember_test={class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",
        connectionString="jdbc:postgresql://127.0.0.1:" & boundaryEnv.get("BUSINESS_AUTH_TEST_PORT") & "/business_auth_test",
        username="business_auth_test",password=""}};
}

function boundaryCheck(required boolean condition, required string label) {
    variables.boundaryChecks++;
    if (!arguments.condition) arrayAppend(variables.boundaryFailures, arguments.label);
}
function boundaryRedirect(required string destination) {
    variables.boundaryResult.redirect = arguments.destination;
    throw(type="BoundaryRedirect",message="Request terminated by redirect adapter");
}
function boundaryRotate() { variables.boundaryResult.rotations++; }
function boundaryInvalidate() { variables.boundaryResult.invalidations++; }
function boundaryHeader(required string name, required string value) {
    variables.boundaryResult.headers[arguments.name] = arguments.value;
    if (arguments.name=="Set-Cookie") arrayAppend(variables.boundaryResult.cookies,arguments.value);
}
function boundaryLog(required any failure) {
    variables.boundaryResult.error=arguments.failure.type & ": " & arguments.failure.message & " " & arguments.failure.detail;
}
function boundaryQuery(required string name, required string sql) {
    arrayAppend(variables.boundaryResult.queries, {name=arguments.name,sql=arguments.sql});
    switch (arguments.name) {
        case "qPerfil": return queryNew("id,name,email,is_admin,is_dev,is_partner", "integer,varchar,varchar,bit,bit,bit",
            [{id=42,name="Stored Verified Name",email="verified@example.test",is_admin=false,is_dev=false,is_partner=false}]);
        case "qBusinessGoogleSignInState": return queryNew("has_business_access,has_pending_registration,has_legacy_bi_access",
            "varchar,varchar,varchar", [{has_business_access=variables.boundaryAccess,
                has_pending_registration=variables.boundaryPending,has_legacy_bi_access=variables.boundaryLegacyBi}]);
        case "":
            if (!reFindNoCase("INSERT\s+INTO\s+tb_(usuarios|log)\b",arguments.sql))
                throw(type="BoundaryHarness",message="Unexpected unnamed SQL boundary");
            return queryNew("unused");
        default: throw(type="BoundaryHarness",message="Unexpected query: " & arguments.name);
    }
}

// Preserve CFML expressions/branches inside SQL, substituting the database I/O
// only. A removed verification gate therefore reaches the observable SQL sink.
function boundaryAdapt(required string source) {
    var adapted = arguments.source;
    for (var scopeName in ["SESSION","REQUEST","FORM","URL","CGI","COOKIE"]) {
        adapted = reReplaceNoCase(adapted,"\b" & scopeName & "(?=\s*[.,)])","VARIABLES.boundary" & scopeName,"all");
        adapted = reReplaceNoCase(adapted,"\b" & scopeName & "(?=\s*\[)","VARIABLES.boundary" & scopeName,"all");
    }
    adapted = replace(adapted,'"services.','"authBoundaryRoot.services.',"all");
    adapted = replace(adapted,'"authBoundaryRoot.services.BusinessRememberDevice").init()',
        '"authBoundaryRoot.services.BusinessRememberDevice").init("remember_test")',"all");
    adapted = replaceNoCase(adapted,'scope="session"','name="BusinessRememberOfflineSession"',"all");
    for (var helper in ["business_remember_issue","business_remember_request","business_remember_revoke"]) {
        adapted = reReplace(adapted,'template="[^"]*' & helper & '\.cfm"',
            'template="' & variables.boundaryScratch & '/' & helper & '.cfm"',"all");
    }
    adapted = replaceNoCase(adapted,"sessionRotate()","boundaryRotate()","all");
    adapted = replaceNoCase(adapted,"sessionInvalidate()","boundaryInvalidate()","all");
    for (var queryTag in reMatchNoCase("(?s)<cfquery\b[^>]*>.*?</cfquery>",adapted)) {
        var opening = reMatchNoCase("<cfquery\b[^>]*>",queryTag)[1];
        var nameMatch = reFindNoCase('name="([^"]+)"',opening,1,true);
        var queryName = arrayLen(nameMatch.pos) > 1 ? mid(opening,nameMatch.pos[2],nameMatch.len[2]) : "";
        var body = mid(queryTag,len(opening)+1,len(queryTag)-len(opening)-len("</cfquery>"));
        for (var paramTag in reMatchNoCase("<cfqueryparam\b[^>]*>",body)) {
            var valueMatch = reFindNoCase('value="([^"]*)"',paramTag,1,true);
            if (arrayLen(valueMatch.pos) < 2) throw(type="BoundaryHarness",message="Query parameter without value");
            var value = mid(paramTag,valueMatch.pos[2],valueMatch.len[2]);
            body = replace(body,paramTag,"<cfoutput>" & value & "</cfoutput>","one");
        }
        adapted = replace(adapted,queryTag,'<cfsavecontent variable="VARIABLES.boundarySql">' & body
            & '</cfsavecontent><cfset ' & (len(queryName) ? queryName & ' = ' : '')
            & 'boundaryQuery("' & queryName & '",VARIABLES.boundarySql)/>',"one");
    }
    for (var locationTag in reMatchNoCase("<cflocation\b[^>]*>",adapted)) {
        var urlMatch = reFindNoCase('url="([^"]*)"',locationTag,1,true);
        if (arrayLen(urlMatch.pos) < 2) throw(type="BoundaryHarness",message="Redirect without destination");
        adapted = replace(adapted,locationTag,'<cfset boundaryRedirect("'
            & mid(locationTag,urlMatch.pos[2],urlMatch.len[2]) & '")/>',"one");
    }
    for (var headerTag in reMatchNoCase("<cfheader\b[^>]*>",adapted)) {
        var headerName = reFindNoCase('name="([^"]+)"',headerTag,1,true);
        var headerValue = reFindNoCase('value="([^"]*)"',headerTag,1,true);
        if (arrayLen(headerName.pos) < 2 OR arrayLen(headerValue.pos) < 2)
            throw(type="BoundaryHarness",message="Unexpected response header boundary");
        adapted = replace(adapted,headerTag,'<cfset boundaryHeader("'
            & mid(headerTag,headerName.pos[2],headerName.len[2]) & '","'
            & mid(headerTag,headerValue.pos[2],headerValue.len[2]) & '")/>',"one");
    }
    for (var logTag in reMatchNoCase("<cflog\b[^>]*>",adapted))
        adapted=replace(adapted,logTag,find("Remembered login",logTag) ? "<cfset boundaryLog(cfcatch)/>" : "<!--- expected provider log --->","one");
    adapted = reReplaceNoCase(adapted,"<cfcookie\b[^>]*>","<!--- external cookie adapter --->","all");
    return adapted;
}
function boundaryRun(required string source) {
    variables.boundarySequence++;
    var fragment = variables.boundaryScratch & "/request-" & variables.boundarySequence & ".cfm";
    fileWrite(fragment,arguments.source,"utf-8");
    try { savecontent variable="local.output" { include fragment; } }
    catch (BoundaryRedirect expectedRedirect) {}
    catch (any failure) { variables.boundaryResult.error = failure.type & ": " & failure.message & " " & failure.detail; }
    return variables.boundaryResult;
}
function boundaryReset() {
    variables.boundaryForm = {};
    variables.boundaryUrl = {};
    variables.boundaryCookie = {id="1",name="Forged Admin",email="admin@example.test"};
    variables.boundaryCgi = {request_method="POST",remote_addr="127.0.0.1",script_name="/index.cfm"};
    variables.boundarySession = {businessLoginCsrf="session-csrf",businessLoginNonce="session-nonce"};
    variables.boundaryRequest = {businessAuthSession=variables.boundaryAuthSession,businessIdentity={},
        businessRememberDevice=variables.boundaryRemember,businessRememberCookie=""};
    variables.boundaryResult = {redirect="",queries=[],headers={},cookies=[],rotations=0,invalidations=0,error=""};
    variables.boundaryAccess = "false";
    variables.boundaryPending = "false";
    variables.boundaryLegacyBi = "false";
    for (var key in ["user_data","qPerfil","qBusinessGoogleSignInState"])
        structDelete(variables,key,false);
}
function boundaryToken(required any key, struct changes={}) {
    var claims = {iss="https://accounts.google.com",aud="boundary-test-client",sub="verified-subject",
        email="verified@example.test",email_verified=true,name="Verified Name",picture="https://example.test/avatar.png",
        nonce="session-nonce",iat=int(createObject("java","java.lang.System").currentTimeMillis()/1000),
        exp=int(createObject("java","java.lang.System").currentTimeMillis()/1000)+300};
    structAppend(claims,arguments.changes,true);
    var fields=[];
    for (var claim in claims) arrayAppend(fields,serializeJSON(lCase(claim)) & ":" & serializeJSON(claims[claim]));
    var jws=createObject("java","org.jose4j.jws.JsonWebSignature").init();
    jws.setPayload("{" & arrayToList(fields,",") & "}");
    jws.setAlgorithmHeaderValue("RS256");
    jws.setKey(arguments.key.getPrivate());
    return jws.getCompactSerialization();
}

try {
    boundaryAuthSession = createObject("component","authBoundaryRoot.services.BusinessAuthSession");
    boundaryRemember = createObject("component","authBoundaryRoot.services.BusinessRememberDevice").init("remember_test");
    for (boundaryHelper in ["business_remember_issue","business_remember_request","business_remember_revoke"])
        fileWrite(boundaryScratch & "/" & boundaryHelper & ".cfm",
            boundaryAdapt(fileRead(boundaryRoot & "includes/backend/" & boundaryHelper & ".cfm","utf-8")),"utf-8");
    // Constructor configures Google's transport without fetching a JWKS document.
    boundaryDefaultVerifier = createObject("component","authBoundaryRoot.services.GoogleIdentityVerifier").init("boundary-test-client");
    boundaryKeys = createObject("java","java.security.KeyPairGenerator").getInstance("RSA");
    boundaryKeys.initialize(2048);
    boundaryPair = boundaryKeys.generateKeyPair();
    boundaryJwk = createObject("java","org.jose4j.jwk.RsaJsonWebKey").init(boundaryPair.getPublic());
    boundaryResolver = createObject("java","org.jose4j.keys.resolvers.JwksVerificationKeyResolver")
        .init(createObject("java","java.util.Collections").singletonList(boundaryJwk));
    APPLICATION.businessGoogleVerifierV1 = createObject("component","authBoundaryRoot.services.GoogleIdentityVerifier")
        .init("boundary-test-client",boundaryResolver);
    APPLICATION.codSite = "TEST";
    boundaryValidToken = boundaryToken(boundaryPair);
    boundaryForgedToken = boundaryToken(boundaryKeys.generateKeyPair(),{email="admin@example.test",sub="forged-admin"});
    boundaryCallback = boundaryAdapt(fileRead(boundaryRoot & "includes/backend/business_google_callback.cfm","utf-8"));
    boundaryCallbackPath = boundaryScratch & "/callback.cfm";
    fileWrite(boundaryCallbackPath,boundaryCallback,"utf-8");
    boundaryIdentity = boundaryAdapt(fileRead(boundaryRoot & "includes/backend/business_request_identity.cfm","utf-8"));
    boundaryIdentity = replace(boundaryIdentity,'template="business_google_callback.cfm"',
        'template="' & boundaryCallbackPath & '"',"all");

    boundaryDeniedCases = [
        {label="forged signature with valid-looking claims",method="POST",form={credential=boundaryForgedToken,business_login_csrf="session-csrf"}},
        {label="GET callback with valid token",method="GET",form={credential=boundaryValidToken,business_login_csrf="session-csrf"}},
        {label="email-only alias",method="POST",form={email="admin@example.test",name="Admin",sub="forged",business_login_csrf="session-csrf"}},
        {label="legacy user_data alias",method="POST",form={user_data='{"email":"admin@example.test","sub":"forged"}',business_login_csrf="session-csrf"}},
        {label="missing CSRF",method="POST",form={credential=boundaryValidToken}},
        {label="incorrect CSRF",method="POST",form={credential=boundaryValidToken,business_login_csrf="attacker"}},
        {label="case-changed CSRF",method="POST",form={credential=boundaryValidToken,business_login_csrf="SESSION-CSRF"}},
        {label="token issued for another browser nonce",method="POST",form={credential=boundaryToken(boundaryPair,{nonce="other-session"}),business_login_csrf="session-csrf"}},
        {label="structured credential input",method="POST",form={credential={token=boundaryValidToken},business_login_csrf="session-csrf"}},
        {label="malformed token",method="POST",form={credential="invalid",business_login_csrf="session-csrf"}}
    ];
    for (boundaryCase in boundaryDeniedCases) {
        boundaryReset();
        boundaryForm = duplicate(boundaryCase.form);
        boundaryForm.action = "googlesignin";
        boundaryCgi.request_method = boundaryCase.method;
        boundaryRun(boundaryIdentity);
        boundaryCheck(boundaryResult.redirect == "/?login=1&auth_error=1" AND !len(boundaryResult.error),boundaryCase.label & " rejects generically");
        boundaryCheck(!arrayLen(boundaryResult.queries) AND boundaryResult.rotations == 0
            AND structIsEmpty(boundaryAuthSession.identity(boundarySession)),boundaryCase.label & " cannot reach SQL/session authentication");
    }
    for (boundaryMissing in ["businessLoginCsrf","businessLoginNonce"]) {
        boundaryReset();
        boundaryForm={action="googlesignin",credential=boundaryValidToken,business_login_csrf="session-csrf"};
        structDelete(boundarySession,boundaryMissing);
        boundaryRun(boundaryIdentity);
        boundaryCheck(boundaryResult.redirect == "/?login=1&auth_error=1" AND !arrayLen(boundaryResult.queries)
            AND !len(boundaryResult.error),"missing " & boundaryMissing & " rejects before SQL");
    }
    boundaryReset();
    boundaryUrl={action="googlesignin",credential=boundaryValidToken,business_login_csrf="session-csrf"};
    boundaryCgi.request_method="GET";
    boundaryRun(boundaryIdentity);
    boundaryCheck(boundaryResult.redirect == "/?login=1&auth_error=1" AND !arrayLen(boundaryResult.queries)
        AND !len(boundaryResult.error),"URL action alias still reaches the POST-only shared gate");

    boundaryRoutes = [
        {label="approved home",access="true",pending="false",requested="",want="/"},
        {label="approved local return",access="t",pending="false",requested="/ads/?campanha=demo",want="/ads/?campanha=demo"},
        {label="pending home",access="false",pending="true",requested="",want="/"},
        {label="pending cannot bypass onboarding",access="false",pending="1",requested="/ads/",want="/"},
        {label="new user onboarding",access="false",pending="false",requested="",want="/cadastro/"},
        {label="new user research return",access="false",pending="false",requested="/pesquisa/demo/?step=2",want="/pesquisa/demo/?step=2"},
        {label="new user research session return",access="false",pending="false",requested="",sessionReturn="/pesquisa/demo/",want="/pesquisa/demo/"},
        {label="partner BI return",access="false",pending="false",legacyBi="true",requested="/bi/?tag=demo",want="/bi/?tag=demo"},
        {label="partner cannot enter Business by BI permission",access="false",pending="false",legacyBi="true",requested="/ads/",want="/cadastro/"},
        {label="non-partner cannot enter BI by redirect",access="false",pending="false",requested="/bi/",want="/cadastro/"},
        {label="external return rejected",access="true",pending="false",requested="https://attacker.example/",want="/"},
        {label="protocol-relative return rejected",access="true",pending="false",requested="//attacker.example/",want="/"},
        {label="backslash return rejected",access="true",pending="false",requested="/\attacker.example/",want="/"},
        {label="line-break return rejected",access="true",pending="false",requested="/" & chr(13) & chr(10) & "evil",want="/"},
        {label="logout return rejected",access="true",pending="false",requested="/?logout=1",want="/"}
    ];
    for (boundaryCase in boundaryRoutes) {
        boundaryReset();
        boundaryAccess=boundaryCase.access;
        boundaryPending=boundaryCase.pending;
        if (structKeyExists(boundaryCase,"legacyBi")) boundaryLegacyBi=boundaryCase.legacyBi;
        boundaryForm={action="googlesignin",credential=boundaryValidToken,business_login_csrf="session-csrf",redirect=boundaryCase.requested};
        boundaryForm.email="admin@example.test";
        boundaryForm.id="1";
        if (structKeyExists(boundaryCase,"sessionReturn")) boundarySession.researchLoginRedirect=boundaryCase.sessionReturn;
        boundarySession.businessActiveAccountId="old-account";
        boundarySession.businessAccountContextCsrf="old-permission-token";
        boundarySession.eventsCsrf="old-event-token";
        boundarySession.agendaManagementFeedToken="old-feed-token";
        boundarySession.stravaMigrationFlash="old-user-flash";
        boundaryRun(boundaryIdentity);
        boundaryCheck(boundaryResult.redirect == boundaryCase.want AND !len(boundaryResult.error),boundaryCase.label & " routes correctly: " & boundaryResult.error);
        boundaryCheck(arrayLen(boundaryResult.queries) == 4 AND boundaryResult.rotations == 1,
            boundaryCase.label & " creates one verified login with session rotation");
        boundaryCheck(structKeyExists(boundaryRequest.businessIdentity,"id") AND boundaryRequest.businessIdentity.id == 42
            AND boundaryRequest.businessIdentity.email == "verified@example.test"
            AND boundaryRequest.businessIdentity.name == "Stored Verified Name",
            boundaryCase.label & " principal comes from verified claims/database, not cookies");
        boundaryCheck(structKeyExists(boundarySession,"businessRememberSelector")
            AND structKeyExists(boundaryResult.headers,"Set-Cookie"),boundaryCase.label & " persists verified login");
        boundaryCheck(!structKeyExists(boundarySession,"businessActiveAccountId")
            AND !structKeyExists(boundarySession,"businessAccountContextCsrf")
            AND !structKeyExists(boundarySession,"researchLoginRedirect")
            AND !structKeyExists(boundarySession,"businessLoginCsrf")
            AND !structKeyExists(boundarySession,"businessLoginNonce")
            AND !structKeyExists(boundarySession,"eventsCsrf")
            AND !structKeyExists(boundarySession,"agendaManagementFeedToken")
            AND !structKeyExists(boundarySession,"stravaMigrationFlash"),boundaryCase.label & " consumes login secrets and stale tenant state");
        if (arrayLen(boundaryResult.queries)) boundaryCheck(find("verified@example.test",boundaryResult.queries[1].sql) > 0
            AND !find("admin@example.test",boundaryResult.queries[1].sql),boundaryCase.label & " writes verified email only");
    }

    boundaryReset();
    boundarySession.cadastroGoogleIdentity={email="admin@example.test",name="Admin",sub="forged"};
    boundaryRun(boundaryIdentity);
    boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND !structKeyExists(boundarySession,"cadastroGoogleIdentity")
        AND !arrayLen(boundaryResult.queries) AND !len(boundaryResult.error),"request init rejects cookie ID and unsigned legacy cadastro identity");
    boundaryCheck(structKeyExists(boundaryResult.headers,"Cache-Control") AND boundaryResult.headers["Cache-Control"] == "private, no-store",
        "anonymous login page with session-bound secrets is not cacheable");
    boundaryReset();
    boundarySession.businessAuthenticatedIdentity={id=1,email="admin@example.test",name="Admin",sub="forged"};
    boundaryRun(boundaryIdentity);
    boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND !len(boundaryResult.error),"request init rejects unversioned principal");
    boundaryReset();
    boundaryAuthSession.establish(boundarySession,42,{sub="verified-subject",email="verified@example.test",name="Verified",picture=""});
    boundaryCgi.script_name="/ads/index.cfm";
    boundaryRun(boundaryIdentity);
    boundaryCheck(boundaryRequest.businessIdentity.id == 42 AND !len(boundaryResult.error),"request init preserves verified session despite forged ID cookie");
    boundaryCheck(structKeyExists(boundaryResult.headers,"Cache-Control") AND boundaryResult.headers["Cache-Control"] == "private, no-store",
        "authenticated request prevents caching identity/CSRF output");
    boundaryNonceBefore=boundarySession.businessLoginNonce;
    boundaryRun(boundaryIdentity);
    boundaryCheck(boundaryRequest.businessIdentity.id == 42 AND boundarySession.businessLoginNonce == boundaryNonceBefore,
        "repeated shared include is idempotent within one request");

    boundaryLogout = boundaryAdapt(fileRead(boundaryRoot & "logout.cfm","utf-8"));
    boundaryRun(boundaryLogout);
    boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND structIsEmpty(boundaryAuthSession.identity(boundarySession))
        AND !structKeyExists(boundarySession,"cadastroGoogleIdentity") AND boundaryResult.invalidations == 1
        AND !len(boundaryResult.error),"actual logout clears request/onboarding principal and invalidates session");

    boundaryCadastro=fileRead(boundaryRoot & "cadastro/includes/backend.cfm","utf-8");
    boundarySwitchStart=find('<cfif FORM.acao EQ "trocar_conta_google">',boundaryCadastro);
    boundarySwitchEnd=find('<cfset VARIABLES.cadastroGoogleAuthenticated',boundaryCadastro,boundarySwitchStart);
    if (!boundarySwitchStart OR !boundarySwitchEnd) throw(type="BoundaryHarness",message="Google account switch boundary missing");
    boundarySwitch=boundaryAdapt(mid(boundaryCadastro,boundarySwitchStart,boundarySwitchEnd-boundarySwitchStart));
    for (boundarySwitchToken in ["wrong","switch-csrf"]) {
        boundaryReset();
        boundaryAuthSession.establish(boundarySession,42,{sub="verified-subject",email="verified@example.test",name="Verified",picture=""});
        boundaryRequest.businessIdentity=boundaryAuthSession.identity(boundarySession);
        boundarySwitchDevice=boundaryRemember.issue(boundaryRequest.businessIdentity);
        boundaryRequest.businessRememberCookie=boundarySwitchDevice.cookieValue;
        boundarySession.businessRememberSelector=boundarySwitchDevice.selector;
        boundarySession.cadastroGoogleCsrf="switch-csrf";
        boundarySession.businessActiveAccountId="old-account";
        boundarySession.businessAccountContextCsrf="old-context";
        boundaryForm={acao="trocar_conta_google",cadastro_csrf=boundarySwitchToken};
        boundaryRun(boundarySwitch);
        if (boundarySwitchToken == "wrong") boundaryCheck(boundaryRequest.businessIdentity.id == 42 AND boundaryResult.rotations == 0
            AND !structIsEmpty(boundaryRemember.restore(boundarySwitchDevice.cookieValue))
            AND !len(boundaryResult.error),"account switch with invalid CSRF preserves login and remembered device");
        else boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND structIsEmpty(boundaryAuthSession.identity(boundarySession))
            AND !structKeyExists(boundarySession,"cadastroGoogleIdentity") AND !structKeyExists(boundarySession,"businessActiveAccountId")
            AND !structKeyExists(boundarySession,"businessAccountContextCsrf") AND boundaryResult.rotations == 1
            AND structIsEmpty(boundaryRemember.restore(boundarySwitchDevice.cookieValue))
            AND boundaryResult.redirect == "/cadastro/" AND !len(boundaryResult.error),"actual account switch revokes device and clears identity and tenant state before rotating");
    }
    // Construction compiles the real application components, but deliberately
    // does not call lifecycle methods (which access configuration and databases).
    savecontent variable="boundaryApplicationOutput" {
        boundaryMainApplication=createObject("component","authBoundaryRoot.Application");
        boundaryBiApplication=createObject("component","authBoundaryRoot.bi.Application");
    }
    boundaryCheck(boundaryMainApplication.name == "RunnerHubBusiness" AND boundaryBiApplication.name == "RunnerHubBusiness"
        AND boundaryMainApplication.sessionManagement AND boundaryBiApplication.sessionManagement,
        "root and BI declare one shared server-session application");
    for (boundaryApplication in [boundaryMainApplication,boundaryBiApplication])
        boundaryCheck(boundaryApplication.sessionCookie.httpOnly AND boundaryApplication.sessionCookie.secure
            AND boundaryApplication.sessionCookie.sameSite == "Lax","application config protects native session cookie");
    boundaryCheck(boundaryMainApplication.sessionTimeout GTE createTimeSpan(1,0,0,0)
        AND boundaryBiApplication.sessionTimeout GTE createTimeSpan(1,0,0,0),"Business and BI keep a session for at least twenty-four idle hours");

    boundaryReset();
    boundaryDevice=boundaryRemember.issue({version=1,id=42,sub="verified-subject",email="verified@example.test"});
    boundaryCookie[boundaryRemember.cookieName()]=boundaryDevice.cookieValue;
    boundarySession={};
    boundaryCgi.request_method="GET";
    boundaryCgi.script_name="/ads/index.cfm";
    boundaryRun(boundaryIdentity);
    boundaryCheck(!len(boundaryResult.error) AND boundaryRequest.businessIdentity.id==42 AND boundaryResult.rotations==1,
        "expired CF session is restored by the actual request boundary: " & boundaryResult.error);
    boundaryCheck(structKeyExists(boundarySession,"cadastroGoogleIdentity")
        AND !structKeyExists(boundarySession,"businessActiveAccountId"),"restoration rebuilds verified onboarding identity without granting tenant permissions");
    boundaryCheck(structKeyExists(boundaryResult.headers,"Cache-Control") AND boundaryResult.headers["Cache-Control"]=="private, no-store",
        "restored private page is not cacheable: " & boundaryResult.error);
    // The raw incoming credential remains revocable during the rotation grace.
    boundaryRun(boundaryLogout);
    boundaryCheck(structIsEmpty(boundaryRemember.restore(boundaryDevice.cookieValue))
        AND arrayFind(boundaryResult.cookies,boundaryRemember.expireCookieHeader())>0
        AND !len(boundaryResult.error),"actual logout revokes remembered device before clearing session");

    for (boundarySuppression in ["marker","logout-route","logout-query","switch"] ) {
        boundaryReset();
        boundaryDevice=boundaryRemember.issue({version=1,id=42,sub="verified-subject",email="verified@example.test"});
        boundaryCookie[boundaryRemember.cookieName()]=boundaryDevice.cookieValue;
        boundarySession={};
        if (boundarySuppression=="marker") boundaryCookie.rr_logged_out="1";
        if (boundarySuppression=="logout-route") boundaryCgi.script_name="/logout.cfm";
        if (boundarySuppression=="logout-query") boundaryUrl.logout="1";
        if (boundarySuppression=="switch") boundaryForm.acao="trocar_conta_google";
        boundaryRun(boundaryIdentity);
        boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND !boundaryResult.rotations AND !len(boundaryResult.error),
            "remembered cookie does not silently sign in during " & boundarySuppression);
    }
    for (boundaryMissingCookie in [false,true]) {
        boundaryReset();
        boundaryAuthSession.establish(boundarySession,42,{sub="verified-subject",email="verified@example.test",name="Verified",picture=""});
        boundaryDevice=boundaryRemember.issue(boundaryAuthSession.identity(boundarySession));
        boundarySession.businessRememberSelector=boundaryDevice.selector;
        boundarySession.businessRememberCheckedAt=dateAdd("n",-6,now());
        if (!boundaryMissingCookie) boundaryCookie[boundaryRemember.cookieName()]=boundaryDevice.cookieValue;
        boundaryRemember.revoke(boundaryDevice.cookieValue);
        boundaryRun(boundaryIdentity);
        boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND boundaryResult.rotations==1 AND !len(boundaryResult.error),
            "revoked device ends active session, cookie missing=" & boundaryMissingCookie);
    }
    // Loss of the persistence table must not reject an otherwise valid Google login.
    queryExecute("ALTER TABLE public.tb_business_remember_devices RENAME TO remember_unavailable",{},{datasource="remember_test"});
    try {
        boundaryReset();
        boundaryAccess="true";
        boundaryForm={action="googlesignin",credential=boundaryValidToken,business_login_csrf="session-csrf"};
        boundaryRun(boundaryIdentity);
        boundaryCheck(boundaryResult.redirect=="/" AND boundaryRequest.businessIdentity.id==42
            AND !structKeyExists(boundarySession,"businessRememberSelector"),"database persistence outage preserves valid twenty-four-hour Google session");
        boundaryReset();
        boundaryCookie[boundaryRemember.cookieName()]=boundaryDevice.cookieValue;
        boundarySession={};
        boundaryRun(boundaryIdentity);
        boundaryCheck(structIsEmpty(boundaryRequest.businessIdentity) AND !boundaryResult.rotations,
            "database persistence outage cannot restore an anonymous session");
    } finally {
        queryExecute("ALTER TABLE public.remember_unavailable RENAME TO tb_business_remember_devices",{},{datasource="remember_test"});
    }
} finally {
    structDelete(APPLICATION,"businessGoogleVerifierV1",false);
    directoryDelete(boundaryScratch,true);
}
for (boundaryFailure in boundaryFailures) writeOutput("FAIL: " & boundaryFailure & chr(10));
writeOutput("BUSINESS AUTH BOUNDARY: " & (arrayLen(boundaryFailures) ? "FAIL" : "PASS")
    & " (" & boundaryChecks & " checks, " & arrayLen(boundaryFailures) & " failures)" & chr(10));
if (arrayLen(boundaryFailures)) throw(type="AuthBoundaryRegression",message="Business request authentication boundary failed",
    detail=arrayToList(boundaryFailures,"; "));
</cfscript>
