#!/usr/bin/env node
// Isolated CFML renderer: copies only the view, admin guard and synthetic fixture.
import assert from 'node:assert/strict';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const scratch = mkdtempSync(resolve(tmpdir(), 'audience-editorial-cfml-'));
const renderRoot = mkdtempSync(resolve(tmpdir(), 'audience-editorial-render-'));
const commandboxHome = process.env.AUDIENCE_CFML_COMMANDBOX_HOME || process.env.AUDIENCE_EDITORIAL_COMMANDBOX_HOME
  || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const box = process.env.AUDIENCE_CFML_BOX_RUNTIME || process.env.AUDIENCE_EDITORIAL_BOX_RUNTIME
  || '/Users/Shared/Projects/ColdFusion Certification/box';

try {
  if (!existsSync(box)) throw new Error(`CommandBox runtime not found: ${box}`);
  if (!existsSync(resolve(commandboxHome, 'lib/lucee-5.3.10.120.jar'))) {
    throw new Error(`Cached Lucee 5.3.10.120 not found under CommandBox home: ${commandboxHome}`);
  }
  mkdirSync(resolve(scratch, 'portal/audiencia'), { recursive: true });
  mkdirSync(resolve(scratch, 'includes/backend'), { recursive: true });
  copyFileSync(resolve(root, '_codex/tests/audience-editorial-business/home-fixture.cfm'), resolve(scratch, 'render.cfm'));
  copyFileSync(resolve(root, 'portal/audiencia/home.cfm'), resolve(scratch, 'portal/audiencia/home.cfm'));
  copyFileSync(resolve(root, 'includes/backend/require_admin.cfm'), resolve(scratch, 'includes/backend/require_admin.cfm'));

  const java = process.env.AUDIENCE_CFML_JAVA_RUNTIME || '/usr/bin/java';
  if (!existsSync(java)) throw new Error('Java runtime not found; set AUDIENCE_CFML_JAVA_RUNTIME');
  const rendered = spawnSync(java, ['-Dfile.encoding=UTF-8', '-Dsun.stdout.encoding=UTF-8', '-Dsun.stderr.encoding=UTF-8', '-cp', box,
    'cliloader.LoaderCLIMain', `-CommandBox_home=${commandboxHome}`, 'execute', 'render.cfm'
  ], { cwd: scratch, encoding: 'utf8', env: { PATH: process.env.PATH, LC_ALL: 'en_US.UTF-8', TMPDIR: tmpdir(), RUNNERHUB_OFFLINE_CFML_TESTS: '1' } });
  if (rendered.status !== 0) throw new Error(`CommandBox: ${rendered.stdout || ''}${rendered.stderr || ''}`);
  const html = rendered.stdout;

  assert.match(html, /Cartões expostos/, 'render must identify qualified card exposures');
  assert.match(html, /Alcance exposto/, 'render must keep exposed visitors separate from opening visitors');
  assert.match(html, /50%[^<]*1 segundo/, 'render must state the card qualification rule');
  assert.match(html, /Profundidade[^<]*trecho[^<]*alcançado[^<]*não leitura comprovada/i,
    'render must not equate depth with reading');
  assert.match(html, /sem histórico retroativo/i, 'render must disclose the editorial coverage boundary');

  const rowFor = contentId => html.match(new RegExp(`<tr>\\s*<td[^>]*>${contentId}[\\s\\S]*?<\\/tr>`, 'i'))?.[0] || '';
  const exposureRow = rowFor('card-sem-abertura');
  assert.match(exposureRow, />\s*2 cartões[^]*>\s*1 navegador[^]*>\s*0 aberturas[^]*>\s*0 páginas/,
    'exposure-only content must show 2 pages, 1 person and zero opens');
  assert.match(exposureRow, /<div class="audience-meta">—<\/div>/, 'exposure-only content must not invent a content path');
  assert.match(exposureRow, /Profundidade indisponível|>—</, 'no progress signal must render unavailable, not measured zero');

  const legacyRow = rowFor('noticia-legada');
  assert.match(legacyRow, /Sinal editorial ainda ausente|>—</, 'legacy content must show no new editorial signal');

  const videoRow = rowFor('video-42');
  assert.match(videoRow, /Não se aplica a vídeo|>—</, 'video depth must be explicitly not applicable');
  assert.match(html, /100 conteúdos[^<]*incluindo itens apenas expostos/i, 'the 100-row limit label must include exposure-only entries');

  mkdirSync(resolve(renderRoot, 'assets/css'), { recursive: true });
  mkdirSync(resolve(renderRoot, 'assets/js'), { recursive: true });
  writeFileSync(resolve(renderRoot, 'audiencia-editorial-fixture.html'), html, 'utf8');
  for (const asset of ['mdb.min.css', 'business-ui.css', 'audience-dashboard.css']) {
    copyFileSync(resolve(root, 'assets/css', asset), resolve(renderRoot, 'assets/css', asset));
  }
  copyFileSync(resolve(root, 'assets/js/audience-dashboard.js'), resolve(renderRoot, 'assets/js/audience-dashboard.js'));
  const mdbScript = resolve(root, 'assets/js/mdb.umd.min.js');
  try { copyFileSync(mdbScript, resolve(renderRoot, 'assets/js/mdb.umd.min.js')); } catch {}

  console.log(`Audience editorial CFML: 11 rendered behavior assertions passed.\nHTML: ${resolve(renderRoot, 'audiencia-editorial-fixture.html')}`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
