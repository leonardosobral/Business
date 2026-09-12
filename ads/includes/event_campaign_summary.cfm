<cfscript>
// Reuse the account-scoped campaign query; no extra query per event.
function adsV1BuildEventCampaignSummaries(required query campaigns, required numeric accountId) {
    var grouped = {};
    var summaries = {};
    var seen = {};
    var campaign = {};
    var eventKey = "";
    var campaignKey = "";
    var label = "";
    var status = "";
    var review = "";
    for (campaign in arguments.campaigns) {
        if (val(campaign.account_id) != arguments.accountId || val(campaign.core_event_id) <= 0) continue;
        eventKey = campaign.core_event_id & "";
        campaignKey = campaign.campaign_id & "";
        if (structKeyExists(seen, campaignKey)) continue;
        seen[campaignKey] = true;
        status = uCase(trim(campaign.status & ""));
        review = uCase(trim(campaign.review_status & ""));
        // Operational state wins for active, paused and finalized campaigns.
        switch (status) {
            case "ACTIVE": label = "Ativa"; break;
            case "PAUSED": label = "Pausada"; break;
            case "ENDED": label = "Finalizada"; break;
            default:
                switch (review) {
                    case "WAITING_PREREQUISITES": label = "Aguardando pré-requisitos"; break;
                    case "PENDING_REVIEW": label = "Em análise"; break;
                    case "CHANGES_REQUESTED": label = "Ajustes solicitados"; break;
                    case "CANCELED": label = "Análise cancelada"; break;
                    case "APPROVED": label = "Aprovada"; break;
                    default: label = "Rascunho";
                }
        }
        if (!structKeyExists(grouped, eventKey)) grouped[eventKey] = {count: 0, labels: []};
        grouped[eventKey].count++;
        if (!arrayFindNoCase(grouped[eventKey].labels, label)) arrayAppend(grouped[eventKey].labels, label);
    }
    for (eventKey in grouped) {
        summaries[eventKey] = grouped[eventKey].count EQ 1
            ? grouped[eventKey].labels[1]
            : grouped[eventKey].count & " campanhas: " & lCase(arrayToList(grouped[eventKey].labels, " e "));
    }
    return summaries;
}
VARIABLES.adsV1EventCampaignSummaries = adsV1BuildEventCampaignSummaries(qAdsV1Campaigns, VARIABLES.adsV1AccountId);
</cfscript>
