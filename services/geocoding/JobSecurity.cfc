component output=false {
    public struct function verify(required string method,required string body,required struct headers,required string secret) {
        var denied={allowed=false,http=401,status="invalid_signature"};var stamp="";var signature="";var expected="";
        if(uCase(method) NEQ "POST")return {allowed=false,http=405,status="method_not_allowed"};
        if(!len(secret))return {allowed=false,http=503,status="not_configured"};
        if(len(body) GT 8192)return {allowed=false,http=400,status="invalid_request"};
        if(!structKeyExists(headers,"X-RR-Handoff-Timestamp") OR !structKeyExists(headers,"X-RR-Handoff-Signature"))return denied;
        stamp=headers["X-RR-Handoff-Timestamp"];signature=headers["X-RR-Handoff-Signature"];
        if(!isSimpleValue(stamp) OR !isSimpleValue(signature) OR !isDate(stamp) OR !reFindNoCase("^[a-f0-9]{64}$",signature))return denied;
        try {
            if(abs(dateDiff("s",parseDateTime(stamp),now())) GT 300)return denied;
            expected=lCase(hmac(stamp & "." & body,secret,"HmacSHA256"));
            if(!createObject("java","java.security.MessageDigest").isEqual(binaryDecode(expected,"hex"),binaryDecode(signature,"hex")))return denied;
        } catch(any invalidSignature){return denied;}
        return {allowed=true,http=200,status="authorized"};
    }
}
