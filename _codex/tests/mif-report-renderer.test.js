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
    cycle: { datasets: {}, observations: [], phase_order: [] },
    territories: { datasets: {}, observations: [] },
    products: { datasets: {}, observations: [] },
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
