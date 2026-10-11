const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const root=process.env.OR_HOME_CANDIDATE || path.resolve(__dirname,'../candidate');
const shared=path.resolve(__dirname,'../../../../../OpenResults/assets/js/openresults-estado-cidades.js');
const window={};
vm.runInNewContext(fs.readFileSync(shared,'utf8'),{window,URL});
const source=path.join(root,'assets/js/openresults-home-cidades.js');
if(fs.existsSync(source))vm.runInNewContext(fs.readFileSync(source,'utf8'),{window,URL});
const search=window.OpenResultsHomeCities || {};
const cities=[
 {name:'São José',uf:'SC',slug:'sao-jose',total:12},
 {name:'São José',uf:'SP',slug:'sao-jose',total:7},
 {name:'Feira de Santana',uf:'BA',slug:'feira-de-santana',total:73},
 {name:'Vila Antiga',uf:'MG',slug:'vila-antiga',total:1},
 {name:'Cidade inválida',uf:'XX',slug:'cidade-invalida',total:4},
 {name:'Injected',uf:'BA',slug:'a/b',total:3}
];
test('finds accented cities nationally and distinguishes homonymous cities by UF',()=>{
 assert.equal(typeof search.findCities,'function');
 const result=search.findCities(cities,'SAO JOSE',30);
 assert.equal(result.length,2);assert.equal(result[0].uf,'SC');assert.equal(result[1].uf,'SP');
 assert.equal(search.findCities(cities,'sao jose sp',30)[0].uf,'SP');
});
test('historical cities stay searchable without a recent event',()=>{
 assert.equal(typeof search.findCities,'function');
 assert.equal(search.findCities(cities,'vila antiga',30)[0].total,1);
 assert.equal(search.findCities(cities,'  FEIRA   DE ',30)[0].slug,'feira-de-santana');
});
test('search is bounded and invalid destinations are excluded',()=>{
 assert.equal(typeof search.findCities,'function');
 assert.equal(search.findCities(cities,'',30).length,4);
 assert.equal(search.findCities(cities,'',2).length,2);
 assert.equal(search.findCities(cities,'nao existe',30).length,0);
});
test('city destination uses its own state and clears stale pagination and city',()=>{
 assert.equal(typeof search.cityUrl,'function');
 const target=new URL(search.cityUrl('https://openresults.run/?cidade=salvador&page=5',cities[0]),'https://openresults.run');
 assert.equal(target.pathname,'/estado/sc/');assert.equal(target.searchParams.get('cidade'),'sao-jose');assert.equal(target.searchParams.has('page'),false);
 assert.equal(search.cityUrl('https://openresults.run/',cities[4]),'');
});
test('exact city matches appear before partial names even when results exceed the cap',()=>{
 assert.equal(typeof search.findCities,'function');
 const many=Array.from({length:35},(_,i)=>({name:'São José da Vila '+i,uf:'SP',slug:'sao-jose-da-vila-'+i,total:1}));
 many.push({name:'São José',uf:'SC',slug:'sao-jose',total:12});
 const result=search.findCities(many,'sao jose',30);
 assert.equal(result.length,30);assert.equal(result[0].slug,'sao-jose');assert.equal(result[0].uf,'SC');
});
test('home shortcuts include all modalities counted by the historical catalog',()=>{
 const url=new URL(search.cityUrl('https://openresults.run/',cities[2]),'https://openresults.run');
 assert.equal(url.searchParams.get('rua'),'true');assert.equal(url.searchParams.get('trail'),'true');
 const explicit=new URL(search.cityUrl('https://openresults.run/?rua=false&trail=true',cities[2]),'https://openresults.run');
 assert.equal(explicit.searchParams.get('rua'),'false');assert.equal(explicit.searchParams.get('trail'),'true');
});
