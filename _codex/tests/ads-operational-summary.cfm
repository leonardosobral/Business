<cfscript>
env = createObject("java", "java.lang.System").getenv();
if (!env.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS") || env.get("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;
repo = getDirectoryFromPath(getCurrentTemplatePath()) & "../../";
source = fileRead(repo & "ads/includes/workspace_admin.cfm");
start = find('<cfoutput query="qAdsV1AdminOperationalCampaigns">', source);
finish = find('</cfoutput>', source, start) + len('</cfoutput>');
fragment = mid(source, start, finish - start);
// Use production label helpers, without loading application queries or sessions.
homeSource = fileRead(repo & "ads/home.cfm");
helperStart = find('function adsV1PlacementLabel', homeSource);
helperEnd = find('function adsV1PlacementCountSummary', homeSource);
fragment = '<cfscript>' & mid(homeSource, helperStart, helperEnd - helperStart) & '</cfscript>' & fragment;
function adsV1CampaignStatusLabel(status) { return status == "ACTIVE" ? "Ativa" : "Pausada"; }
setLocale("Portuguese (Brazilian)");
qAdsV1AdminOperationalCampaigns = queryNew("campaign_id,account_id,campaign_name,campaign_status,cpc_bid,budget_total,budget_daily,starts_at,ends_at,target_device_class,target_country_code,target_region_code,account_name,event_name,event_tag,event_city,event_state,spent_total,served_count,viewable_impression_count,valid_click_count,billable_click_count,cost,placement_keys,reviewed_at");
queryAddRow(qAdsV1AdminOperationalCampaigns, [
 {campaign_id:"id-one", account_id:10, campaign_name:'Corrida <teste>', campaign_status:"ACTIVE", cpc_bid:0.94, budget_total:100, budget_daily:10, starts_at:createDate(2026,9,11), ends_at:createDate(2026,10,20), target_device_class:"ALL", target_country_code:"BR", target_region_code:"SP", account_name:"Conta A", event_name:"Evento Alfa", event_tag:"alfa", event_city:"São Paulo", event_state:"SP", spent_total:1.53, served_count:185, viewable_impression_count:17, valid_click_count:3, billable_click_count:3, cost:1.53, placement_keys:"rr-home-upcoming-native,rr-home-upcoming-native-secondary,rr-search-events-native,rr-state-events-native,rr-sidebar-event-native", reviewed_at:createDate(2026,9,11)},
 {campaign_id:"id-two", account_id:20, campaign_name:"Campanha Beta", campaign_status:"PAUSED", cpc_bid:0.56, budget_total:200, budget_daily:"", starts_at:"", ends_at:"", target_device_class:"MOBILE", target_country_code:"BR", target_region_code:"", account_name:"Conta B", event_name:"Evento Beta", event_tag:"beta", event_city:"Recife", event_state:"PE", spent_total:0, served_count:0, viewable_impression_count:0, valid_click_count:0, billable_click_count:0, cost:0, placement_keys:"rr-search-events-native", reviewed_at:""}
]);
temp = getTempDirectory() & "ads-operation-test-" & createUUID() & ".cfm";
try { fileWrite(temp, fragment); savecontent variable="html" { include temp; } }
finally { if (fileExists(temp)) fileDelete(temp); }
rows = reMatch('(?s)<details\b.*?</details>', html);
if (arrayLen(rows) != 2) throw(message="Each campaign needs its own collapsed details row");
for (i=1; i<=2; i++) {
 if (reFind('<details[^>]*\sopen(?:\s|>|=)', rows[i])) throw(message="Rows must start collapsed");
 summary = reMatch('(?s)<summary\b.*?</summary>', rows[i])[1];
 if (find("id-one", summary) || find("id-two", summary) || find("20/10/2026", summary)) throw(message="IDs and dates belong in expanded details");
 if (!find("CTR", summary) || !find("CPC médio", summary)) throw(message="Summary must show CTR and average CPC");
 if (i==1 && (!find("17,65%", summary) || !find("0,51", summary))) throw(message="Summary must calculate CTR and CPC from metrics, not bid");
 if (i==2 && (!find("CTR —", summary) || find("0,00%", summary))) throw(message="No impressions means undefined CTR, not zero percent");
 if (!find(i==1 ? "Conta A" : "Conta B", summary) || !find(i==1 ? "Ativa" : "Pausada", summary)) throw(message="Missing account/status in summary");
 if (!find(i==1 ? "Evento Alfa" : "Evento Beta", rows[i]) || find(i==1 ? "Evento Beta" : "Evento Alfa", rows[i])) throw(message="Details attached to wrong campaign");
}
if (find('<teste>', html) || !find('&lt;teste&gt;', html)) throw(message="Campaign names must be escaped");
if (!find("17,65", rows[1]) || !find("0,51", rows[1]) || !find("185", rows[1])) throw(message="Lost CTR/CPC/delivery details");
if (!find("Lateral do site", rows[1]) || !find("Eventos por estado", rows[1])) throw(message="Details must list every placement");
if (!find("0,00", rows[2]) || reFindNoCase('NaN|Infinity', html)) throw(message="Zero metrics must remain valid");
if (!find("20/10/2026", rows[1])) throw(message="End date must remain available in details");
// A paid click without a viewable impression must not manufacture a denominator.
querySetCell(qAdsV1AdminOperationalCampaigns, "valid_click_count", 1, 2);
querySetCell(qAdsV1AdminOperationalCampaigns, "billable_click_count", 1, 2);
querySetCell(qAdsV1AdminOperationalCampaigns, "cost", 0.94, 2);
try { fileWrite(temp, fragment); savecontent variable="clickHtml" { include temp; } }
finally { if (fileExists(temp)) fileDelete(temp); }
clickRows = reMatch('(?s)<details\b.*?</details>', clickHtml);
clickSummary = reMatch('(?s)<summary\b.*?</summary>', clickRows[2])[1];
if (!find("CTR —", clickSummary) || !find("0,94", clickSummary) || find("0,00%", clickRows[2])) throw(message="Click without impression must retain CPC and undefined CTR in both views");
writeOutput("ADS OPERATIONAL SUMMARY: PASS (real CFML render; synthetic data)" & chr(10));
</cfscript>
