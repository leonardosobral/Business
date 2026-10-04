const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = process.env.RR_CITY_SOURCE_ROOT || path.resolve(__dirname, '../candidate');
function moduleUnderTest() {
  const file = path.join(root, 'assets/js/runnerhub-estado-cidades.js');
  assert.ok(fs.existsSync(file), 'City navigation feature is missing');
  const context = {window: {}, URL, console};
  vm.runInNewContext(fs.readFileSync(file, 'utf8'), context);
  return context.window.RunnerHubEstadoCities;
}
test('city selection keeps the live calendar filters and discards unrelated routing parameters', () => {
  const city = moduleUnderTest();
  assert.equal(city.buildUrl('https://roadrunners.run/estado/ba/?distancia=5%2C21&tempo=1%2C3&rua=false&trail=true&cupom=true&badges=pcd&nacional=true&internacional=false&cidade=outra&tag=SC&page=8&utm_source=mail', 'BA', 'salvador'),
    '/estado/ba/salvador/?distancia=5%2C21&tempo=1%2C3&rua=false&trail=true&nacional=true&internacional=false&cupom=true&badges=pcd');
});
test('all cities removes the city path but keeps distance and period', () => {
  assert.equal(moduleUnderTest().buildUrl('https://roadrunners.run/estado/ba/feira-de-santana/?tempo=0%2C2&distancia=10%2C42', 'BA', ''), '/estado/ba/?distancia=10%2C42&tempo=0%2C2');
});
test('changing state removes the old city and preserves modality', () => {
  assert.equal(moduleUnderTest().buildUrl('https://roadrunners.run/estado/ba/salvador/?trail=false', 'SC', ''), '/estado/sc/?trail=false');
});
test('invalid state and unsafe city path cannot create navigation targets', () => {
  const city = moduleUnderTest();
  for (const [uf, slug] of [['XX','salvador'],['BA','../login'],['BA','https://other.test'],['BA','foo/bar']]) {
    assert.equal(city.buildUrl('https://roadrunners.run/estado/ba/',uf,slug), '');
  }
});
test('search matches accents, case and extra whitespace', () => {
  const city = moduleUnderTest();
  assert.equal(city.matches('São José da Vitória', '  SAO JOSE  '), true);
  assert.equal(city.matches('Vitória da Conquista', 'conquista'), true);
  assert.equal(city.matches('Salvador', 'feira'), false);
});
test('late counts for previous filters cannot reactivate a city in the current selection', () => {
  const city=moduleUnderTest();
  const defaults={distancia:'1,42',tempo:'0,12',rua:true,trail:true,nacional:true,internacional:false,cupom:false,badges:''};
  assert.equal(city.acceptsFilters('https://roadrunners.run/estado/ba/?cupom=true',defaults),false);
  assert.equal(city.acceptsFilters('https://roadrunners.run/estado/ba/?cupom=true',{...defaults,cupom:true}),true);
  assert.equal(city.acceptsFilters('https://roadrunners.run/estado/ba/?tempo=0%2C1',{...defaults,tempo:'0,12'}),false);
  assert.equal(city.acceptsFilters('https://roadrunners.run/estado/ba/?distancia=5%2C21',{...defaults,distancia:'1,42'}),false);
});
test('equivalent booleans and default filters accept fresh counts', () => {
  const city=moduleUnderTest();
  assert.equal(city.acceptsFilters('https://roadrunners.run/estado/ba/?cupom=YES&rua=0',{distancia:'1,42',tempo:'0,12',rua:false,trail:true,nacional:true,internacional:false,cupom:true,badges:''}),true);
  assert.equal(city.acceptsFilters('https://roadrunners.run/estado/ba/',null),false);
});
test('distance from the city URL remains active when another asynchronous filter changes', () => {
  const source=fs.readFileSync(path.join(root,'estado/index.cfm'),'utf8');
  const call=source.match(/window\.RunnerHubEstadoFiltersController = window\.RunnerHubEventFilters\.init\(\{[\s\S]*?\}\);/)[0];
  const context={window:{RunnerHubEstadoFiltersBootstrap:{distanciaSelecionada:[5,21],periodoMesesSelecionado:[0,12]},RunnerHubEventFilters:{init:config=>config}}};
  vm.runInNewContext(call,context);
  const config=context.window.RunnerHubEstadoFiltersController;
  assert.equal(config.buscaDistanciaInicio,5);
  assert.equal(config.buscaDistanciaFim,21);
  assert.equal(config.buscaDistanciaAtiva,true);
});
