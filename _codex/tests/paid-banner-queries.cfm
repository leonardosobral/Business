<cfscript>
if(createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS')!='1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
include root & 'portal/includes/paid_banner_helpers.cfm';
function check(required boolean ok,required string label){if(!ok)throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
scratch=getTempDirectory() & 'paid-banner-queries-' & createUUID();directoryCreate(scratch);
try {
 fileWrite(scratch & '/queries.cfm',replace(fileRead(root & 'portal/includes/paid_banner_queries.cfm'),'queryExecute(','REQUEST.paidTestQuery(','all'));
 include scratch & '/queries.cfm';REQUEST.calls=[];
 REQUEST.paidTestQuery=function(sql,params,options){arrayAppend(REQUEST.calls,{sql=sql,params=params});return queryNew('campaign_id');};
 ctx={accountId=2,canView=true,canReview=false};
 paidBannerCampaigns(ctx);
 check(REQUEST.calls[1].params.account.value==2 AND !REQUEST.calls[1].params.global.value,'account read is not widened by admin-like account role');
 check(find("a.ad_type='BANNER'",REQUEST.calls[1].sql) AND find("AND r.ad_type='BANNER'",REQUEST.calls[1].sql) AND find("c.billing_model='CPC'",REQUEST.calls[1].sql),'list and latest review exclude event campaigns and HOUSE');
 REQUEST.calls=[];ctx.accountId=0;caught=false;try{paidBannerCampaigns(ctx);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'unselected account cannot list all banners');
 ctx.canReview=true;paidBannerCampaigns(ctx);
 check(REQUEST.calls[1].params.global.value,'real reviewer can list global banners');
 REQUEST.calls=[];ctx.accountId=2;paidBannerDaily(ctx,7,'11111111-1111-4111-8111-111111111111');
 check(REQUEST.calls[1].params.account.value==2 AND !REQUEST.calls[1].params.global.value AND REQUEST.calls[1].params.campaign.value=='11111111-1111-4111-8111-111111111111','metrics are scoped to selected account and campaign');
 check(find("m.ad_type='BANNER'",REQUEST.calls[1].sql) AND find("m.billing_model='CPC'",REQUEST.calls[1].sql),'metrics segregate CPC banners');
 REQUEST.calls=[];caught=false;try{paidBannerDaily(ctx,999);}catch(AdsV1.Validation e){caught=true;}
 check(caught AND !arrayLen(REQUEST.calls),'unsupported chart period rejected');
 writeOutput('PAID BANNER QUERIES PASS' & chr(10));
} finally {directoryDelete(scratch,true);}
</cfscript>
