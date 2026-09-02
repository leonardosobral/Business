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
const report = require(path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
  'assets',
  'report.js',
));

function simulatorFixture() {
  return {
    thresholds: {
      maximum_selected_channels: 10,
      publishable_cell_minimum_registrations: 5,
      exposure_classification_minimum_registrations: 10,
      exposure_high_event_share_pct: '40.00',
      exposure_medium_event_share_pct: '20.00',
      exposure_partner_concentration_pct: '60.00',
    },
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
      { phase: 'Início', modality: '5K', state: 'BA', channel_name: 'ROADRUNNERS', paid_registrations: 6 },
      { phase: 'Início', modality: '5K', state: 'BA', channel_name: 'Pace Floripa', paid_registrations: 4 },
      { phase: 'Início', modality: '5K', state: 'BA', channel_name: 'Orgânico / sem cupom', paid_registrations: 10 },
      { phase: 'Início', modality: '5K', state: 'BA', channel_name: 'Canais comerciais não orgânicos', paid_registrations: 10 },
      { phase: 'Início', modality: '5K', state: 'BA', channel_name: 'Todos os canais', paid_registrations: 20 },
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

test('simulation keeps global event and commercial denominators outside selected cells', () => {
  const result = portfolio.simulate(simulatorFixture(), ['sports-week']);

  assert.equal(result.totals.selected_paid_registrations, 15);
  assert.equal(result.totals.event_paid_registrations, 64);
  assert.equal(result.totals.commercial_paid_registrations, 44);
  assert.deepEqual(result.states.map((row) => row.label), ['SC', 'RS']);

  const root = { innerHTML: '' };
  portfolio.renderSimulation(root, result);
  assert.match(root.innerHTML, /23,44%/);
});

test('simulation describes exposure and selects the largest remaining commercial alternative', () => {
  const result = portfolio.simulate(simulatorFixture(), ['sports-week']);

  assert.equal(result.cells[0].remaining_alternative, 'ROADRUNNERS');
  assert.equal(result.cells[0].exposure, 'média');
  assert.doesNotMatch(JSON.stringify(result), /vendas perdidas|perda prevista/i);
});

test('simulation consumes every exposure threshold supplied by the payload', () => {
  const makeCellData = ({ selected, event, commercial }) => ({
    thresholds: { ...simulatorFixture().thresholds },
    selectable_channels: [
      { slug: 'sports-week', channel_name: 'Sports Week' },
      { slug: 'roadrunners', channel_name: 'ROADRUNNERS' },
    ],
    coverage_cube: [
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Sports Week', paid_registrations: selected },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'ROADRUNNERS', paid_registrations: commercial - selected },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Canais comerciais não orgânicos', paid_registrations: commercial },
      { phase: 'Meio', modality: '21K', state: 'SC', channel_name: 'Todos os canais', paid_registrations: event },
    ],
  });
  const exposure = (data) => portfolio.simulate(data, ['sports-week']).cells[0]?.exposure;

  const high = makeCellData({ selected: 12, event: 40, commercial: 30 });
  high.thresholds.exposure_high_event_share_pct = '30.00';
  assert.equal(exposure(high), 'alta');

  const medium = makeCellData({ selected: 12, event: 40, commercial: 30 });
  medium.thresholds.exposure_medium_event_share_pct = '31.00';
  assert.equal(exposure(medium), 'baixa');

  const partner = makeCellData({ selected: 12, event: 100, commercial: 20 });
  assert.equal(exposure(partner), 'dependência entre parceiros');
  partner.thresholds.exposure_partner_concentration_pct = '61.00';
  assert.equal(exposure(partner), 'baixa');

  const classification = makeCellData({ selected: 9, event: 30, commercial: 20 });
  assert.equal(exposure(classification), 'baixa');
  classification.thresholds.exposure_classification_minimum_registrations = 9;
  assert.equal(exposure(classification), 'média');

  const publishable = makeCellData({ selected: 4, event: 10, commercial: 6 });
  assert.equal(portfolio.simulate(publishable, ['sports-week']).cells.length, 0);
  publishable.thresholds.publishable_cell_minimum_registrations = 4;
  assert.equal(portfolio.simulate(publishable, ['sports-week']).cells.length, 1);
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
      quadrants: [
        { scale: 'Escala alta', differentiation: 'Mais diferenciado relativamente', channels: 1 },
        { scale: 'Escala alta', differentiation: 'Semelhante aos pares', channels: 2 },
        { scale: 'Escala menor', differentiation: 'Mais diferenciado relativamente', channels: 3 },
        { scale: 'Escala menor', differentiation: 'Semelhante aos pares', channels: 4 },
      ],
      top_channels: [{
        channel_name: 'Alfa',
        paid_registrations: 12,
        gross_value: '100.00',
        status: 'referência disponível',
        nearest_channel: '<img src=x>',
        similarity_0_1: 0.8,
      }],
      nearest_peers: {
        Alfa: { status: 'referência disponível', nearest_channel: '<img src=x>', similarity_0_1: 0.8 },
      },
    }])),
    redundancy_candidates: Array.from({ length: 10 }, (_, index) => ({
      left_channel: `Canal ${index + 1}`,
      right_channel: 'Alfa',
      qualifying_dimensions: ['geography', 'lot', 'modality', 'product', 'temporal'],
      qualifying_dimension_count: 5,
      left_paid_registrations: 12 + index,
      right_paid_registrations: 34,
      left_sample_status: 'amostra reduzida',
      right_sample_status: 'referência disponível',
      sample_status: 'amostra reduzida',
      combined_gross_value: index ? '100.00' : '1234.56',
      similarities: { geography: 0.9, modality: 0.8, temporal: 0.7, lot: 0.6, product: 0.5 },
    })),
    dependency_cells: Array.from({ length: 11 }, (_, index) => ({
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

test('summary renderer draws one real four-group matrix for every dimension panel', () => {
  const root = { innerHTML: '' };
  const originalMatrix = report.renderMatrixChart;
  const calls = [];
  report.renderMatrixChart = (config) => {
    calls.push(config);
    return originalMatrix(config);
  };
  try {
    portfolio.renderSummary(root, summaryFixture());
  } finally {
    report.renderMatrixChart = originalMatrix;
  }

  assert.equal(calls.length, 5);
  for (const config of calls) {
    assert.equal(config.rows.length, 4);
    assert.deepEqual(
      new Set(config.rows.map((row) => `${row.scale}\u0000${row.differentiation}`)),
      new Set([
        'Escala alta\u0000Mais diferenciado relativamente',
        'Escala alta\u0000Semelhante aos pares',
        'Escala menor\u0000Mais diferenciado relativamente',
        'Escala menor\u0000Semelhante aos pares',
      ]),
    );
  }
});

test('summary renderer keeps channel names safe and uses Portuguese report conventions', () => {
  const root = { innerHTML: '' };
  const summary = summaryFixture();
  summary.redundancy_candidates[0].left_channel = '<img src=x>';

  portfolio.renderSummary(root, summary);

  assert.match(root.innerHTML, /ALFA/);
  assert.match(root.innerHTML, /Pré-lançamento/);
  assert.doesNotMatch(root.innerHTML, /<img/i);
  assert.match(root.innerHTML, /&lt;img/i);
  assert.match(root.innerHTML, /não estabelecem causalidade/);
});

test('summary renderer consumes full producer-shaped dependencies for KPI and additive Outros', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  const redundancySection = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-redundancia"'),
    root.innerHTML.indexOf('id="portfolio-dependencias"'),
  );
  assert.match(redundancySection, /CANAL 10 × ALFA/);
  assert.doesNotMatch(redundancySection, /OUTROS/);
  assert.match(redundancySection, /Geografia|Modalidade|Temporalidade|Lote|Produto/);
  assert.equal((redundancySection.match(/<article class="portfolio-pair-card"/g) || []).length, 10);

  const dependencySection = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-dependencias"'),
    root.innerHTML.indexOf('id="portfolio-simulador"'),
  );
  assert.match(dependencySection, /Top 10 \+ Outros/);
  assert.equal((dependencySection.match(/>Outros<\/text>/g) || []).length, 1);
  assert.match(dependencySection, />2<\/text>/);
  const dependencyTable = dependencySection.slice(dependencySection.lastIndexOf('<table'));
  assert.doesNotMatch(dependencyTable, /<td>Outros<\/td>/);
  assert.equal((dependencyTable.match(/<tbody>[\s\S]*?<\/tbody>/)?.[0].match(/<tr>/g) || []).length, 10);
  assert.match(root.innerHTML, /Células de dependência<\/span><strong>11<\/strong>/);

  const exactTopTen = summaryFixture();
  exactTopTen.redundancy_candidates = exactTopTen.redundancy_candidates.slice(0, 10);
  exactTopTen.dependency_cells = exactTopTen.dependency_cells.slice(0, 10);
  const exactRoot = { innerHTML: '' };
  portfolio.renderSummary(exactRoot, exactTopTen);
  const exactDependencies = exactRoot.innerHTML.slice(
    exactRoot.innerHTML.indexOf('id="portfolio-dependencias"'),
    exactRoot.innerHTML.indexOf('id="portfolio-simulador"'),
  );
  assert.doesNotMatch(exactDependencies, /Top 10 \+ Outros|>Outros<\/text>/);
});

test('summary renderer presents every Top 10 redundancy pair as complete semantic evidence cards', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  const redundancySection = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-redundancia"'),
    root.innerHTML.indexOf('id="portfolio-dependencias"'),
  );
  const cards = redundancySection.match(/<article class="portfolio-pair-card"[\s\S]*?<\/article>/g) || [];
  assert.equal(cards.length, 10);
  const first = cards[0];
  assert.match(first, /<h3>CANAL 1 × ALFA<\/h3>/);
  assert.equal((first.match(/class="portfolio-pair-dimension"/g) || []).length, 5);
  for (const evidence of [
    ['Geografia', '90,00%'],
    ['Modalidade', '80,00%'],
    ['Temporalidade', '70,00%'],
    ['Lote', '60,00%'],
    ['Produto', '50,00%'],
  ]) {
    assert.match(first, new RegExp(`<span>${evidence[0]}</span>[\\s\\S]*?<strong>${evidence[1]}</strong>`));
  }
  assert.equal((first.match(/Cobertura mínima atendida/g) || []).length, 5);
  assert.match(first, /Dimensões qualificadas<\/dt><dd>Geografia, Lote, Modalidade, Produto, Temporalidade<\/dd>/);
  assert.match(first, /CANAL 1[\s\S]*?12 inscrições[\s\S]*?amostra reduzida/);
  assert.match(first, /ALFA[\s\S]*?34 inscrições[\s\S]*?referência disponível/);
  assert.match(first, /Qualificação do par[\s\S]*?amostra reduzida/);
  assert.match(first, /Valor bruto combinado[\s\S]*?R\$[\s\u00a0]+1\.234,56/);
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
