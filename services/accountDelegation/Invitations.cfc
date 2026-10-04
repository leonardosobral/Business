component output=false {
    // Clock is an internal dependency; HTTP never supplies it or any authority flags.
    public any function init(required string datasource,required any store,required any policy,any clock) {
        variables.datasource=datasource;variables.store=store;variables.policy=policy;
        if(structKeyExists(arguments,'clock')) variables.clock=arguments.clock;
        else variables.clock=function(){return dateConvert('local2utc',now());};
        return this;
    }
    private struct function numberParam(required any value){return {value=value,cfsqltype='cf_sql_bigint'};}
    private struct function textParam(required string value){return {value=value,cfsqltype='cf_sql_varchar'};}
    private struct function timeParam(required date value){return {value=dateTimeFormat(value,"yyyy-mm-dd'T'HH:nn:ss.l") & 'Z',cfsqltype='cf_sql_varchar'};}
    private struct function identityChecked(required struct identity) {
        var id=variables.policy.identifier(structKeyExists(identity,'id')?identity.id:0);
        if(!structKeyExists(identity,'emailVerified') || !isBoolean(identity.emailVerified) || !identity.emailVerified
            || !structKeyExists(identity,'email') || !isSimpleValue(identity.email)) variables.policy.fail('Forbidden','Verified identity required');
        var email=lCase(trim(identity.email));
        if(!reFind('^[^\s@]+@[^\s@]+\.[^\s@]+$',email) || structIsEmpty(variables.store.actor(id))) variables.policy.fail('Forbidden','Verified identity is inactive');
        return {id=id,email=email};
    }
    private struct function authority(required any actorId,required any accountId,boolean ownerOnly=false) {
        var account=variables.store.account(accountId);var member=variables.store.membership(actorId,accountId);
        if(structIsEmpty(variables.store.actor(actorId)) || structIsEmpty(account) || account.status!='ATIVA'
            || structIsEmpty(member) || member.status!='ATIVO' || (ownerOnly?member.papel!='OWNER':!listFind('OWNER,ADMIN',member.papel))) variables.policy.fail('Forbidden','Direct company authority required');
        return member;
    }
    private void function enabledManager(required any id) {
        var account=variables.store.account(id);var config=variables.store.manager(id);
        if(structIsEmpty(account) || account.status!='ATIVA' || structIsEmpty(config) || !config.habilitada) variables.policy.fail('Forbidden','Manager is unavailable');
    }
    private array function normalized(required array capabilities) {
        for(var cap in capabilities) if(!isSimpleValue(cap) || !arrayFind(variables.policy.catalog(),cap)) variables.policy.fail('Validation','Unknown capability');
        var result=variables.policy.expand(capabilities);
        if((arrayFind(result,'ads.payments.view') || arrayFind(result,'ads.credits.purchase')) && !arrayFind(result,'ads.campaigns.view')) variables.policy.fail('Validation','Financial capability requires campaign view');
        return result;
    }
    private void function subset(required array selected,required array proposed) {
        for(var cap in selected) if(!arrayFind(proposed,cap)) variables.policy.fail('Forbidden','Capabilities exceed the approved proposal');
    }
    private struct function relation(required any id) {
        var result=variables.store.lifecycleRelationship(variables.policy.identifier(id));
        if(structIsEmpty(result)) variables.policy.fail('NotFound','Relationship unavailable');return result;
    }
    private void function version(required struct row,required any expected) {
        if(compare(row.version & '',variables.policy.identifier(expected))!=0) variables.policy.fail('Conflict','Relationship changed');
    }
    private array function scopeActors(required array actors,required any clientId,required any managerId) {
        var result=duplicate(actors);
        var members=variables.store.execute('SELECT DISTINCT m.id_usuario FROM tb_conta_gestao_equipe e JOIN tb_conta_usuarios m ON m.id_conta_usuario=e.id_conta_usuario JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=e.id_vinculo WHERE v.id_conta_cliente=:client AND v.id_conta_gestora=:manager ORDER BY m.id_usuario',{client=numberParam(clientId),manager=numberParam(managerId)});
        for(var member in members) if(!arrayFind(result,member.id_usuario)) arrayAppend(result,member.id_usuario);
        return result;
    }
    private struct function result(required struct row){return {status=row.status,id=row.id_vinculo,version=row.version};}
    private void function audit(required struct row,required any actor,required string action,string type='RELATIONSHIP',any resourceId=0) {
        variables.store.audit({actorId=actor,managerAccountId=row.id_conta_gestora,accountId=row.id_conta_cliente,relationshipId=row.id_vinculo},action,{type=type,id=resourceId==0?row.id_vinculo:resourceId});
    }
    private void function cancelInvites(required any id,boolean includeOwner=false) {
        // Only material loss of relationship eligibility cancels separate pending ownership invitations.
        variables.store.execute("UPDATE tb_conta_gestao_convites SET status='CANCELADO',version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id AND (tipo IN('RELACAO','AMPLIACAO') OR (:owners=true AND tipo='TITULAR')) AND status='PENDENTE'",{id=numberParam(id),owners={value=includeOwner,cfsqltype='cf_sql_boolean'}});
    }
    private void function removeTeam(required any id) {
        variables.store.execute('DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_vinculo=:id',{id=numberParam(id)});
        variables.store.execute("UPDATE tb_conta_gestao_equipe SET status='REMOVIDO',version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id AND status='ATIVO'",{id=numberParam(id)});
    }
    private void function replaceGrants(required any id,required array capabilities) {
        // Deleting a relationship grant cascades only that grant from every assignment.
        var current=variables.store.grants(id);
        for(var cap in current) if(!arrayFind(capabilities,cap)) variables.store.execute('DELETE FROM tb_conta_gestao_permissoes WHERE id_vinculo=:id AND id_permissao IN(SELECT id_permissao FROM tb_business_permissoes WHERE codigo=:cap)',{id=numberParam(id),cap=textParam(cap)});
        for(var cap in capabilities) {
            var inserted=variables.store.execute('INSERT INTO tb_conta_gestao_permissoes SELECT :id,id_permissao FROM tb_business_permissoes WHERE codigo=:cap AND ativo=true ON CONFLICT DO NOTHING RETURNING id_permissao',{id=numberParam(id),cap=textParam(cap)});
            if(!arrayFind(current,cap) && !inserted.recordCount) variables.policy.fail('Forbidden','Capability is unavailable');
        }
    }
    private struct function putAssignment(required struct row,required struct member,required array capabilities) {
        if(member.status!='ATIVO' || !listFind('OWNER,ADMIN,OPERADOR,VISUALIZADOR',member.papel) || structIsEmpty(variables.store.actor(member.id_usuario))) variables.policy.fail('Forbidden','Member is ineligible');
        subset(capabilities,variables.store.grants(row.id_vinculo));
        if(member.papel=='VISUALIZADOR') for(var cap in capabilities) if(right(cap,5)!='.view') variables.policy.fail('Forbidden','Viewer cannot receive operational capabilities');
        var assignment=variables.store.execute("INSERT INTO tb_conta_gestao_equipe(id_vinculo,id_conta_usuario,status) VALUES(:id,:member,'ATIVO')
            ON CONFLICT(id_vinculo,id_conta_usuario) DO UPDATE SET status='ATIVO',version=tb_conta_gestao_equipe.version+1,updated_at=CURRENT_TIMESTAMP RETURNING id_equipe,version",
            {id=numberParam(row.id_vinculo),member=numberParam(member.id_conta_usuario)});
        variables.store.execute('DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=:id',{id=numberParam(assignment.id_equipe[1])});
        for(var cap in capabilities) variables.store.execute('INSERT INTO tb_conta_gestao_equipe_permissoes SELECT :team,:id,id_permissao FROM tb_business_permissoes WHERE codigo=:cap AND ativo=true',
            {team=numberParam(assignment.id_equipe[1]),id=numberParam(row.id_vinculo),cap=textParam(cap)});
        return {id=assignment.id_equipe[1],version=assignment.version[1]};
    }
    private struct function issue(required struct row,required any author,required any receivingAccount,required array capabilities,string type='RELACAO') {
        var contact=variables.store.companyContact(receivingAccount,receivingAccount==row.id_conta_cliente);
        if(structIsEmpty(contact)) variables.policy.fail('Validation','Receiving company is unavailable');
        var email=lCase(trim(contact.email));if(!reFind('^[^\s@]+@[^\s@]+\.[^\s@]+$',email)) variables.policy.fail('Validation','Receiving contact is unavailable');
        cancelInvites(row.id_vinculo);
        var bytes=createObject('java','java.nio.ByteBuffer').allocate(32).array();createObject('java','java.security.SecureRandom').nextBytes(bytes);
        var token=lCase(binaryEncode(bytes,'hex'));var issued=variables.clock();var expires=dateAdd('d',7,issued);
        var saved=variables.store.execute("INSERT INTO tb_conta_gestao_convites(tipo,id_conta,id_vinculo,email_destinatario,capacidades_propostas,token_hash,id_usuario_autor,created_at,expires_at)
            VALUES(:type,:account,:id,:email,CAST(:caps AS jsonb),:hash,:actor,CAST(:issued AS timestamptz),CAST(:expires AS timestamptz)) RETURNING id_convite",
            {type=textParam(type),account=numberParam(receivingAccount),id=numberParam(row.id_vinculo),email=textParam(email),caps=textParam(serializeJSON(capabilities)),hash=textParam(lCase(hash(token,'SHA-256'))),actor=numberParam(author),issued=timeParam(issued),expires=timeParam(expires)});
        var response=result(row);response.inviteId=saved.id_convite[1];response.expiresAt=expires;response.url='/convites/?token=' & token;return response;
    }
    public struct function createRelationshipInvite(required struct identity,required numeric clientId,required numeric managerId,required array capabilities) {
        var actor=identityChecked(identity);var caps=normalized(capabilities);var output={};
        variables.policy.identifier(clientId);variables.policy.identifier(managerId);
        if(clientId==managerId) variables.policy.fail('Validation','Companies must differ');
        transaction isolation='read_committed' {
            variables.store.lockScope([clientId,managerId],scopeActors([actor.id],clientId,managerId));actor=identityChecked(identity);authority(actor.id,clientId,true);enabledManager(managerId);
            var row=variables.store.findRelationship(clientId,managerId);
            if(!structIsEmpty(row) && !listFind('REVOGADO,RECUSADO,PENDENTE_GESTORA',row.status)) variables.policy.fail('Conflict','Relationship already exists');
            if(structIsEmpty(row)) {
                var saved=variables.store.execute("INSERT INTO tb_conta_gestao_vinculos(id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante,id_usuario_aprovador_cliente,capacidades_propostas)
                    VALUES(:manager,:client,'CONVITE_CLIENTE','PENDENTE_GESTORA',:actor,:actor,CAST(:caps AS jsonb)) RETURNING id_vinculo",{manager=numberParam(managerId),client=numberParam(clientId),actor=numberParam(actor.id),caps=textParam(serializeJSON(caps))});row=relation(saved.id_vinculo[1]);
            } else {
                removeTeam(row.id_vinculo);replaceGrants(row.id_vinculo,[]);cancelInvites(row.id_vinculo);
                variables.store.execute("UPDATE tb_conta_gestao_vinculos SET origem='CONVITE_CLIENTE',status='PENDENTE_GESTORA',id_usuario_solicitante=:actor,id_usuario_aprovador_cliente=:actor,id_usuario_aprovador_gestora=NULL,capacidades_propostas=CAST(:caps AS jsonb),version=version+1,updated_at=CURRENT_TIMESTAMP,decided_at=NULL WHERE id_vinculo=:id",{actor=numberParam(actor.id),caps=textParam(serializeJSON(caps)),id=numberParam(row.id_vinculo)});row=relation(row.id_vinculo);
            }
            output=issue(row,actor.id,managerId,caps);audit(row,actor.id,'relationship.invite','INVITATION',output.inviteId);
        }return output;
    }
    public struct function requestRelationship(required struct identity,required numeric managerId,required string clientReference,required array capabilities) {
        var actor=identityChecked(identity);var target=variables.policy.identifier(clientReference);var caps=normalized(capabilities);variables.policy.identifier(managerId);
        var receipt={status='PENDING',id=0,version=0};var targetHash=lCase(hash(target,'SHA-256'));
        var actors=scopeActors([actor.id],target,managerId); // Account mutex serializes receipts by manager as well as target.
        transaction isolation='read_committed' {
            variables.store.lockScope([managerId,target],actors);actor=identityChecked(identity);authority(actor.id,managerId);enabledManager(managerId);
            var attempts=variables.store.execute("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE id_usuario_ator=:actor AND id_conta_gestora=:manager AND acao='relationship.request.receipt' AND alteracoes->>'targetHash'=:target AND created_at>CAST(:cutoff AS timestamptz)",{actor=numberParam(actor.id),manager=numberParam(managerId),target=textParam(targetHash),cutoff=timeParam(dateAdd('h',-1,variables.clock()))});
            if(attempts.n[1]<5) {
                var account=variables.store.account(target);var contact=variables.store.companyContact(target,true);var row=variables.store.findRelationship(target,managerId);
                if(target!=managerId && !structIsEmpty(account) && account.status=='ATIVA' && !structIsEmpty(contact)
                    && (structIsEmpty(row) || listFind('REVOGADO,RECUSADO',row.status))) {
                    if(structIsEmpty(row)) {
                        var saved=variables.store.execute("INSERT INTO tb_conta_gestao_vinculos(id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante,id_usuario_aprovador_gestora,capacidades_propostas) VALUES(:manager,:client,'SOLICITACAO_GESTORA','PENDENTE_CLIENTE',:actor,:actor,CAST(:caps AS jsonb)) RETURNING id_vinculo",{manager=numberParam(managerId),client=numberParam(target),actor=numberParam(actor.id),caps=textParam(serializeJSON(caps))});row=relation(saved.id_vinculo[1]);
                    } else {
                        removeTeam(row.id_vinculo);replaceGrants(row.id_vinculo,[]);cancelInvites(row.id_vinculo);
                        variables.store.execute("UPDATE tb_conta_gestao_vinculos SET origem='SOLICITACAO_GESTORA',status='PENDENTE_CLIENTE',id_usuario_solicitante=:actor,id_usuario_aprovador_gestora=:actor,id_usuario_aprovador_cliente=NULL,capacidades_propostas=CAST(:caps AS jsonb),version=version+1,updated_at=CURRENT_TIMESTAMP,decided_at=NULL WHERE id_vinculo=:id",{actor=numberParam(actor.id),caps=textParam(serializeJSON(caps)),id=numberParam(row.id_vinculo)});row=relation(row.id_vinculo);
                    }
                    issue(row,actor.id,target,caps);audit(row,actor.id,'relationship.request');
                }
                // Identical receipt, including missing/ineligible target. Never store/expose client PII here.
                variables.store.execute("INSERT INTO tb_conta_gestao_auditoria(id_usuario_ator,id_conta_gestora,acao,recurso_tipo,resultado,alteracoes,created_at) VALUES(:actor,:manager,'relationship.request.receipt','RELATIONSHIP','SUCCESS',CAST(:changes AS jsonb),CAST(:issued AS timestamptz))",{actor=numberParam(actor.id),manager=numberParam(managerId),changes=textParam('{"targetHash":' & serializeJSON(targetHash) & '}'),issued=timeParam(variables.clock())});
            }
        }return receipt;
    }
    public struct function decideRelationship(required struct identity,required numeric relationshipId,required numeric expectedVersion,required string decision,required array capabilities) {
        var actor=identityChecked(identity);var before=relation(relationshipId);var caps=normalized(capabilities);var output={};
        var previousInvite=variables.store.execute("SELECT id_usuario_autor FROM tb_conta_gestao_convites WHERE id_vinculo=:id AND tipo IN('RELACAO','AMPLIACAO') AND status='PENDENTE' ORDER BY id_convite DESC LIMIT 1",{id=numberParam(before.id_vinculo)});
        var actors=scopeActors([actor.id,before.id_usuario_solicitante],before.id_conta_cliente,before.id_conta_gestora);if(previousInvite.recordCount) arrayAppend(actors,previousInvite.id_usuario_autor[1]);
        if(!listFind('APPROVE,DECLINE',decision)) variables.policy.fail('Validation','Invalid decision');
        transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_cliente,before.id_conta_gestora],actors);
            actor=identityChecked(identity);var row=relation(relationshipId);version(row,expectedVersion);
            var invite=variables.store.pendingRelationshipInvite(row.id_vinculo);
            if(structIsEmpty(invite)) variables.policy.fail('Conflict','Invitation is unavailable');
            // Company notification email is metadata. Current receiving-company membership is authority.
            authority(actor.id,invite.id_conta,invite.id_conta==row.id_conta_cliente);enabledManager(row.id_conta_gestora);
            var expires=variables.store.execute('SELECT CAST(extract(epoch FROM expires_at)*1000 AS bigint) deadline FROM tb_conta_gestao_convites WHERE id_convite=:id',{id=numberParam(invite.id_convite)}).deadline[1];
            var instant=variables.store.execute('SELECT CAST(extract(epoch FROM CAST(:now AS timestamptz))*1000 AS bigint) instant',{now=timeParam(variables.clock())}).instant[1];
            if(instant>=expires) variables.policy.fail('Conflict','Invitation expired');
            if(invite.tipo=='RELACAO' && !listFind('PENDENTE_CLIENTE,PENDENTE_GESTORA',row.status)) variables.policy.fail('Conflict','Relationship is not pending');
            if(invite.tipo=='AMPLIACAO' && row.status!='ATIVO') variables.policy.fail('Conflict','Relationship is inactive');
            var proposed=normalized(deserializeJSON(invite.capacidades_propostas));subset(caps,proposed);
            if(decision=='APPROVE') {
                if(!arrayLen(caps)) variables.policy.fail('Validation','At least one capability required');
                if(invite.tipo=='AMPLIACAO') subset(variables.store.grants(row.id_vinculo),caps);
                var responsible=invite.id_conta==row.id_conta_gestora?actor.id:invite.id_usuario_autor;
                var responsibleMember=authority(responsible,row.id_conta_gestora);
                // Client must still be active, and requesting manager's membership must still exist.
                var account=variables.store.account(row.id_conta_cliente);if(structIsEmpty(account) || account.status!='ATIVA') variables.policy.fail('Forbidden','Client is unavailable');
                replaceGrants(row.id_vinculo,caps);
                putAssignment(row,{id_conta_usuario=responsibleMember.id_conta_usuario,id_usuario=responsible,papel=responsibleMember.papel,status=responsibleMember.status},caps);
                variables.store.execute("UPDATE tb_conta_gestao_vinculos SET status='ATIVO',id_usuario_aprovador_cliente=CASE WHEN :receiver=:client THEN :actor ELSE id_usuario_aprovador_cliente END,id_usuario_aprovador_gestora=CASE WHEN :receiver=:manager THEN :actor ELSE id_usuario_aprovador_gestora END,version=version+1,updated_at=CURRENT_TIMESTAMP,decided_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id",{receiver=numberParam(invite.id_conta),client=numberParam(row.id_conta_cliente),manager=numberParam(row.id_conta_gestora),actor=numberParam(actor.id),id=numberParam(row.id_vinculo)});
            } else variables.store.execute("UPDATE tb_conta_gestao_vinculos SET status=CASE WHEN :type='RELACAO' THEN 'RECUSADO' ELSE status END,version=version+1,updated_at=CURRENT_TIMESTAMP,decided_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id",{type=textParam(invite.tipo),id=numberParam(row.id_vinculo)});
            variables.store.execute("UPDATE tb_conta_gestao_convites SET status=:status,id_usuario_aceite=:actor,version=version+1,updated_at=CURRENT_TIMESTAMP,accepted_at=CASE WHEN :status='ACEITO' THEN CURRENT_TIMESTAMP ELSE NULL END WHERE id_convite=:id",{status=textParam(decision=='APPROVE'?'ACEITO':'RECUSADO'),actor=numberParam(actor.id),id=numberParam(invite.id_convite)});
            row=relation(row.id_vinculo);audit(row,actor.id,decision=='APPROVE'?'relationship.approve':'relationship.decline');output=result(row);
        }return output;
    }
    public struct function changeRelationship(required struct identity,required numeric relationshipId,required numeric expectedVersion,required string action,required array capabilities) {
        var actor=identityChecked(identity);var before=relation(relationshipId);var caps=normalized(capabilities);var output={};
        if(!listFind('REDUCE,EXPAND,REVOKE,RENOUNCE,SUSPEND,REACTIVATE,CANCEL',action)) variables.policy.fail('Validation','Invalid relationship action');
        transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_cliente,before.id_conta_gestora],scopeActors([actor.id,before.id_usuario_solicitante],before.id_conta_cliente,before.id_conta_gestora));
            actor=identityChecked(identity);var row=relation(relationshipId);version(row,expectedVersion);
            if(listFind('SUSPEND,REACTIVATE',action)) {
                if(!structKeyExists(identity,'accessMode') || identity.accessMode!='DIRECT' || !variables.store.actor(actor.id).is_admin) variables.policy.fail('Forbidden','Real direct administrator required');
                if(action=='REACTIVATE' && row.status!='SUSPENSO') variables.policy.fail('Forbidden','Only suspended relationships can reactivate');
                if(action=='SUSPEND' && row.status!='ATIVO') variables.policy.fail('Conflict','Only active relationships can suspend');
                if(action=='REACTIVATE') {enabledManager(row.id_conta_gestora);if(variables.store.account(row.id_conta_cliente).status!='ATIVA') variables.policy.fail('Forbidden','Client is unavailable');}
            } else if(action=='RENOUNCE') authority(actor.id,row.id_conta_gestora);
            else if(action=='EXPAND') {
                var direct=variables.store.membership(actor.id,row.id_conta_cliente);
                var byClient=!structIsEmpty(direct) && direct.status=='ATIVO' && direct.papel=='OWNER';
                authority(actor.id,byClient?row.id_conta_cliente:row.id_conta_gestora,byClient);enabledManager(row.id_conta_gestora);
            } else if(action=='CANCEL') {
                var invite=variables.store.pendingRelationshipInvite(row.id_vinculo);
                if(structIsEmpty(invite)) variables.policy.fail('Conflict','No pending invitation');
                var sendingAccount=invite.id_conta==row.id_conta_cliente?row.id_conta_gestora:row.id_conta_cliente;
                authority(actor.id,sendingAccount,sendingAccount==row.id_conta_cliente);
            } else authority(actor.id,row.id_conta_cliente,true);
            if(listFind('REDUCE,EXPAND',action) && row.status!='ATIVO') variables.policy.fail('Conflict','Relationship is inactive');
            if(listFind('REVOKE,RENOUNCE',action) && !listFind('ATIVO,SUSPENSO,PENDENTE_CLIENTE,PENDENTE_GESTORA',row.status)) variables.policy.fail('Conflict','Relationship cannot be revoked');
            var nextStatus=row.status;
            if(action=='REDUCE') {
                subset(caps,variables.store.grants(row.id_vinculo));replaceGrants(row.id_vinculo,caps);cancelInvites(row.id_vinculo);
                // Every assignment stamp changes on reduction, even if its effective subset was unchanged.
                variables.store.execute('UPDATE tb_conta_gestao_equipe SET version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id',{id=numberParam(row.id_vinculo)});
            }
            if(action=='EXPAND') {subset(variables.store.grants(row.id_vinculo),caps);if(arrayLen(caps)<=arrayLen(variables.store.grants(row.id_vinculo))) variables.policy.fail('Validation','Expansion must add capabilities');}
            if(listFind('REVOKE,RENOUNCE',action)) {removeTeam(row.id_vinculo);replaceGrants(row.id_vinculo,[]);cancelInvites(row.id_vinculo,true);nextStatus='REVOGADO';}
            if(action=='SUSPEND') {cancelInvites(row.id_vinculo,true);nextStatus='SUSPENSO';}
            if(action=='REACTIVATE') nextStatus='ATIVO';
            if(action=='CANCEL') {cancelInvites(row.id_vinculo);if(listFind('PENDENTE_CLIENTE,PENDENTE_GESTORA',row.status)) nextStatus='RECUSADO';}
            variables.store.execute('UPDATE tb_conta_gestao_vinculos SET status=:status,version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id',{status=textParam(nextStatus),id=numberParam(row.id_vinculo)});row=relation(row.id_vinculo);
            if(action=='EXPAND') output=issue(row,actor.id,byClient?row.id_conta_gestora:row.id_conta_cliente,caps,'AMPLIACAO');else output=result(row);
            audit(row,actor.id,'relationship.' & lCase(action));
        }return output;
    }
    public struct function assignMember(required struct identity,required numeric relationshipId,required numeric membershipId,required numeric expectedVersion,required array capabilities) {
        var actor=identityChecked(identity);var before=relation(relationshipId);var member=variables.store.membershipById(variables.policy.identifier(membershipId));var caps=normalized(capabilities);var output={};
        if(structIsEmpty(member)) variables.policy.fail('NotFound','Member unavailable');
        transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_cliente,before.id_conta_gestora],[actor.id,member.id_usuario]);actor=identityChecked(identity);
            var row=relation(relationshipId);version(row,expectedVersion);authority(actor.id,row.id_conta_gestora);enabledManager(row.id_conta_gestora);
            if(row.status!='ATIVO' || variables.store.account(row.id_conta_cliente).status!='ATIVA') variables.policy.fail('Forbidden','Relationship is inactive');
            member=variables.store.membershipById(membershipId);
            if(structIsEmpty(member) || member.id_conta!=row.id_conta_gestora) variables.policy.fail('Forbidden','Member belongs to another company');
            var assignment=putAssignment(row,member,caps);
            variables.store.execute('UPDATE tb_conta_gestao_vinculos SET version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id',{id=numberParam(row.id_vinculo)});row=relation(row.id_vinculo);audit(row,actor.id,'team.assign','ASSIGNMENT',assignment.id);output=result(row);
        }return output;
    }
    public struct function removeAssignment(required struct identity,required numeric assignmentId,required numeric expectedVersion) {
        var actor=identityChecked(identity);var assignment=variables.store.assignmentById(variables.policy.identifier(assignmentId));
        if(structIsEmpty(assignment)) variables.policy.fail('NotFound','Assignment unavailable');
        var before=relation(assignment.id_vinculo);var member=variables.store.membershipById(assignment.id_conta_usuario);var output={};
        if(structIsEmpty(member)) variables.policy.fail('NotFound','Member unavailable');
        transaction isolation='read_committed' {
            variables.store.lockScope([before.id_conta_cliente,before.id_conta_gestora],[actor.id,member.id_usuario]);actor=identityChecked(identity);
            var row=relation(before.id_vinculo);authority(actor.id,row.id_conta_gestora);
            assignment=variables.store.assignmentById(assignmentId);if(structIsEmpty(assignment)) variables.policy.fail('Conflict','Assignment changed');version(assignment,expectedVersion);
            if(assignment.status!='ATIVO') variables.policy.fail('Conflict','Assignment removed');
            variables.store.execute('DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=:id',{id=numberParam(assignmentId)});
            variables.store.execute("UPDATE tb_conta_gestao_equipe SET status='REMOVIDO',version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_equipe=:id",{id=numberParam(assignmentId)});
            variables.store.execute('UPDATE tb_conta_gestao_vinculos SET version=version+1,updated_at=CURRENT_TIMESTAMP WHERE id_vinculo=:id',{id=numberParam(row.id_vinculo)});
            audit(row,actor.id,'team.remove','ASSIGNMENT',assignmentId);assignment=variables.store.assignmentById(assignmentId);output={status=assignment.status,id=assignment.id_equipe,version=assignment.version};
        }return output;
    }
}
