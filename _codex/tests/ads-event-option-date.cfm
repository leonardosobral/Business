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
    "Corrida teste — São Paulo/SP — 20/09/2026",
    "Sem data — Recife/PE",
    "Evento pendente — Curitiba/PR — 02/10/2026 (vínculo em análise)"
];
if (arrayLen(options) != arrayLen(expected)) throw(message="Unexpected option count");
for (i = 1; i <= arrayLen(expected); i++) {
    label = trim(reReplace(reReplace(options[i], "<[^>]+>", "", "all"), "\s+", " ", "all"));
    if (label != expected[i]) throw(message="Option #i#: expected [#expected[i]#], got [#label#]");
}
writeOutput("ADS EVENT OPTION DATE: PASS (final date, missing date, pending link)" & chr(10));
</cfscript>
