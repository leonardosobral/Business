#!/usr/bin/env node
// Browser QA of local synthetic CFML output only; no production traffic or account access.
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
assert.ok(input && /audience-live-render-[a-zA-Z0-9]+\/live-fixture\.html$/.test(input),'Pass only isolated LIVE fixture output');
const html=readFileSync(input,'utf8');
assert.ok(html.includes('data-fixture="observed"') && html.includes('data-fixture="unavailable"'),'Synthetic fixture required');
const allowed=new Set(['/assets/css/mdb.min.css','/assets/css/business-ui.css','/assets/css/audience-dashboard.css']);
const server=createServer((req,res)=>{
  const path=new URL(req.url,'http://localhost').pathname;
  if(path==='/'){res.setHeader('Content-Type','text/html; charset=utf-8');res.end(html);}
  else if(allowed.has(path)){res.setHeader('Content-Type','text/css');res.end(readFileSync(resolve(root,'.'+path)));}
  else{res.statusCode=404;res.end();}
});
await new Promise(done=>server.listen(0,'127.0.0.1',done));
let browser;
const output=resolve(dirname(input),'visual');mkdirSync(output,{recursive:true});
try {
  browser=await chromium.launch({channel:'chrome',headless:true});
  for(const width of [1440,390]) {
    const page=await browser.newPage({viewport:{width,height:1000},javaScriptEnabled:false});
    await page.goto(`http://127.0.0.1:${server.address().port}/`,{waitUntil:'networkidle'});
    const observed=page.locator('[data-fixture="observed"]');
    assert.equal(await observed.locator('table').count(),2,'campaign and event summaries remain distinct');
    assert.equal(await observed.getByRole('button',{name:'Filtrar jornada'}).isVisible(),true,'server-rendered filter works without JS');
    await observed.locator('[name="live_cidade"]').fill('Campinas');
    await observed.locator('[name="live_prova"]').fill('102');
    const entries=await observed.locator('form').evaluate(f=>Object.fromEntries(new FormData(f).entries()));
    assert.deepEqual([entries.live_cidade,entries.live_prova,entries.dias,entries.uf,entries.regiao,entries.dispositivo],['Campinas','102','7','SC','market','MOBILE'],'detail filters retain the global reporting scope');
    assert.equal(await page.locator('[data-fixture="unavailable"] [role="status"]').isVisible(),true,'query failure is visible');
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1),false,'tables scroll inside their regions without page overflow');
    if(width===390) assert.equal(await observed.locator('.table-responsive').first().evaluate(el=>el.scrollWidth>el.clientWidth),true,'wide campaign table is reachable through local horizontal scroll');
    await page.locator('[data-fixture="historical"], [data-fixture="unavailable"]').evaluateAll(elements=>elements.forEach(el=>el.remove()));
    await page.screenshot({path:resolve(output,`live-${width}.png`),fullPage:true});
    console.log(`PASS LIVE CFML browser ${width}px: forms, scope, unavailable state, tables, no page overflow, no JS dependency`);
    await page.close();
  }
  console.log(`Screenshots: ${output}`);
} finally {if(browser) await browser.close();await new Promise(done=>server.close(done));}
