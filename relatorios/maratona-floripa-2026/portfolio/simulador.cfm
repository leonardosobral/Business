<cfset VARIABLES.mifReportRequestedReturnPath = "/relatorios/maratona-floripa-2026/portfolio/simulador.cfm"/>
<cfif structKeyExists(CGI, "QUERY_STRING") AND len(trim(CGI.QUERY_STRING & ""))>
    <cfset VARIABLES.mifReportRequestedReturnPath &= "?" & trim(CGI.QUERY_STRING & "")/>
</cfif>
<cfinclude template="../includes/auth.cfm"/>
<cfinclude template="../includes/data.cfm"/>

<cfset VARIABLES.mifPortfolioSimulatorPayload = mifReadDataset("portfolio/simulator.json")/>
<cfset VARIABLES.mifPortfolioSimulatorPayloadJson = serializeJson(VARIABLES.mifPortfolioSimulatorPayload)/>
<cfset VARIABLES.mifPortfolioSimulatorPayloadJson = replace(VARIABLES.mifPortfolioSimulatorPayloadJson, "<", "\u003c", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Simulador de cobertura — Maratona de Floripa 2026</title>
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
      <span>Simulador descritivo · Evento 72611</span>
      <div class="report-actions">
        <a class="button" href="../">← Análise geral</a>
        <a class="button" href="../canais/">Dossiês</a>
        <a class="button" href="./">Portfólio</a>
        <button class="button button-primary" type="button" onclick="window.print()">Gerar PDF</button>
      </div>
    </header>

    <section class="report-hero">
      <span class="eyebrow">Cenário controlado · 1 a 10 canais</span>
      <h1>Simulador de cobertura em risco</h1>
      <p>Observe onde um conjunto de canais esteve concentrado em 2026. O cenário descreve participação histórica; não estima demanda futura nem garante substituição.</p>
    </section>

    <nav class="chapter-nav no-print" aria-label="Navegação do simulador">
      <a href="#configurar-cenario">Configurar cenário</a>
      <a href="#resultado-cenario">Resultado</a>
    </nav>

    <main class="report-content portfolio-selector-grid">
      <aside class="portfolio-selector-panel no-print" id="configurar-cenario">
        <form id="portfolio-simulator-form">
          <header>
            <span class="eyebrow">Seleção comercial</span>
            <h2>Escolha os canais</h2>
            <p>A lista segue o valor bruto observado, do maior para o menor. Selecione entre um e dez canais.</p>
          </header>
          <label class="portfolio-search-field" for="portfolio-channel-search">
            <span>Pesquisar canal</span>
            <input id="portfolio-channel-search" type="search" autocomplete="off" placeholder="Nome ou identificador"/>
          </label>
          <p class="portfolio-selection-count" id="portfolio-selection-count">0 de 10 canais selecionados</p>
          <div class="portfolio-choice-list" id="portfolio-channel-list" role="group" aria-label="Canais disponíveis"></div>
          <button class="button button-primary portfolio-apply" type="submit">Calcular cenário</button>
        </form>
      </aside>

      <section class="portfolio-simulator-result" id="resultado-cenario">
        <div class="portfolio-simulator-error" id="portfolio-simulator-error" role="alert" hidden></div>
        <div id="mif-portfolio-simulation" aria-live="polite"></div>
      </section>
    </main>

    <footer class="report-footer">
      Cenário descritivo baseado em agregados anônimos de 2026 · uso interno
    </footer>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifPortfolioSimulatorPayloadJson#</cfoutput></script>
  <script src="../assets/report.js?v=20260903-6"></script>
  <script src="../assets/portfolio.js?v=20260903-7"></script>
  <script>
    (function configureMifPortfolioSimulator() {
      'use strict';
      var data = JSON.parse(document.getElementById('mif-report-data').textContent);
      var form = document.getElementById('portfolio-simulator-form');
      var search = document.getElementById('portfolio-channel-search');
      var list = document.getElementById('portfolio-channel-list');
      var counter = document.getElementById('portfolio-selection-count');
      var error = document.getElementById('portfolio-simulator-error');
      var result = document.getElementById('mif-portfolio-simulation');
      var params = new URLSearchParams(window.location.search);
      var requested = params.getAll('canal');
      var maximum = Number(data.thresholds && data.thresholds.maximum_selected_channels) || 10;
      var channels = (data.selectable_channels || []).slice().sort(function grossDescending(left, right) {
        var grossDifference = Number(right.gross_value) - Number(left.gross_value);
        return grossDifference || String(left.channel_name).localeCompare(String(right.channel_name), 'pt-BR', { sensitivity: 'base' });
      });
      var knownSlugs = new Set(channels.map(function slug(channel) { return String(channel.slug); }));

      function normalizeSearch(value) {
        return String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('pt-BR');
      }

      function channelInputs() {
        return Array.from(list.querySelectorAll('input[name="canal"]'));
      }

      function selectedSlugs() {
        return channelInputs().filter(function selected(input) { return input.checked; }).map(function value(input) { return input.value; });
      }

      function updateSelectionState() {
        var selected = selectedSlugs();
        counter.textContent = selected.length + ' de ' + maximum + ' canais selecionados';
        channelInputs().forEach(function enforceMaximum(input) {
          input.disabled = selected.length >= maximum && !input.checked;
        });
      }

      function showError(problem) {
        error.textContent = problem && problem.message ? problem.message : String(problem || 'Não foi possível calcular o cenário.');
        error.hidden = false;
        result.replaceChildren();
      }

      function renderSelection(selection, replaceUrl) {
        try {
          var scenario = MifPortfolio.simulate(data, selection);
          MifPortfolio.renderSimulation(result, scenario);
          error.hidden = true;
          error.textContent = '';
          if (replaceUrl) {
            window.history.replaceState(null, '', MifPortfolio.buildShareUrl(window.location.href, selection));
          }
        } catch (problem) {
          showError(problem);
        }
      }

      channels.forEach(function renderChannelChoice(channel) {
        var label = document.createElement('label');
        var input = document.createElement('input');
        var copy = document.createElement('span');
        var name = document.createElement('strong');
        var gross = document.createElement('small');
        label.className = 'portfolio-choice';
        label.dataset.search = normalizeSearch(channel.channel_name + ' ' + channel.slug);
        input.type = 'checkbox';
        input.name = 'canal';
        input.value = String(channel.slug);
        input.checked = requested.includes(input.value);
        input.addEventListener('change', updateSelectionState);
        name.textContent = MifReport.formatChannelName(channel.channel_name);
        gross.textContent = MifReport.formatCurrency(channel.gross_value) + ' em valor bruto';
        copy.appendChild(name);
        copy.appendChild(gross);
        label.appendChild(input);
        label.appendChild(copy);
        list.appendChild(label);
      });

      search.addEventListener('input', function filterChoices() {
        var query = normalizeSearch(search.value);
        Array.from(list.children).forEach(function toggleChoice(choice) {
          choice.hidden = Boolean(query) && !choice.dataset.search.includes(query);
        });
      });

      form.addEventListener('submit', function calculateScenario(event) {
        event.preventDefault();
        renderSelection(selectedSlugs(), true);
      });

      updateSelectionState();
      var unknown = requested.find(function unknownSlug(slug) { return !knownSlugs.has(slug); });
      if (unknown) {
        showError(new Error('Canal desconhecido: ' + unknown));
      } else if (requested.length) {
        renderSelection(requested, true);
      }
    })();
  </script>
</body>
</html>
