<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
function check(required boolean ok, required string label) { if (!ok) throw(message='FAIL: ' & label); writeOutput('PASS: ' & label & chr(10)); }
check(fileExists(root & 'portal/includes/banner_dashboard_helpers.cfm'),'dashboard helpers available');
include root & 'portal/includes/banner_dashboard_helpers.cfm';
include root & 'portal/includes/banner_form_helpers.cfm';
choices=queryNew('id_banner,nome','varchar,varchar',[{id_banner='28c3eb44-60ec-4745-9128-25969c4172ba',nome='Avaí'}]);
f=bannerDashboardFilters({periodo='7',banner='28C3EB44-60EC-4745-9128-25969C4172BA'},choices);
check(f.days==7 AND f.banner==choices.id_banner[1],'valid filter normalizes selected banner');
f=bannerDashboardFilters({periodo='9000',banner='unknown'},choices);
check(f.days==30 AND f.banner=='' AND f.invalidBanner,'invalid filters do not widen silently');
check(bannerDashboardFilters({},choices).days==30,'default period is 30 days');
rows=queryNew('metric_date,impressions,clicks','date,integer,integer',[
 {metric_date=createDate(2026,9,15),impressions=100,clicks=5},
 {metric_date=createDate(2026,9,16),impressions=10,clicks=1}]);
totals=bannerDashboardTotals(rows);
check(totals.impressions==110 AND totals.clicks==6 AND abs(totals.ctr-600/110)<0.0001,'period CTR is weighted by impressions');
check(bannerDashboardTotals(queryNew('impressions,clicks')).ctr==0,'empty data avoids division by zero');
qBannerManagementList=queryNew('id_banner,nome,status,banner_metadata,views,clicks,arquivo_path,arquivo_mobile_path,inicio_exibicao,fim_exibicao,link_destino,abrir_nova_aba,largura,altura,largura_mobile,altura_mobile,alt_text,local_layout,peso_exibicao,prioridade',
'varchar,varchar,varchar,varchar,integer,integer,varchar,varchar,varchar,varchar,varchar,bit,integer,integer,integer,integer,varchar,varchar,integer,integer',[
 {id_banner=choices.id_banner[1],nome='A <banner>',status='ACTIVE',banner_metadata='{}',views=0,clicks=1,arquivo_path='https://example.org/a.png',arquivo_mobile_path='https://example.org/m.png',inicio_exibicao='',fim_exibicao='',link_destino='https://example.org/?q=<test>',abrir_nova_aba=true,largura=300,altura=250,largura_mobile=600,altura_mobile=500,alt_text='Alt <text>',local_layout='rr-sidebar-banner-300x250',peso_exibicao=1,prioridade=1}]);
function bannerManagementBuildAssetUrl(required string value) {return value;}
function bannerManagementStatusLabel(required string value) {return value;}
function bannerManagementTargetLabel(required boolean value) {return value ? 'Nova aba' : 'Mesma janela';}
VARIABLES.bannerManagementCsrf='test-csrf';
savecontent variable='html' { include root & 'portal/includes/banner_dashboard_list.cfm'; }
check(find('A &lt;banner&gt;',html)>0 AND find('q=&lt;test&gt;',html)>0,'real details escape stored fields');
check(find('<details class="banner-operation"',html)>0 AND find('<summary',html)>0 AND find('Ver detalhes',html)>0,'native keyboard-operable collapsed rows');
check(find('name="banner_csrf" value="test-csrf"',html)>0 AND find('value="PAUSED"',html)>0,'status actions preserve CSRF and active pause');
check(find('banner_editar=',html)==0,'active banner cannot bypass pause-before-edit');
check(find('CTR indisponível sem impressões',html)>0,'no misleading zero CTR when impressions missing');
querySetCell(qBannerManagementList,'status','PAUSED',1);
querySetCell(qBannerManagementList,'banner_metadata','{"banner_scope_v1":{"regions_mode":"SELECTED","regions":["SC"],"pages_mode":"SELECTED","pages":["event"]}}',1);
savecontent variable='html' { include root & 'portal/includes/banner_dashboard_list.cfm'; }
check(find('banner_editar=',html)>0 AND find('value="ACTIVE"',html)>0 AND find('SC',html)>0 AND find('Página de evento',html)>0,'paused banner edit and friendly targeting details preserved');
qBannerManagementList=queryNew('id_banner');
savecontent variable='html' { include root & 'portal/includes/banner_dashboard_list.cfm'; }
check(find('Nenhum banner encontrado',html)>0,'empty listing is explicit');
writeOutput('BANNER DASHBOARD PASS' & chr(10));
</cfscript>
