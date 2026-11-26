<section id="business-funnel" class="business-page py-4" aria-labelledby="funnel-title">
    <div class="d-flex justify-content-between align-items-start flex-wrap gap-3 mb-4">
        <div><div class="funnel-eyebrow">Marketing e audiência / Audiência e relacionamento</div>
            <h1 id="funnel-title" class="business-page-title mb-2">Funil</h1>
            <p class="funnel-muted mb-0">Do cadastro à compra e à vigência por produto.</p>
        </div><span class="funnel-tag">MVP · dados do Business</span>
    </div>
    <form id="funnel-filters" class="business-panel funnel-filters mb-3">
        <label>Público<select name="publico"><option value="athletes">Usuários / atletas</option><option value="organizers">Donos de contas / organizadores</option></select></label>
        <label>Produto<select name="produto"><option value="desafio">Desafio Todo Santo Dia</option><option value="selo">Selo Verificado</option><option value="assinatura">Assinatura</option><option value="gorunners">Go Runners</option><option value="estudo">Estudos</option></select></label>
        <label>Leitura<select name="leitura"><option value="base">Base acumulada até a data final</option><option value="cohort">Cadastros no período</option></select></label>
        <label>De<input type="date" name="de" required/></label>
        <label>Até<input type="date" name="ate" required/></label>
        <button class="btn btn-warning" type="submit">Aplicar filtros</button>
    </form>
    <p id="funnel-context" class="funnel-muted small mb-3">Compras até a data final; vigência comprovada à parte.</p>
    <div id="funnel-message" class="funnel-message mb-3" role="status" aria-live="polite">Consultando dados…</div>
    <div class="funnel-tabs" role="tablist" aria-label="Visões do funil">
        <button id="tab-geral" role="tab" aria-controls="panel-geral" aria-selected="false" tabindex="-1" data-tab="geral">Geral</button>
        <button id="tab-journey" role="tab" aria-controls="panel-journey" aria-selected="true" data-tab="journey">Funil</button>
        <button id="tab-people" role="tab" aria-controls="panel-people" aria-selected="false" tabindex="-1" data-tab="people">Usuários e clientes</button>
        <button id="tab-transmissions" role="tab" aria-controls="panel-transmissions" aria-selected="false" tabindex="-1" data-tab="transmissions" hidden>Transmissões por evento</button>
        <button id="tab-retention" role="tab" aria-controls="panel-retention" aria-selected="false" tabindex="-1" data-tab="retention">Retenção e origem</button>
    </div>
    <div id="funnel-results" aria-busy="true">
        <section id="panel-geral" role="tabpanel" aria-labelledby="tab-geral" class="funnel-panel" hidden>
            <div class="business-panel funnel-general-intro">
                <div><h2>Visão geral de usuários</h2><p class="funnel-muted mb-0">Pessoas cadastradas no RunnerHub, sem filtro de produto ou público.</p></div>
                <form id="funnel-general-filters"><label>Mês de referência<input type="month" name="mes" required/></label><button class="btn btn-warning" type="submit">Consultar</button></form>
            </div>
            <div id="funnel-general-message" class="funnel-message mt-3" role="status" aria-live="polite">Consultando dados…</div>
            <div class="funnel-general-grid mt-3">
                <article class="business-panel funnel-retention-card"><h2>Usuários cadastrados</h2><strong id="general-total">—</strong><p id="general-total-note" class="funnel-muted small mb-0">Base acumulada até a data de referência.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Novos cadastros no mês</h2><strong id="general-new">—</strong><p id="general-new-note" class="funnel-muted small mb-0">Contas criadas no mês selecionado.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Clientes históricos identificados</h2><strong id="general-linked">—</strong><p class="funnel-muted small mb-0">Pessoas únicas com compra identificada ou donas de conta cliente. Cobertura parcial.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Clientes com vigência no mês</h2><strong id="general-term">—</strong><p class="funnel-muted small mb-0">Pessoas únicas com vigência comprovada do Desafio ou da compra direta do Selo em algum momento do mês.</p></article>
            </div>
            <div class="funnel-panel-heading mt-4"><h2>Detalhamento por produto</h2><span class="funnel-muted small">Acumulados até a data de referência</span></div>
            <div class="funnel-general-grid funnel-general-sources mt-2">
                <article class="business-panel funnel-retention-card"><h2>Todo Santo Dia</h2><strong id="general-challenge">—</strong><p class="funnel-muted small mb-0">Pessoas com compra identificada ou status C atual.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Selo · compra direta</h2><strong id="general-selo">—</strong><p class="funnel-muted small mb-0">Pessoas com compra direta paga e não reembolsada, incluindo quem não está vigente no mês.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Selo pelo Desafio</h2><strong id="general-challenge-selo">—</strong><p class="funnel-muted small mb-0">Pessoas com pedido VIP ou upgrade pago identificado, que dá direito ao selo. Não é venda direta do Selo.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Go Runners</h2><strong id="general-go">—</strong><p class="funnel-muted small mb-2">Pessoas com cadastro vinculado ao RunnerHub; pagamentos ainda não foram avaliados.</p><p class="funnel-muted small mb-0">Assinaturas pagas: identificação em validação.</p></article>
                <article class="business-panel funnel-retention-card"><h2>Organizadores clientes</h2><strong id="general-accounts">—</strong><p class="funnel-muted small mb-2">Contas únicas com Transmissão ou Patrocinado, inclusive sem dono identificado.</p><div class="funnel-general-details"><span>Donos identificados</span><span id="general-owners">—</span><span>Contas com Transmissão</span><span id="general-live">—</span><span>Contas com Patrocinado</span><span id="general-ads">—</span></div><p id="general-live-note" class="funnel-muted small mb-0">Contas com evento associado no leaderboard.</p></article>
            </div>
            <div class="business-panel p-4 mt-3"><h2>Como ler esta visão</h2><p class="funnel-muted small mb-0">Clientes históricos e vigentes no mês são perspectivas diferentes e não devem ser somados: uma pessoa pode estar nos dois indicadores. Cada ID RunnerHub é contado uma vez em cada indicador, mesmo em vários produtos; IDs diferentes da mesma pessoa não são conciliados automaticamente. O histórico inclui compras do Todo Santo Dia e do Selo e donos atuais de contas clientes de Transmissão ou Patrocinado. A compra reembolsada do Selo é excluída, mesmo ao consultar datas anteriores. Benefícios do Desafio e concessões legadas não são vendas diretas do Selo. A contagem mensal ainda não cobre vigência de organizadores ou produtos não mapeados. Cadastros Go Runners não entram como pagantes. Contas sem dono identificado aparecem no total de contas, não no de pessoas. As fontes são parciais, não incluem produtos ainda não mapeados nem o Desafio 365 e não recuperam cadastros excluídos ou antigos donos. Status C sem data só contribui na referência de hoje. O leaderboard indica fechamento, sem comprovar data de pagamento ou vigência. Vigência não comprova uso da plataforma.</p></div>
        </section>
        <section id="panel-journey" role="tabpanel" aria-labelledby="tab-journey" class="funnel-panel">
            <div class="funnel-layout">
                <div class="business-panel funnel-visual-panel">
                    <div class="funnel-panel-heading"><h2>Jornada de conversão</h2><span id="funnel-base-label" class="funnel-muted small">Pessoas únicas</span></div>
                    <div id="funnel-shape" class="funnel-shape" aria-label="Etapas do funil"></div>
                    <p class="funnel-muted small mb-0">Clique em uma etapa para ver as pessoas. O desenho é ilustrativo; os números usam o produto selecionado.</p>
                </div>
                <aside class="funnel-side">
                    <div class="business-panel p-4"><h2>Na data final</h2><div id="funnel-groups" class="funnel-groups"></div></div>
                    <div class="business-panel p-4"><h2>Como ler</h2><p id="funnel-reading-help" class="funnel-muted small mb-0">Consulte as regras e limitações das fontes em Retenção e origem.</p></div>
                </aside>
            </div>
        </section>
        <section id="panel-people" role="tabpanel" aria-labelledby="tab-people" class="funnel-panel" hidden>
            <div class="business-panel p-4">
                <div class="funnel-people-tools"><h2>Usuários e clientes</h2><label>Etapa<select id="funnel-stage"><option value="base">Todos os cadastrados</option><option value="related">Com vínculo</option><option value="paid">Compraram Todo Santo Dia</option><option value="active">Com vigência comprovada</option><option value="status_c">Todo Santo Dia com status C hoje</option><option value="expired">Vigência TSD encerrada na data final</option></select></label><label>Buscar por nome ou ID<input type="search" id="funnel-search" maxlength="80" placeholder="Nome ou ID"/></label><button id="funnel-search-button" class="btn btn-outline-warning" type="button">Buscar</button></div>
                <div class="table-responsive"><table id="funnel-people-table" class="table align-middle mb-0"><thead><tr><th scope="col">Pessoa</th><th scope="col">Vínculo</th><th scope="col">Pagamento</th><th scope="col">Vigência até</th><th scope="col">Situação</th><th scope="col">Origem do vínculo</th></tr></thead><tbody id="funnel-people"></tbody></table></div>
                <div class="funnel-pagination"><span id="funnel-page-label" class="funnel-muted small"></span><button type="button" id="funnel-prev" class="btn btn-sm btn-outline-warning">Anterior</button><button type="button" id="funnel-next" class="btn btn-sm btn-outline-warning">Próxima</button></div>
            </div>
        </section>
        <section id="panel-transmissions" role="tabpanel" aria-labelledby="tab-transmissions" class="funnel-panel" hidden>
            <div class="business-panel p-4">
                <h2>Transmissões por evento</h2>
                <p class="funnel-muted small">Provas entre as datas De e Até, configuradas no leaderboard até a data final. Inclui eventos sem conta identificada. Esta visão é independente da coorte de cadastros.</p>
                <div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th scope="col">Evento</th><th scope="col">Data da prova</th><th scope="col">Conta atribuída</th><th scope="col">Vínculo</th></tr></thead><tbody id="funnel-transmissions"></tbody></table></div>
            </div>
        </section>
        <section id="panel-retention" role="tabpanel" aria-labelledby="tab-retention" class="funnel-panel" hidden>
            <div class="funnel-retention-grid" id="funnel-retention"></div>
            <div class="business-panel p-4 mt-3" id="funnel-attribution-panel" hidden>
                <h2>Compras diretas do Selo por campanha</h2>
                <p id="funnel-attribution-note" class="funnel-muted small">Contagem de pedidos pagos sem reembolso. Uma pessoa pode comprar mais de uma vez.</p>
                <div class="table-responsive"><table class="table align-middle mb-0"><thead><tr><th scope="col">Canal</th><th scope="col">Campanha</th><th scope="col">Compras</th><th scope="col">Pessoas</th></tr></thead><tbody id="funnel-attribution-rows"></tbody></table></div>
            </div>
            <div class="business-panel p-4 mt-3"><h2>Origem e cobertura dos dados</h2><div id="funnel-coverage" class="funnel-muted"></div></div>
        </section>
    </div>
    <noscript><p>Ative o JavaScript para consultar e filtrar o funil.</p></noscript>
</section>
