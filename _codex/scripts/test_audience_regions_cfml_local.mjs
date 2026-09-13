#!/usr/bin/env node
// Offline CFML render: no Application.cfc, datasource, browser or external request.
import assert from 'node:assert/strict';
import {copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const box = process.env.AUDIENCE_CFML_BOX_RUNTIME || '/Users/Shared/Projects/ColdFusion Certification/box';
const boxHome = process.env.AUDIENCE_CFML_COMMANDBOX_HOME || '/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox';
const java = process.env.AUDIENCE_CFML_JAVA_RUNTIME || '/usr/bin/java';
for (const path of [box,java,resolve(boxHome,'lib/lucee-5.3.10.120.jar')]) assert.ok(existsSync(path),`Offline runtime missing: ${path}`);
const scratch = mkdtempSync(resolve(tmpdir(),'audience-regions-cfml-'));
const output = mkdtempSync(resolve(tmpdir(),'audience-regions-render-'));
try {
  for (const name of ['portal/audiencia/regions.cfm','portal/audiencia/coverage_paths.cfm','includes/backend/require_admin.cfm']) {
    mkdirSync(dirname(resolve(scratch,name)),{recursive:true});
    if (existsSync(resolve(root,name))) copyFileSync(resolve(root,name),resolve(scratch,name));
  }
  copyFileSync(resolve(root,'_codex/tests/audience-regions/data.cfm'),resolve(scratch,'region-data.cfm'));
  copyFileSync(resolve(root,'_codex/tests/audience-regions/fixture.cfm'),resolve(scratch,'render.cfm'));
  const result = spawnSync(java,['-Dfile.encoding=UTF-8','-Dsun.stdout.encoding=UTF-8','-cp',box,'cliloader.LoaderCLIMain',`-CommandBox_home=${boxHome}`,'execute','render.cfm'],{
    cwd:scratch,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:tmpdir(),RUNNERHUB_OFFLINE_CFML_TESTS:'1'}
  });
  assert.equal(result.status,0,`CFML must compile: ${result.error || ''}${result.stdout}${result.stderr}`);
  const html = result.stdout;
  writeFileSync(resolve(output,'regions-fixture.html'),html);
  const section = name => html.split(`data-fixture="${name}"`)[1]?.split('data-fixture=')[0] || '';
  const observed = section('observed');
  const format = name => observed.split(`data-region-format="${name}"`)[1]?.split('data-region-format=')[0] || '';
  const row = (name,uf) => format(name).split(`data-region-uf="${uf}"`)[1]?.split('</tr>')[0] || '';
  // Catches reuse of global/raw totals and treating missing states as commercial gaps.
  assert.match(row('ads','SC'),/data-region-count="potential">\s*70</,'Each UF uses its own applicable opportunities');
  assert.match(row('ads','SC'),/data-region-count="filled">\s*50<[^]*?71\.4%/);
  assert.match(row('ads','SC'),/data-region-count="empty">\s*15<[^]*?21\.4%/);
  assert.match(row('ads','SC'),/data-region-count="unclassified">\s*5<[^]*?7\.1%/);
  assert.match(row('ads','SC'),/data-region-segment="filled"[^>]*width:71\.4286%/);
  assert.deepEqual([...format('ads').matchAll(/data-region-uf="([^"]+)"/g)].map(match=>match[1]),['--','SP','SC','AC'],'Sort by empty volume, then denominator, then UF');
  assert.deepEqual([...format('banners').matchAll(/data-region-uf="([^"]+)"/g)].map(match=>match[1]),['SP','SC','--','AC']);
  assert.match(row('ads','--'),/Desconhecida/);
  assert.match(row('ads','AC'),/data-region-count="potential">\s*0</);
  assert.match(row('ads','AC'),/—/);
  assert.doesNotMatch(row('ads','AC'),/0\.0%|data-region-segment|NaN|Infinity/,'No applicability is not 0% occupancy');
  assert.match(observed,/<details[^>]*data-region-audience[^>]*>/);
  assert.doesNotMatch(observed,/<details[^>]*data-region-audience[^>]*\bopen\b/);
  assert.match(observed,/400/,'Historical signal detail remains accessible');
  assert.match(observed,/não devem ser somad/i,'Overlapping regional totals cannot imply global additive inventory');
  assert.match(observed,/data-coverage-folder="(?:\/|&#x2f;)corridas"[^]*?17<[^]*?12<[^]*?24<[^]*?9</);
  assert.match(observed,/Pasta não identificada/);
  assert.doesNotMatch(observed,/<&/,'Folder labels must be escaped');
  assert.match(observed,/templates[^]*?URLs/i,'Folder grouping must describe the recorded template path limitation');
  const unavailable = section('unavailable');
  assert.match(unavailable,/ocupação por UF[^]*?indisponível/i);
  assert.match(unavailable,/pastas[^]*?indisponível/i);
  assert.doesNotMatch(unavailable,/data-region-count|data-coverage-folder/,'Failed queries must not reuse stale rows or invent zeros');
  assert.match(section('empty'),/Nenhuma posição registrada/i);
  assert.match(section('empty'),/Nenhuma pasta[^]*?observada/i);
  assert.doesNotMatch(section('empty'),/data-region-count|data-coverage-folder/);
  console.log(`Regional/folder CFML assertions passed.\nHTML: ${resolve(output,'regions-fixture.html')}`);
} finally { rmSync(scratch,{recursive:true,force:true}); }
