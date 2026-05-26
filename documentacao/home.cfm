<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <style>
    .doc-page .doc-kicker {
      color: var(--mdb-warning);
      font-size: .78rem;
      font-weight: 700;
      letter-spacing: .04em;
      text-transform: uppercase;
    }

    .doc-page .doc-section {
      border: 1px solid rgba(255, 255, 255, .12);
      border-radius: 8px;
      padding: 1.25rem;
      background: rgba(255, 255, 255, .03);
    }

    .doc-page .doc-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 1rem;
    }

    .doc-page .doc-pill {
      display: inline-flex;
      align-items: center;
      gap: .4rem;
      border: 1px solid rgba(255, 255, 255, .16);
      border-radius: 999px;
      padding: .35rem .7rem;
      color: var(--mdb-body-color);
      background: rgba(255, 255, 255, .04);
      font-size: .85rem;
      margin: .15rem .2rem .15rem 0;
    }

    .doc-page .doc-list {
      margin-bottom: 0;
      padding-left: 1.1rem;
    }

    .doc-page .doc-list li {
      margin-bottom: .45rem;
    }

    .doc-page .doc-muted {
      color: var(--mdb-secondary-color);
    }
  </style>

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body doc-page">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
            <div>
              <div class="doc-kicker mb-2">RunnerHub Business</div>
              <h3 class="mb-2">Documentação operacional</h3>
              <p class="doc-muted mb-0">
                Guia inicial para entender as principais áreas do painel, quem pode ver cada informação e onde cada fluxo costuma ser operado.
              </p>
            </div>
            <div class="text-lg-end">
              <span class="doc-pill"><i class="fa-solid fa-user-shield"></i> Admin vê tudo</span>
              <span class="doc-pill"><i class="fa-solid fa-building"></i> Parceiro vê sua empresa</span>
              <span class="doc-pill"><i class="fa-solid fa-database"></i> PostgreSQL</span>
            </div>
          </div>

          <hr/>

          <div class="doc-section mb-4">
            <h5 class="mb-3">Visão geral</h5>
            <p class="mb-3">
              O <strong>Business</strong> é o backoffice operacional do ecossistema Road Runners / RunnerHub. Ele reúne gestão de eventos, BI, anúncios, cupons, notificações, suporte, portal, inscrições, CRM e operações administrativas.
            </p>
            <div class="doc-grid">
              <div>
                <h6>Stack</h6>
                <ul class="doc-list">
                  <li>Adobe ColdFusion / CFML com renderização server-side.</li>
                  <li>PostgreSQL no datasource principal <code>runner_dba</code>.</li>
                  <li>Interface logada baseada em MDBootstrap.</li>
                  <li>Módulos novos e legados convivendo no mesmo projeto.</li>
                </ul>
              </div>
              <div>
                <h6>Padrão de módulo</h6>
                <ul class="doc-list">
                  <li><code>index.cfm</code> define tema, template e inclui login.</li>
                  <li><code>home.cfm</code> monta a tela.</li>
                  <li><code>includes/backend.cfm</code> concentra queries e ações.</li>
                  <li><code>VARIABLES.template</code> controla destaque no menu.</li>
                </ul>
              </div>
              <div>
                <h6>Acesso</h6>
                <ul class="doc-list">
                  <li>O login carrega <code>qPerfil</code> a partir do <code>COOKIE.id</code>.</li>
                  <li>Usuários precisam ser <code>is_admin</code> ou <code>is_partner</code>.</li>
                  <li>Empresas do usuário vêm de <code>tb_usuarios_fornecedores</code>.</li>
                  <li>Eventos do parceiro vêm de <code>tb_evento_corridas_fornecedores</code>.</li>
                </ul>
              </div>
            </div>
          </div>

          <div class="doc-section mb-4">
            <h5 class="mb-3">Regras de visibilidade</h5>
            <div class="doc-grid">
              <div>
                <h6>Administrador</h6>
                <p class="mb-0">
                  Usuário com <code>qPerfil.is_admin = true</code> acessa a visão completa dos módulos administrativos, listas de eventos, campanhas, cupons e usuários.
                </p>
              </div>
              <div>
                <h6>Parceiro</h6>
                <p class="mb-0">
                  Usuário parceiro sem admin deve ver apenas dados ligados à empresa, fornecedor, página ou eventos associados ao seu cadastro.
                </p>
              </div>
              <div>
                <h6>Aplicação atual</h6>
                <p class="mb-0">
                  As áreas <code>/admin</code>, <code>/ads</code>, <code>/cupons</code>, <code>/cupons-rr</code> e <code>/usuarios</code> seguem esse padrão de restrição.
                </p>
              </div>
            </div>
          </div>

          <div class="doc-section mb-4">
            <h5 class="mb-3">Módulos principais</h5>
            <div class="table-responsive">
              <table class="table table-sm align-middle mb-0">
                <thead>
                  <tr>
                    <th>Área</th>
                    <th>Uso principal</th>
                    <th>Observações operacionais</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td><a href="/admin/">Eventos</a></td>
                    <td>Cadastro, edição, resultados, percursos, fornecedores, configurações e OR.</td>
                    <td>Admin abre 2026 por padrão. Parceiro abre Todo o Período e vê apenas eventos ligados à empresa. Abas Configurações e OR são admin-only.</td>
                  </tr>
                  <tr>
                    <td><a href="/ads/">Ads</a></td>
                    <td>Campanhas de anúncios por evento, com status, verba, período e segmentação.</td>
                    <td>Parceiro vê e altera apenas campanhas de eventos ligados à sua empresa.</td>
                  </tr>
                  <tr>
                    <td><a href="/inscricoes/">Inscrições</a></td>
                    <td>Relatório de inscrições e vendas por cupom, influenciadores, cashback e assessorias.</td>
                    <td>A visão atual usa base TicketSports de evento configurado no backend e respeita a lista de eventos permitidos ao parceiro.</td>
                  </tr>
                  <tr>
                    <td><a href="/cupons-rr/">Cupons RR</a></td>
                    <td>Gestão e leitura de cupons ligados a eventos, circuitos e páginas.</td>
                    <td>Parceiro vê cupons dos eventos permitidos, circuitos relacionados e páginas vinculadas ao próprio perfil.</td>
                  </tr>
                  <tr>
                    <td><a href="/usuarios/">Usuários</a></td>
                    <td>Aprovação e acompanhamento de usuários parceiros.</td>
                    <td>Admin vê todos. Parceiro vê usuários ligados aos mesmos fornecedores da empresa.</td>
                  </tr>
                  <tr>
                    <td><a href="/notificacoes/">Notificações</a></td>
                    <td>Envio administrativo e gestão operacional de notificações.</td>
                    <td>O Business monta o payload, mas a entrega deve passar pela API central do Road Runners.</td>
                  </tr>
                  <tr>
                    <td><a href="/suporte/">Suporte</a></td>
                    <td>Abertura e acompanhamento de chamados pelo usuário autenticado.</td>
                    <td>Usuário final só vê os próprios chamados. O atendimento administrativo completo fica no Help Desk.</td>
                  </tr>
                  <tr>
                    <td><a href="/helpdesk/">Help Desk</a></td>
                    <td>Painel administrativo de setores, chamados, mensagens e atendimento.</td>
                    <td>Fluxo administrativo, com notificações para responsável e dono do chamado.</td>
                  </tr>
                  <tr>
                    <td><a href="/portal/banners/">Portal Banners</a></td>
                    <td>Gerência de banners consumidos por API no ecossistema Road Runners.</td>
                    <td>Diferente de Ads: serve conteúdo promocional por canal/local e registra impressões e cliques.</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="doc-section mb-4">
            <h5 class="mb-3">Integrações e responsabilidades</h5>
            <div class="doc-grid">
              <div>
                <h6>Road Runners</h6>
                <p class="mb-0">Site público e núcleo de algumas APIs centrais, como o dispatch de notificações.</p>
              </div>
              <div>
                <h6>RunnerHub</h6>
                <p class="mb-0">Ecossistema de operação, eventos, dados e relacionamento com parceiros.</p>
              </div>
              <div>
                <h6>Open Results</h6>
                <p class="mb-0">Contexto de resultados, leaderboard e transmissão de provas.</p>
              </div>
              <div>
                <h6>News / Portal</h6>
                <p class="mb-0">Conteúdos editoriais, canais, vídeos e recursos de publicação no portal.</p>
              </div>
            </div>
          </div>

          <div class="doc-section">
            <h5 class="mb-3">Boas práticas antes de alterar uma área</h5>
            <ol class="mb-0">
              <li>Abra o <code>index.cfm</code> da rota e identifique o backend incluído.</li>
              <li>Confira se a tela usa <code>URL.acao</code>, <code>FORM.action</code> ou query fixa.</li>
              <li>Preserve checks de <code>qPerfil.is_admin</code> e restrições por empresa quando existirem.</li>
              <li>Ao mexer em tabelas densas, validar responsividade e redirects das ações.</li>
              <li>Quando a mudança depender do banco, conferir o DDL auxiliar e validar no ambiente alvo.</li>
            </ol>
          </div>

        </div>

      </div>

    </div>

  </div>

</section>
