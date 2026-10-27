<link rel="stylesheet" href="/teams/assets/admins.css?v=1"><div class="teams-admin-workspace">
<cfscript>
teamAdminPolicy=tw.adminPolicy;
teamRoleLabels={OWNER='Titular',ADMIN='Administrador',VIEWER='Consulta'};teamInviteEmail='';teamInviteRole='VIEWER';
if(CGI.request_method=='POST'&&teamPostOperation=='invite_admin'){
 if(structKeyExists(FORM,'email')&&isSimpleValue(FORM.email))teamInviteEmail=left(FORM.email,255);
 if(structKeyExists(FORM,'role')&&isSimpleValue(FORM.role)&&listFind('ADMIN,VIEWER',FORM.role))teamInviteRole=FORM.role;
}
</cfscript>
<section class="teams-panel"><h2>Equipe administrativa</h2><p class="teams-muted"><cfif tw.role EQ 'GLOBAL'>Altere o papel de cada pessoa sem remover seu acesso. Mantenha pelo menos um titular no Team.<cfelseif tw.role EQ 'OWNER'>Gerencie os acessos de Administrador e Consulta. Alterações de titularidade são feitas pela gestão global.<cfelseif tw.role EQ 'ADMIN'>Seu papel permite adicionar acessos de Consulta.<cfelse>Seu acesso permite consultar a equipe administrativa.</cfif></p>
<cfif NOT tw.admins.recordCount><p class="teams-muted">Nenhum usuário vinculado à gestão deste Team.</p><cfelse>
<cfoutput query="tw.admins">
<cfset teamRowRole=role><cfset teamRowExpected=role>
<cfif CGI.request_method EQ 'POST' AND teamPostOperation EQ 'change_admin_role' AND structKeyExists(FORM,'member') AND isSimpleValue(FORM.member) AND val(FORM.member) EQ user_id>
 <cfif structKeyExists(FORM,'role') AND isSimpleValue(FORM.role) AND listFind('OWNER,ADMIN,VIEWER',FORM.role)><cfset teamRowRole=FORM.role></cfif>
 <cfif structKeyExists(FORM,'expected_role') AND isSimpleValue(FORM.expected_role) AND listFind('OWNER,ADMIN,VIEWER',FORM.expected_role)><cfset teamRowExpected=FORM.expected_role></cfif>
</cfif>
<div class="teams-admin-row">
<div class="teams-admin-person"><strong>#encodeForHTML(name)#</strong><span class="teams-small teams-muted teams-admin-email">#encodeForHTML(email)#</span></div>
<cfif teamAdminPolicy.canEdit AND (tw.role EQ 'GLOBAL' OR role NEQ 'OWNER')><form class="teams-form teams-admin-role" method="post" action="#encodeForHTMLAttribute(teamMembersAction)#" data-confirm="Salvar a alteração do papel desta pessoa na gestão do Team?">
<input type="hidden" name="csrf" value="#teamCsrf#"><input type="hidden" name="operation" value="change_admin_role"><input type="hidden" name="team" value="#teamId#"><input type="hidden" name="member" value="#user_id#"><input type="hidden" name="expected_role" value="#encodeForHTMLAttribute(teamRowExpected)#">
<label class="teams-field" >Papel de #encodeForHTML(name)#<select  name="role" aria-label="Papel de #encodeForHTMLAttribute(name)#"><cfloop list="#teamAdminPolicy.roles#" index="teamRoleKey"><option value="#teamRoleKey#" <cfif teamRowRole EQ teamRoleKey>selected</cfif>>#encodeForHTML(teamRoleLabels[teamRoleKey])#</option></cfloop></select></label><button type="submit">Salvar papel</button></form><cfelse><span class="teams-admin-role-label">#encodeForHTML(teamRoleLabels[role])#</span></cfif>
<cfif teamAdminPolicy.canRemove AND role NEQ 'OWNER'><form class="teams-admin-remove" method="post" data-confirm="Remover o acesso administrativo desta pessoa?"><input type="hidden" name="csrf" value="#teamCsrf#"><input type="hidden" name="operation" value="remove_admin"><input type="hidden" name="team" value="#teamId#"><input type="hidden" name="member" value="#user_id#"><button class="danger" type="submit">Remover acesso</button></form></cfif>
</div></cfoutput></cfif></section>
<cfif len(teamAdminPolicy.roles)><section class="teams-panel" aria-labelledby="team-add-user-title"><h2 id="team-add-user-title">Adicionar usuário</h2><p class="teams-muted">Escolha uma das duas opções para incluir uma pessoa na gestão do Team.</p>
<div class="teams-add-grid"><div>
<details class="teams-add-choice" <cfif len(teamExistingSearch) OR teamPostOperation EQ 'add_existing_admin'>open</cfif>><summary><strong>Adicionar usuário existente</strong><span class="teams-small teams-muted teams-add-description">Busque por nome, email ou ID e libere o acesso diretamente.</span></summary><div class="teams-add-body"><cfscript>
teamExistingMember=0;teamExistingRole='VIEWER';
if(CGI.request_method=='POST'&&teamPostOperation=='add_existing_admin'){
 if(structKeyExists(FORM,'member')&&isSimpleValue(FORM.member)&&reFind('^[0-9]{1,14}$',FORM.member))teamExistingMember=val(FORM.member);
 if(structKeyExists(FORM,'role')&&isSimpleValue(FORM.role)&&listFind('OWNER,ADMIN,VIEWER',FORM.role))teamExistingRole=FORM.role;
}
</cfscript>
<p>Busque uma pessoa já cadastrada no RR e escolha o acesso que ela terá na gestão deste Team.</p>
<form class="teams-form" method="get" action="<cfoutput>#encodeForHTMLAttribute(teamMemberBase)#</cfoutput>">
<cfoutput><cfloop collection="#teamMemberFilters#" item="teamMemberField"><input type="hidden" name="#encodeForHTMLAttribute(teamMemberField)#" value="#encodeForHTMLAttribute(teamMemberFilters[teamMemberField])#"></cfloop></cfoutput>
<label class="teams-field full">Buscar usuário por nome, email ou ID<input name="user_busca" type="search" maxlength="100" value="<cfoutput>#encodeForHTMLAttribute(teamExistingSearch)#</cfoutput>" placeholder="Nome, email ou ID"></label><div class="full"><button type="submit" class="secondary">Buscar usuário</button></div></form>
<cfif teamCandidateRows.recordCount>
<p class="teams-small teams-muted teams-admin-note">Até 25 contas ativas sem acesso administrativo a este Team. Confira o nome, o email e o ID antes de adicionar.</p>
<form class="teams-form" method="post" action="<cfoutput>#encodeForHTMLAttribute(teamMembersAction)#</cfoutput>" data-confirm="Liberar imediatamente o acesso desta pessoa à gestão do Team com o papel selecionado?">
<input type="hidden" name="operation" value="add_existing_admin"><input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><input type="hidden" name="team" value="<cfoutput>#teamId#</cfoutput>">
<label class="teams-field full">Usuário existente<select name="member" required><option value="">Selecione uma pessoa</option><cfoutput query="teamCandidateRows"><option value="#id#" <cfif teamExistingMember EQ id>selected</cfif>>ID #id# · #encodeForHTML(name)# · #encodeForHTML(email)#</option></cfoutput></select></label>
<label class="teams-field">Papel no Team<select name="role"><cfoutput><cfloop list="#teamAdminPolicy.roles#" index="teamAssignRole"><option value="#teamAssignRole#" <cfif teamExistingRole EQ teamAssignRole>selected</cfif>>#encodeForHTML(teamRoleLabels[teamAssignRole])#</option></cfloop></cfoutput></select></label>
<p class="teams-small teams-muted">Administrador: operação do Team. Consulta: somente leitura.<cfif tw.role EQ 'GLOBAL'> Titular: gestão completa da equipe.</cfif></p>
<div class="full"><button type="submit">Adicionar à gestão</button></div><p class="teams-small teams-muted full">A inclusão libera o acesso imediatamente com o papel escolhido. O vínculo de atleta é uma escolha separada.</p></form>
<cfelseif len(teamExistingSearch)><p class="teams-muted teams-admin-note"><cfif len(teamExistingSearch) LT 2 AND NOT reFind('^[1-9][0-9]{0,14}$',teamExistingSearch)>Digite pelo menos dois caracteres do nome/email ou um ID válido.<cfelse>Nenhum usuário ativo sem vínculo encontrado. Confira a busca ou os acessos já listados abaixo.</cfif></p></cfif>

</div></details>
</div><div>
<details class="teams-add-choice" <cfif teamPostOperation EQ 'invite_admin'>open</cfif>><summary><strong>Convidar por email</strong><span class="teams-small teams-muted teams-add-description">Envie um convite para a pessoa aceitar com o email informado.</span></summary><div class="teams-add-body">
<form class="teams-form" method="post" action="<cfoutput>#encodeForHTMLAttribute(teamMembersAction)#</cfoutput>"><input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><input type="hidden" name="operation" value="invite_admin"><input type="hidden" name="team" value="<cfoutput>#teamId#</cfoutput>">
<label class="teams-field full">Email da pessoa<input name="email" type="email" required maxlength="255" value="<cfoutput>#encodeForHTMLAttribute(teamInviteEmail)#</cfoutput>"></label><label class="teams-field full">Papel<select name="role"><cfoutput><cfloop list="#teamAdminPolicy.roles#" index="teamInviteOption"><cfif teamInviteOption NEQ 'OWNER'><option value="#teamInviteOption#" <cfif teamInviteRole EQ teamInviteOption>selected</cfif>>#encodeForHTML(teamRoleLabels[teamInviteOption])#</option></cfif></cfloop></cfoutput></select></label><div class="full"><button type="submit">Enviar convite</button></div></form>
<p class="teams-small teams-muted teams-admin-note">O acesso será liberado após o aceite. O convite vale por sete dias. Depois do aceite, o papel poderá ser alterado na lista da equipe.</p>
</div></details></div></div></section>
<section class="teams-panel"><h2>Convites recentes</h2><cfif NOT tw.invites.recordCount><p class="teams-muted">Nenhum convite enviado.</p><cfelse><div class="teams-table-wrap"><table class="teams-table"><thead><tr><th>Email</th><th>Papel</th><th>Situação</th><th>Ação</th></tr></thead><tbody><cfoutput query="tw.invites"><tr><td>#encodeForHTML(email)#</td><td>#encodeForHTML(teamRoleLabels[role])#</td><td><cfif isDate(accepted_at)>Aceito<cfelseif isDate(revoked_at)>Revogado<cfelseif dateCompare(expires_at,now()) LTE 0>Expirado<cfelse>Aguardando aceite</cfif></td><td><cfif NOT isDate(accepted_at) AND NOT isDate(revoked_at) AND listFind(teamAdminPolicy.roles,role)><form method="post"><input type="hidden" name="csrf" value="#teamCsrf#"><input type="hidden" name="operation" value="revoke_invite"><input type="hidden" name="team" value="#teamId#"><input type="hidden" name="invite" value="#id_invite#"><button class="secondary" type="submit">Revogar</button></form></cfif></td></tr></cfoutput></tbody></table></div></cfif></section>
</cfif>
</div>
