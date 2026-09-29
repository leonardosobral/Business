#!/usr/bin/env node
// Exercises the real CRM page against synthetic data; never reaches production.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {spawn} from 'node:child_process';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {mkdirSync} from 'node:fs';

const require=createRequire(import.meta.url);
const {chromium}=require('playwright');
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const origin='http://127.0.0.1:8768';
const server=spawn('python3',['_codex/scripts/crm_ui_fixture.py'],{cwd:root,stdio:'ignore'});
let browser;
async function ready(){for(let n=0;n<50;n++){try{if((await fetch(origin)).ok)return;}catch{}await new Promise(done=>setTimeout(done,100));}throw new Error('synthetic CRM fixture did not start');}

try{
 await ready();
 browser=await chromium.launch({channel:'chrome',headless:true});
 mkdirSync(resolve(root,'output/playwright'),{recursive:true});
 for(const width of [1440,390]){
  const page=await browser.newPage({viewport:{width,height:900}});
  const errors=[];page.on('pageerror',error=>errors.push(error.message));
  await page.goto(origin);
  await page.locator('[data-tab="campaigns"]').click();
  await page.locator('#newCampaign').click();
  const editor=page.locator('#campaignEditor');
  await editor.waitFor({state:'visible'});
  assert.equal(await editor.evaluate(node=>node.open),true,'new campaign opens a modal');
  assert.equal(await page.locator('#campaignForm [name="name"]').evaluate(node=>document.activeElement===node),true,'campaign name receives focus');
  await page.screenshot({path:resolve(root,`output/playwright/crm-campaign-modal-${width}.png`)});
  await page.keyboard.press('Escape');
  assert.equal(await editor.evaluate(node=>node.open),false,'Escape closes the modal');

  await page.locator('#newCampaign').click();
  await editor.waitFor({state:'visible'});
  await page.locator('#campaignForm [name="name"]').fill(`Campanha sintética ${width}`);
  await page.locator('#campaignForm [name="title"]').fill('Próxima prova');
  await page.locator('#campaignForm [name="body"]').fill('Conheça as provas disponíveis.');
  await page.locator('#campaignForm [name="destination"]').fill('/busca/');
  await page.locator('#campaignForm button[type="submit"]').click();
  await page.locator('#campaignHeading').getByText('Campanha · versão 1').waitFor();
  assert.equal(await editor.evaluate(node=>node.open),true,'saving a draft keeps editing available');
  assert.equal(await page.locator('#campaignMessage').isVisible(),true,'the saved-draft notice appears inside the modal');
  assert.equal(await page.locator('#reviewCampaign').isEnabled(),true,'saved draft can be reviewed');
  await page.locator('#closeCampaign').click();
  assert.equal(await editor.evaluate(node=>node.open),false,'close button dismisses the editor');

  const summary=page.locator('#campaignList [data-campaign-details]').first();
  await summary.waitFor({state:'visible'});
  assert.match(await summary.innerText(),/Campanha sintética [\s\S]*Rascunho[\s\S]*Notificação/,'closed row keeps campaign identity and status visible');
  assert.doesNotMatch(await page.locator('#campaignList').innerText(),/Conheça as provas disponíveis/,'long message stays out of the campaign list');
  assert.equal(await page.locator('#campaignList button').count(),await page.locator('#campaignList [data-campaign-details]').count(),'each row has one details action');
  await summary.click();
  const details=page.locator('#campaignDetailsDialog');
  await details.waitFor({state:'visible'});
  assert.match(await page.locator('#campaignDetailsBody').innerText(),/Público sintético SC[\s\S]*Próxima prova[\s\S]*Conheça as provas disponíveis[\s\S]*\/busca\//,'details modal shows audience, message and destination');
  await page.screenshot({path:resolve(root,`output/playwright/crm-campaign-details-${width}.png`)});
  if(width===390)assert.equal(await details.evaluate(node=>node.scrollWidth<=node.clientWidth+1),true,'details fit the mobile modal width');
  await page.keyboard.press('Escape');
  assert.equal(await details.evaluate(node=>node.open),false,'Escape closes campaign details');

  await summary.click();
  await details.waitFor({state:'visible'});
  await page.locator('#campaignDetailsActions [data-duplicate]').click();
  await editor.waitFor({state:'visible'});
  assert.equal(await page.locator('#campaignHeading').innerText(),'Nova campanha','duplicate opens as a new draft in the modal');
  assert.equal(await page.locator('#campaignMessage').isHidden(),true,'a new draft does not inherit the previous save notice');
  await page.locator('#closeCampaign').click();

  await summary.click();
  await details.waitFor({state:'visible'});
  await page.locator('#campaignDetailsActions [data-edit]').click();
  await editor.waitFor({state:'visible'});
  await page.locator('#reviewCampaign').click();
  await page.locator('#crmDialog').waitFor({state:'visible'});
  assert.equal(await editor.evaluate(node=>node.open),true,'review sits above the campaign modal');
  await page.locator('#closeDialog').click();
  assert.equal(await editor.evaluate(node=>node.open),true,'closing review returns to campaign editor');
  await page.locator('#closeCampaign').click();
  assert.equal(await editor.evaluate(node=>node.open),false,'close button dismisses the editor');

  await summary.click();
  await details.waitFor({state:'visible'});
  await page.locator('#campaignDetailsActions [data-report]').click();
  await page.locator('#crmDialog').waitFor({state:'visible'});
  assert.equal(await details.evaluate(node=>node.open),false,'results replace details with their own modal');
  await page.locator('#closeDialog').click();

  await page.locator('[data-tab="audiences"]').click();
  await page.locator('#audienceList button').first().click();
  await page.locator('#campaignFromAudience').click();
  await editor.waitFor({state:'visible'});
  assert.equal(await page.locator('#campaignForm [name="audience_id"]').inputValue(),'1','audience shortcut preselects its audience');
  if(width===390)assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),true,'campaign modal has no mobile page overflow');
  assert.deepEqual(errors,[],'campaign modal flow has no browser exceptions');
  await page.close();
 }
 const state=await (await fetch(`${origin}/state`)).json();
 assert.equal(state.confirmations,0,'opening, saving and reviewing drafts never confirms delivery');
 console.log('PASS CRM campaign list and modals 1440/390px, draft, details, review, results, duplicate and audience shortcut');
}finally{await browser?.close();server.kill('SIGTERM');}
