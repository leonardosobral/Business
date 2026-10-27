const test = require('node:test');
const assert = require('node:assert/strict');
const chart = require('../../administracao/usuarios/assets/acquisition.js');

const rows = Array.from({length:365}, (_, index) => ({
  day:new Date(Date.UTC(2024,0,1+index)).toISOString().slice(0,10),
  count:index === 364 ? 3 : (index === 358 ? 2 : 0)
}));
test('seleção conserva datas e muda todos os totais por período', () => {
  for (const days of [7,30,90,365]) {
    const selected=chart.select(rows,days);
    assert.equal(selected.length,days);
    assert.equal(selected.at(-1).day,'2024-12-30');
    const metrics=chart.summarize(selected);
    assert.equal(metrics.total,5);
    assert.equal(metrics.average,5/days);
    assert.equal(metrics.peak,3);
    assert.equal(metrics.peakDay,'2024-12-30');
  }
});
test('controles inválidos retornam ao padrão de 30 dias', () => {
  assert.equal(chart.select(rows,'30').length,30);
  for(const invalid of [0,8,366,'7 OR 1=1',[],null]) assert.equal(chart.select(rows,invalid).length,30);
});
test('dias zerados não ganham pico nem eixo indefinido', () => {
  const selected=rows.slice(0,7);
  assert.deepEqual(chart.summarize(selected),{total:0,average:0,peak:0,peakDay:''});
  const geometry=chart.geometry(selected,320,240);
  assert.ok(geometry.maximum >= 1);
  assert.ok(geometry.points.every(point => Number.isFinite(point.x) && point.y === geometry.bottom));
});
test('geometria respeita magnitude, eixo zero e área responsiva', () => {
  const selected=[{day:'2024-02-28',count:0},{day:'2024-02-29',count:10},{day:'2024-03-01',count:5}];
  const geometry=chart.geometry(selected,360,240);
  assert.equal(geometry.points[0].y,geometry.bottom);
  assert.ok(geometry.points[1].y < geometry.points[2].y);
  assert.ok(geometry.points[2].y < geometry.points[0].y);
  assert.ok(geometry.points.every(point => point.x >= geometry.left && point.x <= geometry.right));
});
