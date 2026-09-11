const {test} = require('node:test');
const assert = require('node:assert/strict');
const {dailyChart, regionChart, percentage} = require('../../assets/js/audience-dashboard.js');

test('daily comparison preserves observed dates and never fills unmeasured days with zero', () => {
  const model = dailyChart([{day:'2026-09-01',pageviews:8,slot_views:3},{day:'2026-09-07',pageviews:4,slot_views:1}]);
  assert.equal(model.type, 'bar');
  assert.deepEqual(model.data.labels, ['01/09','07/09']);
  assert.deepEqual(model.data.datasets[0].data, [8,4]);
  assert.deepEqual(model.data.datasets[1].data, [3,1]);
});
test('eight observed days use a zero-based trend and preserve numeric counts from Adobe JSON', () => {
  const model = dailyChart(Array.from({length:8},(_,i)=>({DAY:`2026-09-${String(i+1).padStart(2,'0')}`,PAGEVIEWS:String(i+1),SLOT_VIEWS:0})));
  assert.equal(model.type,'line');
  assert.deepEqual(model.data.datasets[0].data,[1,2,3,4,5,6,7,8]);
  assert.equal(model.options.scales.y.beginAtZero,true);
});
test('regional ranking orders by visible positions, names unknown and does not sum unique visitors', () => {
  const model = regionChart([{audience_uf:'SP',slot_views:2,visitors:500},{audience_uf:'--',slot_views:4},{audience_uf:'SC',slot_views:8}]);
  assert.deepEqual(model.data.labels,['SC','Desconhecida','SP']);
  assert.deepEqual(model.data.datasets[0].data,[8,4,2]);
  assert.equal(model.options.indexAxis,'y');
  assert.equal(model.options.scales.x.beginAtZero,true);
});
test('no visible inventory has no pretend regional chart; top six never modifies source rows', () => {
  assert.equal(regionChart([{audience_uf:'SC',slot_views:0}]),null);
  assert.equal(dailyChart([]),null);
  const rows = Array.from({length:8},(_,i)=>({audience_uf:String(i),slot_views:i}));
  const copy = JSON.stringify(rows);
  assert.equal(regionChart(rows).data.labels.length,6);
  assert.equal(JSON.stringify(rows),copy);
});
test('a rate with no denominator is unknown, not 0%; numeric inputs remain finite', () => {
  assert.equal(percentage(0,0),null);
  assert.equal(percentage(1,4),25);
  assert.equal(percentage('2','4'),50);
  assert.equal(percentage(4,NaN),null);
});
