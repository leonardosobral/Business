const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const explorer = require(path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
  'assets',
  'explorer.js',
));

const data = {
  dimensions: {
    registrations: ['phase', 'modality', 'lot', 'state', 'channel_name'],
    products: ['phase', 'modality', 'state', 'channel_name', 'classification', 'product_name'],
  },
  registration_cube: [
    { phase: 'Início', modality: '21K', state: 'SC', channel_name: 'A', paid_registrations: 1, allocated_gross_value: '100.00' },
    { phase: 'Início', modality: '42K', state: 'SC', channel_name: 'A', paid_registrations: 3, allocated_gross_value: '600.00' },
    { phase: 'Meio', modality: '21K', state: 'PR', channel_name: 'B', paid_registrations: 2, allocated_gross_value: '500.00' },
  ],
  product_cube: [
    { phase: 'Início', product_name: 'Meia', classification: 'adicional', channel_name: 'A', product_quantity: 3, explicit_revenue: '90.00', registrations_with_product: 2 },
    { phase: 'Meio', product_name: 'Boné', classification: 'adicional', channel_name: 'B', product_quantity: 1, explicit_revenue: '50.00', registrations_with_product: 1 },
  ],
};

test('selection permits one or two dimensions and rejects a third', () => {
  assert.equal(explorer.validateSelection({ metric: 'paid_registrations', primaryDimension: 'phase' }, data).cube, 'registrations');
  assert.equal(explorer.validateSelection({ metric: 'paid_registrations', primaryDimension: 'phase', comparisonDimension: 'modality' }, data).cube, 'registrations');
  assert.throws(
    () => explorer.validateSelection({ metric: 'paid_registrations', primaryDimension: 'phase', comparisonDimension: 'modality', thirdDimension: 'state' }, data),
    /no máximo duas dimensões/i,
  );
});

test('metric and dimension must belong to the same anonymous cube', () => {
  assert.throws(
    () => explorer.validateSelection({ metric: 'gross_value', primaryDimension: 'product_name' }, data),
    /incompatível/i,
  );
  assert.throws(
    () => explorer.validateSelection({ metric: 'paid_orders', primaryDimension: 'phase' }, data),
    /métrica/i,
  );
  assert.equal(
    explorer.validateSelection({ metric: 'product_quantity', primaryDimension: 'product_name' }, data).cube,
    'products',
  );
});

test('filters are exact and aggregation computes ticket from ratio of totals', () => {
  const filtered = explorer.filterRows(data.registration_cube, { phase: 'Início' });
  assert.equal(filtered.length, 2);

  const result = explorer.aggregateRows(
    data,
    { metric: 'registration_ticket', primaryDimension: 'channel_name' },
    { phase: 'Início' },
  );
  assert.equal(result.rows.length, 1);
  assert.equal(result.rows[0].value, 175);
  assert.equal(result.denominator, 4);
});

test('two-dimensional grouping stays complete and ordered by value', () => {
  const result = explorer.aggregateRows(data, {
    metric: 'paid_registrations',
    primaryDimension: 'phase',
    comparisonDimension: 'modality',
  });

  assert.deepEqual(
    result.rows.map((row) => [row.primary, row.comparison, row.value]),
    [
      ['Início', '42K', 3],
      ['Meio', '21K', 2],
      ['Início', '21K', 1],
    ],
  );
});

test('chart uses Top 10 + Outros while the table remains complete', () => {
  const many = {
    ...data,
    registration_cube: Array.from({ length: 12 }, (_, index) => ({
      phase: `Fase ${index + 1}`,
      paid_registrations: index + 1,
      allocated_gross_value: String((index + 1) * 100),
    })),
  };
  const result = explorer.aggregateRows(many, {
    metric: 'paid_registrations',
    primaryDimension: 'phase',
  });

  assert.equal(result.rows.length, 12);
  assert.equal(result.chartRows.length, 11);
  assert.equal(result.chartRows.at(-1).primary, 'Outros');
  assert.equal(result.chartRows.at(-1).value, 3);
});

test('share URL is deterministic and includes only validated state', () => {
  const selection = {
    metric: 'paid_registrations',
    primaryDimension: 'phase',
    comparisonDimension: 'modality',
  };
  const first = explorer.buildShareUrl(
    'https://business.roadrunners.run/relatorios/maratona-floripa-2026/explorador/',
    selection,
    { state: 'SC', channel_name: 'ROADRUNNERS' },
  );
  const second = explorer.buildShareUrl(
    'https://business.roadrunners.run/relatorios/maratona-floripa-2026/explorador/',
    selection,
    { channel_name: 'ROADRUNNERS', state: 'SC' },
  );

  assert.equal(first, second);
  assert.match(first, /comparacao=modality/);
  assert.match(first, /filtro_channel_name=ROADRUNNERS/);
  assert.match(first, /filtro_state=SC/);
});
