#!/usr/bin/env node
// Real CFML selection SQL and HTML rendering against disposable PostgreSQL fixtures.
import assert from 'node:assert/strict';
import {copyFileSync,existsSync,mkdirSync,mkdtempSync,readFileSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const stage=process.env.RR_DESCRIPTION_LOCALES_ROOT || '/private/tmp/rr-description-locales-stage';
assert.ok(existsSync(resolve(stage,'services/EventDescriptionLocaleService.cfc')), 'Event description locale selection has not been implemented');
const scratch=mkdtempSync(resolve(tmpdir(),'rr-description-locales-test-'));
const pgBin='/opt/homebrew/opt/postgresql@16/bin';
const port=String(56000+process.pid%400);
const pg=(name,args)=>{const r=spawnSync(resolve(pgBin,name),args,{encoding:'utf8',timeout:30000});assert.equal(r.status,0,`${name}: ${r.stdout}${r.stderr}`);};
let started=false;
try {
  pg('initdb',['-D',resolve(scratch,'db'),'-U','locale_test','-A','trust','--no-locale','--encoding=UTF8']);
  pg('pg_ctl',['-D',resolve(scratch,'db'),'-l',resolve(scratch,'postgres.log'),'-o',`-h 127.0.0.1 -p ${port} -k ${scratch}`,'-w','start']);started=true;
  for(const f of ['services/EventDescriptionLocaleService.cfc','evento/parts/descricao_localizada.cfm','i18n/en.cfm','i18n/es.cfm','i18n/pt-BR.cfm']) {
    mkdirSync(dirname(resolve(scratch,f)),{recursive:true});copyFileSync(resolve(stage,f),resolve(scratch,f));
  }
  copyFileSync(resolve(root,'_codex/tests/rr-description-locales.cfm'),resolve(scratch,'run.cfm'));
  // Execute the real interpolation expressions through CFQUERY, not queryExecute:
  // Adobe/Lucee auto-escape SQL fragments unless the call site preserves their quotes.
  const backend=readFileSync(resolve(stage,'includes/backend/backend_evento.cfm'),'utf8');
  const interpolation=field=>{
    const match=backend.match(new RegExp(`#[^#\\r\\n]*VARIABLES\\.eventDescriptionSelection\\.${field}[^#\\r\\n]*#`));
    assert.ok(match,`Missing production interpolation ${field}`);return match[0];
  };
  writeFileSync(resolve(scratch,'fixture_query.cfm'),`<cfquery name="VARIABLES.fixtureLocaleQuery" datasource="#VARIABLES.fixtureReadDatasource#">SELECT ${interpolation('descriptionSql')} AS descricao, ${interpolation('languageSql')} AS descricao_idioma FROM public.tb_evento_corridas evt ${interpolation('joinSql')} WHERE evt.id_evento=1</cfquery>`);
  const r=spawnSync('/usr/bin/java',['-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox','execute','run.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,env:{PATH:process.env.PATH,TMPDIR:tmpdir(),RR_DESCRIPTION_LOCALES_TEST_PG_PORT:port}});
  assert.equal(r.status,0,`${r.error || ''}${r.stdout}${r.stderr}`);
  assert.match(r.stdout,/RR_DESCRIPTION_LOCALES_PASSED:\d+/);
  console.log(r.stdout.trim());
} finally {
  if(started)pg('pg_ctl',['-D',resolve(scratch,'db'),'-m','fast','-w','stop']);
  rmSync(scratch,{recursive:true,force:true});
}
