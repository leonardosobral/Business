(function initMifStates(globalScope) {
  'use strict';

  function requireReport() {
    if (globalScope && globalScope.MifReport) return globalScope.MifReport;
    if (typeof require === 'function') return require('./report.js');
    throw new Error('MifReport não está disponível.');
  }

  function number(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  function textCompare(left, right) {
    return String(left).localeCompare(String(right), 'pt-BR', { sensitivity: 'base' });
  }

  function channelName(report, value) {
    return report.formatChannelName(value || 'NÃO INFORMADO');
  }

  function section(id, kicker, title, lead, content, options = {}) {
    return `<section class="report-section states-section" id="${id}" data-state-panel="${options.view || ''}"${options.hidden ? ' hidden' : ''}>
      <header class="section-heading"><span>${kicker}</span><h2>${title}</h2><p>${lead}</p></header>
      ${content}
    </section>`;
  }

  function metricCard(label, value, note = '') {
    return requireReport().metricCard(label, value, note);
  }

  function selectState(data, stateCode) {
    const code = String(stateCode || '').trim().toUpperCase();
    const state = (data?.states || []).find((row) => row.state === code);
    if (!state) throw new Error(`Estado desconhecido: ${code || 'não informado'}`);
    const channels = (data?.state_channels || [])
      .filter((row) => row.state === code)
      .sort((left, right) => number(right.paid_registrations) - number(left.paid_registrations)
        || number(right.gross_value) - number(left.gross_value)
        || textCompare(left.channel_name, right.channel_name));
    const modalities = (data?.state_modalities || [])
      .filter((row) => row.state === code)
      .sort((left, right) => number(right.paid_registrations) - number(left.paid_registrations)
        || textCompare(left.modality, right.modality));
    const phases = (data?.state_phases || [])
      .filter((row) => row.state === code)
      .sort((left, right) => number(right.paid_registrations) - number(left.paid_registrations)
        || textCompare(left.phase, right.phase));
    return { state, channels, modalities, phases };
  }

  function pairKey(left, right) {
    return [String(left), String(right)].sort(textCompare).join('\u0000');
  }

  function compareSelection(data, selectedSlugs) {
    const slugs = [...new Set((selectedSlugs || []).map(String).filter(Boolean))];
    if (!slugs.length) throw new Error('Selecione pelo menos um canal.');
    if (slugs.length > 3) throw new Error('Selecione até três canais.');
    const bySlug = new Map((data?.channels || []).map((row) => [row.slug, row]));
    const channels = slugs.map((slug) => {
      const channel = bySlug.get(slug);
      if (!channel) throw new Error(`Canal desconhecido: ${slug}`);
      return channel;
    });
    const pairIndex = new Map((data?.geography_pairs || []).map((row) => [
      pairKey(row.left_channel, row.right_channel),
      row,
    ]));
    const threshold = number(data?.geography_benchmark?.p90_similarity_0_1);
    const pairs = [];
    for (let leftIndex = 0; leftIndex < channels.length; leftIndex += 1) {
      for (let rightIndex = leftIndex + 1; rightIndex < channels.length; rightIndex += 1) {
        const left = channels[leftIndex];
        const right = channels[rightIndex];
        const evidence = pairIndex.get(pairKey(left.channel_name, right.channel_name));
        const similarity = evidence ? number(evidence.similarity_0_1) : null;
        pairs.push({
          left_channel: left.channel_name,
          right_channel: right.channel_name,
          similarity_0_1: similarity,
          p90_similarity_0_1: threshold || null,
          classification: similarity == null || !threshold
            ? 'Evidência insuficiente'
            : similarity >= threshold
              ? 'Sobreposição forte'
              : 'Perfis complementares',
        });
      }
    }
    const stateTotals = new Map();
    for (const channel of channels) {
      for (const row of channel.state_distribution || []) {
        const state = stateTotals.get(row.state) || { state: row.state, paid_registrations: 0, channels: {} };
        state.paid_registrations += number(row.paid_registrations);
        state.channels[channel.channel_name] = number(row.paid_registrations);
        stateTotals.set(row.state, state);
      }
    }
    const states = [...stateTotals.values()].sort((left, right) => (
      right.paid_registrations - left.paid_registrations || textCompare(left.state, right.state)
    ));
    const relevantStates = states.filter((row) => row.paid_registrations >= number(data?.thresholds?.minimum_relevant_state_registrations || 5));
    const totalPaid = channels.reduce((sum, row) => sum + number(row.paid_registrations), 0);
    const totalGross = channels.reduce((sum, row) => sum + number(row.gross_value), 0);
    return {
      channels,
      pairs,
      states,
      total_paid_registrations: totalPaid,
      total_gross_value: totalGross.toFixed(2),
      relevant_state_count: relevantStates.length,
    };
  }

  function renderReachTable(report, data) {
    const rows = (data?.channels || []).filter((row) => number(row.paid_registrations) >= 10);
    return report.renderTable({
      columns: [
        { key: 'channel_name', label: 'Canal', format: (value) => channelName(report, value) },
        { key: 'reach_classification', label: 'Alcance observado' },
        { key: 'paid_registrations', label: 'Inscrições', format: report.formatInteger },
        { key: 'gross_value', label: 'Valor bruto', format: report.formatCurrency },
        { key: 'active_ufs', label: 'UFs relevantes', format: report.formatInteger },
        { key: 'active_regions', label: 'Regiões relevantes', format: report.formatInteger },
        { key: 'leading_state', label: 'Principal UF' },
        { key: 'leading_state_share_valid_pct', label: 'Concentração principal', format: report.formatPercent },
        { key: 'outside_south_share_valid_pct', label: 'Fora do Sul', format: report.formatPercent },
      ],
      rows,
    });
  }

  function renderFeaturedPair(report, data) {
    const pair = data?.featured_pair;
    if (!pair) return '<div class="method-note"><p>O par prioritário não possui evidência suficiente nesta base.</p></div>';
    const channels = Object.fromEntries((data.channels || []).map((row) => [row.channel_name, row]));
    const left = channels[pair.left_channel] || {};
    const right = channels[pair.right_channel] || {};
    const rowByState = new Map((pair.state_comparison || []).map((row) => [row.state, row]));
    const stateRows = [...rowByState.values()].slice(0, 10);
    return `<article class="states-pair-card">
      <header><span>Dupla prioritária sob condição</span><h3>${channelName(report, pair.left_channel)} × ${channelName(report, pair.right_channel)}</h3><strong>${report.escapeHtml(pair.overlap_classification)}</strong></header>
      <div class="metric-grid">
        ${metricCard('Inscrições combinadas', report.formatInteger(pair.combined_paid_registrations))}
        ${metricCard('Valor bruto combinado', report.formatCurrency(pair.combined_gross_value))}
        ${metricCard('Semelhança geográfica', report.formatPercent(number(pair.geography_similarity_0_1) * 100), `p90 = ${report.formatPercent(number(pair.geography_p90_similarity_0_1) * 100)}`)}
        ${metricCard('Mix estadual sobreposto', report.formatPercent(pair.distribution_overlap_pct))}
      </div>
      <div class="states-role-grid">
        <div><span>Âncora nacional</span><h4>${channelName(report, pair.left_channel)}</h4><p>${report.formatInteger(left.paid_registrations)} inscrições; ${report.formatInteger(left.active_ufs)} UFs relevantes. Priorizar capilaridade, escala nacional e a cauda de estados.</p></div>
        <div><span>Prioridade nacional com ênfase estadual</span><h4>${channelName(report, pair.right_channel)}</h4><p>${report.formatInteger(right.paid_registrations)} inscrições; alcance classificado como ${report.escapeHtml(String(right.reach_classification || 'não classificado').toLocaleLowerCase('pt-BR'))}, com maior peso relativo em ${report.escapeHtml((pair.right_distinctive_states || []).join(', ') || 'mercados específicos')}. Usar metas territoriais diferentes do parceiro âncora.</p></div>
      </div>
      <div class="executive-copy"><p><strong>Leitura:</strong> os dois têm alcance nacional observado e podem ser prioritários, mas não para o mesmo briefing. A sobreposição é forte; a manutenção conjunta ganha mérito quando MANIADECORRIDA recebe metas estaduais específicas — sobretudo onde seu mix é relativamente mais forte — e ROADRUNNERS responde pela cobertura nacional ampla.</p></div>
      ${stateRows.length ? report.renderTable({ columns: [
        { key: 'state', label: 'UF' },
        { key: 'left_paid_registrations', label: channelName(report, pair.left_channel), format: report.formatInteger },
        { key: 'right_paid_registrations', label: channelName(report, pair.right_channel), format: report.formatInteger },
        { key: 'left_minus_right_pp', label: 'Diferença de mix', format: report.formatPercent },
      ], rows: stateRows }) : ''}
      <p class="chart-source">${report.escapeHtml(pair.interpretation || data.definitions?.overlap || '')}</p>
    </article>`;
  }

  function renderOverview(data) {
    const report = requireReport();
    const overview = data?.overview || {};
    const stateRows = data?.states || [];
    const topStates = stateRows.slice(0, 10);
    const topChannels = (data?.channels || [])
      .filter((row) => number(row.paid_registrations) >= 10)
      .slice(0, 10);
    const matrixRows = (data?.state_channels || []).filter((row) => (
      topStates.some((state) => state.state === row.state)
      && topChannels.some((channel) => channel.channel_name === row.channel_name)
    ));
    return `${section('states-overview', 'Estados · 1', 'Visão geral territorial', 'Escala estadual, capilaridade dos parceiros e concentração observada.', `
      <div class="metric-grid">
        ${metricCard('Inscrições com UF válida', report.formatInteger(overview.valid_state_registrations), `${report.formatPercent(overview.state_coverage_pct)} da base`)}
        ${metricCard('Canais comerciais', report.formatInteger(overview.commercial_channel_count), 'ticket acima de R$ 10,00')}
        ${metricCard('Canais classificáveis', report.formatInteger(overview.classified_channel_count), 'base e cobertura suficientes')}
        ${metricCard('Alcance nacional', report.formatInteger(overview.national_channel_count), 'pelos critérios publicados')}
      </div>
      ${report.renderBarChart({ title: 'Inscrições por estado', description: 'Top 10 + Outros, em volume decrescente.', rows: stateRows, labelKey: 'state', valueKey: 'paid_registrations', denominator: overview.valid_state_registrations, source: 'UF normalizada nas inscrições pagas; categorias inválidas ou ausentes ficam fora da distribuição estadual.' })}
      <div class="editorial-block"><header><h3>Alcance dos parceiros</h3><p>Ordem por valor bruto; classificações usam volume, cobertura, UFs, regiões e concentração da principal UF.</p></header>${renderReachTable(report, data)}</div>
      ${report.renderMatrixChart({ title: 'Estados × canais', description: 'As dez maiores UFs e os dez canais de maior valor com pelo menos dez inscrições.', rows: matrixRows, rowKey: 'state', columnKey: 'channel_name', columnFormatter: (value) => channelName(report, value), rowOrder: topStates.map((row) => row.state), columnOrder: topChannels.map((row) => row.channel_name), valueKey: 'paid_registrations', shareKey: 'event_state_share_pct', rowLabel: 'UF', denominator: overview.valid_state_registrations, source: 'Células estado × canal com cinco ou mais inscrições; totais estaduais preservam células suprimidas.' })}
    `, { view: 'overview' })}${section('states-featured', 'Estados · 2', 'ROADRUNNERS e MANIADECORRIDA', 'Escala nacional semelhante não significa função contratual idêntica.', renderFeaturedPair(report, data), { view: 'overview' })}`;
  }

  function renderStateDetail(root, selected) {
    const report = requireReport();
    const state = selected.state;
    const channels = selected.channels;
    const modalities = selected.modalities;
    const phases = selected.phases.map((row) => ({ ...row, phase_label: report.formatPhase(row.phase) }));
    root.innerHTML = `<div class="metric-grid">
      ${metricCard('Inscrições', report.formatInteger(state.paid_registrations))}
      ${metricCard('Valor bruto', state.gross_value == null ? 'não disponível' : report.formatCurrency(state.gross_value))}
      ${metricCard('Participação no evento', report.formatPercent(state.event_share_pct))}
      ${metricCard('Peso dos canais comerciais', report.formatPercent(state.commercial_share_of_state_pct))}
    </div>
    ${report.renderBarChart({ title: `Canais em ${state.state}`, description: 'Inscrições pagas por canal em ordem decrescente; Top 10 + Outros.', rows: channels, labelKey: 'channel_name', labelFormatter: (value) => channelName(report, value), valueKey: 'paid_registrations', denominator: state.paid_registrations, source: 'Somente células estado × canal com cinco ou mais inscrições.' })}
    <div class="states-two-column">
      ${report.renderBarChart({ title: 'Distâncias', rows: modalities, labelKey: 'modality', valueKey: 'paid_registrations', denominator: state.paid_registrations, source: 'Todas as inscrições pagas com UF válida.' })}
      ${report.renderBarChart({ title: 'Fases', rows: phases, labelKey: 'phase_label', valueKey: 'paid_registrations', denominator: state.paid_registrations, source: 'Todas as inscrições pagas com UF válida.' })}
    </div>
    ${report.renderTable({ columns: [
      { key: 'channel_name', label: 'Canal', format: (value) => channelName(report, value) },
      { key: 'paid_registrations', label: 'Inscrições', format: report.formatInteger },
      { key: 'gross_value', label: 'Valor bruto', format: (value) => value == null ? 'não disponível' : report.formatCurrency(value) },
      { key: 'event_state_share_pct', label: 'Participação na UF', format: report.formatPercent },
      { key: 'commercial_state_share_pct', label: 'Participação comercial', format: report.formatPercent },
    ], rows: channels })}
    <p class="chart-source">Canais com menos de cinco inscrições na UF permanecem apenas nos totais agregados.</p>`;
    return root;
  }

  function renderStatePanel(data, stateCode) {
    const report = requireReport();
    const states = data?.states || [];
    const selected = selectState(data, stateCode || states[0]?.state);
    const detailRoot = { innerHTML: '' };
    renderStateDetail(detailRoot, selected);
    const options = states.map((row) => `<option value="${report.escapeHtml(row.state)}"${row.state === selected.state.state ? ' selected' : ''}>${report.escapeHtml(row.state)} · ${report.escapeHtml(row.region)} · ${report.formatInteger(row.paid_registrations)}</option>`).join('');
    return section('states-state', 'Estados · 3', 'Estratégia por estado', 'Escolha uma UF para identificar canais líderes, distância e momento de venda.', `
      <div class="states-control no-print"><label for="states-state-select">Estado analisado</label><select id="states-state-select">${options}</select></div>
      <div id="states-state-detail">${detailRoot.innerHTML}</div>
    `, { view: 'state', hidden: true });
  }

  function renderComparison(root, comparison, data) {
    const report = requireReport();
    const channelNames = comparison.channels.map((row) => row.channel_name);
    const matrixRows = comparison.states.flatMap((state) => channelNames.map((name) => ({
      state: state.state,
      channel_name: name,
      paid_registrations: number(state.channels[name]),
      share: state.paid_registrations ? number(state.channels[name]) / state.paid_registrations * 100 : 0,
    })));
    const pairRows = comparison.pairs.map((row) => ({ ...row, pair: `${channelName(report, row.left_channel)} × ${channelName(report, row.right_channel)}`, similarity_pct: row.similarity_0_1 == null ? null : row.similarity_0_1 * 100, p90_pct: row.p90_similarity_0_1 == null ? null : row.p90_similarity_0_1 * 100 }));
    root.innerHTML = `<div class="metric-grid">
      ${metricCard('Parceiros', report.formatInteger(comparison.channels.length))}
      ${metricCard('Inscrições combinadas', report.formatInteger(comparison.total_paid_registrations))}
      ${metricCard('Valor bruto combinado', report.formatCurrency(comparison.total_gross_value))}
      ${metricCard('UFs alcançadas em conjunto', report.formatInteger(comparison.relevant_state_count), 'ao menos cinco inscrições somadas')}
    </div>
    ${comparison.pairs.length ? report.renderTable({ columns: [
      { key: 'pair', label: 'Par' },
      { key: 'similarity_pct', label: 'Semelhança geográfica', format: (value) => value == null ? 'não disponível' : report.formatPercent(value) },
      { key: 'p90_pct', label: 'Limite de forte sobreposição', format: (value) => value == null ? 'não disponível' : report.formatPercent(value) },
      { key: 'classification', label: 'Leitura' },
    ], rows: pairRows }) : ''}
    ${report.renderMatrixChart({ title: 'Distribuição estadual dos parceiros', description: 'Volume por UF e parceiro selecionado.', rows: matrixRows, rowKey: 'state', columnKey: 'channel_name', columnFormatter: (value) => channelName(report, value), rowOrder: comparison.states.map((row) => row.state), columnOrder: channelNames, valueKey: 'paid_registrations', shareKey: 'share', rowLabel: 'UF', denominator: comparison.total_paid_registrations, source: 'Inscrições pagas dos parceiros selecionados; sobreposição descreve distribuição semelhante, não o mesmo pedido.' })}
    <div class="executive-copy"><p>Combinações com sobreposição forte precisam de mandatos territoriais distintos. Perfis complementares ampliam a presença relativa em UFs diferentes, mas não provam vendas incrementais.</p></div>`;
    return root;
  }

  function comparisonSelect(report, channels, position, selectedSlug) {
    const options = [`<option value="">${position === 1 ? 'Selecione um canal' : 'Opcional'}</option>`]
      .concat(channels.map((row) => `<option value="${report.escapeHtml(row.slug)}"${row.slug === selectedSlug ? ' selected' : ''}>${report.escapeHtml(channelName(report, row.channel_name))} · ${report.formatInteger(row.paid_registrations)}</option>`));
    return `<label>Parceiro ${position}<select data-compare-channel="${position}">${options.join('')}</select></label>`;
  }

  function renderComparePanel(data) {
    const report = requireReport();
    const channels = (data?.channels || []).filter((row) => number(row.paid_registrations) >= 10);
    const defaults = ['roadrunners', 'maniadecorrida'];
    const existingDefaults = defaults.filter((slug) => channels.some((row) => row.slug === slug));
    const selection = existingDefaults.length ? existingDefaults : channels.slice(0, 2).map((row) => row.slug);
    let comparisonHtml = '';
    if (selection.length) {
      const resultRoot = { innerHTML: '' };
      renderComparison(resultRoot, compareSelection(data, selection), data);
      comparisonHtml = resultRoot.innerHTML;
    }
    return section('states-compare', 'Estados · 4', 'Comparar parceiros', 'Selecione até três canais para medir capilaridade conjunta e semelhança territorial.', `
      <form class="states-compare-form no-print" id="states-compare-form">
        <div class="states-compare-controls">
          ${comparisonSelect(report, channels, 1, selection[0])}
          ${comparisonSelect(report, channels, 2, selection[1])}
          ${comparisonSelect(report, channels, 3, selection[2])}
        </div>
        <div class="states-control-actions"><button class="button button-primary" type="submit">Comparar</button><a class="button" id="states-share-link" href="">Link compartilhável</a></div>
        <p class="states-error" id="states-compare-error" role="alert" hidden></p>
      </form>
      <div id="states-compare-result">${comparisonHtml}</div>
    `, { view: 'compare', hidden: true });
  }

  function renderMethod(data) {
    const report = requireReport();
    const thresholds = data?.thresholds || {};
    return section('states-method', 'Estados · 5', 'Método e limites', 'A classificação é transparente e descreve apenas este evento.', `<div class="method-note"><p><strong>Nacional:</strong> ao menos ${report.formatInteger(thresholds.national_minimum_relevant_states)} UFs, ${report.formatInteger(thresholds.national_minimum_relevant_regions)} regiões e principal UF até ${report.formatPercent(thresholds.national_maximum_leading_state_share_pct)}.</p><p><strong>Multirregional:</strong> ao menos ${report.formatInteger(thresholds.multiregional_minimum_relevant_states)} UFs, ${report.formatInteger(thresholds.multiregional_minimum_relevant_regions)} regiões e principal UF até ${report.formatPercent(thresholds.multiregional_maximum_leading_state_share_pct)}.</p><p>Classificações exigem ${report.formatInteger(thresholds.minimum_classifiable_registrations)} inscrições e ${report.formatPercent(thresholds.minimum_valid_state_coverage_pct)} de cobertura válida. ${report.escapeHtml(data?.definitions?.overlap || '')}</p></div>`, { view: 'overview' });
  }

  function render(root, data) {
    root.innerHTML = [
      renderOverview(data),
      renderStatePanel(data),
      renderComparePanel(data),
      renderMethod(data),
    ].join('');
    return root;
  }

  function buildShareUrl(baseUrl, view, options = {}) {
    const url = new URL(baseUrl);
    url.search = '';
    url.searchParams.set('visao', String(view || 'overview'));
    if (options.state) url.searchParams.set('estado', String(options.state).toUpperCase());
    const channels = [...new Set((options.channels || []).map(String).filter(Boolean))].sort(textCompare);
    for (const slug of channels) url.searchParams.append('canal', slug);
    return url.toString();
  }

  function parseShareUrl(urlValue, data) {
    const url = new URL(urlValue);
    const requestedView = url.searchParams.get('visao');
    const allowedViews = new Set(['overview', 'state', 'compare']);
    let view = allowedViews.has(requestedView) ? requestedView : 'overview';
    const knownStates = new Set((data?.states || []).map((row) => String(row.state)));
    const requestedState = String(url.searchParams.get('estado') || '').toUpperCase();
    const state = knownStates.has(requestedState) ? requestedState : null;
    const knownChannels = new Set((data?.channels || []).map((row) => String(row.slug)));
    const channels = [...new Set(url.searchParams.getAll('canal').map(String).filter((slug) => knownChannels.has(slug)))].slice(0, 3);
    if ((view === 'state' && !state) || (view === 'compare' && !channels.length)) view = 'overview';
    return { view, state, channels };
  }

  function mount(root, data) {
    render(root, data);
    if (typeof document === 'undefined') return;
    const initial = typeof window !== 'undefined'
      ? parseShareUrl(window.location.href, data)
      : { view: 'overview', state: null, channels: [] };
    const tabs = [...document.querySelectorAll('[data-state-view]')];
    const panels = [...root.querySelectorAll('[data-state-panel]')];
    const showView = (view) => {
      tabs.forEach((tab) => {
        const current = tab.dataset.stateView === view;
        tab.classList.toggle('button-current', current);
        tab.setAttribute('aria-selected', current ? 'true' : 'false');
      });
      panels.forEach((panel) => { panel.hidden = panel.dataset.statePanel !== view; });
    };
    tabs.forEach((tab) => tab.addEventListener('click', () => showView(tab.dataset.stateView)));

    const stateSelect = root.querySelector('#states-state-select');
    const stateDetail = root.querySelector('#states-state-detail');
    if (stateSelect && stateDetail && initial.state) {
      stateSelect.value = initial.state;
      renderStateDetail(stateDetail, selectState(data, initial.state));
    }
    if (stateSelect && stateDetail) stateSelect.addEventListener('change', () => {
      renderStateDetail(stateDetail, selectState(data, stateSelect.value));
    });

    const compareForm = root.querySelector('#states-compare-form');
    const compareRoot = root.querySelector('#states-compare-result');
    const compareError = root.querySelector('#states-compare-error');
    const shareLink = root.querySelector('#states-share-link');
    const compareSelects = [...root.querySelectorAll('[data-compare-channel]')];
    if (initial.channels.length) compareSelects.forEach((select, index) => {
      select.value = initial.channels[index] || '';
    });
    const readSelection = () => [...root.querySelectorAll('[data-compare-channel]')].map((select) => select.value).filter(Boolean);
    const updateShare = () => {
      if (shareLink && typeof window !== 'undefined') shareLink.href = buildShareUrl(window.location.href, 'compare', { channels: readSelection() });
    };
    if (compareForm && compareRoot) compareForm.addEventListener('submit', (event) => {
      event.preventDefault();
      try {
        renderComparison(compareRoot, compareSelection(data, readSelection()), data);
        compareError.hidden = true;
        updateShare();
      } catch (error) {
        compareError.textContent = error.message;
        compareError.hidden = false;
      }
    });
    if (initial.view === 'compare' && initial.channels.length && compareRoot) {
      renderComparison(compareRoot, compareSelection(data, initial.channels), data);
    }
    updateShare();
    showView(initial.view);
  }

  const api = {
    selectState,
    compareSelection,
    renderStateDetail,
    renderComparison,
    render,
    buildShareUrl,
    parseShareUrl,
    mount,
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (globalScope) globalScope.MifStates = api;
})(typeof window !== 'undefined' ? window : globalThis);
