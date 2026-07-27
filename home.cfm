<!DOCTYPE html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="includes/backend/backend_login.cfm"/>

<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <title>Run Pro | O negócio da corrida acontece aqui</title>
    <meta name="description" content="Run Pro é a plataforma de negócios do ecossistema da corrida: eventos, conteúdo, mídia, relacionamento e inteligência para organizadores, marcas, canais e empresas do setor."/>
    <meta name="author" content="RunnerHub"/>
    <meta name="theme-color" content="#121212"/>
    <link rel="canonical" href="https://business.roadrunners.run/"/>
    <link rel="shortcut icon" href="/favicon.ico"/>

    <meta property="og:type" content="website"/>
    <meta property="og:locale" content="pt_BR"/>
    <meta property="og:title" content="Run Pro | O negócio da corrida acontece aqui"/>
    <meta property="og:description" content="Operação, conteúdo, mídia, relacionamento e inteligência em uma plataforma conectada ao ecossistema RunnerHub."/>
    <meta property="og:url" content="https://business.roadrunners.run/"/>
    <meta property="og:image" content="https://business.roadrunners.run/assets/img/runpro-og.png"/>
    <meta property="og:image:width" content="1200"/>
    <meta property="og:image:height" content="630"/>
    <meta property="og:image:alt" content="Run Pro — O negócio da corrida acontece aqui."/>

    <meta name="twitter:card" content="summary_large_image"/>
    <meta name="twitter:title" content="Run Pro | O negócio da corrida acontece aqui"/>
    <meta name="twitter:description" content="A central de negócios para quem organiza, promove, comunica e movimenta a corrida de rua."/>
    <meta name="twitter:image" content="https://business.roadrunners.run/assets/img/runpro-og.png"/>

    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
    <link href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,600;0,700;0,800;0,900;1,700;1,800&amp;family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css"/>
    <link rel="stylesheet" href="/lib/css/fontello.css"/>
    <link rel="stylesheet" href="/assets/css/runpro-home.css?v=20260727-3"/>

    <script src="https://accounts.google.com/gsi/client" async></script>
</head>

<body>
    <a class="skip-link" href="#conteudo">Ir para o conteúdo</a>

    <header class="site-header" data-site-header>
        <div class="container header-inner">
            <a class="brand" href="#inicio" aria-label="Run Pro — início">
                <img src="/lib/images/runpro.svg" alt="Run Pro"/>
                <span class="brand-signature" aria-hidden="true">Road Runners <strong>Business</strong></span>
            </a>

            <button class="menu-toggle" type="button" aria-label="Abrir menu" aria-expanded="false" aria-controls="main-navigation" data-menu-toggle>
                <span></span>
                <span></span>
            </button>

            <nav class="main-nav" id="main-navigation" aria-label="Navegação principal" data-main-nav>
                <a href="#para-quem">Para quem</a>
                <a href="#solucoes">Soluções</a>
                <a href="#inteligencia">Inteligência</a>
                <a href="#ecossistema">Ecossistema</a>
                <a href="#faq">Dúvidas</a>
            </nav>

            <div class="header-actions">
                <button class="text-button" type="button" data-login-open>Entrar</button>
                <a class="button button-small button-primary" href="/cadastro/">Solicitar acesso</a>
            </div>
        </div>
    </header>

    <main id="conteudo">
        <section class="hero" id="inicio">
            <div class="hero-grid" aria-hidden="true"></div>
            <div class="hero-glow hero-glow-one" aria-hidden="true"></div>
            <div class="hero-glow hero-glow-two" aria-hidden="true"></div>

            <div class="container hero-layout">
                <div class="hero-copy">
                    <div class="eyebrow reveal">
                        <span class="eyebrow-dot"></span>
                        A central de negócios da corrida de rua
                    </div>

                    <h1 class="reveal">
                        Da largada ao legado:
                        <span>faça seu negócio correr mais longe.</span>
                    </h1>

                    <p class="hero-lead reveal">
                        O Run Pro conecta operação, conteúdo, mídia, relacionamento e dados para quem organiza, patrocina, comunica e movimenta o mercado de corridas.
                    </p>

                    <div class="hero-actions reveal">
                        <a class="button button-primary button-large" href="/cadastro/">
                            Solicitar acesso gratuito
                            <i class="fa fa-arrow-right" aria-hidden="true"></i>
                        </a>
                        <a class="button button-ghost button-large" href="#solucoes">Explorar a plataforma</a>
                    </div>

                    <ul class="hero-audiences reveal" aria-label="Públicos atendidos">
                        <li><i class="fa fa-check" aria-hidden="true"></i> Organizadores</li>
                        <li><i class="fa fa-check" aria-hidden="true"></i> Marcas e patrocinadores</li>
                        <li><i class="fa fa-check" aria-hidden="true"></i> Mídia e canais</li>
                        <li><i class="fa fa-check" aria-hidden="true"></i> Empresas do setor</li>
                    </ul>
                </div>

                <div class="hero-visual reveal">
                    <div class="race-orbit">
                        <div class="race-image-wrap">
                            <img src="/assets/img/largada.png" alt="Largada de uma grande corrida de rua vista do alto"/>
                        </div>
                        <span class="orbit orbit-one"></span>
                        <span class="orbit orbit-two"></span>
                        <span class="orbit-dot orbit-dot-one"></span>
                        <span class="orbit-dot orbit-dot-two"></span>
                    </div>

                    <div class="floating-card floating-card-top">
                        <span class="floating-icon"><i class="fa fa-line-chart" aria-hidden="true"></i></span>
                        <span>
                            <small>Decisão</small>
                            Dados que viram direção
                        </span>
                    </div>

                    <div class="floating-card floating-card-bottom">
                        <span class="live-dot"></span>
                        <span>
                            <small>Ecossistema conectado</small>
                            Evento · audiência · resultado
                        </span>
                    </div>

                    <div class="visual-stamp" aria-hidden="true">
                        <img src="/lib/images/runpro.svg" alt=""/>
                    </div>
                </div>
            </div>

            <div class="container hero-foot">
                <p>Uma plataforma. Diferentes negócios. O mesmo mercado em movimento.</p>
                <a href="#para-quem" aria-label="Continuar para a próxima seção">
                    <span>Descubra</span>
                    <i class="fa fa-long-arrow-down" aria-hidden="true"></i>
                </a>
            </div>
        </section>

        <section class="audience section" id="para-quem">
            <div class="container">
                <div class="section-heading section-heading-wide reveal">
                    <div>
                        <span class="kicker">Feito para o ecossistema inteiro</span>
                        <h2>Quem faz a corrida acontecer encontra espaço para crescer.</h2>
                    </div>
                    <p>
                        O Run Pro organiza as pontas do mercado em uma experiência única — da prova que precisa lotar à marca que quer participar da conversa certa.
                    </p>
                </div>

                <div class="audience-grid">
                    <article class="audience-card audience-card-featured reveal">
                        <div class="card-index">01</div>
                        <div class="audience-icon"><i class="fa fa-flag-checkered" aria-hidden="true"></i></div>
                        <h3>Organizadores e promotores</h3>
                        <p>Centralize eventos, inscrições, percursos, conteúdo, divulgação e relacionamento com o corredor.</p>
                        <ul>
                            <li>Mais agilidade na operação</li>
                            <li>Mais qualidade na comunicação</li>
                            <li>Mais oportunidades de receita</li>
                        </ul>
                    </article>

                    <article class="audience-card reveal">
                        <div class="card-index">02</div>
                        <div class="audience-icon"><i class="fa fa-bullseye" aria-hidden="true"></i></div>
                        <h3>Marcas e patrocinadores</h3>
                        <p>Encontre contexto, inventário e sinais de audiência para ativar patrocínios com mais relevância.</p>
                        <ul>
                            <li>Visibilidade segmentada</li>
                            <li>Campanhas e ativações</li>
                            <li>Leitura de interesse e alcance</li>
                        </ul>
                    </article>

                    <article class="audience-card reveal">
                        <div class="card-index">03</div>
                        <div class="audience-icon"><i class="fa fa-play-circle-o" aria-hidden="true"></i></div>
                        <h3>Canais e comunicação</h3>
                        <p>Distribua vídeos, notícias e conteúdos para uma audiência interessada em correr, viajar e consumir esporte.</p>
                        <ul>
                            <li>Presença no ecossistema</li>
                            <li>Conteúdo conectado a provas</li>
                            <li>Novas frentes comerciais</li>
                        </ul>
                    </article>

                    <article class="audience-card reveal">
                        <div class="card-index">04</div>
                        <div class="audience-icon"><i class="fa fa-handshake-o" aria-hidden="true"></i></div>
                        <h3>Empresas do setor</h3>
                        <p>Cronometragem, inscrições, turismo, fotografia, serviços e tecnologia podem se aproximar de quem decide.</p>
                        <ul>
                            <li>Conexão com organizadores</li>
                            <li>Integrações operacionais</li>
                            <li>Mais oportunidades B2B</li>
                        </ul>
                    </article>
                </div>
            </div>
        </section>

        <section class="platform-intro section section-dark" id="solucoes">
            <div class="container platform-intro-layout">
                <div class="platform-copy reveal">
                    <span class="kicker">Muito além de um painel</span>
                    <h2>O centro de comando do seu negócio na corrida.</h2>
                    <p>
                        O Run Pro reúne as ferramentas do dia a dia e conecta seu trabalho às plataformas que o corredor já usa para descobrir provas, acompanhar resultados e viver o esporte.
                    </p>
                    <a class="inline-link" href="/cadastro/">
                        Leve sua operação para o Run Pro
                        <i class="fa fa-arrow-right" aria-hidden="true"></i>
                    </a>
                </div>

                <div class="platform-map reveal">
                    <div class="map-center">
                        <img src="/lib/images/runpro.svg" alt="Run Pro"/>
                        <small>Seu negócio conectado</small>
                    </div>
                    <div class="map-node map-node-one"><i class="fa fa-calendar" aria-hidden="true"></i><span>Eventos</span></div>
                    <div class="map-node map-node-two"><i class="fa fa-bullhorn" aria-hidden="true"></i><span>Mídia</span></div>
                    <div class="map-node map-node-three"><i class="fa fa-users" aria-hidden="true"></i><span>Relacionamento</span></div>
                    <div class="map-node map-node-four"><i class="fa fa-database" aria-hidden="true"></i><span>Dados</span></div>
                    <div class="map-node map-node-five"><i class="fa fa-newspaper-o" aria-hidden="true"></i><span>Conteúdo</span></div>
                </div>
            </div>

            <div class="container capability-grid">
                <article class="capability-card capability-card-large reveal">
                    <span class="capability-number">01</span>
                    <div class="capability-icon"><i class="fa fa-calendar-check-o" aria-hidden="true"></i></div>
                    <h3>Gestão de eventos</h3>
                    <p>Organize seu portfólio e mantenha cada prova pronta para ser encontrada e escolhida.</p>
                    <div class="feature-tags">
                        <span>Cadastro e edição</span>
                        <span>Status e pendências</span>
                        <span>Datas e modalidades</span>
                        <span>Organizador e local</span>
                        <span>Links de inscrição</span>
                    </div>
                </article>

                <article class="capability-card reveal">
                    <span class="capability-number">02</span>
                    <div class="capability-icon"><i class="fa fa-map-o" aria-hidden="true"></i></div>
                    <h3>Percursos</h3>
                    <p>Gerencie mapas e informações de rota para transformar o trajeto em parte da experiência da prova.</p>
                    <ul class="check-list">
                        <li>Mapas e geometria do percurso</li>
                        <li>Importação e exportação</li>
                        <li>Integrações com plataformas esportivas</li>
                    </ul>
                </article>

                <article class="capability-card reveal">
                    <span class="capability-number">03</span>
                    <div class="capability-icon"><i class="fa fa-file-text-o" aria-hidden="true"></i></div>
                    <h3>Conteúdo que converte</h3>
                    <p>Apresente sua corrida com a informação que o atleta precisa para decidir e se inscrever.</p>
                    <ul class="check-list">
                        <li>Descrição, categorias e imagens</li>
                        <li>Organizador, inscrição e localização</li>
                        <li>Checklist de qualidade do conteúdo</li>
                    </ul>
                </article>

                <article class="capability-card capability-card-accent reveal">
                    <span class="capability-number">04</span>
                    <div class="capability-icon"><i class="fa fa-rocket" aria-hidden="true"></i></div>
                    <h3>Marketing e mídia</h3>
                    <p>Coloque sua mensagem no caminho de quem já está procurando a próxima corrida.</p>
                    <ul class="check-list">
                        <li>Eventos Turbinados com gestão de verba</li>
                        <li>Banners, campanhas e notificações</li>
                        <li>Cupons de desconto e ativações</li>
                    </ul>
                </article>

                <article class="capability-card reveal">
                    <span class="capability-number">05</span>
                    <div class="capability-icon"><i class="fa fa-address-card-o" aria-hidden="true"></i></div>
                    <h3>Relacionamento e CRM</h3>
                    <p>Estruture bases, participações e históricos para entender jornadas e criar novas conversas.</p>
                    <ul class="check-list">
                        <li>Importação de dados operacionais</li>
                        <li>Histórico de participações</li>
                        <li>Segmentação para relacionamento</li>
                    </ul>
                </article>

                <article class="capability-card reveal">
                    <span class="capability-number">06</span>
                    <div class="capability-icon"><i class="fa fa-trophy" aria-hidden="true"></i></div>
                    <h3>Desafios e experiências</h3>
                    <p>Amplie o ciclo de engajamento com rankings, circuitos, validações e experiências conectadas.</p>
                    <ul class="check-list">
                        <li>Desafios e circuitos</li>
                        <li>Rankings e validações</li>
                        <li>Ações especiais para comunidades</li>
                    </ul>
                </article>

                <article class="capability-card capability-card-wide reveal">
                    <span class="capability-number">07</span>
                    <div class="capability-icon"><i class="fa fa-share-alt" aria-hidden="true"></i></div>
                    <div>
                        <h3>Distribuição, canais e audiência</h3>
                        <p>
                            Conecte provas, resultados, vídeos, notícias e marcas ao ecossistema RunnerHub. O Run Pro aproxima a operação B2B das experiências públicas do Road Runners e do Open Results.
                        </p>
                    </div>
                    <div class="distribution-flow" aria-label="Fluxo de distribuição">
                        <span>Run Pro</span>
                        <i class="fa fa-long-arrow-right" aria-hidden="true"></i>
                        <span>Road Runners</span>
                        <i class="fa fa-long-arrow-right" aria-hidden="true"></i>
                        <span>Corredores</span>
                    </div>
                </article>

                <article class="capability-card reveal">
                    <span class="capability-number">08</span>
                    <div class="capability-icon"><i class="fa fa-users" aria-hidden="true"></i></div>
                    <h3>Conta e equipe</h3>
                    <p>Reúna eventos e usuários na mesma conta Business, com contexto operacional compartilhado.</p>
                    <ul class="check-list">
                        <li>Gestão de contas e usuários</li>
                        <li>Eventos vinculados à empresa</li>
                        <li>Suporte dentro da plataforma</li>
                    </ul>
                </article>
            </div>
        </section>

        <section class="intelligence section" id="inteligencia">
            <div class="container intelligence-layout">
                <div class="intelligence-visual reveal">
                    <div class="bi-panel">
                        <div class="bi-panel-header">
                            <span>Run Pro Intelligence</span>
                            <span class="coming-badge">Em evolução</span>
                        </div>
                        <div class="bi-metrics">
                            <div>
                                <small>Participação</small>
                                <strong>Tendências</strong>
                                <span class="sparkline sparkline-one"></span>
                            </div>
                            <div>
                                <small>Audiência</small>
                                <strong>Perfis</strong>
                                <span class="sparkline sparkline-two"></span>
                            </div>
                            <div>
                                <small>Engajamento</small>
                                <strong>Retenção</strong>
                                <span class="sparkline sparkline-three"></span>
                            </div>
                        </div>
                        <div class="bi-chart">
                            <span style="--bar: 38%"></span>
                            <span style="--bar: 58%"></span>
                            <span style="--bar: 46%"></span>
                            <span style="--bar: 72%"></span>
                            <span style="--bar: 65%"></span>
                            <span style="--bar: 88%"></span>
                            <span style="--bar: 80%"></span>
                        </div>
                        <div class="bi-axis"><span>Histórico</span><span>Próximas decisões</span></div>
                    </div>
                    <div class="data-ribbon">
                        <span>Operação</span>
                        <i></i>
                        <span>Audiência</span>
                        <i></i>
                        <span>Marketing</span>
                        <i></i>
                        <span>Resultado</span>
                    </div>
                </div>

                <div class="intelligence-copy reveal">
                    <span class="kicker">O BI agora mora no Run Pro</span>
                    <h2>O Run BI deixa de ser um produto separado.</h2>
                    <p class="intelligence-lead">
                        A inteligência de negócios será implementada dentro do Run Pro, conectada às ferramentas que já fazem a operação acontecer.
                    </p>
                    <p>
                        Em vez de olhar dados isolados, o objetivo é transformar informações de eventos, audiência, participação, conteúdo e campanhas em uma camada única para planejamento e decisão.
                    </p>

                    <div class="intelligence-benefits">
                        <div>
                            <i class="fa fa-pie-chart" aria-hidden="true"></i>
                            <span><strong>Visão integrada</strong> de participação, perfil e performance.</span>
                        </div>
                        <div>
                            <i class="fa fa-refresh" aria-hidden="true"></i>
                            <span><strong>Histórico e recorrência</strong> para entender evolução e retenção.</span>
                        </div>
                        <div>
                            <i class="fa fa-lightbulb-o" aria-hidden="true"></i>
                            <span><strong>Insights acionáveis</strong> para operação, comunicação e patrocínio.</span>
                        </div>
                    </div>

                    <div class="roadmap-note">
                        <i class="fa fa-info-circle" aria-hidden="true"></i>
                        <p><strong>Importante:</strong> o módulo de Business Intelligence está em desenvolvimento e será disponibilizado gradualmente dentro do Run Pro.</p>
                    </div>
                </div>
            </div>
        </section>

        <section class="outcomes section">
            <div class="container">
                <div class="section-heading reveal">
                    <span class="kicker">Do trabalho ao resultado</span>
                    <h2>Menos pontas soltas. Mais valor em cada etapa.</h2>
                </div>

                <div class="outcomes-grid">
                    <div class="outcome reveal">
                        <span class="outcome-icon"><i class="fa fa-cogs" aria-hidden="true"></i></span>
                        <div>
                            <small>Operar</small>
                            <h3>Organize a base</h3>
                            <p>Eventos, percursos, inscrições e conteúdo em um fluxo mais claro.</p>
                        </div>
                    </div>
                    <div class="outcome reveal">
                        <span class="outcome-icon"><i class="fa fa-bullhorn" aria-hidden="true"></i></span>
                        <div>
                            <small>Promover</small>
                            <h3>Ganhe relevância</h3>
                            <p>Mídia e distribuição onde o corredor descobre e compara provas.</p>
                        </div>
                    </div>
                    <div class="outcome reveal">
                        <span class="outcome-icon"><i class="fa fa-comments-o" aria-hidden="true"></i></span>
                        <div>
                            <small>Relacionar</small>
                            <h3>Construa recorrência</h3>
                            <p>Históricos, canais e experiências que mantêm a comunidade por perto.</p>
                        </div>
                    </div>
                    <div class="outcome reveal">
                        <span class="outcome-icon"><i class="fa fa-line-chart" aria-hidden="true"></i></span>
                        <div>
                            <small>Decidir</small>
                            <h3>Evolua com dados</h3>
                            <p>Sinais do negócio reunidos para orientar o próximo movimento.</p>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <section class="ecosystem section section-dark" id="ecossistema">
            <div class="container ecosystem-layout">
                <div class="ecosystem-copy reveal">
                    <span class="kicker">Tecnologia RunnerHub</span>
                    <h2>Uma infraestrutura criada por quem vive a corrida.</h2>
                    <p>
                        O Run Pro é a camada de negócios de um ecossistema brasileiro que conecta calendário, conteúdo, resultados, atletas e empresas para desenvolver o esporte de forma inteligente.
                    </p>
                </div>

                <div class="ecosystem-products">
                    <a class="product-card reveal" href="https://roadrunners.run/" target="_blank" rel="noopener noreferrer">
                        <img src="/lib/images/rr.png" alt="Road Runners"/>
                        <p>Descoberta, calendário e planejamento da próxima corrida.</p>
                        <span>Conhecer <i class="fa fa-external-link" aria-hidden="true"></i></span>
                    </a>
                    <a class="product-card reveal" href="https://openresults.run/" target="_blank" rel="noopener noreferrer">
                        <img src="/lib/images/or.png" alt="Open Results"/>
                        <p>Resultados reunidos para tornar a corrida mais acessível e transparente.</p>
                        <span>Conhecer <i class="fa fa-external-link" aria-hidden="true"></i></span>
                    </a>
                    <div class="product-card product-card-runpro reveal">
                        <img src="/lib/images/runpro.svg" alt="Run Pro"/>
                        <p>Operação, promoção, relacionamento e inteligência para o mercado.</p>
                        <span>Você está aqui</span>
                    </div>
                </div>
            </div>
        </section>

        <section class="faq section" id="faq">
            <div class="container faq-layout">
                <div class="faq-heading reveal">
                    <span class="kicker">Perguntas frequentes</span>
                    <h2>Antes de entrar na pista.</h2>
                    <p>Se ainda ficar alguma dúvida, nossa equipe ajuda a encontrar a melhor forma de usar o Run Pro no seu negócio.</p>
                    <a class="inline-link" href="https://wa.me/5548991534589" target="_blank" rel="noopener noreferrer">
                        Falar com a equipe
                        <i class="fa fa-whatsapp" aria-hidden="true"></i>
                    </a>
                </div>

                <div class="faq-list">
                    <details class="reveal">
                        <summary>Para quem é o Run Pro?<span></span></summary>
                        <p>Para organizadores e promotores de eventos, marcas, patrocinadores, canais de conteúdo, agências, fornecedores e outras empresas que atuam no mercado da corrida de rua.</p>
                    </details>
                    <details class="reveal">
                        <summary>O acesso é gratuito?<span></span></summary>
                        <p>O cadastro da empresa e o acesso inicial podem ser solicitados gratuitamente. Algumas soluções de mídia, campanhas, serviços ou módulos poderão ter condições comerciais próprias.</p>
                    </details>
                    <details class="reveal">
                        <summary>Como meus eventos entram no Run Pro?<span></span></summary>
                        <p>Após a aprovação da conta, você pode solicitar o vínculo dos eventos da empresa e administrar as informações disponíveis de acordo com as permissões liberadas.</p>
                    </details>
                    <details class="reveal">
                        <summary>O Run BI ainda existe?<span></span></summary>
                        <p>Não como produto independente. A proposta de Business Intelligence será implementada como um módulo integrado ao Run Pro, aproximando análise e operação.</p>
                    </details>
                    <details class="reveal">
                        <summary>Como minha marca ou canal pode participar?<span></span></summary>
                        <p>Solicite o acesso da empresa e conte à equipe sobre sua atuação. O cadastro será analisado para liberar as funcionalidades e oportunidades adequadas ao seu perfil.</p>
                    </details>
                </div>
            </div>
        </section>

        <section class="final-cta">
            <div class="final-cta-grid" aria-hidden="true"></div>
            <div class="container final-cta-inner">
                <div class="final-cta-copy reveal">
                    <span class="kicker">Sua próxima largada começa aqui</span>
                    <h2>O mercado corre. Seu negócio também pode.</h2>
                    <p>Entre para o ecossistema Run Pro e transforme presença em relacionamento, dados em decisões e corridas em oportunidades.</p>
                </div>
                <div class="final-cta-actions reveal">
                    <a class="button button-primary button-large" href="/cadastro/">
                        Solicitar acesso gratuito
                        <i class="fa fa-arrow-right" aria-hidden="true"></i>
                    </a>
                    <button class="button button-ghost button-large" type="button" data-login-open>Já tenho acesso</button>
                </div>
            </div>
        </section>
    </main>

    <footer class="site-footer">
        <div class="container footer-top">
            <a class="brand footer-brand" href="#inicio" aria-label="Run Pro — voltar ao início">
                <img src="/lib/images/runpro.svg" alt="Run Pro"/>
                <span class="brand-signature" aria-hidden="true">Road Runners <strong>Business</strong></span>
            </a>
            <p>A tecnologia do RunnerHub a serviço de quem faz a corrida acontecer.</p>
            <div class="social-links" aria-label="Redes sociais">
                <a href="https://www.instagram.com/runnerhub.run/" target="_blank" rel="noopener noreferrer" aria-label="Instagram"><i class="fa fa-instagram"></i></a>
                <a href="https://www.linkedin.com/company/runnerhub/" target="_blank" rel="noopener noreferrer" aria-label="LinkedIn"><i class="fa fa-linkedin"></i></a>
                <a href="https://www.facebook.com/runnerhub.run" target="_blank" rel="noopener noreferrer" aria-label="Facebook"><i class="fa fa-facebook"></i></a>
                <a href="https://www.strava.com/clubs/runnerhub" target="_blank" rel="noopener noreferrer" aria-label="Strava"><i class="icon-strava" aria-hidden="true"></i></a>
            </div>
        </div>
        <div class="container footer-bottom">
            <p>© <cfoutput>#year(now())#</cfoutput> RunnerHub. Todos os direitos reservados.</p>
            <div>
                <a href="/faq/">FAQ</a>
                <a href="/suporte/">Suporte</a>
                <a href="https://roadrunners.run/" target="_blank" rel="noopener noreferrer">Road Runners</a>
                <a href="https://openresults.run/" target="_blank" rel="noopener noreferrer">Open Results</a>
            </div>
        </div>
    </footer>

    <a class="whatsapp-float" href="https://wa.me/5548991534589" target="_blank" rel="noopener noreferrer" aria-label="Falar com a equipe pelo WhatsApp">
        <i class="fa fa-whatsapp" aria-hidden="true"></i>
        <span>Fale com a gente</span>
    </a>

    <div class="login-modal" aria-hidden="true" data-login-modal>
        <div class="login-backdrop" data-login-close></div>
        <div class="login-dialog" role="dialog" aria-modal="true" aria-labelledby="login-title">
            <button class="modal-close" type="button" aria-label="Fechar" data-login-close>
                <i class="fa fa-times" aria-hidden="true"></i>
            </button>
            <img class="login-logo" src="/lib/images/runpro.svg" alt="Run Pro"/>
            <span class="login-kicker">Acesso Business</span>
            <h2 id="login-title">Bem-vindo de volta.</h2>
            <p>Entre com o mesmo e-mail Google usado no cadastro aprovado da sua empresa.</p>

            <div class="google-login-wrap">
                <div id="g_id_onload"
                     data-client_id="921450846888-qa9a1alk06v6i0ao4jbiihdfrn8j7528.apps.googleusercontent.com"
                     data-callback="handleCredentialResponse"
                     data-auto_select="false"
                     data-auto_prompt="false">
                </div>
                <div class="g_id_signin"
                     data-type="standard"
                     data-size="large"
                     data-theme="outline"
                     data-text="signin_with"
                     data-shape="rectangular"
                     data-logo_alignment="left"
                     data-width="320">
                </div>
            </div>

            <div class="login-divider"><span>ou</span></div>
            <p class="login-new">Sua empresa ainda não está no Run Pro?</p>
            <a class="button button-primary" href="/cadastro/">Solicitar acesso gratuito</a>
            <small>O cadastro passa por uma análise rápida da equipe RunnerHub.</small>
        </div>
    </div>

    <script>
        (function () {
            var header = document.querySelector("[data-site-header]");
            var menuButton = document.querySelector("[data-menu-toggle]");
            var mainNav = document.querySelector("[data-main-nav]");
            var modal = document.querySelector("[data-login-modal]");
            var loginOpeners = document.querySelectorAll("[data-login-open]");
            var loginClosers = document.querySelectorAll("[data-login-close]");
            var lastFocusedElement = null;

            function updateHeader() {
                if (header) {
                    header.classList.toggle("is-scrolled", window.scrollY > 24);
                }
            }

            function closeMenu() {
                if (!menuButton || !mainNav) return;
                menuButton.setAttribute("aria-expanded", "false");
                mainNav.classList.remove("is-open");
                document.body.classList.remove("menu-open");
            }

            function openLogin(event) {
                if (event) event.preventDefault();
                if (!modal) return;
                lastFocusedElement = document.activeElement;
                modal.classList.add("is-open");
                modal.setAttribute("aria-hidden", "false");
                document.body.classList.add("modal-open");
                var closeButton = modal.querySelector(".modal-close");
                if (closeButton) closeButton.focus();
            }

            function closeLogin() {
                if (!modal) return;
                modal.classList.remove("is-open");
                modal.setAttribute("aria-hidden", "true");
                document.body.classList.remove("modal-open");
                if (lastFocusedElement) lastFocusedElement.focus();
            }

            if (menuButton && mainNav) {
                menuButton.addEventListener("click", function () {
                    var isOpen = menuButton.getAttribute("aria-expanded") === "true";
                    menuButton.setAttribute("aria-expanded", String(!isOpen));
                    mainNav.classList.toggle("is-open", !isOpen);
                    document.body.classList.toggle("menu-open", !isOpen);
                });

                mainNav.querySelectorAll("a").forEach(function (link) {
                    link.addEventListener("click", closeMenu);
                });
            }

            loginOpeners.forEach(function (button) {
                button.addEventListener("click", openLogin);
            });

            loginClosers.forEach(function (button) {
                button.addEventListener("click", closeLogin);
            });

            document.addEventListener("keydown", function (event) {
                if (event.key === "Escape") {
                    closeMenu();
                    closeLogin();
                }
            });

            var revealItems = document.querySelectorAll(".reveal");
            if ("IntersectionObserver" in window && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
                var revealObserver = new IntersectionObserver(function (entries, observer) {
                    entries.forEach(function (entry) {
                        if (entry.isIntersecting) {
                            entry.target.classList.add("is-visible");
                            observer.unobserve(entry.target);
                        }
                    });
                }, { threshold: 0.12 });

                revealItems.forEach(function (item) {
                    revealObserver.observe(item);
                });
            } else {
                revealItems.forEach(function (item) {
                    item.classList.add("is-visible");
                });
            }

            updateHeader();
            window.addEventListener("scroll", updateHeader, { passive: true });

            if (new URLSearchParams(window.location.search).get("login") === "1") {
                openLogin();
            }
        })();

        function handleCredentialResponse(response) {
            if (window.location.search.indexOf("logout=1") >= 0 && response && response.select_by === "auto") {
                return;
            }

            document.cookie = "rr_logged_out=; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; Path=/; SameSite=Lax; Secure";
            var urlRedirect = encodeURIComponent("https://business.roadrunners.run/");
            window.location.href = "https://business.roadrunners.run/?action=googlesignin&redirect=" + urlRedirect + "&credential=" + encodeURIComponent(response.credential);
        }

        function signOut(event) {
            if (event && typeof event.preventDefault === "function") {
                event.preventDefault();
            }

            try {
                if (window.google && google.accounts && google.accounts.id) {
                    google.accounts.id.disableAutoSelect();
                }
            } catch (error) {
                console.warn("Google signOut indisponível, usando logout local.", error);
            }

            window.location.href = "/logout.cfm";
            return false;
        }
    </script>
</body>
</html>
