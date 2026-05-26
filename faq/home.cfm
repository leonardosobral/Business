<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<!--- CONTEUDO --->

<section class="">

  <style>
    .faq-page .faq-kicker {
      color: var(--mdb-warning);
      font-size: .78rem;
      font-weight: 700;
      letter-spacing: .04em;
      text-transform: uppercase;
    }

    .faq-page .faq-intro {
      color: var(--mdb-secondary-color);
      max-width: 860px;
    }

    .faq-page .accordion-item {
      border: 1px solid rgba(255, 255, 255, .12);
      border-radius: 8px;
      overflow: hidden;
      background: rgba(255, 255, 255, .03);
      margin-bottom: .75rem;
    }

    .faq-page .accordion-button {
      background: rgba(255, 255, 255, .04);
      color: var(--mdb-body-color);
      font-weight: 600;
      box-shadow: none;
    }

    .faq-page .accordion-button:not(.collapsed) {
      color: var(--mdb-warning);
      background: rgba(255, 255, 255, .06);
    }

    .faq-page .accordion-button::after {
      filter: invert(1) grayscale(1);
    }

    .faq-page .accordion-body {
      color: var(--mdb-body-color);
    }

    .faq-page .faq-tag {
      display: inline-flex;
      align-items: center;
      border: 1px solid rgba(255, 255, 255, .16);
      border-radius: 999px;
      padding: .25rem .6rem;
      color: var(--mdb-secondary-color);
      font-size: .8rem;
      margin: .15rem .2rem .15rem 0;
    }
  </style>

  <div class="row gx-xl-5">

    <div class="col-lg-12 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">

        <div class="card-body faq-page">

          <div class="faq-kicker mb-2">Perguntas frequentes</div>
          <h3 class="mb-2">FAQ</h3>
          <p class="faq-intro mb-3">
            Respostas rápidas para orientar o uso do RunnerHub Business no dia a dia de parceiros, organizadores e equipes que operam eventos, campanhas e atendimento.
          </p>
          <div class="mb-4">
            <span class="faq-tag">Acesso</span>
            <span class="faq-tag">Eventos</span>
            <span class="faq-tag">Ads</span>
            <span class="faq-tag">Cupons</span>
            <span class="faq-tag">Suporte</span>
            <span class="faq-tag">Notificações</span>
          </div>

          <hr/>

          <div class="accordion" id="faqBusinessAccordion">
            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingOne">
                <button class="accordion-button" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseOne" aria-expanded="true" aria-controls="faqCollapseOne">
                  O que é o RunnerHub Business?
                </button>
              </h2>
              <div id="faqCollapseOne" class="accordion-collapse collapse show" aria-labelledby="faqHeadingOne" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  É o painel de gestão para acompanhar e operar informações do ecossistema Road Runners / RunnerHub, incluindo eventos, campanhas, cupons, relatórios, notificações, suporte e conteúdos do portal.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingTwo">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseTwo" aria-expanded="false" aria-controls="faqCollapseTwo">
                  Quem consegue acessar o painel?
                </button>
              </h2>
              <div id="faqCollapseTwo" class="accordion-collapse collapse" aria-labelledby="faqHeadingTwo" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  O acesso é liberado para usuários aprovados. Administradores têm uma visão mais ampla do painel; parceiros e equipes convidadas visualizam as áreas e informações ligadas à própria empresa.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingThree">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseThree" aria-expanded="false" aria-controls="faqCollapseThree">
                  Por que eu não vejo todos os eventos?
                </button>
              </h2>
              <div id="faqCollapseThree" class="accordion-collapse collapse" aria-labelledby="faqHeadingThree" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A visualização depende do seu perfil de acesso. Parceiros normalmente veem apenas os eventos vinculados à própria empresa. Caso algum evento esperado não apareça, abra um chamado no Suporte para revisão do vínculo.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFour">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFour" aria-expanded="false" aria-controls="faqCollapseFour">
                  Qual período aparece por padrão em Eventos?
                </button>
              </h2>
              <div id="faqCollapseFour" class="accordion-collapse collapse" aria-labelledby="faqHeadingFour" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Administradores entram com 2026 selecionado por padrão, porque a base completa de eventos é grande. Parceiros entram com Todo o Período para facilitar a consulta dos eventos ligados à empresa.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFive">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFive" aria-expanded="false" aria-controls="faqCollapseFive">
                  Por que não vejo as abas Configurações e OR?
                </button>
              </h2>
              <div id="faqCollapseFive" class="accordion-collapse collapse" aria-labelledby="faqHeadingFive" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Essas abas são recursos administrativos avançados. Elas aparecem apenas para perfis autorizados.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingSix">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseSix" aria-expanded="false" aria-controls="faqCollapseSix">
                  Como funciona a área de Ads?
                </button>
              </h2>
              <div id="faqCollapseSix" class="accordion-collapse collapse" aria-labelledby="faqHeadingSix" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A área de Ads reúne campanhas ligadas a eventos. Usuários parceiros visualizam e operam somente campanhas associadas aos eventos da própria empresa.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingSeven">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseSeven" aria-expanded="false" aria-controls="faqCollapseSeven">
                  Como funciona a área de Cupons?
                </button>
              </h2>
              <div id="faqCollapseSeven" class="accordion-collapse collapse" aria-labelledby="faqHeadingSeven" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A área de Cupons mostra indicadores de vendas por cupom, incluindo influenciadores, cashback, assessorias e vendas orgânicas. Para parceiros, os relatórios exibem apenas eventos vinculados à empresa.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingEight">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseEight" aria-expanded="false" aria-controls="faqCollapseEight">
                  Qual a diferença entre Cupons e Cupons RR?
                </button>
              </h2>
              <div id="faqCollapseEight" class="accordion-collapse collapse" aria-labelledby="faqHeadingEight" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Cupons é mais voltado a relatórios de performance de vendas. Cupons RR organiza cupons cadastrados para uso no ecossistema Road Runners e pode relacioná-los a eventos, circuitos e páginas.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingNine">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseNine" aria-expanded="false" aria-controls="faqCollapseNine">
                  O que aparece em Usuários?
                </button>
              </h2>
              <div id="faqCollapseNine" class="accordion-collapse collapse" aria-labelledby="faqHeadingNine" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A tela reúne usuários parceiros para aprovação, complementação de cadastro e consulta. Usuários com acesso restrito visualizam apenas pessoas ligadas à própria empresa.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingTen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseTen" aria-expanded="false" aria-controls="faqCollapseTen">
                  Como abro um chamado de suporte?
                </button>
              </h2>
              <div id="faqCollapseTen" class="accordion-collapse collapse" aria-labelledby="faqHeadingTen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Use a área <a href="/suporte/">Suporte</a>. O chamado fica ligado ao seu usuário, e o histórico mostra as mensagens trocadas com a equipe de atendimento.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingEleven">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseEleven" aria-expanded="false" aria-controls="faqCollapseEleven">
                  Como acompanho um chamado?
                </button>
              </h2>
              <div id="faqCollapseEleven" class="accordion-collapse collapse" aria-labelledby="faqHeadingEleven" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Use a área Suporte para ver seus chamados abertos, acompanhar respostas e continuar a conversa com a equipe de atendimento.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingTwelve">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseTwelve" aria-expanded="false" aria-controls="faqCollapseTwelve">
                  Como funcionam as notificações?
                </button>
              </h2>
              <div id="faqCollapseTwelve" class="accordion-collapse collapse" aria-labelledby="faqHeadingTwelve" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  As notificações ajudam a avisar usuários sobre atualizações importantes, como mensagens de suporte e comunicados operacionais. O envio pode depender das permissões do usuário e das configurações de cada campanha.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingThirteen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseThirteen" aria-expanded="false" aria-controls="faqCollapseThirteen">
                  O que é Portal Banners?
                </button>
              </h2>
              <div id="faqCollapseThirteen" class="accordion-collapse collapse" aria-labelledby="faqHeadingThirteen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  É uma área para gerenciar banners exibidos nos canais do ecossistema. Ela permite controlar conteúdo, período de exibição, prioridade e métricas como impressões e cliques.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFourteen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFourteen" aria-expanded="false" aria-controls="faqCollapseFourteen">
                  Onde encontro ajuda para usar o painel?
                </button>
              </h2>
              <div id="faqCollapseFourteen" class="accordion-collapse collapse" aria-labelledby="faqHeadingFourteen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Comece por esta FAQ e pela Documentação do menu lateral. Se a dúvida envolver acesso, dados ausentes ou operação de uma campanha, abra um chamado em Suporte com o máximo de contexto possível.
                </div>
              </div>
            </div>
          </div>

        </div>

      </div>

    </div>

  </div>

</section>
