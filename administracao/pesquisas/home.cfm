<section class="research-admin-mvp py-4 py-lg-5" id="researchAdminMvp" data-research-api="/administracao/pesquisas/api.cfm">
    <div class="research-admin-hero p-4 mb-4">
        <div class="d-flex flex-column flex-xl-row justify-content-between align-items-xl-center gap-3">
            <div>
                <div class="research-admin-kicker mb-2">Administração · Entrevista de produto</div>
                <div class="d-flex flex-wrap align-items-center gap-2 mb-2">
                    <h1 class="h3 mb-0">Entrevista de atletas</h1>
                    <span class="badge rounded-pill research-admin-draft-badge" data-research-status-badge>
                        <i class="fa-solid fa-database me-1"></i>Verificando banco
                    </span>
                </div>
                <p class="research-admin-muted mb-0">Edite a entrevista, valide a experiência e acompanhe as respostas dos corredores.</p>
            </div>
            <div class="d-flex flex-wrap gap-2">
                <a class="btn btn-outline-light" href="/pesquisa/" target="_blank" rel="noopener" data-research-public-link>
                    <i class="fa-solid fa-arrow-up-right-from-square me-2"></i>Abrir pesquisa
                </a>
                <button class="btn btn-success d-none" type="button" data-research-publish>
                    <i class="fa-solid fa-paper-plane me-2"></i>Publicar
                </button>
                <button class="btn btn-outline-warning d-none" type="button" data-research-unpublish>
                    <i class="fa-solid fa-eye-slash me-2"></i>Despublicar
                </button>
                <button class="btn btn-outline-danger d-none" type="button" data-research-close>
                    <i class="fa-solid fa-circle-stop me-2"></i>Encerrar coleta
                </button>
                <button class="btn btn-outline-warning" type="button" data-research-save>
                    <i class="fa-solid fa-floppy-disk me-2"></i>Salvar no banco
                </button>
                <button class="btn btn-warning" type="button" data-research-preview-open>
                    <i class="fa-solid fa-play me-2"></i>Visualizar pesquisa
                </button>
            </div>
        </div>
    </div>

    <div class="research-admin-notice mb-4" data-research-schema-notice>
        <i class="fa-solid fa-circle-notch fa-spin mt-1"></i>
        <div><strong>Carregando entrevista</strong><span>Consultando configuração e respostas salvas.</span></div>
    </div>

    <nav class="nav research-admin-tabs mb-4" aria-label="Seções do gerenciador">
        <button class="nav-link active" type="button" data-research-tab="editor"><i class="fa-solid fa-pen-ruler me-2"></i>Editor</button>
        <button class="nav-link" type="button" data-research-tab="audience"><i class="fa-solid fa-bullseye me-2"></i>Público e publicação</button>
        <button class="nav-link" type="button" data-research-tab="dashboard"><i class="fa-solid fa-chart-column me-2"></i>Respostas</button>
    </nav>

    <div data-research-view="editor">
        <div class="research-admin-grid">
            <aside class="research-admin-panel research-admin-steps-panel">
                <div class="research-admin-panel-heading">
                    <div><h2 class="h6 mb-1">Etapas da entrevista</h2><span class="research-admin-muted small" data-research-item-count></span></div>
                </div>
                <div class="research-admin-step-list" data-research-item-list></div>
                <button class="research-admin-add-block" type="button" data-research-add-block>
                    <i class="fa-solid fa-plus me-2"></i>Adicionar funcionalidade
                </button>
            </aside>

            <div class="research-admin-panel research-admin-editor-panel">
                <div class="research-admin-panel-heading">
                    <div>
                        <h2 class="h6 mb-1" data-research-editor-title>Editar etapa</h2>
                        <span class="research-admin-muted small">Todas as etapas podem ser ajustadas. O preview é atualizado imediatamente.</span>
                    </div>
                    <div class="d-flex flex-wrap gap-2">
                        <button class="btn btn-sm btn-outline-light" type="button" data-research-duplicate>
                            <i class="fa-regular fa-copy me-2"></i>Duplicar funcionalidade
                        </button>
                        <button class="btn btn-sm btn-outline-danger" type="button" data-research-delete>
                            <i class="fa-regular fa-trash-can me-2"></i>Excluir funcionalidade
                        </button>
                    </div>
                </div>

                <div class="research-admin-form p-3 p-lg-4">
                    <div class="row g-3">
                        <div class="col-12 col-lg-4" data-research-feature-field>
                            <label class="form-label" for="researchArea">Área</label>
                            <select class="form-select" id="researchArea" data-research-field="area">
                                <option>Descoberta</option>
                                <option>Performance</option>
                                <option>Comunidade</option>
                                <option>Histórico conectado</option>
                                <option>Experiência</option>
                            </select>
                        </div>
                        <div class="col-12 col-lg-8" data-research-name-column>
                            <label class="form-label" for="researchStepName" data-research-name-label>Nome da etapa</label>
                            <input class="form-control" id="researchStepName" maxlength="100" data-research-field="name"/>
                            <div class="form-text" data-research-name-help>Usado na lista do editor.</div>
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="researchStepTitle">Título apresentado ao atleta</label>
                            <input class="form-control" id="researchStepTitle" maxlength="180" data-research-field="title"/>
                        </div>
                        <div class="col-12">
                            <label class="form-label" for="researchStepSupport" data-research-support-label>Texto de apoio</label>
                            <textarea class="form-control" id="researchStepSupport" rows="2" maxlength="500" data-research-field="support"></textarea>
                            <div class="form-text" data-research-support-help>Explique por que a pergunta é importante.</div>
                        </div>
                        <div class="col-12" data-research-question-field>
                            <label class="form-label" for="researchStepQuestion">Pergunta</label>
                            <input class="form-control" id="researchStepQuestion" maxlength="240" data-research-field="question"/>
                        </div>
                    </div>

                    <div class="research-admin-visual-editor mt-4" data-research-feature-field>
                        <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                            <div>
                                <h3 class="h6 mb-1">Visual da funcionalidade</h3>
                                <p class="small research-admin-muted mb-0">Use uma ilustração do protótipo ou envie uma imagem pronta.</p>
                            </div>
                            <div class="d-flex flex-wrap gap-2" role="group" aria-label="Tipo de visual">
                                <button class="btn btn-sm btn-warning" type="button" data-research-media="illustration"><i class="fa-solid fa-wand-magic-sparkles me-2"></i>Ilustração</button>
                                <label class="btn btn-sm btn-outline-light mb-0" for="researchFeatureImage"><i class="fa-solid fa-upload me-2"></i>Enviar imagem</label>
                                <input class="visually-hidden" id="researchFeatureImage" type="file" accept="image/jpeg,image/png,image/webp" data-research-image-upload/>
                            </div>
                        </div>
                        <div class="research-admin-visual-placeholder" data-research-visual-placeholder></div>
                        <div class="small research-admin-muted mt-2" data-research-upload-status></div>
                    </div>

                    <div data-research-feature-field>
                        <div class="research-admin-option-row mt-4">
                            <div><strong>Disponível para o pacote</strong><span>O atleta poderá incluir esta funcionalidade na assinatura ideal.</span></div>
                            <button type="button" class="research-admin-switch is-on" aria-pressed="true" data-research-switch="package"><span></span></button>
                        </div>
                        <div class="research-admin-option-row">
                            <div><strong>Pode ter a posição alternada</strong><span>Participa da randomização para reduzir viés de ordem.</span></div>
                            <button type="button" class="research-admin-switch is-on" aria-pressed="true" data-research-switch="random"><span></span></button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="d-none" data-research-view="audience">
        <div class="research-admin-panel">
            <div class="research-admin-panel-heading">
                <div><h2 class="h6 mb-1">Público e publicação</h2><span class="research-admin-muted small">Configuração exclusiva para a entrevista de atletas.</span></div>
            </div>
            <div class="p-3 p-lg-4">
                <div class="row g-3">
                    <div class="col-12 col-lg-6"><label class="form-label" for="researchInternalName">Nome interno</label><input class="form-control" id="researchInternalName" data-research-config="internalName"/></div>
                    <div class="col-12 col-lg-6"><label class="form-label" for="researchPublicTitle">Título público</label><input class="form-control" id="researchPublicTitle" data-research-config="publicTitle"/></div>
                    <div class="col-12 col-lg-4"><label class="form-label" for="researchStakeholder">Stakeholder principal</label><input class="form-control" id="researchStakeholder" value="Atletas / corredores" readonly/></div>
                    <div class="col-12 col-lg-4"><label class="form-label" for="researchScope">Escopo do público</label><input class="form-control" id="researchScope" value="Geral" readonly/></div>
                    <div class="col-12 col-lg-4"><label class="form-label" for="researchSlug">Slug futuro</label><div class="input-group"><span class="input-group-text">/pesquisa/</span><input class="form-control" id="researchSlug" data-research-config="slug"/></div></div>
                    <div class="col-12 col-lg-6">
                        <label class="form-label" for="researchEmailMode">Contato ao final</label>
                        <select class="form-select" id="researchEmailMode" data-research-config="emailMode"><option value="optional">Pedir e-mail, mas deixar opcional</option><option value="required">Exigir e-mail para concluir</option><option value="disabled">Não pedir e-mail</option></select>
                        <div class="form-text">Podemos alterar isto quando a decisão sobre login estiver fechada.</div>
                    </div>
                    <div class="col-12 col-lg-3"><label class="form-label" for="researchAnnualDiscount">Desconto no plano anual</label><div class="input-group"><input class="form-control" id="researchAnnualDiscount" min="0" max="50" type="number" data-research-config="annualDiscount"/><span class="input-group-text">%</span></div></div>
                    <div class="col-12 col-lg-3"><label class="form-label" for="researchRedirectUrl">Redirecionar após concluir</label><input class="form-control" id="researchRedirectUrl" placeholder="Vazio mantém a mensagem" data-research-config="redirectUrl"/></div>
                </div>

                <div class="research-admin-option-row mt-4">
                    <div><strong>Randomizar funcionalidades</strong><span>As etapas de perfil, pacote e conclusão continuam em suas posições.</span></div>
                    <button type="button" class="research-admin-switch is-on" aria-pressed="true" data-research-switch="globalRandom"><span></span></button>
                </div>
                <div class="research-admin-option-row">
                    <div><strong>Exigir conta Road Runners</strong><span>Deixe desativado enquanto a equipe define o login. Ao ativar, a publicação informará que a integração segura ainda precisa ser concluída.</span></div>
                    <button type="button" class="research-admin-switch" aria-pressed="false" data-research-switch="requireAccount"><span></span></button>
                </div>
            </div>
        </div>
    </div>

    <div class="d-none" data-research-view="dashboard">
        <div class="research-dashboard-empty d-none" data-research-dashboard-empty><i class="fa-solid fa-chart-simple"></i><h2 class="h5">Ainda não há entrevistas concluídas</h2><p>Assim que a pesquisa receber respostas, os indicadores aparecerão aqui.</p></div>
        <div data-research-dashboard-content>
            <div class="research-dashboard-filters mb-3">
                <div><strong>Filtrar respostas</strong><span>Os indicadores e a lista abaixo acompanham os filtros.</span></div>
                <label><span>Nível do corredor</span><select class="form-select form-select-sm" data-research-dashboard-filter="level"><option value="">Todos os níveis</option><option value="beginner">Estou começando</option><option value="recreational">Recreativo</option><option value="dedicated">Amador dedicado</option><option value="competitive">Competitivo</option></select></label>
                <label><span>Conta Road Runners</span><select class="form-select form-select-sm" data-research-dashboard-filter="account"><option value="">Todos</option><option value="active">Usa com frequência</option><option value="occasional">Tem conta, usa pouco</option><option value="none">Ainda não tem conta</option></select></label>
                <button class="btn btn-sm btn-outline-light" type="button" data-research-dashboard-clear><i class="fa-solid fa-filter-circle-xmark me-2"></i>Limpar</button>
            </div>
            <div class="research-dashboard-kpis" data-research-dashboard-kpis></div>
            <div class="research-dashboard-grid mt-3">
                <section class="research-admin-panel p-3 p-lg-4"><div class="mb-3"><h2 class="h6 mb-1">Interesse por funcionalidade</h2><span class="research-admin-muted small">Uso declarado, presença no pacote e item indispensável.</span></div><div data-research-feature-results></div></section>
                <section class="research-admin-panel p-3 p-lg-4"><h2 class="h6 mb-1">Perfil e preferência</h2><span class="research-admin-muted small">Quem respondeu e como prefere pagar.</span><div class="mt-3" data-research-profile-results></div></section>
            </div>
            <section class="research-admin-panel mt-3 p-3 p-lg-4">
                <div class="d-flex flex-column flex-md-row justify-content-between gap-2 mb-3"><div><h2 class="h6 mb-1">Entrevistas recentes</h2><span class="research-admin-muted small">Clique em uma resposta para ver as funcionalidades escolhidas.</span></div><button class="btn btn-sm btn-outline-light" type="button" data-research-dashboard-refresh><i class="fa-solid fa-rotate me-2"></i>Atualizar</button></div>
                <div class="table-responsive"><table class="table table-dark table-hover align-middle mb-0"><thead><tr><th>Data</th><th>Atleta</th><th>Nível</th><th>Pagamento</th><th>Valor informado</th><th>Pacote</th></tr></thead><tbody data-research-recent-results></tbody></table></div>
            </section>
        </div>
    </div>

    <div class="research-admin-toast" role="status" data-research-toast></div>

    <div class="research-preview-overlay" data-research-preview hidden>
        <div class="research-preview-toolbar">
            <div class="d-flex align-items-center gap-2"><button type="button" class="btn btn-outline-light" data-research-preview-close><i class="fa-solid fa-arrow-left me-2"></i>Voltar ao editor</button><span class="badge badge-warning d-none d-md-inline-flex">Preview · respostas não são registradas</span></div>
            <div class="d-flex flex-wrap align-items-center gap-2"><button type="button" class="btn btn-sm btn-warning" data-research-device="desktop"><i class="fa-solid fa-desktop me-2"></i>Desktop</button><button type="button" class="btn btn-sm btn-outline-light" data-research-device="mobile"><i class="fa-solid fa-mobile-screen me-2"></i>Celular</button><button type="button" class="btn btn-sm btn-outline-light" data-research-shuffle><i class="fa-solid fa-shuffle me-2"></i>Nova ordem</button></div>
        </div>
        <div class="research-preview-workspace"><div class="research-survey-frame" data-research-preview-frame><header class="research-survey-header"><span class="research-survey-logo">RR</span><div class="research-survey-progress"><span data-research-preview-progress></span></div><small data-research-preview-counter></small></header><div class="research-survey-content" data-research-preview-content></div><footer class="research-survey-navigation"><button type="button" class="btn btn-link text-secondary" data-research-preview-back><i class="fa-solid fa-arrow-left me-2"></i>Voltar</button></footer></div></div>
    </div>

    <div class="research-admin-dialog" data-research-add-dialog hidden>
        <div class="research-admin-dialog-panel">
            <div class="d-flex justify-content-between align-items-start gap-3 mb-3"><div><h2 class="h5 mb-1">Adicionar funcionalidade</h2><p class="small research-admin-muted mb-0">A nova etapa entrará antes da montagem do pacote.</p></div><button type="button" class="btn-close btn-close-white" aria-label="Fechar" data-research-add-close></button></div>
            <label class="form-label" for="researchNewFeatureName">Nome curto da funcionalidade</label><input class="form-control mb-3" id="researchNewFeatureName" placeholder="Ex.: Memórias de Corrida" maxlength="100"/>
            <div class="d-flex justify-content-end gap-2"><button type="button" class="btn btn-outline-light" data-research-add-close>Cancelar</button><button type="button" class="btn btn-warning" data-research-add-confirm>Adicionar</button></div>
        </div>
    </div>
</section>
