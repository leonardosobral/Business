<cfscript>
if (createObject("java", "java.lang.System").getenv("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;

root = getDirectoryFromPath(getCurrentTemplatePath()) & "../../";
include root & "portal/includes/banner_form_helpers.cfm";
include root & "portal/includes/paid_banner_helpers.cfm";

function visualImage(required string background, required string accent, required string label) {
    var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="500" viewBox="0 0 600 500">'
        & '<rect width="600" height="500" fill="' & arguments.background & '"/>'
        & '<circle cx="470" cy="90" r="145" fill="' & arguments.accent & '" opacity=".55"/>'
        & '<path d="M0 390 C160 280 310 470 600 250 V500 H0Z" fill="' & arguments.accent & '" opacity=".8"/>'
        & '<text x="48" y="210" fill="white" font-family="Arial,sans-serif" font-size="44" font-weight="700">' & arguments.label & '</text>'
        & '<text x="48" y="252" fill="white" font-family="Arial,sans-serif" font-size="22">CORRA MAIS LONGE</text></svg>';
    return "data:image/svg+xml;base64," & binaryEncode(charsetDecode(svg, "utf-8"), "base64");
}

desktopImage = visualImage("##11304b", "##16b8c9", "AURORA RUN");
mobileImage = visualImage("##351a52", "##f5a623", "AURORA RUN");
VARIABLES.paidBannerReady = true;
VARIABLES.paidBannerContext = {accountId=2,canManage=true,canReview=false,canView=true};
VARIABLES.adsAccessCanViewPayments = true;
VARIABLES.paidBannerCsrf = "visual-fixture-token";
VARIABLES.paidBannerError = "";
VARIABLES.paidBannerNotice = "Banner salvo como rascunho. Revise os dados antes de enviar para análise.";
VARIABLES.paidBannerBalanceValue = 835.40;
VARIABLES.paidBannerShowForm = true;
VARIABLES.paidBannerEditId = "";
VARIABLES.paidBannerEditRow = {};
VARIABLES.paidBannerFormData = paidBannerForm({
    name="Campanha Aurora Run",
    destination_url="https://example.org/aurora",
    alt_text="Tênis azul Aurora Run em uma pista de corrida",
    open_new_tab="1",
    cpc_bid="0,94",
    budget_total="650,00",
    budget_daily="45,00",
    starts_at="2026-09-18T08:00",
    ends_at="2026-10-18T23:59",
    target_device="ALL",
    banner_pages_mode="SELECTED",
    banner_pages="home,search,state",
    banner_regions_mode="SELECTED",
    banner_regions="SC,PR,SP"
});
VARIABLES.paidBannerTotals = {impressions=12840,clicks=386,cost=271.64};
VARIABLES.paidBannerFilter = "";
VARIABLES.paidBannerDays = 30;
VARIABLES.paidBannerChartRows = [
    {date="14/09/2026",impressions=1980,clicks=61,cost=41.55},
    {date="15/09/2026",impressions=2240,clicks=69,cost=48.10},
    {date="16/09/2026",impressions=2670,clicks=82,cost=57.93},
    {date="17/09/2026",impressions=3010,clicks=91,cost=64.06}
];
VARIABLES.paidBannerRows = [
    {
        campaign_id="11111111-1111-4111-8111-111111111111",account_id=2,account_name="Aurora Sports",
        name="Aurora Run · Sul e Sudeste",status="ACTIVE",review_status="APPROVED",review_id=21,review_reason="",
        spent_total=271.64,budget_total=650,budget_daily=45,cpc_bid=.94,cost=271.64,impressions=12840,clicks=386,
        billable_clicks=342,deliveries=16590,metadata='{"banner_scope_v1":{"regions_mode":"SELECTED","regions":["SC","PR","SP"],"pages_mode":"SELECTED","pages":["home","search","state"]}}',
        image_url_desktop=desktopImage,image_url_mobile=mobileImage,starts_at=createDateTime(2026,9,1,8,0,0),ends_at=createDateTime(2026,10,18,23,59,0),
        target_device="ALL",open_new_tab="1",destination_url="https://example.org/aurora",alt_text="Tênis azul Aurora Run em uma pista de corrida"
    },
    {
        campaign_id="22222222-2222-4222-8222-222222222222",account_id=2,account_name="Aurora Sports",
        name="Coleção Noturna",status="DRAFT",review_status="PENDING_REVIEW",review_id=22,review_reason="",
        spent_total=0,budget_total=300,budget_daily="",cpc_bid=.72,cost=0,impressions=0,clicks=0,billable_clicks=0,deliveries=0,
        metadata='{"banner_scope_v1":{"regions_mode":"ALL","regions":[],"pages_mode":"ALL","pages":[]}}',
        image_url_desktop=mobileImage,image_url_mobile=desktopImage,starts_at=createDateTime(2026,9,20,8,0,0),ends_at=createDateTime(2026,10,31,23,59,0),
        target_device="ALL",open_new_tab="1",destination_url="https://example.org/noturna",alt_text="Corredora usando a coleção noturna"
    }
];

savecontent variable="workspace" {
    include root & "portal/includes/paid_banner_home.cfm";
}
writeOutput('<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Paid banner workspace visual fixture</title>'
    & '<link rel="stylesheet" href="/assets/css/mdb.min.css">'
    & '<link rel="stylesheet" href="/assets/plugins/css/all.min.css">'
    & '<link rel="stylesheet" href="/assets/css/style.css?2026062704">'
    & '<link rel="stylesheet" href="/assets/css/cores_admin.css?202512062">'
    & '<link rel="stylesheet" href="/assets/css/business-ui.css?2026062905">'
    & '</head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid px-4 py-4">'
    & workspace
    & '</main></body></html>');
</cfscript>
