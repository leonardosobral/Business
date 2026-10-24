import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,existsSync,mkdtempSync,mkdirSync,copyFileSync,rmSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {tmpdir} from 'node:os';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const view=resolve(root,'includes/estrutura/home_admin_decision_view.cfm');
assert.ok(existsSync(view),'Decision view must expose real KPIs and actionable-only alerts');
const scratch=mkdtempSync(resolve(tmpdir(),'business-home-view-'));
const output=resolve(root,'_codex/staging/business-home-20261024/render');mkdirSync(output,{recursive:true});
let count=0;
const check=(condition,message)=>{assert.ok(condition,message);count++;};
try{
 mkdirSync(resolve(scratch,'includes/estrutura'),{recursive:true});mkdirSync(resolve(scratch,'includes/backend'),{recursive:true});mkdirSync(resolve(scratch,'_codex/tests/business-home'),{recursive:true});
 copyFileSync(resolve(root,'includes/backend/require_admin.cfm'),resolve(scratch,'includes/backend/require_admin.cfm'));
 copyFileSync(view,resolve(scratch,'includes/estrutura/home_admin_decision_view.cfm'));
 copyFileSync(resolve(root,'_codex/tests/business-home/fixture.cfm'),resolve(scratch,'_codex/tests/business-home/fixture.cfm'));
 for(const scenario of ['pending','clear','unavailable','unsafe','tabs','split-comparison']) {
  const r=spawnSync('/usr/bin/java',['-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/business-home-commandbox','execute','_codex/tests/business-home/fixture.cfm'],{cwd:scratch,encoding:'utf8',env:{...process.env,BUSINESS_HOME_SCENARIO:scenario}});
  assert.equal(r.status,0,r.stdout+r.stderr);const html=r.stdout;
  check(!/Error \(|lucee\.runtime\.exp|Expression Exception/.test(html),'CFML renders without runtime errors');
  writeFileSync(resolve(output,scenario+'.html'),html);
  check(!html.includes('Fila sem pendência'),'zero operational queue is absent');
  check(!/<table\b/.test(html),'work tables are outside the home');
  check(html.includes('data-business-home-kpi="audience"'),'site audience is the primary KPI');
  check(html.includes('/portal/banners/?section=performance'),'banners have their own detail destination');
  if(scenario==='pending') {
   check(html.includes('Contas para aprovar'),'positive approval queue stays visible');
   check(html.includes('Sem base anterior'),'zero baseline cannot produce infinite growth');
  }
  if(scenario==='clear') {
   check(!html.includes('Contas para aprovar'),'healthy queues do not occupy rows');
   check(html.includes('Nenhuma pendência'),'valid all-clear is distinguished');
  }
  if(scenario==='unavailable') {
   check(html.includes('Não consultado'),'failed source remains visible');
   check(html.includes('Dados indisponíveis'),'missing audience is not displayed as measured zero');
   check(!html.includes('Nenhuma pendência'),'partial failure cannot claim all-clear');
  }
  if(scenario==='unsafe') check(!html.includes('<script>alert(1)</script>'),'labels and area params cannot inject HTML');
  if(scenario==='split-comparison') {
   const interaction=html.split('data-business-home-kpi="interactions"')[1].split('</article>')[0];
   const audience=html.split('data-business-home-kpi="audience"')[1].split('</article>')[0];
   check(interaction.includes('Histórico insuficiente'),'interaction growth requires its own instrumentation history');
   check(/20[,.]0%/.test(audience),'visitor comparison remains available independently');
  }
  if(scenario==='tabs') {
   check(/home_area=contas/.test(html),'selected tab survives period changes');
   check(/id="home-area-contas"[^>]*data-home-panel="contas"(?![^>]*hidden)/.test(html),'server selects requested panel without JS');
   check(html.includes('periodo=30'),'period is preserved in area links');
  }
 }
 console.log(`PASS Business home view: ${count} rendered behavior checks across six scenarios. ${output}`);
}finally{rmSync(scratch,{recursive:true,force:true});}
