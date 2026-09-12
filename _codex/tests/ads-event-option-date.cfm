<cfscript>
// Render the production option block: missing/wrong dates must fail this test.
source = fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../../ads/includes/workspace_campaign_form.cfm");
blockStart = find('<cfoutput query="qAdsV1Events">', source);
blockEnd = find('</cfoutput>', source, blockStart);
fragment = mid(source, blockStart, blockEnd + len('</cfoutput>') - blockStart);
qAdsV1Events = queryNew("id_evento,nome_evento,cidade,estado,tag,data_inicial,data_final,url_imagem_listagem,url_imagem,imagem,event_link_status");
queryAddRow(qAdsV1Events, [
    {id_evento: 1, nome_evento: "Corrida teste", cidade: "São Paulo", estado: "SP", tag: "teste", data_inicial: createDate(2026, 9, 18), data_final: createDate(2026, 9, 20), url_imagem_listagem: "", url_imagem: "", imagem: "", event_link_status: "ATIVO"},
    {id_evento: 2, nome_evento: "Sem data", cidade: "Recife", estado: "PE", tag: "sem-data", data_inicial: "", data_final: "", url_imagem_listagem: "", url_imagem: "", imagem: "", event_link_status: "ATIVO"},
    {id_evento: 3, nome_evento: "Evento pendente", cidade: "Curitiba", estado: "PR", tag: "pendente", data_inicial: createDate(2026, 10, 1), data_final: createDate(2026, 10, 2), url_imagem_listagem: "", url_imagem: "", imagem: "", event_link_status: "PENDENTE"}
]);
variables.adsV1FormEventId = 1;
variables.adsV1AccountId = 10;
qAdsV1Campaigns = queryNew("campaign_id,account_id,core_event_id,status,review_status");
queryAddRow(qAdsV1Campaigns, [
    {campaign_id: "active-1", account_id: 10, core_event_id: 1, status: "ACTIVE", review_status: "APPROVED"},
    {campaign_id: "draft-1", account_id: 10, core_event_id: 1, status: "DRAFT", review_status: ""},
    {campaign_id: "other-account", account_id: 99, core_event_id: 2, status: "ACTIVE", review_status: "APPROVED"},
    {campaign_id: "review-3", account_id: 10, core_event_id: 3, status: "DRAFT", review_status: "PENDING_REVIEW"},
    {campaign_id: "paused", account_id: 10, core_event_id: 4, status: "PAUSED", review_status: "APPROVED"},
    {campaign_id: "ended", account_id: 10, core_event_id: 5, status: "ENDED", review_status: "PENDING_REVIEW"},
    {campaign_id: "waiting", account_id: 10, core_event_id: 6, status: "DRAFT", review_status: "WAITING_PREREQUISITES"},
    {campaign_id: "changes", account_id: 10, core_event_id: 7, status: "DRAFT", review_status: "CHANGES_REQUESTED"},
    {campaign_id: "canceled", account_id: 10, core_event_id: 8, status: "DRAFT", review_status: "CANCELED"}
]);
summaryPath = getDirectoryFromPath(getCurrentTemplatePath()) & "../../ads/includes/event_campaign_summary.cfm";
if (fileExists(summaryPath)) include summaryPath;
// Image resolution is unrelated to the option's visible date.
function adsV1EventImageUrl(raw) { return ""; }
fragmentPath = getTempDirectory() & "ads-event-options-" & createUUID() & ".cfm";
try {
    fileWrite(fragmentPath, fragment);
    savecontent variable="rendered" { include fragmentPath; }
} finally {
    if (fileExists(fragmentPath)) fileDelete(fragmentPath);
}
options = reMatch("(?s)<option[^>]*>.*?</option>", rendered);
expected = [
    "20/09/2026 — [2 campanhas: ativa e rascunho] — Corrida teste — São Paulo/SP",
    "[Sem campanha] — Sem data — Recife/PE",
    "02/10/2026 — [Em análise] — Evento pendente — Curitiba/PR (vínculo em análise)"
];
if (arrayLen(options) != arrayLen(expected)) throw(message="Unexpected option count");
for (i = 1; i <= arrayLen(expected); i++) {
    label = trim(reReplace(reReplace(options[i], "<[^>]+>", "", "all"), "\s+", " ", "all"));
    if (label != expected[i]) throw(message="Option #i#: expected [#expected[i]#], got [#label#]");
}
expectedStatuses = {"4": "Pausada", "5": "Finalizada", "6": "Aguardando pré-requisitos", "7": "Ajustes solicitados", "8": "Análise cancelada"};
for (eventId in expectedStatuses) {
    if (variables.adsV1EventCampaignSummaries[eventId] != expectedStatuses[eventId]) throw(message="Wrong summary for event #eventId#");
}
writeOutput("ADS EVENT OPTION DATE: PASS (final date, missing date, pending link)" & chr(10));
</cfscript>
