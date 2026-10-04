<cfscript>
dsn=application.delegationTest.datasource;
function db(required string sql, struct params={}) { return queryExecute(arguments.sql,arguments.params,{datasource=application.delegationTest.datasource}); }
function selected(required string mode, numeric manager=0, numeric relationship=0) { return {accountId=102,accessMode=mode,managerAccountId=manager,relationshipId=relationship}; }
identity={id=902,email='owner@example.test',emailVerified=true};
// Synthetic authorization fixtures use the existing user-management and role-grant schemas.
db("CREATE TABLE tb_usuarios_gestao(id_usuario integer PRIMARY KEY REFERENCES tb_usuarios(id),ativo boolean NOT NULL DEFAULT true,excluido boolean NOT NULL DEFAULT false)");
db("CREATE TABLE tb_conta_permissoes(id_conta_permissao bigserial PRIMARY KEY,id_conta bigint REFERENCES tb_contas,id_permissao bigint REFERENCES tb_business_permissoes,papel papel_usuario_conta,ativo boolean DEFAULT true,UNIQUE(id_conta,id_permissao,papel))");
db("INSERT INTO tb_conta_usuarios VALUES(1010,102,902,'VISUALIZADOR','ATIVO')");
db("INSERT INTO tb_conta_permissoes(id_conta,id_permissao,papel) SELECT 102,id_permissao,'VISUALIZADOR' FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','ads.campaigns.manage')");
db("UPDATE tb_conta_usuarios SET papel='VISUALIZADOR' WHERE id_conta_usuario=1004");
db("UPDATE tb_usuarios SET is_admin=true WHERE id=901");
db("CREATE TABLE policy_writes(id bigserial PRIMARY KEY,account_id bigint NOT NULL,marker text NOT NULL)");
assertThrowsType(function(){createObject('component','services.BusinessAccountDelegation').init('',true);},'BusinessDelegation.Validation','facade requires explicit datasource');
service=createObject('component','services.BusinessAccountDelegation').init(dsn,true);
store=createObject('component','services.accountDelegation.Store').init(dsn);
function saveMarker(required struct context) { queryExecute("INSERT INTO policy_writes(account_id,marker) VALUES(:id,'ok')",{id={value=context.accountId,cfsqltype='cf_sql_bigint'}},{datasource=context.datasource}); return 'saved'; }
function testThreeAccessPathsStaySeparate() {
 var directViewer=service.resolve(identity,selected('DIRECT'));
 var agencyManager=service.resolve(identity,selected('DELEGATED',101,2001));
 var secondAgencyViewer=service.resolve(identity,selected('DELEGATED',103,2002));
 assertEqual(service.has(directViewer,'ads.campaigns.manage'),false,'direct');
 assertEqual(service.has(agencyManager,'ads.campaigns.manage'),true,'delegated');
 assertEqual(service.has(secondAgencyViewer,'ads.campaigns.manage'),false,'other agency');
 assertEqual(service.has(agencyManager,'ads.payments.view'),true,'explicit financial view');
 assertEqual(service.has(secondAgencyViewer,'events.view'),true,'second agency own grants');
 var paths=service.listAccess(identity); var clientPaths=[];
 for(var option in paths) if(option.selection.accountId==102) arrayAppend(clientPaths,option.selectionKey);
 assertEqual(arrayLen(clientPaths),3,'three distinct paths to client');
 var uniqueKeys={};for(var key in clientPaths) uniqueKeys[key]=true;
 assertEqual(structCount(uniqueKeys),3,'distinct canonical keys preserve each path');
 assertThrowsType(function(){service.resolve(identity,selected('INTERNAL_SIMULATION'));},'BusinessDelegation.Forbidden','browser cannot simulate');
 var spoof=duplicate(identity);spoof.is_admin=true;spoof.is_dev=true;
 assertThrowsType(function(){service.resolve(spoof,selected('INTERNAL_SIMULATION'));},'BusinessDelegation.Forbidden','forged internal flags ignored');
 var internal=service.resolve({id=901},selected('INTERNAL_SIMULATION'));
 assertEqual(service.has(internal,'ads.campaigns.manage'),true,'DB internal administrator');
 assertThrowsType(function(){service.resolve({id=901},selected('DIRECT'));},'BusinessDelegation.Forbidden','internal authority cannot fill a missing direct membership');
 assertThrowsType(function(){service.resolve(identity,selected('DELEGATED',101,2002));},'BusinessDelegation.Forbidden','relationship cannot be switched');
}
function testDirectAdminAdsCompatibility(){
 var policy=createObject('component','services.accountDelegation.Policy');
 assertEqual(arrayFind(policy.directCapabilities('VISUALIZADOR',[]),'ads.credits.purchase')>0,false,'optional admin default preserves callers');
 db("UPDATE tb_usuarios SET is_admin=true WHERE id=902");
 for(var role in ['OPERADOR','VISUALIZADOR']) {
  db('UPDATE tb_conta_usuarios SET papel=CAST(:role AS papel_usuario_conta) WHERE id_conta_usuario=1010',{role={value=role,cfsqltype='cf_sql_varchar'}});
  var ctx=service.resolve(identity,selected('DIRECT'));
  for(var cap in ['ads.campaigns.view','ads.campaigns.manage','ads.payments.view','ads.credits.purchase']) assertEqual(service.has(ctx,cap),true,'current DIRECT DB admin Ads');
  for(var cap in ['events.view','events.manage','events.links.request']) assertEqual(service.has(ctx,cap),false,'admin Ads override does not add Events');
  assertEqual(service.withMutation(ctx,'ads.credits.purchase',ctx,{type='ACCOUNT',id=102},saveMarker),'saved','locked DIRECT admin authorization');
  var other=service.resolve(identity,selected('DELEGATED',103,2002));
  assertEqual(service.has(other,'ads.credits.purchase'),false,'internal flag never crosses delegated path');
 }
 db('UPDATE tb_usuarios SET is_admin=false,is_dev=true WHERE id=902');
 var dev=service.resolve({id=902,is_admin=true},selected('DIRECT'));
 assertEqual(service.has(dev,'ads.credits.purchase'),false,'is_dev and supplied admin flag are not legacy Ads authority');
 db('UPDATE tb_usuarios SET is_dev=false WHERE id=902');
 db("DELETE FROM policy_writes");
}
function testViewerCannotInheritWrite() {
 db("INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3003,2001,id_permissao FROM tb_business_permissoes WHERE codigo='ads.campaigns.manage'");
 var viewer=service.resolve({id=905},selected('DELEGATED',101,2001));
 assertEqual(service.has(viewer,'ads.campaigns.manage'),false,'viewer role clips incorrect write assignment');
 assertEqual(service.has(viewer,'ads.campaigns.view'),true,'viewer keeps view');
 db("UPDATE tb_conta_usuarios SET papel='MEDICO' WHERE id_conta_usuario=1005");
 assertThrowsType(function(){service.resolve({id=905},selected('DELEGATED',101,2001));},'BusinessDelegation.Forbidden','current medico role denies');
 db("UPDATE tb_conta_usuarios SET papel='VISUALIZADOR' WHERE id_conta_usuario=1005");
 db("DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=3001 AND id_permissao IN(SELECT id_permissao FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','ads.payments.view'))");
 var buyer=service.resolve(identity,selected('DELEGATED',101,2001));
 assertEqual(service.has(buyer,'ads.campaigns.view'),true,'manage implies view');
 assertEqual(service.has(buyer,'ads.credits.purchase'),true,'buyer retains explicit purchase');
 assertEqual(service.has(buyer,'ads.payments.view'),false,'purchase does not imply payment history');
 db("DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=3001 AND id_permissao IN(SELECT id_permissao FROM tb_business_permissoes WHERE codigo='ads.campaigns.manage')");
 buyer=service.resolve(identity,selected('DELEGATED',101,2001));
 assertEqual(service.has(buyer,'ads.credits.purchase'),false,'financial requires campaign view');
 db("INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3001,2001,id_permissao FROM tb_conta_gestao_permissoes WHERE id_vinculo=2001 ON CONFLICT DO NOTHING");
}
function testDeletedMembershipDoesNotResurrect() {
 var old=service.resolve(identity,selected('DELEGATED',101,2001));
 // Existing account management physically deletes membership rows.
 db("DELETE FROM tb_conta_usuarios WHERE id_conta_usuario=1001");
 db("INSERT INTO tb_conta_usuarios VALUES(1011,101,902,'OWNER','ATIVO')");
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_equipe WHERE id_equipe=3001").n[1],0,'physical removal removes old assignment');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=3001").n[1],0,'physical removal removes old grants');
 assertThrowsType(function(){service.resolve(identity,selected('DELEGATED',101,2001));},'BusinessDelegation.Forbidden','new membership has no old assignment');
 assertThrowsType(function(){service.withMutation(old,'ads.campaigns.manage',old,{type='ACCOUNT',id=102},saveMarker);},'BusinessDelegation.Forbidden','old context cannot resurrect assignment');
 // Fresh explicit assignment is allowed, but never authorizes a context carrying the old membership PK.
 db("INSERT INTO tb_conta_gestao_equipe(id_equipe,id_vinculo,id_conta_usuario,status) VALUES(3011,2001,1011,'ATIVO')");
 db("INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3011,2001,id_permissao FROM tb_conta_gestao_permissoes WHERE id_vinculo=2001");
 assertThrowsType(function(){service.withMutation(old,'ads.campaigns.manage',old,{type='ACCOUNT',id=102},saveMarker);},'BusinessDelegation.Conflict','recreated assigned member invalidates old context PK');
 // Restore synthetic fixture explicitly for later cases; this is a new grant, not automatic resurrection.
 db("DELETE FROM tb_conta_usuarios WHERE id_conta_usuario=1011");
 db("INSERT INTO tb_conta_usuarios VALUES(1001,101,902,'OWNER','ATIVO')");
 db("INSERT INTO tb_conta_gestao_equipe(id_equipe,id_vinculo,id_conta_usuario,status) VALUES(3001,2001,1001,'ATIVO')");
 db("INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3001,2001,id_permissao FROM tb_conta_gestao_permissoes WHERE id_vinculo=2001");
}
function testFreshStatusTokensAndAtomicAudit() {
 var ctx=service.resolve(identity,selected('DELEGATED',101,2001));
 var posted=duplicate(ctx);posted.formToken=service.formToken(ctx,'session-secret-12345678901234567890');
 service.verifyForm(ctx,posted,'session-secret-12345678901234567890');
 assertThrowsType(function(){service.verifyForm(ctx,posted,'another-session-secret-1234567890');},'BusinessDelegation.Forbidden','different session nonce');
 var switched=duplicate(ctx);switched.accountId=104;
 assertThrowsType(function(){service.verifyForm(switched,posted,'session-secret-12345678901234567890');},'BusinessDelegation.Conflict','account switch invalidates form');
 var bad=duplicate(posted);bad.accountId=[102];
 assertThrowsType(function(){service.verifyForm(ctx,bad,'session-secret-12345678901234567890');},'BusinessDelegation.Validation','array identifier rejected');
 bad=duplicate(posted);bad.relationshipId='2001,2002';
 assertThrowsType(function(){service.verifyForm(ctx,bad,'session-secret-12345678901234567890');},'BusinessDelegation.Validation','duplicate identifier rejected');
 db("UPDATE tb_conta_gestao_vinculos SET version=version+1 WHERE id_vinculo=2001");
 assertThrowsType(function(){service.withMutation(ctx,'ads.campaigns.manage',ctx,{type='ACCOUNT',id=102},saveMarker);},'BusinessDelegation.Conflict','stale relation cannot write');
 var fresh=service.resolve(identity,selected('DELEGATED',101,2001));
 assertThrowsType(function(){service.withMutation(fresh,'ads.campaigns.manage',fresh,{type='RELATIONSHIP',id=2002},saveMarker);},'BusinessDelegation.NotFound','other agency relationship is out of delegated scope');
 assertThrowsType(function(){service.verifyForm(fresh,posted,'session-secret-12345678901234567890');},'BusinessDelegation.Conflict','old version form invalidated');
 db("INSERT INTO tb_usuarios_gestao(id_usuario,ativo) VALUES(902,false)");
 assertThrowsType(function(){service.withMutation(fresh,'ads.campaigns.manage',fresh,{type='ACCOUNT',id=102},saveMarker);},'BusinessDelegation.Forbidden','actor disabled after render');
 db("UPDATE tb_usuarios_gestao SET ativo=true,excluido=true WHERE id_usuario=902");
 assertThrowsType(function(){service.resolve(identity,selected('DELEGATED',101,2001));},'BusinessDelegation.Forbidden','deleted actor');
 db("DELETE FROM tb_usuarios_gestao WHERE id_usuario=902");
 assertThrowsType(function(){service.withMutation(fresh,'ads.campaigns.manage',fresh,{type='ACCOUNT',id=103},saveMarker);},'BusinessDelegation.NotFound','other account resource');
 assertThrowsType(function(){service.withMutation(fresh,'ads.campaigns.manage',fresh,{type='ACCOUNT',id=102},function(c){saveMarker(c);throw(type='PolicyWorkFailure');});},'PolicyWorkFailure','callback rollback');
 assertEqual(db('SELECT count(*) n FROM policy_writes').n[1],0,'failures never write');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE resultado='SUCCESS'").n[1],0,'failures never audit success');
 assertEqual(service.withMutation(fresh,'ads.campaigns.manage',fresh,{type='ACCOUNT',id=102},saveMarker),'saved','callback return');
 assertEqual(db('SELECT count(*) n FROM policy_writes').n[1],1,'successful write');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE resultado='SUCCESS' AND id_usuario_ator=902 AND id_conta_cliente=102 AND id_vinculo=2001").n[1],1,'transactional success audit');
 assertThrowsType(function(){createObject('component','services.BusinessAccountDelegation').init(dsn,false).resolve(identity,selected('DELEGATED',101,2001));},'BusinessDelegation.Unavailable','disabled delegation');
 db("UPDATE tb_conta_gestoras SET habilitada=false WHERE id_conta=101");
 assertThrowsType(function(){service.resolve(identity,selected('DELEGATED',101,2001));},'BusinessDelegation.Forbidden','disabled manager');
 db("UPDATE tb_conta_gestoras SET habilitada=true WHERE id_conta=101");
}
testThreeAccessPathsStaySeparate();testViewerCannotInheritWrite();testDeletedMembershipDoesNotResurrect();testFreshStatusTokensAndAtomicAudit();
function waitForBlockedAccountLock() {
 var deadline=getTickCount()+10000;
 while(getTickCount()<deadline) {
  db("SELECT pg_stat_clear_snapshot()");
  var blocked=db("SELECT count(*) n FROM pg_stat_activity WHERE datname=current_database() AND pid<>pg_backend_pid() AND wait_event_type='Lock' AND query LIKE '%SELECT id_conta FROM tb_contas%'");
  if(blocked.n[1]>0) return true;
  sleep(20);
 }
 return false;
}
function testRevocationWinsBeforeMutation() {
 var beforeWrites=db('SELECT count(*) n FROM policy_writes').n[1];
 var beforeAudit=db('SELECT count(*) n FROM tb_conta_gestao_auditoria').n[1];
 var ctx=service.resolve(identity,selected('DELEGATED',101,2001));
 var lockObserved=false;
 transaction isolation='read_committed' {
  store.lockScope([101,102],[902]);
  db("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO',version=version+1 WHERE id_vinculo=2001");
  thread name='revokeFirstMutation' svc=service ctx=ctx testDsn=dsn {
   try {
    attributes.svc.withMutation(attributes.ctx,'ads.campaigns.manage',attributes.ctx,{type='ACCOUNT',id=102},function(c){
     queryExecute("INSERT INTO policy_writes(account_id,marker) VALUES(102,'must-never-commit')",{},{datasource=c.datasource});return true;
    });
    thread.outcome='UNSAFE_SUCCESS';
   } catch(any e) {thread.outcome=e.type;thread.detail=e.message;}
  }
  lockObserved=waitForBlockedAccountLock();
 }
 thread action='join' name='revokeFirstMutation' timeout=15000;
 assertEqual(lockObserved,true,'independent connection waits for revocation locks');
 assertEqual(cfthread.revokeFirstMutation.status,'COMPLETED','blocked mutation completes');
 assertEqual(cfthread.revokeFirstMutation.outcome,'BusinessDelegation.Forbidden','committed revocation wins before lock acquisition');
 assertEqual(db('SELECT count(*) n FROM policy_writes').n[1],beforeWrites,'revocation prevented write');
 assertEqual(db('SELECT count(*) n FROM tb_conta_gestao_auditoria').n[1],beforeAudit,'revocation prevented success audit');
 writeOutput('PASS policy revocation-before-mutation, observed real PostgreSQL lock wait' & chr(10));
 db("UPDATE tb_conta_gestao_vinculos SET status='ATIVO',version=version+1 WHERE id_vinculo=2001");
}
function testMutationCommittedBeforeRevocationStaysAudited() {
 var ctx=service.resolve(identity,selected('DELEGATED',101,2001));
 var entered=createObject('java','java.util.concurrent.CountDownLatch').init(1);
 var release=createObject('java','java.util.concurrent.CountDownLatch').init(1);
 var seconds=createObject('java','java.util.concurrent.TimeUnit').SECONDS;
 thread name='mutationFirst' svc=service ctx=ctx entered=entered release=release seconds=seconds {
  try {
   attributes.svc.withMutation(attributes.ctx,'ads.campaigns.manage',attributes.ctx,{type='ACCOUNT',id=102},function(c){
    queryExecute("INSERT INTO policy_writes(account_id,marker) VALUES(102,'before-revoke')",{},{datasource=c.datasource});
    attributes.entered.countDown();
    if(!attributes.release.await(javacast('long',10),attributes.seconds)) throw(type='RaceTimeout',message='Release not received');
    return true;
   });thread.outcome='SUCCESS';
  } catch(any e) {thread.outcome=e.type;thread.detail=e.message;attributes.entered.countDown();}
 }
 var enteredInTime=entered.await(javacast('long',10),seconds);
 thread name='mutationFirstRevoker' testDsn=dsn {
  try {
   var revoker=createObject('component','services.accountDelegation.Store').init(attributes.testDsn);
   transaction isolation='read_committed' {
    revoker.lockScope([101,102],[902]);
    revoker.execute("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO',version=version+1 WHERE id_vinculo=2001");
   }
   thread.outcome='SUCCESS';
  } catch(any e) {thread.outcome=e.type;thread.detail=e.message;}
 }
 var blocked=waitForBlockedAccountLock();
 release.countDown();
 thread action='join' name='mutationFirst,mutationFirstRevoker' timeout=15000;
 assertEqual(enteredInTime,true,'mutation entered callback under real locks');
 assertEqual(blocked,true,'revoker on another connection waits for mutation');
 assertEqual(cfthread.mutationFirst.outcome,'SUCCESS','mutation committed first');
 assertEqual(cfthread.mutationFirstRevoker.outcome,'SUCCESS','revocation committed second');
 assertEqual(db("SELECT count(*) n FROM policy_writes WHERE marker='before-revoke'").n[1],1,'committed write remains');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE resultado='SUCCESS'").n[1],2,'both earlier mutations remain audited');
 assertThrowsType(function(){service.withMutation(ctx,'ads.campaigns.manage',ctx,{type='ACCOUNT',id=102},saveMarker);},'BusinessDelegation.Forbidden','further mutation denied');
 writeOutput('PASS policy mutation-before-revocation, observed real PostgreSQL lock wait' & chr(10));
}
testRevocationWinsBeforeMutation();testMutationCommittedBeforeRevocationStaysAudited();testDirectAdminAdsCompatibility();
</cfscript>
