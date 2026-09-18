<cfscript>
if (createObject("java", "java.lang.System").getenv("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;

root = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../RoadRunners/";
function check(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="PaidBannerDeliveryFailure", message="FAIL: " & arguments.label);
    writeOutput("PASS: " & arguments.label & chr(10));
}
function candidate(required string billingModel) {
    return queryNew(
        "billing_model,ad_type,creative_type,placement_key,destination_url,desktop_image_url,mobile_image_url,desktop_width,desktop_height,mobile_width,mobile_height,alt_text,open_in_new_tab,campaign_id,advertisement_id,creative_id,placement_id",
        "varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,integer,varchar,boolean,varchar,varchar,varchar,varchar",
        [{
            billing_model=arguments.billingModel, ad_type="BANNER", creative_type="IMAGE",
            placement_key="rr-sidebar-banner-300x250", destination_url="https://example.org/stored",
            desktop_image_url="https://example.org/desktop.png", mobile_image_url="https://example.org/mobile.png",
            desktop_width=300, desktop_height=250, mobile_width=600, mobile_height=500,
            alt_text="Paid banner", open_in_new_tab=true,
            campaign_id="11111111-1111-4111-8111-111111111111",
            advertisement_id="22222222-2222-4222-8222-222222222222",
            creative_id="33333333-3333-4333-8333-333333333333",
            placement_id="44444444-4444-4444-8444-444444444444"
        }]
    );
}
function receipt(required string billingModel) {
    return queryNew(
        "result_status,billing_model,price_snapshot,delivery_id,destination_url,currency",
        "varchar,varchar,decimal,varchar,varchar,varchar",
        [{result_status="served", billing_model=arguments.billingModel,
            price_snapshot=arguments.billingModel == "CPC" ? 0.51 : 0,
            delivery_id="55555555-5555-4555-8555-555555555555",
            destination_url="https://example.org/stored", currency="BRL"}]
    );
}

source = fileRead(root & "services/AdsV1BannerDeliveryService.cfc");
source = replace(source, "queryExecute(", "REQUEST.paidBannerQuery(", "all");
scratch = getTempDirectory() & "paid-banner-delivery-" & createUUID();
directoryCreate(scratch);
fileWrite(scratch & "/Banner.cfc", source);
testMappings = duplicate(getApplicationSettings().mappings);
testMappings["/paidBannerTest"] = scratch;
application action="update" mappings=testMappings;

REQUEST.paidBannerCalls = [];
REQUEST.paidBannerMode = "paid";
REQUEST.paidBannerQuery = function(required string sql, required struct params, required struct options) {
    arrayAppend(REQUEST.paidBannerCalls, {sql=arguments.sql, params=arguments.params});
    if (findNoCase("select_paid_banner_candidate", arguments.sql)) {
        if (REQUEST.paidBannerMode == "selection_error") throw(message="Synthetic paid selector unavailable");
        if (REQUEST.paidBannerMode == "no_paid") return queryNew("");
        if (REQUEST.paidBannerMode == "model_mismatch") return candidate("HOUSE");
        return candidate("CPC");
    }
    if (findNoCase("select_house_banner_candidate", arguments.sql)) return candidate("HOUSE");
    if (findNoCase("serve_delivery", arguments.sql)) {
        return receipt(REQUEST.paidBannerMode == "no_paid" || REQUEST.paidBannerMode == "house_only" ? "HOUSE" : "CPC");
    }
    throw(message="Unexpected SQL at paid banner boundary");
};

try {
    service = createObject("component", "paidBannerTest.Banner").init({
        housePlacements=["rr-sidebar-banner-300x250"],
        bannerCpcPlacements=["rr-sidebar-banner-300x250"]
    });
    result = service.deliver(deviceClass="DESKTOP", regionCode="SC", route="sidebar", pageKey="home");
    check(result.status == "served" && result.billingModel == "CPC", "eligible CPC banner wins before HOUSE and exposes receipt billing");
    check(arrayLen(REQUEST.paidBannerCalls) == 2
        && findNoCase("select_paid_banner_candidate", REQUEST.paidBannerCalls[1].sql)
        && findNoCase("serve_delivery", REQUEST.paidBannerCalls[2].sql), "paid win never queries HOUSE");
    check(!structKeyExists(REQUEST.paidBannerCalls[2].params, "price_candidate"), "canonical serve receives no caller price");
    check(REQUEST.paidBannerCalls[1].params.region_code.value == "SC"
        && REQUEST.paidBannerCalls[1].params.banner_page.value == "home", "selected UF and page reach paid selector");
    check(findNoCase('"banner_page":"home"', REQUEST.paidBannerCalls[2].params.request_context.value), "canonical serve receipt keeps banner page context");

    REQUEST.paidBannerCalls = []; REQUEST.paidBannerMode = "no_paid";
    result = service.deliver(deviceClass="MOBILE", regionCode="", route="sidebar", pageKey="event");
    check(result.status == "served" && result.billingModel == "HOUSE", "no paid candidate falls back to canonical HOUSE");
    check(arrayLen(REQUEST.paidBannerCalls) == 3
        && findNoCase("select_paid_banner_candidate", REQUEST.paidBannerCalls[1].sql)
        && findNoCase("select_house_banner_candidate", REQUEST.paidBannerCalls[2].sql), "HOUSE is queried only after an empty paid result");
    check(REQUEST.paidBannerCalls[1].params.region_code.null, "unknown UF remains null for paid selection");

    REQUEST.paidBannerCalls = []; REQUEST.paidBannerMode = "selection_error";
    result = service.deliver();
    check(result.status == "fallback" && result.errorStage == "selection" && arrayLen(REQUEST.paidBannerCalls) == 1,
        "paid selector error enters editorial fallback without querying HOUSE");

    REQUEST.paidBannerCalls = []; REQUEST.paidBannerMode = "model_mismatch";
    result = service.deliver();
    check(result.status == "non_cpc" && arrayLen(REQUEST.paidBannerCalls) == 1,
        "paid selector model mismatch fails closed without HOUSE reclassification");

    REQUEST.paidBannerCalls = []; REQUEST.paidBannerMode = "house_only";
    houseService = createObject("component", "paidBannerTest.Banner").init({housePlacements=["rr-sidebar-banner-300x250"]});
    result = houseService.deliver();
    check(result.status == "served" && result.billingModel == "HOUSE"
        && findNoCase("select_house_banner_candidate", REQUEST.paidBannerCalls[1].sql), "paid gate off preserves HOUSE-only delivery");

    REQUEST.paidBannerCalls = []; REQUEST.paidBannerMode = "paid";
    paidOnlyService = createObject("component", "paidBannerTest.Banner").init({bannerCpcPlacements=["rr-sidebar-banner-300x250"]});
    result = paidOnlyService.deliver();
    check(result.status == "served" && result.billingModel == "CPC" && arrayLen(REQUEST.paidBannerCalls) == 2,
        "paid-only flag can serve without HOUSE enablement");
} finally {
    directoryDelete(scratch, true);
}
</cfscript>
