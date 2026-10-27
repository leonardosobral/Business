component output=false {
    // Caller holds the issuer lock. Only opaque, server-issued browser proofs authenticate Teams.
    public struct function browser(required any protocol,required any accounts,required struct browserCookies) {
        if(!structKeyExists(browserCookies,'__Host-rr-comparador-identity')||!isSimpleValue(browserCookies['__Host-rr-comparador-identity']))return {};
        var binding=browserCookies['__Host-rr-comparador-identity'] & '';var identity=protocol.browserIdentity(binding);
        if(structIsEmpty(identity))return {};
        var current=accounts.byId(identity.id);
        if(structIsEmpty(current)||compare(current.version & '',identity.version & '')!=0){protocol.revokeBrowser(binding);return {};}
        return identity;
    }
    public string function returnPath(required string value) {
        if(len(value)>700||find(chr(10),value)||find(chr(13),value)||find(chr(92),value)||!reFind('^/teams/(meu-team/|convidar/)?(\?[^##]*)?$',value))return '/teams/meu-team/';return value;
    }
    private struct function typed(required struct values){var bound={};for(var key in values)bound[key]={value=values[key],cfsqltype=listFind('id,page',key)?'cf_sql_integer':'cf_sql_varchar'};return bound;}
    public numeric function account(required struct claims,string datasource='runner_dba') {
        if(!structKeyExists(claims,'email_verified')||!isBoolean(claims.email_verified)||!claims.email_verified||!structKeyExists(claims,'email')||!isValid('email',claims.email)||!structKeyExists(claims,'sub')||!len(claims.sub)||len(claims.sub)>250)throw(type='Teams.Forbidden',message='Identidade Google inválida.');
        var name=structKeyExists(claims,'name')?left(claims.name,200):listFirst(claims.email,'@');var userId=0;
        transaction {
            var rows=queryExecute('SELECT u.id FROM public.tb_usuarios u LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id WHERE lower(u.email)=:email AND coalesce(g.ativo,true) AND NOT coalesce(g.excluido,false)',typed({email=lCase(trim(claims.email))}),{datasource=datasource});
            if(rows.recordCount)userId=rows.id[1];
            else {
                var inactive=queryExecute('SELECT id FROM public.tb_usuarios WHERE lower(email)=:email',typed({email=lCase(trim(claims.email))}),{datasource=datasource});if(inactive.recordCount)throw(type='Teams.Forbidden',message='Esta conta está inativa.');
                userId=queryExecute("INSERT INTO public.tb_usuarios(name,email,password,verification_key,is_email_verified,optin_usuario,fonte_lead) VALUES(:name,:email,:subject,:subject,true,false,'rr_teams') ON CONFLICT(email) DO UPDATE SET data_alteracao=tb_usuarios.data_alteracao RETURNING id",typed({name=name,email=lCase(trim(claims.email)),subject=claims.sub}),{datasource=datasource}).id[1];
            }
            queryExecute('SELECT id FROM public.tb_usuarios WHERE id=:id FOR UPDATE',typed({id=userId}),{datasource=datasource});
            if(!queryExecute("SELECT id_pagina FROM public.tb_paginas WHERE id_usuario_cadastro=:id AND tag_prefix='atleta' LIMIT 1",typed({id=userId}),{datasource=datasource}).recordCount){
                var tag='corredor-' & userId & '-' & lCase(left(replace(createUUID(),'-','','all'),8));
                var page=queryExecute("INSERT INTO public.tb_paginas(nome,tag_prefix,tag,id_usuario_cadastro) VALUES(:name,'atleta',:tag,:id) RETURNING id_pagina",typed({name=name,tag=tag,id=userId}),{datasource=datasource}).id_pagina[1];
                queryExecute('INSERT INTO public.tb_paginas_usuarios(id_pagina,id_usuario) VALUES(:page,:id)',typed({page=page,id=userId}),{datasource=datasource});
            }
        }return userId;
    }
}
