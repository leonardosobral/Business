<cfif VARIABLES.businessDelegationAdminReady AND VARIABLES.businessAccountsCanAdminAll AND VARIABLES.businessDelegationTabIdentity.accessMode EQ 'DIRECT'>
  <section class="accounts-panel p-3 mb-4" aria-labelledby="agency-review-title">
    <h4 id="agency-review-title" class="h5">Clientes criados por gestoras</h4>
    <p class="small text-muted">Cada conta requer aprovação interna. A confirmação do titular não concede acesso operacional antes da aprovação.</p>
    <cfif NOT VARIABLES.businessDelegationAgencyQueue.recordCount><p class="mb-0">Nenhum cadastro aguardando revisão.</p></cfif>
    <cfloop query="VARIABLES.businessDelegationAgencyQueue">
      <cfset businessAgencyProposed=deserializeJSON(VARIABLES.businessDelegationAgencyQueue.capacidades_propostas)/>
      <article class="border-top py-3">
        <cfoutput><h5 class="h6">#encodeForHTML(VARIABLES.businessDelegationAgencyQueue.nome_empresa)#</h5><p class="small text-muted">Gestora: #encodeForHTML(VARIABLES.businessDelegationAgencyQueue.gestora_nome)# · Protocolo #VARIABLES.businessDelegationAgencyQueue.id_solicitacao#</p></cfoutput>
        <form method="post" action="./?tab=gestoras" class="row g-2 align-items-end">
          <cfoutput><input type="hidden" name="id_solicitacao" value="#encodeForHTMLAttribute(VARIABLES.businessDelegationAgencyQueue.id_solicitacao)#"/><input type="hidden" name="expectedVersion" value="#encodeForHTMLAttribute(VARIABLES.businessDelegationAgencyQueue.version)#"/><input type="hidden" name="business_account_access_csrf" value="#encodeForHTMLAttribute(VARIABLES.businessAccountContextCsrf)#"/></cfoutput>
          <div class="col-12 col-lg-8"><label class="form-label">Permissões para aprovação
            <select class="form-select" name="capabilities" multiple required aria-describedby="agency-permissions-help">
              <cfloop array="#businessAgencyProposed#" index="businessAgencyCapability"><cfoutput><option value="#encodeForHTMLAttribute(businessAgencyCapability)#" selected>#encodeForHTML(createObject('component','services.accountDelegation.WorkspaceView').label(businessAgencyCapability))#</option></cfoutput></cfloop>
            </select>
          </label><p class="small text-muted" id="agency-permissions-help">Selecione as permissões autorizadas. Use Ctrl ou Command para selecionar mais de uma.</p></div>
          <div class="col-12 col-lg-4 d-flex gap-2"><button class="btn btn-sm btn-warning" name="account_registration_action" value="aprovar" type="submit">Aprovar</button><button class="btn btn-sm btn-outline-danger" name="account_registration_action" value="recusar" type="submit" data-confirm="Recusar este cadastro?">Recusar</button></div>
        </form>
      </article>
    </cfloop>
  </section>
</cfif>
