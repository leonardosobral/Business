// Focused real HTTP POST regression for the workspace's filter-preserving forms.
import {mkdirSync,cpSync,writeFileSync,readFileSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {createServer} from 'node:net';

export async function runWorkspaceHttp({root,scratch,port,boxHome,execute}) {
 const app=resolve(scratch,'workspace-http');mkdirSync(app,{recursive:true});
 const copy=name=>{const dst=resolve(app,name);mkdirSync(dirname(dst),{recursive:true});cpSync(resolve(root,name),dst,{recursive:true});};
 for(const name of ['services','gestao-clientes','includes/parts/business_delegation_form.cfm'])copy(name);
 const datasource=`{class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="business_delegation_test",password=""}`;
 writeFileSync(resolve(app,'Application.cfc'),`component { this.name="DelegationWorkspaceHttpIsolated"; this.sessionManagement=true; this.datasource="runnerhub"; this.datasources={runnerhub=${datasource}}; this.mappings["/services"]="${app}/services"; function onApplicationStart(){application.businessAccountDelegationEnabled=true;return true;} function onRequestStart(target){application.businessAccountDelegationEnabled=true;request.businessDelegationIdentity={id=902,email="owner@example.test",emailVerified=true,accessMode="DIRECT"};request.businessDelegationService=createObject("component","services.BusinessAccountDelegation").init("runnerhub",true);return true;} }`);
 writeFileSync(resolve(app,'gestao-clientes/index.cfm'),'<cfinclude template="includes/backend.cfm"><cfinclude template="home.cfm">');
 mkdirSync(resolve(app,'WEB-INF/lib'),{recursive:true});
 cpSync(resolve(boxHome,'lib/lucee-5.3.10.120.jar'),resolve(app,'WEB-INF/lib/lucee.jar'));
 writeFileSync(resolve(app,'WEB-INF/web.xml'),readFileSync(resolve(boxHome,'cfml/system/config/web.xml'),'utf8'));
 cpSync(resolve(boxHome,'engine/cfml/cli/lucee-server/bundles'),resolve(scratch,'workspace-http-lucee/lucee-server/bundles'),{recursive:true});
 const listener=createServer();await new Promise(r=>listener.listen(0,'127.0.0.1',r));const httpPort=listener.address().port;await new Promise(r=>listener.close(r));
 mkdirSync(resolve(scratch,'workspace-http-tmp'),{recursive:true});
 const task=execute('/usr/bin/java',[`-Djava.io.tmpdir=${resolve(scratch,'workspace-http-tmp')}`,`-Dlucee.server.dir=${resolve(scratch,'workspace-http-lucee')}`,'-jar',resolve(boxHome,'lib/runwar-4.8.3.jar'),'-war',app,'-host','127.0.0.1','-p',String(httpPort),'-b','false','-open','false','-urlrewriteenable','false','-logDir',resolve(scratch,'workspace-http-logs')],undefined,{timeout:180000});
 let servletExit;task.then(result=>{servletExit=result;});
 let cookies='';const base=`http://127.0.0.1:${httpPort}`;
 const request=async(path,options={})=>{const response=await fetch(base+path,{redirect:'manual',...options,headers:{Cookie:cookies,...options.headers}});const set=response.headers.getSetCookie();if(set.length)cookies=set.map(c=>c.split(';')[0]).join('; ');return {status:response.status,body:await response.text(),location:response.headers.get('location')||''};};
 const assert=(ok,label,result)=>{if(!ok)throw Error(label+': '+JSON.stringify(result).slice(0,2400));};
 const decode=value=>value.replaceAll('&amp;','&').replace(/&#x([0-9a-f]+);/gi,(_,code)=>String.fromCharCode(parseInt(code,16))).replace(/&#([0-9]+);/g,(_,code)=>String.fromCharCode(Number(code)));
 const forms=body=>[...body.matchAll(/<form\b([^>]*)>([\s\S]*?)<\/form>/gi)].map(match=>({action:decode((match[1].match(/action="([^"]+)"/)||[])[1]||''),fields:Object.fromEntries([...match[2].matchAll(/<input\b[^>]*name="([^"]+)"[^>]*value="([^"]*)"[^>]*>/gi)].map(input=>[input[1],decode(input[2])]))}));
 const path='/gestao-clientes/?gestora=101&tab=equipe&busca=example%2Etest&estado=ATIVO&pagina=2';
 try {
  let ready;for(let attempt=0;attempt<120;attempt++){if(servletExit)throw Error('Servlet exited before ready: '+JSON.stringify(servletExit));try{const response=await request(path);if(response.status===200){ready=response;break;}if(response.status>=500)throw Error('Workspace servlet startup: '+response.body.slice(0,1800));}catch(error){if(!String(error).includes('fetch failed'))throw error;}await new Promise(r=>setTimeout(r,250));}
  assert(!!ready,'workspace HTTP ready',{});
  const pageForms=forms(ready.body).filter(form=>form.fields.business_delegation_action);
  assert(pageForms.some(form=>form.fields.business_delegation_action==='assign_member'),'page two assignment form rendered',ready);
  assert(pageForms.every(form=>form.action===path),'all page two POST actions retain tab/search/state/page',pageForms);
  const assignment=pageForms.find(form=>form.fields.business_delegation_action==='assign_member');
  const invalid={...assignment.fields,assignment_target:'invalid'};
  const failed=await request(assignment.action,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(invalid)});
  assert(failed.status===200&&failed.body.includes('Revise os campos'),'invalid POST returns local error',failed);
  const failedForms=forms(failed.body).filter(form=>form.fields.business_delegation_action);
  assert(failed.body.includes('aria-current="page"')&&failedForms.some(form=>form.fields.business_delegation_action==='assign_member')&&failedForms.every(form=>form.action===path),'failed POST retains Equipe form and context',failed);
  const removal=pageForms.find(form=>form.fields.business_delegation_action==='remove_assignment');
  assert(!!removal,'page two has a real removal action',pageForms);
  const succeeded=await request(removal.action,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(removal.fields)});
  assert(succeeded.status===302&&succeeded.location.includes('tab=equipe')&&succeeded.location.includes('busca=example%2Etest')&&succeeded.location.includes('estado=ATIVO')&&succeeded.location.includes('pagina=2'),'successful POST redirects to same filtered workspace',succeeded);
  console.log('PASS workspace actual HTTP rendered page-two forms, invalid POST and successful PRG retain context');
 } finally {task.child.kill('SIGTERM');await task;}
}
