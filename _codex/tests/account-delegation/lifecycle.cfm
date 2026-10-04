<cfscript>
dsn=application.delegationTest.datasource;
function db(required string sql,struct params={}){return queryExecute(sql,params,{datasource=application.delegationTest.datasource});}
service=createObject('component','services.BusinessAccountDelegation').init(dsn,true);
store=createObject('component','services.accountDelegation.Store').init(dsn);
owner={id=904,email='client@example.test',emailVerified=true};manager={id=902,email='  OWNER@EXAMPLE.TEST ',emailVerified=true};
function resetRelations(){
 db('UPDATE tb_conta_cadastro_solicitacoes SET gestao_vinculo_id=NULL');
 db('DELETE FROM tb_conta_gestao_auditoria');db('DELETE FROM tb_conta_gestao_convites');db('DELETE FROM tb_conta_gestao_equipe_permissoes');db('DELETE FROM tb_conta_gestao_equipe');db('DELETE FROM tb_conta_gestao_permissoes');db('DELETE FROM tb_conta_gestao_vinculos');
}
function delegated(required numeric relation){return {accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=relation};}
function active(){var invitation=service.createRelationshipInvite(owner,102,101,['events.manage']);return service.decideRelationship(manager,invitation.id,invitation.version,'APPROVE',['events.manage']);}
function testInviteNeedsCounterparty(){
 resetRelations();var invitation=service.createRelationshipInvite(owner,102,101,['events.manage']);
 assertEqual(invitation.status,'PENDENTE_GESTORA','invite pending');
 assertEqual(db('SELECT count(*) n FROM tb_conta_gestao_permissoes').n[1],0,'pending never grants');
 assertThrowsType(function(){service.decideRelationship(owner,invitation.id,invitation.version,'APPROVE',['events.manage']);},'BusinessDelegation.Forbidden','sender cannot approve');
 var accepted=service.decideRelationship(manager,invitation.id,invitation.version,'APPROVE',['events.manage']);
 assertEqual(accepted.status,'ATIVO','counterparty activates');
 assertEqual(service.has(service.resolve(manager,delegated(accepted.id)),'events.manage'),true,'initial responsible assigned');
 assertThrowsType(function(){service.decideRelationship(manager,invitation.id,invitation.version,'APPROVE',['events.manage']);},'BusinessDelegation.Conflict','single acceptance');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE id_usuario_ator=902 AND acao='relationship.approve'").n[1],1,'real acceptor audit');
}
function testRequestApprovalCanOnlyNarrow(){
 resetRelations();var receipt=service.requestRelationship(manager,101,'102',['events.manage']);var proposal=store.relationship(db('SELECT id_vinculo FROM tb_conta_gestao_vinculos').id_vinculo[1]);proposal.id=proposal.id_vinculo;
 assertEqual(serializeJSON(service.requestRelationship(manager,101,'102',['ads.campaigns.view'])),serializeJSON(receipt),'pending repetition idempotent');
 assertThrowsType(function(){service.decideRelationship(owner,proposal.id,proposal.version,'APPROVE',['events.manage','ads.campaigns.view']);},'BusinessDelegation.Forbidden','approval cannot widen');
 var accepted=service.decideRelationship(owner,proposal.id,proposal.version,'APPROVE',['events.view']);
 assertEqual(store.grants(accepted.id),['events.view'],'requested intersection');
 assertEqual(service.has(service.resolve(manager,delegated(accepted.id)),'events.manage'),false,'narrowed assignment');
 var missing=service.requestRelationship(manager,101,'999999',['events.view']);
 assertEqual(missing.status,'PENDING','nonenumerable missing result');assertEqual(serializeJSON(missing),serializeJSON(receipt),'no target existence leak');
 resetRelations();db("UPDATE tb_usuarios SET email='' WHERE id=904");
 var invalidContact=service.requestRelationship(manager,101,'102',['events.view']);
 assertEqual(serializeJSON(invalidContact),serializeJSON(receipt),'ineligible contact does not enumerate');
 db("UPDATE tb_usuarios SET email='client@example.test' WHERE id=904");
}
function testReductionInvalidatesTeamImmediately(){
 resetRelations();var relation=active();var assigned=service.assignMember(manager,relation.id,1002,relation.version,['events.manage']);
 var old=service.resolve({id=903},delegated(relation.id));
 var reduced=service.changeRelationship(owner,relation.id,assigned.version,'REDUCE',['events.view']);
 var fresh=service.resolve({id=903},delegated(relation.id));assertEqual(fresh.capabilities,['events.view'],'immediate reduction');
 assertThrowsType(function(){service.withMutation(old,'events.manage',old,{type='ACCOUNT',id=102},function(c){return true;});},'BusinessDelegation.Conflict','old context invalidated');
 assertThrowsType(function(){service.assignMember(manager,relation.id,1006,reduced.version,['events.view']);},'BusinessDelegation.Forbidden','medico ineligible');
 assertThrowsType(function(){service.assignMember(manager,relation.id,1005,reduced.version,['events.manage']);},'BusinessDelegation.Forbidden','viewer cannot write');
 assertThrowsType(function(){service.assignMember(manager,relation.id,1002,reduced.version,['ads.campaigns.view']);},'BusinessDelegation.Forbidden','assignment subset');
 var row=store.assignment(relation.id,1002);var removed=service.removeAssignment(manager,row.id_equipe,row.version);
 assertThrowsType(function(){service.resolve({id=903},delegated(relation.id));},'BusinessDelegation.Forbidden','removed member denied');
 assertThrowsType(function(){service.removeAssignment(manager,row.id_equipe,row.version);},'BusinessDelegation.Conflict','removed assignment version');
}
function testViewerCeilingIndependentOfSubset(){
 resetRelations();var relation=active();
 assertEqual(arrayFind(store.grants(relation.id),'events.manage')>0,true,'relation really grants manage');
 var before=db('SELECT count(*) n FROM tb_conta_gestao_equipe WHERE id_conta_usuario=1005').n[1];
 assertThrowsType(function(){service.assignMember(manager,relation.id,1005,relation.version,['events.manage']);},'BusinessDelegation.Forbidden','viewer ceiling despite valid relation subset');
 assertEqual(db('SELECT count(*) n FROM tb_conta_gestao_equipe WHERE id_conta_usuario=1005').n[1],before,'viewer denial has no assignment write');
 var assigned=service.assignMember(manager,relation.id,1002,relation.version,['events.manage']);
 assertEqual(assigned.status,'ATIVO','same subset is valid for operator');
}
function testRevokeAndReinviteDoesNotRestoreTeam(){
 resetRelations();var relation=active();var assigned=service.assignMember(manager,relation.id,1002,relation.version,['events.view']);
 var revoked=service.changeRelationship(owner,relation.id,assigned.version,'REVOKE',[]);
 assertThrowsType(function(){service.changeRelationship(manager,relation.id,revoked.version,'REACTIVATE',[]);},'BusinessDelegation.Forbidden','revoked cannot reactivate');
 var invitation=service.createRelationshipInvite(owner,102,101,['events.view']);var accepted=service.decideRelationship(manager,invitation.id,invitation.version,'APPROVE',['events.view']);
 assertThrowsType(function(){service.resolve({id=903},delegated(accepted.id));},'BusinessDelegation.Forbidden','old team not restored');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_equipe e JOIN tb_conta_gestao_equipe_permissoes p USING(id_equipe) WHERE e.id_conta_usuario=1002").n[1],0,'old grants destroyed');
}
function testSevenDayExpiry(){
 resetRelations();fixedNow=createDateTime(2026,10,3,12,0,0);clockNow=fixedNow;
 var invitations=createObject('component','services.accountDelegation.Invitations').init(dsn,store,createObject('component','services.accountDelegation.Policy'),function(){return clockNow;});
 var invitation=invitations.createRelationshipInvite(owner,102,101,['events.view']);
 assertEqual(invitation.expiresAt,dateAdd('d',7,fixedNow),'expiry');
 var token=listLast(invitation.url,'=');var stored=db('SELECT token_hash,email_destinatario FROM tb_conta_gestao_convites');
 assertEqual(len(token),64,'32 byte hex token');assertEqual(stored.token_hash[1],lCase(hash(token,'SHA-256')),'only token hash stored');assertEqual(stored.email_destinatario[1],'owner@example.test','normalized email');
 clockNow=dateAdd('d',7,fixedNow);
 assertThrowsType(function(){invitations.decideRelationship(manager,invitation.id,invitation.version,'APPROVE',['events.view']);},'BusinessDelegation.Conflict','expired');
 assertEqual(db('SELECT count(*) n FROM tb_conta_gestao_permissoes').n[1],0,'expiry never grants');
}
function testNoTransitiveManagement(){
 resetRelations();var relation=active();
 assertThrowsType(function(){service.createRelationshipInvite(manager,102,103,['events.view']);},'BusinessDelegation.Forbidden','delegated cannot invite');
 assertThrowsType(function(){service.changeRelationship(manager,relation.id,relation.version,'REDUCE',['events.view']);},'BusinessDelegation.Forbidden','manager cannot impersonate owner');
 var second=service.createRelationshipInvite(owner,102,103,['ads.campaigns.view']);service.decideRelationship(manager,second.id,second.version,'APPROVE',['ads.campaigns.view']);
 assertEqual(store.grants(relation.id),['events.manage','events.view'],'independent managers');
}
function testRenewalCompanyRecipientAndVerifiedIdentity(){
 resetRelations();var first=service.createRelationshipInvite(owner,102,101,['events.view']);
 var renewed=service.createRelationshipInvite(owner,102,101,['events.view']);
 assertEqual(db('SELECT status FROM tb_conta_gestao_convites WHERE id_convite=:id',{id={value=first.inviteId,cfsqltype='cf_sql_bigint'}}).status[1],'CANCELADO','renewal cancels old token');
 assertEqual(first.url==renewed.url,false,'renewal fresh CSPRNG token');
 assertThrowsType(function(){service.decideRelationship(manager,first.id,first.version,'APPROVE',['events.view']);},'BusinessDelegation.Conflict','renewal old version');
 assertThrowsType(function(){service.decideRelationship({id=902,email='owner@example.test',emailVerified=false},renewed.id,renewed.version,'APPROVE',['events.view']);},'BusinessDelegation.Forbidden','unverified cannot accept');
 db("INSERT INTO tb_usuarios(id,name,email) VALUES(907,'Other Admin','different+alias@example.test') ON CONFLICT DO NOTHING");
 db("INSERT INTO tb_conta_usuarios(id_conta_usuario,id_conta,id_usuario,papel,status) VALUES(1007,101,907,'ADMIN','ATIVO') ON CONFLICT DO NOTHING");
 var accepted=service.decideRelationship({id=907,email=' DIFFERENT+ALIAS@EXAMPLE.TEST ',emailVerified=true},renewed.id,renewed.version,'APPROVE',['events.view']);
 assertEqual(store.assignment(accepted.id,1007).status,'ATIVO','any receiving company eligible admin');
}
function testExpansionNeedsConsentAndRevocationCancels(){
 resetRelations();var row=active();var expansion=service.changeRelationship(manager,row.id,row.version,'EXPAND',['events.manage','ads.campaigns.view']);
 assertEqual(arrayFind(store.grants(row.id),'ads.campaigns.view'),0,'pending expansion grants nothing');
 assertThrowsType(function(){service.decideRelationship(manager,row.id,expansion.version,'APPROVE',['events.manage','ads.campaigns.view']);},'BusinessDelegation.Forbidden','expansion sender cannot accept');
 var accepted=service.decideRelationship(owner,row.id,expansion.version,'APPROVE',['events.manage','ads.campaigns.view']);
 assertEqual(service.has(service.resolve(manager,delegated(row.id)),'ads.campaigns.view'),true,'approved expansion responsible');
 var pending=service.changeRelationship(owner,row.id,accepted.version,'EXPAND',['events.manage','ads.campaigns.view','ads.payments.view']);
 service.changeRelationship(owner,row.id,pending.version,'REVOKE',[]);
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_convites WHERE status='PENDENTE'").n[1],0,'revocation cancels expansion');
}
function testSuspensionAndRequestLimits(){
 resetRelations();db('UPDATE tb_usuarios SET is_admin=true WHERE id=901');var row=active();
 assertThrowsType(function(){service.changeRelationship(manager,row.id,row.version,'SUSPEND',[]);},'BusinessDelegation.Forbidden','internal DB authority required');
 var internal={id=901,email='reviewer@example.test',emailVerified=true,accessMode='DIRECT'};var suspended=service.changeRelationship(internal,row.id,row.version,'SUSPEND',[]);
 assertThrowsType(function(){service.resolve(manager,delegated(row.id));},'BusinessDelegation.Forbidden','suspension denies immediately');
 var restored=service.changeRelationship(internal,row.id,suspended.version,'REACTIVATE',[]);assertEqual(service.has(service.resolve(manager,delegated(row.id)),'events.manage'),true,'explicit suspension reactivation');
 resetRelations();for(var i=1;i<=7;i++) service.requestRelationship(manager,101,'102',['events.view']);
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_vinculos WHERE status='PENDENTE_CLIENTE'").n[1],1,'duplicate row not created');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE acao='relationship.request.receipt'").n[1],5,'five per hour attempt cap');
 assertEqual(db('SELECT count(*) n FROM tb_conta_gestao_convites').n[1],1,'duplicate does not issue another token');
 var proposal=store.relationship(db('SELECT id_vinculo FROM tb_conta_gestao_vinculos').id_vinculo[1]);
 db("UPDATE tb_conta_usuarios SET status='INATIVO' WHERE id_conta_usuario=1001");
 assertThrowsType(function(){service.decideRelationship(owner,proposal.id_vinculo,proposal.version,'APPROVE',['events.view']);},'BusinessDelegation.Forbidden','requester current authority reread');
 db("UPDATE tb_conta_usuarios SET status='ATIVO' WHERE id_conta_usuario=1001");
}
testInviteNeedsCounterparty();testRequestApprovalCanOnlyNarrow();testReductionInvalidatesTeamImmediately();testViewerCeilingIndependentOfSubset();testRevokeAndReinviteDoesNotRestoreTeam();testSevenDayExpiry();testNoTransitiveManagement();testRenewalCompanyRecipientAndVerifiedIdentity();testExpansionNeedsConsentAndRevocationCancels();testSuspensionAndRequestLimits();
</cfscript>
