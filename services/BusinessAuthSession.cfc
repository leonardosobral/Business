component output=false {
    // Authentication is server-owned. Legacy ID cookies and cadastro structures
    // created before signature validation are deliberately not upgraded.
    public struct function identity(required struct state) {
        if (!structKeyExists(arguments.state, "businessAuthenticatedIdentity")
            || !isStruct(arguments.state.businessAuthenticatedIdentity)) return {};
        var principal = arguments.state.businessAuthenticatedIdentity;
        if (!structKeyExists(principal,"version") || principal.version != 1
            || !structKeyExists(principal,"id") || !isValid("integer",principal.id) || principal.id LTE 0
            || !structKeyExists(principal,"sub") || !len(principal.sub)
            || !structKeyExists(principal,"email") || !isValid("email",principal.email)
            || !structKeyExists(principal,"name")) return {};
        return duplicate(principal);
    }

    public void function clear(required struct state) {
        for (var key in structKeyArray(arguments.state)) {
            if (left(key,8) == "business" || left(key,14) == "cadastroGoogle"
                || findNoCase("csrf",key) || key == "researchLoginRedirect"
                || key == "agendaManagementFeedToken" || key == "stravaMigrationFlash") structDelete(arguments.state,key,false);
        }
    }

    public void function establish(required struct state, required numeric userId, required struct claims) {
        clear(arguments.state);
        arguments.state.businessAuthenticatedIdentity = {
            version=1,id=arguments.userId,sub=arguments.claims.sub,
            email=lCase(trim(arguments.claims.email)),name=arguments.claims.name,
            imagem_usuario=arguments.claims.picture,authenticatedAt=now()
        };
        arguments.state.cadastroGoogleIdentity = {
            sub=arguments.claims.sub,email=lCase(trim(arguments.claims.email)),
            name=arguments.claims.name,picture=arguments.claims.picture,authenticatedAt=now()
        };
    }
}
