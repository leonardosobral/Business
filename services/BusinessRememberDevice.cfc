component output=false {
    variables.datasource = "runner_dba";
    variables.cookieName = "__Host-business_remember";

    public any function init(string datasource="runner_dba") {
        variables.datasource = arguments.datasource;
        return this;
    }

    public string function cookieName() { return variables.cookieName; }

    private query function sql(required string statement, struct params={}) {
        return queryExecute(arguments.statement,arguments.params,{datasource=variables.datasource,timeout=5});
    }

    private string function randomSecret() {
        return lCase(hash(generateSecretKey("AES",256),"SHA-256"));
    }

    private struct function parse(required string raw) {
        if (len(arguments.raw) != 97 || !reFind("^[a-f0-9]{32}\.[a-f0-9]{64}$",arguments.raw)) return {};
        return {selector=listFirst(arguments.raw,"."),hash=lCase(hash(listLast(arguments.raw,"."),"SHA-256"))};
    }

    private boolean function sameHash(required string leftHash, required string rightHash) {
        if (len(arguments.leftHash)!=64 || len(arguments.rightHash)!=64) return false;
        return createObject("java","java.security.MessageDigest").isEqual(
            binaryDecode(arguments.leftHash,"hex"),binaryDecode(arguments.rightHash,"hex"));
    }

    public struct function issue(required struct identity) {
        if (!structKeyExists(arguments.identity,"version") || arguments.identity.version != 1
            || !structKeyExists(arguments.identity,"id") || !isValid("integer",arguments.identity.id) || arguments.identity.id LTE 0
            || !structKeyExists(arguments.identity,"sub") || !len(arguments.identity.sub) || len(arguments.identity.sub)>255
            || !structKeyExists(arguments.identity,"email") || !isValid("email",arguments.identity.email)) {
            throw(type="BusinessRememberIdentity",message="A verified identity is required");
        }
        var selector=left(randomSecret(),32);
        var secret=randomSecret();
        var created=sql("INSERT INTO public.tb_business_remember_devices (selector,user_id,google_subject,email,token_hash)
            SELECT :selector,u.id,:subject,lower(u.email),:hash FROM public.tb_usuarios u
            LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id
            WHERE u.id=:userId AND lower(u.email)=:email
              AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false
            RETURNING expires_at",{
                selector={value=selector,cfsqltype="cf_sql_varchar"},
                userId={value=arguments.identity.id,cfsqltype="cf_sql_integer"},
                subject={value=arguments.identity.sub,cfsqltype="cf_sql_varchar"},
                email={value=lCase(trim(arguments.identity.email)),cfsqltype="cf_sql_varchar"},
                hash={value=lCase(hash(secret,"SHA-256")),cfsqltype="cf_sql_varchar"}
            });
        if (!created.recordCount) return {};
        return {selector=selector,cookieValue=selector & "." & secret,expiresAt=created.expires_at[1]};
    }

    public struct function restore(required string raw, boolean rotate=false) {
        var token=parse(arguments.raw);
        if (structIsEmpty(token)) return {};
        var result={};
        transaction {
            var record=sql("SELECT d.selector,d.user_id,d.google_subject,d.email,d.token_hash,
                    coalesce(d.previous_hash,'') AS previous_hash,
                    coalesce(d.previous_valid_until>CURRENT_TIMESTAMP,false) AS previous_valid,
                    d.rotated_at<=CURRENT_TIMESTAMP-interval '24 hours' AS rotate_due,d.expires_at,
                    u.name,coalesce(u.imagem_usuario,'') AS picture
                FROM public.tb_business_remember_devices d
                INNER JOIN public.tb_usuarios u ON u.id=d.user_id AND lower(u.email)=d.email
                LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id
                WHERE d.selector=:selector AND d.revoked_at IS NULL AND d.expires_at>CURRENT_TIMESTAMP
                  AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false
                FOR UPDATE OF d",{selector={value=token.selector,cfsqltype="cf_sql_varchar"}});
            if (record.recordCount) {
                var isCurrent=sameHash(token.hash,record.token_hash[1]);
                var isPrevious=record.previous_valid[1] && sameHash(token.hash,record.previous_hash[1]);
                if (isCurrent || isPrevious) {
                    result={selector=token.selector,cookieValue="",expiresAt=record.expires_at[1],
                        identity={version=1,id=record.user_id[1],sub=record.google_subject[1],email=record.email[1],
                            name=record.name[1],imagem_usuario=record.picture[1]}};
                    if (isCurrent && (arguments.rotate || record.rotate_due[1])) {
                        var secret=randomSecret();
                        var updated=sql("UPDATE public.tb_business_remember_devices
                            SET previous_hash=token_hash,previous_valid_until=CURRENT_TIMESTAMP+interval '120 seconds',
                                token_hash=:hash,rotated_at=CURRENT_TIMESTAMP,last_used_at=CURRENT_TIMESTAMP,
                                expires_at=CURRENT_TIMESTAMP+interval '30 days'
                            WHERE selector=:selector RETURNING expires_at",{
                                hash={value=lCase(hash(secret,"SHA-256")),cfsqltype="cf_sql_varchar"},
                                selector={value=token.selector,cfsqltype="cf_sql_varchar"}
                            });
                        result.cookieValue=token.selector & "." & secret;
                        result.expiresAt=updated.expires_at[1];
                    } else {
                        // A concurrent request with the previous token must never
                        // replace the winner's Set-Cookie response with stale data.
                        sql("UPDATE public.tb_business_remember_devices SET last_used_at=CURRENT_TIMESTAMP WHERE selector=:selector",
                            {selector={value=token.selector,cfsqltype="cf_sql_varchar"}});
                    }
                }
            }
        }
        return result;
    }

    public boolean function isActive(required string selector, required numeric userId) {
        if (!reFind("^[a-f0-9]{32}$",arguments.selector) || arguments.userId LTE 0) return false;
        var record=sql("SELECT d.selector FROM public.tb_business_remember_devices d
            INNER JOIN public.tb_usuarios u ON u.id=d.user_id AND lower(u.email)=d.email
            LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id
            WHERE d.selector=:selector AND d.user_id=:userId AND d.revoked_at IS NULL AND d.expires_at>CURRENT_TIMESTAMP
              AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false",{
                selector={value=arguments.selector,cfsqltype="cf_sql_varchar"},userId={value=arguments.userId,cfsqltype="cf_sql_integer"}
            });
        return record.recordCount==1;
    }

    public void function revoke(string raw="", string sessionSelector="", numeric userId=0) {
        var token=parse(arguments.raw);
        if (!structIsEmpty(token)) {
            sql("UPDATE public.tb_business_remember_devices SET revoked_at=CURRENT_TIMESTAMP
                WHERE selector=:selector AND (token_hash=:hash OR previous_hash=:hash) AND revoked_at IS NULL",{
                    selector={value=token.selector,cfsqltype="cf_sql_varchar"},hash={value=token.hash,cfsqltype="cf_sql_varchar"}
                });
        }
        // The selector/user pair comes only from the authenticated server session.
        if (reFind("^[a-f0-9]{32}$",arguments.sessionSelector) && arguments.userId>0) {
            sql("UPDATE public.tb_business_remember_devices SET revoked_at=CURRENT_TIMESTAMP
                WHERE selector=:selector AND user_id=:userId AND revoked_at IS NULL",{
                    selector={value=arguments.sessionSelector,cfsqltype="cf_sql_varchar"},
                    userId={value=arguments.userId,cfsqltype="cf_sql_integer"}
                });
        }
    }

    public string function cookieHeader(required struct credential) {
        if (structIsEmpty(parse(arguments.credential.cookieValue))) throw(type="BusinessRememberCookie",message="Invalid cookie credential");
        return variables.cookieName & "=" & arguments.credential.cookieValue
            & "; Max-Age=2592000; Expires=" & getHttpTimeString(arguments.credential.expiresAt)
            & "; Path=/; Secure; HttpOnly; SameSite=Lax";
    }

    public string function expireCookieHeader() {
        return variables.cookieName & "=; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Path=/; Secure; HttpOnly; SameSite=Lax";
    }
}
