import assert from 'node:assert/strict';
import {readFileSync,existsSync,mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {tmpdir} from 'node:os';
const stage=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const root=process.env.RR_CITY_SOURCE_ROOT || resolve(stage,'candidate');
const source=resolve(root,'includes/backend/backend_estado_cidades.cfm');
assert.ok(existsSync(source),'Counts for the current calendar are missing');
const code=readFileSync(source,'utf8');
const query=code.match(/<cfquery name="qEstadoCidadesContagens"[\s\S]*?<\/cfquery>/i)?.[0];
assert.ok(query,'Executable city counts query is required');
const fixture=`<cfsetting showdebugoutput="false"/><cfscript>
function check(required boolean condition,required string message){if(!condition)throw(message=message);VARIABLES.assertions++;}
function total(required string slug){for(var row in qEstadoCidadesContagens)if(row.tag_cidade==slug)return row.total_eventos;return 0;}
VARIABLES.assertions=0;
qEventosBase=queryNew('tag_cidade,cidade,data_final,tipo_corrida,cupom,pais,estado','varchar,varchar,date,varchar,varchar,varchar,varchar');
rows=[['salvador','Salvador',15,'rua','CUPOM','BR','BA'],['salvador','Salvador',80,'trail','CUPOM','BR','BA'],['feira-de-santana','Feira de Santana',20,'rua','CUPOM','BR','BA'],['salvador','Salvador',400,'rua','CUPOM','BR','BA'],['salvador','Salvador',-1,'rua','CUPOM','BR','BA'],['florianopolis','Florianópolis',10,'rua','CUPOM','BR','SC']];
for(row in rows){queryAddRow(qEventosBase,{tag_cidade=row[1],cidade=row[2],data_final=dateAdd('d',row[3],now()),tipo_corrida=row[4],cupom=row[5],pais=row[6],estado=row[7]});}
URL={tag='BA',cidade='salvador',tempo='0,1',rua=true,trail=true,nacional=true,internacional=false,cupom=false};
</cfscript>${query}<cfscript>
check(total('salvador')==1,'Current month must exclude past and later events');
check(total('feira-de-santana')==1,'Selected city must not hide the other city choices');
check(total('florianopolis')==0,'Cities must belong to the selected state');
URL.tempo='0,12';URL.rua=false;
</cfscript>${query}<cfscript>
check(total('salvador')==1,'Trail only must exclude street races');
check(total('feira-de-santana')==0,'Street-only city must have zero trail races');
URL.rua=true;URL.trail=true;URL.cupom=true;
</cfscript>${query}<cfscript>
check(total('salvador')==2,'Coupon and default period must match the calendar');
check(total('feira-de-santana')==1,'Coupon city alternatives remain available');
URL.nacional=false;URL.internacional=true;
</cfscript>${query}<cfscript>
check(qEstadoCidadesContagens.recordCount==0,'International only must exclude Brazilian events');
writeOutput('RR_CITY_COUNTS_PASSED:' & VARIABLES.assertions);
</cfscript>`;
if(process.argv.includes('--emit')) {writeFileSync(resolve(stage,'counts-fixture.cfm'),fixture);console.log('Fixture emitted');process.exit(0);}
const scratch=mkdtempSync(resolve(tmpdir(),'rr-city-counts-'));
try{
 writeFileSync(resolve(scratch,'fixture.cfm'),fixture);
 const run=spawnSync('/usr/bin/java',['-Xms128m','-Xmx768m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/runnerhub-audience-cfml.j0MZzV/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:4*1024*1024,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8',TMPDIR:scratch,RUNNERHUB_OFFLINE_CFML_TESTS:'1'}});
 const out=(run.stdout||'')+(run.stderr||'');
 assert.equal(run.status,0,out);
 assert.ok(out.includes('RR_CITY_COUNTS_PASSED:8'),out);
 console.log('CFML city counts: 8 assertions passed');
}finally{rmSync(scratch,{recursive:true,force:true});}
