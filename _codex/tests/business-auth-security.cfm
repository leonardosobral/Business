<!--- Never execute fixtures through a deployed web route. --->
<cfset offlineAuthEnvironment=createObject("java","java.lang.System").getenv()/>
<cfif NOT offlineAuthEnvironment.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS")
    OR offlineAuthEnvironment.get("RUNNERHUB_OFFLINE_CFML_TESTS") NEQ "1">
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<!--- Offline behavioral tests. Set JOSE4J_TEST_JAR to the local jose4j 0.9.4 jar
      when using CommandBox/Lucee; Adobe ColdFusion already bundles jose4j. --->
<cfscript>
authRoot = expandPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../../");
authJavaPaths = [];
authEnv = createObject("java", "java.lang.System").getenv();
if (authEnv.containsKey("JOSE4J_TEST_JAR")) arrayAppend(authJavaPaths, authEnv.get("JOSE4J_TEST_JAR"));
authMappings=duplicate(getApplicationSettings().mappings);
authMappings["/authTestRoot"]=authRoot;
application action="update" mappings=authMappings javaSettings={loadPaths=authJavaPaths,loadColdFusionClassPath=true};
authChecks = 0;
function check(required boolean value, required string label) {
    variables.authChecks++;
    if (!arguments.value) throw(type="AuthRegression",message=arguments.label);
}
function denied(required any verifier, required string token, string nonce="test-nonce") {
    try { arguments.verifier.verify(arguments.token, arguments.nonce); return false; }
    catch (any failure) { return true; }
}
function signedToken(required any key, struct changes={}) {
    var data = {iss="https://accounts.google.com",aud="test-client",sub="google-user-123",
        email="tester@gmail.com",email_verified=true,name="Tester",nonce="test-nonce",
        iat=int(createObject("java","java.lang.System").currentTimeMillis()/1000),
        exp=int(createObject("java","java.lang.System").currentTimeMillis()/1000)+300};
    structAppend(data,arguments.changes,true);
    var jws = createObject("java","org.jose4j.jws.JsonWebSignature").init();
    var jsonFields=[];
    for (var key in data) arrayAppend(jsonFields,serializeJSON(lCase(key)) & ":" & serializeJSON(data[key]));
    jws.setPayload("{" & arrayToList(jsonFields,",") & "}");
    jws.setAlgorithmHeaderValue("RS256");
    jws.setKey(arguments.key.getPrivate());
    return jws.getCompactSerialization();
}
authSession = createObject("component","authTestRoot.services.BusinessAuthSession");
authState = {cadastroGoogleIdentity={sub="forged",email="admin@gmail.com",name="Admin"}};
check(structIsEmpty(authSession.identity(authState)),"old unsigned cadastro sessions cannot authenticate");
authState.businessAuthenticatedIdentity={version=0,id=1,email="admin@gmail.com",name="Admin",sub="forged"};
check(structIsEmpty(authSession.identity(authState)),"unversioned principals are rejected");
authSession.establish(authState,42,{sub="real-sub",email="tester@gmail.com",name="Tester",picture=""});
check(authSession.identity(authState).id == 42,"verified user is independent of client ID cookie");
check(authState.cadastroGoogleIdentity.sub == "real-sub","onboarding identity uses same principal");
authState.businessActiveAccountId="old-account";
authState.businessAccountContextCsrf="old-token";
authSession.clear(authState);
check(structIsEmpty(authSession.identity(authState)) AND !structKeyExists(authState,"cadastroGoogleIdentity")
    AND !structKeyExists(authState,"businessActiveAccountId") AND !structKeyExists(authState,"businessAccountContextCsrf"),
    "logout/account switch removes principal, onboarding and permissions context");
authKeys = createObject("java","java.security.KeyPairGenerator").getInstance("RSA");
authKeys.initialize(2048);
authPair = authKeys.generateKeyPair();
authJwk = createObject("java","org.jose4j.jwk.RsaJsonWebKey").init(authPair.getPublic());
authResolver = createObject("java","org.jose4j.keys.resolvers.JwksVerificationKeyResolver")
    .init(createObject("java","java.util.Collections").singletonList(authJwk));
authVerifier = createObject("component","authTestRoot.services.GoogleIdentityVerifier").init("test-client",authResolver);
authToken = signedToken(authPair);
check(authVerifier.verify(authToken,"test-nonce").email == "tester@gmail.com","valid signed Google claims accepted");
check(denied(authVerifier,authToken,"other-session"),"nonce from another browser rejected");
check(denied(authVerifier,authToken,""),"missing nonce rejected");
for (authClaims in [{aud="attacker-client"},{iss="https://attacker.example"},{exp=1},{email_verified=false},{nonce="other"},{sub=""}]) {
    check(denied(authVerifier,signedToken(authPair,authClaims)),"invalid signed claim rejected: " & serializeJSON(authClaims));
}
check(denied(authVerifier,signedToken(authKeys.generateKeyPair())),"forged RSA signer rejected");
authParts=listToArray(authToken,".");
check(denied(authVerifier,authParts[1] & "." & authParts[2] & ".AA"),"modified signature rejected");
check(denied(authVerifier,"eyJhbGciOiJub25lIn0.e30."),"unsigned token rejected");
check(denied(authVerifier,"not-a-jwt"),"malformed token rejected");
writeOutput("BUSINESS AUTH SECURITY: PASS (" & authChecks & " checks)" & chr(10));
</cfscript>
