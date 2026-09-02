<cfinclude template="../includes/auth.cfm"/>
<cfinclude template="../includes/data.cfm"/>

<cfset VARIABLES.mifPortfolioPayload = mifReadDataset("portfolio/summary.json")/>
<cfset VARIABLES.mifPortfolioPayloadJson = serializeJson(VARIABLES.mifPortfolioPayload)/>
<cfset VARIABLES.mifPortfolioPayloadJson = replace(VARIABLES.mifPortfolioPayloadJson, "<", "\u003c", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Portfólio de canais 2027 — Maratona de Floripa 2026</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
  <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,600;0,700;0,800;0,900;1,700;1,800&amp;family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
  <link rel="stylesheet" href="../assets/report.css?v=20260902-5"/>
  <link rel="stylesheet" href="../assets/portfolio.css?v=20260902-2"/>
</head>
<body>
  <div class="report-shell">
    <header class="report-topbar no-print">
      <div class="report-topbar-start">
        <a class="report-brand" href="/" aria-label="Run Pro Business"><img src="/lib/images/runpro.svg" alt="Run Pro"/></a>
      </div>
      <span>Decisão de portfólio · Evento 72611</span>
      <div class="report-actions">
        <a class="button" href="../">← Análise geral</a>
        <a class="button" href="../canais/">Dossiês</a>
        <a class="button" href="simulador.cfm">Simulador</a>
        <button class="button button-primary" type="button" onclick="window.print()">Gerar PDF</button>
      </div>
    </header>

    <section class="report-hero">
      <span class="eyebrow">Portfólio de canais · 2027</span>
      <h1>Escala, diferenciação e concentração</h1>
      <p>Leitura executiva do histórico de 2026 para revisar canais em conjunto sem confundir associação observada com causalidade ou previsão de vendas.</p>
      <p id="mif-generated-at">Base final reconciliada · inscrições encerradas</p>
    </section>

    <nav class="chapter-nav no-print" aria-label="Capítulos do portfólio">
      <a href="#portfolio-resumo">Resumo</a>
      <a href="#portfolio-diferenciacao">Diferenciação</a>
      <a href="#portfolio-redundancia">Pares para revisão</a>
      <a href="#portfolio-dependencias">Dependências</a>
      <a href="#portfolio-simulador">Como simular</a>
      <a href="#portfolio-metodo">Método</a>
    </nav>

    <main class="report-content portfolio-report" id="mif-portfolio-root" aria-live="polite"></main>

    <footer class="report-footer">
      Agregados anônimos do ciclo comercial de 2026 · uso interno
    </footer>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifPortfolioPayloadJson#</cfoutput></script>
  <script src="../assets/report.js?v=20260902-5"></script>
  <script src="../assets/portfolio.js?v=20260902-6"></script>
  <script>
    (function renderMifPortfolioPage() {
      'use strict';
      var payload = JSON.parse(document.getElementById('mif-report-data').textContent);
      MifPortfolio.renderSummary(document.getElementById('mif-portfolio-root'), payload);
      var generatedAt = payload.meta && payload.meta.generated_at;
      if (generatedAt) {
        document.getElementById('mif-generated-at').textContent = 'Base final gerada em ' + generatedAt + ' · inscrições encerradas';
      }
    })();
  </script>
</body>
</html>
