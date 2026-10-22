component output="false" {
    private void function deny(required string message) {
        throw(type="BusinessDevLogin.Denied",message=arguments.message);
    }

    private boolean function flag(required struct row,required string name) {
        if(!structKeyExists(arguments.row,arguments.name) OR isNull(arguments.row[arguments.name])) return false;
        var value=arguments.row[arguments.name];
        return isSimpleValue(value) AND (isBoolean(value) ? value : listFindNoCase("1,true,t,yes,sim",trim(value & "")) GT 0);
    }

    private boolean function validId(required struct row) {
        return structKeyExists(arguments.row,"id") AND isSimpleValue(arguments.row.id)
            AND reFind("^[1-9][0-9]{0,9}$",arguments.row.id & "") GT 0 AND val(arguments.row.id) LTE 2147483647;
    }

    public struct function createHandoff(required struct actor,required struct target,required string secret,
        required string method,required string expectedCsrf,required string postedCsrf,required string confirmed,
        boolean simulationActive=false) {
        if(uCase(arguments.method) NEQ "POST") deny("O login no DEV exige uma solicitação POST.");
        if(!len(arguments.expectedCsrf) OR len(arguments.postedCsrf) GT 256
            OR !createObject("java","java.security.MessageDigest").isEqual(
                charsetDecode(arguments.expectedCsrf,"UTF-8"),charsetDecode(arguments.postedCsrf,"UTF-8"))) {
            deny("A sessão do formulário expirou. Recarregue a página e tente novamente.");
        }
        if(compare(arguments.confirmed,"1") NEQ 0) deny("Confirme a abertura da sessão de suporte no DEV.");
        if(arguments.simulationActive OR !validId(arguments.actor) OR !flag(arguments.actor,"is_admin")) {
            deny("Somente administradores globais, fora da simulação de contas, podem iniciar o login no DEV.");
        }
        if(!flag(arguments.actor,"gestao_ativo") OR flag(arguments.actor,"gestao_excluido") OR !flag(arguments.actor,"has_active_page")) {
            deny("Sua conta precisa estar ativa e vinculada a um perfil ativo no Road Runners.");
        }
        if(!validId(arguments.target) OR !flag(arguments.target,"gestao_ativo") OR flag(arguments.target,"gestao_excluido")) {
            deny("A conta escolhida não foi encontrada, está inativa ou foi excluída.");
        }
        if(!flag(arguments.target,"has_active_page")) deny("A conta escolhida precisa ter um perfil ativo para ser carregada no DEV.");
        if(!structKeyExists(arguments.target,"email") OR !isSimpleValue(arguments.target.email) OR !isValid("email",trim(arguments.target.email))) {
            deny("O e-mail da conta escolhida não é válido para o login no DEV.");
        }
        if(len(trim(arguments.secret)) LT 32 OR compareNoCase(trim(arguments.secret),hash("RoadRunners::handoff::roadrunners.run::v1","SHA-256")) EQ 0) {
            deny("A credencial segura de acesso ao DEV não está configurada no servidor.");
        }
        var issued=now();
        var expires=dateAdd("s",180,issued);
        var payload={issuedAt=dateTimeFormat(issued,"yyyy-mm-dd HH:nn:ss"),expiresAt=dateTimeFormat(expires,"yyyy-mm-dd HH:nn:ss"),
            origin="business",target="dev",originalUsuarioId=val(arguments.actor.id),impersonateUsuarioId=val(arguments.target.id),
            impersonateEmail=trim(arguments.target.email),redirectPath="/atleta/",nonce=createUUID()};
        var encoded=toBase64(serializeJSON(payload),"UTF-8");
        var token=encoded & "." & lCase(hmac(encoded,arguments.secret,"HmacSHA256"));
        return {url="https://dev.roadrunners.run/?action=handoff_consume&token=" & urlEncodedFormat(token),
            token=token,expiresAt=payload.expiresAt};
    }
}
