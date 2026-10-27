component output=false {
    public string function token(required struct csrfState,required numeric actorId) {
        if(!structKeyExists(csrfState,'rrTeamsCsrf')||!structKeyExists(csrfState,'rrTeamsCsrfActor')||csrfState.rrTeamsCsrfActor!=actorId){csrfState.rrTeamsCsrf=lCase(hash(generateSecretKey('AES',256),'SHA-256'));csrfState.rrTeamsCsrfActor=actorId;}
        return csrfState.rrTeamsCsrf;
    }
    public boolean function valid(required struct csrfState,required struct submitted,required numeric actorId) {
        if(!structKeyExists(csrfState,'rrTeamsCsrfActor')||csrfState.rrTeamsCsrfActor!=actorId||!structKeyExists(csrfState,'rrTeamsCsrf')||!structKeyExists(submitted,'csrf')||!isSimpleValue(submitted.csrf))return false;
        return createObject('java','java.security.MessageDigest').isEqual(charsetDecode(csrfState.rrTeamsCsrf,'UTF-8'),charsetDecode(submitted.csrf & '','UTF-8'));
    }
    public string function text(required struct input,required string key,string fallback='') {if(!structKeyExists(input,key))return fallback;if(!isSimpleValue(input[key]))throw(type='Teams.Validation',message='Solicitação inválida.');return trim(input[key] & '');}
    public numeric function number(required struct input,required string key,numeric fallback=0) {var v=text(input,key,fallback & '');if(!reFind('^[0-9]{1,14}$',v))throw(type='Teams.Validation',message='Solicitação inválida.');return val(v);}
}
