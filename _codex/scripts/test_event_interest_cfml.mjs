import assert from 'node:assert/strict';
import {copyFileSync,mkdirSync,mkdtempSync,readFileSync,writeFileSync,rmSync,existsSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const scratch=mkdtempSync(resolve(tmpdir(),'event-interest-cfml-'));
const output=mkdtempSync(resolve(tmpdir(),'event-interest-preview-'));
const event={content_id:'1',event_name:'Prova <script>alert(1)</script>',city:'Florianópolis',uf:'SC',tag:'prova',event_date:'30/09/2026',event_year:2026,catalog_missing:false,active:true,upcoming:true,missing_fields:['Imagem','Percursos'],pageviews:120,visitors:70,sessions:90,recent_visitors:20,previous_visitors:10,growth_pct:100,last_view:'14/09 12:00'};
const data={meta:{since:'08/09/2026 00:00',until:'14/09/2026 12:00',recent:'08/09/2026 00:00 a 14/09/2026 12:00',previous:'01/09/2026 00:00 a 07/09/2026 12:00',trend_days:7,comparison_ready:true,first_observed:'08/09/2026 20:53',last_received:'14/09/2026 11:59'},summary:{pageviews:120,visitors:70,sessions:90,events:1,gaps:1,hot:1},ranking:[event],hot:[event],gaps:[event],daily:[{day:'13/09',pageviews:120}],sources:[{source:'openresults',medium:'referral',campaign:'salvar',pageviews:120,visitors:70,sessions:90}],devices:[{device:'MOBILE',pageviews:120}],regions:[{uf:'SP',pageviews:120}],flows:[]};
const agendaData={meta:{since:'08/09/2026 00:00',until:'14/09/2026 12:00',days:7},summary:{events:51,athletes:31,gaps:12},ranking:[{...event,athletes:8,pageviews:0,visitors:0,sessions:0}]};
data.campaigns=structuredClone(data.sources);
data.summary.flow_transitions=24;
data.regions=[{uf:'SP',pageviews:90},{uf:'Não identificada',pageviews:30}];
data.devices=[{device:'MOBILE',pageviews:90},{device:'DESKTOP',pageviews:30}];
data.flows=[{from_event:'Anterior <script>',to_event:'Seguinte',transitions:6,sessions:3}];
try{
 for(const f of ['portal/includes/event_interest_backend.cfm','portal/eventos-analytics/home.cfm','includes/backend/require_admin.cfm','portal/audiencia/queries/event_interest.sql','portal/audiencia/queries/event_agenda.sql']){mkdirSync(dirname(resolve(scratch,f)),{recursive:true});copyFileSync(resolve(root,f),resolve(scratch,f));}
 const p=resolve(scratch,'portal/includes/event_interest_backend.cfm');
 for(const f of ['portal/audiencia/queries/event_agenda_ranking.sql','portal/eventos-analytics/agenda.cfm'])if(existsSync(resolve(root,f)))copyFileSync(resolve(root,f),resolve(scratch,f));
 const backend=readFileSync(p,'utf8');
 writeFileSync(p,backend.replace(/\bqueryExecute\(/g,'eventFixtureQuery('));
 let count=0;
 const modes=['publico','publico-empty','publico-unknown','agenda-direct-forbidden','agenda','agenda-monthly','agenda-empty','agenda-unavailable','agenda-invalid','agenda-forbidden','ranking','alta','alta-partial','alta-monthly','alta-new','alta-declining','cadastro','origem','campanha','metodo','empty','error','agenda-error','forbidden'];
 for(const mode of modes){
  const report=structuredClone(data);
  const agendaView=mode==='agenda'||mode.startsWith('agenda-')&&mode!=='agenda-error';
  const alta=mode.startsWith('alta');const expectedDays=mode.endsWith('monthly')?30:7;
  const agendaReport=structuredClone(agendaData);agendaReport.meta.days=expectedDays;
  if(mode==='agenda-empty'){agendaReport.ranking=[];agendaReport.summary={events:0,athletes:0,gaps:0};}
  if(mode==='agenda-invalid')agendaReport.summary.athletes=-1;
  writeFileSync(resolve(scratch,'agenda-fixture.json'),JSON.stringify(agendaReport));
  if(mode==='alta-monthly')report.meta.trend_days=30;
  if(mode==='alta-partial'){report.meta.comparison_ready=false;report.hot[0].growth_pct=null;}
  if(mode==='alta-new'){report.hot[0].previous_visitors=0;report.hot[0].growth_pct=null;}
  if(mode==='alta-declining')report.hot[0].growth_pct=-25;
  if(mode==='empty'||mode==='publico-empty'){for(const k of ['ranking','hot','gaps','daily','sources','campaigns','devices','regions','flows'])report[k]=[];for(const k in report.summary)report.summary[k]=0;}
  if(mode==='publico-unknown')report.regions=[{uf:'Não identificada',pageviews:120}];
  writeFileSync(resolve(scratch,'fixture.json'),JSON.stringify(report));
  writeFileSync(resolve(scratch,'render.cfm'),`<cfprocessingdirective pageencoding="utf-8"><cfscript>
VARIABLES.businessEffectiveIsAdmin=${!mode.endsWith('forbidden')};URL.aba='${agendaView?'agenda':alta?'alta':mode.startsWith('publico')?'publico':mode}';URL.dias='${mode.endsWith('monthly')?90:mode==='alta-partial'||mode==='agenda'?1:7}';URL.internos='0';URL.termo='';URL.fase='all';
function eventFixtureQuery(sql,params={},options={}){
 if(${mode.endsWith('forbidden')})throw(message='DATABASE BEFORE AUTH');
 if(options.datasource!='runnerhub')throw(message='WRONG DSN');
 if(find('to_regclass',sql))return queryNew('ready','bit',[[true]]);
 if(find('tb_evento_corridas_checkin',sql)){
  if(${agendaView}){
   if('${mode}'=='agenda-unavailable')throw(message='PRIVATE AGENDA FAILURE');
   if(params.days.value!=${expectedDays} OR params.include_internal.value OR params.uf.value!='' OR params.term.value!='' OR params.event_id.value!='' OR params.offset.value!=0)throw(message='WRONG FILTERS');
   return queryNew('report','varchar',[[fileRead('agenda-fixture.json','UTF-8')]]);
  }
  if('${mode}'=='agenda-error')throw(message='AGENDA UNAVAILABLE');
  return queryNew('report','varchar',[[serializeJSON([{content_id='1',athletes=8,saved=6,registered=4}])]]);
 }
 if('${mode}'=='error')throw(message='PRIVATE SQL FAILURE');
 if(params.days.value!=${expectedDays} OR params.include_internal.value)throw(message='WRONG FILTERS');
 return queryNew('report','varchar',[[fileRead('fixture.json','UTF-8')]]);
}
</cfscript><!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/assets/css/business-ui.css"></head><body data-mdb-theme="dark" class="bg-dark-subtle"><main class="container-fluid p-4"><cfinclude template="portal/eventos-analytics/${mode==='agenda-direct-forbidden'?'agenda':'home'}.cfm"></main></body></html>`);
  const r=spawnSync(process.env.AUDIENCE_CFML_JAVA_RUNTIME||'/usr/bin/java',['-Dfile.encoding=UTF-8','-cp',process.env.AUDIENCE_CFML_BOX_RUNTIME||'/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home='+(process.env.AUDIENCE_CFML_COMMANDBOX_HOME||'/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox'),'execute','render.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
  assert.equal(r.status,0,r.stdout+r.stderr);assert.ok(!/Error \(|Error executing|DATABASE BEFORE AUTH|WRONG (DSN|FILTERS)/.test(r.stdout),r.stdout.slice(-4500));
  const html=r.stdout;writeFileSync(resolve(output,mode+'.html'),html);
  if(mode.endsWith('forbidden')){assert.match(html,/Acesso restrito/);continue;}
  if(agendaView){
   assert.match(html,/<a[^>]*aria-current="page"[^>]*>Agenda<\/a>/,'agenda tab must be selected, not silently fall back to audience ranking');
   assert.ok(!html.includes('PRIVATE AGENDA'));
   if(mode==='agenda-unavailable'||mode==='agenda-invalid'){assert.match(html,/Agenda indisponível/);assert.ok(!html.includes('data-metric="agenda-athletes"'));continue;}
   assert.match(html,new RegExp('data-metric="agenda-events">\\s*'+(mode==='agenda-empty'?0:51)+'<'));
   assert.match(html,new RegExp('data-metric="agenda-athletes">\\s*'+(mode==='agenda-empty'?0:31)+'<'));
   assert.ok(!html.includes('data-metric="pageviews"'),'audience totals cannot masquerade as agenda headlines');
   assert.ok(!html.includes('<script>alert(1)</script>'));
   if(mode==='agenda-empty'){assert.match(html,/Nenhuma prova/);continue;}
   assert.match(html,/Prova &lt;script&gt;/);assert.match(html,/8 atletas na agenda/);
   assert.match(html,new RegExp('Aberturas[^<]*'+expectedDays+' dias'));
   assert.match(html,/Próxima/,'pagination uses all eligible agenda events');
   assert.ok(!/quero ir| inscritos/.test(html),'agenda display must not imply registration');
   continue;
  }
  if(mode==='error'){assert.match(html,/indisponível/);assert.ok(!html.includes('data-metric="pageviews"'));assert.ok(!html.includes('PRIVATE SQL'));continue;}
  if(mode==='empty'){assert.match(html,/Nenhuma prova/);continue;}
  if(mode==='publico-empty'){assert.match(html,/Nenhuma abertura/);assert.ok(!/NaN|Infinity/.test(html));continue;}
  if(mode.startsWith('publico')){
   const table=id=>html.match(new RegExp('<table[^>]*id="'+id+'"[\\s\\S]*?</table>'))?.[0]||'';
   assert.match(table('ei-regions'),mode==='publico-unknown'?/100,0%/:/75,0%/,'UF shares must use all filtered openings, including unknown');
   assert.match(table('ei-devices'),/75,0%/,'device shares must be rendered beside counts');
   assert.match(table('ei-flows'),/25,0%/,'flow share must use 24 total transitions, not only the six displayed');
   assert.match(table('ei-flows'),/3,3%/,'three sessions out of 90 filtered sessions');
   assert.ok(!table('ei-flows').includes('Anterior <script>'),'flow names are escaped');
  }
  assert.match(html,/data-metric="pageviews">\s*120</);assert.ok(!html.includes('<script>alert(1)</script>'));count+=2;
  assert.match(html,/data-metric="highlights">\s*1</,'a populated highlight count does not depend on historical comparison');
  if(mode==='ranking'){assert.match(html,/Prova &lt;script&gt;/);assert.match(html,/8 atletas na agenda/);assert.ok(!/6 quero ir|4 inscritos/.test(html));}
  if(mode==='origem') {assert.match(html,/openresults/);assert.ok(!html.includes('<th>Campanha</th>'),'origin view has no campaign grouping');assert.match(html,/Uma linha por origem/);}
  if(mode==='campanha'){assert.match(html,/<a[^>]*aria-current="page"[^>]*>Campanha<\/a>/);assert.match(html,/<th>Campanha<\/th>/);assert.match(html,/salvar/);}
  if(mode==='alta')assert.match(html,/100/);
  if(mode==='alta-partial'){assert.match(html,/Destaque no período/);assert.ok(!html.includes('vs. 10 visitantes'),'unknown historical baseline must not appear as a measured comparison');}
  if(mode==='alta-monthly')assert.match(html,/Últimos 30 dias/);
  if(mode==='alta-new')assert.match(html,/Novo interesse/);
  if(mode==='alta-declining')assert.match(html,/-25,0%/);
  if(mode==='agenda-error')assert.match(html,/Agenda indisponível/);
 }
 mkdirSync(resolve(output,'assets/css'),{recursive:true});
 for(const f of ['mdb.min.css','business-ui.css'])copyFileSync(resolve(root,'assets/css',f),resolve(output,'assets/css',f));
 console.log('Event interest CFML: '+modes.length+' rendered scenarios verified. Preview: '+output);
}finally{rmSync(scratch,{recursive:true,force:true});}
