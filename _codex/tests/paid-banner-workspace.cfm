<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
function check(required boolean ok, required string label) {if(!ok) throw(message='FAIL: ' & label);writeOutput('PASS: ' & label & chr(10));}
function rejects(required any action, required string label) {
 var rejected=false;
 try {action();} catch(AdsV1.Validation expected) {rejected=true;}
 check(rejected,label);
}
include root & 'portal/includes/banner_form_helpers.cfm';
include root & 'portal/includes/paid_banner_helpers.cfm';
check(paidBannerMoney('1.234,56')==1234.56 AND paidBannerMoney('0.94')==0.94,'Brazilian and decimal amounts preserve cents');
rejects(function(){paidBannerMoney('0,94evil');},'malformed amount cannot silently become a valid bid');
rejects(function(){paidBannerMoney('-10');},'negative budget rejected');
check(paidBannerDate('2026-09-16T12:30')=='2026-09-16T12:30-03:00','local form date explicitly carries Sao Paulo offset');
rejects(function(){paidBannerDate('2026-02-31T12:30');},'impossible date rejected');
var p={name='Marca parceira',alt_text='Tênis para corrida',destination_url='https://example.org/oferta',open_new_tab='1',starts_at='2026-09-16T10:00',ends_at='2026-10-16T23:59',cpc_bid='0,94',budget_total='100,00',budget_daily='',target_device='ALL',banner_regions_mode='SELECTED',banner_regions='SC,SP',banner_pages_mode='ALL'};
var v=paidBannerValues(p);
check(v.cpc_bid==0.94 AND v.budget_total==100 AND v.banner_scope_v1.regions[1]=='SC' AND v.banner_scope_v1.pages_mode=='ALL','form yields typed product DTO and selected scope');
check(v.placement_key=='rr-sidebar-banner-300x250' AND !structKeyExists(v,'account_id') AND !structKeyExists(v,'actor_id'),'account and actor cannot come from advertiser values');
p.account_id=999;p.actor_id=1;p.placement_key='not-rendered';
check(paidBannerValues(p).placement_key=='rr-sidebar-banner-300x250','posted technical placement cannot select unknown inventory');
p.destination_url='javascript:alert(1)';rejects(function(){paidBannerValues(p);},'executable destination rejected');p.destination_url='https://example.org/';
p.target_device='TABLET';rejects(function(){paidBannerValues(p);},'unknown device rejected');p.target_device='ALL';
p.ends_at=p.starts_at;rejects(function(){paidBannerValues(p);},'zero duration rejected');p.ends_at='2026-10-16T23:59';
paidBannerAssertAction('POST','known','known',true,false,true,'save');
paidBannerAssertAction('POST','known','known',false,true,false,'review');
rejects(function(){paidBannerAssertAction('GET','known','known',true,true,true,'save');},'GET cannot mutate');
rejects(function(){paidBannerAssertAction('POST','wrong','known',true,true,true,'save');},'foreign CSRF cannot mutate');
rejects(function(){paidBannerAssertAction('POST','known','known',false,false,true,'save');},'viewer cannot manage');
rejects(function(){paidBannerAssertAction('POST','known','known',true,false,true,'review');},'account manager cannot approve');
rejects(function(){paidBannerAssertAction('POST','known','known',true,true,false,'save');},'no active account cannot create paid banner');
rejects(function(){paidBannerAssertAction('POST','known','known',true,true,true,'activate');},'direct activation is not a form action');
check(paidBannerStatus('DRAFT','PENDING_REVIEW')=='Em análise' AND paidBannerStatus('DRAFT','WAITING_PREREQUISITES')=='Aguardando conta','pending reviews never look like unsent drafts');
check(paidBannerStatus('DRAFT','NONE')=='Rascunho','unsent draft explicitly identified');
check(paidBannerWorkspaceView({}, {}, true)=='paid','admin defaults to paid banners, not institutional owner');
check(paidBannerWorkspaceView({view='house'}, {}, true)=='house' AND paidBannerWorkspaceView({banner_novo='1'}, {}, true)=='house','explicit HOUSE view and legacy admin form links remain compatible');
rejects(function(){paidBannerWorkspaceView({view='house'}, {}, false);},'account member cannot select HOUSE administration');
check(paidBannerWorkspaceView({}, {paid_banner_action='save'}, false)=='paid','member paid save stays in account workspace');
VARIABLES.paidBannerCsrf='test-token';VARIABLES.paidBannerEditId='';VARIABLES.paidBannerEditRow={};
VARIABLES.paidBannerFormData=paidBannerForm({paid_banner_action='save',name='"/><img src=x onerror=alert(1)>'});
savecontent variable='html' {include root & 'portal/includes/paid_banner_form.cfm';}
check(find('<img src=x',html)==0 AND find('&lt;img',html)>0,'form redisplays invalid user text inertly');
check(find('name="save_intent" value="submit"',html)>0 AND find('name="save_intent" value="draft"',html)>0 AND find('name="paid_banner_csrf" value="test-token"',html)>0,'real form provides explicit submit versus draft and CSRF');
check(find('name="account_id"',html)==0 AND find('name="actor_id"',html)==0,'form cannot choose billing owner or actor');
writeOutput('PAID BANNER WORKSPACE PASS' & chr(10));
</cfscript>
