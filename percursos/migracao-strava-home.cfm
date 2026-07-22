<style>
  .strava-migration-stat { border: 1px solid rgba(255,255,255,.12); border-radius: .75rem; background: rgba(255,255,255,.025); padding: .85rem 1rem; min-height: 84px; }
  .strava-migration-stat strong { display: block; font-size: 1.4rem; line-height: 1.1; }
  .strava-migration-stat span { color: rgba(255,255,255,.6); font-size: .78rem; }
  .strava-migration-message { max-width: 340px; white-space: normal; }
  .strava-migration-event { min-width: 260px; }
  .strava-migration-id { white-space: nowrap; }
  .strava-migration-toolbar { position: sticky; top: 64px; z-index: 5; }
  @media (max-width: 991px) { .strava-migration-toolbar { position: static; } }
</style>

<div class="d-flex flex-wrap align-items-start justify-content-between gap-3 mb-4">
  <div>
    <h2 class="mb-1"><i class="fa-brands fa-strava me-2" style="color:#fc4c02"></i>Migração de mapas Strava</h2>
    <p class="text-muted mb-0">Importação controlada dos GPX antigos com vínculo exato ao evento e à modalidade.</p>
  </div>
  <a class="btn btn-outline-secondary" href="./"><i class="fa-solid fa-arrow-left me-2"></i>Repositório de percursos</a>
</div>

<cfif len(VARIABLES.stravaMigrationAlert.message)>
  <div class="alert alert-<cfoutput>#VARIABLES.stravaMigrationAlert.type#</cfoutput>"><cfoutput>#htmlEditFormat(VARIABLES.stravaMigrationAlert.message)#</cfoutput></div>
</cfif>

<cfif NOT VARIABLES.stravaMigrationSchemaReady>
  <div class="card bg-dark border-warning">
    <div class="card-body p-4">
      <h5 class="text-warning"><i class="fa-solid fa-database me-2"></i>Estrutura de migração pendente</h5>
      <p class="mb-2">Aplique o SQL abaixo antes de iniciar. Ele não remove nem altera o campo <code>mapa</code>.</p>
      <code>/_codex/sql/2026-07-21_strava_percursos_migration.sql</code>
    </div>
  </div>
<cfelse>
  <cfif NOT VARIABLES.stravaMigrationStorageReady>
    <div class="alert alert-danger"><strong>Repositório indisponível.</strong> <cfoutput>#htmlEditFormat(VARIABLES.stravaMigrationStorageError)#</cfoutput></div>
  </cfif>

  <div class="row g-2 mb-4">
    <div class="col-6 col-md-3 col-xl"><div class="strava-migration-stat"><strong><cfoutput>#numberFormat(qStravaMigrationStats.total)#</cfoutput></strong><span>Total inventariado</span></div></div>
    <div class="col-6 col-md-3 col-xl"><div class="strava-migration-stat"><strong class="text-warning"><cfoutput>#numberFormat(qStravaMigrationStats.pendente)#</cfoutput></strong><span>Pendentes</span></div></div>
    <div class="col-6 col-md-3 col-xl"><div class="strava-migration-stat"><strong class="text-info"><cfoutput>#numberFormat(qStravaMigrationStats.validado)#</cfoutput></strong><span>Validados</span></div></div>
    <div class="col-6 col-md-3 col-xl"><div class="strava-migration-stat"><strong class="text-success"><cfoutput>#numberFormat(qStravaMigrationStats.migrado+qStravaMigrationStats.reutilizado)#</cfoutput></strong><span>Migrados</span></div></div>
    <div class="col-6 col-md-3 col-xl"><div class="strava-migration-stat"><strong class="text-warning"><cfoutput>#numberFormat(qStravaMigrationStats.revisao)#</cfoutput></strong><span>Para revisão</span></div></div>
    <div class="col-6 col-md-3 col-xl"><div class="strava-migration-stat"><strong class="text-danger"><cfoutput>#numberFormat(qStravaMigrationStats.erro)#</cfoutput></strong><span>Com erro</span></div></div>
  </div>

  <div class="card bg-dark border-secondary mb-3">
    <div class="card-body">
      <form class="row g-2 align-items-end" method="get" action="./migracao-strava.cfm">
        <div class="col-lg-7">
          <label class="form-label" for="strava-migration-search">Buscar</label>
          <input class="form-control" id="strava-migration-search" name="busca" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>" placeholder="Evento, ID do evento, modalidade ou rota Strava"/>
        </div>
        <div class="col-lg-3">
          <label class="form-label" for="strava-migration-status">Status</label>
          <select class="form-select" id="strava-migration-status" name="status">
            <cfloop list="#VARIABLES.stravaMigrationAllowedStatuses#" item="migrationStatus">
              <option value="<cfoutput>#migrationStatus#</cfoutput>" <cfif URL.status EQ migrationStatus>selected</cfif>><cfoutput>#migrationStatus EQ 'todos' ? 'Todos' : uCase(left(migrationStatus,1)) & mid(migrationStatus,2,len(migrationStatus))#</cfoutput></option>
            </cfloop>
          </select>
        </div>
        <div class="col-lg-2 d-grid"><button class="btn btn-outline-warning" type="submit"><i class="fa-solid fa-filter me-2"></i>Filtrar</button></div>
      </form>
    </div>
  </div>

  <form method="post" action="./migracao-strava.cfm" id="strava-migration-form">
    <input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.stravaMigrationCsrfToken#</cfoutput>"/>

    <div class="card bg-dark border-secondary mb-3 strava-migration-toolbar">
      <div class="card-body py-3">
        <div class="row g-3 align-items-end">
          <div class="col-lg-4">
            <div class="form-label">Modo</div>
            <div class="d-flex flex-wrap gap-3">
              <div class="form-check"><input class="form-check-input" type="radio" name="modo" id="migration-mode-dry" value="simular" checked><label class="form-check-label" for="migration-mode-dry">Simular</label></div>
              <div class="form-check"><input class="form-check-input" type="radio" name="modo" id="migration-mode-write" value="migrar"><label class="form-check-label" for="migration-mode-write">Migrar de verdade</label></div>
            </div>
          </div>
          <div class="col-lg-2">
            <label class="form-label" for="migration-limit">Limite do lote</label>
            <select class="form-select" id="migration-limit" name="limite"><option>1</option><option selected>5</option><option>10</option></select>
          </div>
          <div class="col-lg-3"><div class="small text-muted">Com itens marcados, processa somente a seleção. Sem seleção, usa o próximo lote elegível.</div></div>
          <div class="col-lg-3 d-flex gap-2">
            <button class="btn btn-warning flex-grow-1" type="submit" name="acao" value="processar" <cfif NOT VARIABLES.stravaMigrationStorageReady>disabled</cfif>><i class="fa-solid fa-play me-2"></i>Processar</button>
            <button class="btn btn-outline-secondary" type="submit" name="acao" value="reabrir" title="Reabrir selecionados"><i class="fa-solid fa-rotate-left"></i></button>
            <button class="btn btn-outline-danger" type="submit" name="acao" value="ignorar" title="Ignorar selecionados"><i class="fa-solid fa-ban"></i></button>
          </div>
        </div>
      </div>
    </div>

    <div class="card bg-dark border-secondary">
      <div class="table-responsive">
        <table class="table table-dark table-hover align-middle mb-0">
          <thead><tr><th class="ps-3"><input class="form-check-input" id="migration-select-all" type="checkbox" aria-label="Selecionar todos"/></th><th>Status</th><th>Evento e modalidade</th><th>Strava</th><th>Percurso criado</th><th>Tentativas</th><th>Resultado</th></tr></thead>
          <tbody>
            <cfoutput query="qStravaMigrationItems">
              <cfset VARIABLES.stravaMigrationBadge = "badge-secondary"/>
              <cfif listFindNoCase("migrado,reutilizado",status)><cfset VARIABLES.stravaMigrationBadge="badge-success"/>
              <cfelseif status EQ "erro"><cfset VARIABLES.stravaMigrationBadge="badge-danger"/>
              <cfelseif listFindNoCase("pendente,revisao",status)><cfset VARIABLES.stravaMigrationBadge="badge-warning"/>
              <cfelseif listFindNoCase("validado,processando",status)><cfset VARIABLES.stravaMigrationBadge="badge-info"/></cfif>
              <tr>
                <td class="ps-3"><input class="form-check-input migration-item" type="checkbox" name="modalidade_ids" value="#id_evento_percurso#" aria-label="Selecionar modalidade #id_evento_percurso#" <cfif listFindNoCase('migrado,reutilizado,processando',status)>disabled</cfif>/></td>
                <td><span class="badge #VARIABLES.stravaMigrationBadge#">#htmlEditFormat(status)#</span><cfif len(ultimo_http_status & '')><div class="small text-muted mt-1">HTTP #ultimo_http_status#</div></cfif></td>
                <td class="strava-migration-event"><strong>#htmlEditFormat(nome_evento)#</strong><div class="small text-muted"><span class="strava-migration-id">Evento ###id_evento#</span> · <span class="strava-migration-id">Modalidade ###id_evento_percurso#</span></div><div class="small">#htmlEditFormat(percurso_evento)# #htmlEditFormat(unidade_de_medida)# · #htmlEditFormat(tipo_corrida)#<cfif len(trim(cidade & ''))> · #htmlEditFormat(cidade)#<cfif len(trim(estado & ''))>/#htmlEditFormat(estado)#</cfif></cfif></div></td>
                <td><a href="#htmlEditFormat(strava_url)#" target="_blank" rel="noopener noreferrer">#htmlEditFormat(strava_route_id)# <i class="fa-solid fa-arrow-up-right-from-square ms-1"></i></a><cfif len(sha256 & '')><div class="small text-muted font-monospace" title="#sha256#">#left(sha256,12)#...</div></cfif></td>
                <td><cfif len(id_percurso & '')><a class="btn btn-sm btn-outline-warning" href="./?id=#id_percurso#">Percurso ###id_percurso#</a><cfelse><span class="text-muted">-</span></cfif><cfif len(distancia_gpx_m & '')><div class="small text-muted mt-1">#numberFormat(distancia_gpx_m/1000,'0.000')# km no GPX</div></cfif></td>
                <td>#numberFormat(tentativas)#<cfif isDate(data_atualizacao)><div class="small text-muted">#dateTimeFormat(data_atualizacao,'dd/mm HH:nn')#</div></cfif></td>
                <td><div class="small strava-migration-message">#htmlEditFormat(mensagem)#</div></td>
              </tr>
            </cfoutput>
            <cfif NOT qStravaMigrationItems.recordcount><tr><td colspan="7" class="text-center text-muted py-5">Nenhuma rota encontrada para os filtros selecionados.</td></tr></cfif>
          </tbody>
        </table>
      </div>
    </div>
  </form>

  <cfif VARIABLES.stravaMigrationTotalPages GT 1>
    <nav class="mt-3" aria-label="Paginação da migração"><ul class="pagination pagination-sm justify-content-center">
      <cfloop from="1" to="#VARIABLES.stravaMigrationTotalPages#" index="migrationPageNumber">
        <li class="page-item <cfif migrationPageNumber EQ VARIABLES.stravaMigrationPage>active</cfif>"><a class="page-link" href="./migracao-strava.cfm?status=<cfoutput>#urlEncodedFormat(URL.status)#&busca=#urlEncodedFormat(URL.busca)#&pagina=#migrationPageNumber#</cfoutput>"><cfoutput>#migrationPageNumber#</cfoutput></a></li>
      </cfloop>
    </ul></nav>
  </cfif>

  <script>
    (() => {
      const selectAll = document.getElementById('migration-select-all');
      const items = Array.from(document.querySelectorAll('.migration-item'));
      if (selectAll) selectAll.addEventListener('change', () => items.forEach(item => { item.checked = selectAll.checked; }));
      const form = document.getElementById('strava-migration-form');
      if (form) form.addEventListener('submit', event => {
        const action = event.submitter ? event.submitter.value : '';
        const writeMode = document.getElementById('migration-mode-write');
        if (action === 'processar' && writeMode && writeMode.checked && !window.confirm('Confirmar a criação e vinculação definitiva dos percursos deste lote? O campo mapa será preservado.')) event.preventDefault();
        if (action === 'ignorar' && !window.confirm('Marcar os itens selecionados como ignorados?')) event.preventDefault();
      });
    })();
  </script>
</cfif>
