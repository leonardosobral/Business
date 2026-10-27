<cfinclude template="../includes/start.cfm">
<cfset teamTitle='Entrar no Road Runners Teams'>
<cfset teamReturn=teamIdentity.returnPath(teamBoundary.text(URL,'redirect','/teams/meu-team/'))>
<cfif listFirst(CGI.http_host,':') NEQ 'roadrunners.run'><cflocation url="https://roadrunners.run/teams/entrar/?redirect=#urlEncodedFormat(teamReturn)#" addtoken="false"></cfif>
<cfif NOT structIsEmpty(teamUser)><cflocation url="#teamReturn#" addtoken="false"></cfif>
<cfinclude template="../../sso/comparador/_portal_nonce.cfm">
<cfset teamLoginCsrf=teamBoundary.token(SESSION,0)>
<cfif CGI.request_method EQ 'POST'>
<cftry>
<cfif NOT teamBoundary.valid(SESSION,FORM,0)><cfthrow type="Teams.Forbidden" message="Sua sessão expirou. Recarregue a página."></cfif>
<cfscript>
teamCredential=teamBoundary.text(FORM,'credential');pending={};
lock scope='session' type='exclusive' timeout=5 {
 if(structKeyExists(SESSION,'rrPortalNonceV1')&&SESSION.rrPortalNonceV1.expires>now()&&structKeyExists(COOKIE,'__Host-rr-portal-login')&&teamProtocol.constantEquals(SESSION.rrPortalNonceV1.binding,teamProtocol.digest(COOKIE['__Host-rr-portal-login'] & ''))){pending=duplicate(SESSION.rrPortalNonceV1);structDelete(SESSION,'rrPortalNonceV1');}
}
if(structIsEmpty(pending))throw(type='Teams.Forbidden',message='Sua sessão de login expirou. Recarregue a página.');
lock name='RoadRunners.ComparadorGoogleVerifier.v1' type='exclusive' timeout=5 {
 if(!structKeyExists(APPLICATION,'comparadorGoogleVerifierV1'))APPLICATION.comparadorGoogleVerifierV1=createObject('component','services.ComparadorGoogleIdentityVerifier').init();
}
claims=APPLICATION.comparadorGoogleVerifierV1.verify(teamCredential,pending.nonce);
// The existing verifier returns normalized sub/email only after requiring email_verified=true.
claims.email_verified=true;
loggedId=teamIdentity.account(claims);loggedUser=teamSvc.actor(loggedId);
proofAccount=createObject('component','services.ComparadorIdentityAccounts').init('runner_dba').byId(loggedId);
if(structIsEmpty(proofAccount))throw(type='Teams.Forbidden',message='Esta conta não está disponível.');
proofBinding=teamProtocol.randomToken();proofAccount.sessionId=teamProtocol.randomToken();proofAccount.browserBinding=teamProtocol.digest(proofBinding);
sessionRotate();SESSION.rrComparadorVerifiedV1={identity=duplicate(proofAccount),binding=proofAccount.browserBinding,expires=dateAdd('h',8,now())};
lock name=teamProofLock type='exclusive' timeout=5 {teamProtocol.rememberBrowser(proofBinding,proofAccount,SESSION.rrComparadorVerifiedV1.expires);}
getPageContext().getResponse().addHeader('Set-Cookie','__Host-rr-comparador-identity=' & proofBinding & '; Path=/; Secure; HttpOnly; SameSite=Lax');
structDelete(SESSION,'rrTeamsCsrf',false);structDelete(SESSION,'rrTeamsCsrfActor',false);if(structKeyExists(SESSION,'UsuarioCache'))structClear(SESSION.UsuarioCache);
</cfscript>
<!--- Legacy presentation cookies are written only after cryptographic verification; Teams never authenticates from them. --->
<cfcookie domain="roadrunners.run" name="id" value="#loggedId#" path="/" secure="yes" samesite="Lax" expires="#dateAdd('d',30,now())#">
<cfcookie domain="roadrunners.run" name="name" value="#loggedUser.name#" path="/" secure="yes" samesite="Lax" expires="#dateAdd('d',30,now())#">
<cfcookie domain="roadrunners.run" name="email" value="#loggedUser.email#" path="/" secure="yes" samesite="Lax" expires="#dateAdd('d',30,now())#">
<cfcookie domain="roadrunners.run" name="tag" value="#proofAccount.tag#" path="/" secure="yes" samesite="Lax" expires="#dateAdd('d',30,now())#">
<cflocation url="#teamReturn#" statuscode="303" addtoken="false">
<cfcatch type="Teams.Forbidden"><cfheader statuscode="403"><cfset teamError=cfcatch.message></cfcatch>
<cfcatch type="any"><cflog file="teams" type="warning" text="verified_login_rejected #cfcatch.type#"><cfset teamError="Não foi possível confirmar sua identidade. Recarregue a página e entre novamente."></cfcatch>
</cftry>
</cfif>
<cfinclude template="../includes/header.cfm"><section class="teams-hero"><span class="teams-eyebrow">Road Runners Teams</span><h1>Seu time começa com você.</h1><p>Confirme sua conta para escolher o Team que você quer representar.</p></section><section class="teams-panel"><h2>Entrar ou criar conta</h2><p>Use o mesmo email da sua conta RR. Se você ainda não tem uma conta, ela será criada para você.</p>
<div id="g_id_onload" data-client_id="921450846888-qa9a1alk06v6i0ao4jbiihdfrn8j7528.apps.googleusercontent.com" data-callback="teamsVerifiedCredential" data-auto_select="false" data-auto_prompt="false" data-nonce="<cfoutput>#encodeForHTMLAttribute(REQUEST.portalGoogleNonce)#</cfoutput>"></div><div class="g_id_signin" data-type="standard" data-size="large"></div>
<form id="team-verified-login" method="post"><input type="hidden" name="csrf" value="<cfoutput>#teamLoginCsrf#</cfoutput>"><input type="hidden" name="credential" value=""></form><script>function teamsVerifiedCredential(response){if(!response||!response.credential)return;var form=document.getElementById('team-verified-login');form.elements.credential.value=response.credential;form.submit();}</script><script src="https://accounts.google.com/gsi/client" async defer></script></section><cfinclude template="../includes/footer.cfm">
