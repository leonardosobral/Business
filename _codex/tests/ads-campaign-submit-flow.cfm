<cfscript>
// Executes production CFML branching/rendering, stubbing only database calls.
// No application datasource is loaded and no campaign is written.
env = createObject("java", "java.lang.System").getenv();
if (!env.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") || env.get("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;
repo = getDirectoryFromPath(getCurrentTemplatePath()) & "../../";
source = fileRead(repo & "ads/includes/backend.cfm");
start = find('<cfcase value="save_campaign">', source);
start = find('<cftransaction>', source, start);
finish = find('</cfcase>', source, start);
flow = mid(source, start, finish - start);
queries = reMatch('(?s)<cfquery\b[^>]*>.*?</cfquery>', flow);
for (querySource in queries) {
    kind = find('ads.submit_campaign_review(', querySource) ? "submit" : (find('ads.replace_campaign_placements(', querySource) ? "placements" : "save");
    replacement = '<cfset arrayAppend(VARIABLES.calls, "' & kind & '")/><cfif VARIABLES.failAt EQ "' & kind & '"><cfthrow type="Test.DatabaseFailure" message="simulated database failure"/></cfif>';
    if (kind == "submit") {
        sql = reReplace(querySource, '<cfquery\b[^>]*>|</cfquery>', '', 'all');
        sql = reReplace(sql, '<cfqueryparam\b[^>]*value="([^"]*)"[^>]*>', '\1', 'all');
        replacement &= '<cfsavecontent variable="VARIABLES.submittedSql"><cfoutput>' & sql & '</cfoutput></cfsavecontent>';
    }
    flow = replace(flow, querySource, replacement);
}
flow = reReplace(flow, '<cflocation[^>]*url="([^"]*)"[^>]*>', '<cfset VARIABLES.redirect="\1"/>', 'all');
function renderFragment(required string fragment) {
    var file = getTempDirectory() & "ads-submit-test-" & createUUID() & ".cfm";
    var output = "";
    try {
        fileWrite(file, arguments.fragment);
        savecontent variable="output" { include file; }
    } finally { if (fileExists(file)) fileDelete(file); }
    return output;
}
failures = [];
function check(required boolean condition, required string label) {
    if (!arguments.condition) arrayAppend(VARIABLES.failures, arguments.label);
}
qAdsV1CampaignSave = queryNew("campaign_id", "varchar", [{campaign_id: "11111111-1111-4111-8111-111111111111"}]);
qAdsV1EventTarget = queryNew("id_evento", "integer", [{id_evento: 321}]);
VARIABLES.adsV1AccountId = 10;
VARIABLES.adsV1ActorId = 12;
for (intent in ["submit", "draft", "legacy"]) {
    structDelete(FORM, "campaign_intent");
    if (intent != "legacy") FORM.campaign_intent = intent;
    VARIABLES.calls = []; VARIABLES.redirect = ""; VARIABLES.failAt = ""; VARIABLES.submittedSql = "";
    renderFragment(flow);
    check(arrayToList(VARIABLES.calls) == (intent == "submit" ? "save,placements,submit" : "save,placements"), "Wrong save/submit sequence: " & intent);
    check(find(intent == "submit" ? "success=campaign-submitted" : "success=campaign-saved", VARIABLES.redirect) > 0, "Wrong confirmation: " & intent);
    if (intent == "submit") {
        check(find("11111111-1111-4111-8111-111111111111", VARIABLES.submittedSql) > 0 && find("321", VARIABLES.submittedSql) > 0, "Review must target the saved campaign and linked event");
    }
}
FORM.campaign_intent = "submit";
for (failure in ["save", "placements", "submit"]) {
    VARIABLES.calls = []; VARIABLES.redirect = ""; VARIABLES.failAt = failure;
    caught = false;
    try { renderFragment(flow); } catch (Test.DatabaseFailure e) { caught = true; }
    check(caught && !len(VARIABLES.redirect), "Failure must not show success: " & failure);
}
formSource = fileRead(repo & "ads/includes/workspace_campaign_form.cfm");
footer = reMatch('(?s)<footer\b.*?</footer>', formSource)[1];
footerHtml = renderFragment(footer);
check(reFind('id="ads-wizard-submit"[^>]*name="campaign_intent"[^>]*value="submit"', footerHtml) > 0, "Primary button must submit for review");
check(reFind('id="ads-wizard-draft"[^>]*name="campaign_intent"[^>]*value="draft"', footerHtml) > 0, "Secondary button must keep a draft");
rowSource = fileRead(repo & "ads/includes/workspace_campaigns.cfm");
row = reMatch('(?s)<td class="text-end"><div class="ads-campaign-actions">.*?</td>', rowSource)[1];
VARIABLES.adsAccessCanManageCampaign = true;
VARIABLES.adsV1Csrf = "test-csrf";
qAdsV1Campaigns = queryNew("campaign_id", "varchar", [{campaign_id: "11111111-1111-4111-8111-111111111111"}]);
VARIABLES.adsV1RowStatus = "DRAFT";
for (review in ["", "CHANGES_REQUESTED", "PENDING_REVIEW", "WAITING_PREREQUISITES"]) {
    VARIABLES.adsV1RowReviewStatus = review;
    html = renderFragment('<cfoutput>' & row & '</cfoutput>');
    visible = reReplace(html, '(?s)<details\b.*?</details>', '', 'all');
    check((find('value="submit_campaign_review"', visible) > 0) == (listFind("new,CHANGES_REQUESTED", len(review) ? review : "new") > 0), "Visible review action wrong: " & review);
}
VARIABLES.adsAccessCanManageCampaign = false;
VARIABLES.adsV1RowReviewStatus = "";
html = renderFragment('<cfoutput>' & row & '</cfoutput>');
check(!find('value="submit_campaign_review"', html), "Read-only users cannot submit");
for (canManage in [true, false]) {
    VARIABLES.adsAccessCanManageCampaign = canManage;
    for (review in ["PENDING_REVIEW", "WAITING_PREREQUISITES"]) {
        VARIABLES.adsV1RowStatus = "DRAFT";
        VARIABLES.adsV1RowReviewStatus = review;
        html = renderFragment('<cfoutput>' & row & '</cfoutput>');
        check((find('value="prepare_campaign_edit"', html) > 0) == canManage, "Review editing permission wrong: " & review);
        check(!find('href="./?view=campaigns&amp;campaign=', html), "Review must be withdrawn before opening editor: " & review);
    }
}
homeSource = fileRead(repo & "ads/home.cfm");
defaultsStart = find('<cfset VARIABLES.adsV1FormCampaignId = ""/>', homeSource);
defaultsEnd = find('<cfset VARIABLES.adsV1DraftCount', homeSource, defaultsStart);
defaults = mid(homeSource, defaultsStart, defaultsEnd - defaultsStart);
VARIABLES.adsV1SelectableEventPlacementKeys = ["rr-home-upcoming-native", "rr-search-events-native", "rr-state-events-native", "rr-sidebar-event-native"];
VARIABLES.adsAccessCanManageCampaign = true;
VARIABLES.adsV1Error = "";
FORM.ads_v1_action = "";
qAdsV1SelectedCampaign = queryNew("campaign_id");
renderFragment(defaults);
check(arrayLen(VARIABLES.adsV1FormPlacementKeys) == 4, "New campaign must select all four areas");
qAdsV1SelectedCampaign = queryNew("campaign_id,core_event_id,name,cpc_bid,budget_total,budget_daily,starts_at,ends_at,target_device_class,target_country_code,target_region_code,placement_keys,status,review_status", "varchar,integer,varchar,decimal,decimal,varchar,timestamp,timestamp,varchar,varchar,varchar,varchar,varchar,varchar", [{campaign_id: "11111111-1111-4111-8111-111111111111", core_event_id:321, name:"Test", cpc_bid:0.94, budget_total:100, budget_daily:"", starts_at:now(), ends_at:dateAdd("d",1,now()), target_device_class:"ALL", target_country_code:"BR", target_region_code:"SP", placement_keys:"rr-search-events-native", status:"DRAFT", review_status:"CANCELED"}]);
renderFragment(defaults);
check(arrayToList(VARIABLES.adsV1FormPlacementKeys) == "rr-search-events-native", "Editing must preserve saved areas");
for (review in ["PENDING_REVIEW", "WAITING_PREREQUISITES", "APPROVED"]) {
    querySetCell(qAdsV1SelectedCampaign, "review_status", review, 1);
    renderFragment(defaults);
    check(!VARIABLES.adsV1CampaignEditable, "Direct URL must not bypass withdrawal: " & review);
    guardStart = find('<cfif NOT qAdsV1CampaignSaveTarget.recordcount', source);
    guardEnd = find('</cfif>', source, guardStart) + len('</cfif>');
    qAdsV1CampaignSaveTarget = queryNew("review_status", "varchar", [{review_status:review}]);
    blocked = false;
    try { renderFragment(mid(source, guardStart, guardEnd - guardStart)); } catch (AdsV1.Validation e) { blocked = true; }
    check(blocked, "POST must not bypass withdrawal: " & review);
}
FORM.ads_v1_action = "save_campaign";
VARIABLES.adsV1Error = "test validation error";
structDelete(FORM, "placement_keys");
renderFragment(defaults);
check(arrayLen(VARIABLES.adsV1FormPlacementKeys) == 0, "Failed submission with no areas must not select defaults again");
if (arrayLen(failures)) throw(message=arrayToList(failures, chr(10)));
writeOutput("ADS CAMPAIGN SUBMIT FLOW: PASS (database boundary simulated; no live writes)" & chr(10));
</cfscript>
