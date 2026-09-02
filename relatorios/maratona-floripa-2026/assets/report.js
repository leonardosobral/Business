(function attachMifReport(globalScope) {
  'use strict';

  const GENERAL_CHAPTERS = [
    'resumo-executivo',
    'ciclo-de-vendas',
    'distancias',
    'lotes-e-produtos',
    'territorios',
    'canais',
    'roadrunners',
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
    const rows = topNWithOthers(config.rows || [], labelKey, valueKey, config.limit || 10);
    const max = Math.max(1, ...rows.map((row) => toNumber(row[valueKey])));
    const rowHeight = 38;
    const width = 920;
    const labelWidth = 245;
    const barWidth = 560;
    const height = Math.max(90, rows.length * rowHeight + 24);
    const valueFormatter = config.valueFormatter || formatInteger;
    const bars = rows.map((row, index) => {
      const value = toNumber(row[valueKey]);
      const y = index * rowHeight + 8;
      const visibleWidth = Math.max(value ? 2 : 0, (value / max) * barWidth);
      return `<g class="bar-row">
        <text x="0" y="${y + 17}" class="bar-label">${escapeHtml(row[labelKey])}</text>
        <rect x="${labelWidth}" y="${y}" width="${visibleWidth.toFixed(2)}" height="22" rx="4"></rect>
        <text x="${Math.min(labelWidth + visibleWidth + 8, width - 78).toFixed(2)}" y="${y + 17}" class="bar-value">${escapeHtml(valueFormatter(value))}</text>
      </g>`;
    }).join('');
    return `<figure class="chart-card">
      <figcaption><h3>${escapeHtml(config.title)}</h3><p>${escapeHtml(config.description || '')}</p></figcaption>
      <div class="chart-scroll"><svg class="bar-chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="${escapeHtml(config.title)}">${bars}</svg></div>
      ${sourceNote(config.denominator, config.source)}
      ${config.rows && config.rows.length > 10 ? '<p class="chart-rule">Visual: Top 10 + Outros. A tabela preserva todos os itens.</p>' : ''}
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
    return renderTable({
      columns: [
        { key: 'channel_name', label: 'Canal' },
        { key: 'gross_value', label: 'Valor bruto', format: formatCurrency },
        { key: 'paid_registrations', label: 'Inscrições', format: formatInteger },
        { key: 'registration_ticket', label: 'Ticket médio', format: formatCurrency },
        { key: 'category', label: 'Direção' },
        { key: 'role', label: 'Papel observado' },
      ],
      rows: rows.map((row) => ({
        ...row,
        category: row.recommendation?.category,
        role: row.recommendation?.role,
      })),
    });
  }

  function renderChannelIndex(root, data) {
    const channels = sortChannelsByGross(data.channels || []);
    const cards = channels.map((channel, index) => {
      const recommendation = channel.recommendation || {};
      const summary = channel.executive_summary || channel.executive_highlight || recommendation.role || 'Sem highlight disponível.';
      const href = `dossie.cfm?canal=${encodeURIComponent(channel.slug || '')}`;
      return `<article class="channel-card">
        <div class="channel-position">${index + 1}</div>
        <div class="channel-card-main">
          <span>${escapeHtml(recommendation.category || 'Sem classificação')}</span>
          <h2><a href="${escapeHtml(href)}">${escapeHtml(channel.channel_name)}</a></h2>
          <p>${escapeHtml(summary)}</p>
        </div>
        <dl>
          <div><dt>Valor bruto</dt><dd>${escapeHtml(formatCurrency(channel.gross_value))}</dd></div>
          <div><dt>Inscrições</dt><dd>${escapeHtml(formatInteger(channel.paid_registrations))}</dd></div>
          <div><dt>Ticket</dt><dd>${escapeHtml(formatCurrency(channel.registration_ticket))}</dd></div>
        </dl>
        <a class="channel-open" href="${escapeHtml(href)}">Abrir dossiê</a>
      </article>`;
    }).join('');
    root.innerHTML = `${renderBarChart({
      title: 'Valor bruto por canal',
      description: 'Ordem comercial do portfólio; o visual usa Top 10 + Outros.',
      rows: channels,
      labelKey: 'channel_name',
      valueKey: 'gross_value',
      valueFormatter: formatCurrency,
      denominator: channels.length ? formatCurrency(channels.reduce((total, row) => total + toNumber(row.gross_value), 0)) : 0,
      source: 'Valores de pedido alocados às inscrições pagas de cada canal.',
    })}<div class="channel-directory">${cards || '<p>Não há canais observados.</p>'}</div>`;
  }

  function renderGeneral(root, data) {
    const general = data.general || {};
    const cycle = data.cycle || {};
    const territories = data.territories || {};
    const products = data.products || {};
    const overview = general.overview || {};
    const channels = sortChannelsByGross(data.channels?.channels || []);
    const cycleObservations = cycle.observations || [];
    const phaseRows = groupSum(cycleObservations, 'phase');
    const modalityRows = cycle.datasets?.modality_mix || [];
    const lotRows = naturalOrder(cycle.datasets?.lot_performance || [], 'lot');
    const productRows = products.datasets?.product_summary || [];
    const stateRows = territories.datasets?.state_distribution || [];
    const weeklyRows = cycle.datasets?.weekly_sales || [];
    const capstone = general.datasets?.roadrunners_capstone?.[0] || {};
    const ownChannel = channels.find((row) => String(row.channel_name).toUpperCase() === 'ROADRUNNERS');
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
    const summary = capstone.executive_summary || 'Leitura executiva construída sobre pedidos, inscrições e itens de produto em grãos separados.';

    root.innerHTML = [
      chapter(GENERAL_CHAPTERS[0], 'Capítulo 1', 'Resumo executivo', 'O que aconteceu, qual foi a escala e quais decisões a evidência sustenta.', `${cards}<div class="executive-copy"><p>${escapeHtml(summary)}</p></div>`),
      chapter(GENERAL_CHAPTERS[1], 'Capítulo 2', 'Ciclo e sazonalidade das vendas', 'Semanas reais e fases comerciais mostram quando cada demanda apareceu.', `${renderLineChart({ title: 'Inscrições pagas por semana', description: 'Evolução cronológica do fechamento comercial.', rows: weeklyRows, xKey: 'week_start', yKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'Data de venda válida ou data do pedido como fallback controlado.' })}${renderBarChart({ title: 'Participação por fase', description: 'Volume de inscrições em Lançamento, Início, Meio, Reta final e Encerramento.', rows: phaseRows, labelKey: 'label', valueKey: 'value', denominator: overview.paid_registrations, source: 'Fases calculadas sobre o ciclo fechado.' })}${distributionTable(naturalOrder(phaseRows.map((row) => ({ phase: row.label, paid_registrations: row.value, share_pct: overview.paid_registrations ? row.value / overview.paid_registrations * 100 : 0 })), 'phase'), 'phase')}`),
      chapter(GENERAL_CHAPTERS[2], 'Capítulo 3', 'Distâncias ao longo do ciclo', 'A composição por distância orienta qual prova promover em cada momento.', `${renderBarChart({ title: 'Mix de distâncias', description: 'Inscrições pagas por modalidade.', rows: modalityRows, labelKey: 'modality', valueKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'Modalidade informada na inscrição paga.' })}${distributionTable(modalityRows, 'modality')}`),
      chapter(GENERAL_CHAPTERS[3], 'Capítulo 4', 'Lotes e produtos', 'Preço, urgência e itens adicionais ajudam a explicar o tipo de compra.', `${renderBarChart({ title: 'Inscrições por lote', description: 'Ordem natural dos lotes; volume apresentado no fechamento.', rows: lotRows, labelKey: 'lot', valueKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'Lote informado na inscrição paga.' })}${renderBarChart({ title: 'Adoção de produtos', description: 'Inscrições distintas com cada produto mapeado.', rows: productRows, labelKey: 'product_name', valueKey: 'registrations_with_product', denominator: overview.paid_registrations, source: 'Itens vinculados a inscrições pagas; receita somente quando explícita.' })}${renderTable({ columns: [{ key: 'lot', label: 'Lote' }, { key: 'paid_registrations', label: 'Inscrições', format: formatInteger }, { key: 'allocated_gross_value', label: 'Valor bruto', format: formatCurrency }, { key: 'registration_ticket', label: 'Ticket', format: formatCurrency }], rows: lotRows })}${renderTable({ columns: [{ key: 'product_name', label: 'Produto' }, { key: 'classification', label: 'Classificação' }, { key: 'registrations_with_product', label: 'Inscrições', format: formatInteger }, { key: 'take_rate_pct', label: 'Adoção', format: formatPercent }, { key: 'explicit_revenue', label: 'Receita explícita', format: (value) => value == null ? 'não disponível' : formatCurrency(value) }], rows: productRows })}`),
      chapter(GENERAL_CHAPTERS[4], 'Capítulo 5', 'Territórios e alcance', 'Estados revelam concentração regional, alcance nacional e oportunidades de ativação.', `${renderBarChart({ title: 'Inscrições por estado', description: 'Distribuição territorial das inscrições pagas.', rows: stateRows, labelKey: 'state', valueKey: 'paid_registrations', denominator: overview.paid_registrations, source: 'UF normalizada com cobertura explicitada.' })}${distributionTable(stateRows, 'state')}`),
      chapter(GENERAL_CHAPTERS[5], 'Capítulo 6', 'Portfólio de canais', 'A lista está em valor bruto decrescente; os gráficos exibem Top 10 + Outros.', `${renderBarChart({ title: 'Valor bruto por canal', description: 'Valores de pedido alocados às inscrições de cada canal.', rows: channels, labelKey: 'channel_name', valueKey: 'gross_value', valueFormatter: formatCurrency, denominator: formatCurrency(overview.gross_value), source: 'Pedidos pagos alocados sem duplicar o total do evento.' })}${generalChannelTable(channels)}`),
      chapter(GENERAL_CHAPTERS[6], 'Capítulo 7', 'Aprofundamento ROADRUNNERS', 'O canal próprio recebe uma leitura específica de escala, mix, alcance e papel.', ownChannel ? `<div class="metric-grid">${metricCard('Inscrições', formatInteger(ownChannel.paid_registrations))}${metricCard('Valor bruto', formatCurrency(ownChannel.gross_value))}${metricCard('Ticket', formatCurrency(ownChannel.registration_ticket))}${metricCard('Direção', ownChannel.recommendation?.category || '—')}</div><div class="executive-copy"><p>${escapeHtml(capstone.capstone_markdown || ownChannel.executive_summary || ownChannel.recommendation?.role || '')}</p></div>` : '<p>Canal ROADRUNNERS não observado na base.</p>'),
      chapter(GENERAL_CHAPTERS[7], 'Capítulo 8', 'Recomendações e método', 'Decisões usam escala, diferenciação e redundância visíveis; não existe nota única.', `${renderBarChart({ title: 'Canais por direção recomendada', description: 'Quantidade de canais em cada categoria de ação.', rows: recommendationCounts, labelKey: 'label', valueKey: 'value', denominator: channels.length, source: 'Regras reproduzíveis com bloqueio de recomendação forte para amostras pequenas.' })}<div class="method-note"><p><strong>Grãos preservados:</strong> pedidos, inscrições e produtos são reconciliados separadamente. Valores por canal são alocados; pedidos tocados não são aditivos. Cobertura e limitações permanecem visíveis.</p></div>`),
    ].join('');
  }

  function renderChannel(root, data) {
    const channel = data.channel || {};
    const recommendation = data.recommendation || {};
    const registrations = data.registration_cube || [];
    const products = data.product_cube || [];
    const paid = toNumber(channel.paid_registrations);
    const phases = groupSum(registrations, 'phase');
    const modalities = groupSum(registrations, 'modality');
    const lots = naturalOrder(groupSum(registrations, 'lot'), 'label');
    const states = groupSum(registrations, 'state');
    const productRows = groupSum(products, 'product_name', 'registrations_with_product');
    const weeklyRows = groupSum(registrations, 'week_start').map((row) => ({ week_start: row.label, paid_registrations: row.value }));
    const evidence = (recommendation.evidence || []).map((item) => `<li>${escapeHtml(item)}</li>`).join('');
    const sampleWarning = recommendation.sample_qualification === 'amostra reduzida'
      ? '<p class="warning">Amostra reduzida: use sinais como hipótese, não como conclusão definitiva.</p>'
      : '';
    const summary = channel.executive_summary || channel.executive_highlight || recommendation.role || 'Sem resumo disponível.';

    root.innerHTML = [
      chapter(CHANNEL_SECTIONS[0], 'Dossiê · 1', `Resumo de ${channel.channel_name || 'canal'}`, 'Highlights executivos de escala, valor e função observada.', `<div class="metric-grid">${metricCard('Inscrições', formatInteger(paid))}${metricCard('Valor bruto', formatCurrency(channel.gross_value))}${metricCard('Ticket', formatCurrency(channel.registration_ticket))}${metricCard('Participação no evento', formatPercent(channel.share_of_event_registrations))}</div><div class="executive-copy"><p>${escapeHtml(summary)}</p></div>${sampleWarning}`),
      chapter(CHANNEL_SECTIONS[1], 'Dossiê · 2', 'Ciclo de venda', 'Semanas e fases indicam quando o canal é mais acionável.', `${renderLineChart({ title: 'Inscrições por semana', description: 'Ritmo semanal do canal.', rows: weeklyRows, xKey: 'week_start', yKey: 'paid_registrations', denominator: paid, source: 'Inscrições pagas atribuídas ao canal.' })}${renderBarChart({ title: 'Mix por fase', rows: phases, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'Fases comerciais do ciclo fechado.' })}`),
      chapter(CHANNEL_SECTIONS[2], 'Dossiê · 3', 'Distâncias e lotes', 'O mix mostra o tipo de prova e o momento de preço que o canal mobiliza.', `${renderBarChart({ title: 'Distâncias vendidas', rows: modalities, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'Modalidade das inscrições pagas do canal.' })}${renderBarChart({ title: 'Lotes vendidos', rows: lots, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'Lote das inscrições pagas do canal.' })}${renderTable({ columns: [{ key: 'label', label: 'Distância' }, { key: 'value', label: 'Inscrições', format: formatInteger }, { key: 'share', label: 'Participação no canal', format: formatPercent }], rows: modalities.map((row) => ({ ...row, share: paid ? row.value / paid * 100 : 0 })) })}`),
      chapter(CHANNEL_SECTIONS[3], 'Dossiê · 4', 'Territórios', 'A distribuição estadual diferencia alcance regional e nacional.', `${renderBarChart({ title: 'Estados do canal', rows: states, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'UF normalizada nas inscrições pagas do canal.' })}${renderTable({ columns: [{ key: 'label', label: 'Estado' }, { key: 'value', label: 'Inscrições', format: formatInteger }, { key: 'share', label: 'Participação', format: formatPercent }], rows: [...states].sort((a, b) => b.value - a.value).map((row) => ({ ...row, share: paid ? row.value / paid * 100 : 0 })) })}`),
      chapter(CHANNEL_SECTIONS[4], 'Dossiê · 5', 'Produtos e compra auxiliar', 'Itens adicionais ajudam a descrever comportamento além da inscrição.', `${renderBarChart({ title: 'Produtos vinculados', rows: productRows, labelKey: 'label', valueKey: 'value', denominator: paid, source: 'Inscrições distintas com produto; Top 10 + Outros no visual.' })}${renderTable({ columns: [{ key: 'label', label: 'Produto' }, { key: 'value', label: 'Inscrições com produto', format: formatInteger }, { key: 'take_rate', label: 'Adoção', format: formatPercent }], rows: [...productRows].sort((a, b) => b.value - a.value).map((row) => ({ ...row, take_rate: paid ? row.value / paid * 100 : 0 })) })}`),
      chapter(CHANNEL_SECTIONS[5], 'Dossiê · 6', 'Cupons e aliases consolidados', 'Um parceiro pode reunir mais de um código; a tabela preserva as identidades revisadas.', renderTable({ columns: [{ key: 'coupon_title', label: 'Título observado' }, { key: 'coupon_code', label: 'Código de cupom' }, { key: 'paid_registrations', label: 'Inscrições', format: formatInteger }, { key: 'alias_reason', label: 'Regra de consolidação' }], rows: data.aliases || [] })),
      chapter(CHANNEL_SECTIONS[6], 'Dossiê · 7', 'Recomendação executiva', 'A categoria indica uma direção de portfólio e sempre expõe suas evidências.', `<div class="recommendation recommendation-${escapeHtml(String(recommendation.category || '').toLowerCase().replaceAll(/[^a-z0-9]+/g, '-'))}"><span>Direção recomendada</span><strong>${escapeHtml(recommendation.category || 'Sem classificação')}</strong><p>${escapeHtml(recommendation.role || '')}</p><ul>${evidence}</ul></div><div class="method-note"><p><strong>Qualificação:</strong> ${escapeHtml(recommendation.sample_qualification || 'não informada')}. Comparações são descritivas, com cobertura explícita e sem nota única.</p></div>`),
    ].join('');
  }

  const api = {
    GENERAL_CHAPTERS,
    CHANNEL_SECTIONS,
    escapeHtml,
    formatCurrency,
    formatPercent,
    formatInteger,
    ratioOfTotals,
    topNWithOthers,
    sortChannelsByGross,
    renderBarChart,
    renderLineChart,
    renderStackedChart,
    renderTable,
    renderChannelIndex,
    renderGeneral,
    renderChannel,
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (globalScope) globalScope.MifReport = api;
})(typeof window !== 'undefined' ? window : globalThis);
