(function attachMifPortfolio(globalScope) {
  'use strict';

  const REPORT = globalScope?.MifReport || (typeof require === 'function' ? require('./report.js') : null);
  const ALL_CHANNELS = 'Todos os canais';
  const COMMERCIAL_CHANNELS = 'Canais comerciais não orgânicos';
  const EXPOSURE_ORDER = Object.freeze({
    alta: 0,
    média: 1,
    'dependência entre parceiros': 2,
    baixa: 3,
    '': 4,
  });

  function toNumber(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  function compareText(left, right) {
    return String(left ?? '').localeCompare(String(right ?? ''), 'pt-BR', {
      numeric: true,
      sensitivity: 'base',
    });
  }

  function stableRows(rows, keys) {
    return [...rows].sort((left, right) => {
      for (const key of keys) {
        const result = typeof key === 'function' ? key(left, right) : compareText(left[key], right[key]);
        if (result) return result;
      }
      return 0;
    });
  }

  function threshold(data, key) {
    const value = Number(data?.thresholds?.[key]);
    if (!Number.isFinite(value)) throw new Error(`Limite ausente ou inválido: ${key}`);
    return value;
  }

  function classifyExposure(selected, eventTotal, commercialTotal, thresholds) {
    const publishableMinimum = threshold(thresholds, 'publishable_cell_minimum_registrations');
    const classificationMinimum = threshold(thresholds, 'exposure_classification_minimum_registrations');
    const highEventShare = threshold(thresholds, 'exposure_high_event_share_pct');
    const mediumEventShare = threshold(thresholds, 'exposure_medium_event_share_pct');
    const partnerConcentration = threshold(thresholds, 'exposure_partner_concentration_pct');
    if (selected < publishableMinimum || eventTotal <= 0) return null;
    const eventShare = selected / eventTotal * 100;
    const commercialShare = commercialTotal ? selected / commercialTotal * 100 : 0;
    if (selected >= classificationMinimum && eventShare >= highEventShare) return 'alta';
    if (selected >= classificationMinimum && eventShare >= mediumEventShare) return 'média';
    if (commercialShare >= partnerConcentration && eventShare < mediumEventShare) return 'dependência entre parceiros';
    return 'baixa';
  }

  function selectedChannels(data, selection) {
    const choices = Array.isArray(selection) ? selection.map(String) : [];
    const maximum = toNumber(data?.thresholds?.maximum_selected_channels) || 10;
    if (!choices.length) throw new Error('Selecione de 1 a 10 canais conhecidos.');
    if (choices.length > maximum) throw new Error(`Selecione até ${maximum} canais.`);
    const selectable = new Map((data?.selectable_channels || []).map((channel) => [String(channel.slug), channel]));
    const unique = [...new Set(choices)];
    const unknown = unique.find((slug) => !selectable.has(slug));
    if (unknown) throw new Error(`Canal desconhecido: ${unknown}`);
    return unique.map((slug) => selectable.get(slug));
  }

  function aggregateDimension(rows, key) {
    const totals = new Map();
    for (const row of rows) totals.set(row[key], (totals.get(row[key]) || 0) + row.selected_paid_registrations);
    return stableRows([...totals].map(([label, paid_registrations]) => ({ label, paid_registrations })), [
      (left, right) => right.paid_registrations - left.paid_registrations,
      (left, right) => compareText(left.label, right.label),
    ]);
  }

  function simulate(data, selection) {
    const channels = selectedChannels(data, selection);
    const selectedNames = new Set(channels.map((channel) => String(channel.channel_name)));
    const commercialNames = new Set((data?.selectable_channels || []).map((channel) => String(channel.channel_name)));
    const cells = new Map();
    let eventPaidRegistrations = 0;
    let commercialPaidRegistrations = 0;
    const ensureCell = (row) => {
      const phase = String(row.phase ?? 'Não informado');
      const modality = String(row.modality ?? 'Não informado');
      const state = String(row.state ?? 'Não informado');
      const key = `${phase}\u0000${modality}\u0000${state}`;
      if (!cells.has(key)) cells.set(key, {
        phase,
        modality,
        state,
        selected_paid_registrations: 0,
        event_paid_registrations: 0,
        commercial_paid_registrations: 0,
        channel_totals: new Map(),
      });
      return cells.get(key);
    };

    for (const row of data?.coverage_cube || []) {
      const cell = ensureCell(row);
      const registrations = toNumber(row.paid_registrations);
      const channelName = String(row.channel_name ?? '');
      if (channelName === ALL_CHANNELS) {
        cell.event_paid_registrations += registrations;
        eventPaidRegistrations += registrations;
      } else if (channelName === COMMERCIAL_CHANNELS) {
        cell.commercial_paid_registrations += registrations;
        commercialPaidRegistrations += registrations;
      }
      else if (commercialNames.has(channelName)) {
        cell.channel_totals.set(channelName, (cell.channel_totals.get(channelName) || 0) + registrations);
        if (selectedNames.has(channelName)) cell.selected_paid_registrations += registrations;
      }
    }

    const publishableMinimum = threshold(data, 'publishable_cell_minimum_registrations');
    const completeCells = [...cells.values()].map((cell) => {
      const alternatives = stableRows(
        [...cell.channel_totals]
          .filter(([channelName]) => !selectedNames.has(channelName))
          .map(([channel_name, paid_registrations]) => ({ channel_name, paid_registrations })),
        [
          (left, right) => right.paid_registrations - left.paid_registrations,
          (left, right) => compareText(left.channel_name, right.channel_name),
        ],
      );
      const alternative = alternatives[0] || null;
      const exposure = classifyExposure(
        cell.selected_paid_registrations,
        cell.event_paid_registrations,
        cell.commercial_paid_registrations,
        data,
      );
      return {
        phase: cell.phase,
        modality: cell.modality,
        state: cell.state,
        selected_paid_registrations: cell.selected_paid_registrations,
        event_paid_registrations: cell.event_paid_registrations,
        commercial_paid_registrations: cell.commercial_paid_registrations,
        event_share_pct: cell.event_paid_registrations ? cell.selected_paid_registrations / cell.event_paid_registrations * 100 : 0,
        commercial_share_pct: cell.commercial_paid_registrations ? cell.selected_paid_registrations / cell.commercial_paid_registrations * 100 : 0,
        exposure,
        remaining_alternative: alternative?.channel_name || null,
        remaining_alternative_paid_registrations: alternative?.paid_registrations || 0,
      };
    }).filter((cell) => cell.selected_paid_registrations > 0);
    const publishable = stableRows(
      completeCells.filter((cell) => cell.selected_paid_registrations >= publishableMinimum),
      [
        (left, right) => (EXPOSURE_ORDER[left.exposure || ''] ?? 4) - (EXPOSURE_ORDER[right.exposure || ''] ?? 4),
        (left, right) => right.selected_paid_registrations - left.selected_paid_registrations,
        'phase',
        'modality',
        'state',
      ],
    );
    const suppressed = completeCells.filter((cell) => cell.selected_paid_registrations < publishableMinimum);
    const selectedPaidRegistrations = completeCells.reduce((total, cell) => total + cell.selected_paid_registrations, 0);
    return {
      selected_channels: channels.map((channel) => ({ slug: String(channel.slug), channel_name: String(channel.channel_name) })),
      totals: {
        selected_paid_registrations: selectedPaidRegistrations,
        event_paid_registrations: eventPaidRegistrations,
        commercial_paid_registrations: commercialPaidRegistrations,
        suppressed_selected_registrations: suppressed.reduce((total, cell) => total + cell.selected_paid_registrations, 0),
      },
      cells: publishable,
      states: aggregateDimension(completeCells, 'state'),
      modalities: aggregateDimension(completeCells, 'modality'),
      phases: aggregateDimension(completeCells, 'phase'),
    };
  }

  const SUMMARY_SECTIONS = [
    'portfolio-resumo',
    'portfolio-diferenciacao',
    'portfolio-redundancia',
    'portfolio-dependencias',
    'portfolio-simulador',
    'portfolio-metodo',
  ];
  const DIMENSION_LABELS = Object.freeze({
    geography: 'Geografia',
    modality: 'Modalidade',
    temporal: 'Temporalidade',
    lot: 'Lote',
    product: 'Produto',
  });

  function requireReport() {
    if (!REPORT) throw new Error('MifReport é necessário para renderizar o portfólio.');
    return REPORT;
  }

  function section(id, kicker, title, lead, content) {
    const report = requireReport();
    return `<section class="report-section print-section" id="${report.escapeHtml(id)}">
      <header class="section-heading"><span>${report.escapeHtml(kicker)}</span><h2>${report.escapeHtml(title)}</h2><p>${report.escapeHtml(lead)}</p></header>
      ${content}
    </section>`;
  }

  function metricCard(label, value, note = '') {
    const report = requireReport();
    return `<article class="metric-card"><span>${report.escapeHtml(label)}</span><strong>${report.escapeHtml(value)}</strong>${note ? `<small>${report.escapeHtml(note)}</small>` : ''}</article>`;
  }

  function pairLabel(row) {
    const report = requireReport();
    return `${report.formatChannelName(row.left_channel)} × ${report.formatChannelName(row.right_channel)}`;
  }

  function dimensionPanel(dimension, panel) {
    const report = requireReport();
    const benchmark = panel?.benchmark || {};
    const nearestPeers = Array.isArray(panel?.top_channels)
      ? panel.top_channels
      : Object.entries(panel?.nearest_peers || {}).map(([channel_name, peer]) => ({
      channel_name,
      status: peer?.status || 'evidência insuficiente',
      nearest_channel: peer?.nearest_channel || '—',
      similarity_0_1: peer?.similarity_0_1,
      }));
    const quadrantRows = panel?.quadrants || [];
    return `<article class="editorial-block portfolio-dimension" data-portfolio-dimension="${report.escapeHtml(dimension)}">
      <header><h3>${report.escapeHtml(DIMENSION_LABELS[dimension] || dimension)}</h3><p>${report.escapeHtml(`Pares válidos: ${report.formatInteger(benchmark.eligible_pairs)} · p25 do vizinho: ${report.formatPercent(toNumber(benchmark.nearest_peer_p25_similarity_0_1) * 100)} · p90: ${report.formatPercent(toNumber(benchmark.p90_similarity_0_1) * 100)}.`)}</p></header>
      ${report.renderMatrixChart({
        title: `Quadrantes de escala e diferenciação · ${DIMENSION_LABELS[dimension] || dimension}`,
        description: 'Contagem de canais qualificados em cada grupo; a classificação permanece específica desta dimensão.',
        rows: quadrantRows,
        rowKey: 'scale',
        columnKey: 'differentiation',
        valueKey: 'channels',
        rowOrder: ['Escala alta', 'Escala menor'],
        columnOrder: ['Mais diferenciado relativamente', 'Semelhante aos pares'],
        rowLabel: 'Escala',
        denominator: quadrantRows.reduce((total, row) => total + toNumber(row.channels), 0),
        source: 'Quadrantes por escala observada e semelhança do vizinho mais próximo, sem combinar dimensões.',
      })}
      ${report.renderTable({
        columns: [
          { key: 'channel_name', label: 'Canal', format: report.formatChannelName },
          { key: 'gross_value', label: 'Valor bruto', format: report.formatCurrency },
          { key: 'nearest_channel', label: 'Par mais próximo', format: report.formatChannelName },
          { key: 'similarity_0_1', label: 'Semelhança', format: (value) => value == null ? '—' : report.formatPercent(toNumber(value) * 100) },
          { key: 'status', label: 'Qualificação' },
        ],
        rows: stableRows(nearestPeers, [(left, right) => compareText(left.channel_name, right.channel_name)]),
      })}
    </article>`;
  }

  function renderSummary(root, summary) {
    const report = requireReport();
    const overview = summary?.overview || {};
    const redundancy = (summary?.redundancy_candidates || []).map((row) => ({
      ...row,
      pair: pairLabel(row),
      qualifying_dimensions: (row.qualifying_dimensions || []).join(', '),
      similarity_geography: row.similarities?.geography,
      similarity_modality: row.similarities?.modality,
      similarity_temporal: row.similarities?.temporal,
      similarity_lot: row.similarities?.lot,
      similarity_product: row.similarities?.product,
    }));
    const dependencies = (summary?.dependency_cells || []).map((row) => ({
      ...row,
      label: `${report.formatPhase(row.phase)} · ${row.modality} · ${row.state}`,
      value: toNumber(row.paid_registrations),
    }));
    const takeaways = (summary?.executive_takeaways || []).map((row) => `<article class="takeaway-card"><h3>${report.escapeHtml(row.title)}</h3><p><strong>Evidência:</strong> ${report.escapeHtml(row.evidence)}</p></article>`).join('');
    const panels = Object.keys(DIMENSION_LABELS).map((dimension) => dimensionPanel(dimension, summary?.dimension_panels?.[dimension])).join('');
    const redundancyTop = redundancy.slice(0, 10);
    const dependencyTop = dependencies.slice(0, 10);

    root.innerHTML = [
      section(SUMMARY_SECTIONS[0], 'Portfólio · 1', 'Resumo do portfólio', 'Escala, diferenciação e concentração são leituras separadas.', `<div class="metric-grid">${metricCard('Inscrições pagas', report.formatInteger(overview.paid_registrations))}${metricCard('Valor bruto', report.formatCurrency(overview.gross_value))}${metricCard('Pares de redundância', report.formatInteger(redundancy.length))}${metricCard('Células de dependência', report.formatInteger(dependencies.length))}</div><div class="method-note"><p>${report.escapeHtml(summary?.definitions?.commercial_universe || 'Universo comercial não informado.')}</p></div><div class="takeaway-grid">${takeaways}</div>`),
      section(SUMMARY_SECTIONS[1], 'Portfólio · 2', 'Diferenciação por dimensão', 'Cada dimensão mantém seu próprio benchmark e par de referência.', `<div class="portfolio-dimension-grid">${panels}</div>`),
      section(SUMMARY_SECTIONS[2], 'Portfólio · 3', 'Redundância observada', 'Pares semelhantes em dimensões qualificadas merecem leitura conjunta, sem score mestre.', `${report.renderTable({ columns: [
        { key: 'pair', label: 'Par', format: report.formatChannelName },
        { key: 'similarity_geography', label: 'Geografia', format: (value) => value == null ? '—' : report.formatPercent(toNumber(value) * 100) },
        { key: 'similarity_modality', label: 'Modalidade', format: (value) => value == null ? '—' : report.formatPercent(toNumber(value) * 100) },
        { key: 'similarity_temporal', label: 'Temporalidade', format: (value) => value == null ? '—' : report.formatPercent(toNumber(value) * 100) },
        { key: 'similarity_lot', label: 'Lote', format: (value) => value == null ? '—' : report.formatPercent(toNumber(value) * 100) },
        { key: 'similarity_product', label: 'Produto', format: (value) => value == null ? '—' : report.formatPercent(toNumber(value) * 100) },
        { key: 'qualifying_dimensions', label: 'Dimensões qualificadas' },
        { key: 'combined_gross_value', label: 'Valor bruto combinado', format: report.formatCurrency },
      ], rows: redundancyTop })}`),
      section(SUMMARY_SECTIONS[3], 'Portfólio · 4', 'Dependências observadas', 'As células preservam fase, distância e estado; concentração não é previsão de substituição.', `${report.renderBarChart({ title: 'Top 10 células de concentração observada', description: 'Inscrições selecionadas por célula publicada.', rows: dependencies, labelKey: 'label', valueKey: 'value', denominator: overview.paid_registrations, source: 'Células phase × modality × state; exposição usa total do evento e total comercial.' })}${report.renderTable({ columns: [{ key: 'label', label: 'Célula' }, { key: 'channel_name', label: 'Canal', format: report.formatChannelName }, { key: 'paid_registrations', label: 'Inscrições', format: report.formatInteger }, { key: 'exposure', label: 'Cobertura em risco' }], rows: dependencyTop })}`),
      section(SUMMARY_SECTIONS[4], 'Portfólio · 5', 'Simulador descritivo', 'Selecione de 1 a 10 canais comerciais não orgânicos para observar concentração por célula.', '<p>O simulador mantém os agregados selecionados, suprime detalhes abaixo de cinco inscrições e apresenta a maior alternativa comercial observada quando ela existe.</p>'),
      section(SUMMARY_SECTIONS[5], 'Portfólio · 6', 'Método e limites', 'A evidência preserva os grãos e os denominadores do artefato congelado.', '<div class="method-note"><p>Semelhanças, concentrações e alternativas observadas são descritivas e não estabelecem causalidade.</p></div>'),
    ].join('');
  }

  function renderSimulation(root, scenario) {
    const report = requireReport();
    const totals = scenario?.totals || {};
    const selected = toNumber(totals.selected_paid_registrations);
    const eventTotal = toNumber(totals.event_paid_registrations);
    const selectedChannels = scenario?.selected_channels || [];
    const cells = scenario?.cells || [];
    const phaseRows = (scenario?.phases || []).map((row) => ({ ...row, label: report.formatPhase(row.label) }));
    root.innerHTML = `<div class="scenario-receipt"><p><strong>Canais selecionados:</strong> ${report.escapeHtml(selectedChannels.map((channel) => report.formatChannelName(channel.channel_name)).join(', ') || '—')}</p></div>
      <div class="metric-grid">${metricCard('Canais selecionados', report.formatInteger(selectedChannels.length))}${metricCard('Inscrições selecionadas', report.formatInteger(selected))}${metricCard('Cobertura no evento', report.formatPercent(eventTotal ? selected / eventTotal * 100 : 0))}${metricCard('Detalhes suprimidos', report.formatInteger(totals.suppressed_selected_registrations), 'menos de 5 inscrições na célula')}</div>
      ${report.renderBarChart({ title: 'Top 10 estados', description: 'Inscrições selecionadas por estado; Outros permanece no final.', rows: scenario?.states || [], labelKey: 'label', valueKey: 'paid_registrations', denominator: selected, source: 'Agregação das células selecionadas, incluindo detalhes suprimidos.' })}
      ${report.renderBarChart({ title: 'Distâncias selecionadas', description: 'Mix observado por modalidade.', rows: scenario?.modalities || [], labelKey: 'label', valueKey: 'paid_registrations', denominator: selected, source: 'Agregação das células selecionadas.' })}
      ${report.renderBarChart({ title: 'Fases selecionadas', description: 'Mix observado por fase comercial.', rows: phaseRows, labelKey: 'label', valueKey: 'paid_registrations', labelFormatter: report.formatPhase, preserveOrder: false, denominator: selected, source: 'Agregação das células selecionadas.' })}
      <div class="editorial-block"><header><h3>Células publicáveis</h3><p>Detalhes com cinco ou mais inscrições selecionadas; os totais acima preservam todas as células.</p></header>${report.renderTable({ columns: [
        { key: 'phase', label: 'Fase', format: report.formatPhase },
        { key: 'modality', label: 'Distância' },
        { key: 'state', label: 'Estado' },
        { key: 'selected_paid_registrations', label: 'Inscrições selecionadas', format: report.formatInteger },
        { key: 'event_share_pct', label: 'Cobertura em risco', format: report.formatPercent },
        { key: 'commercial_share_pct', label: 'Concentração observada', format: report.formatPercent },
        { key: 'remaining_alternative', label: 'Alternativa observada', format: (value) => value ? report.formatChannelName(value) : '—' },
        { key: 'exposure', label: 'Classificação' },
      ], rows: cells })}</div>`;
  }

  function buildShareUrl(baseUrl, selection) {
    const url = new URL(baseUrl);
    const channels = [...new Set((selection || []).map(String).filter(Boolean))]
      .sort((left, right) => compareText(left, right));
    url.search = '';
    for (const slug of channels) url.searchParams.append('canal', slug);
    return url.toString();
  }

  const api = { SUMMARY_SECTIONS, renderSummary, simulate, renderSimulation, buildShareUrl };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (globalScope) globalScope.MifPortfolio = api;
})(typeof window !== 'undefined' ? window : globalThis);
