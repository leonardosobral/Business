(function attachMifReport(globalScope) {
  'use strict';

  const GENERAL_CHAPTERS = [
    'resumo-executivo',
    'ciclo-de-vendas',
    'distancias',
    'lotes-e-produtos',
    'territorios',
    'canais',
    'aprofundamento-canais',
    'recomendacoes-e-metodo',
  ];
  const CHANNEL_SECTIONS = [
    'canal-resumo',
    'canal-ciclo',
    'canal-distancias-lotes',
    'canal-territorios',
    'canal-produtos',
    'canal-cupons',
    'canal-recomendacao',
  ];
  const MIN_COMMERCIAL_TICKET = 10;
  const PHASE_DATE_RANGES = Object.freeze([
    { phase: 'Lançamento', label: 'Pré-lançamento', dates: '4–17 jun. 2025' },
    { phase: 'Início', label: 'Início', dates: '18 jun.–24 set. 2025' },
    { phase: 'Meio', label: 'Meio', dates: '25 set. 2025–13 abr. 2026' },
    { phase: 'Reta final', label: 'Reta final', dates: '14 abr.–12 jul. 2026' },
    { phase: 'Encerramento', label: 'Encerramento', dates: '13 jul.–26 ago. 2026' },
  ]);

  const numberFormatter = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });
  const decimalFormatter = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  const currencyFormatter = new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

  function toNumber(value) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  function formatCurrency(value) {
    return currencyFormatter.format(toNumber(value));
  }

  function formatPercent(value) {
    return `${decimalFormatter.format(toNumber(value))}%`;
  }

  function formatInteger(value) {
    return numberFormatter.format(toNumber(value));
  }

  function formatLot(value) {
    const label = String(value ?? '').trim();
    if (!label || /^(não informado|inválido|—)$/iu.test(label)) return label || 'Não informado';
    return /^lote\s+/iu.test(label) ? `Lote ${label.replace(/^lote\s+/iu, '')}` : `Lote ${label}`;
  }

  function formatChannelName(value) {
    return String(value ?? '').toLocaleUpperCase('pt-BR');
  }

  function formatPhase(value) {
    const phase = String(value ?? '');
    return PHASE_DATE_RANGES.find((row) => row.phase === phase)?.label || phase;
  }

  function isVisibleLot(value) {
    return String(value ?? '').trim().toLocaleUpperCase('pt-BR') !== 'OUTRO: 0';
  }

  function isCommercialChannel(row) {
    const registrations = toNumber(row?.paid_registrations);
    const ticket = row?.registration_ticket == null
      ? (registrations ? toNumber(row?.gross_value) / registrations : 0)
      : toNumber(row.registration_ticket);
    return ticket > MIN_COMMERCIAL_TICKET;
  }

  function formatChannelMentions(value, channelNames = []) {
    return [...new Set(channelNames.filter(Boolean).map(String))]
      .sort((left, right) => right.length - left.length)
      .reduce(
        (text, channelName) => text.split(channelName).join(formatChannelName(channelName)),
        String(value ?? ''),
      );
  }

  function formatReportText(value, channelNames = []) {
    return formatChannelMentions(value, channelNames).split('Lançamento').join('Pré-lançamento');
  }

  function renderPhaseLegend() {
    const items = PHASE_DATE_RANGES.map((row) => `<li><strong>${escapeHtml(row.label)}</strong><span>${escapeHtml(row.dates)}</span></li>`).join('');
    return `<div class="phase-legend"><strong>Datas das fases</strong><ul>${items}</ul></div>`;
  }

  function renderNarrative(value) {
    return escapeHtml(value || '')
      .replace(/^##\s*/u, '')
      .replace(/\*\*([^*]+)\*\*/gu, '<strong>$1</strong>')
      .replace(/\s+-\s+(?=<strong>)/gu, '<br>')
      .replaceAll('\n', '<br>');
  }

  function ratioOfTotals(rows, numeratorKey, denominatorKey) {
    const numerator = rows.reduce((total, row) => total + toNumber(row[numeratorKey]), 0);
    const denominator = rows.reduce((total, row) => total + toNumber(row[denominatorKey]), 0);
    return denominator ? numerator / denominator : null;
  }

  function topNWithOthers(rows, labelKey, valueKey, limit = 10) {
    const sorted = [...(rows || [])].sort((left, right) => {
      const valueDifference = toNumber(right[valueKey]) - toNumber(left[valueKey]);
      return valueDifference || String(left[labelKey] ?? '').localeCompare(String(right[labelKey] ?? ''), 'pt-BR');
    });
    if (sorted.length <= limit) return sorted;
    const tail = sorted.slice(limit);
    return [
      ...sorted.slice(0, limit),
      {
        [labelKey]: 'Outros',
        [valueKey]: tail.reduce((total, row) => total + toNumber(row[valueKey]), 0),
        aggregated_rows: tail.length,
      },
    ];
  }

  function sortChannelsByGross(rows) {
    return [...(rows || [])].sort((left, right) => {
      const gross = toNumber(right.gross_value) - toNumber(left.gross_value);
      const registrations = toNumber(right.paid_registrations) - toNumber(left.paid_registrations);
      return gross || registrations || String(left.channel_name ?? '').localeCompare(String(right.channel_name ?? ''), 'pt-BR');
    });
  }

  function rankRowsByTotal(rows, key, valueKey = 'paid_registrations', lastLabel = '') {
    const totals = new Map();
    for (const row of rows || []) {
      const label = String(row[key] ?? 'Não informado');
      totals.set(label, (totals.get(label) || 0) + toNumber(row[valueKey]));
    }
    return [...totals].sort((left, right) => {
      if (lastLabel && left[0] === lastLabel) return 1;
      if (lastLabel && right[0] === lastLabel) return -1;
      return (right[1] - left[1]) || left[0].localeCompare(right[0], 'pt-BR');
    }).map(([label]) => label);
  }

  function buildChannelPortfolio(rows, eventGrossValue) {
    const channels = sortChannelsByGross(rows);
    const eventGross = toNumber(eventGrossValue);
    const categoryOrder = ['Priorizar', 'Manter com função definida', 'Testar/renegociar', 'Reduzir/descontinuar', 'Sem classificação'];
    const grouped = new Map();
    for (const row of channels) {
      const category = row.recommendation?.category || 'Sem classificação';
      const target = grouped.get(category) || { category, channels: 0, paid_registrations: 0, gross_value: 0 };
      target.channels += 1;
      target.paid_registrations += toNumber(row.paid_registrations);
      target.gross_value += toNumber(row.gross_value);
      grouped.set(category, target);
    }
    const share = (size) => eventGross
      ? channels.slice(0, size).reduce((total, row) => total + toNumber(row.gross_value), 0) / eventGross * 100
      : 0;
    const recommendationGroups = [...grouped.values()]
      .sort((left, right) => {
        const leftIndex = categoryOrder.indexOf(left.category);
        const rightIndex = categoryOrder.indexOf(right.category);
        return (leftIndex < 0 ? categoryOrder.length : leftIndex) - (rightIndex < 0 ? categoryOrder.length : rightIndex)
          || left.category.localeCompare(right.category, 'pt-BR');
      })
      .map((row) => ({ ...row, gross_value: row.gross_value.toFixed(2), gross_share_pct: eventGross ? row.gross_value / eventGross * 100 : 0 }));
    return {
      channels: channels.length,
      top_1_gross_share_pct: share(1),
      top_2_gross_share_pct: share(2),
      top_3_gross_share_pct: share(3),
      top_10_gross_share_pct: share(10),
      recommendation_groups: recommendationGroups,
    };
  }

  function naturalOrder(rows, key) {
    return [...(rows || [])].sort((left, right) => String(left[key] ?? '').localeCompare(
      String(right[key] ?? ''),
      'pt-BR',
      { numeric: true, sensitivity: 'base' },
    ));
  }

  function groupSum(rows, key, valueKey = 'paid_registrations') {
    const grouped = new Map();
    for (const row of rows || []) {
      const label = String(row[key] ?? 'Não informado');
      grouped.set(label, (grouped.get(label) || 0) + toNumber(row[valueKey]));
    }
    return [...grouped].map(([label, value]) => ({ label, value }));
  }

  function sourceNote(denominator, source) {
    return `<p class="chart-source"><strong>Denominador:</strong> ${escapeHtml(denominator ?? 'não aplicável')} · <strong>Fonte:</strong> ${escapeHtml(source || 'Agregados anônimos reconciliados do evento 72611.')}</p>`;
  }

  function renderBarChart(config) {
    const labelKey = config.labelKey || 'label';
    const valueKey = config.valueKey || 'value';
    const limit = config.limit || 10;
    const sorted = [...(config.rows || [])].sort((left, right) => {
      const difference = toNumber(right[valueKey]) - toNumber(left[valueKey]);
      return difference || String(left[labelKey] ?? '').localeCompare(String(right[labelKey] ?? ''), 'pt-BR');
    });
    const rows = config.preserveOrder
      ? [...(config.rows || [])]
      : config.aggregateOther === false
        ? sorted.slice(0, limit)
        : topNWithOthers(config.rows || [], labelKey, valueKey, limit);
    const max = Math.max(1, ...rows.map((row) => toNumber(row[valueKey])));
    const rowHeight = 38;
    const width = 920;
    const labelWidth = 245;
    const barWidth = 560;
    const height = Math.max(90, rows.length * rowHeight + 24);
    const valueFormatter = config.valueFormatter || formatInteger;
    const labelFormatter = config.labelFormatter || ((value) => value);
    const bars = rows.map((row, index) => {
      const value = toNumber(row[valueKey]);
      const y = index * rowHeight + 8;
      const visibleWidth = Math.max(value ? 2 : 0, (value / max) * barWidth);
      return `<g class="bar-row">
        <text x="0" y="${y + 17}" class="bar-label">${escapeHtml(labelFormatter(row[labelKey]))}</text>
        <rect x="${labelWidth}" y="${y}" width="${visibleWidth.toFixed(2)}" height="22" rx="4"></rect>
        <text x="${Math.min(labelWidth + visibleWidth + 8, width - 78).toFixed(2)}" y="${y + 17}" class="bar-value">${escapeHtml(valueFormatter(value))}</text>
      </g>`;
    }).join('');
    return `<figure class="chart-card">
      <figcaption><h3>${escapeHtml(config.title)}</h3><p>${escapeHtml(config.description || '')}</p></figcaption>
      <div class="chart-scroll"><svg class="bar-chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="${escapeHtml(config.title)}">${bars}</svg></div>
      ${sourceNote(config.denominator, config.source)}
      ${config.rows && config.rows.length > limit
        ? config.aggregateOther === false
          ? `<p class="chart-rule">Visual: Top ${limit}; os demais itens permanecem na tabela. “Outros” não é somado porque as categorias podem se sobrepor.</p>`
          : `<p class="chart-rule">Visual: Top ${limit} + Outros. A tabela preserva todos os itens.</p>`
        : ''}
    </figure>`;
  }

  function renderMatrixChart(config) {
    const rows = config.rows || [];
    const rowKey = config.rowKey;
    const columnKey = config.columnKey;
    const valueKey = config.valueKey || 'paid_registrations';
    const shareKey = config.shareKey;
    const observedRows = [...new Set(rows.map((row) => String(row[rowKey] ?? 'Não informado')))];
    const observedColumns = [...new Set(rows.map((row) => String(row[columnKey] ?? 'Não informado')))];
    const orderValues = (values, preferred = []) => [...values].sort((left, right) => {
      const leftIndex = preferred.indexOf(left);
      const rightIndex = preferred.indexOf(right);
      if (leftIndex !== -1 || rightIndex !== -1) {
        if (leftIndex === -1) return 1;
        if (rightIndex === -1) return -1;
        return leftIndex - rightIndex;
      }
      return left.localeCompare(right, 'pt-BR', { numeric: true, sensitivity: 'base' });
    });
    const rowLabels = orderValues(observedRows, config.rowOrder || []);
    const columnTotals = new Map();
    for (const row of rows) {
      const label = String(row[columnKey] ?? 'Não informado');
      columnTotals.set(label, (columnTotals.get(label) || 0) + toNumber(row[valueKey]));
    }
    const rankedColumns = [...observedColumns].sort((left, right) => {
      const difference = (columnTotals.get(right) || 0) - (columnTotals.get(left) || 0);
      return difference || left.localeCompare(right, 'pt-BR', { numeric: true, sensitivity: 'base' });
    });
    const limitedColumns = config.columnLimit && rankedColumns.length > config.columnLimit
      ? rankedColumns.slice(0, config.columnLimit)
      : observedColumns;
    const columnLabels = config.columnLimit
      ? limitedColumns
      : orderValues(limitedColumns, config.columnOrder || []);
    const cells = new Map(rows.map((row) => [`${String(row[rowKey])}\u0000${String(row[columnKey])}`, row]));
    const rowFormatter = config.rowFormatter || ((value) => value);
    const columnFormatter = config.columnFormatter || ((value) => value);
    const header = columnLabels.map((label) => `<th scope="col">${escapeHtml(columnFormatter(label))}</th>`).join('');
    const body = rowLabels.map((rowLabel) => {
      const columns = columnLabels.map((columnLabel) => {
        const row = cells.get(`${rowLabel}\u0000${columnLabel}`) || {};
        const value = toNumber(row[valueKey]);
        const share = shareKey ? toNumber(row[shareKey]) : 0;
        const intensity = Math.max(0.06, Math.min(0.6, 0.06 + (share / 100) * 0.54));
        return `<td class="matrix-cell" style="--matrix-intensity:${intensity.toFixed(4)}">${escapeHtml(formatInteger(value))}${shareKey ? ` <small>${escapeHtml(formatPercent(share))}</small>` : ''}</td>`;
      }).join('');
      return `<tr><th scope="row">${escapeHtml(rowFormatter(rowLabel))}</th>${columns}</tr>`;
    }).join('');
    return `<figure class="chart-card matrix-card">
      <figcaption><h3>${escapeHtml(config.title)}</h3><p>${escapeHtml(config.description || '')}</p></figcaption>
      <div class="table-wrap matrix-wrap"><table class="matrix-table"><thead><tr><th scope="col">${escapeHtml(config.rowLabel || '')}</th>${header}</tr></thead><tbody>${body}</tbody></table></div>
      <p class="matrix-legend">Intensidade = participação dentro da linha.</p>
      ${config.columnLimit && observedColumns.length > config.columnLimit
        ? config.aggregateColumnOther === false
          ? `<p class="chart-rule">Visual: Top ${config.columnLimit} colunas; as demais permanecem nas tabelas detalhadas. “Outros” não é somado porque os itens podem se sobrepor.</p>`
          : `<p class="chart-rule">Visual limitado às ${config.columnLimit} principais colunas.</p>`
        : ''}
      ${sourceNote(config.denominator, config.source)}
    </figure>`;
  }

  function renderLineChart(config) {
    const rows = naturalOrder(config.rows || [], config.xKey);
    const values = rows.map((row) => toNumber(row[config.yKey]));
    const width = 920;
    const height = 300;
    const left = 54;
    const top = 22;
    const innerWidth = width - left - 24;
    const innerHeight = height - top - 58;
    const max = Math.max(1, ...values);
    const points = rows.map((row, index) => {
      const x = left + (rows.length <= 1 ? 0 : (index / (rows.length - 1)) * innerWidth);
      const y = top + innerHeight - (toNumber(row[config.yKey]) / max) * innerHeight;
      return { x, y, row };
    });
    const path = points.map((point, index) => `${index ? 'L' : 'M'} ${point.x.toFixed(2)} ${point.y.toFixed(2)}`).join(' ');
    const dots = points.map((point) => `<circle cx="${point.x.toFixed(2)}" cy="${point.y.toFixed(2)}" r="3"><title>${escapeHtml(point.row[config.xKey])}: ${formatInteger(point.row[config.yKey])}</title></circle>`).join('');
    const firstLabel = rows.length ? rows[0][config.xKey] : '';
    const lastLabel = rows.length ? rows.at(-1)[config.xKey] : '';
    return `<figure class="chart-card">
      <figcaption><h3>${escapeHtml(config.title)}</h3><p>${escapeHtml(config.description || '')}</p></figcaption>
      <div class="chart-scroll"><svg class="line-chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="${escapeHtml(config.title)}">
        <line x1="${left}" y1="${top + innerHeight}" x2="${width - 24}" y2="${top + innerHeight}" class="axis"></line>
        <path d="${path}" class="line-series"></path>${dots}
        <text x="${left}" y="${height - 14}" class="axis-label">${escapeHtml(firstLabel)}</text>
        <text x="${width - 24}" y="${height - 14}" text-anchor="end" class="axis-label">${escapeHtml(lastLabel)}</text>
      </svg></div>
      ${sourceNote(config.denominator, config.source)}
    </figure>`;
  }

  function renderStackedChart(config) {
    const categories = naturalOrder(groupSum(config.rows || [], config.categoryKey, config.valueKey), 'label');
    return renderBarChart({
      title: config.title,
      description: config.description,
      rows: categories,
      labelKey: 'label',
      valueKey: 'value',
      denominator: config.denominator,
      source: config.source,
      limit: config.limit || 10,
    }).replace('bar-chart', 'stacked-chart');
  }

  function renderTable(config) {
    const columns = config.columns || [];
    const header = columns.map((column) => `<th scope="col">${escapeHtml(column.label)}</th>`).join('');
    const body = (config.rows || []).map((row) => `<tr>${columns.map((column) => {
      const raw = row[column.key];
      const formatted = column.format ? column.format(raw, row) : raw;
      return `<td>${escapeHtml(formatted ?? '—')}</td>`;
    }).join('')}</tr>`).join('');
    return `<div class="table-wrap"><table><thead><tr>${header}</tr></thead><tbody>${body || `<tr><td colspan="${Math.max(columns.length, 1)}">Sem dados observados.</td></tr>`}</tbody></table></div>`;
  }

  function metricCard(label, value, note) {
    return `<article class="metric-card"><span>${escapeHtml(label)}</span><strong>${escapeHtml(value)}</strong>${note ? `<small>${escapeHtml(note)}</small>` : ''}</article>`;
  }

  function chapter(id, kicker, title, lead, content) {
    return `<section class="report-section print-section" id="${escapeHtml(id)}">
      <header class="section-heading"><span>${escapeHtml(kicker)}</span><h2>${escapeHtml(title)}</h2><p>${escapeHtml(lead)}</p></header>
      ${content}
    </section>`;
  }

  function distributionTable(rows, labelKey) {
    return renderTable({
      columns: [
        { key: labelKey, label: 'Segmento' },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'share_pct', label: 'Participação', format: formatPercent },
      ],
      rows,
    });
  }

  function generalChannelTable(rows) {
    const channelNames = rows.map((row) => row.channel_name);
    return renderTable({
      columns: [
        { key: 'channel_name', label: 'Canal', format: formatChannelName },
        { key: 'gross_value', label: 'Valor bruto', format: formatCurrency },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'registration_ticket', label: 'Ticket médio', format: formatCurrency },
        { key: 'category', label: 'Direção' },
        { key: 'role', label: 'Papel observado' },
      ],
      rows: rows.map((row) => ({
        ...row,
        category: row.recommendation?.category,
        role: formatReportText(row.recommendation?.role, channelNames),
      })),
    });
  }

  function editorialBlock(title, lead, content, className = '') {
    return `<div class="editorial-block ${escapeHtml(className)}"><header><h3>${escapeHtml(title)}</h3>${lead ? `<p>${escapeHtml(lead)}</p>` : ''}</header>${content}</div>`;
  }

  function renderTakeaways(rows) {
    const cards = (rows || []).map((row) => `<article class="takeaway-card">
      <h3>${escapeHtml(formatReportText(row.title))}</h3>
      <p><strong>Evidência:</strong> ${escapeHtml(formatReportText(row.evidence))}</p>
      <p><strong>Implicação 2027:</strong> ${escapeHtml(formatReportText(row.implication))}</p>
    </article>`).join('');
    return `<div class="takeaway-grid">${cards}</div>`;
  }

  function withoutMarkdownHeading(value) {
    return String(value || '').replace(/^##[^\n]*(?:\r?\n)+/u, '');
  }

  function renderTopChannelDeepDives(channels, capstone, channelNames) {
    const topChannels = channels
      .filter((channel) => String(channel.channel_type || '').toLocaleLowerCase('pt-BR') !== 'organico')
      .slice(0, 6);
    if (!topChannels.length) return '<p>Nenhum canal não orgânico observado na base.</p>';

    return `<div class="channel-deep-dives">${topChannels.map((channel, index) => {
      const isRoadrunners = formatChannelName(channel.channel_name) === 'ROADRUNNERS';
      const narrative = isRoadrunners && capstone?.available
        ? capstone.capstone_markdown
        : channel.executive_summary || channel.executive_highlight || channel.recommendation?.role;
      const href = `canais/dossie.cfm?canal=${encodeURIComponent(channel.slug || '')}`;
      return `<article class="channel-deep-dive">
        <header class="channel-deep-dive-heading">
          <div><span>${index + 1}º em valor bruto entre os canais não orgânicos</span><h3>${escapeHtml(formatChannelName(channel.channel_name))}</h3></div>
          ${channel.slug ? `<a class="channel-open no-print" href="${escapeHtml(href)}">Ver dossiê completo</a>` : ''}
        </header>
        <div class="metric-grid">
          ${metricCard('Inscrições', formatInteger(channel.paid_registrations))}
          ${metricCard('Valor bruto', formatCurrency(channel.gross_value))}
          ${metricCard('Ticket', formatCurrency(channel.registration_ticket))}
          ${metricCard('Direção', channel.recommendation?.category || '—')}
        </div>
        <div class="executive-copy"><p>${renderNarrative(formatReportText(withoutMarkdownHeading(narrative || 'Resumo executivo não disponível.'), channelNames))}</p></div>
      </article>`;
    }).join('')}</div>`;
  }

  function renderChannelIndex(root, data) {
    const channels = sortChannelsByGross(data.channels || []).filter(isCommercialChannel);
    const channelNames = channels.map((channel) => channel.channel_name);
    const cards = channels.map((channel, index) => {
      const recommendation = channel.recommendation || {};
      const summary = channel.executive_summary || channel.executive_highlight || recommendation.role || 'Sem highlight disponível.';
      const href = `dossie.cfm?canal=${encodeURIComponent(channel.slug || '')}`;
      return `<article class="channel-card">
        <header class="channel-card-heading">
          <div class="channel-position">${index + 1}</div>
          <div class="channel-card-main">
            <span>${escapeHtml(recommendation.category || 'Sem classificação')}</span>
            <h2><a href="${escapeHtml(href)}">${escapeHtml(formatChannelName(channel.channel_name))}</a></h2>
          </div>
          <a class="channel-open" href="${escapeHtml(href)}">Abrir dossiê</a>
        </header>
        <dl class="channel-card-metrics">
          <div><dt>Valor bruto</dt><dd>${escapeHtml(formatCurrency(channel.gross_value))}</dd></div>
          <div><dt>Inscrições</dt><dd>${escapeHtml(formatInteger(channel.paid_registrations))}</dd></div>
          <div><dt>Ticket</dt><dd>${escapeHtml(formatCurrency(channel.registration_ticket))}</dd></div>
        </dl>
        <div class="channel-card-summary"><p>${renderNarrative(formatReportText(summary, channelNames))}</p></div>
      </article>`;
    }).join('');
    root.innerHTML = `${renderBarChart({
      title: 'Valor bruto por canal',
      description: 'Ordem comercial do portfólio; o visual usa Top 10 + Outros.',
      rows: channels,
      labelKey: 'channel_name',
      valueKey: 'gross_value',
      labelFormatter: formatChannelName,
      valueFormatter: formatCurrency,
      denominator: channels.length ? formatCurrency(channels.reduce((total, row) => total + toNumber(row.gross_value), 0)) : 0,
      source: 'Valores de pedido alocados às inscrições pagas de cada canal.',
    })}<div class="channel-directory">${cards || '<p>Não há canais observados.</p>'}</div>`;
  }

  function renderGeneral(root, data) {
    const general = data.general || {};
    const strategy = data.strategy || {};
    const datasets = strategy.datasets || {};
    const insights = strategy.insights || {};
    const definitions = strategy.definitions || {};
    const overview = general.overview || {};
    const channels = sortChannelsByGross(data.channels?.channels || []).filter(isCommercialChannel);
    const phaseOrder = definitions.phase_order || [];
    const modalityOrder = definitions.modality_order || [];
    const modalityRows = datasets.modality_mix || [];
    const lotRows = naturalOrder((datasets.lot_performance || []).filter((row) => isVisibleLot(row.lot)), 'lot');
    const lotModalityRows = (datasets.lot_modality || []).filter((row) => isVisibleLot(row.lot));
    const productLotRows = (datasets.product_lot_additional || []).filter((row) => isVisibleLot(row.lot));
    const productRows = [...(datasets.product_summary || [])].sort((left, right) => {
      const sales = toNumber(right.registrations_with_product) - toNumber(left.registrations_with_product);
      return sales || String(left.product_name ?? '').localeCompare(String(right.product_name ?? ''), 'pt-BR');
    });
    const stateRows = datasets.state_distribution || [];
    const weeklyRows = datasets.weekly_sales || [];
    const phasePlaybook = insights.phase_playbook || [];
    const distancePlaybook = insights.distance_playbook || [];
    const stateTiming = insights.state_timing || [];
    const portfolio = buildChannelPortfolio(channels, overview.gross_value);
    const productOpportunities = insights.product_opportunities || [];
    const portfolioGroups = portfolio.recommendation_groups || [];
    const capstone = general.datasets?.roadrunners_capstone?.[0] || {};
    const channelNames = channels.map((channel) => channel.channel_name);
    const visibleChannelNames = new Set(channelNames);
    const channelModalityRows = (datasets.channel_modality || []).filter((row) =>
      row.channel_name === 'Outros' || visibleChannelNames.has(row.channel_name));
    const channelVolumeOrder = rankRowsByTotal(
      channelModalityRows,
      'channel_name',
      'paid_registrations',
      'Outros',
    );
    const recommendationCounts = groupSum(
      channels.map((row) => ({ category: row.recommendation?.category || 'Sem classificação', paid_registrations: 1 })),
      'category',
    );

    const cards = `<div class="metric-grid">
      ${metricCard('Pedidos pagos', formatInteger(overview.paid_orders), 'grão de pedido')}
      ${metricCard('Inscrições pagas', formatInteger(overview.paid_registrations), 'grão de inscrição')}
      ${metricCard('Valor bruto', formatCurrency(overview.gross_value), 'pedidos pagos únicos')}
      ${metricCard('Ticket por inscrição', formatCurrency(overview.registration_ticket), 'razão entre totais')}
    </div>`;
    const orderedPhases = phasePlaybook.map((row) => ({
      label: row.phase,
      value: row.paid_registrations,
    }));
    const phaseTable = renderTable({
      columns: [
        { key: 'phase', label: 'Fase', format: formatPhase },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'event_share_pct', label: 'Participação', format: formatPercent },
        { key: 'lead_modality', label: 'Distância líder' },
        { key: 'lead_modality_share_pct', label: '% da fase', format: formatPercent },
        { key: 'lead_lot', label: 'Lote líder', format: formatLot },
        { key: 'lead_state', label: 'Estado líder' },
        { key: 'lead_channel', label: 'Canal acionável', format: formatChannelName },
      ],
      rows: phasePlaybook,
    });
    const distanceTable = renderTable({
      columns: [
        { key: 'modality', label: 'Distância' },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'event_share_pct', label: 'Participação', format: formatPercent },
        { key: 'peak_phase', label: 'Pico', format: formatPhase },
        { key: 'lead_lot', label: 'Lote líder', format: formatLot },
        { key: 'lead_state', label: 'Estado líder' },
        { key: 'volume_channel', label: 'Canal de volume' },
        { key: 'specialist', label: 'Canal especialista' },
      ],
      rows: distancePlaybook.map((row) => ({
        ...row,
        volume_channel: formatChannelName(row.volume_channel),
        specialist: row.specialist_channel && row.specialist_channel !== '—'
          ? `${formatChannelName(row.specialist_channel)} (índice ${decimalFormatter.format(toNumber(row.specialist_index))}; n=${formatInteger(row.specialist_cell)})`
          : 'Sem base robusta',
      })),
    });
    const stateTimingTable = renderTable({
      columns: [
        { key: 'state', label: 'Estado' },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'peak_phase', label: 'Fase de pico', format: formatPhase },
        { key: 'early_share_pct', label: 'Pré-lançamento + início', format: formatPercent },
        { key: 'late_share_pct', label: 'Reta final + encerramento', format: formatPercent },
      ],
      rows: stateTiming,
    });
    const productOpportunityTable = renderTable({
      columns: [
        { key: 'modality', label: 'Distância' },
        { key: 'paid_registrations', label: 'Base da distância', format: formatInteger },
        { key: 'leading_product', label: 'Produto líder sem kit' },
        { key: 'leading_product_registrations', label: 'Inscrições com item', format: formatInteger },
        { key: 'leading_product_take_rate_pct', label: 'Adoção', format: formatPercent },
        { key: 'alternatives', label: 'Próximos produtos observados' },
      ],
      rows: productOpportunities.map((row) => ({
        ...row,
        alternatives: (row.top_additional_products || []).slice(1).map((item) => `${item.product_name} (${formatPercent(item.take_rate_pct)})`).join('; ') || '—',
      })),
    });
    const portfolioTable = renderTable({
      columns: [
        { key: 'category', label: 'Direção' },
        { key: 'channels', label: 'Canais', format: formatInteger },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'gross_value', label: 'Valor bruto', format: formatCurrency },
        { key: 'gross_share_pct', label: 'Participação em valor', format: formatPercent },
      ],
      rows: portfolioGroups,
    });
    const caveats = (strategy.caveats || []).map((item) => `<li>${escapeHtml(item)}</li>`).join('');

    root.innerHTML = [
      chapter(GENERAL_CHAPTERS[0], 'Capítulo 1', 'Resumo executivo', 'O que aconteceu, onde o ciclo mudou e quais decisões a evidência sustenta.', `${cards}${renderTakeaways(insights.executive_takeaways || [])}`),
      chapter(GENERAL_CHAPTERS[1], 'Capítulo 2', 'Ciclo e sazonalidade das vendas', 'Semanas reais e fases comerciais mostram quando cada demanda apareceu.', `${renderLineChart({ title: 'Inscrições pagas por semana', description: 'Evolução cronológica do fechamento comercial.', rows: weeklyRows, xKey: 'week_start', yKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'Data de venda válida ou data do pedido como fallback controlado.' })}${renderBarChart({ title: 'Participação por fase', description: 'Volume de inscrições em Pré-lançamento, Início, Meio, Reta final e Encerramento.', rows: orderedPhases, labelKey: 'label', labelFormatter: formatPhase, valueKey: 'value', preserveOrder: true, denominator: overview.paid_registrations, source: 'Fases calculadas sobre o ciclo fechado.' })}${renderPhaseLegend()}${editorialBlock('Calendário de ativação', 'O que liderou em distância, lote, território e canal comercial em cada fase.', phaseTable, 'page-break-block')}`),
      chapter(GENERAL_CHAPTERS[2], 'Capítulo 3', 'Distâncias ao longo do ciclo', 'A composição por distância orienta qual prova promover em cada momento.', `${renderBarChart({ title: 'Mix de distâncias', description: 'Inscrições pagas por modalidade.', rows: modalityRows, labelKey: 'modality', valueKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'Modalidade informada na inscrição paga.' })}${renderMatrixChart({ title: 'Distâncias por fase', description: 'A matriz mostra como o produto dominante muda ao longo do ciclo.', rows: datasets.phase_modality || [], rowKey: 'phase', rowFormatter: formatPhase, columnKey: 'modality', valueKey: 'paid_registrations', shareKey: 'within_phase_share_pct', rowOrder: phaseOrder, columnOrder: modalityOrder, rowLabel: 'Fase', denominator: overview.paid_registrations, source: 'Inscrições pagas por fase comercial e modalidade.' })}${editorialBlock('Playbook por distância', 'Quando, onde e por quais canais cada prova encontrou sua principal tração.', distanceTable, 'page-break-block')}`),
      chapter(GENERAL_CHAPTERS[3], 'Capítulo 4', 'Lotes e produtos', 'Preço, urgência e itens vendidos além do kit ajudam a explicar o tipo de compra.', `${renderBarChart({ title: 'Inscrições por lote', description: 'Ordem natural dos lotes; volume apresentado no fechamento.', rows: lotRows, labelKey: 'lot', labelFormatter: formatLot, valueKey: 'paid_registrations', preserveOrder: true, denominator: overview.paid_registrations, source: 'Lote informado na inscrição paga.' })}${renderMatrixChart({ title: 'Distâncias por lote', description: 'A composição de cada lote evidencia a migração entre provas ao longo do calendário.', rows: lotModalityRows, rowKey: 'lot', rowFormatter: formatLot, columnKey: 'modality', valueKey: 'paid_registrations', shareKey: 'within_lot_share_pct', columnOrder: modalityOrder, rowLabel: 'Lote', denominator: overview.paid_registrations, source: 'Inscrições pagas por lote e modalidade; lote e fase são colineares.' })}${renderBarChart({ title: 'Venda de produtos sem itens de kit', description: 'Inscrições distintas com cada produto; somente kit_incluso é excluído.', rows: productRows, labelKey: 'product_name', valueKey: 'registrations_with_product', aggregateOther: false, denominator: overview.paid_registrations, source: 'Produtos adicionais e desconhecidos vinculados a inscrições pagas; itens podem se sobrepor e receita aparece somente quando explícita.' })}${renderMatrixChart({ title: 'Produtos vendidos por distância', description: 'Taxa de adoção dentro de cada prova; somente kit_incluso é excluído e o visual mostra o Top 10.', rows: datasets.product_modality_additional || [], rowKey: 'modality', columnKey: 'product_name', valueKey: 'registrations_with_product', shareKey: 'take_rate_pct', rowOrder: modalityOrder, rowLabel: 'Distância', columnLimit: 10, aggregateColumnOther: false, denominator: overview.paid_registrations, source: 'Produtos adicionais e desconhecidos vinculados a inscrições pagas; itens podem se sobrepor.' })}${renderMatrixChart({ title: 'Produtos vendidos por fase', description: 'Itens que ganharam tração em cada momento comercial; somente kit_incluso é excluído.', rows: datasets.product_phase_additional || [], rowKey: 'phase', rowFormatter: formatPhase, columnKey: 'product_name', valueKey: 'registrations_with_product', shareKey: 'take_rate_pct', rowOrder: phaseOrder, rowLabel: 'Fase', columnLimit: 10, aggregateColumnOther: false, denominator: overview.paid_registrations, source: 'Produtos adicionais e desconhecidos por fase; taxas usam a base de inscrições da própria fase.' })}${renderMatrixChart({ title: 'Produtos vendidos por lote', description: 'Adoção observada ao longo da progressão de lotes; somente kit_incluso é excluído.', rows: productLotRows, rowKey: 'lot', rowFormatter: formatLot, columnKey: 'product_name', valueKey: 'registrations_with_product', shareKey: 'take_rate_pct', rowLabel: 'Lote', columnLimit: 10, aggregateColumnOther: false, denominator: overview.paid_registrations, source: 'Produtos adicionais e desconhecidos por lote; lote e fase são colineares.' })}${editorialBlock('Leitura de oferta além do kit', 'A oferta auxiliar deve acompanhar o perfil da prova; taxas são lidas item a item.', productOpportunityTable)}${renderTable({ columns: [{ key: 'lot', label: 'Lote', format: formatLot }, { key: 'paid_registrations', label: 'Inscrições', format: formatInteger }, { key: 'allocated_gross_value', label: 'Valor bruto', format: formatCurrency }, { key: 'registration_ticket', label: 'Ticket', format: formatCurrency }], rows: lotRows })}${renderTable({ columns: [{ key: 'product_name', label: 'Produto' }, { key: 'classification', label: 'Classificação' }, { key: 'registrations_with_product', label: 'Inscrições', format: formatInteger }, { key: 'take_rate_pct', label: 'Adoção', format: formatPercent }, { key: 'explicit_revenue', label: 'Receita explícita', format: (value) => value == null ? 'não disponível' : formatCurrency(value) }], rows: productRows })}`),
      chapter(GENERAL_CHAPTERS[4], 'Capítulo 5', 'Territórios e alcance', 'Estados revelam concentração regional, alcance nacional e oportunidades de ativação.', `${renderBarChart({ title: 'Inscrições por estado', description: 'Distribuição territorial das inscrições pagas.', rows: stateRows, labelKey: 'state', valueKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'UF normalizada com cobertura explicitada.' })}${renderMatrixChart({ title: 'Distâncias por estado', description: 'O mix de prova diferencia mercados de endurance, meia maratona e entrada.', rows: datasets.state_modality || [], rowKey: 'state', columnKey: 'modality', valueKey: 'paid_registrations', shareKey: 'within_state_share_pct', columnOrder: modalityOrder, rowLabel: 'Estado', denominator: overview.paid_registrations, source: 'Top 10 estados válidos + Outros, por modalidade.' })}${editorialBlock('Timing dos principais estados', 'Participação própria no começo e no fechamento do ciclo.', stateTimingTable, 'page-break-block')}${distributionTable(stateRows, 'state')}`),
      chapter(GENERAL_CHAPTERS[5], 'Capítulo 6', 'Portfólio de canais', 'A lista está em valor bruto decrescente; escala e diferenciação são avaliadas separadamente. Canais com ticket médio de até R$ 10,00 ficam fora desta visão comercial.', `${renderBarChart({ title: 'Valor bruto por canal', description: 'Valores de pedido alocados às inscrições de cada canal.', rows: channels, labelKey: 'channel_name', labelFormatter: formatChannelName, valueKey: 'gross_value', valueFormatter: formatCurrency, denominator: formatCurrency(overview.gross_value), source: 'Pedidos pagos alocados sem duplicar o total do evento; corte comercial: ticket médio acima de R$ 10,00.' })}${renderMatrixChart({ title: 'Distâncias por canal', description: 'Canais em ordem decrescente de inscrições; “Outros” permanece no final.', rows: channelModalityRows, rowKey: 'channel_name', rowFormatter: formatChannelName, rowOrder: channelVolumeOrder, columnKey: 'modality', valueKey: 'paid_registrations', shareKey: 'within_channel_share_pct', columnOrder: modalityOrder, rowLabel: 'Canal', denominator: overview.paid_registrations, source: 'Inscrições pagas por canal e modalidade; canais com ticket médio de até R$ 10,00 foram removidos da visão.' })}${editorialBlock('O ganho está na função', `O maior canal concentra ${formatPercent(portfolio.top_1_gross_share_pct)} do valor; Top 3 = ${formatPercent(portfolio.top_3_gross_share_pct)}; Top 10 = ${formatPercent(portfolio.top_10_gross_share_pct)}.`, portfolioTable, 'portfolio-block')}${generalChannelTable(channels)}`),
      chapter(GENERAL_CHAPTERS[6], 'Capítulo 7', 'Aprofundamento dos 6 maiores canais', 'Os seis maiores canais por valor bruto, excluindo o orgânico, recebem leitura executiva de escala, mix, alcance, timing, produtos e diferenciação.', renderTopChannelDeepDives(channels, capstone, channelNames)),
      chapter(GENERAL_CHAPTERS[7], 'Capítulo 8', 'Recomendações e método', 'Decisões usam escala, diferenciação e redundância visíveis; não existe nota única.', `${renderBarChart({ title: 'Canais por direção recomendada', description: 'Quantidade de canais em cada categoria de ação.', rows: recommendationCounts, labelKey: 'label', valueKey: 'value', denominator: channels.length, source: 'Regras reproduzíveis com bloqueio de recomendação forte para amostras pequenas.' })}${editorialBlock('Direção do portfólio 2027', 'Concentrar escala sem eliminar funções complementares comprovadas.', portfolioTable)}<div class="method-note"><p><strong>Grãos preservados:</strong> pedidos, inscrições e produtos são reconciliados separadamente. Valores por canal são alocados; pedidos tocados não são aditivos.</p>${caveats ? `<ul>${caveats}</ul>` : ''}</div>`),
    ].join('');
  }

  function renderChannel(root, data) {
    const channel = data.channel || {};
    const recommendation = data.recommendation || {};
    const registrations = data.registration_cube || [];
    const products = data.product_cube || [];
    const paid = toNumber(channel.paid_registrations);
    const phaseOrder = ['Lançamento', 'Início', 'Meio', 'Reta final', 'Encerramento'];
    const phaseDistribution = groupSum(registrations, 'phase');
    const phases = phaseOrder.map((phase) => phaseDistribution.find((row) => row.label === phase)).filter(Boolean);
    const modalities = groupSum(registrations, 'modality');
    const lots = naturalOrder(groupSum(registrations.filter((row) => isVisibleLot(row.lot)), 'lot'), 'label');
    const states = groupSum(registrations, 'state');
    const productRows = groupSum(products, 'product_name', 'registrations_with_product');
    const weeklyRows = groupSum(registrations, 'week_start').map((row) => ({ week_start: row.label, paid_registrations: row.value }));
    const channelNames = [
      channel.channel_name,
      ...(channel.similar_channels_by_dimension || []).map((row) => row.other_channel),
    ];
    const evidence = (recommendation.evidence || []).map((item) => `<li>${escapeHtml(formatReportText(item, channelNames))}</li>`).join('');
    const sampleWarning = recommendation.sample_qualification === 'amostra reduzida'
      ? '<p class="warning">Amostra reduzida: use sinais como hipótese, não como conclusão definitiva.</p>'
      : '';
    const summary = formatReportText(
      channel.executive_summary || channel.executive_highlight || recommendation.role || 'Sem resumo disponível.',
      channelNames,
    );

    root.innerHTML = [
      chapter(CHANNEL_SECTIONS[0], 'Dossiê · 1', `Resumo de ${formatChannelName(channel.channel_name || 'canal')}`, 'Highlights executivos de escala, valor e função observada.', `<div class="metric-grid">${metricCard('Inscrições', formatInteger(paid))}${metricCard('Valor bruto', formatCurrency(channel.gross_value))}${metricCard('Ticket', formatCurrency(channel.registration_ticket))}${metricCard('Participação no evento', formatPercent(channel.share_of_event_registrations))}</div><div class="executive-copy"><p>${renderNarrative(summary)}</p></div>${sampleWarning}`),
      chapter(CHANNEL_SECTIONS[1], 'Dossiê · 2', 'Ciclo de venda', 'Semanas e fases indicam quando o canal é mais acionável.', `${renderLineChart({ title: 'Inscrições por semana', description: 'Ritmo semanal do canal.', rows: weeklyRows, xKey: 'week_start', yKey: 'paid_registrations', denominator: paid, source: 'Inscrições pagas atribuídas ao canal.' })}${renderBarChart({ title: 'Mix por fase', rows: phases, labelKey: 'label', labelFormatter: formatPhase, valueKey: 'value', preserveOrder: true, denominator: paid, source: 'Fases comerciais do ciclo fechado.' })}${renderPhaseLegend()}`),
      chapter(CHANNEL_SECTIONS[2], 'Dossiê · 3', 'Distâncias e lotes', 'O mix mostra o tipo de prova e o momento de preço que o canal mobiliza.', `${renderBarChart({ title: 'Distâncias vendidas', rows: modalities, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'Modalidade das inscrições pagas do canal.' })}${renderBarChart({ title: 'Lotes vendidos', rows: lots, labelKey: 'label', labelFormatter: formatLot, valueKey: 'value', preserveOrder: true, denominator: paid, source: 'Lote das inscrições pagas do canal.' })}${renderTable({ columns: [{ key: 'label', label: 'Distância' }, { key: 'value', label: 'Inscrições', format: formatInteger }, { key: 'share', label: 'Participação no canal', format: formatPercent }], rows: modalities.map((row) => ({ ...row, share: paid ? row.value / paid * 100 : 0 })) })}`),
      chapter(CHANNEL_SECTIONS[3], 'Dossiê · 4', 'Territórios', 'A distribuição estadual diferencia alcance regional e nacional.', `${renderBarChart({ title: 'Estados do canal', rows: states, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'UF normalizada nas inscrições pagas do canal.' })}${renderTable({ columns: [{ key: 'label', label: 'Estado' }, { key: 'value', label: 'Inscrições', format: formatInteger }, { key: 'share', label: 'Participação', format: formatPercent }], rows: [...states].sort((a, b) => b.value - a.value).map((row) => ({ ...row, share: paid ? row.value / paid * 100 : 0 })) })}`),
      chapter(CHANNEL_SECTIONS[4], 'Dossiê · 5', 'Produtos e compra auxiliar', 'Itens vendidos além do kit ajudam a descrever comportamento além da inscrição.', `${renderBarChart({ title: 'Produtos vendidos sem itens de kit', rows: productRows, labelKey: 'label', valueKey: 'value', aggregateOther: false, denominator: paid, source: 'Inscrições distintas com produto adicional ou desconhecido; Top 10 no visual, sem somar categorias sobrepostas.' })}${renderTable({ columns: [{ key: 'label', label: 'Produto' }, { key: 'value', label: 'Inscrições com produto', format: formatInteger }, { key: 'take_rate', label: 'Adoção', format: formatPercent }], rows: [...productRows].sort((a, b) => (b.value - a.value) || a.label.localeCompare(b.label, 'pt-BR')).map((row) => ({ ...row, take_rate: paid ? row.value / paid * 100 : 0 })) })}`),
      chapter(CHANNEL_SECTIONS[5], 'Dossiê · 6', 'Cupons e aliases consolidados', 'Um parceiro pode reunir mais de um código; a tabela preserva as identidades revisadas.', renderTable({ columns: [{ key: 'coupon_title', label: 'Título observado' }, { key: 'coupon_code', label: 'Código de cupom' }, { key: 'paid_registrations', label: 'Inscrições', format: formatInteger }, { key: 'alias_reason', label: 'Regra de consolidação' }], rows: data.aliases || [] })),
      chapter(CHANNEL_SECTIONS[6], 'Dossiê · 7', 'Recomendação executiva', 'A categoria indica uma direção de portfólio e sempre expõe suas evidências.', `<div class="recommendation recommendation-${escapeHtml(String(recommendation.category || '').toLowerCase().replaceAll(/[^a-z0-9]+/g, '-'))}"><span>Direção recomendada</span><strong>${escapeHtml(recommendation.category || 'Sem classificação')}</strong><p>${escapeHtml(formatReportText(recommendation.role || '', channelNames))}</p><ul>${evidence}</ul></div><div class="method-note"><p><strong>Qualificação:</strong> ${escapeHtml(recommendation.sample_qualification || 'não informada')}. Comparações são descritivas, com cobertura explícita e sem nota única.</p></div>`),
    ].join('');
  }

  const api = {
    GENERAL_CHAPTERS,
    CHANNEL_SECTIONS,
    escapeHtml,
    formatCurrency,
    formatPercent,
    formatInteger,
    formatLot,
    formatChannelName,
    formatPhase,
    isVisibleLot,
    isCommercialChannel,
    formatChannelMentions,
    formatReportText,
    renderPhaseLegend,
    renderNarrative,
    ratioOfTotals,
    topNWithOthers,
    rankRowsByTotal,
    sortChannelsByGross,
    renderBarChart,
    renderLineChart,
    renderMatrixChart,
    renderStackedChart,
    renderTable,
    renderChannelIndex,
    renderGeneral,
    renderChannel,
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (globalScope) globalScope.MifReport = api;
})(typeof window !== 'undefined' ? window : globalThis);
