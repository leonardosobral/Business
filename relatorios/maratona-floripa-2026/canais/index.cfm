<cfinclude template="../includes/auth.cfm"/>
<cfinclude template="../includes/data.cfm"/>

<cfset VARIABLES.mifChannelIndexPayload = mifReadDataset("channels/index.json")/>
<cfset VARIABLES.mifChannelIndexJson = serializeJson(VARIABLES.mifChannelIndexPayload)/>
<cfset VARIABLES.mifChannelIndexJson = replace(VARIABLES.mifChannelIndexJson, "</", "<\/", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Dossiês de canais — Maratona de Floripa 2026</title>
  <link rel="stylesheet" href="../assets/report.css?v=20260902-1"/>
</head>
<body>
  <div class="report-shell">
    <header class="report-topbar no-print">
      <a href="../">← Análise geral</a>
      <span>Portfólio de canais · Evento 72611</span>
      <div class="report-actions">
        <a class="button" href="../explorador/">Explorador</a>
        <button class="button button-primary" type="button" onclick="window.print()">Gerar PDF da lista</button>
      </div>
    </header>
    <section class="report-hero">
      <span class="eyebrow">Dossiês individuais</span>
      <h1>Canais em ordem de valor vendido</h1>
      <p>O catálogo completo começa pelo maior valor bruto alocado. Cada dossiê registra highlights, ciclo, distâncias, lotes, territórios, produtos, aliases de cupom e recomendação.</p>
    </section>
    <main class="report-content" id="mif-channel-index-root" aria-live="polite"></main>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifChannelIndexJson#</cfoutput></script>
  <script src="../assets/report.js?v=20260902-1"></script>
  <script>
    (function renderMifChannelIndexPage() {
      'use strict';
      var payload = JSON.parse(document.getElementById('mif-report-data').textContent);
      MifReport.renderChannelIndex(document.getElementById('mif-channel-index-root'), payload);
    })();
  </script>
</body>
</html>
