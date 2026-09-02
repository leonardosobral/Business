const assert = require('node:assert/strict');
const fs = require('node:fs');
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

test('simulation preserves unavailable selected money as explicit null', () => {
  const result = portfolio.simulate(simulatorFixture(), ['sports-week']);

  assert.equal(result.totals.selected_gross_value, null);
  assert.equal(result.cells[0].selected_gross_value, null);
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
  assert.equal(result.cells[0].remaining_commercial_channels, 2);
  assert.equal(result.cells[0].exposure, 'média');
  assert.doesNotMatch(JSON.stringify(result), /vendas perdidas|perda prevista/i);
});

test('simulation deduplicates slugs before enforcing the selection limit', () => {
  const duplicates = Array.from({ length: 11 }, () => 'sports-week');

  assert.deepEqual(
    portfolio.simulate(simulatorFixture(), duplicates).selected_channels,
    [{ slug: 'sports-week', channel_name: 'Sports Week' }],
  );
});

test('canonical ROADRUNNERS plus SPORTS WEEK scenario reconciles registrations and gross value', () => {
  const canonical = JSON.parse(fs.readFileSync(path.resolve(
    __dirname,
    '..',
    'analyses',
    'mif_2026_channels',
    'modular_dist',
    'portfolio',
    'simulator.json',
  ), 'utf8'));
  const scenario = portfolio.simulate(canonical, ['roadrunners', 'sports-week']);
  const root = { innerHTML: '' };

  assert.equal(scenario.totals.selected_paid_registrations, 2825);
  assert.equal(scenario.totals.selected_gross_value, '778505.90');
  portfolio.renderSimulation(root, scenario);
  assert.match(root.innerHTML, /2\.825/);
  assert.match(root.innerHTML, /R\$[\s\u00a0]+778\.505,90/);
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
  const dependencyRegistrations = [20, 19, 18, 17, 16, 15, 14, 13, 12, 9, 5];
  return {
    overview: { paid_registrations: 40, gross_value: '10000.00' },
    definitions: {
      commercial_universe: 'Canais comerciais acima do corte.',
      similarity: 'Pares presentes no índice; orgânico pode aparecer como vizinho exibido, mas fica fora do benchmark.',
    },
    executive_summary: {
      commercial_channel_count: 143,
      commercial_paid_registrations: 20,
      commercial_event_share_pct: '50.00',
      concentration_basis: 'gross_value desc',
      top_1: { channels: 1, paid_registrations: 8, event_share_pct: '20.00', commercial_share_pct: '40.00', gross_value: '4000.00' },
      top_3: { channels: 3, paid_registrations: 14, event_share_pct: '35.00', commercial_share_pct: '70.00', gross_value: '7000.00' },
      top_10: { channels: 10, paid_registrations: 20, event_share_pct: '50.00', commercial_share_pct: '100.00', gross_value: '10000.00' },
      principal_dependencies: [],
      implication_2027: 'Para 2027, revisar contratos junto com custos e evidências complementares, sem inferência causal.',
    },
    redundancy_summary: { total_qualified_pairs: 16, displayed_pairs: 10 },
    dimension_panels: Object.fromEntries(dimensions.map((dimension) => [dimension, {
      benchmark: { eligible_pairs: 2, p90_similarity_0_1: 0.9, nearest_peer_p25_similarity_0_1: 0.4 },
      scale_high_gross_value_cutoff: 100,
      scale_population_channels: 143,
      sort: ['gross_value desc', 'paid_registrations desc', 'channel_name asc'],
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
      channels: [{
        channel_name: 'Alfa',
        paid_registrations: 12,
        gross_value: '100.00',
        event_share_pct: '30.00',
        registration_ticket: '20.00',
        scale: 'Escala alta',
        differentiation: 'Semelhante aos pares',
        quadrant: 'Escala alta · Semelhante aos pares',
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
      dimension_evidence: Object.fromEntries(dimensions.map((dimension, dimensionIndex) => [dimension, {
        similarity_0_1: 0.9 - dimensionIndex / 10,
        left_coverage_pct: '90.00',
        right_coverage_pct: '80.00',
        p90_similarity_0_1: 0.5,
        qualified: true,
        reason: 'Similaridade no p90 e cobertura bilateral mínima atendida.',
      }])),
    })),
    dependency_cells: dependencyRegistrations.map((paidRegistrations, index) => ({
      phase: index ? 'Início' : 'Lançamento',
      modality: '21K',
      state: `S${index + 1}`,
      channel_name: 'Alfa',
      paid_registrations: paidRegistrations,
      event_paid_registrations: 40,
      commercial_paid_registrations: 20,
      event_share_pct: '50.00',
      commercial_share_pct: '100.00',
      exposure: 'média',
      sample_status: paidRegistrations < 10
        ? 'amostra celular reduzida'
        : 'amostra celular suficiente',
    })),
    dependency_sample_summary: {
      published_cells: 11,
      published_cell_registrations: 158,
      reduced_cells: 2,
      reduced_cell_registrations: 14,
      reduced_cell_share_pct: '18.18',
      reduced_registration_share_pct: '8.86',
      publishable_cell_minimum_registrations: 5,
      sufficient_cell_minimum_registrations: 10,
    },
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
  assert.match(dependencySection, />5<\/text>/);
  const dependencyTable = dependencySection.slice(dependencySection.lastIndexOf('<table'));
  assert.doesNotMatch(dependencyTable, /<td>Outros<\/td>/);
  assert.equal((dependencyTable.match(/<tbody>[\s\S]*?<\/tbody>/)?.[0].match(/<tr>/g) || []).length, 11);
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

test('summary renderer visibly qualifies reduced dependency samples without causal wording', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  const dependencySection = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-dependencias"'),
    root.innerHTML.indexOf('id="portfolio-simulador"'),
  );
  const methodSection = root.innerHTML.slice(root.innerHTML.indexOf('id="portfolio-metodo"'));
  assert.match(dependencySection, /2 de 11 células publicadas/);
  assert.match(dependencySection, /18,18% das células/);
  assert.match(dependencySection, /14 de 158 inscrições publicadas/);
  assert.match(dependencySection, /8,86% das inscrições/);
  assert.match(dependencySection, /Qualificação da amostra/);
  assert.match(dependencySection, /amostra celular reduzida/);
  assert.match(methodSection, /5–9 inscrições/);
  assert.match(methodSection, /não estabelecem causalidade/);
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
  assert.equal((first.match(/90,00%/g) || []).length, 6);
  assert.equal((first.match(/80,00%/g) || []).length, 6);
  assert.equal((first.match(/p90: 50,00%/g) || []).length, 5);
  assert.equal((first.match(/Similaridade no p90 e cobertura bilateral mínima atendida/g) || []).length, 5);
  assert.match(first, /Dimensões qualificadas<\/dt><dd>Geografia, Lote, Modalidade, Produto, Temporalidade<\/dd>/);
  assert.match(first, /CANAL 1[\s\S]*?12 inscrições[\s\S]*?amostra reduzida/);
  assert.match(first, /ALFA[\s\S]*?34 inscrições[\s\S]*?referência disponível/);
  assert.match(first, /Qualificação do par[\s\S]*?amostra reduzida/);
  assert.match(first, /Valor bruto combinado[\s\S]*?R\$[\s\u00a0]+1\.234,56/);
});

test('summary renders global p75, population and a complete expandable gross-desc table', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  const dimensionSection = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-diferenciacao"'),
    root.innerHTML.indexOf('id="portfolio-redundancia"'),
  );
  assert.match(dimensionSection, /p75 de escala[^<]*R\$[\s\u00a0]+100,00/i);
  assert.match(dimensionSection, /143 canais comerciais/i);
  assert.match(dimensionSection, /Valor bruto decrescente/i);
  assert.match(dimensionSection, /Inscrições/);
  assert.match(dimensionSection, /Participação no evento/);
  assert.match(dimensionSection, /Ticket/);
  assert.match(dimensionSection, /Quadrante/);
  assert.match(dimensionSection, /<details[^>]+portfolio-dimension-audit/i);
});

test('missing dimension benchmarks render as insufficient evidence, never zero', () => {
  const root = { innerHTML: '' };
  const summary = summaryFixture();
  summary.dimension_panels.product.benchmark.nearest_peer_p25_similarity_0_1 = null;
  summary.dimension_panels.product.benchmark.p90_similarity_0_1 = null;

  portfolio.renderSummary(root, summary);

  const product = root.innerHTML.slice(root.innerHTML.indexOf('data-portfolio-dimension="product"'));
  assert.match(product, /evidência insuficiente/i);
  assert.doesNotMatch(product.split('</header>')[0], /0,00%/);
});

test('dependency evidence ranks relevant cells, labels channels and keeps low rows in a full appendix', () => {
  const root = { innerHTML: '' };
  const summary = summaryFixture();
  summary.dependency_cells = [
    ...summary.dependency_cells,
    {
      phase: 'Reta final', modality: '42K', state: 'SC', channel_name: 'Baixo',
      paid_registrations: 50, event_paid_registrations: 1000,
      commercial_paid_registrations: 100, event_share_pct: '5.00',
      commercial_share_pct: '50.00', exposure: 'baixa',
      sample_status: 'amostra celular suficiente',
    },
  ];
  const originalBar = report.renderBarChart;
  const calls = [];
  report.renderBarChart = (config) => {
    calls.push(config);
    return originalBar(config);
  };
  try {
    portfolio.renderSummary(root, summary);
  } finally {
    report.renderBarChart = originalBar;
  }

  const dependencyCall = calls.find((call) => /exposição relevante/i.test(call.title));
  assert.ok(dependencyCall);
  assert.equal(dependencyCall.rows.length, 11);
  assert.ok(dependencyCall.rows.every((row) => row.exposure !== 'baixa'));
  assert.ok(dependencyCall.rows.every((row) => /ALFA/.test(row.label)));
  const dependencySection = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-dependencias"'),
    root.innerHTML.indexOf('id="portfolio-simulador"'),
  );
  assert.match(dependencySection, /portfolio-dependency-appendix/);
  assert.match(dependencySection, /BAIXO/);
  assert.match(dependencySection, /Participação no evento/);
  assert.match(dependencySection, /Participação comercial/);
});

test('executive summary distinguishes total qualified pairs from the displayed Top 10', () => {
  const root = { innerHTML: '' };

  portfolio.renderSummary(root, summaryFixture());

  const executive = root.innerHTML.slice(
    root.innerHTML.indexOf('id="portfolio-resumo"'),
    root.innerHTML.indexOf('id="portfolio-diferenciacao"'),
  );
  assert.match(executive, /Canais comerciais[\s\S]*?143/);
  assert.match(executive, /Top 1[\s\S]*?R\$[\s\u00a0]+4\.000,00/);
  assert.match(executive, /Top 3[\s\S]*?R\$[\s\u00a0]+7\.000,00/);
  assert.match(executive, /Top 10[\s\S]*?R\$[\s\u00a0]+10\.000,00/);
  assert.match(executive, /16 pares qualificados[\s\S]*?10 exibidos/i);
  assert.match(executive, /2027/);
  assert.doesNotMatch(executive, /vendas perdidas|causou/i);
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

test('simulation renderer states when no commercial alternative was observed', () => {
  const root = { innerHTML: '' };
  const scenario = portfolio.simulate(simulatorFixture(), ['sports-week', 'roadrunners', 'pace']);

  portfolio.renderSimulation(root, scenario);

  assert.match(root.innerHTML, /sem alternativa comercial observada/i);
});

test('share URL repeats deterministically ordered channel parameters', () => {
  assert.equal(
    portfolio.buildShareUrl('https://example.test/simulador?ignored=1', ['sports-week', 'roadrunners']),
    'https://example.test/simulador?canal=roadrunners&canal=sports-week',
  );
});
