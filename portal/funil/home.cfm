<section id="business-funnel" class="business-page py-4" aria-labelledby="funnel-title">
    <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-4">
        <div><div class="funnel-eyebrow">Marketing e audiência / Audiência e relacionamento</div>
            <h1 id="funnel-title" class="business-page-title mb-2">Funil</h1>
            <p class="funnel-muted mb-0">Do cadastro à renovação. Acompanhe pessoas, produtos e vigências.</p>
        </div><span class="funnel-tag">MVP · dados do Business</span>
    </div>
    <form id="funnel-filters" class="business-panel funnel-filters mb-3">
        <label>Público<select name="publico"><option value="athletes">Usuários / atletas</option><option value="organizers">Donos de contas / organizadores</option></select></label>
        <label>Produto<select name="produto"><option value="desafio">Desafio Todo Santo Dia</option><option value="all">Todos os produtos mapeados</option><option value="patrocinio">Patrocínio (banners / anúncios)</option><option value="transmissao">Transmissão</option><option value="perfil">Perfil.Run</option><option value="dados">API / dashboard de dados</option></select></label>
        <label>Leitura<select name="leitura"><option value="base">Base acumulada até a data final</option><option value="cohort">Cadastros no período</option></select></label>
        <label>De<input type="date" name="de" required/></label>
        <label>Até<input type="date" name="ate" required/></label>
        <button class="btn btn-warning" type="submit">Aplicar filtros</button>
    </form>
    <p id="funnel-context" class="funnel-muted small mb-3">A data final define a vigência; o período define as entradas e saídas observadas.</p>
    <div id="funnel-message" class="funnel-message mb-3" role="status" aria-live="polite">Consultando dados…</div>
    <div class="funnel-tabs" role="tablist" aria-label="Visões do funil">
        <button id="tab-journey" role="tab" aria-controls="panel-journey" aria-selected="true" data-tab="journey">Funil</button>
        <button id="tab-people" role="tab" aria-controls="panel-people" aria-selected="false" tabindex="-1" data-tab="people">Usuários e clientes</button>
        <button id="tab-retention" role="tab" aria-controls="panel-retention" aria-selected="false" tabindex="-1" data-tab="retention">Retenção e origem</button>
    </div>
    <div id="funnel-results" aria-busy="true">
        <section id="panel-journey" role="tabpanel" aria-labelledby="tab-journey" class="funnel-panel">
            <div class="funnel-layout">
                <div class="business-panel funnel-visual-panel">
                    <div class="funnel-panel-heading"><h2>Jornada de conversão</h2><span id="funnel-base-label" class="funnel-muted small">Pessoas únicas</span></div>
                    <div id="funnel-shape" class="funnel-shape" aria-label="Etapas do funil"></div>
                    <p class="funnel-muted small mb-0">Clique em uma etapa para ver as pessoas. O desenho é ilustrativo; os números e percentuais representam a base filtrada.</p>
                </div>
                <aside class="funnel-side">
                    <div class="business-panel p-4"><h2>Na data final</h2><div id="funnel-groups" class="funnel-groups"></div></div>
                    <div class="business-panel p-4"><h2>Como ler</h2><p class="funnel-muted small mb-2">Participar do Desafio confirma um vínculo com o produto. O cadastro ou a inscrição, por si só, não comprovam pagamento nem uso de funcionalidades.</p><p class="funnel-muted small mb-0">Uma renovação identifica outra compra anual. Isso não significa assinatura com cobrança automática.</p></div>
                </aside>
            </div>
        </section>
        <section id="panel-people" role="tabpanel" aria-labelledby="tab-people" class="funnel-panel" hidden>
            <div class="business-panel p-4">
                <div class="funnel-people-tools"><h2>Usuários e clientes</h2><label>Etapa<select id="funnel-stage"><option value="base">Todos os cadastrados</option><option value="related">Com vínculo</option><option value="paid">Com pagamento confirmado</option><option value="active">Com vigência na data final</option><option value="renewed">Renovados e vigentes</option><option value="expired">Vigência encerrada, sem renovação observada</option></select></label><label>Buscar por nome ou ID<input type="search" id="funnel-search" maxlength="80" placeholder="Nome ou ID"/></label><button id="funnel-search-button" class="btn btn-outline-warning" type="button">Buscar</button></div>
                <div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th scope="col">Pessoa</th><th scope="col">Vínculo</th><th scope="col">Pagamento</th><th scope="col">Vigência até</th><th scope="col">Recorrência</th><th scope="col">Origem do vínculo</th></tr></thead><tbody id="funnel-people"></tbody></table></div>
                <div class="funnel-pagination"><span id="funnel-page-label" class="funnel-muted small"></span><button type="button" id="funnel-prev" class="btn btn-sm btn-outline-warning">Anterior</button><button type="button" id="funnel-next" class="btn btn-sm btn-outline-warning">Próxima</button></div>
            </div>
        </section>
        <section id="panel-retention" role="tabpanel" aria-labelledby="tab-retention" class="funnel-panel" hidden>
            <div class="funnel-retention-grid" id="funnel-retention"></div>
            <div class="business-panel p-4 mt-3"><h2>Origem e cobertura dos dados</h2><div id="funnel-coverage" class="funnel-muted"></div></div>
        </section>
    </div>
    <noscript><p>Ative o JavaScript para consultar e filtrar o funil.</p></noscript>
</section>
