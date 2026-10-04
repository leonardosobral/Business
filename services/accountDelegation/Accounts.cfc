component output=false {
    public any function init(required string datasource,required any store,required any policy,any clock) {
        variables.datasource=datasource;variables.store=store;variables.policy=policy;
        if(structKeyExists(arguments,'clock')) variables.clock=arguments.clock;
        else variables.clock=function(){return dateConvert('local2utc',now());};return this;
    }
    private struct function n(required any value){return {value=value,cfsqltype='cf_sql_bigint'};}
    private struct function t(required string value){return {value=value,cfsqltype='cf_sql_varchar'};}
    private struct function instant(required date value){return t(dateTimeFormat(value,"yyyy-mm-dd'T'HH:nn:ss.l") & 'Z');}
    private struct function first(required query rows){var row={};if(rows.recordCount)for(var key in listToArray(rows.columnList))row[key]=rows[key][1];return row;}
    private string function normalizeEmail(required any value){if(!isSimpleValue(value))variables.policy.fail('Validation','Invalid email');var result=lCase(trim(value));if(len(result)>255 || !isValid('email',result))variables.policy.fail('Validation','Invalid email');return result;}
    private struct function identityChecked(required struct identity){
        var id=variables.policy.identifier(structKeyExists(identity,'id')?identity.id:0);
        if(!structKeyExists(identity,'emailVerified') || !isBoolean(identity.emailVerified) || !identity.emailVerified || !structKeyExists(identity,'email') || !isSimpleValue(identity.email))variables.policy.fail('Forbidden','Verified identity required');
        var user=variables.store.execute('SELECT email FROM tb_usuarios WHERE id=:id',{id=n(id)});
        if(structIsEmpty(variables.store.actor(id)) || !user.recordCount || compare(lCase(trim(user.email[1])),lCase(trim(identity.email)))!=0)variables.policy.fail('Forbidden','Current verified identity required');
        return {id=id,email=normalizeEmail(identity.email)};
    }
    private struct function authority(required any actorId,required any managerId){
        var account=variables.store.account(managerId);var config=variables.store.manager(managerId);var member=variables.store.membership(actorId,managerId);
        if(structIsEmpty(account) || account.status!='ATIVA' || structIsEmpty(config) || !config.habilitada || structIsEmpty(member) || member.status!='ATIVO' || !listFind('OWNER,ADMIN',member.papel))variables.policy.fail('Forbidden','Current direct manager authority required');return member;
    }
    private array function caps(required array values){
        for(var value in values)if(!isSimpleValue(value) || !arrayFind(variables.policy.catalog(),value))variables.policy.fail('Validation','Unknown capability');
        var result=variables.policy.expand(values);
        if((arrayFind(result,'ads.payments.view') || arrayFind(result,'ads.credits.purchase')) && !arrayFind(result,'ads.campaigns.view'))variables.policy.fail('Validation','Financial capability requires campaign view');return result;
    }
    private struct function fieldsChecked(required struct fields){
        var limits={nome_empresa=160,tipo_titular=2,documento=20,nome_responsavel=200,email_responsavel=255,telefone_responsavel=30,site=256,cidade=128,estado=2,tipo_prestador=80,mensagem=10000};var result={};
        for(var key in limits){if(structKeyExists(fields,key) && !isSimpleValue(fields[key]))variables.policy.fail('Validation','Invalid registration field');result[key]=structKeyExists(fields,key)?trim(fields[key]):'';}
        result.documento=reReplace(result.documento,'[^0-9]','','all');result.tipo_titular=uCase(result.tipo_titular);result.estado=uCase(left(result.estado,2));result.email_responsavel=normalizeEmail(result.email_responsavel);
        for(var key in limits)if(len(result[key])>limits[key])variables.policy.fail('Validation','Registration field too long');
        if(!len(result.nome_empresa) || !listFind('PF,PJ',result.tipo_titular) || !len(result.documento) || !len(result.nome_responsavel) || !len(result.tipo_prestador))variables.policy.fail('Validation','Required registration field missing');return result;
    }
    private struct function fieldParams(required struct fields){var params={};for(var key in fields)params[key]=t(fields[key]);return params;}
    private struct function relation(required any id){var row=variables.store.lifecycleRelationship(variables.policy.identifier(id));if(structIsEmpty(row))variables.policy.fail('NotFound','Relationship unavailable');return row;}
    private void function version(required struct row,required any expected){if(compare(row.version & '',variables.policy.identifier(expected))!=0)variables.policy.fail('Conflict','Record changed');}
    private struct function result(required struct row){return {status=row.status,id=row.id_vinculo,version=row.version};}
    private void function audit(required struct row,required any actor,required string action,string type='RELATIONSHIP',any id=0){variables.store.audit({actorId=actor,managerAccountId=row.id_conta_gestora,accountId=row.id_conta_cliente,relationshipId=row.id_vinculo},action,{type=type,id=id==0?row.id_vinculo:id});}
    private struct function registrationFor(required struct row){
        var registration=first(variables.store.execute('SELECT * FROM tb_conta_cadastro_solicitacoes WHERE gestao_vinculo_id=:id AND origem_gestora_id=:manager AND id_conta=:client FOR UPDATE',{id=n(row.id_vinculo),manager=n(row.id_conta_gestora),client=n(row.id_conta_cliente)}));
        if(structIsEmpty(registration) || row.origem!='CRIACAO_GESTORA')variables.policy.fail('Forbidden','Agency-created registration required');return registration;
    }
    private void function pending(required struct row,required struct registration){if(row.status!='AGUARDANDO_CONTA' || registration.status!='PENDENTE' || variables.store.account(row.id_conta_cliente).status!='PENDENTE')variables.policy.fail('Conflict','Registration is no longer pending');}
    private void function noConfirmedOwner(required any accountId){
        // Accepted invitation/audit is durable ownership confirmation even after membership deletion.
        var owners=variables.store.execute("SELECT 1 FROM tb_conta_usuarios WHERE id_conta=:id AND papel='OWNER' UNION ALL SELECT 1 FROM tb_conta_gestao_convites WHERE id_conta=:id AND tipo='TITULAR' AND status='ACEITO' UNION ALL SELECT 1 FROM tb_conta_gestao_auditoria WHERE id_conta_cliente=:id AND acao='owner.accept' AND resultado='SUCCESS' LIMIT 1",{id=n(accountId)});
        if(owners.recordCount)variables.policy.fail('Conflict','Ownership already confirmed');
    }
    private void function cancelOwnerInvites(required any accountId){variables.store.execute("UPDATE tb_conta_gestao_convites SET status='CANCELADO',version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_conta=:id AND tipo='TITULAR' AND status='PENDENTE'",{id=n(accountId)});}
    public struct function createClient(required struct identity,required numeric managerId,required struct fields,required array capabilities){
        var actor=identityChecked(identity);variables.policy.identifier(managerId);var data=fieldsChecked(fields);var proposed=caps(capabilities);var output={};
        if(!arrayLen(proposed))variables.policy.fail('Validation','At least one capability required');
        transaction isolation='read_committed' {
            variables.store.lockScope([managerId],[actor.id]);actor=identityChecked(identity);authority(actor.id,managerId);
            var params=fieldParams(data);params.actor=n(actor.id);params.manager=n(managerId);params.caps=t(serializeJSON(proposed));
            // Never disclose or attach an existing account. Unique conflicts also produce the same denial.
            if(variables.store.execute('SELECT 1 FROM tb_contas WHERE documento=:documento',params).recordCount)variables.policy.fail('Forbidden','Registration unavailable');
            var saved=variables.store.execute("INSERT INTO tb_contas(nome_conta,tipo_titular,documento,nome_titular,email_principal,telefone_principal,status) VALUES(:nome_empresa,CAST(:tipo_titular AS tipo_titular_conta),:documento,:nome_responsavel,:email_responsavel,NULLIF(:telefone_responsavel,''),'PENDENTE') ON CONFLICT DO NOTHING RETURNING id_conta",params);
            if(!saved.recordCount)variables.policy.fail('Forbidden','Registration unavailable');params.client=n(saved.id_conta[1]);
            var linked=variables.store.execute("INSERT INTO tb_conta_gestao_vinculos(id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante,id_usuario_aprovador_gestora,capacidades_propostas) VALUES(:manager,:client,'CRIACAO_GESTORA','AGUARDANDO_CONTA',:actor,:actor,CAST(:caps AS jsonb)) RETURNING id_vinculo",params);params.relationship=n(linked.id_vinculo[1]);
            variables.store.execute("INSERT INTO tb_conta_cadastro_solicitacoes(nome_empresa,tipo_titular,documento,nome_responsavel,email_responsavel,telefone_responsavel,site,cidade,estado,tipo_prestador,mensagem,id_usuario,id_conta,status,origem_gestora_id,gestao_vinculo_id) VALUES(:nome_empresa,CAST(:tipo_titular AS tipo_titular_conta),:documento,:nome_responsavel,:email_responsavel,NULLIF(:telefone_responsavel,''),NULLIF(:site,''),NULLIF(:cidade,''),NULLIF(:estado,''),:tipo_prestador,NULLIF(:mensagem,''),:actor,:client,'PENDENTE',:manager,:relationship)",params);
            var row=relation(linked.id_vinculo[1]);audit(row,actor.id,'client.create','ACCOUNT',row.id_conta_cliente);output=result(row);
        }return output;
    }
    public struct function updatePendingClient(required struct identity,required numeric relationshipId,required numeric expectedVersion,required struct fields){
        var actor=identityChecked(identity);var before=relation(relationshipId);var data=fieldsChecked(fields);var output={};
        try { transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_gestora,before.id_conta_cliente],[actor.id]);actor=identityChecked(identity);var row=relation(relationshipId);authority(actor.id,row.id_conta_gestora);version(row,expectedVersion);var registration=registrationFor(row);pending(row,registration);
            var params=fieldParams(data);params.id=n(row.id_conta_cliente);params.request=n(registration.id_solicitacao);params.relationship=n(row.id_vinculo);
            if(compare(data.documento,registration.documento)!=0 || compare(data.tipo_titular,registration.tipo_titular)!=0 || compare(data.nome_responsavel,registration.nome_responsavel)!=0)noConfirmedOwner(row.id_conta_cliente);
            if(variables.store.execute('SELECT 1 FROM tb_contas WHERE documento=:documento AND id_conta<>:id',params).recordCount)variables.policy.fail('Forbidden','Registration unavailable');
            if(compare(data.email_responsavel,lCase(trim(registration.email_responsavel)))!=0){noConfirmedOwner(row.id_conta_cliente);cancelOwnerInvites(row.id_conta_cliente);}
            variables.store.execute("UPDATE tb_contas SET documento=:documento,nome_conta=:nome_empresa,tipo_titular=CAST(:tipo_titular AS tipo_titular_conta),nome_titular=:nome_responsavel,email_principal=:email_responsavel,telefone_principal=NULLIF(:telefone_responsavel,''),data_atualizacao=CURRENT_TIMESTAMP WHERE id_conta=:id",params);
            variables.store.execute("UPDATE tb_conta_cadastro_solicitacoes SET documento=:documento,nome_empresa=:nome_empresa,tipo_titular=CAST(:tipo_titular AS tipo_titular_conta),nome_responsavel=:nome_responsavel,email_responsavel=:email_responsavel,telefone_responsavel=NULLIF(:telefone_responsavel,''),site=NULLIF(:site,''),cidade=NULLIF(:cidade,''),estado=NULLIF(:estado,''),tipo_prestador=:tipo_prestador,mensagem=NULLIF(:mensagem,'') WHERE id_solicitacao=:request",params);
            variables.store.execute('UPDATE tb_conta_gestao_vinculos SET version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:relationship',params);row=relation(row.id_vinculo);audit(row,actor.id,'client.update','ACCOUNT',row.id_conta_cliente);output=result(row);
        }} catch(any error) {if(structKeyExists(error,'sqlState') && error.sqlState=='23505')variables.policy.fail('Forbidden','Registration unavailable');rethrow;}return output;
    }
    public struct function reviewCreatedClient(required struct identity,required numeric registrationId,required numeric expectedVersion,required string decision,required array capabilities){
        var actor=identityChecked(identity);var selected=caps(capabilities);var output={};
        if(!structKeyExists(identity,'accessMode') || !isSimpleValue(identity.accessMode) || identity.accessMode!='DIRECT' || !variables.store.actor(actor.id).is_admin)variables.policy.fail('Forbidden','Internal review outside simulation required');
        if(!listFind('APPROVE,DECLINE',decision))variables.policy.fail('Validation','Invalid decision');
        var registration=first(variables.store.execute('SELECT * FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=:id',{id=n(variables.policy.identifier(registrationId))}));
        if(structIsEmpty(registration) || !len(registration.origem_gestora_id & '') || !len(registration.gestao_vinculo_id & ''))variables.policy.fail('Forbidden','Agency-created registration required');
        var before=relation(registration.gestao_vinculo_id);
        transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_gestora,before.id_conta_cliente],[actor.id,before.id_usuario_solicitante]);actor=identityChecked(identity);
            if(!variables.store.actor(actor.id).is_admin)variables.policy.fail('Forbidden','Current internal administrator required');
            var row=relation(before.id_vinculo);version(row,expectedVersion);registration=registrationFor(row);pending(row,registration);
            if(registration.id_solicitacao!=registrationId)variables.policy.fail('Conflict','Registration changed');
            var params={client=n(row.id_conta_cliente),id=n(row.id_vinculo),request=n(registrationId),actor=n(actor.id)};
            if(decision=='APPROVE'){
                var proposed=caps(deserializeJSON(row.capacidades_propostas));for(var cap in selected)if(!arrayFind(proposed,cap))variables.policy.fail('Forbidden','Capabilities exceed proposal');if(!arrayLen(selected))variables.policy.fail('Validation','At least one capability required');
                if(structIsEmpty(variables.store.actor(row.id_usuario_solicitante)))variables.policy.fail('Forbidden','Requester inactive');var member=authority(row.id_usuario_solicitante,row.id_conta_gestora);
                for(var cap in selected){params.cap=t(cap);if(!variables.store.execute('INSERT INTO tb_conta_gestao_permissoes SELECT :id,id_permissao FROM tb_business_permissoes WHERE codigo=:cap AND ativo=true RETURNING id_permissao',params).recordCount)variables.policy.fail('Forbidden','Capability unavailable');}
                params.member=n(member.id_conta_usuario);var assigned=variables.store.execute("INSERT INTO tb_conta_gestao_equipe(id_vinculo,id_conta_usuario,status) VALUES(:id,:member,'ATIVO') RETURNING id_equipe",params);params.team=n(assigned.id_equipe[1]);
                variables.store.execute('INSERT INTO tb_conta_gestao_equipe_permissoes SELECT :team,:id,id_permissao FROM tb_conta_gestao_permissoes WHERE id_vinculo=:id',params);
                variables.store.execute("UPDATE tb_contas SET status='ATIVA',data_atualizacao=CURRENT_TIMESTAMP WHERE id_conta=:client",params);
            }else cancelOwnerInvites(row.id_conta_cliente);
            params.status=t(decision=='APPROVE'?'ATIVO':'RECUSADO');params.registrationStatus=t(decision=='APPROVE'?'APROVADA':'RECUSADA');
            variables.store.execute('UPDATE tb_conta_cadastro_solicitacoes SET status=CAST(:registrationStatus AS status_conta_cadastro_solicitacao),id_usuario_revisor=:actor,data_revisao=CURRENT_TIMESTAMP WHERE id_solicitacao=:request',params);
            variables.store.execute('UPDATE tb_conta_gestao_vinculos SET status=:status,id_usuario_revisor=:actor,version=version+1,updated_at=CURRENT_TIMESTAMP,decided_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id',params);
            row=relation(row.id_vinculo);audit(row,actor.id,decision=='APPROVE'?'client.approve':'client.decline','ACCOUNT',row.id_conta_cliente);output=result(row);
        }return output;
    }
    public struct function inviteOwner(required struct identity,required numeric relationshipId,required numeric expectedVersion,required string email){
        var actor=identityChecked(identity);var recipient=variables.policy.identifier(relationshipId);var before=relation(recipient);var address=normalizeEmail(email);var output={};
        transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_gestora,before.id_conta_cliente],[actor.id]);actor=identityChecked(identity);var row=relation(relationshipId);authority(actor.id,row.id_conta_gestora);version(row,expectedVersion);registrationFor(row);
            ownerRelationshipEligible(row);noConfirmedOwner(row.id_conta_cliente);cancelOwnerInvites(row.id_conta_cliente);
            var bytes=createObject('java','java.nio.ByteBuffer').allocate(32).array();createObject('java','java.security.SecureRandom').nextBytes(bytes);var token=lCase(binaryEncode(bytes,'hex'));var issued=variables.clock();var expires=dateAdd('d',7,issued);
            var saved=variables.store.execute("INSERT INTO tb_conta_gestao_convites(tipo,id_conta,id_vinculo,email_destinatario,token_hash,id_usuario_autor,created_at,expires_at) VALUES('TITULAR',:account,:id,:email,:hash,:actor,CAST(:issued AS timestamptz),CAST(:expires AS timestamptz)) RETURNING id_convite",{account=n(row.id_conta_cliente),id=n(row.id_vinculo),email=t(address),hash=t(lCase(hash(token,'SHA-256'))),actor=n(actor.id),issued=instant(issued),expires=instant(expires)});
            variables.store.execute('UPDATE tb_conta_gestao_vinculos SET version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id',{id=n(row.id_vinculo)});row=relation(row.id_vinculo);audit(row,actor.id,'owner.invite','INVITATION',saved.id_convite[1]);output=result(row);output.inviteId=saved.id_convite[1];output.expiresAt=expires;output.url='/convites/?token=' & token;
        }return output;
    }
    private struct function inviteByToken(required string token){
        if(!reFind('^[a-f0-9]{64}$',token))variables.policy.fail('Forbidden','Invitation unavailable');
        var row=first(variables.store.execute('SELECT * FROM tb_conta_gestao_convites WHERE token_hash=:hash',{hash=t(lCase(hash(token,'SHA-256')))}));if(structIsEmpty(row))variables.policy.fail('Forbidden','Invitation unavailable');return row;
    }
    private void function liveInvite(required struct invite){
        if(invite.status!='PENDENTE')variables.policy.fail('Conflict','Invitation unavailable');
        var live=variables.store.execute('SELECT expires_at>CAST(:now AS timestamptz) live FROM tb_conta_gestao_convites WHERE id_convite=:id',{now=instant(variables.clock()),id=n(invite.id_convite)});
        if(!live.recordCount || !live.live[1])variables.policy.fail('Conflict','Invitation expired');
    }
    private void function ownerRelationshipEligible(required struct row){
        var account=variables.store.account(row.id_conta_cliente);
        if(structIsEmpty(account) || row.origem!='CRIACAO_GESTORA'
            || !((row.status=='AGUARDANDO_CONTA' && account.status=='PENDENTE') || (row.status=='ATIVO' && account.status=='ATIVA')))
            variables.policy.fail('Conflict','Owner invitation relationship is unavailable');
    }
    private void function receivingIdentity(required struct actor,required struct invite,required struct row){
        if(invite.tipo=='TITULAR'){
            if(invite.id_conta!=row.id_conta_cliente || row.origem!='CRIACAO_GESTORA' || compare(actor.email,invite.email_destinatario)!=0)variables.policy.fail('Forbidden','Invitation unavailable');
            ownerRelationshipEligible(row);
            var member=variables.store.membership(actor.id,row.id_conta_gestora);if(!structIsEmpty(member) && member.status=='ATIVO')variables.policy.fail('Forbidden','Agency member cannot acquire ownership');
        }else if(listFind('RELACAO,AMPLIACAO',invite.tipo)){
            var member=variables.store.membership(actor.id,invite.id_conta);var account=variables.store.account(invite.id_conta);
            if((invite.id_conta!=row.id_conta_cliente && invite.id_conta!=row.id_conta_gestora) || structIsEmpty(account) || account.status!='ATIVA' || structIsEmpty(member) || member.status!='ATIVO' || (invite.id_conta==row.id_conta_cliente?member.papel!='OWNER':!listFind('OWNER,ADMIN',member.papel)))variables.policy.fail('Forbidden','Invitation unavailable');
        }else variables.policy.fail('Forbidden','Invitation unavailable');
    }
    public struct function inspectInvite(required struct identity,required string token){
        var actor=identityChecked(identity);var before=inviteByToken(token);var scope=relation(before.id_vinculo);var output={};
        transaction isolation='read_committed' {
            variables.store.lockScope([scope.id_conta_gestora,scope.id_conta_cliente],[actor.id]);actor=identityChecked(identity);var invite=inviteByToken(token);var row=relation(invite.id_vinculo);receivingIdentity(actor,invite,row);liveInvite(invite);
            // Display only these account identities after recipient and live-state checks.
            var clientAccount=variables.store.account(row.id_conta_cliente);
            var managerAccount=variables.store.account(row.id_conta_gestora);
            if(structIsEmpty(clientAccount) || structIsEmpty(managerAccount))variables.policy.fail('Conflict','Invitation accounts unavailable');
            output={type=invite.tipo,id=invite.id_convite,version=invite.version,relationshipId=row.id_vinculo,relationshipVersion=row.version,accountId=invite.id_conta,status=invite.status,expiresAt=invite.expires_at};
            output.clientAccountId=clientAccount.id_conta;
            output.clientAccountName=clientAccount.nome_conta;
            output.clientAccountStatus=clientAccount.status;
            output.managerAccountName=managerAccount.nome_conta;
            if(invite.tipo!='TITULAR')output.capabilities=deserializeJSON(invite.capacidades_propostas);
        }return output;
    }
    public struct function acceptOwner(required struct identity,required string token,required numeric expectedVersion){
        var actor=identityChecked(identity);var before=inviteByToken(token);if(before.tipo!='TITULAR')variables.policy.fail('Forbidden','Invitation unavailable');var scope=relation(before.id_vinculo);var output={};
        transaction isolation='read_committed' {
            variables.store.lockScope([scope.id_conta_gestora,scope.id_conta_cliente],[actor.id,before.id_usuario_autor]);actor=identityChecked(identity);var invite=inviteByToken(token);version(invite,expectedVersion);liveInvite(invite);var row=relation(invite.id_vinculo);receivingIdentity(actor,invite,row);registrationFor(row);noConfirmedOwner(row.id_conta_cliente);
            var params={account=n(row.id_conta_cliente),actor=n(actor.id),author=n(invite.id_usuario_autor),id=n(invite.id_convite)};
            variables.store.execute("INSERT INTO tb_conta_usuarios(id_conta,id_usuario,papel,status,usuario_convite,data_convite,data_aceite) VALUES(:account,:actor,'OWNER','ATIVO',:author,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP) ON CONFLICT(id_conta,id_usuario) DO UPDATE SET papel='OWNER',status='ATIVO',data_aceite=CURRENT_TIMESTAMP,data_atualizacao=CURRENT_TIMESTAMP",params);
            variables.store.execute("UPDATE tb_conta_gestao_convites SET status='ACEITO',id_usuario_aceite=:actor,version=version+1,accepted_at=CURRENT_TIMESTAMP,updated_at=CURRENT_TIMESTAMP WHERE id_convite=:id",params);
            audit(row,actor.id,'owner.accept','INVITATION',invite.id_convite);output={status='ACEITO',id=invite.id_convite,version=invite.version+1};
        }return output;
    }
    public struct function rejectOwner(required struct identity,required string token,required numeric expectedVersion){
        var actor=identityChecked(identity);var before=inviteByToken(token);if(before.tipo!='TITULAR')variables.policy.fail('Forbidden','Invitation unavailable');var scope=relation(before.id_vinculo);var output={};
        transaction isolation='read_committed' {
            variables.store.lockScope([scope.id_conta_gestora,scope.id_conta_cliente],[actor.id,before.id_usuario_autor]);actor=identityChecked(identity);
            var invite=inviteByToken(token);var row=relation(invite.id_vinculo);receivingIdentity(actor,invite,row);version(invite,expectedVersion);liveInvite(invite);registrationFor(row);noConfirmedOwner(row.id_conta_cliente);
            variables.store.execute("UPDATE tb_conta_gestao_convites SET status='RECUSADO',id_usuario_aceite=:actor,version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_convite=:id",{actor=n(actor.id),id=n(invite.id_convite)});
            audit(row,actor.id,'owner.reject','INVITATION',invite.id_convite);output={status='RECUSADO',id=invite.id_convite,version=invite.version+1};
        }return output;
    }
}
