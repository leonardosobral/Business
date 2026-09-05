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
            <button class="btn btn-outline-light" type="button" data-kanban-archived>
                <i class="fa-solid fa-box-archive me-2"></i>Arquivados
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

    <dialog class="trello-kanban-dialog trello-kanban-card-dialog" data-kanban-card-dialog aria-labelledby="trelloKanbanCardTitle">
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
            <nav class="trello-kanban-tabs" aria-label="Opções do cartão" data-kanban-card-tabs>
                <button class="is-active" type="button" data-kanban-tab="details"><i class="fa-solid fa-pen-to-square"></i>Detalhes</button>
                <button type="button" data-kanban-tab="checklists"><i class="fa-solid fa-list-check"></i>Checklists</button>
                <button type="button" data-kanban-tab="attachments"><i class="fa-solid fa-paperclip"></i>Anexos</button>
                <button type="button" data-kanban-tab="activity"><i class="fa-regular fa-comment"></i>Atividade</button>
                <button type="button" data-kanban-tab="custom-fields"><i class="fa-solid fa-table-list"></i>Campos</button>
                <button type="button" data-kanban-tab="advanced"><i class="fa-solid fa-ellipsis"></i>Mais</button>
            </nav>
            <div class="trello-kanban-dialog-body">
                <input type="hidden" data-kanban-card-id/>

                <section data-kanban-panel="details">
                    <div class="mb-3">
                        <label class="form-label" for="trelloKanbanCardName">Título</label>
                        <input class="form-control" id="trelloKanbanCardName" maxlength="512" required data-kanban-card-name/>
                    </div>
                    <div class="mb-3">
                        <label class="form-label" for="trelloKanbanCardDescription">Descrição</label>
                        <textarea class="form-control" id="trelloKanbanCardDescription" rows="6" maxlength="10000" data-kanban-card-description></textarea>
                    </div>
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label" for="trelloKanbanCardList">Lista</label>
                            <select class="form-select" id="trelloKanbanCardList" required data-kanban-card-list></select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="trelloKanbanCardStart">Início</label>
                            <input class="form-control" id="trelloKanbanCardStart" type="datetime-local" data-kanban-card-start/>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="trelloKanbanCardDue">Prazo</label>
                            <input class="form-control" id="trelloKanbanCardDue" type="datetime-local" data-kanban-card-due/>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label" for="trelloKanbanCardCover">Cor da capa</label>
                            <select class="form-select" id="trelloKanbanCardCover" data-kanban-card-cover>
                                <option value="none">Sem capa colorida</option>
                                <option value="attachment">Manter capa do anexo</option>
                                <option value="green">Verde</option><option value="yellow">Amarelo</option>
                                <option value="orange">Laranja</option><option value="red">Vermelho</option>
                                <option value="purple">Roxo</option><option value="blue">Azul</option>
                                <option value="sky">Azul-claro</option><option value="lime">Lima</option>
                                <option value="pink">Rosa</option><option value="black">Preto</option>
                            </select>
                        </div>
                        <div class="col-md-4 d-flex flex-column justify-content-end gap-2">
                            <div class="form-check">
                                <input class="form-check-input" id="trelloKanbanCardDueComplete" type="checkbox" data-kanban-card-due-complete/>
                                <label class="form-check-label" for="trelloKanbanCardDueComplete">Prazo concluído</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" id="trelloKanbanCardSubscribed" type="checkbox" data-kanban-card-subscribed/>
                                <label class="form-check-label" for="trelloKanbanCardSubscribed">Observar pela conta integrada</label>
                            </div>
                        </div>
                    </div>
                    <fieldset class="mt-4">
                        <legend class="form-label mb-2">Etiquetas</legend>
                        <div class="trello-kanban-choice-grid" data-kanban-card-labels></div>
                        <div class="trello-kanban-inline-form mt-2 d-none" data-kanban-label-create>
                            <input class="form-control" maxlength="128" placeholder="Nome da nova etiqueta" data-kanban-label-name/>
                            <select class="form-select" data-kanban-label-color><option value="green">Verde</option><option value="yellow">Amarelo</option><option value="orange">Laranja</option><option value="red">Vermelho</option><option value="purple">Roxo</option><option value="blue">Azul</option><option value="sky">Azul-claro</option><option value="lime">Lima</option><option value="pink">Rosa</option><option value="black">Preto</option></select>
                            <button class="btn btn-outline-warning" type="button" data-kanban-label-submit>Criar e aplicar</button>
                        </div>
                    </fieldset>
                    <fieldset class="trello-kanban-members mt-4">
                        <legend class="form-label mb-2">Responsáveis</legend>
                        <div class="trello-kanban-choice-grid" data-kanban-card-members></div>
                    </fieldset>
                    <fieldset class="mt-4">
                        <legend class="form-label mb-2">Localização</legend>
                        <div class="row g-3">
                            <div class="col-md-6"><input class="form-control" maxlength="256" placeholder="Nome do local" aria-label="Nome do local" data-kanban-card-location-name/></div>
                            <div class="col-md-6"><input class="form-control" maxlength="512" placeholder="Endereço" aria-label="Endereço" data-kanban-card-address/></div>
                            <div class="col-md-6"><input class="form-control" type="number" min="-90" max="90" step="any" placeholder="Latitude" aria-label="Latitude" data-kanban-card-latitude/></div>
                            <div class="col-md-6"><input class="form-control" type="number" min="-180" max="180" step="any" placeholder="Longitude" aria-label="Longitude" data-kanban-card-longitude/></div>
                        </div>
                    </fieldset>
                </section>

                <section class="d-none" data-kanban-panel="checklists">
                    <div class="trello-kanban-section-heading"><div><h3 class="h6 mb-1">Checklists</h3><p class="small text-muted mb-0">Itens, prazos, lembretes e responsáveis.</p></div><button class="btn btn-sm btn-outline-warning" type="button" data-kanban-checklist-create><i class="fa-solid fa-plus me-1"></i>Novo checklist</button></div>
                    <div data-kanban-checklists></div>
                </section>

                <section class="d-none" data-kanban-panel="attachments">
                    <h3 class="h6">Anexos</h3>
                    <div class="trello-kanban-attachment-add">
                        <div class="trello-kanban-subpanel"><strong>Adicionar por link</strong><div class="row g-2 mt-1"><div class="col-md-4"><input class="form-control" maxlength="256" placeholder="Nome (opcional)" data-kanban-attachment-name/></div><div class="col-md-8"><input class="form-control" type="url" maxlength="2000" placeholder="https://…" data-kanban-attachment-url/></div></div><div class="form-check mt-2"><input class="form-check-input" type="checkbox" id="trelloKanbanUrlCover" data-kanban-attachment-url-cover/><label class="form-check-label" for="trelloKanbanUrlCover">Usar como capa</label></div><button class="btn btn-sm btn-outline-warning mt-2" type="button" data-kanban-attachment-url-submit>Anexar link</button></div>
                        <div class="trello-kanban-subpanel"><strong>Enviar arquivo</strong><input class="form-control mt-2" type="file" data-kanban-attachment-file/><div class="small text-muted mt-1">Até 10 MB. Arquivos executáveis e scripts são bloqueados.</div><div class="form-check mt-2"><input class="form-check-input" type="checkbox" id="trelloKanbanFileCover" data-kanban-attachment-file-cover/><label class="form-check-label" for="trelloKanbanFileCover">Usar como capa</label></div><button class="btn btn-sm btn-outline-warning mt-2" type="button" data-kanban-attachment-file-submit>Enviar arquivo</button></div>
                    </div>
                    <div class="trello-kanban-attachment-list mt-3" data-kanban-attachments></div>
                </section>

                <section class="d-none" data-kanban-panel="activity">
                    <h3 class="h6">Comentários e atividade</h3>
                    <div class="input-group mb-3"><textarea class="form-control" rows="2" maxlength="10000" placeholder="Escreva um comentário" data-kanban-comment-text></textarea><button class="btn btn-outline-warning" type="button" data-kanban-comment-submit>Publicar</button></div>
                    <div class="trello-kanban-comment-list" data-kanban-activity></div>
                </section>

                <section class="d-none" data-kanban-panel="custom-fields">
                    <div class="trello-kanban-section-heading"><div><h3 class="h6 mb-1">Campos personalizados</h3><p class="small text-muted mb-0">Disponíveis quando o Power-Up de Campos Personalizados está ativo no quadro.</p></div></div>
                    <div class="trello-kanban-custom-fields" data-kanban-custom-fields></div>
                </section>

                <section class="d-none" data-kanban-panel="advanced">
                    <h3 class="h6">Ações avançadas</h3>
                    <div class="trello-kanban-subpanel mb-3"><strong>Duplicar cartão</strong><div class="row g-2 mt-1"><div class="col-md-7"><input class="form-control" maxlength="512" placeholder="Título da cópia" data-kanban-duplicate-name/></div><div class="col-md-5"><select class="form-select" data-kanban-duplicate-list></select></div></div><button class="btn btn-sm btn-outline-warning mt-2" type="button" data-kanban-card-duplicate>Duplicar com todo o conteúdo</button></div>
                    <div class="trello-kanban-subpanel mb-3"><strong>Mover para outro departamento</strong><div class="row g-2 mt-1"><div class="col-md-6"><select class="form-select" aria-label="Quadro de destino" data-kanban-transfer-board></select></div><div class="col-md-6"><select class="form-select" aria-label="Lista de destino" data-kanban-transfer-list></select></div></div><button class="btn btn-sm btn-outline-warning mt-2" type="button" data-kanban-card-transfer>Mover cartão</button></div>
                    <div class="trello-kanban-danger-zone"><strong>Zona de risco</strong><p class="small text-muted mb-2">Arquivar é reversível pela lista de arquivados. Excluir apaga o cartão permanentemente no Trello.</p><div class="d-flex flex-wrap gap-2"><button class="btn btn-outline-danger" type="button" data-kanban-card-archive><i class="fa-solid fa-box-archive me-2"></i>Arquivar</button><button class="btn btn-danger" type="button" data-kanban-card-delete><i class="fa-solid fa-trash me-2"></i>Excluir permanentemente</button></div></div>
                </section>
            </div>
            <footer class="trello-kanban-dialog-footer">
                <span class="small text-muted me-auto" data-kanban-card-save-hint></span>
                <a class="btn btn-outline-light d-none" target="_blank" rel="noopener noreferrer" data-kanban-card-open>
                    <i class="fa-brands fa-trello me-2"></i>Abrir no Trello
                </a>
                <a class="btn btn-outline-light d-none" target="_blank" rel="noopener noreferrer" data-kanban-card-agenda><i class="fa-regular fa-calendar me-2"></i>Agendar</a>
                <button class="btn btn-warning" type="submit" data-kanban-card-save>
                    <i class="fa-solid fa-floppy-disk me-2"></i>Salvar
                </button>
            </footer>
        </form>
    </dialog>

    <dialog class="trello-kanban-dialog" data-kanban-archived-dialog aria-labelledby="trelloKanbanArchivedTitle">
        <div class="trello-kanban-dialog-shell">
            <header class="trello-kanban-dialog-header"><div><div class="trello-kanban-kicker">Trello</div><h2 class="h5 mb-0" id="trelloKanbanArchivedTitle">Cartões arquivados</h2></div><button class="btn btn-sm btn-outline-light" type="button" data-kanban-archived-close aria-label="Fechar"><i class="fa-solid fa-xmark"></i></button></header>
            <div class="trello-kanban-dialog-body"><div data-kanban-archived-list></div></div>
        </div>
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
