const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const dashboard = require('../../portal/seo/assets/domains.js');
const source = JSON.parse(fs.readFileSync(path.join(__dirname, '../analyses/seo_domains/2026-10-25T150300-0300.json'), 'utf8'));
const rows = source.domains.map(row => ({...row, metrics: Object.fromEntries(Object.entries(row.metrics).map(([key, m]) => [key, {
  value: m.available ? m.value : null, change: m.changeAvailable ? m.change : null
}]))}));
const sorted = (key, direction = 'desc', data = rows) => data.slice().sort((a, b) => dashboard.compare(a, b, key, direction));
const state = extra => ({search: '', group: 'all', trend: 'all', ...extra});

test('numeric sorting preserves 474.7K > 169.9K > 118.7K and ranks RR 17 of 27', () => {
  const ordered = sorted('traffic');
  assert.deepEqual(ordered.slice(0, 3).map(row => row.domain), ['focoradical.com.br', 'ticketsports.com.br', 'ativo.com']);
  assert.equal(ordered.findIndex(row => row.domain === 'roadrunners.run'), 16);
  assert.equal(ordered.length, 27);
});
test('ascending, domain and percent ordering use numbers rather than formatted text', () => {
  assert.equal(sorted('traffic', 'asc')[0].domain, 'corridanoar.com');
  assert.equal(sorted('domain', 'asc')[0].domain, 'ativo.com');
  assert.deepEqual(sorted('trafficChange').slice(0, 3).map(row => row.domain), ['portaldocorredor.com.br', 'roadrunners.run', 'suacorrida.com.br']);
});
test('measured zero remains distinct from missing values in both directions', () => {
  const data = [{domain:'a.br',metrics:{traffic:{value:null}}},{domain:'b.br',metrics:{traffic:{value:0}}},{domain:'c.br',metrics:{traffic:{value:10}}}];
  assert.deepEqual(sorted('traffic', 'asc', data).map(row => row.domain), ['b.br', 'c.br', 'a.br']);
  assert.deepEqual(sorted('traffic', 'desc', data).map(row => row.domain), ['c.br', 'b.br', 'a.br']);
  assert.equal(dashboard.numeric(''), null); assert.equal(dashboard.numeric('0'), 0);
  assert.equal(dashboard.numeric('Infinity'), null);
});
test('ties are stable and do not mutate the imported source', () => {
  const before = rows.map(row => row.domain);
  assert.deepEqual(sorted('keywords').filter(row => row.metrics.keywords.value === 1400).map(row => row.domain), ['portaldascorridas.com.br', 'suacorrida.com.br']);
  assert.deepEqual(rows.map(row => row.domain), before);
});
test('own and reference filters retain exactly the selected group', () => {
  assert.deepEqual(rows.filter(row => dashboard.matches(row, state({group:'own'}))).map(row => row.domain), ['roadrunners.run', 'openresults.run']);
  assert.equal(rows.filter(row => dashboard.matches(row, state({group:'reference'}))).length, 25);
});
test('traffic movement filters distinguish rise, fall, stable and unavailable', () => {
  for (const [trend, compare] of [['up', n => n > 0], ['down', n => n < 0], ['flat', n => n === 0]]) {
    const selected = rows.filter(row => dashboard.matches(row, state({trend})));
    assert.ok(selected.length > 0);
    assert.ok(selected.every(row => compare(row.metrics.traffic.change)));
  }
  const absent = {domain:'a.br',own:false,metrics:{traffic:{change:null}}};
  assert.equal(dashboard.matches(absent, state({trend:'unknown'})), true);
  assert.equal(dashboard.matches(absent, state({trend:'flat'})), false);
});
test('search is case insensitive and composes with filters', () => {
  assert.deepEqual(rows.filter(row => dashboard.matches(row, state({search:'ROADRUNNERS'}))).map(row => row.domain), ['roadrunners.run']);
  assert.equal(rows.filter(row => dashboard.matches(row, state({search:'roadrunners', group:'reference'}))).length, 0);
});
test('URL state is allowlisted and bounds free text', () => {
  assert.deepEqual(dashboard.readState(new URLSearchParams('dominio_ordem=__proto__&dominio_grupo=bad&dominio_sinal=bad&dominio_direcao=bad')), {...state(), key:'traffic', direction:'desc'});
  const valid = dashboard.readState(new URLSearchParams('dominio_ordem=trafficChange&dominio_grupo=own&dominio_sinal=up&dominio_direcao=asc&dominio_busca=' + 'a'.repeat(200)));
  assert.equal(valid.key, 'trafficChange'); assert.equal(valid.direction, 'asc'); assert.equal(valid.search.length, 100);
});
