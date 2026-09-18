<cfscript>
testEnvironment = createObject("java", "java.lang.System").getenv();
if (!testEnvironment.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") || testEnvironment.get("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") {
    cfheader(statuscode=404); abort;
}
function check(required boolean condition, required string label) {
    if (!arguments.condition) throw(type="AdsListingTestFailure", message=arguments.label);
    writeOutput("PASS: " & arguments.label & chr(10));
}
// Execute the real orchestration, replacing only external config/metrics I/O.
source = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../../../RoadRunners/includes/eventos_ads.cfm");
scriptStart = find('<cfscript>', source, find('Todos os spots patrocinados', source));
scriptEnd = find('</cfscript>', source, scriptStart);
script = mid(source, scriptStart, scriptEnd - scriptStart + len('</cfscript>'));
script = replace(script, 'include "ads_v1/runtime_config.cfm";', '', 'one');
script = replace(script, 'include "analytics/slot_marker.cfm";', 'arrayAppend(VARIABLES.testMarkers, duplicate(VARIABLES.audienceSlot));', 'all');
fixture = getTempDirectory() & "ads-listing-" & createUUID() & ".cfm";
fileWrite(fixture, script);
try {
    for (scenario in [
        {path="/estado/", route="state", slots=["rr-state-events-native", "rr-state-events-native"]},
        {path="/busca/", route="search", slots=["rr-search-events-native", "rr-search-events-native"]},
        {path="/", route="home", slots=["rr-home-upcoming-native", "rr-home-upcoming-native-secondary"]}
    ]) {
        for (available in [2, 1, 0]) {
            VARIABLES.template = scenario.path;
            VARIABLES.adContextUf = "BA";
            VARIABLES.testCalls = [];
            VARIABLES.testMarkers = [];
            VARIABLES.testAvailable = available;
            REQUEST.adsV1 = {cpcPlacements=scenario.slots, housePlacements=[]};
            VARIABLES.adsV1CpcService = {deliver=function() {
                arrayAppend(VARIABLES.testCalls, duplicate(arguments));
                var index = arrayLen(VARIABLES.testCalls);
                if (index > VARIABLES.testAvailable) return {status="no_candidate", coreEventId=0, errorStage=""};
                return {status="served", coreEventId=index, campaignId="campaign-" & index,
                    deliveryId="delivery-" & index, viewEventId="view-" & index,
                    clickEventId="click-" & index, rawToken="test-token-" & index};
            }};
            include fixture;
            check(arrayLen(VARIABLES.testCalls) == 2, scenario.route & ": two auction requests (available=" & available & ")");
            check(arrayLen(VARIABLES.adsV1NativeDeliveredSlots) == available, "only eligible results render");
            for (i in [1, 2]) {
                check(VARIABLES.testCalls[i].placementKey == scenario.slots[i] && VARIABLES.testCalls[i].route == scenario.route,
                    "canonical placement and route retained for position " & i);
                check(VARIABLES.testCalls[i].regionCode == "BA" && VARIABLES.testCalls[i].countryCode == "BR", "regional auction context retained");
            }
            check(arrayLen(VARIABLES.testCalls[1].excludedCampaignIds) == 0, "first auction has no prior winner");
            check(arrayLen(VARIABLES.testCalls[2].excludedCampaignIds) == min(available, 1), "second auction excludes exactly prior served winner");
            if (available > 0) check(VARIABLES.testCalls[2].excludedCampaignIds[1] == "campaign-1", "first campaign cannot win twice");
            check(arrayLen(VARIABLES.testMarkers) == 2 - available, "unfilled positions are marked, not fabricated");
            physicalKeys = [];
            for (servedSlot in VARIABLES.adsV1NativeDeliveredSlots) arrayAppend(physicalKeys, servedSlot.slotKey);
            for (marker in VARIABLES.testMarkers) arrayAppend(physicalKeys, marker.key);
            check(arrayLen(physicalKeys) == 2 && physicalKeys[1] != physicalKeys[2], "physical inventory positions have distinct tracking keys");
        }
    }
    writeOutput("ADS LISTING TWO SLOTS: PASSED" & chr(10));
} finally {
    fileDelete(fixture);
}
</cfscript>
