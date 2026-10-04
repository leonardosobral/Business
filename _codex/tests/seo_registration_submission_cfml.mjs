import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,copyFileSync,existsSync,writeFileSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
const scratch=mkdtempSync('/private/tmp/seo-registration-submission-');
try {
 mkdirSync(scratch+'/services');
 for(const n of ['EventRegistrationAvailability','EventRegistrationAvailabilityService']) if(existsSync('services/'+n+'.cfc'))copyFileSync('services/'+n+'.cfc',scratch+'/services/'+n+'.cfc');
 writeFileSync(scratch+'/fixture.cfm',`<cfscript>
settings=getApplicationSettings();mappings=duplicate(settings.mappings);mappings['/services']=getDirectoryFromPath(getCurrentTemplatePath()) & 'services';application action='update' mappings=mappings;
service=new services.EventRegistrationAvailabilityService();
base={status='open',source_url='https://organizador.example/prova',registration_url='https://inscricao.example/prova',confirmed='1'};
rows=[];cases=[];
for(status in ['open','sold_out','preorder','closed','unknown']) {s=duplicate(base);s.status=status;arrayAppend(cases,{data=s,admin=true,post=true,csrf=true});}
s=duplicate(base);s.confirmed='';arrayAppend(cases,{data=s,admin=true,post=true,csrf=true});
s=duplicate(base);s.source_url='javascript:alert(1)';arrayAppend(cases,{data=s,admin=true,post=true,csrf=true});
s=duplicate(base);s.status='InStock';arrayAppend(cases,{data=s,admin=true,post=true,csrf=true});
s=duplicate(base);s.source_url='https://user:password@example.org/';arrayAppend(cases,{data=s,admin=true,post=true,csrf=true});
arrayAppend(cases,{data=base,admin=false,post=true,csrf=true});arrayAppend(cases,{data=base,admin=true,post=false,csrf=true});arrayAppend(cases,{data=base,admin=true,post=true,csrf=false});
for(test in cases){try{saved=service.validateSubmission(test.data,test.admin,test.post,test.csrf);arrayAppend(rows,{accepted=true,status=saved.status});}catch(any rejected){arrayAppend(rows,{accepted=false});}}
writeOutput('SUBMISSION_RESULTS:' & serializeJSON(rows));
</cfscript>`);
 const r=spawnSync('/usr/bin/java',['-Xms128m','-Xmx512m','-Dfile.encoding=UTF-8','-cp','/Users/Shared/Projects/ColdFusion Certification/box','cliloader.LoaderCLIMain','-CommandBox_home=/private/tmp/seo-availability-cfml-20261003/commandbox','execute','fixture.cfm'],{cwd:scratch,encoding:'utf8',timeout:60000,maxBuffer:3e6,env:{PATH:process.env.PATH,LC_ALL:'en_US.UTF-8'}});
 assert.equal(r.status,0,r.stdout+r.stderr);
 const m=r.stdout.match(/SUBMISSION_RESULTS:(\[[^\n]*\])/);assert.ok(m,r.stdout);
 const rows=JSON.parse(m[1]).map(r=>Object.fromEntries(Object.entries(r).map(([k,v])=>[k.toLowerCase(),v])));
 for(let i=0;i<5;i++)assert.equal(rows[i].accepted,true);
 for(let i=5;i<12;i++)assert.equal(rows[i].accepted,false,'Unconfirmed/unsafe/unauthorized submission '+i+' must fail');
 console.log('CFML submissions: 5 valid statuses and 7 refusal cases passed.');
}finally{rmSync(scratch,{recursive:true,force:true});}
