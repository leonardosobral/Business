#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { readFile, writeFile, mkdir, mkdtemp, rm, lstat, realpath, open } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { writeReport, readReport } from './seo_report.mjs';

const SITE_IDS=new Set(['roadrunners','openresults']);
const FORBIDDEN=['/Users/Shared/Projects/RunnerHub/Business','/Users/Shared/Projects/RunnerHub/RoadRunners','/Users/Shared/Projects/RunnerHub/OpenResults','/var/www'];
const PILOT={limit:100,concurrency:2,timeoutMs:15000,maxSitemaps:100,maxDiscoveredUrls:100000,maxRunMs:600000,maxRps:1};
const sha=value=>createHash('sha256').update(value).digest('hex');

async function noSymlinks(target) {
  const parts=path.resolve(target).split(path.sep).filter(Boolean);
  let current=path.parse(path.resolve(target)).root;
  for(const part of parts){current=path.join(current,part);try{if((await lstat(current)).isSymbolicLink())throw new Error(`Caminho com link simbólico não permitido: ${current}`);}catch(error){if(error.code!=='ENOENT')throw error;}}
}

export async function validateReportRoot(root) {
  if(!root || !path.isAbsolute(root)) throw new Error('SEO_REPORT_ROOT deve ser caminho absoluto.');
  const resolved=path.resolve(root);
  if(resolved.split(path.sep).filter(Boolean).length<3 || FORBIDDEN.some(base=>resolved===base||resolved.startsWith(base+path.sep))) throw new Error('Relatórios devem ficar fora dos repositórios e do docroot, em diretório privado próprio.');
  // /tmp and /var are OS aliases on macOS. Resolve the existing prefix, then
  // enforce the same containment rules on the physical destination.
  let parent=resolved,tail=[];
  while(true){try{parent=await realpath(parent);break;}catch(error){if(error.code!=='ENOENT')throw error;tail.unshift(path.basename(parent));parent=path.dirname(parent);}}
  const physical=path.join(parent,...tail);
  if(FORBIDDEN.some(base=>physical===base||physical.startsWith(base+path.sep)))throw new Error('Destino físico dentro de repositório/docroot.');
  await noSymlinks(physical);
  return physical;
}

export async function runSite(site,options={}) {
  if(!site || !SITE_IDS.has(site.site_id)) throw new Error('site_id inválido.');
  options.signal?.throwIfAborted();
  const root=await validateReportRoot(options.reportRoot||process.env.SEO_REPORT_ROOT);
  await mkdir(root,{recursive:true,mode:0o700});
  const lockRoot=path.join(root,'.locks');await noSymlinks(lockRoot);await mkdir(lockRoot,{mode:0o700,recursive:true});
  const lockPath=path.join(lockRoot,`${site.site_id}.lock`);
  let lock;
  try{lock=await open(lockPath,'wx',0o600);}catch(error){if(error.code==='EEXIST')return {site_id:site.site_id,status:'already_running',exit_code:1};throw error;}
  let temporary,child;
  try{
    await lock.writeFile(JSON.stringify({pid:process.pid,started_at:new Date().toISOString()}));
    const cli=options.collectorCli||process.env.SEO_INVENTORY_CLI;
    if(!cli || !path.isAbsolute(cli))throw new Error('SEO_INVENTORY_CLI deve apontar para a CLI instalada, com caminho absoluto.');
    await lstat(cli);
    const limits={...PILOT,...options.limits};
    if(limits.limit>PILOT.limit || limits.maxRps>PILOT.maxRps || limits.concurrency>PILOT.concurrency || limits.maxRunMs>PILOT.maxRunMs || limits.maxSitemaps>PILOT.maxSitemaps || limits.maxDiscoveredUrls>PILOT.maxDiscoveredUrls)throw new Error('Limites excedem o orçamento autorizado para o piloto.');
    for(const [key,value] of Object.entries(limits))if(!Number.isFinite(value)||value<=0)throw new Error(`Limite inválido: ${key}`);
    temporary=await mkdtemp(path.join(tmpdir(),`seo-${site.site_id}-`));
    const json=path.join(temporary,'run.json'),csv=path.join(temporary,'inventory.csv'),strategic=path.join(temporary,'strategic.json'),recheck=path.join(temporary,'recheck.json');
    await writeFile(strategic,JSON.stringify(site.strategic_urls||[]),{mode:0o600});
    const pending=[];
    const pointerPath=path.join(root,site.site_id,'latest-complete.json');
    await noSymlinks(pointerPath);
    let pointer;
    try{pointer=JSON.parse(await readFile(pointerPath,'utf8'));}catch(error){if(error.code!=='ENOENT')throw error;}
    if(pointer){
      if(!/^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$/.test(pointer.run_id)||pointer.run_id.includes('..'))throw new Error('Ponteiro de execução inválido.');
      const directory=path.join(root,site.site_id,pointer.run_id),previous=await readReport(directory);
      if(sha(await readFile(path.join(directory,'manifest.json')))!==pointer.manifest_sha256)throw new Error('Integridade do ponteiro de execução inválida.');
      const comparison=JSON.parse(await readFile(path.join(directory,'comparison.json'),'utf8'));
      for(const finding of [...previous.findings,...comparison.not_rechecked])if(new URL(finding.source_url).host===new URL(site.base_url).host)pending.push(finding.source_url);
    }
    await writeFile(recheck,JSON.stringify([...new Set(pending)]),{mode:0o600});
    const args=[cli,'--base',site.base_url,'--sitemap',site.sitemap_url,'--site-id',site.site_id,'--audit','--json-output',json,'--output',csv,'--strategic-urls',strategic,'--recheck-urls',recheck];
    for(const [key,flag] of Object.entries({limit:'--limit',concurrency:'--concurrency',timeoutMs:'--timeout-ms',maxSitemaps:'--max-sitemaps',maxDiscoveredUrls:'--max-discovered-urls',maxRunMs:'--max-run-ms',maxRps:'--max-rps'}))args.push(flag,String(limits[key]));
    let stderr='',killTimer,hardTimer;
    const forward=()=>child?.kill('SIGTERM');
    const result=await new Promise((resolve,reject)=>{
      child=spawn(process.execPath,args,{stdio:['ignore','ignore','pipe'],shell:false});
      child.stderr.on('data',buffer=>{stderr=(stderr+buffer.toString()).slice(-20000);});
      killTimer=setTimeout(()=>{forward();hardTimer=setTimeout(()=>child.kill('SIGKILL'),10000);},limits.maxRunMs+10000);
      options.signal?.addEventListener('abort',forward,{once:true});
      child.on('error',reject);child.on('close',(code,signal)=>resolve({code,signal}));
    }).finally(()=>{clearTimeout(killTimer);clearTimeout(hardTimer);options.signal?.removeEventListener('abort',forward);});
    let run;
    try{run=JSON.parse(await readFile(json,'utf8'));}
    catch(error){
      const now=new Date().toISOString();
      run={schema_version:1,rules_version:'1',collector_version:'unavailable',collector_hash:sha(await readFile(cli)),site_id:site.site_id,run_id:now.replace(/[.:]/g,'-')+'-failed',base_url:site.base_url,sitemap_url:site.sitemap_url,started_at:now,finished_at:now,mode:'audit',scope:'sample',completion:'failed',discovery_complete:false,exit_code:1,config_hash:sha(JSON.stringify({site,limits})),selection_hash:sha('[]'),selected_urls:[],counts:{discovered:0,selected:0,inspected:0,duplicates:0,errors:0,warnings:0},limits,sitemaps:[],errors:[{url:site.sitemap_url,code:'COLLECTOR_FAILED',message:`Coletor sem relatório final; exit=${result.code}, sinal=${result.signal||'nenhum'}. ${stderr}`}],observations:[],findings:[]};
      try{
        const lines=(await readFile(json+'.observations.jsonl','utf8')).split('\n');
        for(const line of lines){
          if(!line.trim())continue;
          try{const observation=JSON.parse(line);if(typeof observation.source_url!=='string')throw new Error('Observação inválida.');run.observations.push(observation);}
          catch{run.errors.push({url:site.sitemap_url,code:'TRUNCATED_OBSERVATIONS',message:'Prefixo válido recuperado; cauda incompleta das observações foi descartada.'});break;}
        }
        if(run.observations.length){run.completion='partial';run.counts.inspected=run.observations.filter(o=>!o.skip_reason).length;}
      }catch(error){if(error.code!=='ENOENT')run.errors.push({url:site.sitemap_url,code:'OBSERVATIONS_UNREADABLE',message:error.message});}
    }
    if(run.site_id!==site.site_id)throw new Error('Relatório do coletor pertence a outro site.');
    if(run.exit_code!==result.code || result.signal){run.completion='partial';run.exit_code=1;run.errors.push({url:site.sitemap_url,code:'EXIT_MISMATCH',message:'Estado do processo não corresponde ao relatório final.'});}
    const report=await writeReport(run,root);
    await readReport(report.run_dir);
    return {site_id:site.site_id,run_id:run.run_id,completion:run.completion,exit_code:run.exit_code,...report};
  }finally{
    await lock.close();await rm(lockPath,{force:true});
    if(temporary)await rm(temporary,{recursive:true,force:true});
  }
}

async function main(argv){
  const siteId=argv[0];if(argv.length!==1 || !SITE_IDS.has(siteId))throw new Error('Uso: node seo_run.mjs roadrunners|openresults; configure SEO_INVENTORY_CLI e SEO_REPORT_ROOT.');
  const config=JSON.parse(await readFile(new URL('../analyses/seo_monitoramento/sites.json',import.meta.url),'utf8'));
  const site=config.sites.find(s=>s.site_id===siteId);if(!site)throw new Error('Site não configurado.');
  const controller=new AbortController(),stop=()=>controller.abort();
  process.once('SIGINT',stop);process.once('SIGTERM',stop);
  try{const result=await runSite(site,{signal:controller.signal});process.stdout.write(JSON.stringify(result,null,2)+'\n');return result.exit_code;}
  finally{process.off('SIGINT',stop);process.off('SIGTERM',stop);}
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))main(process.argv.slice(2)).then(code=>{process.exitCode=code;}).catch(error=>{process.stderr.write(`SEO: ${error.message}\n`);process.exitCode=1;});
