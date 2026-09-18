<cfscript>
if (createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS') != '1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../../RoadRunners/';
function check(required boolean ok, required string label) { if (!ok) throw(message='FAIL: ' & label); writeOutput('PASS: ' & label & chr(10)); }
check(fileExists(root & 'includes/ads_v1/banner_context.cfm'),'page context helper is available');
REQUEST.currentRouteKey='event'; REQUEST.Usuario={logado=true,estado='SP'}; qEvento=queryNew('estado','varchar',[{estado='SC'}]); VARIABLES.uf='PR';
include root & 'includes/ads_v1/banner_context.cfm';
check(adsV1BannerPageKey=='event' AND adsV1BannerRegionCode=='SC','event UF precedes visitor and access');
REQUEST.currentRouteKey='athlete'; qPagina=queryNew('uf','varchar',[{uf='SC'}]); include root & 'includes/ads_v1/banner_context.cfm';
check(adsV1BannerPageKey=='athlete' AND adsV1BannerRegionCode=='SP','visited athlete is not visitor location');
REQUEST.currentRouteKey='home'; homeContextFallback=true; homeContextUf='SC'; include root & 'includes/ads_v1/banner_context.cfm'; check(adsV1BannerRegionCode=='','national fallback suppresses profile');
structDelete(VARIABLES,'homeContextFallback'); structDelete(VARIABLES,'homeContextUf');
REQUEST.currentRouteKey='search'; URL.estados='PR,SC'; include root & 'includes/ads_v1/banner_context.cfm'; check(adsV1BannerRegionCode=='PR','search uses single existing first UF context');
REQUEST.bannerSourceContext={pageKey='event',regionCode='SC'}; REQUEST.currentRouteKey='home'; VARIABLES.template='/'; include root & 'includes/ads_v1/banner_context.cfm'; check(adsV1BannerPageKey=='event' AND adsV1BannerRegionCode=='SC','AJAX source survives internal home template');
REQUEST.bannerSourceContext={pageKey='sidebar',regionCode='ZZ'}; include root & 'includes/ads_v1/banner_context.cfm'; check(adsV1BannerPageKey=='' AND adsV1BannerRegionCode=='','invalid explicit AJAX context fails closed');
writeOutput('BANNER CONTEXT PASS' & chr(10));
structDelete(REQUEST,'bannerSourceContext'); REQUEST.currentRouteKey='athlete'; REQUEST.Usuario={logado=false}; REQUEST.LocationContext={uf='RS'}; VARIABLES.uf='';
include root & 'includes/ads_v1/banner_context.cfm'; check(adsV1BannerRegionCode=='RS','resolved visitor access location used for anonymous visitor');
// Execute real endpoint capture before home composition, with only response headers removed.
endpoint=fileRead(root & 'api/home_sidebar.cfm'); endpoint=left(endpoint,find('<cfset VARIABLES.template =',endpoint)-1);
endpoint=reReplace(endpoint,'<cfheader[^>]+>','','all'); endpoint=replace(endpoint,'../includes/ads_v1/banner_context.cfm',root & 'includes/ads_v1/banner_context.cfm');
fragment=getTempDirectory() & 'banner-endpoint-' & createUUID() & '.cfm'; fileWrite(fragment,endpoint);
try { URL.context_uf='SC'; structDelete(URL,'banner_page'); structDelete(URL,'banner_uf'); include fragment; check(REQUEST.bannerSourceContext.pageKey=='home' AND REQUEST.bannerSourceContext.regionCode=='SC','legacy home sidebar caller retains resolved context');
URL.context_uf='BR'; include fragment; check(REQUEST.bannerSourceContext.regionCode=='','legacy national home suppresses visitor region');
URL.banner_page='invalid'; URL.banner_uf='ZZ'; include fragment; check(REQUEST.bannerSourceContext.pageKey=='' AND REQUEST.bannerSourceContext.regionCode=='','invalid explicit page cannot inherit home');
} finally {fileDelete(fragment);}
</cfscript>
