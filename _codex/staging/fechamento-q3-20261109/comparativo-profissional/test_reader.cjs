const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const root=path.resolve(__dirname,'../../../..');
const A=require(path.join(root,'estudos/leitor/dados.js'));
const G=require(path.join(root,'estudos/leitor/graficos.js'));

async function renderReader(dir,payload){
  const elements=new Map();
  const element=key=>{if(!elements.has(key))elements.set(key,{dataset:{},setAttribute(){},matches(){return false;},remove(){},insertAdjacentHTML(){},innerHTML:'',textContent:''});return elements.get(key);};
  const document={body:{dataset:{endpoint:'dados.cfm'}},getElementById:element,querySelector:element,querySelectorAll:()=>[],addEventListener(){}};
  const window={EstudoData:A,EstudoCharts:{...G,mount(){}}};
  const context=vm.createContext({window,document,URL,location:{href:'https://example.test/leitor/?ano=2026',hash:''},fetch:async()=>({ok:true,json:async()=>payload}),Intl,console});
  vm.runInContext(fs.readFileSync(path.join(dir,'parcial.js'),'utf8'),context);
  vm.runInContext(fs.readFileSync(path.join(root,'estudos/leitor/estudo.js'),'utf8').replace('}catch(error){','}catch(error){console.error(error);'),context);
  await new Promise(setImmediate);
  const html=element('content').innerHTML;
  assert.ok(!html.includes('A edição está indisponível.'),'The complete reader must remain available');
  return html;
}
function sections(html){return new Map([...html.matchAll(/<section\b[^>]*id="([^"]+)"[\s\S]*?<\/section>/g)].map(m=>[m[1],m[0]]));}
function normal(html){return html.replace(/\b(?:chart|plot)-\d+/g,'ID');}
(async()=>{
  const before=JSON.parse(fs.readFileSync(path.join(__dirname,'before-payload.json')));
  const after=JSON.parse(fs.readFileSync(path.join(__dirname,'after-payload.json')));
  const baseline=await renderReader(path.join(__dirname,'local-before/estudos/leitor'),before);
  const candidate=await renderReader(path.join(root,'estudos/leitor'),after);
  fs.writeFileSync(path.join(__dirname,'before-render.html'),baseline);
  fs.writeFileSync(path.join(__dirname,'after-render.html'),candidate);
  const originalSections=sections(baseline),newSections=sections(candidate);
  assert.equal(originalSections.size,37);assert.equal(newSections.size,37);
  for(const [id,html] of originalSections)if(id!=='calendario')assert.equal(normal(newSections.get(id)),normal(html),'Unrelated page changed: '+id);
  assert.equal(after.meta.comparativo_pareado.status,'disponivel');
  assert.equal(after.meta.comparativo_pareado.execucao,231);
  assert.equal(after.meta.comparativo_pareado.narrativa.execucao,239);
  const originalSeries=new Set(before.series.map(s=>s.id));
  assert.deepEqual(after.series.filter(s=>originalSeries.has(s.id)),before.series);
  assert.deepEqual(after.comparacoes.filter(c=>originalSeries.has(c.serie)),before.comparacoes);
  const calendar=newSections.get('calendario');
  for(const text of ['comparativo-pareado','+2,1%','+33,9%','608','1.185.401','1.210.676','5.895','7.891','não são pessoas únicas','captura','inativos ou cancelados'])assert.ok(calendar.includes(text),'Missing visible evidence: '+text);
  const csv=A.csv(A.exportAll(after,'atual'));
  assert.ok(csv.includes('2.132189866551487640047545100'),'CSV must preserve the unrounded source value');
  assert.ok(csv.includes('comparativo_pareadas_amostra'));assert.ok(csv.includes('execução congelada 231'));
  assert.ok(!after.series.some(s=>/^(inscricoes_|cna_|performance_42k_)/.test(s.id)));
  for(const mutate of [d=>{delete d.meta.comparativo_pareado;},d=>{delete d.meta.comparativo_pareado.narrativa;},d=>{d.meta.comparativo_pareado.metodologia='';},d=>{d.meta.comparativo_pareado.status='em_revisao';},d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_concluintes').atual.valor=null;},d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_amostra').atual.valor='';},d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_variacao').atual.valor='inválido';}]){
    const missing=structuredClone(after);mutate(missing);const html=await renderReader(path.join(root,'estudos/leitor'),missing);
    assert.ok(html.includes('Comparativo das mesmas provas em revisão'));
    assert.ok(html.includes('+33,9%'),'Calendar stays available when pairing is missing');
    assert.ok(!sections(html).get('calendario').includes('+2,1%'),'Missing pairing must not appear as a real value');
    assert.equal(sections(html).size,37);
  }
  const absent=await renderReader(path.join(root,'estudos/leitor'),before);
  assert.ok(absent.includes('Comparativo das mesmas provas em revisão'),'New assets must degrade visibly with the old payload');
  console.log('PAIRED_READER_PASS: real frozen JSON, exact CSV, missing/invalid data, 37 pages, 36 unrelated snapshots unchanged');
})().catch(e=>{console.error(e);process.exitCode=1;});
