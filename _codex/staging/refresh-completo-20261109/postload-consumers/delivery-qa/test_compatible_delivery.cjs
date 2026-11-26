// Local Node VM QA for real SELECT-only delivery snapshots. No browser/DB/API calls.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const crypto=require('node:crypto');
const root=path.resolve(__dirname,'../../../../..');
const A=require(path.join(root,'estudos/leitor/dados.js'));
const G=require(path.join(root,'estudos/leitor/graficos.js'));
const compatible=path.join(__dirname,'../candidates-42-352/compatible/candidate/business/estudos/leitor');
const cfc=fs.readFileSync(path.join(compatible,'../includes/StudyAccess.cfc'),'utf8');
const sha=text=>crypto.createHash('sha256').update(text).digest('hex');

async function renderReader(dir,payload){
  const elements=new Map();
  const element=key=>{if(!elements.has(key))elements.set(key,{dataset:{},setAttribute(){},matches(){return false;},remove(){},insertAdjacentHTML(){},innerHTML:'',textContent:''});return elements.get(key);};
  const document={body:{dataset:{endpoint:'dados.cfm'}},getElementById:element,querySelector:element,querySelectorAll:()=>[],addEventListener(){}};
  const errors=[];
  const quietConsole={...console,error:(...args)=>errors.push(args.map(String).join(' '))};
  const window={EstudoData:A,EstudoCharts:{...G,mount(){}}};
  const context=vm.createContext({window,document,URL,location:{href:'https://example.test/leitor/?ano=2026',hash:''},fetch:async()=>({ok:true,json:async()=>payload}),Intl,console:quietConsole});
  vm.runInContext(fs.readFileSync(path.join(dir,'parcial.js'),'utf8'),context,{filename:'parcial.js'});
  vm.runInContext(fs.readFileSync(path.join(root,'estudos/leitor/estudo.js'),'utf8').replace('}catch(error){','}catch(error){console.error(error);'),context,{filename:'estudo.js'});
  await new Promise(setImmediate);
  const html=element('content').innerHTML;
  assert.ok(!html.includes('A edição está indisponível.'),'The reader must remain available');
  assert.equal(errors.length,0,errors.join('\n'));
  return html;
}
function sections(html){return new Map([...html.matchAll(/<section\b[^>]*id="([^"]+)"[\s\S]*?<\/section>/g)].map(m=>[m[1],m[0]]));}
function normal(html){return html.replace(/\b(?:chart|plot)-\d+/g,'ID');}
function highlight(calendar){const match=calendar.match(/<article class="insight-card paired-highlight">[\s\S]*?<\/article>/);assert.ok(match,'Pair highlight exists');return match[0];}
function read(pub){const p=path.join(__dirname,`compatible-publication-${pub}.json`);assert.ok(fs.existsSync(p),`Real read-only delivery snapshot is required: ${p}`);return JSON.parse(fs.readFileSync(p));}

(async()=>{
  const old=read(41),fresh=read(42);
  assert.equal(old.meta.escopo_editorial.publicacao_fonte,41);
  assert.equal(fresh.meta.escopo_editorial.publicacao_fonte,42);
  for(const [payload,source,narrative,sample] of [[old,231,239,608],[fresh,329,352,615]]){
    const meta=payload.meta.comparativo_pareado;
    assert.equal(meta.status,'disponivel');assert.equal(meta.celula,387);
    assert.equal(meta.execucao,source);assert.equal(meta.narrativa.execucao,narrative);
    assert.equal(meta.coorte.pares,sample);
    assert.ok(!payload.series.some(s=>/^(inscricoes_|cna_|performance_42k_)/.test(s.id)));
  }
  // The SQL pair identity is enforced server-side; the client deliberately accepts two run IDs.
  assert.ok(cfc.includes('(41::bigint,239::bigint,5::integer)'));
  assert.ok(cfc.includes('(42::bigint,352::bigint,7::integer)'));
  assert.ok(cfc.includes('JOIN paired_public n ON n.publication_id=p.publicacao_id'));
  assert.ok(!cfc.includes('FROM paired_source p CROSS JOIN paired_public n'));
  const oldHTML=await renderReader(compatible,old);
  const freshHTML=await renderReader(compatible,fresh);
  assert.equal(sections(oldHTML).size,37);assert.equal(sections(freshHTML).size,37);
  const previousAssetsHTML=await renderReader(path.join(root,'estudos/leitor'),old);
  assert.equal(normal(oldHTML),normal(previousAssetsHTML),'Old41 delivery must remain identical with compatible assets');
  const calendar=sections(freshHTML).get('calendario');
  for(const text of ['comparativo-pareado','+2,2%','+38,7%','615','1.191.628','1.218.094','não são pessoas únicas','captura','inativos ou cancelados'])assert.ok(calendar.includes(text),'Visible evidence missing: '+text);
  assert.ok(calendar.includes('execução congelada 329'));
  assert.ok(calendar.includes('execução 352'));
  const rate=fresh.comparacoes.find(c=>c.serie==='comparativo_pareadas_variacao').atual.valor;
  assert.equal(String(rate),'2.220995142779458018777672200');
  const csv=A.csv(A.exportAll(fresh,'atual'));
  assert.ok(csv.includes(String(rate)),'CSV preserves the full unrounded decimal string');
  assert.ok(csv.includes('comparativo_pareadas_amostra'));
  assert.ok(csv.includes('execução congelada 329'));
  const cases=[
    ['missing_metadata',d=>{delete d.meta.comparativo_pareado;}],
    ['missing_narrative',d=>{delete d.meta.comparativo_pareado.narrativa;}],
    ['unapproved_narrative',d=>{d.meta.comparativo_pareado.narrativa.execucao=999999;}],
    ['string_narrative_id',d=>{d.meta.comparativo_pareado.narrativa.execucao='352';}],
    ['empty_methodology',d=>{d.meta.comparativo_pareado.metodologia='';}],
    ['review_status',d=>{d.meta.comparativo_pareado.status='em_revisao';}],
    ['source_id_wrong_type',d=>{d.meta.comparativo_pareado.execucao='329';}],
    ['revision_not_integer',d=>{d.meta.comparativo_pareado.revisao=1.5;}],
    ['cohort_count_mismatch',d=>{d.meta.comparativo_pareado.coorte.concluintes_2025+=1;}],
    ['missing_count',d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_concluintes').atual.valor=null;}],
    ['empty_sample',d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_amostra').atual.valor='';}],
    ['invalid_rate',d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_variacao').atual.valor='inválido';}],
    ['noninteger_sample',d=>{d.comparacoes.find(c=>c.serie==='comparativo_pareadas_amostra').atual.valor=615.5;}]
  ];
  for(const [name,mutate] of cases){
    const data=structuredClone(fresh);mutate(data);
    const html=await renderReader(compatible,data),parts=sections(html),cal=parts.get('calendario'),pair=highlight(cal);
    assert.equal(parts.size,37,name+': complete reader remains');
    assert.ok(pair.includes('Comparativo das mesmas provas em revisão'),name+': visible review state');
    assert.ok(pair.includes('<strong>??</strong>'),name+': missing is not zero');
    assert.ok(!pair.includes('+2,2%'),name+': no stale paired result');
    assert.ok(cal.includes('+38,7%'),name+': registered calendar stays readable');
  }
  fs.writeFileSync(path.join(__dirname,'compatible-publication-41-render.html'),oldHTML);
  fs.writeFileSync(path.join(__dirname,'compatible-publication-42-render.html'),freshHTML);
  fs.writeFileSync(path.join(__dirname,'compatible-publication-42-export.csv'),csv);
  const report={passed:true,scope:'Local Node VM using actual read-only SQL delivery snapshots; no auth identity or pointers modified',
    pages:{publication41:37,publication42:37},old:{publication:41,source:231,narrative:239,pairs:608},fresh:{publication:42,source:329,narrative:352,pairs:615,paired_rate_exact:String(rate),paired_display:'+2,2%',calendar_display:'+38,7%'},
    old_assets_identical:true,negative_cases:cases.map(([name])=>name),sql_pair_join_checked:true,
    artifacts:{old_render_sha256:sha(oldHTML),fresh_render_sha256:sha(freshHTML),fresh_csv_sha256:sha(csv)},
    limits:['No browser/layout checks','No live CFML compilation','Actual SQL execution/capture is owned by parent; this harness only reads its JSON artifacts']};
  fs.writeFileSync(path.join(__dirname,'vm-verification.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report,null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
