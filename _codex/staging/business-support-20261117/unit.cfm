<cfscript>
svc=new services.BusinessSupportSession();auth=new services.BusinessAuthSession();checks=0;meta={reason='teste_rollback',method='POST',path='/suporte/acesso/'};
function check(required boolean ok,required string label){checks++;if(!ok)throw(type='Support.Test',message=label);}
function rejects(required any action){try{action();return false;}catch(BusinessSupport.Forbidden e){return true;}}
function fresh(){return {businessAuthenticatedIdentity={version=1,id=139,sub='isolated-fixture',email='operator@example.org',name='Operator',imagem_usuario=''},businessRememberSelector='original-device',businessRememberCheckedAt=now(),cachedProfile={is_admin=true},agendaManagementCsrfToken='stale'};}
transaction {try {
 state=fresh();principal=auth.identity(state);token=svc.startToken(state,136808);
 check(rejects(function(){svc.begin(state,principal,136808,token,'GET','1',meta);}), 'GET cannot start');
 check(rejects(function(){svc.begin(state,principal,136808,repeatString('a',64),'POST','1',meta);}), 'invalid CSRF');
 check(rejects(function(){svc.begin(state,principal,136808,token,'POST','0',meta);}), 'confirmation required');
 check(rejects(function(){svc.begin(state,{id=136808},136808,token,'POST','1',meta);}), 'ordinary user cannot impersonate');
 check(rejects(function(){svc.target(principal,state,139);}), 'admin target denied');
 state.businessSimulatedAccountId=25;check(rejects(function(){svc.target(principal,state,136808);}), 'simulation cannot start');structDelete(state,'businessSimulatedAccountId');
 state.businessAccessSelection={accessMode='DELEGATED'};check(rejects(function(){svc.target(principal,state,136808);}), 'delegated cannot start');structDelete(state,'businessAccessSelection');
 check(rejects(function(){svc.target(principal,state,999999999);}), 'missing target denied');
 supported=svc.begin(state,principal,136808,token,'POST','1',meta);
 check(auth.identity(state).id==139,'original Google principal retained only for operator restore');
 check(!structKeyExists(state,'cachedProfile')&&!structKeyExists(state,'agendaManagementCsrfToken')&&!structKeyExists(state,'businessSupportCsrf'),'previous context and CSRF discarded');
 check(state.businessRememberSelector=='original-device','original remember binding retained');
 current=svc.current(state,principal,meta);check(current.identity.id==136808&&current.actorId==139,'effective target and real operator separated');
 check(!structKeyExists(current.identity,'sub')&&!structKeyExists(current.identity,'version'),'support identity cannot become Google or persistent-device principal');
 check(dateDiff('s',now(),current.expiresAt)>1700&&dateDiff('s',now(),current.expiresAt)<=1800,'30 minute absolute expiry');
 check(rejects(function(){svc.target(principal,state,136808);}), 'nested support denied');
 check(rejects(function(){svc.finish(state,principal,repeatString('b',64),'POST',meta);}), 'invalid stop CSRF');
 check(rejects(function(){svc.finish(state,principal,current.stopToken,'GET',meta);}), 'GET cannot restore admin');
 check(rejects(function(){svc.current(state,{id=136808},meta);}), 'support bound to authenticated operator');
 svc.recordRequest(state,meta);
 svc.finish(state,principal,current.stopToken,'POST',meta);check(!structKeyExists(state,'businessSupportSession')&&auth.identity(state).id==139,'stop restores clean operator');
 audits=queryExecute("SELECT acao,id_usuario_autor,id_usuario_alvo,dados_novos FROM tb_usuarios_gestao_auditoria WHERE dados_novos->>'SUPPORTID'=:id ORDER BY id_auditoria",{id={value=supported.id,cfsqltype='cf_sql_varchar'}},{datasource='runner_dba'});
 check(audits.recordCount==3,'start request stop audit');
 for(row in audits)check(row.id_usuario_autor==139&&row.id_usuario_alvo==136808&&!findNoCase(current.stopToken,row.dados_novos),'audit retains operator and target without token');
 state=fresh();token=svc.startToken(state,136808);svc.begin(state,principal,136808,token,'POST','1',meta);state.businessSupportSession.expiresAt=dateAdd('s',-1,now());
 expired=svc.current(state,principal,meta);check(expired.ended&&expired.reason=='expirada'&&!structKeyExists(state,'businessSupportSession'),'expiry clears context before next action');
 state=fresh();token=svc.startToken(state,136808);svc.begin(state,principal,136808,token,'POST','1',meta);state.businessSupportSession.targetEmail='changed@example.org';
 check(svc.current(state,principal,meta).ended,'changed target identity revokes support');
 state=fresh();token=svc.startToken(state,136808);svc.begin(state,principal,136808,token,'POST','1',meta);svc.logout(state,meta);
 check(!structKeyExists(state,'businessSupportSession'),'logout clears support');
 report={passed=checks,rollback=true};
}finally{transaction action='rollback';}}
remaining=queryExecute("SELECT count(*) total FROM tb_usuarios_gestao_auditoria WHERE dados_novos->>'SUPPORTID'=:id",{id={value=supported.id,cfsqltype='cf_sql_varchar'}},{datasource='runner_dba'});check(remaining.total==0,'rollback removed audit records');report.passed=checks;writeOutput(serializeJSON(report));
</cfscript>
