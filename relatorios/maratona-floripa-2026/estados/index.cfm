<cfinclude template="../includes/auth.cfm"/>
<cfinclude template="../includes/data.cfm"/>

<cfset VARIABLES.mifStatesPayload = mifReadDataset("states/strategy.json")/>
<cfset VARIABLES.mifStatesPayloadJson = serializeJson(VARIABLES.mifStatesPayload)/>
<cfset VARIABLES.mifStatesPayloadJson = replace(VARIABLES.mifStatesPayloadJson, "<", "\u003c", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Estratégia por estado — Maratona de Floripa 2026</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
  <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,600;0,700;0,800;0,900;1,700;1,800&amp;family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
  <link rel="stylesheet" href="../assets/report.css?v=20260903-9"/>
  <link rel="stylesheet" href="../assets/states.css?v=20260903-2"/>
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
        <a class="button button-current" aria-current="page" href="/relatorios/maratona-floripa-2026/estados/">Estados</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/canais/">Canais</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/portfolio/simulador.cfm">Simulador</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/explorador/">Explorador</a>
        <button class="button button-pdf" type="button" onclick="window.print()">Gerar PDF</button>
      </nav>
    </header>

    <section class="report-hero">
      <span class="eyebrow">Estratégia territorial · 2027</span>
      <h1>Estados, alcance e combinação de parceiros</h1>
      <p>Uma visão para escolher canais nacionais, reforços regionais e combinações que ampliem presença sem repetir o mesmo mandato territorial.</p>
      <p id="mif-generated-at">Base final reconciliada · inscrições encerradas</p>
    </section>

    <nav class="states-view-tabs no-print" aria-label="Visões territoriais" role="tablist">
      <button class="button button-current" type="button" data-state-view="overview" aria-selected="true">Visão geral</button>
      <button class="button" type="button" data-state-view="state" aria-selected="false">Escolher estado</button>
      <button class="button" type="button" data-state-view="compare" aria-selected="false">Comparar parceiros</button>
    </nav>

    <main class="report-content states-report" id="mif-states-root" aria-live="polite"></main>

    <footer class="report-footer">Agregados anônimos do ciclo comercial de 2026 · uso interno</footer>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifStatesPayloadJson#</cfoutput></script>
  <script src="../assets/report.js?v=20260903-9"></script>
  <script src="../assets/states.js?v=20260903-3"></script>
  <script>
    (function renderMifStatesPage() {
      'use strict';
      var payload = JSON.parse(document.getElementById('mif-report-data').textContent);
      MifStates.mount(document.getElementById('mif-states-root'), payload);
      var generatedAt = payload.meta && payload.meta.generated_at;
      if (generatedAt) document.getElementById('mif-generated-at').textContent = 'Base final gerada em ' + generatedAt + ' · inscrições encerradas';
    })();
  </script>
</body>
</html>
