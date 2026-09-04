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
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
  <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,600;0,700;0,800;0,900;1,700;1,800&amp;family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
  <link rel="stylesheet" href="../assets/report.css?v=20260903-9"/>
</head>
<body>
  <div class="report-shell">
    <header class="report-topbar no-print">
      <div class="report-topbar-start">
        <a class="report-brand" href="/" aria-label="Run Pro Business"><img src="/lib/images/runpro.svg" alt="Run Pro"/></a>
      </div>
      <nav class="report-actions" aria-label="Áreas do estudo">
        <a class="button" href="/relatorios/maratona-floripa-2026/">Visão geral</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/portfolio/">Portfólio 2027</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/estados/">Estados</a>
        <a class="button button-current" aria-current="page" href="/relatorios/maratona-floripa-2026/canais/">Canais</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/portfolio/simulador.cfm">Simulador</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/explorador/">Explorador</a>
        <button class="button button-pdf" type="button" onclick="window.print()">Gerar PDF</button>
      </nav>
    </header>
    <section class="report-hero">
      <span class="eyebrow">Dossiês individuais</span>
      <h1>Canais em ordem de valor vendido</h1>
      <p>O catálogo comercial começa pelo maior valor bruto alocado e omite canais com ticket médio de até R$ 10,00. Cada dossiê registra highlights, ciclo, distâncias, lotes, territórios, produtos vendidos além do kit, aliases de cupom e recomendação.</p>
    </section>
    <main class="report-content" id="mif-channel-index-root" aria-live="polite"></main>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifChannelIndexJson#</cfoutput></script>
  <script src="../assets/report.js?v=20260903-9"></script>
  <script>
    (function renderMifChannelIndexPage() {
      'use strict';
      var payload = JSON.parse(document.getElementById('mif-report-data').textContent);
      MifReport.renderChannelIndex(document.getElementById('mif-channel-index-root'), payload);
    })();
  </script>
</body>
</html>
