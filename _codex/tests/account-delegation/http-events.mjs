import {mkdirSync,cpSync,writeFileSync,readFileSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {createServer} from 'node:net';
export async function runEventsHttp({root,scratch,port,boxHome,execute,sql}) {
 const app=resolve(scratch,'events-http');mkdirSync(app,{recursive:true});
 const copy=name=>{const dst=resolve(app,name);mkdirSync(dirname(dst),{recursive:true});if(existsSync(resolve(root,name)))cpSync(resolve(root,name),dst,{recursive:true});};
 for(const name of ['services','includes/backend','includes/parts','eventos','_codex/tests/account-delegation'])copy(name);
 const ds=user=>`{class="org.postgresql.Driver",bundleName="org.postgresql.jdbc",bundleVersion="42.2.20",connectionString="jdbc:postgresql://127.0.0.1:${port}/business_delegation_test",username="${user}",password=""}`;
 const settings=`<cfset THIS.datasource="runner_dba"/><cfset THIS.datasources={business_delegation_test=${ds('business_delegation_test')},runnerhub=${ds('runnerhub')},runner_dba=${ds('runner_dba')}}/><cfset THIS.mappings["/services"]="${app}/services"/>`;
 let source=readFileSync(resolve(root,'Application.cfc'),'utf8').replace('secure=true','secure=false').replace('<cfset THIS.datasource = "runner_dba"/>',settings);
 source=source.replace(/<cffunction\s+name="OnApplicationStart"[\s\S]*?<\/cffunction>/,'<cffunction name="OnApplicationStart" returntype="boolean"><cfset APPLICATION.businessAccountDelegationEnabled=true/><cfreturn true/></cffunction>');writeFileSync(resolve(app,'Application.cfc'),source);
 writeFileSync(resolve(app,'suite.cfm'),`<cfinclude template="_codex/tests/account-delegation/assertions.cfm"><cfinclude template="_codex/tests/account-delegation/events.cfm"><cfoutput>PASS events CFML</cfoutput>`);
 for(const [name,id] of [['manager',903],['owner',902],['viewer',905]])writeFileSync(resolve(app,`bootstrap-${name}.cfm`),`<cfscript>createObject('component','services.BusinessAuthSession').establish(SESSION,${id},{sub='synthetic-verified',email='${name}@example.test',name='Synthetic',picture=''});SESSION.businessRememberCheckedAt=now();SESSION.businessAccessSelection={accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001};writeOutput('READY');</cfscript>`);
 // Exercise the real Events entry catch and handlers; the unrelated listing is omitted in this focused fixture.
 const entry=readFileSync(resolve(root,'eventos/home.cfm'),'utf8').split('<!--- FILTROS --->')[0].replace('<cfinclude template="includes/backend/backend.cfm"/>','');
 writeFileSync(resolve(app,'eventos/index.cfm'),`<cfquery name="qPerfil">SELECT * FROM tb_usuarios WHERE id=<cfqueryparam value="#REQUEST.businessIdentity.id#" cfsqltype="cf_sql_integer"/></cfquery>
 <cfif CGI.request_method EQ 'POST' AND structKeyExists(FORM,'fixture_stale')><cfquery datasource="business_delegation_test">UPDATE tb_conta_gestao_vinculos SET version=version+1 WHERE id_vinculo=2001</cfquery></cfif>
 ${entry}
 <cfif CGI.request_method EQ 'GET'>
 <cfif len(URL.evento_referencia)><cfinclude template="solicitacoes_eventos.cfm"><cfelseif URL.sessao EQ 'percursos'><cfinclude template="form_edicao_percursos.cfm"><cfelseif URL.sessao EQ 'conteudo'><cfinclude template="form_edicao_conteudo.cfm"><cfelseif URL.sessao EQ 'dados' AND structKeyExists(URL,'fixture_basic')><cfinclude template="form_edicao.cfm"><cfelse><cfinclude template="form_edicao_fornecedores.cfm"></cfif>
 <cfelse>EVENT SAVED</cfif>`);
 mkdirSync(resolve(app,'WEB-INF/lib'),{recursive:true});cpSync(resolve(boxHome,'lib/lucee-5.3.10.120.jar'),resolve(app,'WEB-INF/lib/lucee.jar'));writeFileSync(resolve(app,'WEB-INF/web.xml'),readFileSync(resolve(boxHome,'cfml/system/config/web.xml'),'utf8'));
 cpSync(resolve(boxHome,'engine/cfml/cli/lucee-server/bundles'),resolve(scratch,'events-http-lucee/lucee-server/bundles'),{recursive:true});
 const listener=createServer();await new Promise(r=>listener.listen(0,'127.0.0.1',r));const httpPort=listener.address().port;await new Promise(r=>listener.close(r));
 mkdirSync(resolve(scratch,'events-http-tmp'),{recursive:true});
 const task=execute('/usr/bin/java',[`-Djava.io.tmpdir=${resolve(scratch,'events-http-tmp')}`,`-Dlucee.server.dir=${resolve(scratch,'events-http-lucee')}`,'-jar',resolve(boxHome,'lib/runwar-4.8.3.jar'),'-war',app,'-host','127.0.0.1','-p',String(httpPort),'-b','false','-open','false','-urlrewriteenable','false','-logDir',resolve(scratch,'events-http-logs')],undefined,{timeout:240000});
 let cookies='';const request=async(path,options={})=>{const response=await fetch(`http://127.0.0.1:${httpPort}`+path,{redirect:'manual',...options,headers:{Cookie:cookies,Host:'business.roadrunners.run',...options.headers}});const set=response.headers.getSetCookie();if(set.length)cookies=set.map(c=>c.split(';')[0]).join('; ');return {status:response.status,body:await response.text()};};
 const assert=(ok,label,result)=>{if(!ok){writeFileSync(resolve(root,'../task-10-http-response.html'),result?.body||'');const diagnostic=[...(result?.body||'').matchAll(/<td class="label">(?:Message|Detail)<\/td>\s*<td>([\s\S]*?)<\/td>/g)].map(m=>m[1]).join(' | ');throw Error(label+': '+(diagnostic||JSON.stringify(result).slice(0,800)));}};
 const fields=body=>Object.fromEntries([...body.matchAll(/<input[^>]*type="hidden"[^>]*name="([^"]+)"[^>]*value="([^"]*)"/g)].map(x=>[x[1].toLowerCase(),x[2].replaceAll('&amp;','&').replace(/&#x([0-9a-f]+);/gi,(_,n)=>String.fromCharCode(parseInt(n,16)))]));
 try{
  let ready=false;for(let i=0;i<120;i++){try{const r=await request('/bootstrap-manager.cfm');if(r.status===200&&r.body.includes('READY')){ready=true;break;}if(r.status>=500)throw Error(r.body.slice(0,1800));}catch(e){if(!String(e).includes('fetch failed'))throw e;}await new Promise(r=>setTimeout(r,250));}assert(ready,'HTTP ready',{});
  cookies='';const unit=await request('/suite.cfm',{method:'POST'});assert(unit.status===200&&unit.body.includes('PASS events CFML'),'actual CFML event suite',unit);
  cookies='';await request('/bootstrap-manager.cfm');
  const form=await request('/eventos/index.cfm?id_evento=701&sessao=fornecedores');assert(form.status===200&&form.body.toLowerCase().includes('business_access_token'),'actual supplier form signed',form);
  const first=form.body.split('</form>')[0];const posted=fields(first);assert(posted.business_access_token&&posted.fornecedor_count,'signed indexed noJS supplier form',posted);
  const send=values=>request('/eventos/index.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(values)});
  Object.assign(posted,{action:'editar_evento_fornecedores',id_evento:'701',fornecedor_count:'3',fornecedor_1:'1',fornecedor_tipo_1:'1',fornecedor_2:'',fornecedor_tipo_2:'',fornecedor_3:'2',fornecedor_tipo_3:'2'});
  const saved=await send(posted);assert(saved.status===200&&saved.body.includes('EVENT SAVED'),'legitimate multiple supplier rows',saved);
  assert((await sql('SELECT count(*) FROM tb_evento_corridas_fornecedores WHERE id_evento=701')).trim()==='2','actual two supplier rows',{});
  const duplicate=new URLSearchParams(posted);duplicate.append('id_evento','701');const dup=await send(duplicate);assert(dup.status===403,'duplicate scalar denied',dup);
  for(const action of ['excluir_evento','excluir_resultados','editar_evento_configuracoes','editar_evento_or','editar_evento_agregadores','confirmar_inscricao_disponibilidade'])assert((await send({...posted,action})).status===403,'global denied '+action,{});
  const get=await request('/eventos/index.cfm?id_evento=701&action=editar_evento_descricao&descricao=unsafe');assert(get.status===403,'GET action denied',get);
  cookies='';await request('/bootstrap-viewer.cfm');const viewerForm=await request('/eventos/index.cfm?id_evento=701');const viewerPost={...fields(viewerForm.body.split('</form>')[0]),action:'editar_evento_descricao',id_evento:'701',descricao:'unsafe',resumo:'',url_imagem:''};assert((await send(viewerPost)).status===403,'viewer HTTP 403',{});
  cookies='';await request('/bootstrap-manager.cfm');
  for(const tab of ['percursos','conteudo']){
   const rendered=await request('/eventos/index.cfm?id_evento=701&sessao='+tab);
   assert(rendered.status===200,'actual '+tab+' form renders',rendered);
   for(const fragment of rendered.body.split('</form>').filter(x=>x.includes('<form'))){
    const opening=fragment.match(/<form[^>]*>/)?.[0];assert(opening&&!opening.includes('<fieldset')&&!opening.includes('<input'),'form action is intact',rendered);
    assert(fields(fragment).business_access_token,'each '+tab+' operation signed',rendered);
   }
  }
  // Real basic form, including its state/city workflow and signed POST.
  const basicPage=await request('/eventos/index.cfm?id_evento=701&sessao=dados&fixture_basic=1');
  assert(basicPage.status===200,'actual basic form renders',basicPage);
  const basicFragment=basicPage.body.split('</form>').find(x=>x.includes('value="editar_evento_basico"'));
  assert(basicFragment,'actual basic POST exists',basicPage);
  const inputValues=fragment=>Object.fromEntries([...fragment.matchAll(/<input[^>]*name="([^"]+)"[^>]*value="([^"]*)"/g)].map(m=>[m[1].toLowerCase(),m[2].replaceAll('&amp;','&').replace(/&#x([0-9a-f]+);/gi,(_,n)=>String.fromCharCode(parseInt(n,16)))]));
  const basicPost={...inputValues(basicFragment),...fields(basicFragment),tipo_corrida:'rua',estado:'RJ',cidade:'123'};
  const beforeLocation=await sql('SELECT estado || chr(58) || cod_cidade::text || chr(58) || cidade FROM tb_evento_corridas WHERE id_evento=701');
  const mismatched=await send(basicPost);assert(mismatched.status===400,'basic handler refuses mismatched city/state',mismatched);
  assert((await sql('SELECT estado || chr(58) || cod_cidade::text || chr(58) || cidade FROM tb_evento_corridas WHERE id_evento=701'))===beforeLocation,'mismatched city/state zero writes',{});
  const lookup=basicPage.body.split('</form>').find(x=>x.includes('id="eventCityLookup"'));
  assert(lookup,'noJS state refresh form exists',basicPage);
  const refreshValues={...inputValues(lookup),cidade_uf:'RJ',fixture_basic:'1'};
  const refreshed=await request('/eventos/?'+new URLSearchParams(refreshValues));
  assert(refreshed.status===200,'noJS state refresh succeeds',refreshed);
  const refreshedBasic=refreshed.body.split('</form>').find(x=>x.includes('value="editar_evento_basico"'));
  const citySelect=refreshedBasic?.match(/<select[^>]*id="selectCidade"[\s\S]*?<\/select>/)?.[0]||'';
  assert(citySelect.includes('value="124"')&&!citySelect.includes('value="123"')&&!/value="124"[^>]*selected/.test(citySelect),'new state cities only, stale selection cleared',refreshed);
  assert(!refreshedBasic.includes('onchange="getCidades()"'),'delegated basic form avoids internal city API',refreshed);
  const matchingPost={...inputValues(refreshedBasic),...fields(refreshedBasic),tipo_corrida:'rua',cidade:'124'};
  assert(matchingPost.estado==='RJ','refreshed basic state is explicit',matchingPost);
  const matching=await send(matchingPost);assert(matching.status===200,'matching city/state saves',matching);
  assert((await sql('SELECT estado || chr(58) || cod_cidade::text || chr(58) || cidade FROM tb_evento_corridas WHERE id_evento=701')).trim()==='RJ:124:Outra cidade','actual matching location persisted',{});
  assert((await request('/api/Evento.cfc?method=getCidades&uf=RJ')).status===403,'internal API remains denied',{});
  console.log('PASS events real basic form noJS SP-to-RJ refresh, cleared city, matching save; mismatched city400 zero writes; internal API403');
  const freshForm=await request('/eventos/index.cfm?id_evento=701');
  const signed=fields(freshForm.body.split('</form>')[0]);
  const foreign=await send({...signed,action:'salvar_evento_percurso',id_evento:'701',id_evento_percurso:'712',percurso_evento:'42',unidade_de_medida:'km',data_percurso:'2026-12-01',hora_largada:'',tipo_corrida:'rua'});
  assert(foreign.status===404,'actual foreign child handler404',foreign);
  assert((await sql('SELECT percurso_evento FROM tb_evento_corridas_percursos WHERE id_evento_percurso=712')).trim()==='10','foreign HTTP zero writes',{});
  const stale=await send({...signed,action:'editar_evento_descricao',id_evento:'701',descricao:'stale write',resumo:'',url_imagem:'',fixture_stale:'1'});
  assert(stale.status===409,'post-boundary stale handler409',stale);
  assert((await sql('SELECT descricao FROM tb_evento_corridas WHERE id_evento=701')).trim()==='Own description','stale HTTP zero writes',{});
  cookies='';await request('/bootstrap-owner.cfm');
  await sql("INSERT INTO tb_evento_corridas(id_evento,nome_evento,tag,cidade,estado,data_final) VALUES(704,'Public HTTP','public-http','Teste','SP','2026-12-01'); INSERT INTO tb_conta_evento_solicitacoes(id_conta,id_evento,id_usuario_solicitante,mensagem,status) VALUES(103,704,902,'FOREIGN PRIVATE REQUEST','NEGADA')");
  const search=await request('/eventos/index.cfm?evento_referencia=public-http');
  assert(search.status===200&&!search.body.includes('FOREIGN PRIVATE REQUEST')&&!search.body.includes('NEGADA')&&!search.body.includes('Manager Two'),'search shows public event and selected-client relations only',search);
  const requestFragment=search.body.split('</form>').find(x=>x.includes('name="evento_solicitacao_action"'));
  assert(requestFragment,'actual request POST form exists',search);const link=fields(requestFragment);
  const cross=await send({...link,id_conta_solicitacao:'103'});assert(cross.status===403,'request cannot select foreign account',cross);
  const requested=await send(link);assert(requested.status===302,'actual request submitted',requested);
  assert((await sql("SELECT status::text || ':' || id_usuario_solicitante::text FROM tb_conta_evento_solicitacoes WHERE id_conta=102 AND id_evento=704")).trim()==='PENDENTE:902','pending request actual actor',{});
  assert((await sql("SELECT status FROM tb_conta_eventos WHERE id_conta=102 AND id_evento=704")).trim()==='PENDENTE','request never self approves',{});
  assert((await send({...link,evento_solicitacao_action:'aprovar',id_solicitacao:'1'})).status===403,'approval denied',{});
  console.log('PASS events actual request form, active client only, PENDENTE actual actor; course/content forms; post-boundary foreign404/stale409 zero writes');
  console.log('PASS events HTTP signed noJS supplier collection, duplicate scalar, viewer, GET and global denials');
  return unit.body;
 }finally{task.child.kill('SIGTERM');await task;}
}
