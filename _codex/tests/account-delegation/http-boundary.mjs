// Disposable localhost servlet runtime. Uses production lifecycle/includes; fixtures only authenticate
// synthetic actors and expose counters. No production configuration or identity bypass is copied.
import {mkdirSync,cpSync,writeFileSync,readFileSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {createServer} from 'node:net';
export async function runBoundaryHttp({root,scratch,port,boxHome,execute,sql,env}) {
 const app=resolve(scratch,'http');mkdirSync(app,{recursive:true});
 const copy=name=>{const dst=resolve(app,name);mkdirSync(dirname(dst),{recursive:true});if(existsSync(resolve(root,name)))cpSync(resolve(root,name),dst,{recursive:true});};
 for(const name of ['services','includes/backend','includes/parts/business_delegation_form.cfm','includes/estrutura/account_context_modal.cfm','includes/estrutura/navbar.cfm','includes/estrutura/sidenav.cfm','includes/estrutura/home_delegated_account.cfm','selecionar-conta/index.cfm','leaderboard/api/leaderboard.cfc','leaderboard/api/transmissao.cfc'])copy(name);
 const datasource=`{class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="business_delegation_test",password=""}`;
 const settings=`<cfset THIS.datasource="business_delegation_test"/><cfset THIS.datasources={business_delegation_test=${datasource},runnerhub=${datasource},runner_dba=${datasource}}/><cfset THIS.mappings["/services"]="${app}/services"/>`;
 for(const name of ['Application.cfc','bi/Application.cfc']) {
  let source=readFileSync(resolve(root,name),'utf8').replace('secure=true','secure=false').replace('<cfset THIS.datasource = "runner_dba"/>',settings);
  if(name==='Application.cfc') source=source.replace(/<cffunction\s+name="OnApplicationStart"[\s\S]*?<\/cffunction>/,'<cffunction name="OnApplicationStart" returntype="boolean"><cfset APPLICATION.businessAccountDelegationEnabled=true/><cfreturn true/></cffunction>');
  source=source.replace('<cfset ApplicationStop()>',`<cfquery>INSERT INTO boundary_http_counter(marker) VALUES('GLOBAL_RESET')</cfquery><cfset ApplicationStop()>`);
  mkdirSync(dirname(resolve(app,name)),{recursive:true});writeFileSync(resolve(app,name),source);
 }
 await sql('CREATE TABLE boundary_http_counter(marker text); CREATE TABLE tb_conta_eventos(id_conta bigint,id_evento integer,status text); INSERT INTO tb_conta_eventos VALUES(102,551,\'ATIVO\');');
 mkdirSync(resolve(app,'ads'),{recursive:true});
 writeFileSync(resolve(app,'ads/index.cfm'),`<cfif CGI.request_method EQ "POST"><cfquery>INSERT INTO boundary_http_counter(marker) VALUES('AUTHORIZED_MUTATION')</cfquery><cfoutput>MUTATED</cfoutput><cfelse><form method="post"><input type="hidden" name="ads_v1_action" value="save_campaign"><cfinclude template="../includes/parts/business_delegation_form.cfm"></form></cfif>`);
 mkdirSync(resolve(app,'portal/banners'),{recursive:true});mkdirSync(resolve(app,'fixture-uploads'),{recursive:true});
 writeFileSync(resolve(app,'portal/banners/index.cfm'),`<cfif CGI.request_method EQ "POST"><cfquery>INSERT INTO boundary_http_counter(marker) VALUES('MULTIPART_HANDLER')</cfquery><cffile action="upload" filefield="banner_arquivo_desktop" destination="#expandPath('/fixture-uploads')#" nameconflict="makeunique" result="fixtureFile"><cfoutput>MULTIPART_OK #fixtureFile.fileSize#</cfoutput><cfelse><form method="post" enctype="multipart/form-data"><input type="hidden" name="paid_banner_action" value="save"><cfinclude template="../../includes/parts/business_delegation_form.cfm"></form></cfif>`);
 const counter=`<cfquery>INSERT INTO boundary_http_counter(marker) VALUES('BUSINESS_DATA')</cfquery><cfoutput>UNSAFE BUSINESS BODY</cfoutput>`;
 for(const path of ['crm/index.cfm','bi/index.cfm','administracao/contas/index.cfm','inscricoes/index.cfm','cupons/index.cfm','saude-eventos/index.cfm','importacoes/index.cfm','api/ads/payments/webhook.cfm','api/ads/payments/reconcile.cfm','api/event-description-rewrite.cfm','api/percursos/index.cfm']) {mkdirSync(dirname(resolve(app,path)),{recursive:true});writeFileSync(resolve(app,path),counter);}
 writeFileSync(resolve(app,'bootstrap.cfm'),`<cfscript>auth=createObject('component','services.BusinessAuthSession');auth.establish(SESSION,902,{sub='synthetic-verified',email='owner@example.test',name='Manager Owner',picture=''});SESSION.businessRememberCheckedAt=now();SESSION.businessAccessSelection={accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001};writeOutput('READY');</cfscript>`);
 for(const [name,id,email,selection] of [
  ['bootstrap-direct.cfm',902,'owner@example.test',"{accountId=101,accessMode='DIRECT',managerAccountId=0,relationshipId=0}"],
  ['bootstrap-simulation.cfm',901,'reviewer@example.test',"{accountId=102,accessMode='INTERNAL_SIMULATION',managerAccountId=0,relationshipId=0}"]]) {
  writeFileSync(resolve(app,name),`<cfscript>createObject('component','services.BusinessAuthSession').establish(SESSION,${id},{sub='synthetic-verified',email='${email}',name='Synthetic',picture=''});SESSION.businessRememberCheckedAt=now();SESSION.businessAccessSelection=${selection};writeOutput('READY');</cfscript>`);
 }
 mkdirSync(resolve(app,'convites'),{recursive:true});writeFileSync(resolve(app,'convites/index.cfm'),counter);
 writeFileSync(resolve(app,'index.cfm'),`<cfinclude template="includes/backend/backend_login.cfm"><cfinclude template="includes/estrutura/navbar.cfm"><cfinclude template="includes/estrutura/sidenav.cfm"><cfinclude template="includes/backend/business_request_identity.cfm"><cfoutput>MODE=#REQUEST.businessDelegationIdentity.accessMode# AUTHORIZED #REQUEST.businessAccessContext.accountId# USERS=#VARIABLES.businessEffectiveUserIds# BI=#qPermissoes.recordCount#</cfoutput>`);
 mkdirSync(resolve(app,'WEB-INF/lib'),{recursive:true});
 cpSync(resolve(boxHome,'lib/lucee-5.3.10.120.jar'),resolve(app,'WEB-INF/lib/lucee.jar'));
 writeFileSync(resolve(app,'WEB-INF/web.xml'),readFileSync(resolve(boxHome,'cfml/system/config/web.xml'),'utf8').replace('<url-pattern>/index.cfm/*</url-pattern>','<url-pattern>/index.cfm/*</url-pattern><url-pattern>/convites/index.cfm/*</url-pattern>'));
 // Reuse cached engine bundles offline in a private server context, avoiding downloads/config mutation.
 cpSync(resolve(boxHome,'engine/cfml/cli/lucee-server/bundles'),resolve(scratch,'http-lucee/lucee-server/bundles'),{recursive:true});
 const listener=createServer();await new Promise(r=>listener.listen(0,'127.0.0.1',r));const httpPort=listener.address().port;await new Promise(r=>listener.close(r));
 mkdirSync(resolve(scratch,'http-tmp'),{recursive:true});
 const task=execute('/usr/bin/java',[`-Djava.io.tmpdir=${resolve(scratch,'http-tmp')}`, `-Dlucee.server.dir=${resolve(scratch,'http-lucee')}`,'-jar',resolve(boxHome,'lib/runwar-4.8.3.jar'),'-war',app,'-host','127.0.0.1','-p',String(httpPort),'-b','false','-open','false','-urlrewriteenable','false','-logDir',resolve(scratch,'http-logs')],undefined,{timeout:180000});
 let cookies='';const url=`http://127.0.0.1:${httpPort}`;
 const request=async(path,options={})=>{const response=await fetch(url+path,{redirect:'manual',...options,headers:{Cookie:cookies,...options.headers}});const set=response.headers.getSetCookie();if(set.length)cookies=set.map(c=>c.split(';')[0]).join('; ');return {status:response.status,body:await response.text()};};
 const parseFields=body=>Object.fromEntries([...body.matchAll(/name="([^"]+)"[^>]*value="([^"]*)"/g)].map(x=>[x[1].toLowerCase(),x[2].replaceAll('&amp;','&').replace(/&#x([0-9a-f]+);/gi,(_,n)=>String.fromCharCode(parseInt(n,16)))]));
 const assert=(ok,label,result)=>{if(!ok)throw Error(label+': '+JSON.stringify(result).slice(0,2200));};
 try {
  let ready=false;for(let i=0;i<120;i++){try{const r=await request('/bootstrap.cfm');if(r.status===200&&r.body.includes('READY')){ready=true;break;}if(r.status>=500)throw Error('Servlet startup: '+r.body.slice(0,1800));}catch(error){if(!String(error).includes('fetch failed'))throw error;}await new Promise(r=>setTimeout(r,250));}
  assert(ready,'HTTP runtime ready',{});
  for(const path of ['/crm/index.cfm','/bi/index.cfm','/leaderboard/api/leaderboard.cfc?method=rankingToHTML&returnformat=json','/leaderboard/api/transmissao.cfc?method=ranking&returnformat=json']) {
   const r=await request(path);assert(r.status===403,'HTTP before business data '+path,r);
  }
  // Runtime-denied inventory: each route traverses the actual lifecycle, before target execution.
  for(const path of ['/administracao/contas/','/inscricoes/','/cupons/','/saude-eventos/','/importacoes/','/includes/backend/backend_login.cfm','/api/ads/payments/webhook.cfm','/api/ads/payments/reconcile.cfm','/api/event-description-rewrite.cfm','/api/percursos/index.cfm']) {
   for(const method of ['GET','POST']){const r=await request(path,{method});assert(r.status===403,'denied route inventory '+method+' '+path,r);}
  }
  for(const method of ['PUT','PATCH','DELETE']){const r=await request('/ads/index.cfm',{method});assert([403,405].includes(r.status),'unsupported verb '+method,r);}
  for(const body of ['ads_v1_action=unknown','ads_v1_action=save_campaign&ads_v1_action=save_campaign','ads_v1_action[]=save_campaign','ads_v1_action=save_campaign&account_id[]=102']) {
   const r=await request('/ads/index.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body});assert(r.status===403,'unknown action/duplicate/array before handler',r);
  }
  console.log('PASS boundary actual denied route inventory, unsupported verbs, unknown action, arrays and duplicate fields');
  assert((await sql('SELECT count(*) FROM boundary_http_counter')).trim()==='0','zero denied target queries',{});
  const remotePost=await request('/leaderboard/api/leaderboard.cfc',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'method=rankingToHTML&returnformat=json'});assert(remotePost.status===403,'remote POST before invocation',remotePost);
  const home=await request('/index.cfm');assert(home.status===200&&home.body.includes('MODE=DELEGATED AUTHORIZED 102 USERS=0 BI=0'),'authorized home/menu no forbidden module queries',home);
  const duplicate=await request('/index.cfm?x=1&x=1');assert(duplicate.status===403,'raw duplicate HTTP rejection',duplicate);
  const renderedForm=await request('/ads/index.cfm');assert(renderedForm.status===200,'integrated form renders',renderedForm);
  const mutationFields=parseFields(renderedForm.body);assert(!!mutationFields.business_access_token,'real form include token',mutationFields);
  const submitMutation=()=>request('/ads/index.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(mutationFields)});
  const mutation=await submitMutation();assert(mutation.status===200&&mutation.body.includes('MUTATED'),'current signed form reaches own handler',mutation);
  assert((await sql("SELECT count(*) FROM boundary_http_counter WHERE marker='AUTHORIZED_MUTATION'")).trim()==='1','one current-context mutation',{});
  const bannerForm=await request('/portal/banners/index.cfm');assert(bannerForm.status===200,'multipart banner form renders',bannerForm);
  const bannerFields=parseFields(bannerForm.body);
  const multipart=async(names,collections=false,extra=[])=>{
   const data=new FormData();for(const [key,value] of Object.entries(bannerFields)) data.append(key,value);
   for(const name of names)data.append('name',name);
   data.append('banner_arquivo_desktop',new Blob([Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7','base64')],{type:'image/gif'}),'fixture.gif');
   if(collections){data.append('banner_pages_mode','SELECTED');data.append('banner_pages','home');data.append('banner_pages','event');data.append('banner_regions_mode','SELECTED');data.append('banner_regions','SP');data.append('banner_regions','RJ');}
   for(const [key,value] of extra)data.append(key,value);
   return request('/portal/banners/index.cfm',{method:'POST',body:data});
  };
  for(const values of [['alpha','alpha'],['alpha','beta']]) {
   const before=(await sql("SELECT count(*) FROM boundary_http_counter WHERE marker='MULTIPART_HANDLER'")).trim();
   const repeated=await multipart(values);const after=(await sql("SELECT count(*) FROM boundary_http_counter WHERE marker='MULTIPART_HANDLER'")).trim();
   assert(repeated.status===403,'multipart repeated scalar rejected '+values.join('/'),{...repeated,before,after});
   assert(before===after,'multipart rejected before upload handler',{before,after});
  }
  for(const extra of [
   [['banner_arquivo_desktop',new Blob(['duplicate fixture'],{type:'image/gif'})]],
   [['banner_pages','home']],
   [['paid_banner_action','save']]
  ]) {
   const before=(await sql("SELECT count(*) FROM boundary_http_counter WHERE marker='MULTIPART_HANDLER'")).trim();
   const malformed=await multipart(['unique'],true,extra);const after=(await sql("SELECT count(*) FROM boundary_http_counter WHERE marker='MULTIPART_HANDLER'")).trim();
   assert(malformed.status===403,'multipart duplicate file/action or repeated collection value denied '+extra[0][0],{...malformed,before,after});
   assert(before===after,'malformed multipart before handler',{before,after});
  }
  const validMultipart=await multipart(['alpha,beta'],true);assert(validMultipart.status===200&&validMultipart.body.includes('MULTIPART_OK'),'unique multipart scalar with genuine comma and supported checkbox collections preserves upload',validMultipart);
  console.log('PASS boundary actual multipart duplicate scalars/file/action rejected; unique banner upload and declared collections accepted');
  const selector=await request('/selecionar-conta/index.cfm');
  assert(selector.status===200&&selector.body.toLowerCase().includes('business_selection_csrf')&&selector.body.includes('DELEGATED'),'HTML selector exposes independent access paths',selector);
  const forms=[...selector.body.matchAll(/<form\b[^>]*>([\s\S]*?)<\/form>/gi)].map(m=>parseFields(m[1]));
  const choice=forms.find(f=>f.accessmode==='DELEGATED'&&f.manageraccountid==='103');assert(!!choice,'second agency option present',forms);
  const post=async(fields)=>request('/selecionar-conta/index.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(fields)});
  const switched=await post(choice);assert(switched.status===302,'non-JS selector redirect',switched);
  const staleMutation=await submitMutation();assert(staleMutation.status===409,'old integrated form cannot mutate switched access',staleMutation);
  assert((await sql("SELECT count(*) FROM boundary_http_counter WHERE marker='AUTHORIZED_MUTATION'")).trim()==='1','stale form adds zero mutations',{});
  const stale=await post(choice);assert(stale.status===409,'stale tab selector rejected',stale);
  const newHome=await request('/index.cfm');assert(newHome.status===200&&!newHome.body.includes('href="/ads/"'),'new agency capabilities exclusively applied',newHome);
  await sql("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO' WHERE id_vinculo=2002");
  const revoked=await request('/index.cfm');assert(revoked.status===403,'revoked HTTP selection has no fallback',revoked);
  await sql("UPDATE tb_conta_gestao_vinculos SET status='ATIVO' WHERE id_vinculo=2002");
  const stillInvalid=await request('/index.cfm');assert(stillInvalid.status===403,'invalid HTTP selection persists',stillInvalid);
  const recovery=await request('/selecionar-conta/index.cfm');assert(recovery.status===200&&recovery.body.includes('Escolha novamente'),'recovery selector works after revocation',recovery);
  const recoveryForms=[...recovery.body.matchAll(/<form\b[^>]*>([\s\S]*?)<\/form>/gi)].map(m=>parseFields(m[1]));
  const concurrentChoices=[recoveryForms.find(f=>f.accessmode==='DELEGATED'&&f.manageraccountid==='101'),recoveryForms.find(f=>f.accessmode==='DELEGATED'&&f.manageraccountid==='103')];
  const concurrent=await Promise.all(concurrentChoices.map(post));
  assert(concurrent.filter(r=>r.status===302).length===1&&concurrent.filter(r=>r.status===409).length===1,'concurrent selectors serialize expected state',concurrent);
  for(const mode of ['direct','simulation']) for(const suffix of ['?resetApp=1','?x=1&x=1','/unexpected']) {
   await sql("UPDATE tb_conta_usuarios SET status='ATIVO' WHERE id_conta_usuario=1001; UPDATE tb_usuarios SET is_admin=true WHERE id=901");
   cookies='';const boot=await request('/bootstrap-'+mode+'.cfm');assert(boot.status===200&&boot.body.includes('READY'),'synthetic fresh '+mode,boot);
   await sql(mode==='direct'?"UPDATE tb_conta_usuarios SET status='INATIVO' WHERE id_conta_usuario=1001":"UPDATE tb_usuarios SET is_admin=false WHERE id=901");
   const before=(await sql('SELECT count(*) FROM boundary_http_counter')).trim();
   const path=(suffix.startsWith('?resetApp')?'/selecionar-conta/index.cfm':'/convites/index.cfm')+suffix;
   const denied=await request(path);const after=(await sql('SELECT count(*) FROM boundary_http_counter')).trim();
   assert(denied.status===403,'first invalidated '+mode+' recovery rejects '+suffix,{...denied,before,after});
   assert(before===after,'recovery before target/global action '+mode+suffix,{before,after});
  }
  await sql("UPDATE tb_conta_usuarios SET status='ATIVO' WHERE id_conta_usuario=1001; UPDATE tb_usuarios SET is_admin=true WHERE id=901");
  cookies='';await request('/bootstrap-direct.cfm');
  const legacyMultipart=new FormData();legacyMultipart.append('paid_banner_action','save');legacyMultipart.append('name','alpha');legacyMultipart.append('name','beta');
  legacyMultipart.append('banner_arquivo_desktop',new Blob([Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7','base64')],{type:'image/gif'}),'legacy-fixture.gif');
  const directTransport=await request('/portal/banners/index.cfm',{method:'POST',body:legacyMultipart});
  assert(directTransport.status===200&&directTransport.body.includes('MULTIPART_OK'),'ordinary direct multipart boundary preserves existing handler contract',directTransport);
  console.log('PASS boundary ordinary DIRECT multipart transport remains on its legacy handler/CSRF path');
  console.log('PASS boundary actual HTTP newly invalidated DIRECT/SIMULATION recovery rejects reset/duplicates/PATH_INFO before target/global actions');
  console.log('PASS boundary actual integrated form HMAC/current mutation/stale mutation and revoked session recovery');
  console.log('PASS boundary actual HTML selector POST/CSRF/stale-tab and separate agency menus');
  console.log('PASS boundary actual HTTP root, nested BI and remote CFC; zero denied business queries');
  console.log('PASS boundary actual HTTP delegated backend/menu; no forbidden module schema installed');
 } finally {task.child.kill('SIGTERM');const stopped=await task;if(stopped.status!==143&&stopped.status!==0&&stopped.status!==null)console.log('HTTP runtime shutdown status '+stopped.status);}
}
