// Offline browser contract: render real CTA fragments with CFML, route every
// browser request locally, and exercise the real tracker. No partner requests.
import { createRequire } from 'node:module';
import { readFile, writeFile, mkdtemp, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const require=createRequire(import.meta.url);
const { chromium }=require('playwright');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const temp=await mkdtemp('/private/tmp/rr-live-browser-');
let browser;
try {
    const modal=await readFile(path.join(root,'includes/modal/modal_cupom_link_conteudo.cfm'),'utf8');
    const direct=await readFile(path.join(root,'evento/index.cfm'),'utf8');
    const bar=await readFile(path.join(root,'evento/parts/barra_acoes.cfm'),'utf8');
    const edition=await readFile(path.join(root,'evento/parts/edicoes_evento.cfm'),'utf8');
    const fragments={
        edition: [...edition.matchAll(/<a\b[\s\S]*?<\/a>/g)].map(m=>m[0]).find(s=>s.includes('event-edition-link')),
        modal: modal.match(/<a id="linkInscricao"[\s\S]*?<\/a>/)?.[0],
        direct: [...direct.matchAll(/<a\b[\s\S]*?<\/a>/g)].map(m=>m[0]).find(s=>s.includes('#eventActions.register#')),
        bar: [...bar.matchAll(/<button\b[\s\S]*?<\/button>/g)].map(m=>m[0]).find(s=>s.includes('#eventActions.register#'))
    };
    for (const [name,fragment] of Object.entries(fragments)) {
        assert.ok(fragment,`${name} real registration control is present`);
        await writeFile(path.join(temp,`${name}.cfm`),['modal','edition'].includes(name)?`<cfoutput>${fragment}</cfoutput>`:fragment);
    }
    await writeFile(path.join(temp,'render.cfm'),`<cfscript>
qEvento=queryNew('id_evento,url_inscricao,url_hotsite','integer,varchar,varchar',[{'id_evento'=304,'url_inscricao'='https://www.appliveexperience.com.br/evento/test/?coupon=test','url_hotsite'='https://liverun.com.br/etapa/test/'}]);
qCupom=queryNew('id_evento,curl','integer,varchar',[{'id_evento'=304,'curl'='https://www.liverun.com.br/etapa/test/?coupon=test'}]);
qEventoEdicoes={'id_evento'=304,'data_final'=now(),'nome_evento'='Evento teste','cidade'='Cidade teste','estado'='SP','concluintes'=0,'tempo_campeao_masculino'='','tempo_campea_feminina'=''};
VARIABLES.eventEditionIsCurrent=true;VARIABLES.eventEditionIsOpenForRegistration=true;VARIABLES.eventEditionIsHidden=false;VARIABLES.eventEditionPath=qEvento.url_inscricao;VARIABLES.eventEditionAnchorAttrs=' target="_blank" rel="noopener"';VARIABLES.eventEditionRegistrationLabel='Inscreva-se';REQUEST.t=function(key){return key;};
couponLinkModal={'useCoupon'='Usar cupom'};eventActions={'register'='Inscrever'};fixtures={};
</cfscript>
<cfsavecontent variable="fixtures.modal"><cfinclude template="modal.cfm"/></cfsavecontent>
<cfsavecontent variable="fixtures.direct"><cfinclude template="direct.cfm"/></cfsavecontent>
<cfsavecontent variable="fixtures.bar"><cfinclude template="bar.cfm"/></cfsavecontent>
<cfsavecontent variable="fixtures.edition"><cfinclude template="edition.cfm"/></cfsavecontent>
<cfset VARIABLES.eventEditionIsOpenForRegistration=false/>
<cfsavecontent variable="fixtures.closedEdition"><cfinclude template="edition.cfm"/></cfsavecontent>
<cfscript>writeOutput('LIVE_FIXTURE_START' & serializeJSON(fixtures) & 'LIVE_FIXTURE_END');</cfscript>`);
    const cfml=spawnSync(process.env.AUDIENCE_CFML_JAVA_RUNTIME||'/usr/bin/java',[
        '-cp',process.env.AUDIENCE_CFML_BOX_RUNTIME||'/Users/Shared/Projects/ColdFusion Certification/box',
        'cliloader.LoaderCLIMain',`-CommandBox_home=${process.env.AUDIENCE_CFML_COMMANDBOX_HOME||'/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox'}`,'execute','render.cfm'
    ],{cwd:temp,encoding:'utf8',timeout:60000,env:{...process.env,RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
    assert.equal(cfml.status,0,cfml.stderr+cfml.stdout);
    const fixtures=JSON.parse(cfml.stdout.match(/LIVE_FIXTURE_START([\s\S]*?)LIVE_FIXTURE_END/)?.[1]||'null');
    assert.ok(fixtures,'CFML rendered fixtures');
    const tracker=await readFile(path.join(root,'assets/js/rr-audience.js'),'utf8');
    browser=await chromium.launch({headless:true,channel:process.env.AUDIENCE_BROWSER_CHANNEL||'chrome'});
    for (const width of [1280,390]) {
        for (const surface of ['edition','modal','direct','bar']) {
            const context=await browser.newContext({viewport:{width,height:900}});
            const bodies=[],destinations=[],errors=[];
            const config={endpoint:'/api/analytics/collect.cfm',contextToken:'local-fixture',signature:'local-fixture',context:{pageViewId:'11111111-1111-4111-8111-111111111111',pageFamily:'event',contentType:'event',contentId:'304'}};
            await context.route('**/*',async route=>{
                const request=route.request(),url=new URL(request.url());
                if(url.hostname!=='roadrunners.test') { destinations.push(request.url()); await route.fulfill({status:200,contentType:'text/html',body:'Offline partner fixture'}); return; }
                if(url.pathname==='/api/analytics/collect.cfm') { bodies.push(request.postDataJSON()); await route.fulfill({status:204,body:''}); return; }
                if(url.pathname==='/assets/js/rr-audience.js') { await route.fulfill({contentType:'application/javascript',body:tracker}); return; }
                await route.fulfill({contentType:'text/html',body:`<!doctype html><html><body><div id="controls">${surface==='modal'?'':fixtures[surface]}</div><script>window.RoadRunnersAudienceConfig=${JSON.stringify(config)}</script><script src="/assets/js/rr-audience.js"></script></body></html>`});
            });
            const page=await context.newPage();page.on('pageerror',error=>errors.push(error.message));
            await page.goto('https://roadrunners.test/?utm_source=google&utm_medium=cpc&utm_campaign=live_run_retomada&utm_content=smart_retomada');
            if(surface==='modal') await page.locator('#controls').evaluate((el,html)=>{el.innerHTML=html;},fixtures.modal);
            const control=page.locator(surface==='bar'?'#controls button':'#controls a');
            const expected=surface==='modal'?'https://www.liverun.com.br/etapa/test/?coupon=test':'https://www.appliveexperience.com.br/evento/test/?coupon=test';
            const popup=page.waitForEvent('popup');
            if(surface==='direct') { await control.focus();await page.keyboard.press('Enter'); }
            else await control.click();
            const destination=await popup;await destination.waitForLoadState('domcontentloaded');
            assert.equal(destination.url(),expected,`${surface} preserves new-tab navigation`);await destination.close();
            await page.waitForTimeout(100);
            let outbound=bodies.flatMap(b=>b.events).filter(e=>e.kind==='outbound_click');
            assert.equal(outbound.length,1,`${width}px ${surface} sends one outbound event`);
            if(surface==='edition') {
                await page.locator('#controls').evaluate((el,html)=>{el.innerHTML=html;},fixtures.closedEdition);
                assert.equal(await page.locator('[data-audience-live-registration]').count(),0,'closed edition carries no registration marker');
                await page.locator('#controls').evaluate((el,html)=>{el.innerHTML=html;},fixtures.edition);
            }
            assert.equal(outbound[0].key,'outbound_click:live_registration:304');
            assert.equal(outbound[0].contentType,'event');assert.equal(outbound[0].contentId,'304');
            assert.equal(bodies.find(b=>b.events.some(e=>e.kind==='outbound_click')).campaign,'live_run_retomada');
            if(surface==='modal') await page.locator('#controls').evaluate((el,html)=>{el.innerHTML=html;},fixtures.modal);
            const nextPopup=page.waitForEvent('popup');await control.click();await (await nextPopup).close();await page.waitForTimeout(100);
            assert.equal(bodies.flatMap(b=>b.events).filter(e=>e.kind==='outbound_click').length,1,'repeat/modal replacement does not duplicate the event');
            await page.evaluate(()=>window.dispatchEvent(new CustomEvent('rr-audience-preference',{detail:{allowed:false}})));
            const refusedPopup=page.waitForEvent('popup');await control.click();await (await refusedPopup).close();await page.waitForTimeout(50);
            assert.equal(bodies.flatMap(b=>b.events).filter(e=>e.kind==='outbound_click').length,1,'refusal preserves navigation without collecting');
            assert.deepEqual(errors,[]);assert.ok(destinations.every(url=>url.startsWith('https://www.liverun.com.br/')||url.startsWith('https://www.appliveexperience.com.br/')));
            await context.close();console.log(`PASS: ${width}px real CFML ${surface}, new tab/keyboard, repetition and refusal`);
        }
    }
} finally { await browser?.close(); await rm(temp,{recursive:true,force:true}); }
