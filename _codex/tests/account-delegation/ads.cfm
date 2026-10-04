<cfinclude template="ads-db.cfm"/>
<cfscript>
// Actual final installed SQL, real delegation, actual actor. No authority substitutes.
adsService.withMutation(adsContext,'ads.campaigns.manage',adsContext,{type='CAMPAIGN',id=adsSaved.id & ''},function(fresh){
 return queryExecute('SELECT * FROM ads.prepare_campaign_for_edit(CAST(:id AS uuid),:account,:actor)',{id={value=adsSaved.id,cfsqltype='cf_sql_varchar'},account={value=fresh.accountId,cfsqltype='cf_sql_bigint'},actor={value=fresh.actorId,cfsqltype='cf_sql_integer'}},{datasource=fresh.datasource});
});
writeOutput('PASS ads delegated canonical prepare' & chr(10));
</cfscript>

<cfscript>
application action="update" sessionmanagement=true;
application.businessAccountDelegationEnabled=true;
adsPolicy=createObject('component','services.accountDelegation.Policy');
SESSION.businessDelegationFormSeed=repeatString('ads-suite-',8);
queryExecute("DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=3002; INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3002,2001,id_permissao FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','ads.campaigns.manage')",{},{datasource='business_delegation_test'});
campaignManager=adsService.resolve({id=903},{accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001});
assertEqual(adsService.has(campaignManager,'events.view'),false,'Ads manager needs no Events grant');
REQUEST.businessAccessContext=campaignManager;
VARIABLES.businessRealIsAdmin=true;VARIABLES.businessCurrentAccountId=103;VARIABLES.businessCurrentAccountRole='OWNER';
</cfscript>
<cfinclude template="../../../ads/includes/access.cfm"/>
<cfinclude template="../../../portal/includes/banner_form_helpers.cfm"/>
<cfinclude template="../../../portal/includes/paid_banner_helpers.cfm"/>
<cfinclude template="../../../portal/includes/paid_banner_actions.cfm"/>
<cfinclude template="../../../ads/includes/campaign_mutations.cfm"/>
<cfscript>
function testCampaignManagerCannotBuy(){
    assertEqual(VARIABLES.adsAccessAccountId & '', '102','active client only');
    assertEqual(VARIABLES.adsAccessActorId & '', '903','actual actor');
    assertEqual(VARIABLES.adsAccessCanManageCampaign,true,'assigned manager');
    for(var flag in ['adsAccessCanPurchaseCredit','adsAccessCanViewPayments','adsAccessCanAdminFinance','adsAccessCanReviewCampaign','adsAccessCanAdminVouchers','adsAccessCanReserveVoucher']) assertEqual(VARIABLES[flag],false,flag);
    var fakeProvider=createObject('component','delegationTests.FakeAdsProvider');
    var payments=createObject('component','ads.components.AdsPaymentService').init('runnerhub',fakeProvider);
    assertThrowsType(function(){payments.createCheckout(102,903,5000,'business:payment:denied-manager',campaignManager);},'BusinessDelegation.Forbidden','manager cannot purchase');
    assertEqual(fakeProvider.calls,0,'denied purchase');
    assertEqual(queryExecute('SELECT count(*) AS n FROM ads.payment_intents',{},{datasource='business_delegation_test'}).n[1],0,'denied purchase has no intent');
}
function signedAdsForm(required struct context,required struct values){
    var posted=duplicate(values);structAppend(posted,adsPolicy.formFields(context,adsPolicy.formToken(context,SESSION.businessDelegationFormSeed)));return posted;
}
function testCampaignAndBannerKeepRealActor(){
    var posted=signedAdsForm(campaignManager,{paid_banner_action='save',paid_banner_csrf='banner-test',save_intent='submit',name='Delegated banner',alt_text='Synthetic fixture',destination_url='https://example.test/banner',starts_at=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn"),ends_at=dateTimeFormat(dateAdd('d',2,now()),"yyyy-mm-dd'T'HH:nn"),cpc_bid='1',budget_total='10',target_device='ALL',banner_regions_mode='ALL',banner_pages_mode='ALL'});
    var context={method='POST',csrf='banner-test',accountId=102,actorId=903,canManage=true,canReview=false};
    var saved=paidBannerSave(posted,context,{image_url_desktop='https://example.test/d.png',image_url_mobile='https://example.test/m.png',width_desktop=300,height_desktop=250,width_mobile=300,height_mobile=250});
    VARIABLES.taskBannerId=saved.campaign_id & '';
    var row=queryExecute('SELECT account_id,created_by,updated_by FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=taskBannerId,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'});
    assertEqual(row.account_id[1],102,'wallet');assertEqual(row.updated_by[1],903,'actor');
    var prepare=signedAdsForm(campaignManager,{paid_banner_action='prepare',paid_banner_csrf='banner-test',campaign_id=taskBannerId});
    paidBannerManage(prepare,context);
    assertEqual(queryExecute('SELECT status FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=taskBannerId,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'}).status[1],'DRAFT','delegated withdraw review');
    var foreignContext=duplicate(context);foreignContext.accountId=103;
    assertThrowsType(function(){paidBannerManage(prepare,foreignContext);},'AdsV1.Validation','foreign account banner denied');
    // Actual campaign handler callback consumes client event links, never Events effective IDs.
    queryExecute("ALTER TABLE tb_evento_corridas ADD COLUMN IF NOT EXISTS tag text; INSERT INTO tb_evento_corridas(id_evento,ativo,estado,tag) VALUES(701,true,'SP','synthetic-race'),(702,true,'SP','foreign-race'); INSERT INTO tb_conta_eventos VALUES(102,701,'ATIVO'),(103,702,'ATIVO')",{},{datasource='business_delegation_test'});
    VARIABLES.adsV1AccountId=102;VARIABLES.adsV1ActorId=903;VARIABLES.adsV1FormCampaignId='';VARIABLES.adsV1FormEventId=701;VARIABLES.adsAccessIsPendingNewAccount=false;
    VARIABLES.roadRunnersBaseUrl='https://example.test';VARIABLES.adsV1FormPlacementKeys=['rr-home-upcoming-native'];VARIABLES.adsV1FormPlacementArrayLiteral='{rr-home-upcoming-native}';
    VARIABLES.adsV1FormName='Delegated event';VARIABLES.adsV1FormCpc=1;VARIABLES.adsV1FormBudgetTotal=10;VARIABLES.adsV1FormBudgetDaily=5;VARIABLES.adsV1FormBudgetDailyRaw='5';
    VARIABLES.adsV1FormStarts=now();VARIABLES.adsV1FormEnds=dateAdd('d',2,now());VARIABLES.adsV1FormDevice='ALL';VARIABLES.adsV1FormCountry='BR';VARIABLES.adsV1FormRegion='';
    FORM.campaign_intent='submit';
    adsDelegationMutation(signedAdsForm(campaignManager,{}),'ads.campaigns.manage',{type='CAMPAIGN',id=''},adsV1MutationSave,VARIABLES);
    VARIABLES.taskEventId=VARIABLES.qAdsV1CampaignSave.campaign_id[1] & '';
    var eventSaved=queryExecute('SELECT account_id,updated_by FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=taskEventId,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'});
    assertEqual(eventSaved.account_id[1],102,'event wallet');assertEqual(eventSaved.updated_by[1],903,'event actor');
    VARIABLES.adsV1FormEventId=702;
    assertThrowsType(function(){adsDelegationMutation(signedAdsForm(campaignManager,{}),'ads.campaigns.manage',{type='CAMPAIGN',id=''},adsV1MutationSave,VARIABLES);},'AdsV1.Validation','foreign advertising event denied');
}
function testDelegatedActivationKeepsReviewGates(){
    // A genuine internal admin must receive only the selected delegated authority.
    queryExecute('UPDATE tb_usuarios SET is_admin=true WHERE id IN(901,903)',{},{datasource='business_delegation_test'});
    var runtimeStore=createObject('component','services.accountDelegation.Store').init('runnerhub');
    var activate=function(ctx,id){transaction {runtimeStore.setAdsContext(ctx);return queryExecute("SELECT ads.activate_campaign(CAST(:id AS uuid),903,'Fixture resume')",{id={value=id,cfsqltype='cf_sql_varchar'}},{datasource='runnerhub'});}};
    for(var id in [taskEventId,taskBannerId]) assertThrowsType(function(){activate(campaignManager,id);},'database','delegated admin cannot initially activate');
    // Approve solely through the pre-existing internal canonical review path, outside delegated context.
    queryExecute("SELECT ads.credit_account(102,100,'task9-fixture-credit','MANUAL',901,'{}')",{},{datasource='business_delegation_test'});
    var bannerPost=signedAdsForm(campaignManager,{paid_banner_action='submit',paid_banner_csrf='banner-test',campaign_id=taskBannerId});
    paidBannerManage(bannerPost,{method='POST',csrf='banner-test',accountId=102,actorId=903,canManage=true,canReview=false});
    for(var entry in [{id=taskBannerId,fn='review_paid_banner_campaign'},{id=taskEventId,fn='review_campaign'}]){
        var review=queryExecute('SELECT max(campaign_review_request_id) AS id FROM ads.campaign_review_requests WHERE campaign_id=CAST(:id AS uuid)',{id={value=entry.id,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'}).id[1];
        queryExecute("SELECT * FROM ads." & entry.fn & "(CAST(:id AS uuid),'APPROVE',901,'Fixture approved',:key,CAST(:review AS bigint))",{id={value=entry.id,cfsqltype='cf_sql_varchar'},key={value='task9-approve-' & entry.id,cfsqltype='cf_sql_varchar'},review={value=review,cfsqltype='cf_sql_bigint'}},{datasource='business_delegation_test'});
        adsService.withMutation(campaignManager,'ads.campaigns.manage',campaignManager,{type='CAMPAIGN',id=entry.id},function(fresh){return queryExecute("SELECT ads.change_campaign_status(CAST(:id AS uuid),'PAUSED',903,'Fixture pause')",{id={value=entry.id,cfsqltype='cf_sql_varchar'}},{datasource=fresh.datasource});});
        var stale=duplicate(campaignManager);stale.versions.relationshipVersion++;
        assertThrowsType(function(){activate(stale,entry.id);},'database','stale delegated internal admin denied');
        queryExecute("DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=3002 AND id_permissao=(SELECT id_permissao FROM tb_business_permissoes WHERE codigo='ads.campaigns.manage')",{},{datasource='business_delegation_test'});
        assertThrowsType(function(){activate(campaignManager,entry.id);},'database','missing grant cannot borrow admin');
        queryExecute("INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3002,2001,id_permissao FROM tb_business_permissoes WHERE codigo='ads.campaigns.manage'",{},{datasource='business_delegation_test'});
        adsService.withMutation(campaignManager,'ads.campaigns.manage',campaignManager,{type='CAMPAIGN',id=entry.id},function(fresh){return queryExecute("SELECT ads.activate_campaign(CAST(:id AS uuid),903,'Authorized resume')",{id={value=entry.id,cfsqltype='cf_sql_varchar'}},{datasource=fresh.datasource});});
        var current=queryExecute('SELECT status,updated_by FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=entry.id,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'});
        assertEqual(current.status[1],'ACTIVE','approved paused resume');assertEqual(current.updated_by[1],903,'resume actor');
    }
    queryExecute('UPDATE tb_usuarios SET is_admin=false WHERE id=903',{},{datasource='business_delegation_test'});
    writeOutput('PASS ads EVENT/BANNER delegated internal-admin stale/missing grant and initial activation denied; approved paused resume actual actor' & chr(10));
}
function testUncertainCheckoutIsIdempotent(){
    queryExecute("DELETE FROM tb_conta_gestao_equipe_permissoes WHERE id_equipe=3001 AND id_permissao IN(SELECT id_permissao FROM tb_business_permissoes WHERE codigo NOT IN('ads.campaigns.view','ads.credits.purchase'))",{},{datasource='business_delegation_test'});
    VARIABLES.buyer=adsService.resolve({id=902},{accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001});
    assertEqual(adsService.has(buyer,'ads.payments.view'),false,'purchase does not grant history');
    VARIABLES.fakeProvider=createObject('component','delegationTests.FakeAdsProvider');fakeProvider.uncertain=true;
    VARIABLES.payments=createObject('component','ads.components.AdsPaymentService').init('runnerhub',fakeProvider);
    var uncertain=payments.createCheckout(102,902,5000,'business:payment:uncertain-checkout',buyer);
    assertEqual(uncertain.success,false,'uncertain provider result is not success');
    var intent=queryExecute("SELECT payment_intent_id,account_id,created_by FROM ads.payment_intents WHERE idempotency_key='business:payment:uncertain-checkout'",{},{datasource='business_delegation_test'});
    assertEqual(intent.recordCount,1,'confirmed local intent survives uncertainty');assertEqual(intent.account_id[1],102,'wallet');assertEqual(intent.created_by[1],902,'intent actor');
    VARIABLES.ownPaymentId=intent.payment_intent_id[1] & '';
    var retry=payments.createCheckout(102,902,5000,'business:payment:uncertain-checkout',buyer);
    assertEqual(retry.success,true,'idempotent retry reconciles checkout');
    assertEqual(queryExecute("SELECT count(*) AS n FROM ads.payment_intents WHERE idempotency_key='business:payment:uncertain-checkout'",{},{datasource='business_delegation_test'}).n[1],1,'one intent');
    assertEqual(queryExecute("SELECT count(*) AS n FROM tb_conta_gestao_auditoria WHERE recurso_tipo='PAYMENT_INTENT' AND recurso_id=:id",{id={value=ownPaymentId,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'}).n[1],1,'one creation origin audit');
    var calls=fakeProvider.calls;payments.createCheckout(102,902,5000,'business:payment:uncertain-checkout',buyer);assertEqual(fakeProvider.calls,calls,'attached checkout reused');
}
function testBuyerCannotReadOtherPayments(){
    var own=payments.getIntentStatus(102,ownPaymentId,buyer);assertEqual(own.success,true,'own receipt');
    for(var field in ['actorId','createdBy','relationshipId','managerAccountId']) assertEqual(structKeyExists(own,field),false,'receipt does not disclose ' & field);
    var other=queryExecute("SELECT * FROM ads.create_payment_intent(102,904,5000,'BRL','business:payment:other-actor',now()+interval '1 hour')",{},{datasource='business_delegation_test'}).payment_intent_id[1] & '';
    assertEqual(payments.getIntentStatus(102,other,buyer).success,false,'other actor receipt denied');
    queryExecute("INSERT INTO tb_conta_gestao_permissoes SELECT 2002,id_permissao FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','ads.credits.purchase') ON CONFLICT DO NOTHING; INSERT INTO tb_conta_gestao_equipe_permissoes SELECT 3004,2002,id_permissao FROM tb_business_permissoes WHERE codigo IN('ads.campaigns.view','ads.credits.purchase') ON CONFLICT DO NOTHING",{},{datasource='business_delegation_test'});
    var second=adsService.resolve({id=902},{accountId=102,accessMode='DELEGATED',managerAccountId=103,relationshipId=2002});
    assertEqual(payments.getIntentStatus(102,ownPaymentId,second).success,false,'same actor different relation denied');
    assertThrowsType(function(){payments.createCheckout(102,902,5000,'business:payment:uncertain-checkout',second);},'BusinessDelegation.Forbidden','retry cannot change origin');
    var boundary=createObject('component','services.accountDelegation.RequestBoundary').init('runnerhub',true);
    var state={businessAccessSelection=buyer,businessDelegationFormSeed=SESSION.businessDelegationFormSeed};
    assertEqual(boundary.handle({id=902},state,'/ads/','GET',{view='payments'},{ }).status,200,'purchase page reachable');
    assertEqual(boundary.handle({id=902},state,'/api/ads/payments/status.cfm','GET',{payment=ownPaymentId},{}).status,200,'own receipt boundary');
    assertEqual(boundary.handle({id=902},state,'/api/ads/payments/status.cfm','GET',{payment=other},{}).status,403,'other receipt boundary');
    assertEqual(boundary.handle({id=902},state,'/ads/','GET',{view='payments',payment=other},{}).status,403,'other receipt page denied');
    state.businessAccessSelection=second;
    assertEqual(boundary.handle({id=902},state,'/api/ads/payments/status.cfm','GET',{payment=ownPaymentId},{}).status,403,'origin-bound receipt boundary');
}
function testRevokedPostDoesNotUpload(){
    var stale=signedAdsForm(campaignManager,{paid_banner_action='save'});
    queryExecute("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO',version=version+1 WHERE id_vinculo=2001",{},{datasource='business_delegation_test'});
    assertThrowsType(function(){adsDelegationValidate(stale,'ads.campaigns.manage');},'BusinessDelegation.Forbidden','revoked pre-upload validation');
    assertThrowsType(function(){payments.createCheckout(102,902,5000,'business:payment:uncertain-checkout',buyer);},'BusinessDelegation.Forbidden','revoked retry denied');
    assertEqual(queryExecute("SELECT count(*) AS n FROM ads.payment_intents WHERE idempotency_key='business:payment:uncertain-checkout'",{},{datasource='business_delegation_test'}).n[1],1,'revocation keeps earlier local intent');
    queryExecute("UPDATE tb_conta_gestao_vinculos SET status='ATIVO',version=version+1 WHERE id_vinculo=2001",{},{datasource='business_delegation_test'});
}
function testRevocationDuringProviderKeepsIntent(){
    var current=adsService.resolve({id=902},{accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001});
    var provider=createObject('component','delegationTests.FakeAdsProvider');provider.revoke=true;
    var service=createObject('component','ads.components.AdsPaymentService').init('runnerhub',provider);
    var result=service.createCheckout(102,902,5000,'business:payment:revoked-during-provider',current);
    assertEqual(result.success,true,'previously authorized intent reconciles after revoke');
    var intent=queryExecute("SELECT count(*) AS n FROM ads.payment_intents WHERE idempotency_key='business:payment:revoked-during-provider' AND provider_payment_link_id IS NOT NULL",{},{datasource='business_delegation_test'});
    assertEqual(intent.n[1],1,'one attached intent survives provider-time revoke');
    assertThrowsType(function(){service.createCheckout(102,902,5000,'business:payment:revoked-during-provider',current);},'BusinessDelegation.Forbidden','new revoked retry refused');
    assertEqual(provider.calls,1,'revoked retry never calls provider');
    queryExecute("UPDATE tb_conta_gestao_vinculos SET status='ATIVO',version=version+1 WHERE id_vinculo=2001",{},{datasource='business_delegation_test'});
    var directProvider=createObject('component','delegationTests.FakeAdsProvider');
    assertEqual(createObject('component','ads.components.AdsPaymentService').init('runnerhub',directProvider).createCheckout(102,904,5000,'business:payment:legacy-direct').success,true,'legacy four-argument direct checkout');
}
function testDirectInternalAdminSignedAds(){
    queryExecute("UPDATE tb_usuarios SET is_admin=true WHERE id=901; INSERT INTO tb_conta_usuarios(id_conta_usuario,id_conta,id_usuario,papel,status) VALUES(1009,102,901,'OPERADOR','ATIVO')",{},{datasource='business_delegation_test'});
    var original=REQUEST.businessAccessContext;
    for(var role in ['OPERADOR','VISUALIZADOR']){
        queryExecute('UPDATE tb_conta_usuarios SET papel=CAST(:role AS papel_usuario_conta) WHERE id_conta_usuario=1009',{role={value=role,cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'});
        var direct=adsService.resolve({id=901},{accountId=102,accessMode='DIRECT',managerAccountId=0,relationshipId=0});
        REQUEST.businessAccessContext=direct;
        var posted=signedAdsForm(direct,{});
        var validated=adsDelegationValidate(posted,'ads.credits.purchase');
        assertEqual(validated.actorId & '', '901','DIRECT admin signed ' & role);
        var provider=createObject('component','delegationTests.FakeAdsProvider');
        var paymentService=createObject('component','ads.components.AdsPaymentService').init('runnerhub',provider);
        var checkout=paymentService.createCheckout(102,901,5000,'business:payment:direct-admin-' & lCase(role),validated);
        assertEqual(checkout.success,true,'DIRECT admin checkout ' & role);
        assertEqual(paymentService.getIntentStatus(102,checkout.paymentIntentId,direct).success,true,'DIRECT admin status ' & role);
        var other=queryExecute("SELECT payment_intent_id FROM ads.payment_intents WHERE idempotency_key='business:payment:other-actor'",{},{datasource='business_delegation_test'}).payment_intent_id[1] & '';
        assertEqual(paymentService.getIntentStatus(102,other,direct).success,true,'DIRECT admin payment access ' & role);
        var banner=signedAdsForm(direct,{paid_banner_action='save',paid_banner_csrf='direct-test',save_intent='submit',name='Direct admin ' & role,alt_text='Synthetic admin banner',destination_url='https://example.test/banner',starts_at=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn"),ends_at=dateTimeFormat(dateAdd('d',2,now()),"yyyy-mm-dd'T'HH:nn"),cpc_bid='1',budget_total='10',target_device='ALL',banner_regions_mode='ALL',banner_pages_mode='ALL'});
        var directBanner={method='POST',csrf='direct-test',accountId=102,actorId=901,canManage=true,canReview=true};
        adsDelegationValidate(banner,'ads.campaigns.manage');
        var saved=paidBannerSave(banner,directBanner,{image_url_desktop='https://example.test/d.png',image_url_mobile='https://example.test/m.png',width_desktop=300,height_desktop=250,width_mobile=300,height_mobile=250});
        var review=signedAdsForm(direct,{paid_banner_action='review',paid_banner_csrf='direct-test',campaign_id=saved.campaign_id & '',decision='APPROVE',review_id=saved.campaign_review_request_id & '',reason='Synthetic internal review'});
        // Actual backend's shared pre-upload/review validation followed by actual canonical review handler.
        adsDelegationValidate(review,'ads.campaigns.manage');paidBannerManage(review,directBanner);
        var approved=queryExecute('SELECT status,updated_by FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=saved.campaign_id & '',cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'});
        assertEqual(approved.status[1],'ACTIVE','DIRECT admin banner review ' & role);assertEqual(approved.updated_by[1],901,'DIRECT admin real actor');
        var pause=signedAdsForm(direct,{paid_banner_action='pause',paid_banner_csrf='direct-test',campaign_id=saved.campaign_id & ''});paidBannerManage(pause,directBanner);
        var prepare=signedAdsForm(direct,{paid_banner_action='prepare',paid_banner_csrf='direct-test',campaign_id=saved.campaign_id & ''});paidBannerManage(prepare,directBanner);
        // Existing EVENT handler callback, not a synthetic authority-only write.
        VARIABLES.adsV1AccountId=102;VARIABLES.adsV1ActorId=901;VARIABLES.adsV1FormEventId=701;VARIABLES.adsV1FormCampaignId='';VARIABLES.adsV1FormName='DIRECT admin event ' & role;
        adsDelegationMutation(posted,'ads.campaigns.manage',{type='CAMPAIGN',id=''},adsV1MutationSave,VARIABLES);
        assertEqual(queryExecute('SELECT updated_by FROM ads.campaigns WHERE campaign_id=CAST(:id AS uuid)',{id={value=VARIABLES.qAdsV1CampaignSave.campaign_id[1] & '',cfsqltype='cf_sql_varchar'}},{datasource='business_delegation_test'}).updated_by[1],901,'DIRECT admin event handler ' & role);
        var stale=duplicate(posted);stale.business_access_accountId=101;
        assertThrowsType(function(){adsDelegationValidate(stale,'ads.campaigns.manage');},'BusinessDelegation.Conflict','DIRECT admin signed context still bound');
        // Supplied legacy flags cannot keep authority after the real DB flag is removed.
        queryExecute('UPDATE tb_usuarios SET is_admin=false WHERE id=901',{},{datasource='business_delegation_test'});
        VARIABLES.businessRealIsAdmin=true;
        assertThrowsType(function(){adsDelegationValidate(posted,'ads.credits.purchase');},'BusinessDelegation.Forbidden','current DB admin required');
        assertThrowsType(function(){paymentService.createCheckout(102,901,5000,'business:payment:no-admin-' & lCase(role),direct);},'BusinessDelegation.Forbidden','checkout rechecks DB admin');
        assertEqual(paymentService.getIntentStatus(102,other,direct).success,false,'status rechecks DB admin');
        queryExecute('UPDATE tb_usuarios SET is_admin=true WHERE id=901',{},{datasource='business_delegation_test'});
    }
    REQUEST.businessAccessContext=original;
    writeOutput('PASS ads signed DIRECT OPERADOR/VISUALIZADOR real internal admin checkout/status/campaign/banner/review, stale context and removed DB admin' & chr(10));
}
testCampaignManagerCannotBuy();testCampaignAndBannerKeepRealActor();testDelegatedActivationKeepsReviewGates();testUncertainCheckoutIsIdempotent();testBuyerCannotReadOtherPayments();testDirectInternalAdminSignedAds();testRevokedPostDoesNotUpload();testRevocationDuringProviderKeepsIntent();
writeOutput('PASS ads real handlers, service transactions, capability split, origin receipts and uncertain checkout' & chr(10));
</cfscript>
