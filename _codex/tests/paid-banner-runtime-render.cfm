<cfscript>
if (createObject("java", "java.lang.System").getenv("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;
root = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../RoadRunners/";
function check(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="PaidBannerRenderFailure", message="FAIL: " & arguments.label);
    writeOutput("PASS: " & arguments.label & chr(10));
}
function renderBanner(required string billingModel, required string lang) {
    structClear(REQUEST);
    REQUEST.lang = arguments.lang;
    desktopData = "data:image/svg+xml;base64," & toBase64('<svg xmlns="http://www.w3.org/2000/svg" width="300" height="250"><rect width="300" height="250" fill="navy"/><text x="150" y="130" text-anchor="middle" fill="white" font-size="24">DESKTOP ' & arguments.billingModel & '</text></svg>');
    mobileData = "data:image/svg+xml;base64," & toBase64('<svg xmlns="http://www.w3.org/2000/svg" width="600" height="500"><rect width="600" height="500" fill="teal"/><text x="300" y="260" text-anchor="middle" fill="white" font-size="48">MOBILE ' & arguments.billingModel & '</text></svg>');
    VARIABLES.audienceBannerSlotKey = "rr-sidebar-banner-desktop";
    VARIABLES.adsV1BannerSlot = {
        placementKey="rr-sidebar-banner-300x250", className="home-side-banner",
        delivery={billingModel=arguments.billingModel,
            campaignId="11111111-1111-4111-8111-111111111111",
            deliveryId="22222222-2222-4222-8222-222222222222",
            viewEventId="33333333-3333-4333-8333-333333333333",
            clickEventId="44444444-4444-4444-8444-444444444444",
            rawToken="raw-token-fixture-12345678901234567890", openInNewTab=false,
            destinationUrl="https://private.example/destination", priceSnapshot=9.99,
            desktopImageUrl=desktopData, desktopWidth=300, desktopHeight=250,
            mobileImageUrl=mobileData, mobileWidth=600, mobileHeight=500,
            altText="Responsive banner"}
    };
    savecontent variable="html" { include root & "includes/ads_v1/banner_slot.cfm"; }
    return html;
}

cpc = renderBanner("CPC", "en");
check(find(encodeForHTMLAttribute("/api/ads/v1/cpc-click.cfm"), cpc) && find(encodeForHTMLAttribute("/api/ads/v1/cpc-viewable.cfm"), cpc), "CPC receipt selects canonical paid endpoints");
check(find('data-ads-v1-billing="CPC"', cpc) && find('data-audience-state="filled"', cpc), "CPC render exposes actual billing class to trackers");
check(find("Advertisement", cpc) && find('class="home-side-banner-shell"', cpc), "production disclosure wrapper remains localized in English");
check(find('media="(max-width: 767.98px)"', cpc) && arrayLen(reMatchNoCase("data&##x3a;image&##x2f;svg", cpc)) == 2,
    "desktop and mobile creatives render responsively without external artwork");
check(!find("private.example", cpc) && !find("9.99", cpc), "destination and price are not browser authority");

house = renderBanner("HOUSE", "es");
check(find(encodeForHTMLAttribute("/api/ads/v1/click.cfm"), house) && find(encodeForHTMLAttribute("/api/ads/v1/viewable.cfm"), house)
    && !find(encodeForHTMLAttribute("/api/ads/v1/cpc-"), house), "HOUSE receipt preserves zero-debit endpoints");
check(find('data-ads-v1-billing="HOUSE"', house) && find('data-audience-state="house"', house), "HOUSE render preserves audience state");
check(find("Publicidad", house), "production disclosure remains localized in Spanish");
visualHtml = '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Paid banner runtime fixture</title><style>body{margin:0;background:white;font-family:Arial,sans-serif}.fixture{max-width:340px;margin:24px auto;padding:12px;border:1px solid silver}.fixture h2{font-size:14px}</style></head><body><section class="fixture"><h2>CPC / English disclosure</h2>' & cpc & '</section><section class="fixture"><h2>HOUSE / Spanish disclosure</h2>' & house & '</section></body></html>';
fileWrite("/private/tmp/paid-banner-runtime-visual.html", visualHtml);
writeOutput("VISUAL FIXTURE: /private/tmp/paid-banner-runtime-visual.html" & chr(10));
</cfscript>
