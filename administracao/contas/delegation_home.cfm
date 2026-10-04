<cfset VARIABLES.businessDelegationLabels=createObject("component","services.accountDelegation.WorkspaceView")/>
<section class="accounts-tab-panel <cfif VARIABLES.accountManagementTab NEQ 'gestoras'>d-none</cfif>" data-account-tab-panel="gestoras">
  <h5>Gestoras</h5>
  <p class="small text-muted">Gerenciar campanhas pode consumir o saldo desta conta. Compras e histórico de pagamentos são permissões separadas.</p>
  <cfif len(VARIABLES.businessDelegationTabError)><cfoutput><div class="alert alert-danger" role="alert">#encodeForHTML(VARIABLES.businessDelegationTabError)#</div></cfoutput></cfif>
  <cfif VARIABLES.businessDelegationCanSeeClientManagers>
    <cfif NOT arrayLen(VARIABLES.businessDelegationClientManagers)><p>Nenhuma gestora vinculada.</p></cfif>
    <cfloop array="#VARIABLES.businessDelegationClientManagers#" index="businessManager">
      <article class="accounts-panel p-3 mb-2">
        <cfoutput><h6>#encodeForHTML(businessManager.managerName)#</h6><p class="small text-muted">#encodeForHTML(VARIABLES.businessDelegationLabels.label(businessManager.classification))# · #encodeForHTML(VARIABLES.businessDelegationLabels.label(businessManager.status))#</p></cfoutput>
        <cfif listFind('ATIVO,SUSPENSO,PENDENTE_CLIENTE',businessManager.status)>
          <details><summary>Revogar acesso desta gestora</summary><p>Esta ação encerra as atribuições da equipe da gestora neste cliente.</p>
            <form method="post" action="./?tab=gestoras">
              <input type="hidden" name="account_delegation_action" value="revoke_relationship"/>
              <cfoutput><input type="hidden" name="business_account_access_csrf" value="#encodeForHTMLAttribute(VARIABLES.businessAccountContextCsrf)#"/><input type="hidden" name="account_id" value="#encodeForHTMLAttribute(qBusinessAccountEdit.id_conta)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(businessManager.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(businessManager.version)#"/></cfoutput>
              <button class="btn btn-sm btn-outline-danger" type="submit" data-confirm="Revogar esta gestora?">Confirmar revogação</button>
            </form>
          </details>
        </cfif>
      </article>
    </cfloop>
  </cfif>
  <cfif VARIABLES.businessAccountsCanAdminAll AND VARIABLES.businessDelegationTabIdentity.accessMode EQ 'DIRECT'>
    <div class="accounts-panel p-3 mb-3">
      <h6>Configuração interna</h6>
      <form method="post" action="./?tab=gestoras" class="row g-2 align-items-end">
        <input type="hidden" name="account_delegation_action" value="configure_manager"/>
        <cfoutput><input type="hidden" name="business_account_access_csrf" value="#encodeForHTMLAttribute(VARIABLES.businessAccountContextCsrf)#"/><input type="hidden" name="account_id" value="#encodeForHTMLAttribute(qBusinessAccountEdit.id_conta)#"/><input type="hidden" name="expected_version" value="#VARIABLES.businessDelegationManagerConfig.recordCount?VARIABLES.businessDelegationManagerConfig.version[1]:0#"/></cfoutput>
        <div class="col-12 col-md-5"><label class="form-label">Classificação<select class="form-select" name="classification"><cfloop list="AGENCIA,TICKETEIRA,OUTROS" index="businessClass"><cfoutput><option value="#businessClass#"<cfif VARIABLES.businessDelegationManagerConfig.recordCount AND VARIABLES.businessDelegationManagerConfig.classificacao[1] EQ businessClass> selected</cfif>>#encodeForHTML(VARIABLES.businessDelegationLabels.label(businessClass))#</option></cfoutput></cfloop></select></label></div>
        <div class="col-12 col-md-3"><label class="form-label">Habilitação<select class="form-select" name="enabled"><option value="1"<cfif VARIABLES.businessDelegationManagerConfig.recordCount AND VARIABLES.businessDelegationManagerConfig.habilitada[1]> selected</cfif>>Habilitada</option><option value="0"<cfif NOT VARIABLES.businessDelegationManagerConfig.recordCount OR NOT VARIABLES.businessDelegationManagerConfig.habilitada[1]> selected</cfif>>Desabilitada</option></select></label></div>
        <div class="col-12 col-md-4"><button class="btn btn-warning" type="submit">Salvar configuração</button></div>
      </form>
    </div>
    <cfif VARIABLES.businessDelegationInternalManagers.recordCount>
      <h6>Relações deste cliente</h6>
      <cfloop query="VARIABLES.businessDelegationInternalManagers">
        <form method="post" action="./?tab=gestoras" class="accounts-panel p-2 mb-2 d-flex flex-wrap justify-content-between align-items-center gap-2">
          <cfoutput><span>#encodeForHTML(VARIABLES.businessDelegationInternalManagers.managerName)# · #encodeForHTML(VARIABLES.businessDelegationLabels.label(VARIABLES.businessDelegationInternalManagers.status))#</span><input type="hidden" name="account_id" value="#encodeForHTMLAttribute(qBusinessAccountEdit.id_conta)#"/><input type="hidden" name="relationship_id" value="#encodeForHTMLAttribute(VARIABLES.businessDelegationInternalManagers.relationshipId)#"/><input type="hidden" name="expected_version" value="#encodeForHTMLAttribute(VARIABLES.businessDelegationInternalManagers.version)#"/><input type="hidden" name="business_account_access_csrf" value="#encodeForHTMLAttribute(VARIABLES.businessAccountContextCsrf)#"/></cfoutput>
          <cfif VARIABLES.businessDelegationInternalManagers.status EQ 'ATIVO'><button class="btn btn-sm btn-outline-danger" name="account_delegation_action" value="suspend_relationship" type="submit" data-confirm="Suspender esta relação?">Suspender</button><cfelse><button class="btn btn-sm btn-outline-warning" name="account_delegation_action" value="reactivate_relationship" type="submit">Reativar</button></cfif>
        </form>
      </cfloop>
    </cfif>
  </cfif>
</section>
<script>document.querySelectorAll('[data-confirm]').forEach(function(button){button.addEventListener('click',function(event){if(!window.confirm(button.dataset.confirm))event.preventDefault();});});</script>
