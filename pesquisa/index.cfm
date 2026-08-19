<!doctype html>
<html lang="pt-br">
<cfprocessingdirective pageencoding="utf-8"/>
<cfparam name="URL.slug" default="assinatura-atletas-2026"/>
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="robots" content="noindex,nofollow"/>
    <title>Entrevista com atletas · Road Runners</title>
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v7.1.0/css/all.css"/>
    <link rel="stylesheet" href="/assets/css/mdb.min.css"/>
    <link rel="stylesheet" href="/assets/plugins/css/all.min.css"/>
    <link rel="stylesheet" href="/administracao/pesquisas/assets/pesquisas.css?v=20260819-1"/>
</head>
<body class="research-public-body">
    <main class="research-public-page" id="researchPublicApp" data-research-slug="<cfoutput>#htmlEditFormat(URL.slug)#</cfoutput>" data-research-api="/pesquisa/api.cfm">
        <div class="research-public-shell">
            <div class="research-survey-frame">
                <header class="research-survey-header">
                    <span class="research-survey-logo">RR</span>
                    <div class="research-survey-progress"><span data-public-progress></span></div>
                    <small data-public-counter></small>
                </header>
                <div class="research-survey-content" data-public-content>
                    <div class="research-public-loading"><i class="fa-solid fa-circle-notch fa-spin"></i><span>Carregando entrevista...</span></div>
                </div>
                <footer class="research-survey-navigation">
                    <button type="button" class="btn btn-link text-secondary" data-public-back disabled><i class="fa-solid fa-arrow-left me-2"></i>Voltar</button>
                    <span class="research-public-secure"><i class="fa-solid fa-lock me-1"></i>Resposta protegida</span>
                </footer>
            </div>
        </div>
    </main>
    <script src="/pesquisa/pesquisa.js?v=20260819-4"></script>
</body>
</html>
