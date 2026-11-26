'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const W=__dirname,D=JSON.parse(fs.readFileSync(path.join(W,'data.json'),'utf8'));
const js=fs.readFileSync(path.join(W,'runtime/business/estudos/lancamento/maratonas-detalhado.js'),'utf8');
function render(data,year,source=js){
 const nodes=new Map();
 function node(id){if(!nodes.has(id))nodes.set(id,{innerHTML:'',textContent:'',value:'',hidden:false,dataset:{},listeners:new Map(),classList:{toggle(){}},setAttribute(){},addEventListener(event,fn){this.listeners.set(event,fn)}});return nodes.get(id)}
 node('study-data').textContent=JSON.stringify(data);node('race').value=String([...data.years[String(year)].races].sort((a,b)=>b.total-a.total)[0].id_evento);
 const window={location:{search:'?ano='+year,href:'https://example.invalid/?ano='+year},history:{replaceState(){}},Chart:null};
 const document={getElementById:node,querySelectorAll(){return []},querySelector(){return null},body:{dataset:{pressYear:String(year)}}};
 vm.runInNewContext(source,{document,window,location:window.location,URL,URLSearchParams,Intl,console},{timeout:10000});
 return {nodes,html:node('report').innerHTML,age:node('age-audit').innerHTML,detail:node('race-detail').innerHTML};
}
const outputs={};
for(const year of [2025,2026]){
 const r=render(D,year);outputs[year]={html_bytes:Buffer.byteLength(r.html),age_bytes:Buffer.byteLength(r.age),detail_bytes:Buffer.byteLength(r.detail)};
 for(const id of ['resumo','contexto','perfil-distancias','nova-york','pares','top10','todas-maratonas','tempos','cortes','grupos','podios','perfil','cobertura','fontes'])assert.ok(r.html.includes('id="'+id+'"'),year+' missing '+id);
 const Y=D.years[String(year)],total=Y.races.reduce((a,r)=>a+r.total,0),n=x=>x.toLocaleString('pt-BR');
 assert.ok(r.html.includes(n(total)));assert.ok(r.html.includes('Todas as '+n(Y.races.length)+' maratonas'));
 assert.equal((r.html.match(/data-event-id=/g)||[]).length,Y.races.length,'Full list omits/duplicates selected events');
 assert.ok(r.age.includes(n(D.notes[String(year)].profile_total)),'New age denominator absent');
 assert.ok(r.html.includes('congelamento '+n(D.context.run)),'Context provenance stale');
 assert.ok(r.detail.includes('congelamento '+D.runs['provas-'+year]),'Detail histogram source stale');
 if(year===2026){
  for(const id of ['boston','brasil-gigante','cenarios'])assert.ok(r.html.includes('id="'+id+'"'),id);
  assert.ok(r.html.includes('3.609 registros'),'Operational Floripa count stale');
  assert.ok(r.html.includes('1.562'),'Adoption result count stale');
  assert.ok(r.html.includes('180'),'Adoption recurrence stale');
  assert.ok(!r.age.includes('Diferença total de dois registros'));
  assert.ok(r.html.includes('3.592'),'Official Floripa lost');
 }else{
  assert.ok(!r.html.includes('id="boston"'));assert.ok(!r.html.includes('id="brasil-gigante"'));assert.ok(!r.html.includes('id="cenarios"'));
 }
 fs.writeFileSync(path.join(W,'rendered-'+year+'.html'),r.html+'\n'+r.age+'\n'+r.detail);
}
const press=fs.readFileSync(path.join(W,'runtime/portal/brasilquecorreprovas/imprensa/maratonas/index.cfm'),'utf8');
const match=press.match(/<script id="study-data" type="application\/json"><cfif VARIABLES.pressYear EQ '2025'>(.*?)<cfelse>(.*?)<\/cfif><\/script>/s);assert.ok(match);
const p25=JSON.parse(match[1]),p26=JSON.parse(match[2]);assert.deepEqual(Object.keys(p25.years),['2025']);assert.deepEqual(Object.keys(p26.years),['2026']);assert.equal(p25.boston,null);assert.ok(!('brasil_gigante'in p25));assert.equal(p26.pairs2025,null);assert.deepEqual(p25.years['2025'].races,D.years['2025'].races);assert.deepEqual(p26.years['2026'].races,D.years['2026'].races);
const pressjs=fs.readFileSync(path.join(W,'runtime/portal/brasilquecorreprovas/imprensa/maratonas/maratonas-detalhado.js'),'utf8');
for(const [year,payload]of[[2025,p25],[2026,p26]]){
 const r=render(payload,year,pressjs);assert.ok(r.html.includes('id="todas-maratonas"'));assert.ok(!r.html.includes('arquivo.cfm'));
}
const old=JSON.parse(fs.readFileSync(path.join(W,'baseline/data.json'),'utf8'));assert.deepEqual(D.boston,old.boston);assert.deepEqual(D.context.nyc,old.context.nyc);
for(const year of ['2025','2026']){
 const Y=D.years[year],selected=new Set(Y.selection.filter(r=>(r.decisao||'selecionada')==='selecionada').map(r=>r.id_evento));assert.deepEqual([...selected].sort(),Y.races.map(r=>r.id_evento).sort());
 const main=Y.series.find(s=>s.id==='maratonas_concluintes').values.map(v=>Number(v.value)).sort((a,b)=>b-a),detail=Y.races.map(r=>r.total).sort((a,b)=>b-a).slice(0,10);assert.deepEqual(main,detail,'Principal top10 differs from detailed selection');
}
const report={scope:'offline rendering and numerical reconciliation; no visual/browser/CF compilation claim',rendered:outputs,all_chapters_present:true,full_lists:true,principal_top10_matches:true,press_year_partition:true,boston_nyc_unchanged:true,source_runs:D.runs};
fs.writeFileSync(path.join(W,'validation.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
