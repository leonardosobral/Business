<cfscript>
dsn=application.delegationTest.datasource;
function db(required string sql) {return queryExecute(sql,{}, {datasource=application.delegationTest.datasource});}
policy=createObject('component','services.accountDelegation.Policy');
service=createObject('component','services.BusinessAccountDelegation').init(dsn,true);
identity={id=902,email='owner@example.test',emailVerified=true,accessMode='DIRECT'};
function stateForClient(){return {businessAccessSelection={accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001},businessDelegationFormSeed=repeatString('s',64)};}
function boundary(boolean enabled=true){return createObject('component','services.accountDelegation.RequestBoundary').init(application.delegationTest.datasource,enabled);}
function testBoundaryBeforeQueries(){
 var state=stateForClient();var queryCounter=0;
 var response=boundary().handle(identity,state,'/crm/index.cfm','GET',{},{});
 if(response.status==200){db('SELECT * FROM tb_contas');queryCounter++;}
 assertEqual(response.status,403,'denied');assertEqual(queryCounter,0,'before business data');
 var home=boundary().handle(identity,state,'/index.cfm','GET',{},{});
 assertEqual(home.status,200,'authorized home');assertEqual(home.context.accountId,'102','selected client');
 for(var path in ['/ads/includes/backend.cfm','/eventos/form_edicao.cfm','/api/ads/payments/webhook.cfm','/api/ads/payments/reconcile.cfm','/home_logado.cfm','/administracao/contas/index.cfm']) assertEqual(boundary().handle(identity,state,path,'GET',{},{}).status,403,'exact routes only ' & path);
 assertEqual(boundary().handle(identity,state,'/index.cfm','GET',{resetApp='1'},{}).status,403,'application reset denied');
 assertEqual(boundary().handle(identity,state,'/ads/index.cfm','GET',{}, {},'/unexpected').status,403,'PATH_INFO denied');
}
function testNestedBiDenied(){assertEqual(boundary().handle(identity,stateForClient(),'/bi/index.cfm','GET',{},{}).status,403,'nested BI denied');}
function testRemoteCfcDenied(){for(var path in ['/leaderboard/api/leaderboard.cfc','/leaderboard/api/transmissao.cfc']) assertEqual(boundary().handle(identity,stateForClient(),path,'POST',{method='ranking'},{}).status,403,'remote denied');}
function testDuplicateParametersRejected(){
 var state=stateForClient();
 for(var bad in [{ads_v1_action=['save_campaign','credit_account']},{ads_v1_action='save_campaign,credit_account'},{ads_v1_action='save_campaign',action='credit_account'}]) assertEqual(boundary().handle(identity,state,'/ads/index.cfm','POST',{},bad).status,403,'duplicate/alias mutation denied');
 assertEqual(boundary().handle(identity,state,'/ads/index.cfm','GET',{id_evento='1,2'},{}).status,403,'duplicate scalar id');
 assertEqual(boundary().handle(identity,state,'/ads/index.cfm','GET',{}, {},'','id_evento=1&id_evento=1').status,403,'raw duplicate even same value');
 assertThrowsType(function(){policy.normalizeSelection({accountId=[102],accessMode='DIRECT'});},'BusinessDelegation.Validation','selection array');
}
function testStaleTabCannotChangeClient(){
 var b=boundary();var state=stateForClient();var previous=service.resolve(identity,state.businessAccessSelection);
 var formData=policy.formFields(previous,service.formToken(previous,state.businessDelegationFormSeed));formData.ads_v1_action='save_campaign';
 state.businessAccessSelection={accountId=102,accessMode='DELEGATED',managerAccountId=103,relationshipId=2002};
 var changesToWrongClient=0;var response=b.handle(identity,state,'/ads/index.cfm','POST',{},formData);
 if(response.status==200) changesToWrongClient++;
 assertEqual(response.status,409,'stale context rejected');assertEqual(changesToWrongClient,0,'stale form');
 state.businessAccessSelection={accountId=101,accessMode='DIRECT',managerAccountId=0,relationshipId=0};
 assertEqual(b.handle(identity,state,'/ads/index.cfm','POST',{},formData).status,409,'delegated form cannot mutate newly selected direct account');
 assertEqual(boundary(false).handle(identity,state,'/ads/index.cfm','POST',{},formData).status,409,'feature off cannot downgrade a signed delegated form');
 var switchState=stateForClient();var switchFields=b.selectionFields(switchState);
 switchState.businessAccessSelection={accountId=102,accessMode='DELEGATED',managerAccountId=103,relationshipId=2002};
 structAppend(switchFields,{accountId=101,accessMode='DIRECT',managerAccountId=0,relationshipId=0});
 assertEqual(b.handle(identity,switchState,'/selecionar-conta/index.cfm','POST',{},switchFields).status,409,'stale selector cannot change new context');
 assertEqual(switchState.businessAccessSelection.managerAccountId,103,'new selection preserved');
}
function testRevokedSelectionHasNoFallback(){
 var state=stateForClient();state.businessActiveAccountId=101;
 db("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO' WHERE id_vinculo=2001");
 var response=boundary().handle(identity,state,'/ads/index.cfm','GET',{},{});
 assertEqual(response.status,403,'revocation denied');assertEqual(structIsEmpty(response.context),true,'no fallback context');assertEqual(state.businessAccessSelectionInvalid,true,'choose again persisted');
 assertEqual(structKeyExists(state,'businessActiveAccountId'),false,'effective legacy id cleared');
 db("UPDATE tb_conta_gestao_vinculos SET status='ATIVO' WHERE id_vinculo=2001");
 assertEqual(boundary().handle(identity,state,'/index.cfm','GET',{},{}).status,403,'reactivation is not silent reselection');
 assertEqual(boundary().handle(identity,state,'/selecionar-conta/index.cfm','GET',{resetApp='1'},{}).status,403,'invalid state recovery does not allow global mutation');
 for(var path in ['/selecionar-conta/index.cfm','/logout.cfm','/convites/index.cfm']) assertEqual(boundary().handle(identity,state,path,'GET',{},{}).status,200,'recovery path');
 for(var scenario in ['disabled','schema']){
  state=stateForClient();if(scenario=='schema') db('DELETE FROM tb_business_delegacao_schema WHERE version=1');
  response=boundary(scenario!='disabled').handle(identity,state,'/index.cfm','GET',{},{});
  assertEqual(response.status,403,'unavailable delegated state denied');assertEqual(state.businessAccessSelectionInvalid,true,'unavailable state remains invalid');
  if(scenario=='schema') db('INSERT INTO tb_business_delegacao_schema(version) VALUES(1)');
 }
}
function testRouteActionInventory(){
 for(var action in ['save_campaign','prepare_campaign_edit','submit_campaign_review','change_campaign_status']) assertEqual(policy.routePolicy('/ads/index.cfm','POST',{}, {ads_v1_action=action}).capability,'ads.campaigns.manage',action);
 assertEqual(policy.routePolicy('/ads/index.cfm','POST',{}, {ads_v1_action='create_payment_checkout'}).capability,'ads.credits.purchase','purchase');
 for(var action in ['approve_campaign_review','credit_account','redeem_voucher','reserve_voucher','reverse_click_debit']) assertEqual(policy.routePolicy('/ads/index.cfm','POST',{}, {ads_v1_action=action}).allowed,false,'forbidden action');
 assertEqual(policy.routePolicy('/ads/canonical/index.cfm','GET',{},{}).allowed,true,'read-only canonical alias');
 assertEqual(policy.routePolicy('/ads/canonical/index.cfm','POST',{}, {ads_v1_action='save_campaign'}).allowed,false,'alias mutation denied');
 assertEqual(policy.routePolicy('/eventos/index.cfm','POST',{}, {evento_solicitacao_action='solicitar'}).capability,'events.links.request','event link');
 assertEqual(policy.routePolicy('/eventos/index.cfm','POST',{}, {evento_solicitacao_action='aprovar'}).allowed,false,'internal event approval denied');
 for(var eventAction in ['editar_evento_basico','editar_evento_fornecedores','editar_evento_competition_id','editar_evento_descricao','editar_evento_percursos','salvar_evento_percurso']) assertEqual(policy.routePolicy('/eventos/index.cfm','POST',{}, {action=eventAction}).capability,'events.manage','real Task10 event action ' & eventAction);
 assertEqual(policy.routePolicy('/eventos/index.cfm','POST',{}, {action='confirmar_inscricao_disponibilidade'}).allowed,false,'registration availability stays internal');
 var administrativeFields=policy.formFields(service.resolve(identity,stateForClient().businessAccessSelection),service.formToken(service.resolve(identity,stateForClient().businessAccessSelection),repeatString('s',64)));
 administrativeFields.action='confirmar_inscricao_disponibilidade';
 assertEqual(boundary().handle(identity,stateForClient(),'/eventos/index.cfm','POST',{},administrativeFields).status,403,'delegated event manager cannot change registration availability');

 assertEqual(policy.routePolicy('/portal/banners/index.cfm','POST',{}, {paid_banner_action='save'}).capability,'ads.campaigns.manage','CPC');
 assertEqual(policy.routePolicy('/portal/banners/index.cfm','POST',{}, {action='salvar_banner'}).allowed,false,'HOUSE denied');
 assertEqual(policy.routePolicy('/portal/banners/index.cfm','POST',{}, {paid_banner_action='save',view='house'}).allowed,false,'HOUSE form-view alias denied');
}
function testLegacyFeatureOffSelectionResynchronizes(){
 var oldSelection={accountId=101,accessMode='DIRECT',managerAccountId=0,relationshipId=0};
 var state={businessAccessSelection=oldSelection,businessActiveAccountId=101,businessDelegationFormSeed=repeatString('s',64)};
 var oldContext=service.resolve(identity,oldSelection);
 var oldForm=policy.formFields(oldContext,service.formToken(oldContext,state.businessDelegationFormSeed));oldForm.ads_v1_action='save_campaign';
 // Existing legacy handler has checked the requested account membership and CSRF before this point.
 service.resolve(identity,{accountId=103,accessMode='DIRECT',managerAccountId=0,relationshipId=0});
 state.businessActiveAccountId=103;
 boundary(false).clearLegacySelection(state);
 assertEqual(structKeyExists(state,'businessAccessSelection'),false,'successful legacy switch removes obsolete canonical selection');
 assertEqual(boundary(false).handle(identity,state,'/ads/index.cfm','POST',{},oldForm).status,409,'legacy switch still rejects old signed form');
 var enabledAgain=boundary().handle(identity,state,'/ads/index.cfm','GET',{},{});
 assertEqual(enabledAgain.context.accountId,'103','reenablement resolves explicitly selected legacy account');
 assertEqual(enabledAgain.context.accessMode,'DIRECT','legacy switch remains direct');
 var delegated=stateForClient();
 assertThrowsType(function(){boundary(false).clearLegacySelection(delegated);},'BusinessDelegation.Forbidden','legacy helper cannot discard delegated selection');
 var invalid={businessAccessSelectionInvalid=true};
 assertThrowsType(function(){boundary(false).clearLegacySelection(invalid);},'BusinessDelegation.Forbidden','legacy helper cannot discard invalid selection');
}
function testSelectionAndAuthReset(){
 var b=boundary();var state=stateForClient();var fields=b.selectionFields(state);
 structAppend(fields,{accountId=101,accessMode='DIRECT',managerAccountId=0,relationshipId=0});
 var response=b.handle(identity,state,'/selecionar-conta/index.cfm','POST',{},fields);
 assertEqual(response.status,200,'HTML selector works');assertEqual(state.businessAccessSelection.accessMode,'DIRECT','explicit direct selection');
 fields=b.selectionFields(state);structAppend(fields,{accountId=999,accessMode='DIRECT',managerAccountId=0,relationshipId=0});
 assertEqual(b.handle(identity,state,'/selecionar-conta/index.cfm','POST',{},fields).status,403,'invalid option denied');assertEqual(state.businessAccessSelectionInvalid,true,'invalid selection no fallback');
 var freshChoice=boundary().handle(identity,{},'/index.cfm','GET',{},{});
 assertEqual(freshChoice.selectionRequired,true,'multiple access paths require explicit choice');
 db('UPDATE tb_usuarios SET is_admin=true WHERE id=901');
 assertEqual(boundary().handle({id=901,email='reviewer@example.test',emailVerified=true,accessMode='DIRECT'}, {},'/administracao/contas/index.cfm','GET',{},{}).selectionRequired,false,'real internal admin needs no selected client');
 var fresh={};assertEqual(boundary(false).handle(identity,fresh,'/crm/index.cfm','GET',{},{}).status,200,'disabled clean legacy behavior');
 var auth=createObject('component','services.BusinessAuthSession');
 auth.establish(state,902,{sub='verified',email='Owner@Example.Test',name='Owner',picture=''});
 assertEqual(structKeyExists(state,'businessAccessSelection'),false,'login clears selection');assertEqual(structKeyExists(state,'businessAccessSelectionInvalid'),false,'login clears invalid state');assertEqual(structKeyExists(state,'businessDelegationFormSeed'),false,'login clears seed');
 assertEqual(auth.delegationIdentity(state).emailVerified,true,'only authenticated identity verified');assertEqual(structIsEmpty(auth.delegationIdentity({cadastroGoogleIdentity={id=902,email='owner@example.test'}})),true,'legacy registration not verified');
 auth.clear(state);assertEqual(structIsEmpty(auth.delegationIdentity(state)),true,'logout clears identity');
}
testRouteActionInventory();testBoundaryBeforeQueries();testNestedBiDenied();testRemoteCfcDenied();testDuplicateParametersRejected();testStaleTabCannotChangeClient();testRevokedSelectionHasNoFallback();testSelectionAndAuthReset();testLegacyFeatureOffSelectionResynchronizes();
</cfscript>
