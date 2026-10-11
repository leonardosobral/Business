const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = path.join(__dirname,'../candidate/assets/js/openresults-estado-cidades.js');
const window = {};
if (fs.existsSync(source)) vm.runInNewContext(fs.readFileSync(source,'utf8'),{window,URL});
const city = window.OpenResultsEstadoCities || {};
const href = 'https://openresults.run/estado/ba/?cidade=salvador&filtro=maiores&distancia=5%2C21&tempo=0%2C6&rua=true&trail=true&cupom=true&badges=ouro&page=4&lastMonth=8';
test('city selection preserves every supported filter, without pagination',()=>{
 const url = new URL(city.buildUrl(href,'BA','feira-de-santana'),'https://openresults.run');
 assert.equal(url.pathname,'/estado/ba/'); assert.equal(url.searchParams.get('cidade'),'feira-de-santana');
 for(const [k,v] of Object.entries({filtro:'maiores',distancia:'5,21',tempo:'0,6',rua:'true',trail:'true',cupom:'true',badges:'ouro'})) assert.equal(url.searchParams.get(k),v);
 assert.equal(url.searchParams.has('page'),false); assert.equal(url.searchParams.has('lastMonth'),false);
});
test('all cities clears only city selection',()=>{
 const url = new URL(city.buildUrl(href,'BA',''),'https://openresults.run');
 assert.equal(url.searchParams.has('cidade'),false); assert.equal(url.searchParams.get('filtro'),'maiores');assert.equal(url.searchParams.get('cupom'),'true');
});
test('changing state discards the old city',()=>{
 const url = new URL(city.buildUrl(href,'SC',''),'https://openresults.run');
 assert.equal(url.pathname,'/estado/sc/');assert.equal(url.searchParams.has('cidade'),false);assert.equal(url.searchParams.get('distancia'),'5,21');
});
test('tabs preserve city and filters and replace their own mode',()=>{
 const url = new URL(city.buildTabUrl(href,'maratonas'),'https://openresults.run');
 assert.equal(url.searchParams.get('cidade'),'salvador');assert.equal(url.searchParams.get('filtro'),'maratonas');assert.equal(url.searchParams.get('cupom'),'true');
 assert.equal(new URL(city.buildTabUrl(href,''),'https://openresults.run').searchParams.has('filtro'),false);
});
test('invalid UF or injected city slug cannot create links',()=>{
 for(const [uf,slug] of [['XX','salvador'],['BA','../sp'],['BA','<script>'],['BA','a/b']])assert.equal(city.buildUrl(href,uf,slug),'');
});
test('search ignores accents, case, and repeated whitespace',()=>{
 assert.equal(city.matches('São José dos Campos','SAO JOSE'),true);
 assert.equal(city.matches('Feira de Santana','  feira   de  '),true);
 assert.equal(city.matches('Salvador','recife'),false);
});
test('pagination uses the state endpoint and retains city and modality',()=>{
 const url = new URL(city.buildApiUrl(href,'BA',2,'2026-09'),'https://openresults.run');
 assert.equal(url.pathname,'/api/eventos_por_estado.cfm');assert.equal(url.searchParams.get('tag'),'BA');assert.equal(url.searchParams.get('cidade'),'salvador');assert.equal(url.searchParams.get('page'),'2');assert.equal(url.searchParams.get('lastMonthKey'),'2026-09');assert.equal(url.searchParams.get('trail'),'true');assert.equal(url.searchParams.get('filtro'),'maiores');
});
