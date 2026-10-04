<h2 class="h4">Equipe</h2><p class="small text-muted">Só integrantes atribuídos a um cliente podem operar os módulos concedidos.</p>
<cfif arrayLen(VARIABLES.wsTeamPage.items) EQ 0><p>Nenhum integrante neste filtro.</p></cfif>
<cfloop array="#VARIABLES.wsTeamPage.items#" index="wsMember">
  <article class="business-workspace-card mb-3">
    <cfoutput><h3 class="h5">#encodeForHTML(wsMember.memberName)#</h3><p class="small text-muted">Integrante ## #encodeForHTML(wsMember.membershipId)# · #encodeForHTML(wsMember.email)# · #encodeForHTML(VARIABLES.wsView.label(wsMember.role))# · #encodeForHTML(VARIABLES.wsView.label(wsMember.status))#</p></cfoutput>
    <cfif arrayLen(wsMember.assignments)><h4 class="h6">Clientes atribuídos</h4><ul>
      <cfloop array="#wsMember.assignments#" index="wsAssignment"><li><cfoutput>#encodeForHTML(wsAssignment.clientName)#</cfoutput>
      <cfif VARIABLES.wsCanManage><cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="d-inline"></cfoutput>
        <input type="hidden" name="business_delegation_action" value="remove_assignment"/>
        <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="assignment_id" value="#encodeForHTMLAttribute(wsAssignment.assignmentId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(wsAssignment.version)#"/></cfoutput>
        <cfinclude template="workspace_form.cfm"/>
        <button class="btn btn-sm btn-outline-danger" type="submit" data-confirm="Remover esta atribuição?">Remover</button>
      </form></cfif></li></cfloop>
    </ul></cfif>
    <cfif VARIABLES.wsCanManage AND wsMember.status EQ 'ATIVO'>
      <details><summary>Atribuir cliente</summary><cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="row g-2 mt-2"></cfoutput>
        <input type="hidden" name="business_delegation_action" value="assign_member"/>
        <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="membership_id" value="#encodeForHTMLAttribute(wsMember.membershipId)#"/></cfoutput>
        <div class="col-12 col-md-6"><label class="form-label">Cliente<select class="form-select" name="assignment_target" required>
          <cfloop array="#VARIABLES.wsClientPage.items#" index="wsAssignable"><cfif wsAssignable.status EQ 'ATIVO'><cfoutput><option value="#encodeForHTMLAttribute(wsAssignable.relationshipId & ':' & wsAssignable.version)#">#encodeForHTML(wsAssignable.clientName)#</option></cfoutput></cfif></cfloop>
        </select></label></div>
        <div class="col-12"><cfinclude template="capabilities.cfm"/></div>
        <cfinclude template="workspace_form.cfm"/>
        <div><button class="btn btn-warning" type="submit">Salvar atribuição</button></div>
      </form></details>
    </cfif>
  </article>
</cfloop>
