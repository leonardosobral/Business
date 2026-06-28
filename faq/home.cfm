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
            Respostas rápidas para empresas, organizadores e equipes que usam o Run Pro para cuidar dos seus eventos, campanhas e cupons no RoadRunners.
          </p>
          <div class="mb-4">
            <span class="faq-tag">Acesso</span>
            <span class="faq-tag">Conta</span>
            <span class="faq-tag">Eventos</span>
            <span class="faq-tag">Turbinados</span>
            <span class="faq-tag">Vouchers</span>
            <span class="faq-tag">Cupons</span>
            <span class="faq-tag">Equipe</span>
          </div>

          <hr/>

          <div class="accordion" id="faqBusinessAccordion">
            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingOne">
                <button class="accordion-button" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseOne" aria-expanded="true" aria-controls="faqCollapseOne">
                  O que é o Run Pro?
                </button>
              </h2>
              <div id="faqCollapseOne" class="accordion-collapse collapse show" aria-labelledby="faqHeadingOne" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  É a área Business do RunnerHub para empresas que organizam, divulgam ou operam eventos. Por aqui você acompanha provas vinculadas à sua conta, completa informações importantes, ativa créditos de divulgação, cria campanhas de destaque e consulta cupons.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingTwo">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseTwo" aria-expanded="false" aria-controls="faqCollapseTwo">
                  Como solicito acesso para a minha empresa?
                </button>
              </h2>
              <div id="faqCollapseTwo" class="accordion-collapse collapse" aria-labelledby="faqHeadingTwo" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Use a opção de solicitar acesso na tela inicial e preencha os dados da empresa, do responsável e do tipo de atuação. Use um e-mail Google que você realmente utilizará para entrar no painel depois da liberação.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingThree">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseThree" aria-expanded="false" aria-controls="faqCollapseThree">
                  Já enviei a solicitação. O que acontece agora?
                </button>
              </h2>
              <div id="faqCollapseThree" class="accordion-collapse collapse" aria-labelledby="faqHeadingThree" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A equipe RunnerHub revisa os dados e associa seu usuário à conta correta da empresa. Quando o acesso estiver liberado, você poderá entrar com o mesmo e-mail Google informado no cadastro.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFour">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFour" aria-expanded="false" aria-controls="faqCollapseFour">
                  Consigo entrar antes da aprovação?
                </button>
              </h2>
              <div id="faqCollapseFour" class="accordion-collapse collapse" aria-labelledby="faqHeadingFour" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Você pode até conseguir fazer login com Google, mas a operação da conta só fica disponível depois que seu acesso estiver aprovado e vinculado a uma empresa. Enquanto isso, o painel pode mostrar uma mensagem de acesso em análise.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFive">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFive" aria-expanded="false" aria-controls="faqCollapseFive">
                  Como faço login no Run Pro?
                </button>
              </h2>
              <div id="faqCollapseFive" class="accordion-collapse collapse" aria-labelledby="faqHeadingFive" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Entre usando o botão de login com Google. O ideal é usar o mesmo e-mail informado no pedido de acesso ou o e-mail que foi convidado pelo responsável da conta.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingSix">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseSix" aria-expanded="false" aria-controls="faqCollapseSix">
                  Por que vejo somente alguns eventos?
                </button>
              </h2>
              <div id="faqCollapseSix" class="accordion-collapse collapse" aria-labelledby="faqHeadingSix" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A sua conta mostra os eventos vinculados à sua empresa. Se uma prova sua ainda não aparece, solicite o vínculo pela área de Eventos informando a URL, tag, ID ou nome da prova no RoadRunners.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingSeven">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseSeven" aria-expanded="false" aria-controls="faqCollapseSeven">
                  Como vinculo uma prova à minha conta?
                </button>
              </h2>
              <div id="faqCollapseSeven" class="accordion-collapse collapse" aria-labelledby="faqHeadingSeven" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Acesse Eventos e busque a prova pelo link do RoadRunners, pela tag, pelo ID ou pelo nome. Se o evento ainda não estiver na sua conta, envie a solicitação de vínculo. Após a validação, ele passa a aparecer para gestão e campanhas.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingEight">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseEight" aria-expanded="false" aria-controls="faqCollapseEight">
                  O que devo revisar em Conteúdo das provas?
                </button>
              </h2>
              <div id="faqCollapseEight" class="accordion-collapse collapse" aria-labelledby="faqHeadingEight" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Essa área ajuda a identificar quais provas precisam de informações melhores, como descrição, link de inscrição, categorias, local, organizador, imagem e resultados. O objetivo é deixar a página da prova mais completa para o atleta.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingNine">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseNine" aria-expanded="false" aria-controls="faqCollapseNine">
                  O que são Turbinados?
                </button>
              </h2>
              <div id="faqCollapseNine" class="accordion-collapse collapse" aria-labelledby="faqHeadingNine" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Turbinados são campanhas para destacar eventos em áreas do RoadRunners, como busca e espaços de divulgação. Você define o evento, o investimento e acompanha resultados como visualizações, cliques, taxa de clique e consumo de crédito.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingTen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseTen" aria-expanded="false" aria-controls="faqCollapseTen">
                  Preciso ter evento vinculado para turbinar?
                </button>
              </h2>
              <div id="faqCollapseTen" class="accordion-collapse collapse" aria-labelledby="faqHeadingTen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Sim. Primeiro o evento precisa estar vinculado à sua conta. Depois disso, ele fica disponível para criação de campanha, desde que exista crédito de divulgação ativo.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingEleven">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseEleven" aria-expanded="false" aria-controls="faqCollapseEleven">
                  Como ativo um voucher de crédito?
                </button>
              </h2>
              <div id="faqCollapseEleven" class="accordion-collapse collapse" aria-labelledby="faqHeadingEleven" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Vá até Turbinados e use o campo de ativação de voucher. Quando o código for válido para sua conta, o crédito fica disponível para campanhas de destaque.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingTwelve">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseTwelve" aria-expanded="false" aria-controls="faqCollapseTwelve">
                  O que faço se recebi um voucher, mas ele não aparece?
                </button>
              </h2>
              <div id="faqCollapseTwelve" class="accordion-collapse collapse" aria-labelledby="faqHeadingTwelve" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Confira se você está acessando a conta correta e tente digitar o código manualmente em Turbinados. Se ainda assim não funcionar, fale com a equipe RunnerHub informando o código recebido e o nome da empresa.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingThirteen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseThirteen" aria-expanded="false" aria-controls="faqCollapseThirteen">
                  Como acompanho o resultado de uma campanha?
                </button>
              </h2>
              <div id="faqCollapseThirteen" class="accordion-collapse collapse" aria-labelledby="faqHeadingThirteen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Em Turbinados, acompanhe os indicadores e a lista de campanhas. Ali você encontra dados como visualizações, cliques, taxa de clique, custo médio e investimento usado. Esses números ajudam a decidir se vale pausar, manter ou ajustar a campanha.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFourteen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFourteen" aria-expanded="false" aria-controls="faqCollapseFourteen">
                  Como funcionam os cupons de desconto?
                </button>
              </h2>
              <div id="faqCollapseFourteen" class="accordion-collapse collapse" aria-labelledby="faqHeadingFourteen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  A área de Cupons de Desconto ajuda a acompanhar códigos ligados aos eventos da sua conta. Ela pode ser usada para analisar campanhas promocionais, parceiros, influenciadores e ações comerciais relacionadas às inscrições.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingFifteen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseFifteen" aria-expanded="false" aria-controls="faqCollapseFifteen">
                  Posso convidar outras pessoas da minha equipe?
                </button>
              </h2>
              <div id="faqCollapseFifteen" class="accordion-collapse collapse" aria-labelledby="faqHeadingFifteen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Sim, quando seu acesso permite gerenciar a conta. Em Gestão da conta, você pode adicionar pessoas da equipe e definir quem acompanha dados ou também opera eventos, campanhas e cupons.
                </div>
              </div>
            </div>

            <div class="accordion-item">
              <h2 class="accordion-header" id="faqHeadingSixteen">
                <button class="accordion-button collapsed" type="button" data-mdb-collapse-init data-mdb-target="#faqCollapseSixteen" aria-expanded="false" aria-controls="faqCollapseSixteen">
                  O que faço se algo da minha conta estiver faltando?
                </button>
              </h2>
              <div id="faqCollapseSixteen" class="accordion-collapse collapse" aria-labelledby="faqHeadingSixteen" data-mdb-parent="#faqBusinessAccordion">
                <div class="accordion-body">
                  Se um evento, voucher, usuário ou informação importante não aparecer, fale com a equipe RunnerHub com o máximo de contexto possível: nome da empresa, evento, link da prova e o e-mail usado para login.
                </div>
              </div>
            </div>
          </div>

        </div>

      </div>

    </div>

  </div>

</section>
