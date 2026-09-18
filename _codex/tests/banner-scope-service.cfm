<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../../RoadRunners/';
function check(required boolean ok, required string label) {if(!ok) throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
// Replace only the external query boundary; run actual selection, validation,
// transaction, context serialization and response mapping from the service.
source=fileRead(root & 'services/AdsV1BannerDeliveryService.cfc');
source=replace(source,'queryExecute(','REQUEST.bannerTestQuery(','all');
scratch=getTempDirectory() & 'banner-service-' & createUUID();directoryCreate(scratch);
fileWrite(scratch & '/Banner.cfc',source);
testMappings=duplicate(getApplicationSettings().mappings);testMappings['/bannerTest']=scratch;application action='update' mappings=testMappings;
REQUEST.bannerTestCalls=[];
REQUEST.bannerTestQuery=function(sql,params,options) {
 arrayAppend(REQUEST.bannerTestCalls,{sql=sql,params=params});
 if(find('serve_delivery',sql)) return queryNew('result_status,billing_model,price_snapshot,delivery_id,destination_url','varchar,varchar,integer,varchar,varchar',[{result_status='served',billing_model='HOUSE',price_snapshot=0,delivery_id='11111111-1111-4111-8111-111111111111',destination_url='https://example.org/race'}]);
 return queryNew('billing_model,ad_type,creative_type,placement_key,destination_url,desktop_image_url,mobile_image_url,desktop_width,desktop_height,mobile_width,mobile_height,alt_text,open_in_new_tab,campaign_id,advertisement_id,creative_id,placement_id','varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,integer,varchar,boolean,varchar,varchar,varchar,varchar',[{billing_model='HOUSE',ad_type='BANNER',creative_type='IMAGE',placement_key='rr-sidebar-banner-300x250',destination_url='https://example.org/race',desktop_image_url='https://example.org/a.png',mobile_image_url='https://example.org/b.png',desktop_width=300,desktop_height=250,mobile_width=600,mobile_height=500,alt_text='Corrida de exemplo',open_in_new_tab=true,campaign_id='11111111-1111-4111-8111-111111111111',advertisement_id='22222222-2222-4222-8222-222222222222',creative_id='33333333-3333-4333-8333-333333333333',placement_id='44444444-4444-4444-8444-444444444444'}]);
};
try {
 svc=createObject('component','bannerTest.Banner').init({housePlacements=['rr-sidebar-banner-300x250']});
 result=svc.deliver(deviceClass='DESKTOP',regionCode='sc',route='sidebar',pageKey='event');
 check(result.status=='served' AND result.desktopWidth==300,'real service maps valid HOUSE delivery');
 check(arrayLen(REQUEST.bannerTestCalls)==2,'selection and revalidated serve called once');
 check(find('select_house_banner_candidate',REQUEST.bannerTestCalls[1].sql)>0 AND REQUEST.bannerTestCalls[1].params.page_key.value=='event' AND REQUEST.bannerTestCalls[1].params.region_code.value=='SC','family and UF sent to canonical selection before LIMIT');
 check(REQUEST.bannerTestCalls[2].params.route_key.value=='sidebar' AND find('"banner_page":"event"',REQUEST.bannerTestCalls[2].params.request_context.value)>0,'physical sidebar route distinct from lowercase receipt family');
 REQUEST.bannerTestCalls=[]; svc.deliver(regionCode='ZZ',route='sidebar',pageKey='sidebar');
 check(REQUEST.bannerTestCalls[1].params.page_key.null AND REQUEST.bannerTestCalls[1].params.region_code.null,'invalid explicit context remains unknown');
} finally {directoryDelete(scratch,true);}
</cfscript>
