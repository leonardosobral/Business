#!/usr/bin/env node
// Visual QA of the actual Adobe-rendered report using local Business assets.
// Source HTML must come from the isolated native HTTP harness, never production data.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {readFileSync,mkdirSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createServer} from 'node:http';
const require=createRequire(import.meta.url);
const {chromium}=require('playwright');
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const input=process.argv[2];
assert.ok(input && /rr-audience-native-[a-zA-Z0-9]+\/business-report\.html$/.test(input),'Pass guarded native fixture HTML');
let html=readFileSync(input,'utf8');
assert.ok(html.includes('data-fixture-run-id=') && html.includes('id="audience-test-summary"'),'Only isolated fixture output');
html=html.replace('</head>','<link rel="stylesheet" href="/assets/css/mdb.min.css"/><link rel="stylesheet" href="/assets/css/business-ui.css"/></head>')
  .replace('<body ','<body data-mdb-theme="dark" style="background:#20242a;padding:20px" ')
  .replace('</body>','<script src="/assets/js/mdb.umd.min.js"></script></body>');
const allowed=new Set(['/assets/css/mdb.min.css','/assets/css/business-ui.css','/assets/css/audience-dashboard.css','/assets/js/mdb.umd.min.js','/assets/js/audience-dashboard.js']);
const server=createServer((req,res)=>{
  const path=new URL(req.url,'http://localhost').pathname;
  if(path==='/'){res.setHeader('Content-Type','text/html; charset=utf-8');res.end(html);}
  else if(allowed.has(path)){res.setHeader('Content-Type',path.endsWith('.js')?'text/javascript':'text/css');res.end(readFileSync(resolve(root,'.'+path)));}
  else{res.statusCode=404;res.end();}
});
await new Promise(done=>server.listen(0,'127.0.0.1',done));
const browser=await chromium.launch({channel:'chrome',headless:true});
const output=resolve(dirname(input),'dashboard-visual');mkdirSync(output,{recursive:true});
try{
 for(const width of [1440,390]){
  const page=await browser.newPage({viewport:{width,height:1000}});const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto(`http://127.0.0.1:${server.address().port}/`,{waitUntil:'networkidle'});
  await page.locator('h1').waitFor();
  assert.equal(await page.getByText('Política de retenção: 90 dias · operação da base inteira',{exact:true}).count(),1,'Target policy must not claim successful retention when the job is absent');
  assert.equal(await page.locator('#audience-daily-chart').isVisible(),true,'Daily chart actually renders');
  assert.equal(await page.locator('#audience-region-chart').isVisible(),true,'Regional chart actually renders');
  const rendered=await page.evaluate(()=>['audience-daily-chart','audience-region-chart'].map(id=>{
    const chart=window.mdb.Chart.getInstance(document.getElementById(id));
    return {type:chart._chart.config.type,labels:chart._chart.data.labels,values:chart._chart.data.datasets[0].data,stacked:chart._chart.options.scales.y.stacked,zero:chart._chart.options.scales[chart._chart.options.indexAxis==='y'?'x':'y'].beginAtZero};
  }));
  assert.equal(rendered[0].type,'bar');assert.deepEqual(rendered[0].values,[1]);
  assert.equal(rendered[0].stacked,false,'Page openings and visible slots compare side by side, never sum in a stack');
  assert.deepEqual(rendered[1].labels,['SC']);assert.deepEqual(rendered[1].values,[1]);assert.equal(rendered[1].zero,true);
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false,'No whole-page horizontal overflow');
  await page.getByText('Como interpretar o potencial comercial',{exact:true}).click();
  assert.equal(await page.getByText('Espaço não é anúncio',{exact:true}).isVisible(),true);
  await page.getByText('Como interpretar o potencial comercial',{exact:true}).click();
  await page.locator('.audience-filter-details > summary').click();
  await page.locator('#aud-uf').selectOption('SP');await page.locator('#aud-region').selectOption('visitor');
  const entries=await page.locator('form').evaluate(f=>Object.fromEntries(new FormData(f).entries()));
  assert.equal(entries.uf,'SP');assert.equal(entries.regiao,'visitor');
  await page.locator('#aud-uf').selectOption('SC');await page.locator('#aud-region').selectOption('market');
  assert.deepEqual(errors,[],'No browser execution errors');
  await page.evaluate(()=>window.scrollTo(0,0));
  await page.screenshot({path:resolve(output,`audience-${width}.png`),fullPage:true});
  await page.screenshot({path:resolve(output,`audience-${width}-viewport.png`)});
  console.log(`PASS Business actual CFML report + native MDB charts ${width}px, filters, disclosures, zero scale, layout`);
  await page.close();
 }
 const nojs=await browser.newPage({javaScriptEnabled:false});await nojs.goto(`http://127.0.0.1:${server.address().port}/`);
 assert.equal(await nojs.locator('#inventario table tbody tr').count(),1);
 await nojs.locator('.audience-filter-details > summary').click();
 assert.equal(await nojs.getByRole('button',{name:'Aplicar filtros'}).isVisible(),true);
 console.log('PASS no-JavaScript exact inventory and server-side filter fallback');
 console.log(`Screenshots: ${output}`);
} finally {await browser.close();await new Promise(done=>server.close(done));}
