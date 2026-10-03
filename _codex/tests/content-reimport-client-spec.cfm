<cfscript>
failures = [];
function expect(required boolean condition, required string message) {
  if (!arguments.condition) arrayAppend(failures, arguments.message);
}

contentReimportClient = createObject("component", "portal.services.content_reimport_client").init(
  "https://conteudo.roadrunners.run",
  "test-secret"
);
requestData = contentReimportClient.buildRequest(42, "2026-10-02 12:34:56");

expect(requestData.endpoint EQ "https://conteudo.roadrunners.run/api/admin/importers/reimport.cfm", "usa o endpoint unitário do News");
expect(deserializeJSON(requestData.body).content_id EQ 42, "envia somente o ID numérico do conteúdo");
expect(requestData.timestamp EQ "2026-10-02 12:34:56", "mantém o timestamp usado na assinatura");
expect(requestData.signature EQ lCase(hmac(requestData.timestamp & "." & requestData.body, "test-secret", "HmacSHA256", "UTF-8")), "assina exatamente timestamp e corpo");

success = contentReimportClient.parseResponse(200, serializeJSON({success=true,status="completed",message="Conteúdo reimportado.",updated=1}));
expect(success.success AND success.message EQ "Conteúdo reimportado.", "normaliza a resposta de sucesso");

failure = contentReimportClient.parseResponse(409, serializeJSON({success=false,status="locked",message="Importador em execução."}));
expect(!failure.success AND failure.status EQ "locked", "preserva o erro operacional retornado pelo News");

invalid = contentReimportClient.parseResponse(502, "resposta inválida");
expect(!invalid.success AND findNoCase("resposta inválida", invalid.message), "trata respostas não JSON sem vazar detalhes internos");

cfcontent(type="application/json; charset=utf-8");
if (arrayLen(failures)) {
  cfheader(statuscode=500);
  writeOutput(serializeJSON({ok=false, failures=failures}));
} else {
  writeOutput(serializeJSON({ok=true, tests=7}));
}
</cfscript>
