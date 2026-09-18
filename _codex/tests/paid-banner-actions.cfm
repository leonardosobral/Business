<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
function check(required boolean ok, required string label) {if(!ok) throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
include root & 'portal/includes/banner_form_helpers.cfm';
include root & 'portal/includes/paid_banner_helpers.cfm';
scratch=getTempDirectory() & 'paid-banner-actions-' & createUUID();directoryCreate(scratch);
try {
 source=fileRead(root & 'portal/includes/paid_banner_actions.cfm');
 fileWrite(scratch & '/actions.cfm',replace(source,'queryExecute(','REQUEST.paidTestQuery(','all'));
 include scratch & '/actions.cfm';
 REQUEST.calls=[];
 REQUEST.paidTestQuery=function(sql,params,options){
  arrayAppend(REQUEST.calls,{sql=sql,params=params});
  return queryNew('campaign_id,campaign_status,review_status,campaign_review_request_id','varchar,varchar,varchar,bigint',[{campaign_id='11111111-1111-4111-8111-111111111111',campaign_status='DRAFT',review_status='PENDING_REVIEW',campaign_review_request_id=5}]);
 };
 ctx={method='POST',csrf='token',accountId=2,actorId=902,canManage=true,canReview=false};
 posted={paid_banner_action='save',paid_banner_csrf='token',campaign_id='',save_intent='submit',name='Marca de teste',alt_text='Oferta para atletas',destination_url='https://example.org/',open_new_tab='1',starts_at='2026-09-16T10:00',ends_at='2026-10-16T23:59',cpc_bid='0,94',budget_total='100',budget_daily='',target_device='ALL',banner_regions_mode='ALL',banner_pages_mode='ALL',account_id=999,actor_id=1};
 images={image_url_desktop='https://business.roadrunners.run/portal/banners/assets/a.png',width_desktop=300,height_desktop=250,image_url_mobile='https://business.roadrunners.run/portal/banners/assets/b.png',width_mobile=600,height_mobile=500};
 outcome=paidBannerSave(posted,ctx,images);
 check(arrayLen(REQUEST.calls)==1 AND find('ads.save_paid_banner_campaign',REQUEST.calls[1].sql)>0,'save and submit use one atomic product API');
 check(REQUEST.calls[1].params.account.value==2 AND REQUEST.calls[1].params.actor.value==902 AND REQUEST.calls[1].params.submit.value,'authenticated account and actor override forged ownership');
 payload=deserializeJSON(REQUEST.calls[1].params.values.value);
 check(payload.image_url_desktop==images.image_url_desktop AND payload.width_desktop==300 AND payload.image_url_mobile==images.image_url_mobile AND payload.height_mobile==500 AND !structKeyExists(payload,'desktop_image_url'),'runtime sends the exact Task 1 image payload keys');
 check(outcome.review_status=='PENDING_REVIEW','caller gets persisted review state');
 REQUEST.calls=[];posted.paid_banner_csrf='wrong';caught=false;try{paidBannerSave(posted,ctx,images);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'invalid CSRF never reaches SQL');
 posted.paid_banner_csrf='token';ctx.canManage=false;caught=false;try{paidBannerSave(posted,ctx,images);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'read-only account role never reaches save SQL');
 ctx.canManage=true;posted.save_intent='draft';paidBannerSave(posted,ctx,images);
 check(!REQUEST.calls[1].params.submit.value,'save as draft never submits for review');
 REQUEST.calls=[];posted.save_intent='activate';caught=false;try{paidBannerSave(posted,ctx,images);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'unknown intent cannot fall through to activation');
 posted.save_intent='draft';posted.campaign_id='11111111-1111-4111-8111-111111111111';posted.expected_version='7';paidBannerSave(posted,ctx,images);
 check(deserializeJSON(REQUEST.calls[1].params.values.value).expected_version==7,'edit sends expected version to protect against stale writes');
 REQUEST.calls=[];structDelete(posted,'expected_version');caught=false;try{paidBannerSave(posted,ctx,images);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'editing without version is rejected before SQL');
 posted.paid_banner_action='review';posted.decision='APPROVE';posted.review_id='8';caught=false;try{paidBannerManage(posted,ctx);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'account manager cannot review');
 ctx.canReview=true;ctx.accountId=0;paidBannerManage(posted,ctx);
 check(REQUEST.calls[1].params.global.value AND find("a.ad_type='BANNER'",REQUEST.calls[1].sql) AND REQUEST.calls[2].params.review.value==8,'global reviewer uses BANNER ownership check and exact review id');
 REQUEST.calls=[];ctx.accountId=2;posted.paid_banner_action='pause';paidBannerManage(posted,ctx);
 check(!REQUEST.calls[1].params.global.value AND REQUEST.calls[1].params.account.value==2 AND REQUEST.calls[2].params.status.value=='PAUSED','pause stays in selected account and uses canonical status API');
 REQUEST.calls=[];ctx.accountId=0;ctx.canReview=true;posted.paid_banner_action='review';posted.review_id='8';posted.decision='APPROVE';
 REQUEST.paidTestQuery=function(sql,params,options){
  arrayAppend(REQUEST.calls,{sql=sql,params=params});
  if(arrayLen(REQUEST.calls)==1)return queryNew('campaign_id','varchar',[{campaign_id='11111111-1111-4111-8111-111111111111'}]);
  throw(type='database',message='ERROR: Revisao vigente diverge da exibida; reenvie o banner',detail='SQL state P0001');
 };
 caught=false;safeMessage='';try{paidBannerManage(posted,ctx);}catch(AdsV1.Validation e){caught=true;safeMessage=e.message;}
 check(caught AND findNoCase('obsoleta',safeMessage)>0 AND findNoCase('recarregue',safeMessage)>0 AND findNoCase('SQL',safeMessage)==0,'obsolete displayed review becomes a safe explicit reload message');
 writeOutput('PAID BANNER ACTIONS PASS' & chr(10));
} finally {directoryDelete(scratch,true);}
</cfscript>
