<cfscript>
teamExistingMember=0;teamExistingRole='VIEWER';
if(CGI.request_method=='POST'&&teamPostOperation=='add_existing_admin'){
 if(structKeyExists(FORM,'member')&&isSimpleValue(FORM.member)&&reFind('^[0-9]{1,14}$',FORM.member))teamExistingMember=val(FORM.member);
 if(structKeyExists(FORM,'role')&&isSimpleValue(FORM.role)&&listFind('OWNER,ADMIN,VIEWER',FORM.role))teamExistingRole=FORM.role;
}
</cfscript>
<p>Busque uma pessoa já cadastrada no RR e escolha o acesso que ela terá na gestão deste Team.</p>
<form class="teams-form" method="get" action="/administracao/teams/">
<cfoutput><input type="hidden" name="team" value="#teamId#"><input type="hidden" name="tab" value="equipe"><input type="hidden" name="q" value="#encodeForHTMLAttribute(teamSearch)#"><input type="hidden" name="status" value="#encodeForHTMLAttribute(teamStatus)#"><input type="hidden" name="type" value="#encodeForHTMLAttribute(teamType)#"><input type="hidden" name="uf" value="#encodeForHTMLAttribute(teamUf)#"><input type="hidden" name="page" value="#teamPage#"><input type="hidden" name="aq" value="#encodeForHTMLAttribute(teamAthleteSearch)#"><input type="hidden" name="apage" value="#teamAthletePage#"></cfoutput>
<label class="teams-field full">Buscar usuário por nome, email ou ID<input name="user_busca" type="search" maxlength="100" value="<cfoutput>#encodeForHTMLAttribute(teamExistingSearch)#</cfoutput>" placeholder="Nome, email ou ID"></label><div class="full"><button type="submit" class="secondary">Buscar usuário</button></div></form>
<cfif teamCandidateRows.recordCount>
<p class="teams-small teams-muted mt-3">Até 25 contas ativas sem acesso administrativo a este Team. Confira o nome, o email e o ID antes de adicionar.</p>
<form class="teams-form" method="post" action="<cfoutput>#encodeForHTMLAttribute(teamAdminUrl(teamId,'equipe'))#</cfoutput>" data-confirm="Liberar imediatamente o acesso desta pessoa à gestão do Team com o papel selecionado?">
<input type="hidden" name="operation" value="add_existing_admin"><input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><input type="hidden" name="team" value="<cfoutput>#teamId#</cfoutput>">
<label class="teams-field full">Usuário existente<select name="member" required><option value="">Selecione uma pessoa</option><cfoutput query="teamCandidateRows"><option value="#id#" <cfif teamExistingMember EQ id>selected</cfif>>ID #id# · #encodeForHTML(name)# · #encodeForHTML(email)#</option></cfoutput></select></label>
<label class="teams-field">Papel no Team<select name="role"><option value="VIEWER" <cfif teamExistingRole EQ 'VIEWER'>selected</cfif>>Consulta</option><option value="ADMIN" <cfif teamExistingRole EQ 'ADMIN'>selected</cfif>>Administrador</option><option value="OWNER" <cfif teamExistingRole EQ 'OWNER'>selected</cfif>>Titular</option></select></label>
<p class="teams-small teams-muted">Titular: gestão completa da equipe. Administrador: operação do Team. Consulta: somente leitura.</p>
<div class="full"><button type="submit">Adicionar à gestão</button></div><p class="teams-small teams-muted full">A inclusão libera o acesso imediatamente com o papel escolhido. O vínculo de atleta é uma escolha separada.</p></form>
<cfelseif len(teamExistingSearch)><p class="teams-muted mt-3"><cfif len(teamExistingSearch) LT 2 AND NOT reFind('^[1-9][0-9]{0,14}$',teamExistingSearch)>Digite pelo menos dois caracteres do nome/email ou um ID válido.<cfelse>Nenhum usuário ativo sem vínculo encontrado. Confira a busca ou os acessos já listados abaixo.</cfif></p></cfif>

