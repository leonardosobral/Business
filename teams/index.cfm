<cfinclude template="includes/start.cfm">
<cfscript>
teamId=teamBoundary.number(URL,'team');teamTab=teamBoundary.text(URL,'tab','visao');teamSearch=left(teamBoundary.text(URL,'q'),100);teamPage=max(1,teamBoundary.number(URL,'page',1));
teamExistingSearch=left(teamBoundary.text(URL,'user_busca'),100);teamCandidateRows=queryNew('id,name,email');teamPostOperation='';
teamTabs={visao='Visão geral',atletas='Atletas',resultados='Resultados',divulgacao='Divulgação',equipe='Equipe administrativa',cadastro='Cadastro'};
teamTabOrder=['visao','atletas','resultados','divulgacao','equipe','cadastro'];if(!structKeyExists(teamTabs,teamTab))teamTab='visao';
function teamOwnerUrl(required numeric selectedTeam,string selectedTab='equipe'){
 return '/teams/?team=' & selectedTeam & '&tab=' & urlEncodedFormat(selectedTab) & '&q=' & urlEncodedFormat(teamSearch) & '&page=' & teamPage & '&user_busca=' & urlEncodedFormat(teamExistingSearch);
}
if(!structIsEmpty(teamUser)&&teamUser.is_admin){
 if(CGI.request_method!='GET'){cfheader(statuscode=403);writeOutput('As alterações globais devem ser feitas na Gestão de Teams.');abort;}
 globalReturn='/administracao/teams/?q=' & urlEncodedFormat(teamSearch) & '&page=' & teamPage;
 if(teamId>0)globalReturn&='&team=' & teamId & '&tab=' & (listFind('cadastro,equipe,atletas',teamTab)?teamTab:'cadastro');
 if(teamId>0&&teamTab=='atletas')globalReturn='/administracao/teams/?team=' & teamId & '&tab=atletas&aq=' & urlEncodedFormat(teamSearch) & '&apage=' & teamPage;
 if(len(teamExistingSearch)&&teamTab=='equipe')globalReturn&='&user_busca=' & urlEncodedFormat(teamExistingSearch);
 location(url=globalReturn,statuscode=303,addtoken=false);
}
if(structKeyExists(URL,'saved'))teamSuccess='Cadastro recebido. Acompanhe aqui a análise do RR.';
if(structKeyExists(URL,'accepted'))teamSuccess='Convite aceito. Seu acesso administrativo está disponível.';
if(structKeyExists(URL,'updated'))teamSuccess='Alteração registrada.';
if(structKeyExists(URL,'invited'))teamSuccess='Convite criado e encaminhado para a fila de email.';
teamWorkspace={};teamList=queryNew('id_team,name,status,city,uf,role,total_count');
try {
 if(CGI.request_method=='POST'){
  teamPostOperation=teamBoundary.text(FORM,'operation');teamPost();submittedTeam=teamBoundary.number(FORM,'team');
  if(teamId>0&&submittedTeam!=teamId)throw(type='Teams.Validation',message='Selecione novamente o Team antes de registrar a alteração.');
  teamId=submittedTeam;
 }
 if(teamReady&&!structIsEmpty(teamUser)){
  if(teamId>0){teamWorkspace=teamSvc.workspace(teamUser.id,teamId,teamSearch,teamPage);teamTitle=teamWorkspace.team.name;}
  else teamList=teamSvc.ownedTeams(teamUser.id,teamSearch,teamPage);
 }
 if(!structIsEmpty(teamWorkspace)&&teamTab=='equipe'&&len(teamWorkspace.adminPolicy.roles))teamCandidateRows=teamSvc.adminCandidates(teamUser.id,teamId,teamExistingSearch);
 if(CGI.request_method=='POST'){
  switch(teamPostOperation){
   case 'review':throw(type='Teams.Forbidden',message='A revisão é exclusiva da Gestão de Teams.');
   case 'save':teamSvc.updateTeam(teamUser.id,teamId,FORM,teamBoundary.number(FORM,'version'));break;
   case 'remove_athlete':teamSvc.removeAthlete(teamUser.id,teamId,teamBoundary.number(FORM,'athlete'));break;
   case 'unblock_athlete':teamSvc.unblockAthlete(teamUser.id,teamId,teamBoundary.number(FORM,'athlete'));break;
   case 'add_existing_admin':teamTab='equipe';teamSvc.addExistingAdmin(teamUser.id,teamId,teamBoundary.number(FORM,'member'),teamBoundary.text(FORM,'role'));break;
   case 'change_admin_role':teamTab='equipe';teamSvc.changeAdminRole(teamUser.id,teamId,teamBoundary.number(FORM,'member'),teamBoundary.text(FORM,'role'),teamBoundary.text(FORM,'expected_role'));break;
   case 'invite_admin':teamTab='equipe';teamSvc.inviteAdmin(teamUser.id,teamId,teamBoundary.text(FORM,'email'),teamBoundary.text(FORM,'role'));break;
   case 'remove_admin':teamTab='equipe';teamSvc.removeAdmin(teamUser.id,teamId,teamBoundary.number(FORM,'member'));break;
   case 'revoke_invite':teamTab='equipe';teamSvc.revokeInvite(teamUser.id,teamId,teamBoundary.number(FORM,'invite'));break;
   default:throw(type='Teams.Validation',message='Operação inválida.');
  }
  location(url=teamOwnerUrl(teamId,teamTab) & (teamPostOperation=='invite_admin'?'&invited=1':'&updated=1'),statuscode=303,addtoken=false);
 }
}catch(Teams.Validation failed){teamError=failed.message;cfheader(statuscode=400);}
catch(Teams.Forbidden failed){teamError=failed.message;cfheader(statuscode=403);}
catch(any failed){writeLog(file='teams',type='error',text='workspace_failed type=' & failed.type);teamError='Não foi possível concluir a operação. Recarregue a página e tente novamente.';cfheader(statuscode=500);}
// Errors before loading the workspace can still show this actor's authorized Team safely.
if(teamReady&&!structIsEmpty(teamUser)&&teamId>0&&structIsEmpty(teamWorkspace)){
 try{teamWorkspace=teamSvc.workspace(teamUser.id,teamId,teamSearch,teamPage);teamTitle=teamWorkspace.team.name;
 if(teamTab=='equipe'&&len(teamWorkspace.adminPolicy.roles))teamCandidateRows=teamSvc.adminCandidates(teamUser.id,teamId,teamExistingSearch);
 }catch(any unavailable){teamId=0;}
}
teamMembersAction=teamOwnerUrl(teamId,'equipe');teamMemberBase='/teams/';teamMemberFilters={team=teamId,tab='equipe',q=teamSearch,page=teamPage};
</cfscript>
<cfinclude template="includes/header.cfm">
<cfif structIsEmpty(teamUser)><section class="teams-hero"><span class="teams-eyebrow">RunnerHub Business</span><h1>Um espaço para o seu time.</h1><p>Gerencie seu Team, compartilhe o link de adesão e acompanhe os atletas que escolheram representar sua comunidade.</p></section><cfinclude template="includes/login.cfm">
<cfelseif teamId EQ 0>
<section class="teams-hero"><span class="teams-eyebrow">Seus acessos</span><h1>Road Runners Teams</h1><p>Uma comunidade, muitos corredores. Selecione um Team para continuar.</p><a class="teams-button" href="/teams/cadastro/">Cadastrar um Team</a></section>
<form class="teams-toolbar" method="get"><label>Buscar Team<input name="q" maxlength="100" value="<cfoutput>#encodeForHTMLAttribute(teamSearch)#</cfoutput>" placeholder="Nome ou cidade"></label><button>Buscar</button></form>
<cfif NOT teamList.recordCount><section class="teams-panel teams-empty"><h2>Nenhum Team encontrado</h2><p>Cadastre seu Team ou aceite o convite enviado pelo responsável para começar.</p></section><cfelse><div class="teams-grid"><cfoutput query="teamList"><article class="teams-panel teams-card"><span class="teams-badge teams-status-#encodeForHTMLAttribute(status)#">#encodeForHTML(teamLabel(status))#</span><h2>#encodeForHTML(name)#</h2><p class="teams-muted">#encodeForHTML(city)# / #encodeForHTML(uf)#</p><a class="teams-button secondary" href="/teams/?team=#id_team#">Abrir painel</a></article></cfoutput></div><nav class="teams-pagination" aria-label="Paginação"><cfif teamPage GT 1><a href="?page=<cfoutput>#teamPage-1#&q=#urlEncodedFormat(teamSearch)#</cfoutput>">Anterior</a></cfif><cfif teamList.recordCount EQ 24><a href="?page=<cfoutput>#teamPage+1#&q=#urlEncodedFormat(teamSearch)#</cfoutput>">Próxima</a></cfif></nav></cfif>
<cfelse>
<cfset tw=teamWorkspace><cfset tt=tw.team><cfset teamCanWrite=listFind('OWNER,ADMIN,GLOBAL',tw.role) GT 0>
<section class="teams-hero"><a href="/teams/">← Todos os Teams</a><h1><cfoutput>#encodeForHTML(tt.name)#</cfoutput></h1><span class="teams-badge teams-status-<cfoutput>#encodeForHTMLAttribute(tt.status)#</cfoutput>"><cfoutput>#encodeForHTML(teamLabel(tt.status))#</cfoutput></span> <span class="teams-muted teams-small"><cfoutput>#encodeForHTML(tt.city)# / #encodeForHTML(tt.uf)# · #encodeForHTML(tw.role)#</cfoutput></span></section>
<cfif len(tt.review_note)><div class="teams-alert"><strong>Revisão RR:</strong> <cfoutput>#encodeForHTML(tt.review_note)#</cfoutput></div></cfif>
<cfif tt.status NEQ 'ACTIVE'><div class="teams-alert">As adesões e o acompanhamento de resultados ficam disponíveis quando o Team estiver ativo.</div></cfif>
<nav class="teams-tabs" aria-label="Seções do Team"><cfoutput><cfloop array="#teamTabOrder#" index="tabKey"><a href="?team=#teamId#&tab=#tabKey#" <cfif teamTab EQ tabKey>aria-current="page"</cfif>>#encodeForHTML(teamTabs[tabKey])#</a></cfloop></cfoutput></nav>
<cfif teamTab EQ 'visao'>
<div class="teams-stats"><div class="teams-stat"><strong><cfoutput>#tw.stats.athletes#</cfoutput></strong><span>Atletas vinculados</span></div><div class="teams-stat"><strong><cfoutput>#tw.stats.joins#</cfoutput></strong><span>Adesões em 30 dias</span></div><div class="teams-stat"><strong><cfoutput>#tw.stats.exits#</cfoutput></strong><span>Saídas em 30 dias</span></div></div>
<div class="teams-stats"><div class="teams-stat"><strong><cfoutput>#tw.stats.new_users#</cfoutput></strong><span>Novos usuários trazidos por Teams</span></div><div class="teams-stat"><strong><cfoutput>#tw.stats.existing_users#</cfoutput></strong><span>Usuários existentes na primeira adesão</span></div><div class="teams-stat"><strong><cfoutput>#tw.stats.retained_users# / #tw.stats.retention_eligible#</cfoutput></strong><span>Retorno observado após 30 dias</span></div></div><p class="teams-small teams-muted">A origem de aquisição considera a primeira adesão. O retorno mede visitas autenticadas à área Teams, entre usuários com pelo menos 30 dias desde a primeira adesão; não representa toda a atividade no RR.</p>
<section class="teams-panel"><h2>Seu próximo passo</h2><cfif tt.status EQ 'ACTIVE'><p>Compartilhe o link com seus atletas. Cada pessoa confirma a adesão usando a própria conta no RR.</p><a class="teams-button" href="?team=<cfoutput>#teamId#</cfoutput>&tab=divulgacao">Divulgar meu Team</a><cfelse><p>Acompanhe a análise na aba Cadastro. Se o RR solicitar ajustes, atualize os dados e envie novamente.</p></cfif></section>
<section class="teams-panel"><h2>Atividade recente</h2><cfif NOT tw.audit.recordCount><p class="teams-muted">As atividades do Team aparecerão aqui.</p><cfelse><ul class="teams-notices"><cfoutput query="tw.audit"><li><span class="teams-small teams-muted">#dateTimeFormat(created_at,'dd/mm/yyyy HH:nn')#</span> · #encodeForHTML(event)#<cfif len(detail)><br>#encodeForHTML(detail)#</cfif></li></cfoutput></ul></cfif></section>
<cfelseif teamTab EQ 'atletas'>
<form class="teams-toolbar" method="get"><input type="hidden" name="team" value="<cfoutput>#teamId#</cfoutput>"><input type="hidden" name="tab" value="atletas"><label>Buscar atleta<input name="q" value="<cfoutput>#encodeForHTMLAttribute(teamSearch)#</cfoutput>" maxlength="100"></label><button>Filtrar</button></form>
<section class="teams-panel"><h2>Atletas do Team</h2><p class="teams-muted">A adesão é uma escolha do atleta. Remover encerra o vínculo e bloqueia o retorno até sua liberação.</p><cfif NOT tw.athletes.recordCount><p>Nenhum atleta encontrado. Divulgue seu link para receber adesões.</p><cfelse><div class="teams-table-wrap"><table class="teams-table"><thead><tr><th>Atleta</th><th>Adesão</th><cfif teamCanWrite><th>Ação</th></cfif></tr></thead><tbody><cfoutput query="tw.athletes"><tr><td><cfif len(tag)><a href="https://roadrunners.run/atleta/#encodeForURL(tag)#/" target="_blank" rel="noopener">#encodeForHTML(name)#</a><cfelse>#encodeForHTML(name)#</cfif></td><td>#encodeForHTML(joined_on)#</td><cfif teamCanWrite><td><form method="post" data-confirm="Encerrar o vínculo deste atleta com o Team?"><input type="hidden" name="csrf" value="#teamCsrf#"><input type="hidden" name="operation" value="remove_athlete"><input type="hidden" name="team" value="#teamId#"><input type="hidden" name="athlete" value="#user_id#"><button class="danger">Remover vínculo</button></form></td></cfif></tr></cfoutput></tbody></table></div></cfif></section>
<cfif teamCanWrite AND tw.exclusions.recordCount><section class="teams-panel"><h2>Retornos bloqueados</h2><cfoutput query="tw.exclusions"><form class="teams-inline" method="post"><input type="hidden" name="csrf" value="#teamCsrf#"><input type="hidden" name="operation" value="unblock_athlete"><input type="hidden" name="team" value="#teamId#"><input type="hidden" name="athlete" value="#user_id#"><span>#encodeForHTML(name)#</span><button class="secondary">Permitir nova adesão</button></form></cfoutput></section></cfif>
<cfelseif teamTab EQ 'resultados'>
<section class="teams-panel"><h2>Resultados dos atletas</h2><p class="teams-muted">Resultados oficiais disponíveis no RR dos atletas atualmente vinculados. A equipe informada originalmente em cada prova é preservada.</p><cfif NOT tw.results.recordCount><p>Nenhum resultado disponível para este recorte.</p><cfelse><div class="teams-table-wrap"><table class="teams-table"><thead><tr><th>Atleta</th><th>Prova</th><th>Data</th><th>Distância</th><th>Tempo</th></tr></thead><tbody><cfoutput query="tw.results"><tr><td>#encodeForHTML(name)#</td><td><a href="https://roadrunners.run/evento/#encodeForURL(tag)#/">#encodeForHTML(nome_evento)#</a></td><td>#dateFormat(data_final,'dd/mm/yyyy')#</td><td>#encodeForHTML(percurso)# km</td><td>#encodeForHTML(tempo_total)#</td></tr></cfoutput></tbody></table></div></cfif></section>
<cfelseif teamTab EQ 'divulgacao'>
<cfset teamPublicLink='https://roadrunners.run/teams/?team=' & urlEncodedFormat(tt.slug)>
<section class="teams-panel"><h2>Convide seus atletas</h2><p>Envie este link para alunos e membros. O atleta entra no RR e confirma o próprio vínculo.</p><cfif tt.status EQ 'ACTIVE'><div class="teams-copy"><input id="team-public-link" readonly aria-label="Link de adesão" value="<cfoutput>#encodeForHTMLAttribute(teamPublicLink)#</cfoutput>"><button type="button" data-copy-target="team-public-link">Copiar link</button></div><figure class="teams-qr"><div data-team-qr="<cfoutput>#encodeForHTMLAttribute(teamPublicLink)#</cfoutput>" role="img" aria-label="QR Code do link de adesão do Team"></div><figcaption><a data-qr-download download="road-runners-team.svg">Baixar QR Code</a></figcaption></figure><p class="teams-small teams-muted">Cada atleta representa um Team. O intervalo mínimo entre vínculos ou trocas é de 14 dias.</p><p><a class="teams-button secondary" href="https://wa.me/?text=<cfoutput>#urlEncodedFormat('Venha representar ' & tt.name & ' no Road Runners! Acesse e confirme seu vínculo: ' & teamPublicLink)#</cfoutput>" target="_blank" rel="noopener">Compartilhar no WhatsApp</a></p><cfelse><p>Seu link estará disponível após a aprovação do cadastro.</p></cfif></section>
<cfelseif teamTab EQ 'equipe'>
<cfinclude template="includes/admins.cfm">
<cfelseif teamTab EQ 'cadastro'>
<cfinclude template="includes/registration.cfm">
</cfif>
<cfif listFind('atletas,resultados',teamTab)><nav class="teams-pagination" aria-label="Paginação"><cfif teamPage GT 1><a href="?team=<cfoutput>#teamId#&tab=#teamTab#&q=#urlEncodedFormat(teamSearch)#&page=#teamPage-1#</cfoutput>">Anterior</a></cfif><cfif (teamTab EQ 'atletas' AND tw.athletes.recordCount EQ 25) OR (teamTab EQ 'resultados' AND tw.results.recordCount EQ 25)><a href="?team=<cfoutput>#teamId#&tab=#teamTab#&q=#urlEncodedFormat(teamSearch)#&page=#teamPage+1#</cfoutput>">Próxima</a></cfif></nav></cfif>
</cfif>
<cfinclude template="includes/footer.cfm">
