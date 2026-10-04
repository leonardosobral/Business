<h2 class="h4">Clientes</h2>
<cfif VARIABLES.wsCanManage>
  <details class="business-workspace-card mb-3"><summary>Solicitar gestão de uma conta existente</summary>
    <p class="small text-muted">Informe o número exato da conta. O recebimento é genérico; o titular da conta decide se autoriza a relação.</p>
    <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="row g-2"></cfoutput>
      <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/></cfoutput>
      <input type="hidden" name="business_delegation_action" value="request_relationship"/>
      <div class="col-12 col-md-4"><label for="client-reference" class="form-label">Número da conta</label><input id="client-reference" class="form-control" name="client_reference" inputmode="numeric" pattern="[1-9][0-9]*" required/></div>
      <div class="col-12"><cfinclude template="capabilities.cfm"/></div>
      <cfinclude template="workspace_form.cfm"/>
      <div><button class="btn btn-warning" type="submit">Enviar solicitação</button></div>
    </form>
  </details>
  <details class="business-workspace-card mb-4"><summary>Criar cliente</summary>
    <p class="small text-muted">A conta ficará pendente até revisão interna. O titular precisa confirmar o convite.</p>
    <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="row g-2"></cfoutput>
      <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/></cfoutput>
      <input type="hidden" name="business_delegation_action" value="create_client"/>
      <div class="col-12 col-md-7"><label class="form-label">Nome da empresa<input class="form-control" name="nome_empresa" maxlength="160" required/></label></div>
      <div class="col-12 col-md-2"><label class="form-label">Titular<select class="form-select" name="tipo_titular"><option value="PJ">Pessoa jurídica</option><option value="PF">Pessoa física</option></select></label></div>
      <div class="col-12 col-md-3"><label class="form-label">Documento<input class="form-control" name="documento" maxlength="20" required/></label></div>
      <div class="col-12 col-md-6"><label class="form-label">Responsável<input class="form-control" name="nome_responsavel" maxlength="200" required/></label></div>
      <div class="col-12 col-md-6"><label class="form-label">E-mail do responsável<input class="form-control" type="email" name="email_responsavel" maxlength="255" required/></label></div>
      <div class="col-12 col-md-4"><label class="form-label">Telefone<input class="form-control" name="telefone_responsavel" maxlength="30"/></label></div>
      <div class="col-12 col-md-4"><label class="form-label">Site<input class="form-control" name="site" maxlength="256"/></label></div>
      <div class="col-12 col-md-4"><label class="form-label">Tipo de prestador<input class="form-control" name="tipo_prestador" maxlength="80" required/></label></div>
      <div class="col-12 col-md-5"><label class="form-label">Cidade<input class="form-control" name="cidade" maxlength="128"/></label></div>
      <div class="col-12 col-md-2"><label class="form-label">UF<input class="form-control" name="estado" maxlength="2"/></label></div>
      <div class="col-12"><label class="form-label">Observação<textarea class="form-control" name="mensagem" rows="2" maxlength="10000"></textarea></label></div>
      <div class="col-12"><cfinclude template="capabilities.cfm"/></div>
      <cfinclude template="workspace_form.cfm"/>
      <div><button class="btn btn-warning" type="submit">Criar para revisão</button></div>
    </form>
  </details>
</cfif>
<cfif arrayLen(VARIABLES.wsClientPage.items) EQ 0><p>Nenhum cliente neste filtro.</p></cfif>
<cfloop array="#VARIABLES.wsClientPage.items#" index="wsClient">
  <article class="business-workspace-card mb-3">
    <cfoutput><h3 class="h5">#encodeForHTML(wsClient.clientName)#</h3><p class="small text-muted">Conta ## #encodeForHTML(wsClient.clientId)# · #encodeForHTML(VARIABLES.wsView.label(wsClient.status))#</p></cfoutput>
    <cfif wsClient.origin EQ 'CRIACAO_GESTORA' AND listFind('AGUARDANDO_CONTA,ATIVO',wsClient.status)>
      <cfif NOT wsClient.ownerConfirmed><p class="business-workspace-warning">Titular ainda não confirmado</p><cfelseif wsClient.status EQ 'AGUARDANDO_CONTA'><p>Convite do titular confirmado. A aprovação interna continua pendente.</p></cfif>
      <cfif VARIABLES.wsCanManage AND NOT wsClient.ownerConfirmed>
        <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="d-flex flex-wrap gap-2 align-items-end"></cfoutput>
          <input type="hidden" name="business_delegation_action" value="invite_owner"/>
          <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(wsClient.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(wsClient.version)#"/></cfoutput>
          <label class="form-label">E-mail do titular<input class="form-control" type="email" name="owner_email" required/></label>
          <cfinclude template="workspace_form.cfm"/>
          <button class="btn btn-outline-warning" type="submit">Emitir ou renovar link</button>
        </form>
      </cfif>
    </cfif>
    <cfif wsClient.status EQ 'AGUARDANDO_CONTA'>
      <cfif VARIABLES.wsCanManage AND structKeyExists(wsClient,'pendingFields') AND NOT structIsEmpty(wsClient.pendingFields)>
        <details class="mt-3"><summary>Corrigir cadastro pendente</summary>
          <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="row g-2 mt-2"></cfoutput>
            <input type="hidden" name="business_delegation_action" value="update_pending_client"/>
            <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(wsClient.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(wsClient.version)#"/></cfoutput>
            <div class="col-12 col-md-8"><label class="form-label">Nome da empresa<cfoutput><input class="form-control" name="nome_empresa" maxlength="160" value="#encodeForHTMLAttribute(wsClient.pendingFields.nome_empresa)#" required/></cfoutput></label></div>
            <div class="col-12 col-md-4"><label class="form-label">Titular<select class="form-select" name="tipo_titular"><cfoutput><option value="PJ"<cfif wsClient.pendingFields.tipo_titular EQ 'PJ'> selected</cfif>>Pessoa jurídica</option><option value="PF"<cfif wsClient.pendingFields.tipo_titular EQ 'PF'> selected</cfif>>Pessoa física</option></cfoutput></select></label></div>
            <div class="col-12 col-md-4"><label class="form-label">Documento<cfoutput><input class="form-control" name="documento" maxlength="20" value="#encodeForHTMLAttribute(wsClient.pendingFields.documento)#"<cfif wsClient.ownerConfirmed> readonly</cfif> required/></cfoutput></label></div>
            <div class="col-12 col-md-8"><label class="form-label">Responsável<cfoutput><input class="form-control" name="nome_responsavel" maxlength="200" value="#encodeForHTMLAttribute(wsClient.pendingFields.nome_responsavel)#"<cfif wsClient.ownerConfirmed> readonly</cfif> required/></cfoutput></label></div>
            <div class="col-12 col-md-6"><label class="form-label">E-mail do responsável<cfoutput><input class="form-control" name="email_responsavel" type="email" maxlength="255" value="#encodeForHTMLAttribute(wsClient.pendingFields.email_responsavel)#"<cfif wsClient.ownerConfirmed> readonly</cfif> required/></cfoutput></label></div>
            <div class="col-12 col-md-6"><label class="form-label">Telefone<cfoutput><input class="form-control" name="telefone_responsavel" maxlength="30" value="#encodeForHTMLAttribute(wsClient.pendingFields.telefone_responsavel)#"/></cfoutput></label></div>
            <div class="col-12 col-md-6"><label class="form-label">Site<cfoutput><input class="form-control" name="site" maxlength="256" value="#encodeForHTMLAttribute(wsClient.pendingFields.site)#"/></cfoutput></label></div>
            <div class="col-12 col-md-6"><label class="form-label">Tipo de prestador<cfoutput><input class="form-control" name="tipo_prestador" maxlength="80" value="#encodeForHTMLAttribute(wsClient.pendingFields.tipo_prestador)#" required/></cfoutput></label></div>
            <div class="col-12 col-md-6"><label class="form-label">Cidade<cfoutput><input class="form-control" name="cidade" maxlength="128" value="#encodeForHTMLAttribute(wsClient.pendingFields.cidade)#"/></cfoutput></label></div>
            <div class="col-12 col-md-2"><label class="form-label">UF<cfoutput><input class="form-control" name="estado" maxlength="2" value="#encodeForHTMLAttribute(wsClient.pendingFields.estado)#"/></cfoutput></label></div>
            <div class="col-12"><label class="form-label">Observação<cfoutput><textarea class="form-control" name="mensagem" rows="2" maxlength="10000">#encodeForHTML(wsClient.pendingFields.mensagem)#</textarea></cfoutput></label></div>
            <cfinclude template="workspace_form.cfm"/>
            <div><button class="btn btn-outline-warning" type="submit">Salvar correção</button></div>
          </form>
        </details>
      </cfif>
    </cfif>
    <cfif wsClient.status EQ 'ATIVO'><p class="small text-muted mb-0">O acesso operacional depende das atribuições da equipe.</p></cfif>
    <cfif VARIABLES.wsCanManage AND wsClient.status EQ 'ATIVO'>
      <details class="mt-2"><summary>Atribuir integrante a este cliente</summary>
        <p class="small text-muted mt-2">Use o número do integrante exibido na aba Equipe. A permissão escolhida precisa estar no vínculo do cliente.</p>
        <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="row g-2"></cfoutput>
          <input type="hidden" name="business_delegation_action" value="assign_member"/>
          <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="assignment_target" value="#encodeForHTMLAttribute(wsClient.relationshipId & ':' & wsClient.version)#"/></cfoutput>
          <div class="col-12 col-md-4"><label class="form-label">Número do integrante<input class="form-control" name="membership_id" inputmode="numeric" pattern="[1-9][0-9]*" required/></label></div>
          <div class="col-12"><cfinclude template="capabilities.cfm"/></div>
          <cfinclude template="workspace_form.cfm"/>
          <div><button class="btn btn-sm btn-warning" type="submit">Salvar atribuição</button></div>
        </form>
      </details>
    </cfif>
    <cfif VARIABLES.wsCanManage AND wsClient.status EQ 'PENDENTE_GESTORA'>
      <p>O titular convidou esta gestora. Escolha as permissões para aceitar.</p>
      <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="mb-2"></cfoutput>
        <input type="hidden" name="business_delegation_action" value="decide_relationship"/><input type="hidden" name="decision" value="APPROVE"/>
        <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(wsClient.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(wsClient.version)#"/></cfoutput>
        <cfinclude template="capabilities.cfm"/><cfinclude template="workspace_form.cfm"/>
        <button class="btn btn-sm btn-warning mt-2" type="submit">Aceitar convite</button>
      </form>
      <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#"></cfoutput>
        <input type="hidden" name="business_delegation_action" value="decide_relationship"/><input type="hidden" name="decision" value="DECLINE"/>
        <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(wsClient.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(wsClient.version)#"/></cfoutput>
        <cfinclude template="workspace_form.cfm"/><button class="btn btn-sm btn-outline-danger" type="submit" data-confirm="Recusar esta proposta?">Recusar</button>
      </form>
    </cfif>
    <cfif VARIABLES.wsCanManage AND listFind('ATIVO,SUSPENSO,PENDENTE_GESTORA',wsClient.status)>
      <cfoutput><form method="post" action="#encodeForHTMLAttribute(VARIABLES.wsLink)#" class="mt-2"></cfoutput>
        <input type="hidden" name="business_delegation_action" value="change_relationship"/><input type="hidden" name="relationship_action" value="RENOUNCE"/>
        <cfoutput><input type="hidden" name="business_workspace_csrf" value="#encodeForHTMLAttribute(VARIABLES.wsCsrf)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(wsClient.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(wsClient.version)#"/></cfoutput>
        <cfinclude template="workspace_form.cfm"/>
        <button class="btn btn-sm btn-outline-danger" type="submit" data-confirm="Abrir mão da gestão deste cliente?">Renunciar à gestão</button>
      </form>
    </cfif>
  </article>
</cfloop>
