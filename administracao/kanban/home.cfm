<div
    class="business-page trello-kanban-page"
    id="trelloKanban"
    data-api-url="/administracao/kanban/api.cfm"
    data-csrf-token="<cfoutput>#encodeForHtmlAttribute(VARIABLES.trelloKanbanCsrf)#</cfoutput>"
    data-schema-ready="<cfoutput>#VARIABLES.trelloKanbanSchemaReady ? 'true' : 'false'#</cfoutput>"
    data-configured="<cfoutput>#VARIABLES.trelloKanbanConfigured ? 'true' : 'false'#</cfoutput>"
>
    <header class="trello-kanban-header mb-3">
        <div>
            <div class="trello-kanban-kicker">Operação RunnerHub</div>
            <h1 class="business-page-title mb-1">Kanban dos departamentos</h1>
            <p class="text-muted mb-0">Gerencie os quadros autorizados do Trello sem sair do Business.</p>
        </div>
        <div class="business-page-actions">
            <select class="form-select trello-kanban-board-select" data-kanban-board-select aria-label="Selecionar departamento">
                <option value="">Carregando quadros…</option>
            </select>
            <button class="btn btn-outline-light" type="button" data-kanban-refresh title="Atualizar quadro">
                <i class="fa-solid fa-arrows-rotate me-2"></i>Atualizar
            </button>
            <button class="btn btn-outline-light" type="button" data-kanban-add-list>
                <i class="fa-solid fa-table-columns me-2"></i>Nova lista
            </button>
            <button class="btn btn-warning" type="button" data-kanban-settings>
                <i class="fa-solid fa-gear me-2"></i>Quadros
            </button>
        </div>
    </header>

    <cfif NOT VARIABLES.trelloKanbanSchemaReady>
        <div class="alert alert-warning" role="alert">
            <strong>Banco ainda não preparado.</strong>
            Execute <code>administracao/kanban/kanban_schema.sql</code> antes de abrir os quadros.
        </div>
    <cfelseif NOT VARIABLES.trelloKanbanConfigured>
        <div class="alert alert-warning" role="alert">
            <strong>Credencial do Trello ausente.</strong>
            Configure <code>RR_TRELLO_API_KEY</code> e <code>RR_TRELLO_API_TOKEN</code> no servidor e reinicie a aplicação.
        </div>
    </cfif>

    <div class="trello-kanban-status text-muted" data-kanban-status aria-live="polite">Preparando o painel…</div>
    <div class="trello-kanban-board" data-kanban-board aria-busy="true"></div>

    <dialog class="trello-kanban-dialog" data-kanban-card-dialog aria-labelledby="trelloKanbanCardTitle">
        <form method="dialog" class="trello-kanban-dialog-shell" data-kanban-card-form>
            <header class="trello-kanban-dialog-header">
                <div>
                    <div class="trello-kanban-kicker">Cartão do Trello</div>
                    <h2 class="h5 mb-0" id="trelloKanbanCardTitle" data-kanban-card-dialog-title>Novo cartão</h2>
                </div>
                <button class="btn btn-sm btn-outline-light" type="button" data-kanban-dialog-close aria-label="Fechar">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </header>
            <div class="trello-kanban-dialog-body">
                <input type="hidden" data-kanban-card-id/>
                <div class="mb-3">
                    <label class="form-label" for="trelloKanbanCardName">Título</label>
                    <input class="form-control" id="trelloKanbanCardName" maxlength="512" required data-kanban-card-name/>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="trelloKanbanCardDescription">Descrição</label>
                    <textarea class="form-control" id="trelloKanbanCardDescription" rows="6" maxlength="10000" data-kanban-card-description></textarea>
                </div>
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label" for="trelloKanbanCardList">Lista</label>
                        <select class="form-select" id="trelloKanbanCardList" required data-kanban-card-list></select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label" for="trelloKanbanCardDue">Prazo</label>
                        <input class="form-control" id="trelloKanbanCardDue" type="datetime-local" data-kanban-card-due/>
                    </div>
                    <div class="col-12">
                        <div class="form-check">
                            <input class="form-check-input" id="trelloKanbanCardDueComplete" type="checkbox" data-kanban-card-due-complete/>
                            <label class="form-check-label" for="trelloKanbanCardDueComplete">Prazo concluído</label>
                        </div>
                    </div>
                </div>
                <fieldset class="trello-kanban-members mt-3">
                    <legend class="form-label mb-2">Responsáveis</legend>
                    <div class="trello-kanban-member-grid" data-kanban-card-members></div>
                </fieldset>

                <section class="trello-kanban-comments mt-4 d-none" data-kanban-comments-section>
                    <h3 class="h6">Comentários</h3>
                    <div class="trello-kanban-comment-list" data-kanban-comments></div>
                    <div class="input-group mt-2">
                        <textarea class="form-control" rows="2" maxlength="10000" placeholder="Escreva um comentário" data-kanban-comment-text></textarea>
                        <button class="btn btn-outline-warning" type="button" data-kanban-comment-submit>Publicar</button>
                    </div>
                </section>
            </div>
            <footer class="trello-kanban-dialog-footer">
                <button class="btn btn-outline-danger me-auto d-none" type="button" data-kanban-card-archive>
                    <i class="fa-solid fa-box-archive me-2"></i>Arquivar
                </button>
                <a class="btn btn-outline-light d-none" target="_blank" rel="noopener noreferrer" data-kanban-card-open>
                    <i class="fa-brands fa-trello me-2"></i>Abrir no Trello
                </a>
                <button class="btn btn-warning" type="submit" data-kanban-card-save>
                    <i class="fa-solid fa-floppy-disk me-2"></i>Salvar
                </button>
            </footer>
        </form>
    </dialog>

    <dialog class="trello-kanban-dialog trello-kanban-settings-dialog" data-kanban-settings-dialog aria-labelledby="trelloKanbanSettingsTitle">
        <div class="trello-kanban-dialog-shell">
            <header class="trello-kanban-dialog-header">
                <div>
                    <div class="trello-kanban-kicker">Configuração</div>
                    <h2 class="h5 mb-0" id="trelloKanbanSettingsTitle">Quadros dos departamentos</h2>
                </div>
                <button class="btn btn-sm btn-outline-light" type="button" data-kanban-settings-close aria-label="Fechar">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </header>
            <div class="trello-kanban-dialog-body">
                <p class="text-muted small">Somente quadros vinculados aqui podem ser acessados pela API do Business. Remover um vínculo não arquiva o quadro no Trello.</p>
                <div class="trello-kanban-settings-list" data-kanban-settings-list></div>
            </div>
        </div>
    </dialog>

    <div class="trello-kanban-toast" role="status" aria-live="polite" data-kanban-toast></div>
</div>
