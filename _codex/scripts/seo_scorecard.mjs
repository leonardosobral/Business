#!/usr/bin/env node
import {readFile,writeFile,mkdir,rename,lstat} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash,randomUUID} from 'node:crypto';
import {readReport} from './seo_report.mjs';
import {validateReportRoot} from './seo_run.mjs';
export const METHOD='technical-checks-v1';
const sha=v=>createHash('sha256').update(v).digest('hex');
const labels={roadrunners:'Road Runners',openresults:'Open Results'};
const number=v=>v.toLocaleString('pt-BR',{minimumFractionDigits:1,maximumFractionDigits:1});
const date=v=>new Intl.DateTimeFormat('pt-BR',{timeZone:'America/Sao_Paulo',dateStyle:'short',timeStyle:'short'}).format(new Date(v))+' (Brasília)';
const states={pass:['Verificado','✓'],warning:['Atenção','!'],error:['Erro','×'],unknown:['Não medido','—']};
const defs=[
 ['http','Resposta HTTP final 2xx',15,'Resposta observada; falhas de rede explícitas contam como erro.'],
 ['direct','URLs sem redirecionamento',5,'Redirecionamentos merecem revisão; podem ser intencionais.'],
 ['https','Entrega por HTTPS',5,'Esquema da URL final observado; não é uma auditoria completa de TLS.'],
 ['title','Título presente',10,'Presença de título no HTML; não mede qualidade nem unicidade no site.'],
 ['h1','Título principal presente',10,'Verifica presença de H1 no HTML utilizável.'],
 ['canonical','Canonical único e válido',15,'Declaração observada; não comprova o canonical escolhido pelo Google.'],
 ['alignment','Canonical alinhado à URL',15,'Diferenças da URL de origem pedem revisão de intenção.'],
 ['index','Diretivas sem noindex para Googlebot',10,'Somente diretivas genéricas e Googlebot observadas; não comprova indexação.'],
 ['crawl','Googlebot permitido no robots.txt',10,'Permissão observada; não comprova intenção da política nem indexação.'],
 ['sitemaps','Sitemaps descobertos e XML validado',5,'Exige descoberta completa, contagem de XML processado e respostas válidas do coletor.'],
 ['hierarchy','Hierarquia de títulos para revisão',0,'Múltiplos H1 pedem revisão editorial; este item não penaliza a nota nem prova penalidade Google.'],
 ['description','Meta description',0,'Não coletada nesta auditoria.'],
 ['hreflang','Hreflang',0,'Não coletado na coorte da auditoria; verificações direcionadas ficam na fila.'],
 ['structured','Dados estruturados',0,'Não coletados nesta auditoria.'],
 ['cwv','Core Web Vitals',0,'Sem medição de experiência real ou laboratório nesta auditoria.'],
 ['google','Indexação e tráfego Google',0,'Sem dados de Search Console ou Analytics nesta auditoria.']
];
export function safeCaseUrl(value){
 if(typeof value!=='string'||/[\s\u0000-\u001f\u007f\\]/u.test(value)||/%(?:0[0-9a-f]|1[0-9a-f]|7f|5c)/i.test(value))return null;
 try{const u=new URL(value);return u.protocol==='https:'&&['roadrunners.run','openresults.run'].includes(u.hostname)&&!u.username&&!u.password&&!u.port?u.href:null;}catch{return null;}
}
function usable(o){return o.html_evaluation==='evaluated'&&!o.error&&!o.error_code&&!o.skip_reason&&o.status>=200&&o.status<300&&/^(text\/html|application\/xhtml\+xml)(?:\s*;|\s*$)/i.test(o.content_type||'');}
function relevantDirectives(o){
 if(typeof o.meta_robots!=='string'||typeof o.x_robots_tag!=='string'||!o.robots_by_agent||!o.robots_header_by_agent)return null;
 const relevant=['googlebot','robots','*',''];
 for(const map of [o.robots_by_agent,o.robots_header_by_agent]){
  if(typeof map!=='object'||Array.isArray(map))return null;
  for(const [agent,value]of Object.entries(map))if(relevant.includes(agent.toLowerCase())&&(!Array.isArray(value)||value.some(v=>typeof v!=='string')))return null;
 }
 const values=[o.meta_robots];
 // Raw X-Robots-Tag may target another crawler; use parsed agent-specific maps.
 if(!o.x_robots_tag.includes(':'))values.push(o.x_robots_tag);
 for(const map of [o.robots_by_agent,o.robots_header_by_agent])for(const [agent,v]of Object.entries(map))if(['googlebot','robots','*',''].includes(agent.toLowerCase()))values.push(...(Array.isArray(v)?v:[v]));
 return values.join(',');
}
export function scoreRun(run){
 const criteria=defs.map(([id,label,weight,note])=>({id,label,weight,status:'unknown',statusLabel:states.unknown[0],icon:states.unknown[1],pass:0,warning:0,error:0,unknown:0,total:0,known:0,partial:false,note,cases:{pass:[],warning:[],error:[],unknown:[]}}));
 const map=Object.fromEntries(criteria.map(c=>[c.id,c]));
 // Preserve the identity of evaluated evidence, not just aggregate coverage.
 // Outcomes are excluded so repairs on the same URLs remain comparable.
 const coverageMask=[];
 const add=(id,status,url)=>{const c=map[id];coverageMask.push([id,typeof url==='string'?url:'',status!=='unknown']);c[status]++;c.total++;const safe=safeCaseUrl(url);if(safe&&c.cases[status].length<3&&!c.cases[status].includes(safe))c.cases[status].push(safe);};
 for(const o of run.observations||[]){
 const html=usable(o),directives=relevantDirectives(o);
 add('http',o.error||o.error_code?'error':!Number.isInteger(o.status)||o.status<=0?'unknown':o.status>=200&&o.status<300?'pass':o.status>=400?'error':'warning',o.source_url);
 add('direct',!Number.isInteger(o.status)||o.status<=0||typeof o.redirected!=='boolean'?'unknown':o.redirected?'warning':'pass',o.source_url);
 add('https',!o.final_url?'unknown':/^https:\/\//i.test(o.final_url)?'pass':'error',o.source_url);
 add('title',!html||typeof o.title!=='string'?'unknown':o.title.trim()?'pass':'warning',o.source_url);
 add('h1',!html||!Number.isInteger(o.h1_count)||o.h1_count<0?'unknown':o.h1_count>0?'pass':'warning',o.source_url);
 add('hierarchy',!html||!Number.isInteger(o.h1_count)||o.h1_count<0?'unknown':o.h1_count===1?'pass':'warning',o.source_url);
 add('canonical',!html||!Number.isInteger(o.canonical_count)||typeof o.canonical_invalid!=='boolean'?'unknown':o.canonical_invalid?'error':o.canonical_count===1&&o.canonical_url?'pass':'warning',o.source_url);
 add('alignment',!html||!o.canonical_url?'unknown':o.canonical_url===o.source_url?'pass':'warning',o.source_url);
 add('index',!html||directives===null?'unknown':/(?:^|[\s,;])(noindex|none)(?:$|[\s,;])/i.test(directives)?'warning':'pass',o.source_url);
 add('crawl',typeof o.robots_policy?.googlebot?.allowed!=='boolean'?'unknown':o.robots_policy.googlebot.allowed?'pass':'warning',o.source_url);
 }
 const errors=run.errors||[];
 for(const sm of run.sitemaps||[])add('sitemaps',sm.error||sm.error_code||(sm.status>=400)||errors.some(e=>e.url===sm.url)?'error':run.discovery_complete!==true||errors.length||!Number.isInteger(sm.count)||sm.count<0||!Number.isInteger(sm.status)||sm.status<200||sm.status>=300?'unknown':'pass',sm.url);
 for(const c of criteria){
 if(!c.total){c.total=1;c.unknown=1;}
 c.known=c.total-c.unknown;c.partial=c.unknown>0&&c.known>0;
 c.status=c.error?'error':c.warning?'warning':c.pass?'pass':'unknown';
 [c.statusLabel,c.icon]=states[c.status];
 }
 const scored=criteria.filter(c=>c.weight>0),knownWeight=scored.filter(c=>c.known>0).reduce((n,c)=>n+c.weight,0);
 const score=knownWeight?100*scored.reduce((n,c)=>n+c.weight*({pass:1,warning:.5,error:0,unknown:0}[c.status]),0)/knownWeight:null;
 const coverage=scored.reduce((n,c)=>n+c.weight*c.known/c.total,0);
 const coverageIdentity=sha(JSON.stringify(coverageMask.sort((a,b)=>JSON.stringify(a).localeCompare(JSON.stringify(b)))));
 return {coverageIdentity,id:run.site_id,label:labels[run.site_id],runId:run.run_id,auditAt:run.finished_at,auditLabel:date(run.finished_at),scopeLabel:run.scope==='sample'?'Amostra de páginas':'Escopo completo',discovered:run.counts.discovered,inspected:run.counts.inspected,discoveryComplete:run.discovery_complete,operationalErrors:(run.errors||[]).length,pageErrors:(run.findings||[]).filter(f=>f.severity==='error').length,warnings:(run.findings||[]).filter(f=>f.severity==='warning').length,coverageNote:`Foram analisadas ${run.counts.inspected.toLocaleString('pt-BR')} de ${run.counts.discovered.toLocaleString('pt-BR')} URLs descobertas nos sitemaps. ${run.scope==='sample'?'A amostra não representa todas as páginas do site.':'O escopo cobre as URLs selecionadas nesta auditoria.'}`,score,scoreLabel:score===null?'—':number(score),coverageLabel:number(coverage)+'%',counts:Object.fromEntries(Object.keys(states).map(s=>[s,criteria.filter(c=>c.status===s).length])),criteria,history:[],historyNote:'Base inicial calculada com o método atual sobre a auditoria indicada. Correções direcionadas posteriores ficam na fila e não alteram esta nota. Cobertura de evidências não representa a fração do site auditada.'};
}
function compatibility(run,site){return sha(JSON.stringify({method:METHOD,collectorHash:run.collector_hash,collectorVersion:run.collector_version,mode:run.mode,config:run.config_hash,rules:run.rules_version,schema:run.schema_version,scope:run.scope,cohort:[...run.selected_urls].sort(),observed:[...run.observations.map(o=>o.source_url)].sort(),coverageIdentity:site.coverageIdentity,coverage:site.criteria.map(c=>[c.id,c.known,c.total])}));}
export function appendHistory(history,run,site){
 if(!Array.isArray(history))throw new Error('Histórico privado inválido.');
 const existing=history.find(h=>h.runId===run.run_id&&h.methodVersion===METHOD);
 const signature=compatibility(run,site);
 if(existing){if(existing.signature!==signature||existing.score!==site.score)throw new Error('Execução histórica mudou sem novo identificador.');return history;}
 const previous=history.at(-1);
 if(previous&&Date.parse(run.finished_at)<Date.parse(previous.auditAt))throw new Error('Auditoria anterior ao último ponto; ordem cronológica inválida.');
 const comparable=!!previous&&previous.signature===signature&&previous.methodVersion===METHOD;
 const delta=comparable&&site.score!==null&&previous.score!==null?site.score-previous.score:null;
 return [...history,{methodVersion:METHOD,signature,runId:run.run_id,auditAt:run.finished_at,auditLabel:site.auditLabel,score:site.score,scoreLabel:site.scoreLabel,comparable,deltaLabel:!previous?'Base inicial':!comparable?'Amostra, método ou cobertura diferente':delta===null?'Sem nota comparável':`${delta>0?'+':''}${number(delta)} pontos`}];
}
export async function loadLatest(root,site){
 if(!Object.hasOwn(labels,site))throw new Error('Site inválido.');
 const pointerPath=path.join(root,site,'latest-complete.json');if((await lstat(pointerPath)).isSymbolicLink())throw new Error('Ponteiro simbólico não permitido.');
 const pointer=JSON.parse(await readFile(pointerPath,'utf8'));
 if(!/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(pointer.run_id)||pointer.run_id.includes('..'))throw new Error('Ponteiro inválido.');
 const dir=path.join(root,site,pointer.run_id),run=await readReport(dir);
 if(sha(await readFile(path.join(dir,'manifest.json')))!==pointer.manifest_sha256)throw new Error('Integridade: hash do ponteiro divergente.');
 if(run.site_id!==site||run.run_id!==pointer.run_id)throw new Error('Integridade: identidade da execução difere do ponteiro.');
 if(run.completion!=='complete')throw new Error('Ponteiro exige execução completa.');
 return run;
}
export function renderCfml(snapshot){
 const encoded=Buffer.from(JSON.stringify(snapshot),'utf8').toString('base64');
 return `<cfinclude template="../../includes/backend/require_admin.cfm"/>\n<cfprocessingdirective pageencoding="utf-8"/>\n<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>\n    <cfheader statuscode="403" statustext="Forbidden"/>\n    <cfabort/>\n</cfif>\n<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>\n    <cfheader statuscode="405" statustext="Method Not Allowed"/>\n    <cfheader name="Allow" value="GET"/>\n    <cfabort/>\n</cfif>\n<!--- Gerado por seo_scorecard.mjs. Dados auditados; aplicar escape na view. --->\n<cfscript>\nVARIABLES.seoScoreSnapshot = deserializeJSON(charsetEncode(binaryDecode("${encoded}", "base64"), "utf-8"));\n</cfscript>\n`;
}
async function atomic(file,data){const temp=file+'.'+randomUUID()+'.tmp';await writeFile(temp,data,{mode:0o600,flag:'wx'});await rename(temp,file);}
export async function generate({reportsRoot='/Users/Shared/RunnerHubReports/seo',output,historyRoot}){
 const privateRoot=await validateReportRoot(historyRoot);await mkdir(privateRoot,{recursive:true,mode:0o700});
 const snapshot={methodVersion:METHOD,generatedAt:new Date().toISOString(),methodLabel:'Nota técnica interna',formula:'100 × soma(peso × resultado de cada critério) ÷ soma dos pesos avaliados. Verificado = 1; atenção = 0,5; erro = 0; não medido fica fora.',methodNote:'Heurística interna, não é nota WooRank nem avaliação do Google. Cada critério usa o pior resultado observado. Itens informativos têm peso zero. A cobertura representa campos avaliados na amostra; correções posteriores não reescrevem a auditoria.',sites:[]};
 const writes=[];
 for(const id of Object.keys(labels)){
 const run=await loadLatest(reportsRoot,id),site=scoreRun(run),file=path.join(privateRoot,id+'.json');let history=[];
 try{if((await lstat(file)).isSymbolicLink())throw new Error('Histórico simbólico não permitido.');history=JSON.parse(await readFile(file,'utf8'));}catch(e){if(e.code!=='ENOENT')throw e;}
 history=appendHistory(history,run,site);site.history=history.map(({runId,auditAt,auditLabel,scoreLabel,comparable,deltaLabel})=>({runId,auditAt,auditLabel,scoreLabel,comparable,deltaLabel}));writes.push([file,JSON.stringify(history,null,2)+'\n']);snapshot.sites.push(site);
 }
 for(const [file,data]of writes)await atomic(file,data);
 await atomic(output,renderCfml(snapshot));return snapshot;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 const args=process.argv.slice(2),opts={reportsRoot:'/Users/Shared/RunnerHubReports/seo',output:path.resolve('portal/includes/seo_score_data.cfm'),historyRoot:'/Users/Shared/RunnerHubReports/seo/score-history'};
 const names={'--reports-root':'reportsRoot','--output':'output','--history-root':'historyRoot'};
 try{for(let i=0;i<args.length;i+=2){if(!names[args[i]]||!args[i+1])throw new Error('Argumentos inválidos.');opts[names[args[i]]]=args[i+1];}const s=await generate(opts);console.log(JSON.stringify({methodVersion:s.methodVersion,sites:s.sites.map(({id,scoreLabel,coverageLabel,counts})=>({id,scoreLabel,coverageLabel,counts}))}));}catch(e){console.error(e.message);process.exitCode=1;}
}
