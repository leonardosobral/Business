<section class="research-admin-mvp py-4 py-lg-5" id="researchAdminMvp">
    <div class="research-admin-hero p-4 mb-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-center gap-3">
            <div>
                <div class="research-admin-kicker mb-2">Administração · Produto</div>
                <div class="d-flex flex-wrap align-items-center gap-2 mb-2">
                    <h1 class="h3 mb-0">Pesquisas</h1>
                    <span class="badge rounded-pill research-admin-draft-badge"><i class="fa-solid fa-circle me-1"></i>Rascunho local</span>
                </div>
                <p class="research-admin-muted mb-0">Monte e valide a pesquisa com sua equipe antes de criar banco, publicação e coleta de respostas.</p>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <button class="btn btn-outline-light" type="button" data-research-reset>
                    <i class="fa-solid fa-rotate-left me-2"></i>Restaurar demonstração
                </button>
                <button class="btn btn-outline-warning" type="button" data-research-save>
                    <i class="fa-solid fa-floppy-disk me-2"></i>Salvar rascunho
                </button>
                <button class="btn btn-warning" type="button" data-research-preview-open>
                    <i class="fa-solid fa-play me-2"></i>Visualizar pesquisa
                </button>
            </div>
        </div>
    </div>

    <div class="research-admin-notice mb-4">
        <i class="fa-solid fa-flask mt-1"></i>
        <div><strong>MVP somente de frontend</strong><span>As alterações ficam salvas apenas neste navegador. O preview não registra respostas nem publica conteúdo no Road Runners.</span></div>
    </div>

    <nav class="nav research-admin-tabs mb-4" aria-label="Seções do editor">
        <button class="nav-link active" type="button" data-research-tab="editor"><i class="fa-solid fa-pen-ruler me-2"></i>Editor</button>
        <button class="nav-link" type="button" data-research-tab="audience"><i class="fa-solid fa-bullseye me-2"></i>Público e publicação</button>
    </nav>

    <div data-research-view="editor">
        <div class="research-admin-grid">
            <aside class="research-admin-panel research-admin-steps-panel">
                <div class="research-admin-panel-heading">
                    <div><h2 class="h6 mb-1">Etapas da pesquisa</h2><span class="research-admin-muted small" data-research-item-count></span></div>
                    <button class="btn btn-sm btn-link text-light px-2" type="button" title="Mais opções"><i class="fa-solid fa-ellipsis"></i></button>
                </div>
                <div class="research-admin-step-list" data-research-item-list></div>
                <button class="research-admin-add-block" type="button" data-research-add-block>
                    <i class="fa-solid fa-plus me-2"></i>Adicionar funcionalidade
                </button>
            </aside>

            <div class="research-admin-panel research-admin-editor-panel">
                <div class="research-admin-panel-heading">
                    <div><h2 class="h6 mb-1">Editar funcionalidade</h2><span class="research-admin-muted small">As mudanças aparecem imediatamente no preview.</span></div>
                    <button class="btn btn-sm btn-outline-light" type="button" data-research-duplicate><i class="fa-regular fa-copy me-2"></i>Duplicar</button>
                </div>

                <div class="research-admin-form p-3 p-lg-4">
                    <div class="row g-3">
                        <div class="col-12 col-lg-4">
                            <label class="form-label" for="researchArea">Área</label>
                            <select class="form-select" id="researchArea" data-research-field="area">
                                <option>Descoberta</option>
                                <option>Performance</option>
                                <option>Comunidade</option>
                                <option>Histórico conectado</option>
                                <option>Experiência</option>
                            </select>
                        </div>
                        <div class="col-12 col-lg-8">
                            <label class="form-label" for="researchFeatureName">Nome curto da funcionalidade</label>
                            <input class="form-control" id="researchFeatureName" maxlength="100" data-research-field="name"/>
                            <div class="form-text">Deve permitir que o atleta entenda a funcionalidade rapidamente.</div>
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="researchFeatureTitle">Título apresentado ao atleta</label>
                            <input class="form-control" id="researchFeatureTitle" maxlength="180" data-research-field="title"/>
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="researchFeatureExplanation">O que é a funcionalidade</label>
                            <textarea class="form-control" id="researchFeatureExplanation" rows="3" maxlength="600" data-research-field="explanation"></textarea>
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="researchFeatureSolution">O que ela resolve para o atleta</label>
                            <textarea class="form-control" id="researchFeatureSolution" rows="2" maxlength="400" data-research-field="solution"></textarea>
                        </div>
                    </div>

                    <div class="research-admin-visual-editor mt-4">
                        <div class="d-flex flex-column flex-md-row justify-content-between gap-2 mb-3">
                            <div><h3 class="h6 mb-1">Visual da funcionalidade</h3><p class="small research-admin-muted mb-0">Neste MVP, o preview utiliza uma ilustração de interface própria.</p></div>
                            <div class="d-flex flex-wrap gap-2" role="group" aria-label="Tipo de visual">
                                <button class="btn btn-sm btn-warning" type="button" data-research-media="interface"><i class="fa-solid fa-window-maximize me-2"></i>Interface</button>
                                <button class="btn btn-sm btn-outline-light" type="button" data-research-media="video"><i class="fa-solid fa-circle-play me-2"></i>Vídeo futuro</button>
                                <button class="btn btn-sm btn-outline-light" type="button" data-research-media="none">Somente texto</button>
                            </div>
                        </div>
                        <div class="research-admin-visual-placeholder" data-research-visual-placeholder>
                            <div class="research-admin-placeholder-window">
                                <span></span><span></span><span></span>
                            </div>
                            <div class="research-admin-placeholder-content">
                                <i class="fa-solid fa-wand-magic-sparkles"></i>
                                <strong>Ilustração de interface</strong>
                                <span>O visual será gerado conforme o tipo da funcionalidade.</span>
                            </div>
                        </div>
                    </div>

                    <div class="research-admin-option-row mt-4">
                        <div><strong>Exibir na montagem do pacote</strong><span>Permite selecionar esta funcionalidade na etapa final.</span></div>
                        <button type="button" class="research-admin-switch is-on" aria-pressed="true" data-research-switch="package"><span></span></button>
                    </div>
                    <div class="research-admin-option-row">
                        <div><strong>Alternar posição entre participantes</strong><span>Ajuda a reduzir viés de ordem e cansaço.</span></div>
                        <button type="button" class="research-admin-switch is-on" aria-pressed="true" data-research-switch="random"><span></span></button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="d-none" data-research-view="audience">
        <div class="research-admin-panel">
            <div class="research-admin-panel-heading">
                <div><h2 class="h6 mb-1">Configuração da pesquisa</h2><span class="research-admin-muted small">Estrutura pronta para outros stakeholders e públicos de eventos específicos.</span></div>
            </div>
            <div class="p-3 p-lg-4">
                <div class="row g-3">
                    <div class="col-12 col-lg-6">
                        <label class="form-label" for="researchInternalName">Nome interno</label>
                        <input class="form-control" id="researchInternalName" value="Assinatura para atletas 2026" data-research-config="internalName"/>
                    </div>
                    <div class="col-12 col-lg-6">
                        <label class="form-label" for="researchPublicTitle">Título público</label>
                        <input class="form-control" id="researchPublicTitle" value="O próximo Road Runners será construído com quem corre" data-research-config="publicTitle"/>
                    </div>
                    <div class="col-12 col-lg-4">
                        <label class="form-label" for="researchStakeholder">Stakeholder principal</label>
                        <select class="form-select" id="researchStakeholder" data-research-config="stakeholder">
                            <option value="atleta">Atletas / corredores</option>
                            <option value="organizador">Organizadores</option>
                            <option value="cronometrador">Cronometradores</option>
                            <option value="assessoria">Assessorias esportivas</option>
                            <option value="marca">Marcas e patrocinadores</option>
                        </select>
                    </div>
                    <div class="col-12 col-lg-4">
                        <label class="form-label" for="researchScope">Escopo do público</label>
                        <select class="form-select" id="researchScope" data-research-config="scope">
                            <option value="general">Público geral</option>
                            <option value="event">Pessoas relacionadas a um evento</option>
                        </select>
                    </div>
                    <div class="col-12 col-lg-4">
                        <label class="form-label" for="researchSlug">Slug futuro</label>
                        <div class="input-group"><span class="input-group-text">/mkt/pesquisa/</span><input class="form-control" id="researchSlug" value="assinatura-atletas-2026" data-research-config="slug"/></div>
                    </div>
                </div>

                <div class="research-admin-event-box mt-4 d-none" data-research-event-settings>
                    <div class="d-flex gap-3 mb-3"><i class="fa-solid fa-flag-checkered text-warning mt-1"></i><div><strong>Segmentação por evento</strong><p class="small research-admin-muted mb-0">A futura publicação poderá ser direcionada a quem participou, demonstrou interesse ou concluiu uma distância específica.</p></div></div>
                    <div class="row g-3">
                        <div class="col-12 col-lg-6"><label class="form-label" for="researchEvent">Evento</label><select class="form-select" id="researchEvent"><option>Maratona Internacional de Florianópolis 2026</option><option>Meia Maratona de Balneário Camboriú</option><option>Treinão Road Runners</option></select></div>
                        <div class="col-12 col-lg-3"><label class="form-label" for="researchRelation">Relação</label><select class="form-select" id="researchRelation"><option>Participou / concluiu</option><option>Marcou “Eu vou”</option><option>Marcou “Quero ir”</option><option>Qualquer relação</option></select></div>
                        <div class="col-12 col-lg-3"><label class="form-label" for="researchDistance">Distância</label><select class="form-select" id="researchDistance"><option>Todas</option><option>5 km</option><option>10 km</option><option>21 km</option><option>42 km</option></select></div>
                    </div>
                </div>

                <div class="research-admin-option-row mt-4">
                    <div><strong>Randomizar funcionalidades</strong><span>Introdução, identificação e etapa final continuam fixas.</span></div>
                    <button type="button" class="research-admin-switch is-on" aria-pressed="true" data-research-switch="globalRandom"><span></span></button>
                </div>
                <div class="research-admin-option-row">
                    <div><strong>Exigir conta Road Runners</strong><span>Desativado para permitir pesquisa presencial por QR Code no evento.</span></div>
                    <button type="button" class="research-admin-switch" aria-pressed="false" data-research-switch="requireAccount"><span></span></button>
                </div>
            </div>
        </div>
    </div>

    <div class="research-admin-toast" role="status" data-research-toast></div>

    <div class="research-preview-overlay" data-research-preview hidden>
        <div class="research-preview-toolbar">
            <div class="d-flex align-items-center gap-2">
                <button type="button" class="btn btn-outline-light" data-research-preview-close><i class="fa-solid fa-arrow-left me-2"></i>Voltar ao editor</button>
                <span class="badge badge-warning d-none d-md-inline-flex">Modo de visualização · respostas não serão salvas</span>
            </div>
            <div class="d-flex flex-wrap align-items-center gap-2">
                <button type="button" class="btn btn-sm btn-warning" data-research-device="desktop"><i class="fa-solid fa-desktop me-2"></i>Desktop</button>
                <button type="button" class="btn btn-sm btn-outline-light" data-research-device="mobile"><i class="fa-solid fa-mobile-screen me-2"></i>Celular</button>
                <button type="button" class="btn btn-sm btn-outline-light" data-research-shuffle><i class="fa-solid fa-shuffle me-2"></i>Nova ordem</button>
            </div>
        </div>

        <div class="research-preview-workspace">
            <div class="research-survey-frame" data-research-preview-frame>
                <header class="research-survey-header">
                    <span class="research-survey-logo">RR</span>
                    <div class="research-survey-progress"><span data-research-preview-progress></span></div>
                    <small data-research-preview-counter></small>
                </header>
                <div class="research-survey-content" data-research-preview-content></div>
                <footer class="research-survey-navigation">
                    <button type="button" class="btn btn-link text-secondary" data-research-preview-back><i class="fa-solid fa-arrow-left me-2"></i>Voltar</button>
                    <button type="button" class="btn btn-warning" data-research-preview-next>Continuar<i class="fa-solid fa-arrow-right ms-2"></i></button>
                </footer>
            </div>
        </div>
    </div>

    <div class="research-admin-dialog" data-research-add-dialog hidden>
        <div class="research-admin-dialog-panel">
            <div class="d-flex justify-content-between align-items-start gap-3 mb-3"><div><h2 class="h5 mb-1">Adicionar funcionalidade</h2><p class="small research-admin-muted mb-0">Crie um bloco livre e refine o conteúdo no editor.</p></div><button type="button" class="btn-close btn-close-white" aria-label="Fechar" data-research-add-close></button></div>
            <label class="form-label" for="researchNewFeatureName">Nome da funcionalidade</label>
            <input class="form-control mb-3" id="researchNewFeatureName" placeholder="Ex.: Memórias de Corrida" maxlength="100"/>
            <div class="d-flex justify-content-end gap-2"><button type="button" class="btn btn-outline-light" data-research-add-close>Cancelar</button><button type="button" class="btn btn-warning" data-research-add-confirm>Adicionar ao final</button></div>
        </div>
    </div>
</section>
