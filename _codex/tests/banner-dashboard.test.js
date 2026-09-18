const test = require('node:test');
const assert = require('node:assert/strict');
const dashboard = require('../../assets/js/portal-banner-dashboard.js');

test('HOUSE chart uses dated real traffic only, without monetary datasets', () => {
  const config = dashboard.buildChartConfig([{date:'2026-09-16', impressions:100, clicks:3}]);
  assert.deepEqual(config.data.labels, ['16/09']);
  assert.deepEqual(config.data.datasets.map(d => d.label), ['Impressões', 'Cliques']);
  assert.deepEqual(config.data.datasets.map(d => d.data), [[100], [3]]);
  assert.equal(config.options.scales.money, undefined);
  assert.equal(config.options.maintainAspectRatio, false);
});
test('empty chart is supported and shared ads config remains unchanged', () => {
  assert.deepEqual(dashboard.buildChartConfig([]).data.labels, []);
  const ads = require('../../assets/js/ads-performance-dashboard.js');
  assert.equal(ads.buildChartConfig([]).data.datasets.length, 3);
});
