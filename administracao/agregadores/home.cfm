<style>
  .aggregator-manager-list { max-height: 72vh; overflow-y: auto; }
  .aggregator-manager-event { border-bottom: 1px solid rgba(255,255,255,.08); }
</style>

<div class="d-flex flex-wrap justify-content-between align-items-center gap-3 mb-4">
  <div>
    <h1 class="business-page-title mb-1">Gerenciador de Agregadores</h1>
    <p class="text-muted mb-0">Pesquise agregadores, edite seus dados e gerencie os eventos vinculados.</p>
  </div>
  <a class="btn btn-outline-warning" href="/administracao/agrega-revisao/"><i class="fa-solid fa-wand-magic-sparkles me-2"></i>Revisão de agregações</a>
</div>

<cfif len(VARIABLES.aggregatorNotice)><div class="alert alert-success"><cfoutput>#htmlEditFormat(VARIABLES.aggregatorNotice)#</cfoutput></div></cfif>
<cfif len(VARIABLES.aggregatorError)><div class="alert alert-danger"><cfoutput>#htmlEditFormat(VARIABLES.aggregatorError)#</cfoutput></div></cfif>

<div class="row g-4">
  <div class="col-xl-4">
    <div class="card">
      <div class="card-body">
        <form method="get" action="./" class="mb-3">
          <label class="form-label" for="aggregator-search">Pesquisar agregadores</label>
          <div class="input-group">
            <input class="form-control" id="aggregator-search" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.aggregatorSearch)#</cfoutput>" placeholder="Nome, tag ou ID" />
            <button class="btn btn-warning"><i class="fa-solid fa-magnifying-glass"></i></button>
          </div>
        </form>
        <div class="aggregator-manager-list">
          <cfif qAggregators.recordcount>
            <div class="list-group list-group-light">
              <cfoutput query="qAggregators">
                <a class="list-group-item list-group-item-action <cfif id_agrega_evento EQ VARIABLES.aggregatorId>active</cfif>" href="./?id=#id_agrega_evento#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#">
                  <div class="d-flex justify-content-between gap-2"><strong>#htmlEditFormat(nome_evento_agregado)#</strong><span class="badge badge-secondary">#total_eventos#</span></div>
                  <div class="small opacity-75">###id_agrega_evento# · #htmlEditFormat(tipo_agregacao)#<cfif len(trim(tag & ""))> · #htmlEditFormat(tag)#</cfif></div>
                </a>
              </cfoutput>
            </div>
          <cfelse>
            <div class="text-muted">Nenhum agregador encontrado.</div>
          </cfif>
        </div>
      </div>
    </div>
  </div>

  <div class="col-xl-8">
    <cfif qAggregator.recordcount>
      <div class="card mb-4">
        <div class="card-header"><strong>Editar agregador #<cfoutput>#qAggregator.id_agrega_evento#</cfoutput></strong></div>
        <div class="card-body">
          <form method="post" action="./?id=<cfoutput>#qAggregator.id_agrega_evento#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#</cfoutput>" class="row g-3">
            <input type="hidden" name="acao" value="salvar" />
            <input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.aggregatorCsrf#</cfoutput>" />
            <input type="hidden" name="id_agrega_evento" value="<cfoutput>#qAggregator.id_agrega_evento#</cfoutput>" />
            <div class="col-lg-8"><label class="form-label">Nome</label><input class="form-control" name="nome_evento_agregado" required maxlength="255" value="<cfoutput>#htmlEditFormat(qAggregator.nome_evento_agregado)#</cfoutput>" /></div>
            <div class="col-lg-4"><label class="form-label">Tipo de agregação</label><input class="form-control" name="tipo_agregacao" required maxlength="24" value="<cfoutput>#htmlEditFormat(qAggregator.tipo_agregacao)#</cfoutput>" /></div>
            <div class="col-lg-6"><label class="form-label">Tag</label><input class="form-control" name="tag" maxlength="255" value="<cfoutput>#htmlEditFormat(qAggregator.tag & "")#</cfoutput>" /></div>
            <div class="col-lg-3"><label class="form-label">Divisão</label><input class="form-control" name="divisao" maxlength="100" value="<cfoutput>#htmlEditFormat(qAggregator.divisao & "")#</cfoutput>" /></div>
            <div class="col-lg-3"><label class="form-label">Ordem</label><input class="form-control" type="number" name="ordem" value="<cfoutput>#qAggregator.ordem#</cfoutput>" /></div>
            <div class="col-lg-6"><label class="form-label">Tema</label><select class="form-select" name="id_tema" required><cfoutput query="qAggregatorThemes"><option value="#id_tema#" <cfif id_tema EQ qAggregator.id_tema>selected</cfif>>#htmlEditFormat(nome_tema)#</option></cfoutput></select></div>
            <div class="col-12"><button class="btn btn-warning"><i class="fa-solid fa-floppy-disk me-2"></i>Salvar alterações</button></div>
          </form>
        </div>
      </div>

      <div class="card mb-4">
        <div class="card-header d-flex justify-content-between"><strong>Eventos vinculados</strong><span class="badge badge-secondary"><cfoutput>#qAggregatorEvents.recordcount#</cfoutput></span></div>
        <div class="card-body p-0">
          <cfif qAggregatorEvents.recordcount>
            <cfoutput query="qAggregatorEvents">
              <div class="aggregator-manager-event d-flex justify-content-between align-items-center gap-3 p-3">
                <div><strong>#htmlEditFormat(nome_evento)#</strong><div class="small text-muted">###id_evento# · <cfif isDate(data_inicial)>#dateFormat(data_inicial,"dd/mm/yyyy")#<cfelse>Sem data</cfif> · #htmlEditFormat(cidade)#/#htmlEditFormat(estado)#</div></div>
                <form method="post" action="./?id=#qAggregator.id_agrega_evento#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#" onsubmit="return confirm('Remover este evento do agregador?');">
                  <input type="hidden" name="acao" value="remover_evento" /><input type="hidden" name="csrf_token" value="#VARIABLES.aggregatorCsrf#" />
                  <input type="hidden" name="id_agrega_evento" value="#qAggregator.id_agrega_evento#" /><input type="hidden" name="id_evento" value="#id_evento#" />
                  <button class="btn btn-sm btn-outline-danger"><i class="fa-solid fa-link-slash me-1"></i>Remover</button>
                </form>
              </div>
            </cfoutput>
          <cfelse><div class="p-3 text-muted">Nenhum evento vinculado.</div></cfif>
        </div>
      </div>

      <div class="card">
        <div class="card-header"><strong>Adicionar eventos</strong></div>
        <div class="card-body">
          <form method="get" action="./" class="row g-2 mb-3">
            <input type="hidden" name="id" value="<cfoutput>#qAggregator.id_agrega_evento#</cfoutput>" /><input type="hidden" name="busca" value="<cfoutput>#htmlEditFormat(VARIABLES.aggregatorSearch)#</cfoutput>" />
            <div class="col"><input class="form-control" name="evento_busca" value="<cfoutput>#htmlEditFormat(VARIABLES.aggregatorEventSearch)#</cfoutput>" placeholder="Digite ao menos 3 caracteres do nome, tag ou ID" /></div>
            <div class="col-auto"><button class="btn btn-outline-warning">Pesquisar eventos</button></div>
          </form>
          <cfif len(VARIABLES.aggregatorEventSearch) GTE 3>
            <form method="post" action="./?id=<cfoutput>#qAggregator.id_agrega_evento#&busca=#urlEncodedFormat(VARIABLES.aggregatorSearch)#</cfoutput>" onsubmit="return confirm('Adicionar os eventos selecionados? Eventos ligados a outro agregador serão transferidos.');">
              <input type="hidden" name="acao" value="adicionar_eventos" /><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.aggregatorCsrf#</cfoutput>" /><input type="hidden" name="id_agrega_evento" value="<cfoutput>#qAggregator.id_agrega_evento#</cfoutput>" />
              <div class="table-responsive"><table class="table align-middle"><thead><tr><th></th><th>Evento</th><th>Data/local</th><th>Agregador atual</th></tr></thead><tbody>
                <cfoutput query="qAggregatorEventSearch"><tr><td><input class="form-check-input" type="checkbox" name="eventos" value="#id_evento#" /></td><td><strong>#htmlEditFormat(nome_evento)#</strong><div class="small text-muted">###id_evento# · #htmlEditFormat(tag & "")#</div></td><td><cfif isDate(data_inicial)>#dateFormat(data_inicial,"dd/mm/yyyy")#<cfelse>Sem data</cfif><div class="small text-muted">#htmlEditFormat(cidade)#/#htmlEditFormat(estado)#</div></td><td><cfif val(id_agrega_evento) GT 0><span class="text-warning">###id_agrega_evento# · #htmlEditFormat(agregador_atual)#</span><cfelse><span class="text-muted">Sem agregador</span></cfif></td></tr></cfoutput>
              </tbody></table></div>
              <cfif qAggregatorEventSearch.recordcount><button class="btn btn-success"><i class="fa-solid fa-link me-2"></i>Adicionar selecionados</button><cfelse><div class="text-muted">Nenhum evento encontrado.</div></cfif>
            </form>
          </cfif>
        </div>
      </div>
    <cfelse>
      <div class="card"><div class="card-body text-center py-5 text-muted"><i class="fa-solid fa-object-group fa-3x mb-3"></i><p class="mb-0">Selecione um agregador para editar e gerenciar seus eventos.</p></div></div>
    </cfif>
  </div>
</div>
