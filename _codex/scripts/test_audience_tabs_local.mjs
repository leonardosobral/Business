#!/usr/bin/env node
// Real CFML and DOM, with synthetic data only. No DB, app bootstrap or external HTTP.
import assert from 'node:assert/strict';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { createServer } from 'node:http';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
let input = process.argv[2];
if (!input) {
  const scratch = mkdtempSync(resolve(tmpdir(), 'audience-tabs-cfml-'));
  const output = mkdtempSync(resolve(tmpdir(), 'audience-tabs-render-'));
  try {
    mkdirSync(resolve(scratch, 'portal/audiencia'), { recursive: true });
    mkdirSync(resolve(scratch, 'includes/backend'), { recursive: true });
    for (const name of ['home.cfm', 'live_journey.cfm', 'capacity.cfm']) {
      copyFileSync(resolve(root, 'portal/audiencia', name), resolve(scratch, 'portal/audiencia', name));
    }
    copyFileSync(resolve(root, 'includes/backend/require_admin.cfm'), resolve(scratch, 'includes/backend/require_admin.cfm'));
    const baseFixture = readFileSync(resolve(root, '_codex/tests/audience-editorial-business/home-fixture.cfm'), 'utf8');
    writeFileSync(resolve(scratch, 'base-fixture.cfm'), baseFixture.replace('VARIABLES.audienceDays = 7;', 'VARIABLES.audienceDays = 30;'), 'utf8');
    const capacityFixture = readFileSync(resolve(root, '_codex/tests/audience-capacity/fixture.cfm'), 'utf8');
    const capacityData = capacityFixture.match(/VARIABLES\.audienceCapacityQuery = queryNew[\s\S]*?(?=<\/cfscript>)/)?.[0];
    assert.ok(capacityData, 'Reuse the capacity fixture query without duplicating the model');
    writeFileSync(resolve(scratch, 'capacity-data.cfm'), `<cfscript>${capacityData}</cfscript>`, 'utf8');
    copyFileSync(resolve(root, '_codex/tests/audience-tabs/fixture.cfm'), resolve(scratch, 'render.cfm'));
    const box = process.env.AUDIENCE_CFML_BOX_RUNTIME || process.env.AUDIENCE_TABS_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
    const boxHome = process.env.AUDIENCE_CFML_COMMANDBOX_HOME || process.env.AUDIENCE_TABS_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
    const java = process.env.AUDIENCE_CFML_JAVA_RUNTIME || '/usr/bin/java';
    assert.ok(existsSync(box), 'CommandBox is missing; set AUDIENCE_CFML_BOX_RUNTIME to an existing offline runtime');
    assert.ok(existsSync(java), 'Java is missing; set AUDIENCE_CFML_JAVA_RUNTIME to an existing Java executable');
    assert.ok(existsSync(resolve(boxHome, 'lib/lucee-5.3.10.120.jar')), 'Cached Lucee is missing; set AUDIENCE_CFML_COMMANDBOX_HOME to an installed offline cache');
    const result = spawnSync(java, ['-Dfile.encoding=UTF-8', '-Dsun.stdout.encoding=UTF-8', '-Dsun.stderr.encoding=UTF-8', '-cp', box,
      'cliloader.LoaderCLIMain', `-CommandBox_home=${boxHome}`, 'execute', 'render.cfm'], {
      cwd: scratch, encoding: 'utf8', env: { PATH: process.env.PATH, LC_ALL: 'en_US.UTF-8', TMPDIR: tmpdir(), RUNNERHUB_OFFLINE_CFML_TESTS: '1' }
    });
    assert.equal(result.status, 0, `CFML view must compile: ${result.error || ''}${result.stdout || ''}${result.stderr || ''}`);
    input = resolve(output, 'tabs-fixture.html');
    writeFileSync(input, result.stdout, 'utf8');
    console.log(`HTML: ${input}`);
  } finally { rmSync(scratch, { recursive: true, force: true }); }
}
assert.ok(/audience-tabs-render-[a-zA-Z0-9]+\/tabs-fixture\.html$/.test(input), 'Use isolated tabs fixture output only');
const html = readFileSync(input, 'utf8');
assert.ok(html.includes('Fixture local sintética'), 'Synthetic data required');
const allowed = new Set(['/assets/css/mdb.min.css', '/assets/css/business-ui.css', '/assets/css/audience-dashboard.css', '/assets/js/audience-dashboard.js', '/assets/js/mdb.umd.min.js']);
for (const asset of allowed) {
  const target = resolve(dirname(input), '.' + asset);
  mkdirSync(dirname(target), { recursive: true });
  copyFileSync(resolve(root, '.' + asset), target);
}
const server = createServer((req, res) => {
  const path = new URL(req.url, 'http://localhost').pathname;
  if (path === '/' || path === '/portal/audiencia/') { res.setHeader('Content-Type', 'text/html; charset=utf-8'); res.end(html); }
  else if (allowed.has(path)) { res.setHeader('Content-Type', path.endsWith('.js') ? 'text/javascript' : 'text/css'); res.end(readFileSync(resolve(root, '.' + path))); }
  else { res.statusCode = 404; res.end(); }
});
await new Promise(done => server.listen(0, '127.0.0.1', done));
const { chromium } = createRequire(import.meta.url)('playwright');
const origin = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch({ channel: 'chrome', headless: true });
const output = resolve(dirname(input), 'visual'); mkdirSync(output, { recursive: true });
try {
  for (const width of [1440, 768, 390]) {
    const page = await browser.newPage({ viewport: { width, height: 1000 } });
    const errors = []; page.on('pageerror', error => errors.push(error.message));
    await page.route('**/*', route => new URL(route.request().url()).origin === origin ? route.continue() : route.abort());
    await page.goto(origin + '/', { waitUntil: 'networkidle' });
    await page.getByRole('tab', { name: 'Posições', exact: true }).click();
    await page.goBack();
    assert.equal(await page.getByRole('tab', { selected: true }).innerText(), 'Visão geral', 'Back to the initial URL without a fragment restores overview');
    await page.goto(origin + '/#conteudo', { waitUntil: 'networkidle' });
    assert.equal(await page.locator('.audience-filter-details > summary').isVisible(), true, 'The compact filter summary exposes the current reporting scope');
    // Catches missing progressive enhancement and inaccessible multiple-panel states.
    assert.equal(await page.getByRole('tab').count(), 6, 'Six navigable report tabs');
    const selected = () => page.getByRole('tab', { selected: true });
    assert.equal(await selected().innerText(), 'Conteúdo', 'A descendant hash opens its owning panel on load');
    const onePanel = async () => assert.equal(await page.locator('[role="tabpanel"]:visible').count(), 1, 'Exactly one report panel is visible');
    await onePanel();
    await page.getByRole('tab', { name: 'Capacidade', exact: true }).click();
    assert.equal((await page.locator('[data-capacity="views"]').innerText()).trim(), '210', 'Capacity tab renders observed exposure from the shared synthetic fixture');
    assert.equal((await page.locator('[data-scenario="low"]').innerText()).trim(), '300');
    assert.equal((await page.locator('[data-scenario="base"]').innerText()).trim(), '450');
    assert.equal(await page.getByText('Histórico insuficiente', { exact: true }).isVisible(), true, 'Immature capacity remains clearly unavailable');
    if (width === 390) {
      const rows = await page.locator('#capacidade tbody tr').evaluateAll(elements => elements.map(row => ({
        height: row.getBoundingClientRect().height,
        position: row.cells[1].getBoundingClientRect().width,
        history: row.cells[6].getBoundingClientRect().width,
        scenario: row.cells[7].getBoundingClientRect().width
      })));
      assert.ok(rows.every(row => row.position >= 150), 'Long position identifiers retain a readable column on mobile');
      assert.ok(rows.every(row => row.history >= 170 && row.scenario >= 170), 'History and scenarios retain readable columns on mobile');
      assert.ok(rows.every(row => row.height <= 160), 'Long synthetic capacity rows do not become excessively tall');
      assert.equal(await page.locator('#capacidade .table-responsive').evaluate(el => el.scrollWidth > el.clientWidth), true, 'Readable capacity columns remain reachable through internal horizontal scrolling');
    }
    await page.getByRole('tab', { name: 'Posições', exact: true }).click();
    await onePanel();
    const inventory = page.locator('#inventario');
    assert.ok(await inventory.locator('th').count() <= 6, 'Operational detail does not force a 13-column table');
    const details = inventory.locator('tbody details').first();
    assert.equal(await details.getByLabel(/^Ver detalhes.*home-feed/).count(), 1, 'The disclosure accessible name starts with its visible action');
    assert.equal(await details.getAttribute('open'), null, 'Operational delivery detail starts collapsed');
    await details.locator('summary').click();
    assert.equal(await details.locator('dt', { hasText: /^Pedidos$/ }).isVisible(), true, 'Disclosure reveals operational metrics');
    assert.deepEqual((await details.locator('dd').allTextContents()).map(value => value.trim()), ['4', '3', '2', '1', '2', '1', '0', '0'], 'All synthetic delivery states survive compaction');
    await page.getByRole('tab', { name: 'Conteúdo', exact: true }).click();
    const exposure = page.locator('#conteudo tbody tr').filter({ hasText: 'card-sem-abertura' });
    assert.match(await exposure.innerText(), /2.*cartões[\s\S]*1.*navegador[\s\S]*0.*aberturas[\s\S]*0.*páginas/i, 'Exposure-only content keeps its distinct counts');
    const depth = page.locator('#conteudo tbody tr').filter({ hasText: 'noticia-com-profundidade' });
    assert.match(await depth.innerText(), /25%[\s\S]*2[\s\S]*50%[\s\S]*2[\s\S]*75%[\s\S]*1[\s\S]*100%[\s\S]*1/, 'All depth thresholds remain visible');
    assert.equal(await page.locator('#conteudo tbody tr').count(), 100, 'Existing bounded content detail preserved');
    // Catches missing roving focus, incorrect edge wrapping and focus stranded in hidden content.
    await selected().focus(); await page.keyboard.press('ArrowRight');
    assert.equal(await selected().innerText(), 'Origem e LIVE!');
    assert.equal(await selected().evaluate(el => el === document.activeElement), true);
    await page.keyboard.press('End'); assert.equal(await selected().innerText(), 'Cobertura');
    await page.keyboard.press('ArrowRight'); assert.equal(await selected().innerText(), 'Visão geral');
    await page.keyboard.press('ArrowLeft'); assert.equal(await selected().innerText(), 'Cobertura');
    await page.keyboard.press('Home'); assert.equal(await selected().innerText(), 'Visão geral');
    assert.equal(await page.locator('[role="tab"][tabindex="0"]').count(), 1);
    for (const id of ['audience-daily-chart', 'audience-region-chart']) {
      await page.locator('#' + id).waitFor({ state: 'visible' });
      assert.ok(await page.locator('#' + id).evaluate(el => el.width > 0 && el.height > 0), 'Charts initialize after hidden content becomes visible');
    }
    if (width === 1440) {
      await page.getByRole('tab', { name: 'Posições', exact: true }).click();
      await page.setViewportSize({ width: 390, height: 1000 });
      await page.getByRole('tab', { name: 'Visão geral', exact: true }).click();
      await page.waitForFunction(() => {
        const canvas = document.getElementById('audience-daily-chart');
        return canvas.width > 0 && canvas.width / devicePixelRatio <= canvas.parentElement.clientWidth + 1;
      });
      await page.setViewportSize({ width, height: 1000 });
    }
    await page.evaluate(() => { location.hash = 'jornada-live'; });
    await page.waitForFunction(() => document.querySelector('[role="tab"][aria-selected="true"]')?.textContent === 'Origem e LIVE!');
    assert.equal(await page.locator('#jornada-live').isVisible(), true, 'Existing LIVE deep link reveals its report');
    await page.getByRole('tab', { name: 'Posições', exact: true }).click();
    await page.goBack(); assert.equal(await selected().innerText(), 'Origem e LIVE!', 'Back restores owning tab');
    await page.goForward(); assert.equal(await selected().innerText(), 'Posições', 'Forward restores owning tab');
    await page.locator('.audience-filter-details > summary').click();
    await page.locator('#aud-uf').selectOption('SC');
    await Promise.all([page.waitForURL(url => url.searchParams.get('uf') === 'SC'), page.getByRole('button', { name: 'Aplicar filtros', exact: true }).click()]);
    assert.equal(await selected().innerText(), 'Posições', 'GET filter submission preserves current panel');
    assert.equal(new URL(page.url()).searchParams.get('live_campanha'), 'fixture-campaign', 'Global filters retain LIVE filters');
    assert.equal(new URL(page.url()).searchParams.get('dias'), '30', 'Capacity fixture uses a period that supports its 14-day baseline');
    await page.getByRole('tab', { name: 'Origem e LIVE!', exact: true }).click();
    await page.locator('#live-city').fill('Florianópolis');
    await Promise.all([page.waitForURL(url => url.searchParams.get('live_cidade') === 'Florianópolis'), page.getByRole('button', { name: 'Filtrar jornada' }).click()]);
    assert.equal(await selected().innerText(), 'Origem e LIVE!', 'LIVE form stays in its panel');
    for (const label of ['Visão geral', 'Capacidade', 'Posições', 'Conteúdo', 'Origem e LIVE!', 'Cobertura']) {
      await page.getByRole('tab', { name: label, exact: true }).click(); await onePanel();
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false, `${label}: no whole-page overflow at ${width}px`);
    }
    await page.getByRole('tab', { name: 'Visão geral', exact: true }).click();
    await page.evaluate(() => scrollTo(0, 0));
    await page.screenshot({ path: resolve(output, `tabs-${width}.png`), fullPage: true });
    await page.getByRole('tab', { name: 'Posições', exact: true }).click();
    await page.screenshot({ path: resolve(output, `positions-${width}.png`), fullPage: true });
    await page.getByRole('tab', { name: 'Capacidade', exact: true }).click();
    await page.screenshot({ path: resolve(output, `capacity-${width}.png`), fullPage: true });
    if (width === 390) {
      await page.locator('#capacidade .table-responsive').evaluate(el => { el.scrollLeft = el.scrollWidth; });
      await page.screenshot({ path: resolve(output, 'capacity-history-390.png'), fullPage: true });
    }
    if (width !== 768) {
      for (const [label, filename] of [['Conteúdo', 'content'], ['Origem e LIVE!', 'acquisition'], ['Cobertura', 'coverage']]) {
        await page.getByRole('tab', { name: label, exact: true }).click();
        await page.screenshot({ path: resolve(output, `${filename}-${width}.png`), fullPage: true });
      }
    }
    assert.deepEqual(errors, [], 'No uncaught browser errors');
    console.log(`PASS tabs ${width}px: keyboard, deep links, history, GET filters, disclosures, editorial metrics, charts, overflow`);
    await page.close();
  }
  for (const mode of ['nojs', 'no-chart-library', 'malformed-chart-data']) {
    const page = await browser.newPage({ javaScriptEnabled: mode !== 'nojs', viewport: { width: 390, height: 1000 } });
    if (mode === 'no-chart-library') await page.route('**/mdb.umd.min.js', route => route.abort());
    if (mode === 'malformed-chart-data') await page.route(origin + '/', route => route.fulfill({ contentType: 'text/html', body: html.replace(/(<script type="application\/json" id="audience-chart-data">)[\s\S]*?(<\/script>)/, '$1invalid JSON$2') }));
    await page.goto(origin + '/', { waitUntil: 'networkidle' });
    await page.locator('.audience-filter-details > summary').click();
    assert.equal(await page.getByRole('button', { name: 'Aplicar filtros', exact: true }).isVisible(), true);
    if (mode === 'nojs') {
      assert.equal(await page.getByRole('tab').count(), 0, 'No-JS navigation remains ordinary anchors');
      for (const id of ['inventario', 'regioes', 'conteudo', 'aquisicao', 'jornada-live', 'cobertura', 'capacidade']) assert.equal(await page.locator('#' + id).isVisible(), true, `${id} remains visible without JS`);
      await page.locator('#inventario details summary').click();
      assert.equal(await page.locator('#inventario details[open]').count(), 1, 'Native disclosures still work');
    } else {
      await page.getByRole('tab', { name: 'Posições', exact: true }).click();
      assert.equal(await page.locator('#inventario table').isVisible(), true, 'Chart errors cannot disable tab navigation or exact data');
    }
    assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth + 1), false);
    await page.close(); console.log(`PASS ${mode} fallback`);
  }
  console.log(`Screenshots: ${output}`);
} finally { await browser.close(); await new Promise(done => server.close(done)); }
