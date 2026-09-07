component output=false {
    // jose4j is supplied by Adobe ColdFusion. A resolver may be injected by
    // offline tests only; HTTP inputs never select a key, issuer or audience.
    public any function init(required string clientId, any keyResolver) {
        variables.clientId=arguments.clientId;
        if (structKeyExists(arguments,"keyResolver")) {
            variables.keyResolver=arguments.keyResolver;
        } else {
            var jwks=createObject("java","org.jose4j.jwk.HttpsJwks")
                .init("https://www.googleapis.com/oauth2/v3/certs");
            jwks.setDefaultCacheDuration(javacast("long",3600));
            jwks.setRefreshReprieveThreshold(javacast("long",60000));
            var transport=createObject("java","org.jose4j.http.Get").init();
            transport.setConnectTimeout(javacast("int",4000));
            transport.setReadTimeout(javacast("int",4000));
            transport.setRetries(javacast("int",0));
            jwks.setSimpleHttpGet(transport);
            variables.keyResolver=createObject("java","org.jose4j.keys.resolvers.HttpsJwksVerificationKeyResolver").init(jwks);
        }
        return this;
    }

    public struct function verify(required string token, required string expectedNonce) {
        if (!len(arguments.expectedNonce) || len(arguments.token) GT 16384 || listLen(arguments.token,".") != 3)
            throw(type="BusinessAuth.InvalidToken",message="Token Google inválido.");
        var builder=createObject("java","org.jose4j.jwt.consumer.JwtConsumerBuilder").init();
        builder.setRequireExpirationTime();
        builder.setRequireSubject();
        builder.setExpectedAudience(javacast("string[]",[variables.clientId]));
        builder.setExpectedIssuers(true,javacast("string[]",["https://accounts.google.com","accounts.google.com"]));
        builder.setAllowedClockSkewInSeconds(javacast("int",30));
        builder.setVerificationKeyResolver(variables.keyResolver);
        var permit=createObject("java","org.jose4j.jwa.AlgorithmConstraints$ConstraintType").PERMIT;
        var constraints=createObject("java","org.jose4j.jwa.AlgorithmConstraints")
            .init(permit,javacast("string[]",["RS256"]));
        builder.setJwsAlgorithmConstraints(constraints);
        var claims=builder.build().processToClaims(arguments.token);
        var data=deserializeJSON(claims.toJson());
        if (!structKeyExists(data,"nonce") || !isSimpleValue(data.nonce)
            || compare(data.nonce,arguments.expectedNonce) != 0
            || !structKeyExists(data,"email_verified") || !isBoolean(data.email_verified) || !data.email_verified
            || !structKeyExists(data,"email") || !isValid("email",data.email)
            || !structKeyExists(data,"sub") || !len(trim(data.sub)))
            throw(type="BusinessAuth.InvalidClaims",message="Identidade Google não confirmada.");
        return {sub=data.sub,email=lCase(trim(data.email)),
            name=structKeyExists(data,"name") && isSimpleValue(data.name) && len(trim(data.name)) ? trim(data.name) : data.email,
            picture=structKeyExists(data,"picture") && isSimpleValue(data.picture) && reFindNoCase("^https://",data.picture) ? data.picture : ""};
    }
}
