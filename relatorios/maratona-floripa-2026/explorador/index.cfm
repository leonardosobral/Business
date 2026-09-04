<cfinclude template="../includes/auth.cfm"/>
<cfinclude template="../includes/data.cfm"/>

<cfset VARIABLES.mifExplorerPayload = mifReadDataset("explorer.json")/>
<cfset VARIABLES.mifExplorerPayloadJson = serializeJson(VARIABLES.mifExplorerPayload)/>
<cfset VARIABLES.mifExplorerPayloadJson = replace(VARIABLES.mifExplorerPayloadJson, "</", "<\/", "all")/>

<cfheader name="Cache-Control" value="private, no-store, max-age=0"/>
<cfcontent type="text/html; charset=utf-8"/>
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <meta name="robots" content="noindex,nofollow,noarchive"/>
  <title>Explorador de vendas — Maratona de Floripa 2026</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
  <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,600;0,700;0,800;0,900;1,700;1,800&amp;family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
  <link rel="stylesheet" href="../assets/report.css?v=20260903-9"/>
  <link rel="stylesheet" href="../assets/explorer.css?v=20260902-2"/>
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
        <a class="button" href="/relatorios/maratona-floripa-2026/canais/">Canais</a>
        <a class="button" href="/relatorios/maratona-floripa-2026/portfolio/simulador.cfm">Simulador</a>
        <a class="button button-current" aria-current="page" href="/relatorios/maratona-floripa-2026/explorador/">Explorador</a>
        <button class="button button-pdf" type="button" onclick="window.print()">Gerar PDF</button>
      </nav>
    </header>
    <section class="report-hero">
      <span class="eyebrow">Cruzamentos adicionais</span>
      <h1>Explorador de vendas</h1>
      <p>Escolha uma dimensão principal e, se necessário, uma comparação. O Grão e a Cobertura ficam visíveis; combinações incompatíveis são bloqueadas.</p>
    </section>

    <main class="report-content explorer-layout">
      <aside class="explorer-panel no-print">
        <h2>Configurar visão</h2>
        <p>Máximo de duas dimensões. Categorias exclusivas usam Top 10 + Outros; produtos vendidos sem itens de kit usam Top 10 sem somar Outros. A tabela mantém todas as linhas.</p>
        <form id="explorer-form">
          <div class="explorer-field">
            <label for="explorer-metric">Métrica</label>
            <select id="explorer-metric" name="metrica"></select>
          </div>
          <div class="explorer-field">
            <label for="explorer-primary">Dimensão principal</label>
            <select id="explorer-primary" name="dimensao"></select>
          </div>
          <div class="explorer-field">
            <label for="explorer-comparison">Comparar com</label>
            <select id="explorer-comparison" name="comparacao"></select>
          </div>
          <h3>Filtros</h3>
          <div class="explorer-filter-grid">
            <div class="explorer-field"><label for="filter-phase">Fase</label><select id="filter-phase" data-filter="phase"><option value="">Todas</option></select></div>
            <div class="explorer-field"><label for="filter-modality">Distância</label><select id="filter-modality" data-filter="modality"><option value="">Todas</option></select></div>
            <div class="explorer-field"><label for="filter-lot">Lote</label><select id="filter-lot" data-filter="lot"><option value="">Todos</option></select></div>
            <div class="explorer-field"><label for="filter-state">Estado</label><select id="filter-state" data-filter="state"><option value="">Todos</option></select></div>
            <div class="explorer-field"><label for="filter-channel">Canal</label><select id="filter-channel" data-filter="channel_name"><option value="">Todos</option></select></div>
            <div class="explorer-field"><label for="filter-product">Produto</label><select id="filter-product" data-filter="product_name"><option value="">Todos</option></select></div>
          </div>
          <div class="explorer-actions">
            <button class="button button-primary" type="submit">Aplicar cruzamento</button>
            <button class="button" type="button" id="explorer-reset">Limpar filtros</button>
            <a class="button" id="explorer-share" href="">Link compartilhável</a>
          </div>
        </form>
      </aside>

      <section class="explorer-result">
        <div class="explorer-guide"><strong>Leitura de referência</strong><p>Use os capítulos fixos da análise geral para decisões executivas. Esta área serve para testar hipóteses adicionais sem misturar grãos.</p></div>
        <div class="explorer-error" id="explorer-error" role="alert" hidden></div>
        <div id="explorer-result" aria-live="polite"></div>
      </section>
    </main>
  </div>

  <script type="application/json" id="mif-report-data"><cfoutput>#VARIABLES.mifExplorerPayloadJson#</cfoutput></script>
  <script src="../assets/report.js?v=20260903-9"></script>
  <script src="../assets/explorer.js?v=20260902-4"></script>
  <script>
    (function configureMifExplorer() {
      'use strict';
      var data = JSON.parse(document.getElementById('mif-report-data').textContent);
      var form = document.getElementById('explorer-form');
      var metric = document.getElementById('explorer-metric');
      var primary = document.getElementById('explorer-primary');
      var comparison = document.getElementById('explorer-comparison');
      var error = document.getElementById('explorer-error');
      var resultRoot = document.getElementById('explorer-result');
      var share = document.getElementById('explorer-share');
      var params = new URLSearchParams(window.location.search);
      var dimensionLabels = {
        week_start: 'Semana', phase: 'Fase', modality: 'Distância', lot: 'Lote', state: 'Estado', city: 'Cidade',
        channel_name: 'Canal', classification: 'Classificação de produto', product_name: 'Produto'
      };

      function option(value, label) {
        var element = document.createElement('option');
        element.value = value;
        element.textContent = label;
        return element;
      }

      Object.entries(MifExplorer.METRIC_CONTRACTS).forEach(function addMetric(entry) {
        metric.appendChild(option(entry[0], entry[1].label));
      });
      metric.value = MifExplorer.METRIC_CONTRACTS[params.get('metrica')] ? params.get('metrica') : 'paid_registrations';

      function activeContract() { return MifExplorer.METRIC_CONTRACTS[metric.value]; }
      function activeRows() { return activeContract().cube === 'products' ? data.product_cube : data.registration_cube; }
      function activeDimensions() { return data.dimensions[activeContract().cube]; }

      function rebuildDimensions(requestedPrimary, requestedComparison) {
        var dimensions = activeDimensions();
        primary.replaceChildren();
        comparison.replaceChildren(option('', 'Sem comparação'));
        dimensions.forEach(function addDimension(dimension) {
          primary.appendChild(option(dimension, dimensionLabels[dimension] || dimension));
          comparison.appendChild(option(dimension, dimensionLabels[dimension] || dimension));
        });
        primary.value = dimensions.includes(requestedPrimary) ? requestedPrimary : (dimensions.includes('phase') ? 'phase' : dimensions[0]);
        comparison.value = dimensions.includes(requestedComparison) && requestedComparison !== primary.value ? requestedComparison : '';
      }

      function rebuildFilters(initial) {
        var dimensions = activeDimensions();
        var rows = activeRows();
        document.querySelectorAll('[data-filter]').forEach(function populateFilter(select) {
          var field = select.dataset.filter;
          var requested = initial ? params.get('filtro_' + field) : select.value;
          select.replaceChildren(option('', field === 'phase' || field === 'modality' ? 'Todas' : 'Todos'));
          select.disabled = !dimensions.includes(field);
          if (!select.disabled) {
            var values = [...new Set(rows.map(function value(row) { return String(row[field] == null ? 'Não informado' : row[field]); }))]
              .filter(function visibleValue(value) { return field !== 'lot' || MifReport.isVisibleLot(value); })
              .sort(function sort(left, right) { return left.localeCompare(right, 'pt-BR', { numeric: true }); });
            values.forEach(function addValue(value) {
              var label = field === 'lot' ? MifReport.formatLot(value) : (field === 'phase' ? MifReport.formatPhase(value) : (field === 'channel_name' ? MifReport.formatChannelName(value) : value));
              select.appendChild(option(value, label));
            });
            if (values.includes(requested)) select.value = requested;
          }
        });
      }

      function filters() {
        var selected = {};
        document.querySelectorAll('[data-filter]').forEach(function collect(select) {
          if (!select.disabled && select.value) selected[select.dataset.filter] = select.value;
        });
        return selected;
      }

      function selection() {
        return { metric: metric.value, primaryDimension: primary.value, comparisonDimension: comparison.value };
      }

      function render() {
        try {
          MifExplorer.validateSelection(selection(), data);
          MifExplorer.render(resultRoot, data, selection(), filters());
          error.hidden = true;
          var shared = MifExplorer.buildShareUrl(window.location.href, selection(), filters());
          share.href = shared;
          window.history.replaceState(null, '', shared);
        } catch (problem) {
          error.textContent = problem.message || 'Não foi possível montar este cruzamento.';
          error.hidden = false;
          resultRoot.replaceChildren();
        }
      }

      metric.addEventListener('change', function changeMetric() {
        rebuildDimensions(primary.value, comparison.value);
        rebuildFilters(false);
      });
      primary.addEventListener('change', function avoidDuplicateDimension() {
        if (comparison.value === primary.value) comparison.value = '';
      });
      form.addEventListener('submit', function apply(event) { event.preventDefault(); render(); });
      document.getElementById('explorer-reset').addEventListener('click', function resetExplorer() {
        form.reset();
        metric.value = 'paid_registrations';
        rebuildDimensions('phase', 'modality');
        rebuildFilters(false);
        render();
      });

      rebuildDimensions(params.get('dimensao') || 'phase', params.get('comparacao') || 'modality');
      rebuildFilters(true);
      render();
    })();
  </script>
</body>
</html>
