component output=false {
    public any function init(required any store,required any policy){variables.store=store;variables.policy=policy;return this;}
    private struct function n(required any value){return {value=value,cfsqltype='cf_sql_bigint'};}
    private struct function t(required string value){return {value=value,cfsqltype='cf_sql_varchar'};}
    private struct function actor(required struct identity){
        var id=variables.policy.identifier(structKeyExists(identity,'id')?identity.id:0);
        if(!structKeyExists(identity,'emailVerified') || !isBoolean(identity.emailVerified) || !identity.emailVerified || !structKeyExists(identity,'email') || !isSimpleValue(identity.email))variables.policy.fail('Forbidden','Verified identity required');
        var current=variables.store.actor(id);
        var email=variables.store.execute('SELECT email FROM tb_usuarios WHERE id=:id',{id=n(id)});
        if(structIsEmpty(current) || !email.recordCount || compare(lCase(trim(email.email[1])),lCase(trim(identity.email)))!=0)variables.policy.fail('Forbidden','Current identity required');
        return {id=id,isAdmin=current.is_admin};
    }
    private struct function managerAccess(required struct identity,required numeric managerId){
        var current=actor(identity);var id=variables.policy.identifier(managerId);
        var account=variables.store.account(id);var config=variables.store.manager(id);var membership=variables.store.membership(current.id,id);
        if(structIsEmpty(account) || account.status!='ATIVA' || structIsEmpty(config) || !config.habilitada || structIsEmpty(membership) || membership.status!='ATIVO' || !listFind('OWNER,ADMIN,OPERADOR,VISUALIZADOR',membership.papel))variables.policy.fail('Forbidden','Direct manager membership required');
        return {actorId=current.id,managerId=id,member=membership,canManage=listFind('OWNER,ADMIN',membership.papel)>0};
    }
    private struct function pageFilter(required struct filters,string states=''){
        var page=1;var search='';var state='';
        if(structKeyExists(filters,'page')){
            if(!isSimpleValue(filters.page) || !reFind('^[1-9][0-9]{0,5}$',filters.page & ''))variables.policy.fail('Validation','Invalid page');
            page=val(filters.page);
        }
        if(structKeyExists(filters,'search')){
            if(!isSimpleValue(filters.search) || len(trim(filters.search))>160)variables.policy.fail('Validation','Invalid search');
            search=trim(filters.search);
        }
        if(structKeyExists(filters,'state')){
            if(!isSimpleValue(filters.state) || (len(filters.state) && !listFind('ATIVO,AGUARDANDO_CONTA,PENDENTE_GESTORA,SUSPENSO,REVOGADO,RECUSADO,PENDENTE,ACEITO,CANCELADO,EXPIRADO,SUCCESS,DENIED,CONFLICT,ERROR,INATIVO,CONVIDADO,BLOQUEADO',filters.state)))variables.policy.fail('Validation','Invalid state');
            state=filters.state;
        }
        return {page=page,search=search,state=state};
    }
    private array function rows(required query queryRows){var output=[];for(var row in queryRows)arrayAppend(output,row);return output;}
    private struct function page(required string sql,required struct params,required struct filters){
        var count=variables.store.execute('SELECT count(*) AS total FROM (' & sql & ') workspace_count',params);
        var offset=(filters.page-1)*25;var sorted=sql & ' ORDER BY sort_name,id LIMIT 25 OFFSET :offset';
        params.offset=n(offset);
        return {items=rows(variables.store.execute(sorted,params)),page=filters.page,pageSize=25,total=val(count.total[1])};
    }
    public struct function listClients(required struct identity,required numeric managerId,struct filters={}){
        var access=managerAccess(identity,managerId);var f=pageFilter(filters,'ATIVO,AGUARDANDO_CONTA,SUSPENSO,REVOGADO,RECUSADO');
        var params={manager=n(access.managerId),actor=n(access.actorId),search=t(f.search),state=t(f.state)};
        var sql="SELECT v.id_vinculo AS id,v.id_vinculo AS relationshipId,v.version,v.origem AS origin,c.id_conta AS clientId,c.nome_conta AS clientName,c.status AS clientStatus,v.status AS status,c.nome_conta AS sort_name, " &
            "(EXISTS(SELECT 1 FROM tb_conta_usuarios own WHERE own.id_conta=c.id_conta AND own.papel='OWNER') OR EXISTS(SELECT 1 FROM tb_conta_gestao_convites accepted WHERE accepted.id_conta=c.id_conta AND accepted.tipo='TITULAR' AND accepted.status='ACEITO') OR EXISTS(SELECT 1 FROM tb_conta_gestao_auditoria confirmed WHERE confirmed.id_conta_cliente=c.id_conta AND confirmed.acao='owner.accept' AND confirmed.resultado='SUCCESS')) AS ownerConfirmed " &
            "FROM tb_conta_gestao_vinculos v JOIN tb_contas c ON c.id_conta=v.id_conta_cliente " &
            "WHERE v.id_conta_gestora=:manager AND (v.status IN('ATIVO','SUSPENSO','PENDENTE_GESTORA') OR (v.status='REVOGADO' AND (v.id_usuario_aprovador_cliente IS NOT NULL OR v.origem='CRIACAO_GESTORA')) OR (v.origem='CRIACAO_GESTORA' AND v.status IN('AGUARDANDO_CONTA','RECUSADO'))) " &
            "AND (:state='' OR v.status=:state) AND (:search='' OR position(lower(:search) in lower(c.nome_conta))>0) ";
        if(!access.canManage)sql &= "AND v.status='ATIVO' AND EXISTS(SELECT 1 FROM tb_conta_gestao_equipe e WHERE e.id_vinculo=v.id_vinculo AND e.id_conta_usuario=:member AND e.status='ATIVO') ";
        if(!access.canManage)params.member=n(access.member.id_conta_usuario);
        var result=page(sql,params,f);
        if(access.canManage)for(var item in result.items){
            item.pendingFields={};
            if(item.status=='AGUARDANDO_CONTA'){
                var registration=variables.store.execute("SELECT nome_empresa,tipo_titular,documento,nome_responsavel,email_responsavel,telefone_responsavel,site,cidade,estado,tipo_prestador,mensagem FROM tb_conta_cadastro_solicitacoes WHERE gestao_vinculo_id=:relation AND origem_gestora_id=:manager AND id_conta=:client AND status='PENDENTE'",{relation=n(item.relationshipId),manager=n(access.managerId),client=n(item.clientId)});
                if(registration.recordCount)item.pendingFields=rows(registration)[1];
            }
        }
        return result;
    }
    public struct function listTeam(required struct identity,required numeric managerId,struct filters={}){
        var access=managerAccess(identity,managerId);var f=pageFilter(filters,'ATIVO,INATIVO,CONVIDADO,BLOQUEADO');
        var params={manager=n(access.managerId),actor=n(access.actorId),search=t(f.search),state=t(f.state)};
        var sql="SELECT m.id_conta_usuario AS id,m.id_conta_usuario AS membershipId,u.id AS userId,u.name AS memberName,u.email,m.papel AS role,m.status,u.name AS sort_name " &
            "FROM tb_conta_usuarios m JOIN tb_usuarios u ON u.id=m.id_usuario WHERE m.id_conta=:manager AND m.papel IN('OWNER','ADMIN','OPERADOR','VISUALIZADOR') " &
            "AND (:state='' OR CAST(m.status AS text)=:state) AND (:search='' OR position(lower(:search) in lower(u.name))>0 OR position(lower(:search) in lower(u.email))>0) ";
        if(!access.canManage)sql &= 'AND m.id_usuario=:actor ';
        var result=page(sql,params,f);
        for(var member in result.items){
            member.assignments=rows(variables.store.execute("SELECT e.id_equipe AS assignmentId,e.version,v.id_vinculo AS relationshipId,c.nome_conta AS clientName FROM tb_conta_gestao_equipe e JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=e.id_vinculo JOIN tb_contas c ON c.id_conta=v.id_conta_cliente WHERE e.id_conta_usuario=:member AND e.status='ATIVO' AND v.id_conta_gestora=:manager AND v.status='ATIVO' ORDER BY c.nome_conta,e.id_equipe",{member=n(member.membershipId),manager=n(access.managerId)}));
        }
        return result;
    }
    public struct function listInvites(required struct identity,required numeric managerId,struct filters={}){
        var access=managerAccess(identity,managerId);var f=pageFilter(filters,'PENDENTE,ACEITO,RECUSADO,CANCELADO,EXPIRADO');
        var params={manager=n(access.managerId),actor=n(access.actorId),search=t(f.search),state=t(f.state)};
        // Outbound proposals to an unaccepted existing client are deliberately absent.
        var sql="SELECT i.id_convite AS id,i.tipo AS type,i.status,i.expires_at AS expiresAt,i.email_destinatario AS recipient,c.nome_conta AS clientName,v.id_vinculo AS relationshipId,i.created_at AS sort_name " &
            "FROM tb_conta_gestao_convites i JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=i.id_vinculo JOIN tb_contas c ON c.id_conta=v.id_conta_cliente " &
            "WHERE v.id_conta_gestora=:manager AND (v.status IN('ATIVO','SUSPENSO','PENDENTE_GESTORA') OR (v.status='REVOGADO' AND (v.id_usuario_aprovador_cliente IS NOT NULL OR v.origem='CRIACAO_GESTORA')) OR (v.origem='CRIACAO_GESTORA' AND v.status IN('AGUARDANDO_CONTA','RECUSADO'))) " &
            "AND (:state='' OR i.status=:state) AND (:search='' OR position(lower(:search) in lower(c.nome_conta))>0) ";
        if(!access.canManage){
            sql &= "AND i.id_usuario_autor=:actor AND v.status='ATIVO' AND EXISTS(SELECT 1 FROM tb_conta_gestao_equipe e WHERE e.id_vinculo=v.id_vinculo AND e.id_conta_usuario=:member AND e.status='ATIVO') ";
            params.member=n(access.member.id_conta_usuario);
        }
        return page(sql,params,f);
    }
    public struct function listAudit(required struct identity,required numeric managerId,struct filters={}){
        var access=managerAccess(identity,managerId);var f=pageFilter(filters,'SUCCESS,DENIED,CONFLICT,ERROR');
        var params={manager=n(access.managerId),actor=n(access.actorId),search=t(f.search),state=t(f.state)};
        var sql="SELECT a.id_auditoria AS id,a.acao AS action,a.resultado AS status,a.created_at AS happenedAt,u.name AS actorName,c.nome_conta AS clientName,a.created_at AS sort_name " &
            "FROM tb_conta_gestao_auditoria a JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=a.id_vinculo JOIN tb_contas c ON c.id_conta=v.id_conta_cliente JOIN tb_usuarios u ON u.id=a.id_usuario_ator " &
            "WHERE a.id_conta_gestora=:manager AND (v.status IN('ATIVO','SUSPENSO','PENDENTE_GESTORA') OR (v.status='REVOGADO' AND (v.id_usuario_aprovador_cliente IS NOT NULL OR v.origem='CRIACAO_GESTORA')) OR (v.origem='CRIACAO_GESTORA' AND v.status IN('AGUARDANDO_CONTA','RECUSADO'))) " &
            "AND (:state='' OR a.resultado=:state) AND (:search='' OR position(lower(:search) in lower(c.nome_conta))>0) ";
        if(!access.canManage){
            sql &= "AND a.id_usuario_ator=:actor AND v.status='ATIVO' AND EXISTS(SELECT 1 FROM tb_conta_gestao_equipe e WHERE e.id_vinculo=v.id_vinculo AND e.id_conta_usuario=:member AND e.status='ATIVO') ";
            params.member=n(access.member.id_conta_usuario);
        }
        return page(sql,params,f);
    }
    public array function listClientManagers(required struct identity,required numeric clientId){
        var current=actor(identity);var id=variables.policy.identifier(clientId);var direct=variables.store.membership(current.id,id);
        if(structIsEmpty(direct) || direct.status!='ATIVO' || direct.papel!='OWNER')variables.policy.fail('Forbidden','Direct client owner required');
        var result=variables.store.execute("SELECT v.id_vinculo AS relationshipId,v.version,v.status,m.id_conta AS managerId,m.nome_conta AS managerName,g.classificacao AS classification " &
            "FROM tb_conta_gestao_vinculos v JOIN tb_contas m ON m.id_conta=v.id_conta_gestora JOIN tb_conta_gestoras g ON g.id_conta=m.id_conta " &
            "WHERE v.id_conta_cliente=:client AND v.status IN('ATIVO','SUSPENSO','REVOGADO','PENDENTE_CLIENTE') ORDER BY m.nome_conta,m.id_conta",{client=n(id)});
        return rows(result);
    }
    public struct function configureManager(required struct identity,required numeric accountId,required boolean enabled,required string classification,required numeric expectedVersion){
        var current=actor(identity);var id=variables.policy.identifier(accountId);
        if(!isSimpleValue(expectedVersion) || !reFind('^(0|[1-9][0-9]*)$',expectedVersion & ''))variables.policy.fail('Validation','Invalid version');
        var expected=val(expectedVersion);
        if(!structKeyExists(identity,'accessMode') || identity.accessMode!='DIRECT' || !current.isAdmin)variables.policy.fail('Forbidden','Real direct administrator required');
        if(!listFind('AGENCIA,TICKETEIRA,OUTROS',classification))variables.policy.fail('Validation','Invalid classification');
        var output={};
        transaction isolation='read_committed' {
            variables.store.lockScope([id],[current.id]);current=actor(identity);
            var account=variables.store.account(id);
            if(!current.isAdmin || identity.accessMode!='DIRECT' || structIsEmpty(account) || account.status!='ATIVA')variables.policy.fail('Forbidden','Active account and direct administrator required');
            var config=variables.store.manager(id);if((structIsEmpty(config)?0:config.version)!=expected)variables.policy.fail('Conflict','Manager configuration changed');
            if(structIsEmpty(config))variables.store.execute("INSERT INTO tb_conta_gestoras(id_conta,classificacao,habilitada,id_usuario_autor) VALUES(:id,:class,:enabled,:actor)",{id=n(id),class=t(classification),enabled={value=enabled,cfsqltype='cf_sql_boolean'},actor=n(current.id)});
            else variables.store.execute("UPDATE tb_conta_gestoras SET classificacao=:class,habilitada=:enabled,version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_conta=:id",{id=n(id),class=t(classification),enabled={value=enabled,cfsqltype='cf_sql_boolean'}});
            config=variables.store.manager(id);output={status=config.habilitada?'ENABLED':'DISABLED',id=id,version=config.version};
        }
        return output;
    }
    public struct function pendingOwnerRegistration(required struct identity){
        var current=actor(identity);
        var result=variables.store.execute("SELECT sol.id_solicitacao,sol.id_conta,coalesce(c.nome_conta,sol.nome_empresa) AS nome_empresa,sol.tipo_prestador,sol.status,c.status AS status_conta,sol.data_criacao,sol.nome_responsavel,sol.email_responsavel,sol.origem_gestora_id " &
            "FROM tb_conta_cadastro_solicitacoes sol JOIN tb_contas c ON c.id_conta=sol.id_conta JOIN tb_conta_usuarios owner_member ON owner_member.id_conta=c.id_conta AND owner_member.id_usuario=:actor AND owner_member.papel='OWNER' AND owner_member.status='ATIVO' " &
            "JOIN tb_conta_gestao_convites accepted ON accepted.id_conta=c.id_conta AND accepted.id_vinculo=sol.gestao_vinculo_id AND accepted.tipo='TITULAR' AND accepted.status='ACEITO' AND accepted.id_usuario_aceite=:actor " &
            "WHERE sol.origem_gestora_id IS NOT NULL AND sol.status='PENDENTE' AND c.status='PENDENTE' ORDER BY sol.id_solicitacao DESC LIMIT 1",{actor=n(current.id)});
        return result.recordCount?rows(result)[1]:{};
    }
}
