const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const rendererPath = path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
  'assets',
  'report.js',
);
const report = require(rendererPath);

test('Top 10 is value-descending and combines every remaining row as Outros', () => {
  const rows = Array.from({ length: 12 }, (_, index) => ({
    label: `Canal ${index + 1}`,
    value: index + 1,
  }));

  const result = report.topNWithOthers(rows, 'label', 'value', 10);

  assert.equal(result.length, 11);
  assert.deepEqual(result.slice(0, 3).map((row) => row.value), [12, 11, 10]);
  assert.equal(result.at(-1).label, 'Outros');
  assert.equal(result.at(-1).value, 3);
});

test('formatters and ticket use ratio of totals', () => {
  assert.equal(report.formatCurrency(4321891.2), 'R$ 4.321.891,20');
  assert.equal(report.formatPercent(51.56), '51,56%');
  assert.equal(
    report.ratioOfTotals(
      [
        { gross: '100.00', registrations: 1 },
        { gross: '300.00', registrations: 3 },
      ],
      'gross',
      'registrations',
    ),
    100,
  );
});

test('HTML escaping protects headings, table cells and links', () => {
  assert.equal(
    report.escapeHtml('<script>alert("x")</script>&'),
    '&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;&amp;',
  );
  const table = report.renderTable({
    columns: [{ key: 'name', label: 'Canal' }],
    rows: [{ name: '<img src=x onerror=1>' }],
  });
  assert.doesNotMatch(table, /<img/i);
  assert.match(table, /&lt;img/);
});

test('generated narrative renders safe emphasis without Markdown artifacts', () => {
  const narrative = report.renderNarrative('## Resumo - **Escala:** forte <script>');

  assert.equal(narrative, 'Resumo<br><strong>Escala:</strong> forte &lt;script&gt;');
  assert.doesNotMatch(narrative, /##|\*\*/);
});

test('ordered charts preserve commercial sequences such as lots', () => {
  const chart = report.renderBarChart({
    title: 'Lotes',
    rows: [{ lot: '1', count: 5 }, { lot: '2', count: 10 }],
    labelKey: 'lot',
    valueKey: 'count',
    preserveOrder: true,
  });

  assert.ok(chart.indexOf('>1</text>') < chart.indexOf('>2</text>'));
});

test('channel list is ordered by gross DESC, registrations DESC and name', () => {
  const rows = report.sortChannelsByGross([
    { channel_name: 'Zeta', gross_value: '100.00', paid_registrations: 2 },
    { channel_name: 'Beta', gross_value: '200.00', paid_registrations: 1 },
    { channel_name: 'Alfa', gross_value: '100.00', paid_registrations: 3 },
  ]);

  assert.deepEqual(rows.map((row) => row.channel_name), ['Beta', 'Alfa', 'Zeta']);
});

test('channel directory renders executive highlights without raw Markdown', () => {
  const root = { innerHTML: '' };
  report.renderChannelIndex(root, {
    channels: [{
      slug: 'roadrunners',
      channel_name: 'ROADRUNNERS',
      gross_value: '545290.12',
      paid_registrations: 1876,
      registration_ticket: '290.67',
      executive_summary: '## ROADRUNNERS - **Escala e valor** — destaque <script>',
      recommendation: { category: 'Priorizar' },
    }],
  });

  assert.doesNotMatch(root.innerHTML, /##|\*\*/);
  assert.match(root.innerHTML, /<strong>Escala e valor<\/strong>/);
  assert.match(root.innerHTML, /&lt;script&gt;/);
});

test('chart markup states title, denominator, source and Top 10 rule', () => {
  const chart = report.renderBarChart({
    title: 'Inscrições por canal',
    description: 'Comparação do volume pago.',
    rows: Array.from({ length: 12 }, (_, index) => ({
      channel: `Canal ${index}`,
      count: index + 1,
    })),
    labelKey: 'channel',
    valueKey: 'count',
    denominator: 78,
    source: 'Inscrições pagas reconciliadas.',
  });

  assert.match(chart, /Inscrições por canal/);
  assert.match(chart, /Outros/);
  assert.match(chart, /Denominador:<\/strong>\s*78/);
  assert.match(chart, /Inscrições pagas reconciliadas/);
  assert.match(chart, /<svg/);
});

test('overlapping product charts truncate at ten without manufacturing Outros', () => {
  const chart = report.renderBarChart({
    title: 'Produtos adicionais',
    rows: Array.from({ length: 12 }, (_, index) => ({
      product: `Produto ${index + 1}`,
      count: index + 1,
    })),
    labelKey: 'product',
    valueKey: 'count',
    aggregateOther: false,
  });

  assert.doesNotMatch(chart, />Outros</);
  assert.match(chart, /Top 10; os demais itens permanecem na tabela/);
  assert.doesNotMatch(chart, />Produto 1</);
  assert.match(chart, />Produto 12</);
});

test('matrix chart renders exact row-column crossings with an inspectable legend', () => {
  const chart = report.renderMatrixChart({
    title: 'Distância por fase',
    description: 'Composição de cada fase.',
    rows: [
      { phase: 'Início', modality: '21K', paid_registrations: 4, within_phase_share_pct: 66.67 },
      { phase: 'Início', modality: '42K', paid_registrations: 2, within_phase_share_pct: 33.33 },
      { phase: 'Meio', modality: '21K', paid_registrations: 3, within_phase_share_pct: 100 },
    ],
    rowKey: 'phase',
    columnKey: 'modality',
    valueKey: 'paid_registrations',
    shareKey: 'within_phase_share_pct',
    rowOrder: ['Início', 'Meio'],
    columnOrder: ['42K', '21K'],
    denominator: 9,
    source: 'Base reconciliada.',
  });

  assert.match(chart, /Distância por fase/);
  assert.ok(chart.indexOf('>42K<') < chart.indexOf('>21K<'));
  assert.match(chart, /4 <small>66,67%<\/small>/);
  assert.match(chart, /Intensidade = participação dentro da linha/);
  assert.match(chart, /Base reconciliada/);
});

test('overlapping product matrix keeps only its top ten columns without Outros', () => {
  const chart = report.renderMatrixChart({
    title: 'Produtos por distância',
    rows: Array.from({ length: 12 }, (_, index) => ({
      modality: '21K',
      product: `Produto ${index + 1}`,
      count: index + 1,
      takeRate: index + 1,
    })),
    rowKey: 'modality',
    columnKey: 'product',
    valueKey: 'count',
    shareKey: 'takeRate',
    columnLimit: 10,
    aggregateColumnOther: false,
  });

  assert.doesNotMatch(chart, />Outros</);
  assert.match(chart, />Produto 12</);
  assert.doesNotMatch(chart, />Produto 1</);
  assert.match(chart, /Top 10 colunas; as demais permanecem nas tabelas detalhadas/);
});

test('general and channel renderers expose every print chapter', () => {
  const generalRoot = { innerHTML: '' };
  report.renderGeneral(generalRoot, {
    general: {
      overview: {
        paid_orders: 10,
        paid_registrations: 12,
        gross_value: '3000.00',
        registration_ticket: '250.00',
      },
      datasets: { roadrunners_capstone: [{ executive_summary: 'Resumo executivo.' }] },
      source_notes: {},
    },
    strategy: {
      definitions: { phase_order: [], modality_order: [] },
      datasets: {},
      insights: {
        phase_playbook: [],
        distance_playbook: [],
        state_timing: [],
        channel_portfolio: { recommendation_groups: [] },
        product_opportunities: [],
      },
      caveats: [],
    },
    channels: { channels: [] },
  });
  for (const anchor of report.GENERAL_CHAPTERS) {
    assert.match(generalRoot.innerHTML, new RegExp(`id=["']${anchor}["']`));
  }

  const channelRoot = { innerHTML: '' };
  report.renderChannel(channelRoot, {
    channel: {
      channel_name: 'ROADRUNNERS',
      paid_registrations: 100,
      gross_value: '30000.00',
      registration_ticket: '300.00',
      executive_summary: 'Canal próprio forte.',
    },
    recommendation: {
      category: 'Priorizar',
      role: 'Venda ampla',
      evidence: ['Escala material', 'Cobertura nacional'],
    },
    aliases: [],
    registration_cube: [],
    product_cube: [],
  });
  for (const anchor of report.CHANNEL_SECTIONS) {
    assert.match(channelRoot.innerHTML, new RegExp(`id=["']${anchor}["']`));
  }
  assert.match(channelRoot.innerHTML, /Priorizar/);
});

test('general report fixes every strategic crossing and playbook in the editorial flow', () => {
  const root = { innerHTML: '' };
  report.renderGeneral(root, {
    general: {
      overview: {
        paid_orders: 10,
        paid_registrations: 16,
        gross_value: '3200.00',
        registration_ticket: '200.00',
      },
      datasets: { roadrunners_capstone: [{ executive_summary: 'Resumo ROADRUNNERS.' }] },
    },
    strategy: {
      definitions: {
        phase_order: ['Início', 'Meio', 'Encerramento'],
        modality_order: ['42K', '21K', '5K'],
      },
      datasets: {
        weekly_sales: [], lot_performance: [], modality_mix: [], state_distribution: [], product_summary: [],
        phase_modality: [{ phase: 'Início', modality: '21K', paid_registrations: 4, within_phase_share_pct: 66.67 }],
        lot_modality: [{ lot: '1', modality: '21K', paid_registrations: 4, within_lot_share_pct: 66.67 }],
        state_modality: [{ state: 'SC', modality: '21K', paid_registrations: 4, within_state_share_pct: 50 }],
        channel_modality: [{ channel_name: 'ROADRUNNERS', modality: '21K', paid_registrations: 4, within_channel_share_pct: 50 }],
        product_modality_additional: [{ modality: '21K', product_name: 'Gravação', registrations_with_product: 2, take_rate_pct: 28.57 }],
        product_phase_additional: [{ phase: 'Início', product_name: 'Gravação', registrations_with_product: 2, take_rate_pct: 33.33 }],
        product_lot_additional: [{ lot: '1', product_name: 'Gravação', registrations_with_product: 2, take_rate_pct: 33.33 }],
      },
      insights: {
        executive_takeaways: [{ title: 'Decisão central', evidence: 'Evidência.', implication: 'Ação.' }],
        phase_playbook: [{ phase: 'Início', paid_registrations: 6, event_share_pct: 37.5, lead_modality: '21K', lead_modality_share_pct: 66.67, lead_lot: '1', lead_state: 'SC', lead_channel: 'ROADRUNNERS' }],
        distance_playbook: [{ modality: '21K', paid_registrations: 7, event_share_pct: 43.75, peak_phase: 'Início', lead_lot: '1', lead_state: 'SC', volume_channel: 'ROADRUNNERS', specialist_channel: 'Sports Week', specialist_index: 122.9, specialist_cell: 30 }],
        state_timing: [{ state: 'SC', paid_registrations: 12, peak_phase: 'Encerramento', early_share_pct: 33.33, late_share_pct: 41.67 }],
        channel_portfolio: { channels: 3, top_1_gross_share_pct: 53.12, top_3_gross_share_pct: 100, top_10_gross_share_pct: 100, recommendation_groups: [{ category: 'Priorizar', channels: 1, paid_registrations: 7, gross_value: '1700.00', gross_share_pct: 53.12 }] },
        product_opportunities: [{ modality: '21K', paid_registrations: 7, leading_product: 'Gravação', leading_product_registrations: 2, leading_product_take_rate_pct: 28.57, top_additional_products: [] }],
      },
      caveats: ['Fase e lote são colineares.'],
    },
    channels: {
      channels: [{ channel_name: 'ROADRUNNERS', paid_registrations: 7, gross_value: '1700.00', registration_ticket: '242.86', recommendation: { category: 'Priorizar' } }],
    },
  });

  for (const title of [
    'Distâncias por fase',
    'Distâncias por lote',
    'Distâncias por estado',
    'Distâncias por canal',
    'Calendário de ativação',
    'Playbook por distância',
    'Timing dos principais estados',
    'Produtos adicionais por distância',
    'Produtos adicionais por fase',
    'Produtos adicionais por lote',
  ]) {
    assert.match(root.innerHTML, new RegExp(title));
  }
  assert.match(root.innerHTML, /O ganho está na função/);
  assert.match(root.innerHTML, /Sports Week/);
  assert.match(root.innerHTML, /Fase e lote são colineares/);
});
