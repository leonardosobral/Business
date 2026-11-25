component output=false {
    variables.datasource='runner_dba';
    public any function init(string datasource='runner_dba') {variables.datasource=datasource;return this;}
    private void function deny(string message='Este acesso de suporte não está disponível.') {throw(type='BusinessSupport.Forbidden',message=message);}
    private numeric function identifier(required any value) {
        if(!isSimpleValue(value)||!reFind('^[1-9][0-9]{0,9}$',value & '')||val(value)>2147483647)deny();return val(value);
    }
    private struct function user(required any id) {
        var rows=queryExecute('SELECT u.id,u.name,u.email,coalesce(u.imagem_usuario,'''') imagem_usuario,coalesce(u.is_admin,false) is_admin,coalesce(u.is_dev,false) is_dev,coalesce(u.is_email_verified,false) email_verified,coalesce(g.ativo,true) active,coalesce(g.excluido,false) deleted FROM public.tb_usuarios u LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id WHERE u.id=:id',
            {id={value=identifier(id),cfsqltype='cf_sql_integer'}},{datasource=variables.datasource,timeout=10});
        return rows.recordCount?queryGetRow(rows,1):{};
    }
    private boolean function active(required struct row) {return !structIsEmpty(row)&&row.active&&!row.deleted;}
    private boolean function same(required string expected,required any supplied) {
        return isSimpleValue(supplied)&&len(expected)==64&&len(supplied & '')==64&&createObject('java','java.security.MessageDigest').isEqual(charsetDecode(expected,'UTF-8'),charsetDecode(supplied & '','UTF-8'));
    }
    private string function secret() {return lCase(hash(generateSecretKey('AES',256),'SHA-256'));}
    public boolean function internalContext(required struct state) {
        return !(structKeyExists(state,'businessSupportSession')
            ||(structKeyExists(state,'businessSimulatedAccountId')&&val(state.businessSimulatedAccountId)>0)
            ||(structKeyExists(state,'businessAccessSelectionInvalid')&&state.businessAccessSelectionInvalid)
            ||(structKeyExists(state,'businessAccessSelection')&&(!isStruct(state.businessAccessSelection)||!structKeyExists(state.businessAccessSelection,'accessMode')||state.businessAccessSelection.accessMode!='DIRECT')));
    }
    public struct function target(required struct principal,required struct state,required any targetId) {
        if(!structKeyExists(principal,'id')||!internalContext(state))deny('Volte à Administração RunnerHub antes de iniciar o acesso de suporte.');
        var actor=user(principal.id);var selected=user(targetId);
        if(!active(actor)||!actor.is_admin)deny('Somente um administrador global ativo pode iniciar o acesso de suporte.');
        if(!active(selected)||selected.is_admin||selected.is_dev||selected.id==actor.id||!new services.EmailAddress().isValidAddress(selected.email))deny('Escolha um usuário ativo sem privilégios de Admin ou Dev.');
        return selected;
    }
    public string function startToken(required struct state,required any targetId) {
        if(!structKeyExists(state,'businessSupportCsrf'))state.businessSupportCsrf=secret();
        return lCase(hmac('start:' & identifier(targetId),state.businessSupportCsrf,'HmacSHA256','UTF-8'));
    }
    // Discard every previous identity's cached state and CSRF token; retain only the
    // verified operator login and its own remembered-device binding, never the target's.
    private void function clearContext(required struct state) {
        for(var key in structKeyArray(state))if(!listFindNoCase('sessionid,cfid,cftoken,urltoken,businessAuthenticatedIdentity,businessRememberSelector,businessRememberCheckedAt',key))structDelete(state,key,false);
    }
    private void function audit(required struct support,required string event,required struct meta) {
        queryExecute('INSERT INTO public.tb_usuarios_gestao_auditoria(id_usuario_alvo,id_usuario_autor,acao,dados_anteriores,dados_novos,endereco_ip,user_agent) VALUES(:target,:actor,:event,CAST(:before AS jsonb),CAST(:after AS jsonb),:ip,:agent)',{
            target={value=support.targetId,cfsqltype='cf_sql_integer'},actor={value=support.actorId,cfsqltype='cf_sql_integer'},event={value=event,cfsqltype='cf_sql_varchar'},
            before={value='{}',cfsqltype='cf_sql_longvarchar'},after={value=serializeJSON({supportId=support.id,operator=support.actorId,user=support.targetId,expiresAt=support.expiresAt,method=structKeyExists(meta,'method')?left(meta.method,10):'',path=structKeyExists(meta,'path')?left(listFirst(meta.path,'?'),500):'',reason=structKeyExists(meta,'reason')?left(meta.reason,100):'suporte_tecnico'}),cfsqltype='cf_sql_longvarchar'},
            ip={value=structKeyExists(meta,'ip')?left(meta.ip,64):'',cfsqltype='cf_sql_varchar'},agent={value=structKeyExists(meta,'agent')?left(meta.agent,512):'',cfsqltype='cf_sql_varchar'}
        },{datasource=variables.datasource,timeout=10});
    }
    public struct function begin(required struct state,required struct principal,required any targetId,required any csrf,required string method,required string confirmed,struct meta={}) {
        if(method!='POST'||confirmed!='1'||!structKeyExists(state,'businessSupportCsrf')||!same(startToken(state,targetId),csrf))deny('Confirme novamente o acesso de suporte.');
        var selected=target(principal,state,targetId);
        var support={id=createUUID(),actorId=principal.id,targetId=selected.id,targetEmail=selected.email,expiresAt=dateAdd('n',30,now()),stopToken=secret()};
        audit(support,'business_suporte_inicio',meta);
        clearContext(state);state.businessSupportSession=support;
        return duplicate(support);
    }
    public struct function current(required struct state,required struct principal,struct meta={}) {
        if(!structKeyExists(state,'businessSupportSession'))return {};
        var support=state.businessSupportSession;
        if(!isStruct(support)||!structKeyExists(support,'actorId')||!structKeyExists(principal,'id')||support.actorId!=principal.id)deny();
        var actor=user(support.actorId);var selected=user(support.targetId);var reason='';
        if(!active(actor)||!actor.is_admin)reason='operador_indisponivel';
        else if(!active(selected)||selected.is_admin||selected.is_dev||compareNoCase(selected.email,support.targetEmail)!=0)reason='usuario_indisponivel';
        else if(dateCompare(now(),support.expiresAt)>=0)reason='expirada';
        if(len(reason)) {
            var ended=duplicate(meta);ended.reason=reason;audit(support,'business_suporte_fim',ended);clearContext(state);
            if(reason=='operador_indisponivel')new services.BusinessAuthSession().clear(state);
            return {ended=true,reason=reason};
        }
        return {ended=false,id=support.id,actorId=support.actorId,targetId=support.targetId,expiresAt=support.expiresAt,stopToken=support.stopToken,
            identity={id=selected.id,name=selected.name,email=selected.email,imagem_usuario=selected.imagem_usuario,emailVerified=selected.email_verified,supportAccess=true}};
    }
    public void function recordRequest(required struct state,struct meta={}) {
        if(!structKeyExists(state,'businessSupportSession'))deny();audit(state.businessSupportSession,'business_suporte_requisicao',meta);
    }
    public void function finish(required struct state,required struct principal,required any csrf,required string method,struct meta={}) {
        if(method!='POST'||!structKeyExists(state,'businessSupportSession')||!structKeyExists(principal,'id')||state.businessSupportSession.actorId!=principal.id||!same(state.businessSupportSession.stopToken,csrf))deny('Recarregue a página antes de voltar ao administrador.');
        audit(state.businessSupportSession,'business_suporte_fim',meta);clearContext(state);
    }
    public void function logout(required struct state,struct meta={}) {
        try {if(structKeyExists(state,'businessSupportSession'))audit(state.businessSupportSession,'business_suporte_fim',meta);}
        finally {clearContext(state);}
    }
}
