<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="90"/>
<cfscript>
failures=[];tests=0;
function verifySignedCatalog(required numeric actorId, string mode="valid") {
    var cfg=APPLICATION.specialGroups;
    var body=serializeJSON({action="catalog",actor_id=arguments.actorId});
    var stamp=dateTimeFormat(arguments.mode EQ "expired" ? dateAdd("n",-10,now()) : now(),"yyyy-mm-dd HH:nn:ss");
    var signature=lCase(hmac(stamp & "." & body,arguments.mode EQ "wrong-key" ? "synthetic-wrong-secret" : cfg.secret,"HmacSHA256"));
    var outgoing=new http(method="post",url=cfg.url,timeout=15,throwOnError=false);
    outgoing.addParam(type="header",name="Content-Type",value="application/json; charset=utf-8");
    outgoing.addParam(type="header",name="X-RR-Handoff-Timestamp",value=stamp);
    outgoing.addParam(type="header",name="X-RR-Handoff-Signature",value=signature);
    outgoing.addParam(type="body",value=body & (arguments.mode EQ "tampered" ? " " : ""));
    var response=outgoing.send().getPrefix();
    return {status=val(response.statusCode),payload=isJSON(response.fileContent) ? deserializeJSON(response.fileContent) : {success=false,message="non-json"}};
}
function expectSigned(required boolean condition,required string label) {
    tests++;
    if (!arguments.condition) arrayAppend(failures,arguments.label);
}
valid=verifySignedCatalog(142);
expectSigned(valid.status EQ 200 && valid.payload.success,"An authorized admin loads the signed catalog");
for (invalidMode in ["tampered","wrong-key"]) {
    invalid=verifySignedCatalog(142,invalidMode);
    expectSigned(invalid.status EQ 401 && invalid.payload.message EQ "invalid_signature","Reject " & invalidMode);
}
expired=verifySignedCatalog(142,"expired");
expectSigned(expired.status EQ 401 && expired.payload.message EQ "expired_signature","Expired signatures remain rejected");
ordinary=queryExecute("SELECT id FROM tb_usuarios WHERE coalesce(is_admin,false)=false ORDER BY id LIMIT 1",{},{datasource="runner_dba",timeout=5});
if (!ordinary.recordCount) throw(message="Usuário comum de validação não encontrado.");
forbidden=verifySignedCatalog(ordinary.id);
expectSigned(forbidden.status EQ 403 && !forbidden.payload.success,"A valid signature does not grant global-admin access");
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),tests=tests,failures=failures}));
</cfscript>
