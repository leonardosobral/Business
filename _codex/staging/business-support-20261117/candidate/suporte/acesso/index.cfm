<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false">
<cfheader name="Cache-Control" value="private, no-store"><cfheader name="Referrer-Policy" value="same-origin">
<cfscript>
supportService=new services.BusinessSupportSession();supportError='';supportTarget={};supportActive=structKeyExists(SESSION,'businessSupportSession');supportToken='';
supportPrincipal=structKeyExists(REQUEST,'businessAuthenticatedActor')?REQUEST.businessAuthenticatedActor:{};
supportMeta={method=CGI.request_method,path=CGI.script_name,ip=CGI.remote_addr,agent=CGI.http_user_agent};
try {
 if(!listFind('GET,POST',CGI.request_method))throw(type='BusinessSupport.Forbidden',message='Método não permitido.');
 if(CGI.request_method=='POST') {
  if(!structKeyExists(FORM,'action')||!isSimpleValue(FORM.action)||!structKeyExists(FORM,'csrf')||!isSimpleValue(FORM.csrf))throw(type='BusinessSupport.Forbidden',message='Solicitação inválida.');
  lock scope='session' type='exclusive' timeout=10 {
   if(FORM.action=='start') {
    if(!structKeyExists(FORM,'user_id')||!structKeyExists(FORM,'confirmed')||!isSimpleValue(FORM.confirmed))throw(type='BusinessSupport.Forbidden',message='Confirme o usuário escolhido.');
    supportService.begin(SESSION,supportPrincipal,FORM.user_id,FORM.csrf,CGI.request_method,FORM.confirmed,supportMeta);
   } else if(FORM.action=='stop'){supportMeta.reason='retorno_administrador';supportService.finish(SESSION,supportPrincipal,FORM.csrf,CGI.request_method,supportMeta);}
   else throw(type='BusinessSupport.Forbidden',message='Solicitação inválida.');
   sessionRotate();
  }
  location(url=FORM.action=='stop'?'/administracao/usuarios/':'/',statuscode=303,addtoken=false);
 }
 if(!supportActive) {
  if(!structKeyExists(URL,'user_id')){location(url='/administracao/usuarios/',statuscode=303,addtoken=false);}
  supportTarget=supportService.target(supportPrincipal,SESSION,URL.user_id);
  lock scope='session' type='exclusive' timeout=10 {supportToken=supportService.startToken(SESSION,supportTarget.id);}
 }
}catch(BusinessSupport.Forbidden e){supportError=e.message;cfheader(statuscode=403);}
catch(any e){supportError='Não foi possível abrir a sessão de suporte. Tente novamente.';cfheader(statuscode=503);writeLog(file='business_auth',type='error',text='Business support transition rejected: ' & e.type);}
</cfscript>
<!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Logar como no Business</title>
<style>body{margin:0;background:#242424;color:#f7f7f7;font:16px/1.6 system-ui,sans-serif}main{max-width:680px;margin:60px auto;padding:28px;background:#333;border:1px solid #555;border-radius:12px}h1{font-size:28px}a{color:#ffc340}button{display:block;margin-top:24px;background:#fab120;color:#202020;border:0;border-radius:5px;padding:12px 20px;font:inherit;font-weight:bold;cursor:pointer}label{display:flex;gap:10px;align-items:flex-start}input{margin-top:7px}@media(max-width:720px){main{margin:16px;padding:20px}}</style></head><body><main>
<h1>Logar como no Business</h1>
<cfif len(supportError)><p role="alert"><cfoutput>#encodeForHTML(supportError)#</cfoutput></p><p><a href="/selecionar-conta/">Escolher meu acesso</a></p>
<cfelseif supportActive><p>A sessão de suporte já está ativa. Use o botão abaixo para voltar ao administrador.</p>
<cfelse><cfoutput>
<p>Você vai acessar como <strong>#encodeForHTML(supportTarget.name)#</strong><br>#encodeForHTML(supportTarget.email)#</p>
<p>Durante 30 minutos, o Business usará somente as permissões desse usuário. Suas ações serão registradas como suporte realizado pelo seu administrador.</p>
<p>A troca vale para todas as abas do Business neste perfil do navegador. Alterações afetam os dados reais do usuário.</p>
<form method="post" action="/suporte/acesso/"><input type="hidden" name="action" value="start"><input type="hidden" name="csrf" value="#encodeForHTMLAttribute(supportToken)#"><input type="hidden" name="user_id" value="#supportTarget.id#">
<label><input type="checkbox" name="confirmed" value="1" required>Confirmo o acesso de suporte a este usuário.</label><button type="submit">Entrar como #encodeForHTML(supportTarget.name)#</button></form>
<p><a href="/administracao/usuarios/?user_id=#supportTarget.id#">Cancelar e voltar</a></p>
</cfoutput></cfif></main><cfinclude template="../../includes/estrutura/business_support_banner.cfm"></body></html>
