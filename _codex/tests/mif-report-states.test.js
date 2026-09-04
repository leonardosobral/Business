const assert = require('node:assert/strict');
const path = require('node:path');
const test = require('node:test');

const states = require(path.resolve(
  __dirname,
  '..',
  '..',
  'relatorios',
  'maratona-floripa-2026',
  'assets',
  'states.js',
));

function fixture() {
  return {
    overview: {
      event_paid_registrations: 100,
      event_gross_value: '30000.00',
      valid_state_registrations: 95,
      state_coverage_pct: '95.00',
      commercial_paid_registrations: 60,
      commercial_channel_count: 3,
      classified_channel_count: 2,
      national_channel_count: 2,
    },
    thresholds: {
      minimum_classifiable_registrations: 30,
      minimum_valid_state_coverage_pct: '70.00',
      minimum_relevant_state_registrations: 5,
      national_minimum_relevant_states: 10,
      national_minimum_relevant_regions: 4,
      national_maximum_leading_state_share_pct: '40.00',
      multiregional_minimum_relevant_states: 5,
      multiregional_minimum_relevant_regions: 3,
      multiregional_maximum_leading_state_share_pct: '60.00',
      minimum_publishable_state_channel_registrations: 5,
    },
    definitions: {
      reach: 'Alcance observado, sem inferência causal.',
      overlap: 'Semelhança de distribuição, sem pedidos duplicados.',
      commercial_universe: 'Canais comerciais elegíveis.',
    },
    states: [
      { state: 'SP', region: 'Sudeste', paid_registrations: 40, gross_value: '12400.00', registration_ticket: '310.00', event_share_pct: '40.00', commercial_paid_registrations: 30, commercial_share_of_state_pct: '75.00', leading_channel: 'MANIADECORRIDA', leading_channel_registrations: 18, leading_channel_state_share_pct: '45.00', publishable_channel_count: 2 },
      { state: 'SC', region: 'Sul', paid_registrations: 30, gross_value: '8700.00', registration_ticket: '290.00', event_share_pct: '30.00', commercial_paid_registrations: 20, commercial_share_of_state_pct: '66.67', leading_channel: 'ROADRUNNERS', leading_channel_registrations: 15, leading_channel_state_share_pct: '50.00', publishable_channel_count: 2 },
      { state: 'MG', region: 'Sudeste', paid_registrations: 15, gross_value: '4500.00', registration_ticket: '300.00', event_share_pct: '15.00', commercial_paid_registrations: 10, commercial_share_of_state_pct: '66.67', leading_channel: 'MANIADECORRIDA', leading_channel_registrations: 6, leading_channel_state_share_pct: '40.00', publishable_channel_count: 1 },
      { state: 'PR', region: 'Sul', paid_registrations: 10, gross_value: '2900.00', registration_ticket: '290.00', event_share_pct: '10.00', commercial_paid_registrations: 0, commercial_share_of_state_pct: '0.00', leading_channel: null, leading_channel_registrations: null, leading_channel_state_share_pct: null, publishable_channel_count: 0 },
    ],
    channels: [
      { channel_name: 'ROADRUNNERS', channel_type: 'influenciador', slug: 'roadrunners', paid_registrations: 35, gross_value: '10300.00', registration_ticket: '294.29', valid_state_registrations: 35, valid_state_coverage_pct: '100.00', active_ufs: 12, active_regions: 5, leading_state: 'SC', leading_state_share_valid_pct: '42.86', top_3_state_share_valid_pct: '80.00', outside_south_share_valid_pct: '57.14', state_concentration_hhi: 0.3, reach_classification: 'Nacional', reach_rationale: '12 UFs e 5 regiões relevantes.', state_distribution: [
        { state: 'SC', region: 'Sul', paid_registrations: 15, share_valid_pct: '42.86', relevant: true },
        { state: 'SP', region: 'Sudeste', paid_registrations: 12, share_valid_pct: '34.29', relevant: true },
        { state: 'MG', region: 'Sudeste', paid_registrations: 4, share_valid_pct: '11.43', relevant: false },
        { state: 'PR', region: 'Sul', paid_registrations: 4, share_valid_pct: '11.43', relevant: false },
      ] },
      { channel_name: 'MANIADECORRIDA', channel_type: 'midia', slug: 'maniadecorrida', paid_registrations: 25, gross_value: '7750.00', registration_ticket: '310.00', valid_state_registrations: 25, valid_state_coverage_pct: '100.00', active_ufs: 10, active_regions: 4, leading_state: 'SP', leading_state_share_valid_pct: '72.00', top_3_state_share_valid_pct: '100.00', outside_south_share_valid_pct: '96.00', state_concentration_hhi: 0.6, reach_classification: 'Evidência insuficiente', reach_rationale: 'Base abaixo do corte.', state_distribution: [
        { state: 'SP', region: 'Sudeste', paid_registrations: 18, share_valid_pct: '72.00', relevant: true },
        { state: 'MG', region: 'Sudeste', paid_registrations: 6, share_valid_pct: '24.00', relevant: true },
        { state: 'SC', region: 'Sul', paid_registrations: 1, share_valid_pct: '4.00', relevant: false },
      ] },
      { channel_name: '<script>x</script>', channel_type: 'outro', slug: 'x', paid_registrations: 10, gross_value: '100.00', registration_ticket: '20.00', valid_state_registrations: 10, valid_state_coverage_pct: '100.00', active_ufs: 1, active_regions: 1, leading_state: 'SP', leading_state_share_valid_pct: '100.00', top_3_state_share_valid_pct: '100.00', outside_south_share_valid_pct: '100.00', state_concentration_hhi: 1, reach_classification: 'Evidência insuficiente', reach_rationale: 'Base baixa.', state_distribution: [] },
    ],
    state_channels: [
      { state: 'SP', region: 'Sudeste', channel_name: 'MANIADECORRIDA', channel_slug: 'maniadecorrida', paid_registrations: 18, gross_value: '5580.00', event_state_share_pct: '45.00', commercial_state_share_pct: '60.00', channel_valid_state_share_pct: '72.00' },
      { state: 'SP', region: 'Sudeste', channel_name: 'ROADRUNNERS', channel_slug: 'roadrunners', paid_registrations: 12, gross_value: '3600.00', event_state_share_pct: '30.00', commercial_state_share_pct: '40.00', channel_valid_state_share_pct: '34.29' },
      { state: 'SC', region: 'Sul', channel_name: 'ROADRUNNERS', channel_slug: 'roadrunners', paid_registrations: 15, gross_value: '4350.00', event_state_share_pct: '50.00', commercial_state_share_pct: '75.00', channel_valid_state_share_pct: '42.86' },
      { state: 'SC', region: 'Sul', channel_name: 'MANIADECORRIDA', channel_slug: 'maniadecorrida', paid_registrations: 5, gross_value: '1550.00', event_state_share_pct: '16.67', commercial_state_share_pct: '25.00', channel_valid_state_share_pct: '20.00' },
      { state: 'MG', region: 'Sudeste', channel_name: 'MANIADECORRIDA', channel_slug: 'maniadecorrida', paid_registrations: 6, gross_value: '1860.00', event_state_share_pct: '40.00', commercial_state_share_pct: '60.00', channel_valid_state_share_pct: '24.00' },
    ],
    state_modalities: [
      { state: 'SP', modality: '21K', paid_registrations: 25 },
      { state: 'SP', modality: '42K', paid_registrations: 15 },
      { state: 'SC', modality: '42K', paid_registrations: 20 },
      { state: 'SC', modality: '21K', paid_registrations: 10 },
    ],
    state_phases: [
      { state: 'SP', phase: 'Lançamento', paid_registrations: 22 },
      { state: 'SP', phase: 'Meio', paid_registrations: 18 },
      { state: 'SC', phase: 'Meio', paid_registrations: 30 },
    ],
    geography_benchmark: { p90_similarity_0_1: 0.7 },
    geography_pairs: [
      { left_channel: 'MANIADECORRIDA', right_channel: 'ROADRUNNERS', similarity_0_1: 0.81, left_coverage_pct: '100.00', right_coverage_pct: '100.00' },
    ],
    featured_pair: {
      left_channel: 'ROADRUNNERS',
      right_channel: 'MANIADECORRIDA',
      left_paid_registrations: 35,
      right_paid_registrations: 25,
      combined_paid_registrations: 60,
      combined_gross_value: '18050.00',
      geography_similarity_0_1: 0.81,
      geography_p90_similarity_0_1: 0.7,
      distribution_overlap_pct: '38.29',
      overlap_classification: 'Sobreposição forte',
      combined_relevant_states: ['MG', 'SC', 'SP'],
      shared_relevant_states: ['SP'],
      left_distinctive_states: ['SC'],
      right_distinctive_states: ['MG', 'SP'],
      state_comparison: [],
      interpretation: 'A semelhança não mede incrementalidade.',
    },
    privacy: { suppressed_state_channel_registrations: 4, state_channel_minimum_registrations: 5 },
  };
}

test('state selection returns complete totals and commercial channels in sales DESC order', () => {
  const selected = states.selectState(fixture(), 'SP');

  assert.equal(selected.state.state, 'SP');
  assert.deepEqual(selected.channels.map((row) => row.channel_name), ['MANIADECORRIDA', 'ROADRUNNERS']);
  assert.deepEqual(selected.modalities.map((row) => row.modality), ['21K', '42K']);
  assert.equal(selected.state.paid_registrations, 40);
});

test('partner comparison accepts one to three known slugs and exposes pair overlap', () => {
  const result = states.compareSelection(fixture(), ['roadrunners', 'maniadecorrida']);

  assert.deepEqual(result.channels.map((row) => row.channel_name), ['ROADRUNNERS', 'MANIADECORRIDA']);
  assert.equal(result.pairs[0].similarity_0_1, 0.81);
  assert.equal(result.pairs[0].classification, 'Sobreposição forte');
  assert.deepEqual(result.states.slice(0, 3).map((row) => row.state), ['SP', 'SC', 'MG']);
  assert.throws(() => states.compareSelection(fixture(), []), /pelo menos um canal/i);
  assert.throws(() => states.compareSelection(fixture(), ['missing']), /canal desconhecido/i);
  assert.throws(
    () => states.compareSelection(fixture(), ['roadrunners', 'maniadecorrida', 'x', 'quarto']),
    /até três canais/i,
  );
});

test('overview renderer exposes territorial strategy, fixed pair and safe channel names', () => {
  const root = { innerHTML: '' };

  states.render(root, fixture());

  assert.match(root.innerHTML, /id="states-overview"/);
  assert.match(root.innerHTML, /id="states-state"/);
  assert.match(root.innerHTML, /id="states-compare"/);
  assert.match(root.innerHTML, /ROADRUNNERS × MANIADECORRIDA/);
  assert.match(root.innerHTML, /Sobreposição forte/);
  assert.match(root.innerHTML, /Âncora nacional/);
  assert.match(root.innerHTML, /Prioridade nacional com ênfase estadual/);
  assert.doesNotMatch(root.innerHTML, /<script>x<\/script>/i);
  assert.match(root.innerHTML, /&lt;SCRIPT&gt;X&lt;\/SCRIPT&gt;/i);
});

test('state charts apply Top 10 plus Outros and preserve Outros last', () => {
  const data = fixture();
  data.state_channels = Array.from({ length: 12 }, (_, index) => ({
    state: 'SP',
    channel_name: `CANAL ${index + 1}`,
    channel_slug: `canal-${index + 1}`,
    paid_registrations: 20 - index,
    gross_value: `${(20 - index) * 300}.00`,
    event_state_share_pct: `${20 - index}.00`,
    commercial_state_share_pct: `${20 - index}.00`,
    channel_valid_state_share_pct: `${20 - index}.00`,
  }));
  const selected = states.selectState(data, 'SP');
  const root = { innerHTML: '' };

  states.renderStateDetail(root, selected);

  assert.equal((root.innerHTML.match(/>OUTROS<\/text>/g) || []).length, 1);
  assert.ok(root.innerHTML.indexOf('CANAL 10') < root.innerHTML.indexOf('OUTROS'));
});

test('share URL is deterministic and keeps the selected view', () => {
  assert.equal(
    states.buildShareUrl(
      'https://business.roadrunners.run/relatorios/maratona-floripa-2026/estados/?old=1',
      'compare',
      { channels: ['maniadecorrida', 'roadrunners', 'maniadecorrida'] },
    ),
    'https://business.roadrunners.run/relatorios/maratona-floripa-2026/estados/?visao=compare&canal=maniadecorrida&canal=roadrunners',
  );
});

test('shared state URLs restore only known views, states and partner slugs', () => {
  const data = fixture();

  assert.deepEqual(
    states.parseShareUrl(
      'https://business.roadrunners.run/relatorios/maratona-floripa-2026/estados/?visao=compare&canal=maniadecorrida&canal=missing&canal=roadrunners&canal=maniadecorrida',
      data,
    ),
    { view: 'compare', state: null, channels: ['maniadecorrida', 'roadrunners'] },
  );
  assert.deepEqual(
    states.parseShareUrl('https://business.roadrunners.run/relatorios/maratona-floripa-2026/estados/?visao=state&estado=sc', data),
    { view: 'state', state: 'SC', channels: [] },
  );
  assert.deepEqual(
    states.parseShareUrl('https://business.roadrunners.run/relatorios/maratona-floripa-2026/estados/?visao=unknown&estado=xx', data),
    { view: 'overview', state: null, channels: [] },
  );
});
