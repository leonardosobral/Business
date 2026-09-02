const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const portfolioPath = path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
  'assets',
  'portfolio.js',
);
const portfolio = require(portfolioPath);

function simulatorFixture() {
  return {
    thresholds: { maximum_selected_channels: 10 },
    selectable_channels: [
      { slug: 'sports-week', channel_name: 'Sports Week' },
      { slug: 'roadrunners', channel_name: 'ROADRUNNERS' },
      { slug: 'pace', channel_name: 'Pace Floripa' },
    ],
    coverage_cube: [
      { phase: 'Lançamento', modality: '21K', state: 'SC', channel_name: 'Sports Week', paid_registrations: 12 },
      { phase: 'Lançamento', modality: '21K', state: 'SC', channel_name: 'ROADRUNNERS', paid_registrations: 14 },
      { phase: 'Lançamento', modality: '21K', state: 'SC', channel_name: 'Pace Floripa', paid_registrations: 4 },
      { phase: 'Lançamento', modality: '21K', state: 'SC', channel_name: 'Orgânico / sem cupom', paid_registrations: 10 },
      { phase: 'Lançamento', modality: '21K', state: 'SC', channel_name: 'Canais comerciais não orgânicos', paid_registrations: 30 },
      { phase: 'Lançamento', modality: '21K', state: 'SC', channel_name: 'Todos os canais', paid_registrations: 40 },
      { phase: 'Meio', modality: '42K', state: 'RS', channel_name: 'Sports Week', paid_registrations: 3 },
      { phase: 'Meio', modality: '42K', state: 'RS', channel_name: 'ROADRUNNERS', paid_registrations: 1 },
      { phase: 'Meio', modality: '42K', state: 'RS', channel_name: 'Canais comerciais não orgânicos', paid_registrations: 4 },
      { phase: 'Meio', modality: '42K', state: 'RS', channel_name: 'Todos os canais', paid_registrations: 4 },
    ],
  };
}

test('simulation rejects unknown and oversized selections', () => {
  const data = simulatorFixture();

  assert.throws(() => portfolio.simulate(data, ['missing']), /Canal desconhecido/);
  assert.throws(
    () => portfolio.simulate(data, Array.from({ length: 11 }, (_, index) => `c${index}`)),
    /até 10 canais/,
  );
});

test('simulation keeps selected aggregates while suppressing cells below five registrations', () => {
  const result = portfolio.simulate(simulatorFixture(), ['sports-week']);

  assert.equal(result.totals.selected_paid_registrations, 15);
  assert.equal(result.totals.suppressed_selected_registrations, 3);
  assert.equal(result.cells.length, 1);
  assert.equal(result.cells[0].selected_paid_registrations, 12);
});

test('simulation describes exposure and selects the largest remaining commercial alternative', () => {
  const result = portfolio.simulate(simulatorFixture(), ['sports-week']);

  assert.equal(result.cells[0].remaining_alternative, 'ROADRUNNERS');
  assert.equal(result.cells[0].exposure, 'média');
  assert.doesNotMatch(JSON.stringify(result), /vendas perdidas|perda prevista/i);
});

test('simulation ordering breaks ties by phase, modality and state after exposure and volume', () => {
  const data = simulatorFixture();
  data.coverage_cube.push(
    { phase: 'Início', modality: '5K', state: 'SP', channel_name: 'Sports Week', paid_registrations: 12 },
    { phase: 'Início', modality: '5K', state: 'SP', channel_name: 'ROADRUNNERS', paid_registrations: 12 },
    { phase: 'Início', modality: '5K', state: 'SP', channel_name: 'Canais comerciais não orgânicos', paid_registrations: 24 },
    { phase: 'Início', modality: '5K', state: 'SP', channel_name: 'Todos os canais', paid_registrations: 40 },
  );

  const result = portfolio.simulate(data, ['sports-week']);

  assert.deepEqual(result.cells.map((cell) => cell.phase), ['Início', 'Lançamento']);
});

function summaryFixture() {
  const dimensions = ['geography', 'modality', 'temporal', 'lot', 'product'];
  return {
    overview: { paid_registrations: 40, gross_value: '10000.00' },
    definitions: { commercial_universe: 'Canais comerciais acima do corte.' },
    dimension_panels: Object.fromEntries(dimensions.map((dimension) => [dimension, {
      benchmark: { eligible_pairs: 2, p90_similarity_0_1: 0.9, nearest_peer_p25_similarity_0_1: 0.4 },
      nearest_peers: {
        Alfa: { status: 'referência disponível', nearest_channel: '<img src=x>', similarity_0_1: 0.8 },
      },
    }])),
    redundancy_candidates: Array.from({ length: 12 }, (_, index) => ({
      left_channel: `Canal ${index + 1}`,
      right_channel: 'Alfa',
      qualifying_dimensions: ['geography', 'temporal'],
      qualifying_dimension_count: 2,
      combined_gross_value: '100.00',
    })),
    dependency_cells: Array.from({ length: 12 }, (_, index) => ({
      phase: index ? 'Início' : 'Lançamento',
      modality: '21K',
      state: `S${index + 1}`,
      channel_name: 'Alfa',
      paid_registrations: 12 - index,
      event_paid_registrations: 40,
      commercial_paid_registrations: 20,
      exposure: 'média',
    })),
    executive_takeaways: [{ title: 'Leitura', evidence: 'Padrão observado.' }],
  };
}

test('summary renderer exposes the six portfolio chapters and five separated dimension panels', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  for (const anchor of [
    'portfolio-resumo', 'portfolio-diferenciacao', 'portfolio-redundancia',
    'portfolio-dependencias', 'portfolio-simulador', 'portfolio-metodo',
  ]) assert.match(root.innerHTML, new RegExp(`id=["']${anchor}["']`));
  assert.equal((root.innerHTML.match(/data-portfolio-dimension=/g) || []).length, 5);
});

test('summary renderer keeps channel names safe and uses Portuguese report conventions', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  assert.match(root.innerHTML, /ALFA/);
  assert.match(root.innerHTML, /Pré-lançamento/);
  assert.doesNotMatch(root.innerHTML, /<img/i);
  assert.match(root.innerHTML, /&lt;img/i);
  assert.match(root.innerHTML, /não estabelecem causalidade/);
});

test('summary renderer limits redundancy and dependency evidence to Top 10 with Outros last', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  assert.match(root.innerHTML, /Top 10 \+ Outros/);
  assert.ok(root.innerHTML.lastIndexOf('OUTROS') > root.innerHTML.indexOf('CANAL 12'));
  const redundancySvg = root.innerHTML.slice(
    root.innerHTML.indexOf('Top 10 pares com redundância observada'),
    root.innerHTML.indexOf('</svg>', root.innerHTML.indexOf('Top 10 pares com redundância observada')),
  );
  assert.equal(redundancySvg.indexOf('>OUTROS</text>'), redundancySvg.lastIndexOf('>OUTROS</text>'));
});

test('simulation renderer exposes four KPI cards and complete publishable-cell evidence', () => {
  const root = { innerHTML: '' };
  const scenario = portfolio.simulate(simulatorFixture(), ['sports-week']);

  portfolio.renderSimulation(root, scenario);

  assert.equal((root.innerHTML.match(/class="metric-card"/g) || []).length, 4);
  assert.match(root.innerHTML, /Top 10 estados/);
  assert.match(root.innerHTML, /Células publicáveis/);
  assert.match(root.innerHTML, /ROADRUNNERS/);
});

test('share URL repeats deterministically ordered channel parameters', () => {
  assert.equal(
    portfolio.buildShareUrl('https://example.test/simulador?ignored=1', ['sports-week', 'roadrunners']),
    'https://example.test/simulador?canal=roadrunners&canal=sports-week',
  );
});
