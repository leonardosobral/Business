<cfinclude template="../includes/start.cfm"><cfinclude template="../includes/require_identity.cfm">
<cfscript>
teamTitle='Meu Team · Road Runners';
if(CGI.request_method=='POST'){
 try {teamPost();if(teamBoundary.text(FORM,'operation')!='leave')throw(type='Teams.Validation',message='Operação inválida.');teamSvc.leave(teamUser.id);cfheader(statuscode=303);cfheader(name='Location',value='/teams/meu-team/?left=1');abort;}
 catch(Teams.Validation failed){teamError=failed.message;}catch(Teams.Forbidden failed){cfheader(statuscode=403);teamError=failed.message;}catch(any failed){teamError='Não foi possível encerrar o vínculo. Tente novamente.';}
}
if(structKeyExists(URL,'joined'))teamSuccess='Vínculo confirmado. Você agora representa seu Team no RR.';
if(structKeyExists(URL,'left'))teamSuccess='Você saiu do Team. O prazo anterior para uma nova adesão continua valendo.';
myState={teamId=0,name='',slug='',blocked=false,nextChangeAt=''};myNotices=queryNew('message,created_at');
if(teamReady){myState=teamSvc.state(teamUser.id);myNotices=teamSvc.notices(teamUser.id);}
</cfscript>
<cfinclude template="../includes/header.cfm"><section class="teams-hero"><span class="teams-eyebrow">Seu perfil, sua escolha</span><h1>Meu Team</h1><p>Escolha a comunidade que você quer representar no Road Runners.</p></section>
<section class="teams-panel"><cfif myState.teamId GT 0><h2><cfoutput>#encodeForHTML(myState.name)#</cfoutput></h2><p>Este é o Team vinculado ao seu perfil.</p><div class="teams-inline"><a class="teams-button secondary" href="/teams/?team=<cfoutput>#urlEncodedFormat(myState.slug)#</cfoutput>">Conhecer meu Team</a><a href="/teams/">Encontrar outro Team</a></div><form method="post" data-confirm="Deseja sair do Team? O prazo anterior para uma nova adesão será mantido."><input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><input type="hidden" name="operation" value="leave"><p class="teams-small teams-muted">Você pode sair a qualquer momento. O acesso do Team ao acompanhamento pelo painel termina com sua saída.</p><button class="danger">Sair do Team</button></form><cfelse><h2>Você está sem Team</h2><p>Encontre seu grupo ou continue usando o RR de forma independente.</p><a class="teams-button" href="/teams/">Encontrar meu Team</a></cfif>
<cfif myState.blocked><p class="teams-alert">Próxima adesão ou troca: <strong><cfoutput>#encodeForHTML(myState.nextChangeAt)#</cfoutput></strong> (Brasília).</p></cfif></section>
<section class="teams-panel"><h2>Não encontrou seu Team?</h2><p>Convide o responsável para cadastrar sua assessoria, clube ou grupo de corrida.</p><a class="teams-button secondary" href="/teams/convidar/">Convidar responsável</a></section>
<cfif myNotices.recordCount><section class="teams-panel"><h2>Atualizações</h2><ul class="teams-notices"><cfoutput query="myNotices"><li>#encodeForHTML(message)#</li></cfoutput></ul></section></cfif><cfinclude template="../includes/footer.cfm">
