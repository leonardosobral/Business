<cfset offlineEnv=createObject("java","java.lang.System").getenv()/>
<cfif NOT offlineEnv.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") OR offlineEnv.get("RUNNERHUB_OFFLINE_CFML_TESTS") NEQ "1">
    <cfheader statuscode="404"/><cfabort/>
</cfif>
<cfscript>
root=expandPath(getDirectoryFromPath(getCurrentTemplatePath()) & "../../");
testMappings=duplicate(getApplicationSettings().mappings);
testMappings["/rememberRoot"]=root;
application action="update" mappings=testMappings datasources={remember_test={
    class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",
    connectionString="jdbc:postgresql://127.0.0.1:" & offlineEnv.get("BUSINESS_AUTH_TEST_PORT") & "/business_auth_test",
    username="business_auth_test",password=""
}};
checks=0;
function check(required boolean ok, required string label) {
    variables.checks++;
    if (!arguments.ok) throw(type="RememberRegression",message=arguments.label);
}
function sql(required string statement, struct params={}) {
    return queryExecute(arguments.statement,arguments.params,{datasource="remember_test"});
}
// Removing expiration/revocation checks, accepting a guessed validator, or
// restoring the cookie's user ID must break these real PostgreSQL tests.
check(fileExists(root & "services/BusinessRememberDevice.cfc"),"persistent login service is implemented");
sql("CREATE ROLE runner_dba");
sql("CREATE TABLE public.tb_usuarios (id integer PRIMARY KEY, name varchar(256), email varchar(256), imagem_usuario varchar(256))");
sql("CREATE TABLE public.tb_usuarios_gestao (id_usuario integer PRIMARY KEY, ativo boolean, excluido boolean)");
sql("INSERT INTO public.tb_usuarios VALUES (42,'Verified User','verified@example.test',''),(43,'Other User','other@example.test','')");
sql("INSERT INTO public.tb_usuarios_gestao VALUES (42,true,false)");
sql(fileRead(root & "_codex/sql/2026-09-09_business_remember_devices.sql"));
sql(fileRead(root & "_codex/sql/2026-09-09_business_remember_devices.sql"));
service=createObject("component","rememberRoot.services.BusinessRememberDevice").init("remember_test");
principal={version=1,id=42,sub="verified-google-sub",email="verified@example.test",name="Verified User",imagem_usuario=""};
issued=service.issue(principal);
check(reFind("^[a-f0-9]{32}\.[a-f0-9]{64}$",issued.cookieValue)==1,"cookie is an opaque random credential");
record=sql("SELECT * FROM public.tb_business_remember_devices");
check(record.recordCount==1 AND record.user_id==42 AND record.token_hash!=listLast(issued.cookieValue,"."),"only credential hash is stored");
check(dateDiff("s",now(),issued.expiresAt)>2591900 AND dateDiff("s",now(),issued.expiresAt)<=2592000,"credential lasts thirty days");
check(find("Max-Age=2592000",service.cookieHeader(issued))>0
    AND find("HttpOnly",service.cookieHeader(issued))>0 AND find("Secure",service.cookieHeader(issued))>0
    AND find("SameSite=Lax",service.cookieHeader(issued))>0 AND !findNoCase("Domain=",service.cookieHeader(issued)),"cookie is protected and host-only");
restored=service.restore(issued.cookieValue,true);
check(restored.identity.id==42 AND restored.identity.sub=="verified-google-sub","empty session can recover verified identity from persistent credential");
check(len(restored.cookieValue)>0 AND restored.cookieValue!=issued.cookieValue,"restoration rotates the credential");
parallel=service.restore(issued.cookieValue,true);
check(parallel.identity.id==42 AND !len(parallel.cookieValue),"concurrent request accepts previous token briefly without overwriting rotated cookie");
current=service.restore(restored.cookieValue,false);
check(current.identity.id==42 AND !len(current.cookieValue),"normal requests do not continually rotate the cookie");
for (bad in ["42", "", "invalid", listFirst(restored.cookieValue,".") & "." & repeatString("0",64),uCase(restored.cookieValue)]) {
    check(structIsEmpty(service.restore(bad)),"invalid credential cannot restore identity");
}
sql("UPDATE public.tb_business_remember_devices SET previous_valid_until=CURRENT_TIMESTAMP-interval '1 second'");
check(structIsEmpty(service.restore(issued.cookieValue)),"replayed previous token is rejected after concurrency grace");
check(service.restore(restored.cookieValue).identity.id==42,"bad token cannot revoke a valid device by guessing its selector");
sql("UPDATE public.tb_business_remember_devices SET rotated_at=CURRENT_TIMESTAMP-interval '25 hours'");
renewed=service.restore(restored.cookieValue,false);
check(len(renewed.cookieValue)>0 AND dateDiff("s",now(),renewed.expiresAt)>2591900,"daily use renews the thirty-day cookie");
sql("UPDATE public.tb_usuarios SET name='Updated User' WHERE id=42");
check(service.restore(renewed.cookieValue).identity.name=="Updated User","restored profile is loaded from current user record");
sql("UPDATE public.tb_usuarios_gestao SET ativo=false WHERE id_usuario=42");
check(structIsEmpty(service.restore(renewed.cookieValue)),"disabled account cannot restore a persistent login");
sql("UPDATE public.tb_usuarios_gestao SET ativo=true, excluido=true WHERE id_usuario=42");
check(structIsEmpty(service.restore(renewed.cookieValue)),"deleted account cannot restore a persistent login");
sql("UPDATE public.tb_usuarios_gestao SET excluido=false WHERE id_usuario=42");
sql("UPDATE public.tb_usuarios SET email='changed@example.test' WHERE id=42");
check(structIsEmpty(service.restore(renewed.cookieValue)),"changed email cannot inherit a remembered identity");
sql("UPDATE public.tb_usuarios SET email='verified@example.test' WHERE id=42");
sql("UPDATE public.tb_business_remember_devices SET expires_at=CURRENT_TIMESTAMP-interval '1 second'");
check(structIsEmpty(service.restore(renewed.cookieValue)),"expired cookie fails even if browser sends it");
deviceA=service.issue(principal);
deviceB=service.issue(principal);
service.revoke(deviceA.cookieValue);
check(structIsEmpty(service.restore(deviceA.cookieValue)),"logout revokes the server credential");
check(service.restore(deviceB.cookieValue).identity.id==42,"logout preserves other devices");
service.revoke("malformed");
service.revoke("",deviceB.selector,42);
check(structIsEmpty(service.restore(deviceB.cookieValue)),"logout can revoke remembered session when browser cookie is missing");
deviceC=service.issue(principal);
check(service.isActive(deviceC.selector,42) AND !service.isActive(deviceC.selector,43),"session device validation is bound to its verified user");
service.revoke(deviceC.cookieValue);
check(!service.isActive(deviceC.selector,42),"revoked session stays revoked even if the browser deletes its persistent cookie");
check(find("Max-Age=0",service.expireCookieHeader())>0 AND find("HttpOnly",service.expireCookieHeader())>0,"logout expires persistent cookie");
writeOutput("BUSINESS REMEMBER DEVICE: PASS (" & checks & " checks)" & chr(10));
</cfscript>
