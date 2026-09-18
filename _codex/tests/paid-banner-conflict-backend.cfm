<cfscript>
if(createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS')!='1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
function check(required boolean ok,required string label){if(!ok)throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
scratch=getTempDirectory() & 'paid-banner-conflict-' & createUUID();directoryCreate(scratch);
try {
 fileWrite(scratch & '/queries.cfm',"
<cfscript>
function paidBannerCampaigns(required struct context,string campaignId='') {
 return queryNew('campaign_id,account_id,account_name,name,status,version,starts_at,ends_at,cpc_bid,budget_total,budget_daily,target_device,metadata,destination_url,alt_text,image_url_desktop,image_url_mobile,width_desktop,height_desktop,width_mobile,height_mobile,open_new_tab,review_status,review_id,review_reason,spent_total,impressions,clicks,billable_clicks,deliveries,cost','varchar,bigint,varchar,varchar,varchar,integer,timestamp,timestamp,decimal,decimal,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,integer,varchar,varchar,bigint,varchar,decimal,bigint,bigint,bigint,bigint,decimal',[{campaign_id='11111111-1111-4111-8111-111111111111',account_id=2,account_name='Conta',name='Versão atual',status='DRAFT',version=8,starts_at=now(),ends_at=dateAdd('d',30,now()),cpc_bid=.94,budget_total=100,budget_daily='',target_device='ALL',metadata='{}',destination_url='https://example.org/atual',alt_text='Versão atual',image_url_desktop='https://example.org/d.png',image_url_mobile='https://example.org/m.png',width_desktop=300,height_desktop=250,width_mobile=600,height_mobile=500,open_new_tab='1',review_status='PENDING_REVIEW',review_id=9,review_reason='',spent_total=0,impressions=0,clicks=0,billable_clicks=0,deliveries=0,cost=0}]);
}
function paidBannerDaily(required struct context,numeric days=30,string campaignId=''){return queryNew('metric_date,impressions,clicks,cost');}
function paidBannerBalance(required struct context){return queryNew('available_balance','decimal',[{available_balance=50}]);}
</cfscript>");
 REQUEST.testSession={paidBannerCsrfSeed='conflict-seed'};REQUEST.testMethod='POST';
 VARIABLES.adsAccessAccountId=2;VARIABLES.adsAccessActorId=912;VARIABLES.adsAccessCanManageCampaign=true;VARIABLES.adsAccessCanReviewCampaign=false;VARIABLES.adsAccessCanView=true;
 VARIABLES.paidBannerPostedVersion='7';
 structClear(FORM);structAppend(FORM,{paid_banner_action='save',paid_banner_csrf=hmac('912:2',REQUEST.testSession.paidBannerCsrfSeed,'HmacSHA256'),campaign_id='11111111-1111-4111-8111-111111111111',expected_version=VARIABLES.paidBannerPostedVersion,save_intent='draft',name='Texto enviado na aba B',alt_text='Descrição enviada na aba B',destination_url='https://example.org/conflito',open_new_tab='1',starts_at='2026-09-16T10:00',ends_at='2026-10-16T23:59',cpc_bid='1,23',budget_total='321,00',budget_daily='20,00',target_device='ALL',banner_regions_mode='ALL',banner_pages_mode='ALL'},true);
 source=fileRead(root & 'portal/includes/paid_banner_backend.cfm');
 source=replace(source,'template="','template="' & root & 'portal/includes/','all');
 source=replace(source,'<cfinclude template="' & root & 'portal/includes/paid_banner_queries.cfm"/>','<cfinclude template="' & scratch & '/queries.cfm"/>','all');
 source=replace(source,'SESSION.','REQUEST.testSession.','all');source=replace(source,'structKeyExists(SESSION,','structKeyExists(REQUEST.testSession,','all');source=replace(source,'structDelete(SESSION,','structDelete(REQUEST.testSession,','all');
 source=replace(source,'scope="session"','name="paid-banner-conflict-test"','all');source=replace(source,'CGI.request_method','REQUEST.testMethod','all');
 source=reReplace(source,'(?s)<cfquery name="qPaidBannerReady".*?</cfquery>','<cfset qPaidBannerReady=queryNew("ready","bit",[{ready=true}])/>','one');
 fileWrite(scratch & '/backend.cfm',source);include scratch & '/backend.cfm';
 check(structKeyExists(VARIABLES,'paidBannerConflict') AND VARIABLES.paidBannerConflict,'concurrent submitted state enters an explicit edit conflict');
 check(VARIABLES.paidBannerShowForm AND VARIABLES.paidBannerFormData.name=='Texto enviado na aba B' AND VARIABLES.paidBannerFormData.budget_total=='321,00','backend keeps failed POST values visible');
 check(VARIABLES.paidBannerEditRow.version==7,'backend does not replace the submitted expected version with the current version');
 writeOutput('PAID BANNER CONFLICT BACKEND PASS' & chr(10));
} finally {directoryDelete(scratch,true);}
</cfscript>
