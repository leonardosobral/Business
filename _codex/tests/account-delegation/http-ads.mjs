// Actual Ads boundary, status endpoint and paid-banner backend in a private localhost servlet.
import {mkdirSync,cpSync,writeFileSync,readFileSync,existsSync,readdirSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {createServer} from 'node:net';
export async function runAdsHttp({root,scratch,port,boxHome,execute,sql}) {
 const app=resolve(scratch,'ads-http');mkdirSync(app,{recursive:true});
 const copy=name=>{const dst=resolve(app,name);mkdirSync(dirname(dst),{recursive:true});if(existsSync(resolve(root,name)))cpSync(resolve(root,name),dst,{recursive:true});};
 for(const name of ['services','includes/backend','includes/parts/business_delegation_form.cfm','ads/components','ads/includes','api/ads/payments/status.cfm','portal/includes'])copy(name);
 const ds=user=>`{class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="${user}",password=""}`;
 const settings=`<cfset THIS.datasource="runnerhub"/><cfset THIS.datasources={business_delegation_test=${ds('business_delegation_test')},runnerhub=${ds('runnerhub')}}/><cfset THIS.mappings["/services"]="${app}/services"/><cfset THIS.mappings["/ads"]="${app}/ads"/>`;
 let source=readFileSync(resolve(root,'Application.cfc'),'utf8').replace('secure=true','secure=false').replace('<cfset THIS.datasource = "runner_dba"/>',settings);
 source=source.replace(/<cffunction\s+name="OnApplicationStart"[\s\S]*?<\/cffunction>/,'<cffunction name="OnApplicationStart" returntype="boolean"><cfset APPLICATION.businessAccountDelegationEnabled=true/><cfreturn true/></cffunction>');writeFileSync(resolve(app,'Application.cfc'),source);
 for(const [name,id] of [['manager',903],['buyer',902]])writeFileSync(resolve(app,`bootstrap-${name}.cfm`),`<cfscript>createObject('component','services.BusinessAuthSession').establish(SESSION,${id},{sub='synthetic-verified',email='${name}@example.test',name='Synthetic',picture=''});SESSION.businessRememberCheckedAt=now();SESSION.businessAccessSelection={accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001};writeOutput('READY');</cfscript>`);
 mkdirSync(resolve(app,'portal/banners/assets'),{recursive:true});
 // Counter exists in the private copy only, immediately before the real upload call.
 const backend=resolve(app,'portal/includes/paid_banner_backend.cfm');writeFileSync(backend,readFileSync(backend,'utf8').replace('<cffile action="upload"','<cfset REQUEST.fixtureUploadAttempts++/><cffile action="upload"').replaceAll('<cfcatch type="any">','<cfcatch type="any"><cfset REQUEST.fixtureCaughtType=cfcatch.type/>'));
 writeFileSync(resolve(app,'portal/banners/index.cfm'),`<cfinclude template="../../ads/includes/access.cfm"><cfset REQUEST.fixtureUploadAttempts=0/><cfset REQUEST.fixtureCaughtType=""/>
 <cfif CGI.request_method EQ 'POST' AND structKeyExists(FORM,'fixture_midrevoke')><cfquery datasource="business_delegation_test">UPDATE tb_conta_gestao_vinculos SET status='REVOGADO',version=version+1 WHERE id_vinculo=2001</cfquery></cfif>
 <cfinclude template="../includes/paid_banner_backend.cfm">
 <cfif CGI.request_method EQ 'GET'><cfset VARIABLES.paidBannerBannersUrl="/portal/banners/"/><cfset VARIABLES.paidBannerFormActionUrl="/portal/banners/index.cfm"/><cfinclude template="../includes/paid_banner_form.cfm"><cfelse><cfoutput>UPLOADS=#REQUEST.fixtureUploadAttempts# NEWFILES=#arrayLen(VARIABLES.paidBannerNewFiles)# TYPE=#REQUEST.fixtureCaughtType# ERROR=#encodeForHTML(VARIABLES.paidBannerError)#</cfoutput></cfif>`);
 mkdirSync(resolve(app,'WEB-INF/lib'),{recursive:true});cpSync(resolve(boxHome,'lib/lucee-5.3.10.120.jar'),resolve(app,'WEB-INF/lib/lucee.jar'));writeFileSync(resolve(app,'WEB-INF/web.xml'),readFileSync(resolve(boxHome,'cfml/system/config/web.xml'),'utf8'));
 cpSync(resolve(boxHome,'engine/cfml/cli/lucee-server/bundles'),resolve(scratch,'ads-http-lucee/lucee-server/bundles'),{recursive:true});
 const listener=createServer();await new Promise(r=>listener.listen(0,'127.0.0.1',r));const httpPort=listener.address().port;await new Promise(r=>listener.close(r));
 mkdirSync(resolve(scratch,'ads-http-tmp'),{recursive:true});
 const task=execute('/usr/bin/java',[`-Djava.io.tmpdir=${resolve(scratch,'ads-http-tmp')}`,`-Dlucee.server.dir=${resolve(scratch,'ads-http-lucee')}`,'-jar',resolve(boxHome,'lib/runwar-4.8.3.jar'),'-war',app,'-host','127.0.0.1','-p',String(httpPort),'-b','false','-open','false','-urlrewriteenable','false','-logDir',resolve(scratch,'ads-http-logs')],undefined,{timeout:180000});
 let cookies='';const request=async(path,options={})=>{const response=await fetch(`http://127.0.0.1:${httpPort}`+path,{redirect:'manual',...options,headers:{Cookie:cookies,Host:'business.roadrunners.run',...options.headers}});const set=response.headers.getSetCookie();if(set.length)cookies=set.map(c=>c.split(';')[0]).join('; ');return {status:response.status,body:await response.text()};};
 const assert=(ok,label,result)=>{if(!ok){if(result?.body)writeFileSync(resolve(root,'../task-9-http-response.html'),result.body);for(const name of readdirSync(app,{recursive:true}))if(String(name).endsWith('business_ads_v1.log'))writeFileSync(resolve(root,'../task-9-http-backend.log'),readFileSync(resolve(app,name)));throw Error(label+': '+JSON.stringify(result).slice(0,500));}};
 const fields=body=>Object.fromEntries([...body.matchAll(/<input[^>]*type="hidden"[^>]*name="([^"]+)"[^>]*value="([^"]*)"/g)].map(x=>[x[1].toLowerCase(),x[2].replaceAll('&amp;','&').replace(/&#x([0-9a-f]+);/gi,(_,n)=>String.fromCharCode(parseInt(n,16)))]));
 try{
  let ready=false;for(let i=0;i<120;i++){try{const r=await request('/bootstrap-manager.cfm');if(r.status===200&&r.body.includes('READY')){ready=true;break;}if(r.status>=500)throw Error(r.body.slice(0,1800));}catch(e){if(!String(e).includes('fetch failed'))throw e;}await new Promise(r=>setTimeout(r,250));}assert(ready,'HTTP ready',{});
  const form=await request('/portal/banners/index.cfm?novo=1');assert(form.status===200&&form.body.toLowerCase().includes('business_access_token'),'actual paid banner form signed',form);
  const posted=fields(form.body);assert(posted.paid_banner_csrf&&posted.business_access_token,'both actual form tokens',posted);
  const upload=new FormData();for(const [k,v] of Object.entries(posted))upload.append(k,v);
  for(const [k,v] of Object.entries({fixture_midrevoke:'1',save_intent:'draft',name:'Revoked synthetic banner',alt_text:'Synthetic banner',destination_url:'https://example.test/banner',starts_at:'2026-10-03T12:00',ends_at:'2026-10-10T12:00',cpc_bid:'1',budget_total:'10',target_device:'ALL',banner_regions_mode:'ALL',banner_pages_mode:'ALL'}))upload.append(k,v);
  upload.append('banner_arquivo_desktop',new Blob([Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7','base64')],{type:'image/gif'}),'fixture.gif');
  const before=await sql('SELECT count(*) FROM ads.campaigns');
  const denied=await request('/portal/banners/index.cfm',{method:'POST',body:upload});
  assert(denied.status===200&&denied.body.includes('UPLOADS=0 NEWFILES=0 TYPE=BusinessDelegation.Forbidden ERROR=')&&!denied.body.includes('ERROR=\n'),'mid-request revocation before actual cffile',denied);
  assert((await sql('SELECT count(*) FROM ads.campaigns'))===before,'no revoked banner mutation',{});assert(readdirSync(resolve(app,'portal/banners/assets')).length===0,'no uploaded asset',{});
  await sql("UPDATE tb_conta_gestao_vinculos SET status='ATIVO',version=version+1 WHERE id_vinculo=2001");
  const stale=await request('/portal/banners/index.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(posted)});assert(stale.status===409,'old actual form cannot mutate new version',stale);
  cookies='';assert((await request('/bootstrap-buyer.cfm')).status===200,'buyer auth',{});
  const own=(await sql("SELECT payment_intent_id FROM ads.payment_intents WHERE idempotency_key='business:payment:uncertain-checkout'")).trim();
  const other=(await sql("SELECT payment_intent_id FROM ads.payment_intents WHERE idempotency_key='business:payment:other-actor'")).trim();
  const ownStatus=await request('/api/ads/payments/status.cfm?payment='+own);assert(ownStatus.status===200&&JSON.parse(ownStatus.body).SUCCESS,'actual own receipt status endpoint',ownStatus);
  const foreign=await request('/api/ads/payments/status.cfm?payment='+other);assert(foreign.status===403,'actual endpoint denies other actor receipt',foreign);
  console.log('PASS ads actual signed banner form, mid-request revoked multipart before upload, stale version, own/foreign status endpoint');
 }finally{task.child.kill('SIGTERM');await task;}
}
