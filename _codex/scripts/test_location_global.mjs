import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdtempSync,mkdirSync,copyFileSync,rmSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {tmpdir} from 'node:os';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const rr=process.env.LOCATION_TEST_SOURCE||resolve(root,'../RoadRunners');
const scratch=mkdtempSync(resolve(tmpdir(),'location-global-test-'));
try {
 mkdirSync(resolve(scratch,'services'));
 for(const file of ['LocationResolver.cfc','AudienceMeasurementService.cfc'])copyFileSync(resolve(rr,'services',file),resolve(scratch,'services',file));
 copyFileSync(resolve(root,'_codex/tests/location-global.cfm'),resolve(scratch,'test.cfm'));
 const app=readFileSync(resolve(rr,'Application.cfc'),'utf8');
 const method=app.match(/<cffunction\s+name="OnRequestStart"[\s\S]*?<\/cffunction>/i)?.[0];
 assert.ok(method,'real request-start body must be available');
 const voids=['ensureAppSettings','ensureI18nCatalog','initSessionUsuarioCache','hydrateRequestUsuarioFromApiIntegration','hydrateRequestI18n','applyRequestLocale','processEnvironmentHandoff','enforceApiBearerAccess','enforceAuthenticatedJsonApiAccess'];
 const stubs=voids.map(name=>`public void function ${name}(){}`).join('\n')+`
public any function buildRequestUsuario(){return {};}
public string function getCurrentEnvironment(){return 'prod';}
public string function getEnvironmentBaseUrl(any environment){return 'https://roadrunners.run';}
public any function buildEmptyApiIntegration(){return {};}
public boolean function isApiBearerCandidateRequest(){return false;}
public void function enforceBetaAccess(){arrayAppend(REQUEST.testOrder,'beta');}`;
 writeFileSync(resolve(scratch,'RequestFixture.cfc'),`<cfcomponent>${method}<cfscript>${stubs}</cfscript></cfcomponent>`);
 const result=spawnSync('/usr/bin/java',['-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox','execute','test.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,env:{...process.env,RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
 process.stdout.write(result.stdout+result.stderr);
 assert.equal(result.status,0);
 assert.ok(result.stdout.includes('LOCATION GLOBAL CONTRACT PASSED'),'real global-location contract must pass');
} finally {rmSync(scratch,{recursive:true,force:true});}
