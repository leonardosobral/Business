<cfif structKeyExists(APPLICATION,"businessAccountDelegationEnabled") AND APPLICATION.businessAccountDelegationEnabled AND structKeyExists(REQUEST,"businessDelegationIdentity") AND isStruct(REQUEST.businessDelegationIdentity) AND structKeyExists(REQUEST.businessDelegationIdentity,"id")>
  <cfquery name="qMyManagerAccounts" datasource="runnerhub">
    SELECT g.id_conta,c.nome_conta
    FROM tb_conta_gestoras g
    JOIN tb_contas c ON c.id_conta=g.id_conta
    JOIN tb_conta_usuarios m ON m.id_conta=g.id_conta
    WHERE m.id_usuario=<cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessDelegationIdentity.id#"/>
      AND m.status='ATIVO' AND m.papel IN('OWNER','ADMIN','OPERADOR','VISUALIZADOR')
      AND c.status='ATIVA' AND g.habilitada=true
    ORDER BY c.nome_conta,c.id_conta
  </cfquery>
  <cfif qMyManagerAccounts.recordCount>
    <div class="col-12"><section class="business-workspace-card" aria-labelledby="manager-home-title">
      <h2 class="h5" id="manager-home-title">Carteira da gestora</h2>
      <p class="small text-muted">Clientes, equipe, convites e histórico em abas.</p>
      <cfoutput><a class="btn btn-outline-warning" href="/gestao-clientes/?gestora=#urlEncodedFormat(qMyManagerAccounts.id_conta[1])#">Abrir carteira</a></cfoutput>
    </section></div>
  </cfif>
</cfif>
