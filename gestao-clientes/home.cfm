<link rel="stylesheet" href="/assets/css/account-delegation.css"/>
<header class="business-workspace-header py-4">
  <h1 class="h2 mb-1">Carteira de clientes</h1>
  <p class="text-muted mb-3">Acompanhe clientes, equipe, convites e histórico da gestora.</p>
  <form method="get" action="/gestao-clientes/" class="d-flex flex-wrap gap-2 align-items-end">
    <label for="gestora" class="form-label mb-0">Gestora</label>
    <select id="gestora" name="gestora" class="form-select business-workspace-manager" required>
      <cfoutput query="VARIABLES.wsManagers"><option value="#encodeForHTMLAttribute(id_conta)#"<cfif id_conta EQ VARIABLES.wsManagerId> selected</cfif>>#encodeForHTML(nome_conta)#</option></cfoutput>
    </select>
    <cfoutput><input type="hidden" name="tab" value="#encodeForHTMLAttribute(VARIABLES.wsTab)#"/><input type="hidden" name="busca" value="#encodeForHTMLAttribute(VARIABLES.wsFilters.search)#"/><input type="hidden" name="estado" value="#encodeForHTMLAttribute(VARIABLES.wsFilters.state)#"/></cfoutput>
    <button class="btn btn-outline-warning" type="submit">Trocar</button>
  </form>
</header>
<cfif len(VARIABLES.wsError)><cfoutput><div class="alert alert-danger" role="alert">#encodeForHTML(VARIABLES.wsError)#</div></cfoutput></cfif>
<cfif len(VARIABLES.wsNotice)><cfoutput><div class="alert alert-success" role="status">#encodeForHTML(VARIABLES.wsNotice)#</div></cfoutput></cfif>
<cfif len(VARIABLES.wsIssuedLink)>
  <div class="alert alert-warning" role="status">
    <p class="mb-2">Link emitido. Copie agora; ele não será mostrado novamente.</p>
    <cfoutput><label for="business-issued-link" class="form-label">Link do convite</label><input id="business-issued-link" class="form-control" type="text" readonly value="#encodeForHTMLAttribute(VARIABLES.wsIssuedLink)#"/></cfoutput>
    <button class="btn btn-outline-dark mt-2" type="button" data-business-copy-link="business-issued-link">Copiar link</button>
  </div>
</cfif>
<nav aria-label="Seções da carteira" class="business-workspace-tabs">
  <ul class="nav nav-tabs">
    <cfloop list="clientes,equipe,convites,historico" index="wsNavTab">
      <cfset wsNavLabel=wsNavTab EQ 'clientes'?'Clientes':wsNavTab EQ 'equipe'?'Equipe':wsNavTab EQ 'convites'?'Convites':'Histórico'/>
      <cfoutput><li class="nav-item"><a class="nav-link<cfif VARIABLES.wsTab EQ wsNavTab> active</cfif>" href="#encodeForHTMLAttribute(VARIABLES.wsView.tabUrl(VARIABLES.wsManagerId,wsNavTab,VARIABLES.wsFilters))#"<cfif VARIABLES.wsTab EQ wsNavTab> aria-current="page"</cfif>>#encodeForHTML(wsNavLabel)#</a></li></cfoutput>
    </cfloop>
  </ul>
</nav>
<form method="get" action="/gestao-clientes/" class="business-workspace-filters row g-2 align-items-end my-3">
  <cfoutput><input type="hidden" name="gestora" value="#encodeForHTMLAttribute(VARIABLES.wsManagerId)#"/><input type="hidden" name="tab" value="#encodeForHTMLAttribute(VARIABLES.wsTab)#"/></cfoutput>
  <div class="col-12 col-md-5"><label for="workspace-search" class="form-label">Buscar</label><cfoutput><input id="workspace-search" class="form-control" name="busca" maxlength="160" value="#encodeForHTMLAttribute(VARIABLES.wsFilters.search)#"/></cfoutput></div>
  <div class="col-12 col-md-4"><label for="workspace-state" class="form-label">Estado</label><select id="workspace-state" class="form-select" name="estado"><option value="">Todos</option>
    <cfloop list="ATIVO,AGUARDANDO_CONTA,PENDENTE_GESTORA,SUSPENSO,REVOGADO,RECUSADO,PENDENTE,ACEITO,CANCELADO,EXPIRADO,SUCCESS,DENIED,CONFLICT,ERROR,INATIVO,CONVIDADO,BLOQUEADO" index="wsState"><cfoutput><option value="#wsState#"<cfif VARIABLES.wsFilters.state EQ wsState> selected</cfif>>#encodeForHTML(VARIABLES.wsView.label(wsState))#</option></cfoutput></cfloop>
  </select></div>
  <div class="col-12 col-md-3"><button class="btn btn-outline-warning w-100" type="submit">Filtrar</button></div>
</form>
<section aria-live="polite" class="business-workspace-panel">
  <cfif VARIABLES.wsTab EQ 'clientes'><cfinclude template="includes/clients.cfm"/>
  <cfelseif VARIABLES.wsTab EQ 'equipe'><cfinclude template="includes/team.cfm"/>
  <cfelseif VARIABLES.wsTab EQ 'convites'><cfinclude template="includes/invites.cfm"/>
  <cfelse><cfinclude template="includes/history.cfm"/></cfif>
</section>
<cfif VARIABLES.wsPage.total GT VARIABLES.wsPage.pageSize>
  <nav aria-label="Páginas da carteira" class="d-flex justify-content-between my-4">
    <cfif VARIABLES.wsPage.page GT 1><cfset wsPrevious=duplicate(VARIABLES.wsFilters)/><cfset wsPrevious.page=VARIABLES.wsPage.page-1/><cfoutput><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(VARIABLES.wsView.tabUrl(VARIABLES.wsManagerId,VARIABLES.wsTab,wsPrevious))#">Anterior</a></cfoutput><cfelse><span></span></cfif>
    <cfoutput><span>Página #VARIABLES.wsPage.page#</span></cfoutput>
    <cfif VARIABLES.wsPage.page*VARIABLES.wsPage.pageSize LT VARIABLES.wsPage.total><cfset wsNext=duplicate(VARIABLES.wsFilters)/><cfset wsNext.page=VARIABLES.wsPage.page+1/><cfoutput><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(VARIABLES.wsView.tabUrl(VARIABLES.wsManagerId,VARIABLES.wsTab,wsNext))#">Próxima</a></cfoutput></cfif>
  </nav>
</cfif>
<script>document.querySelectorAll('[data-business-copy-link]').forEach(function(button){button.addEventListener('click',function(){var input=document.getElementById(button.dataset.businessCopyLink);if(input&&navigator.clipboard)navigator.clipboard.writeText(input.value);});});document.querySelectorAll('[data-confirm]').forEach(function(button){button.addEventListener('click',function(event){if(!window.confirm(button.dataset.confirm))event.preventDefault();});});</script>
