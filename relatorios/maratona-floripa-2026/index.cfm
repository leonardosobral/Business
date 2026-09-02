<cfinclude template="includes/auth.cfm"/>
<cfinclude template="includes/data.cfm"/>

<cfset VARIABLES.mifGeneralPayload = {
    "general" = mifReadDataset("general.json"),
    "cycle" = mifReadDataset("cycle.json"),
    "territories" = mifReadDataset("territories.json"),
    "products" = mifReadDataset("products.json"),
    "channels" = mifReadDataset("channels/index.json")
}/>
<cfset VARIABLES.mifGeneralPayloadJson = serializeJson(VARIABLES.mifGeneralPayload)/>
<cfset VARIABLES.mifGeneralPayloadJson = replace(VARIABLES.mifGeneralPayloadJson, "</", "<\/", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Maratona de Floripa 2026 — estudo de vendas</title>
  <link rel="stylesheet" href="assets/report.css?v=20260902-1"/>
</head>
<body>
  <div class="report-shell">
    <header class="report-topbar no-print">
      <a href="/">Road Runners Business</a>
      <span>Estudo pós-vendas · Evento 72611</span>
      <div class="report-actions">
        <a class="button" href="canais/">Dossiês de canais</a>
        <a class="button" href="explorador/">Explorador</a>
        <button class="button button-primary" type="button" onclick="window.print()">Gerar PDF</button>
      </div>
    </header>

    <section class="report-hero">
      <span class="eyebrow">Maratona Internacional de Floripa 2026</span>
      <h1>Performance de vendas e estratégia de canais</h1>
      <p>Leitura fechada do ciclo comercial: quando as distâncias venderam, como lotes, estados, produtos e canais se combinaram e onde concentrar o portfólio do próximo ano.</p>
      <p id="mif-generated-at">Base final reconciliada · inscrições encerradas</p>
    </section>

    <nav class="chapter-nav no-print" aria-label="Capítulos do relatório">
      <a href="#resumo-executivo">Resumo</a>
      <a href="#ciclo-de-vendas">Ciclo</a>
      <a href="#distancias">Distâncias</a>
      <a href="#lotes-e-produtos">Lotes e produtos</a>
      <a href="#territorios">Territórios</a>
      <a href="#canais">Canais</a>
      <a href="#roadrunners">ROADRUNNERS</a>
      <a href="#recomendacoes-e-metodo">Recomendações</a>
    </nav>

    <main class="report-content" id="mif-report-root" aria-live="polite"></main>

    <footer class="report-footer">
      Agregados anônimos reconciliados de pedidos, inscrições e produtos · uso interno
    </footer>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifGeneralPayloadJson#</cfoutput></script>
  <script src="assets/report.js?v=20260902-1"></script>
  <script>
    (function renderMifGeneralPage() {
      'use strict';
      var payloadNode = document.getElementById('mif-report-data');
      var payload = JSON.parse(payloadNode.textContent);
      MifReport.renderGeneral(document.getElementById('mif-report-root'), payload);
      var generatedAt = payload.general && payload.general.meta && payload.general.meta.generated_at;
      if (generatedAt) {
        document.getElementById('mif-generated-at').textContent = 'Base final gerada em ' + generatedAt + ' · inscrições encerradas';
      }
    })();
  </script>
</body>
</html>
