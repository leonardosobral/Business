<cfscript>
if(createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS')!='1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
include root & 'portal/includes/banner_form_helpers.cfm';include root & 'portal/includes/paid_banner_helpers.cfm';
function check(required boolean ok,required string label){if(!ok)throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
VARIABLES.paidBannerReady=true;VARIABLES.paidBannerContext={accountId=2,canManage=true,canReview=false,canView=true};
VARIABLES.adsAccessCanViewPayments=true;VARIABLES.paidBannerCsrf='test-token';VARIABLES.paidBannerError='';VARIABLES.paidBannerNotice='';VARIABLES.paidBannerBalanceValue=50;VARIABLES.paidBannerShowForm=false;
VARIABLES.paidBannerTotals={impressions=20,clicks=2,cost=1};VARIABLES.paidBannerFilter='11111111-1111-4111-8111-111111111111';VARIABLES.paidBannerDays=90;VARIABLES.paidBannerChartRows=[{'date'='2026-09-16','impressions'=20,'clicks'=2,'cost'=1}];
VARIABLES.paidBannerRows=[{campaign_id='11111111-1111-4111-8111-111111111111',account_id=2,account_name='Conta <script>',name='Banner <img src=x>',status='DRAFT',review_status='PENDING_REVIEW',review_id=6,review_reason='',spent_total=1,budget_total=100,budget_daily='',cpc_bid=.94,cost=1,impressions=20,clicks=2,billable_clicks=2,deliveries=30,metadata='{}',image_url_desktop='https://example.org/a.png',image_url_mobile='https://example.org/b.png',starts_at=now(),ends_at=dateAdd('d',30,now()),target_device='ALL',open_new_tab='1',destination_url='https://example.org/?a=<test>',alt_text='Oferta'}];
draftRow=duplicate(VARIABLES.paidBannerRows[1]);draftRow.campaign_id='22222222-2222-4222-8222-222222222222';draftRow.name='Rascunho editável';draftRow.review_status='NONE';draftRow.review_id='';arrayAppend(VARIABLES.paidBannerRows,draftRow);
structClear(URL);URL.section='banners';
savecontent variable='html'{include root & 'portal/includes/paid_banner_home.cfm';}
decodedLinks=decodeForHTML(html);
check(find('<script>',html)==0 AND find('<img src=x>',html)==0 AND find('&lt;img',html)>0,'list escapes advertiser and account text');
check(find('value="prepare"',html)>0 AND find('Aprovar banner',html)==0,'member can edit pending banner but cannot approve');
check(find('Ver detalhes',html)>0 AND find('id="paid-banner-chart-data"',html)==0,'banner list tab renders independently from performance');
check(find('section=performance&banner=11111111-1111-4111-8111-111111111111&periodo=90',decodedLinks)>0 AND find('section=banners&banner=11111111-1111-4111-8111-111111111111&periodo=90',decodedLinks)>0,'performance and banner tabs preserve the selected banner and period');
check(find('section=form&novo=1&banner=11111111-1111-4111-8111-111111111111&periodo=90',decodedLinks)>0 AND find('section=form&edit=22222222-2222-4222-8222-222222222222&banner=11111111-1111-4111-8111-111111111111&periodo=90',decodedLinks)>0,'create and edit links preserve the performance return filters');
check(find('name="paid_banner_return_banner" value="11111111-1111-4111-8111-111111111111"',html)>0 AND find('name="paid_banner_return_period" value="90"',html)>0,'list actions carry the validated return filters through POST');
structClear(URL);URL.section='performance';
savecontent variable='html'{include root & 'portal/includes/paid_banner_home.cfm';}
check(find('id="paid-banner-chart-data"',html)>0 AND find('Dados diários',html)>0 AND find('class="banner-operation"',html)==0,'performance tab has chart and accessible data without the long list');
VARIABLES.paidBannerContext={accountId=0,canManage=false,canReview=true,canView=false};
structClear(URL);URL.section='banners';
savecontent variable='html'{include root & 'portal/includes/paid_banner_home.cfm';}
check(find('Aprovar banner',html)>0 AND find('name="review_id" value="6"',html)>0 AND find('value="prepare"',html)==0,'global reviewer sees latest revision controls but no cross-account editor');
structClear(URL);URL.section='form';
savecontent variable='html'{include root & 'portal/includes/paid_banner_home.cfm';}
check(find('id="paid-banner-form"',html)==0 AND find('Ver detalhes',html)>0,'read-only reviewer cannot open the advertiser form tab');
VARIABLES.paidBannerContext={accountId=2,canManage=true,canReview=false,canView=true};VARIABLES.paidBannerConflict=true;
VARIABLES.paidBannerEditId='11111111-1111-4111-8111-111111111111';VARIABLES.paidBannerEditRow={version=7};
VARIABLES.paidBannerFormData=paidBannerForm({paid_banner_action='save',name='Texto enviado na aba B',alt_text='Descrição enviada na aba B',destination_url='https://example.org/conflito',open_new_tab='1',starts_at='2026-09-16T10:00',ends_at='2026-10-16T23:59',cpc_bid='1,23',budget_total='321,00',budget_daily='20,00',target_device='ALL',banner_regions_mode='ALL',banner_pages_mode='ALL'});
savecontent variable='html'{include root & 'portal/includes/paid_banner_form.cfm';}
decodedLinks=decodeForHTML(html);
check(find('Texto enviado na aba B',html)>0 AND find('value="321,00"',html)>0,'conflict form preserves the submitted edit values');
check(find('data-paid-banner-conflict',html)>0 AND find('disabled',html)>0 AND find('name="expected_version" value="7"',html)>0 AND find('name="expected_version" value="8"',html)==0,'conflict form is disabled and retains the submitted expected version');
check(find('section=banners&banner=11111111-1111-4111-8111-111111111111&periodo=90',decodedLinks)>0 AND find('name="paid_banner_return_banner" value="11111111-1111-4111-8111-111111111111"',html)>0 AND find('name="paid_banner_return_period" value="90"',html)>0,'form close and POST preserve the performance roundtrip filters');
writeOutput('PAID BANNER RENDER PASS' & chr(10));
</cfscript>
