<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="403" statustext="Forbidden"/>
    <cfabort/>
</cfif>
<cfif structKeyExists(CGI, "request_method") AND compareNoCase(CGI.request_method, "GET") NEQ 0>
    <cfheader statuscode="405" statustext="Method Not Allowed"/>
    <cfheader name="Allow" value="GET"/>
    <cfabort/>
</cfif>

<!---
    Posição curada manualmente a partir de _codex/docs/2026-09-13_seo_piloto_fila.md.
    Atualizar data, medições e evidências juntas após uma nova conferência.
    Este snapshot não é uma coleta ao vivo nem contém acesso aos relatórios privados.
    Textos e URLs são dados; a view deve aplicar o escape do contexto de saída.
--->
<cfscript>
VARIABLES.seoQueueSnapshot = {
    updatedAt = "2026-09-14T04:48:30.522Z",
    updatedLabel = "14/09/2026 às 01:48 (Brasília)",
    runs = [
        {
            siteId = "roadrunners",
            label = "Road Runners",
            auditLabel = "13/09/2026 às 21:26 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 99360,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 1,
            warnings = 111,
            coverageNote = "Cadastro reconciliado: 33.095 eventos ativos em três idiomas, totalizando 99.285 URLs de eventos, mais 75 outras páginas. O sitemap inclui 30.339 eventos históricos e 2.756 futuros/recentes. Apenas 100 páginas tiveram o HTML analisado. Estes números são da auditoria das 21:26; as correções posteriores estão registradas na fila abaixo."
        },
        {
            siteId = "openresults",
            label = "Open Results",
            auditLabel = "13/09/2026 às 15:25 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 33096,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 0,
            warnings = 2,
            coverageNote = "100 páginas auditadas de 33.096 URLs descobertas em quatro lotes válidos. A amostra não cobre todo o acervo. Estes números são da auditoria das 15:25; as correções posteriores estão registradas na fila abaixo."
        }
    ],
    items = [
        {
            resolved = false,
            id = "RR-01",
            sites = ["roadrunners"],
            priority = "p1",
            priorityLabel = "P1 · Alta",
            title = "Corrigir rotas e canonicals de eventos com tags especiais",
            summary = "A descoberta foi recuperada. Algumas tags ainda produzem páginas bloqueadas ou desvios para a busca e precisam de correção própria.",
            impact = "O inventário agora mostra essas URLs, mas isso não garante que o evento possa ser acessado ou tenha canonical correto.",
            owner = "RoadRunners — manutenção das rotas e dos identificadores de eventos",
            rule = "http.error / http.redirect / canonical.mismatch",
            evidence = "Sitemaps agora codificam as tags sem perder caracteres. A nova amostra encontrou HTTP 403 em Operário Night Run, cuja tag contém CR/LF. A conferência adicional confirmou 403 nas três variantes de Rock n Run e desvios para a busca nas duas tags Atibaia com %23. Outro evento da amostra declarou canonical truncado por aspas na tag. O cadastro também contém outras tags especiais; a correção da descoberta não encerra a revisão das rotas.",
            acceptance = "Fazer cada URL pública abrir o evento correto e declarar canonical coerente. Tratar mudanças de identificador com plano de compatibilidade e redirects, sem alterar silenciosamente os dados nem contornar proteções HTTP.",
            urls = [
                {url = "https://roadrunners.run/sitemaps/events-upcoming-1.xml", label = "Sitemap de eventos futuros"},
                {url = "https://roadrunners.run/es/evento/2026-operario%0D%0Anight%0D%0Arun/", label = "Evento com HTTP 403 na nova amostra"}
            ],
            stateLabel = "Descoberta corrigida · rotas pendentes"
        },
        {
            resolved = true,
            id = "RR-02",
            sites = ["roadrunners"],
            priority = "p1",
            priorityLabel = "P1 · Alta",
            title = "Recuperar a entrega dos lotes históricos",
            summary = "A montagem do XML foi corrigida e os três lotes históricos passaram a concluir dentro do limite de 15 segundos.",
            impact = "A descoberta passou de 1.090 URLs parciais para 99.360 URLs, com os eventos ativos reconciliados com o cadastro nos três idiomas.",
            owner = "RoadRunners — sitemap e infraestrutura de entrega",
            rule = "TIMEOUT — corrigido",
            evidence = "Antes, os lotes históricos 1 e 2 falharam mesmo com 45 segundos. Após a publicação, chegaram em 1,55 s e 1,00 s, incluindo espera do limitador de taxa. A nova auditoria obteve os sete sitemaps sem falhas operacionais. As tags de 33.095 eventos coincidiram com o banco em PT, EN e ES.",
            acceptance = "Concluído nesta rodada: XML válido, todos os filhos dentro de 15 segundos e conjuntos de eventos reconciliados. Manter a verificação nas próximas auditorias.",
            urls = [
                {url = "https://roadrunners.run/sitemaps/events-history-1.xml", label = "Sitemap histórico — lote 1"},
                {url = "https://roadrunners.run/sitemaps/events-history-2.xml", label = "Sitemap histórico — lote 2"}
            ],
            stateLabel = "Corrigido e verificado em produção"
        },
        {
            resolved = true,
            id = "RR-03",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Correção técnica",
            title = "Normalizar canonical das notícias",
            summary = "Canonical e alternates das notícias passaram a usar a tag normalizada, com uma única barra final.",
            impact = "As URLs declaradas no HTML agora apontam para a mesma notícia e mantêm o idioma correspondente.",
            owner = "RoadRunners — conteúdo editorial e metadados da rota",
            rule = "canonical.mismatch",
            evidence = "Verificação em 14/09/2026 às 01:48 (Brasília): 12 notícias conferidas, incluindo nove variantes de acesso em PT, EN e ES, com e sem barra e com parâmetro de campanha. Canonical e quatro alternates corretos em todos os casos. As três listagens com page=2 preservaram seus canonicals.",
            acceptance = "Concluído: canonical absoluto com uma barra final e alternates coerentes. Testes CFML também verificaram canais e paginação; os templates foram compilados antes da publicação.",
            urls = [
                {url = "https://roadrunners.run/noticias/gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio/", label = "Notícia de Gleison em Maceió"}
            ],
            stateLabel = "Corrigido e verificado em produção"
        },
        {
            resolved = true,
            id = "OR-01",
            sites = ["openresults"],
            priority = "p2",
            priorityLabel = "P2 · Correção técnica",
            title = "Codificar a tag no canonical do evento",
            summary = "A tag do evento passou a ser codificada como segmento da URL, com escape dos atributos HTML.",
            impact = "O ponto de interrogação agora permanece dentro do identificador do evento, sem virar query string no canonical.",
            owner = "OpenResults — metadados da página de evento",
            rule = "canonical.mismatch",
            evidence = "Verificação em 14/09/2026 às 01:48 (Brasília): Atleta de Cristo Run retornou HTTP 200 e canonical com %3F. Outros dois eventos e a home preservaram seus canonicals. Testes CFML cobriram pontuação, aspas, espaços, acentos, percentuais e atributos HTML de canonical e redes sociais.",
            acceptance = "Concluído: tag bruta codificada uma única vez, sem query ou fragmento acidental; canonical absoluto e atributos HTML válidos. Compilação e conferência pública aprovadas.",
            urls = [
                {url = "https://openresults.run/evento/2026-venha-viver-a-2-atleta-de-cristo-run-correndo-com-proposito%3F/", label = "Atleta de Cristo Run"}
            ],
            stateLabel = "Corrigido e verificado em produção"
        },
        {
            resolved = true,
            id = "RR-04",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Correção técnica",
            title = "Retirar destinos privados do sitemap público",
            summary = "As três rotas de desafios que levam ao login foram retiradas do sitemap público.",
            impact = "O sitemap estático deixou de anunciar esses destinos privados. A exigência de login permanece preservada.",
            owner = "RoadRunners — seleção do sitemap; autenticação com o dono da rota",
            rule = "http.redirect; canonical.mismatch",
            evidence = "Verificação em 14/09/2026 às 01:48 (Brasília): o sitemap estático passou de 52 para 49 URLs, removendo exclusivamente /desafios/, /en/challenges/ e /es/desafios/. As três URLs continuam retornando o mesmo redirecionamento HTTP 302 para login.",
            acceptance = "Concluído: XML válido, conjunto anterior menos os três destinos privados e comportamento de autenticação preservado.",
            urls = [
                {url = "https://roadrunners.run/desafios/", label = "Desafios — português"},
                {url = "https://roadrunners.run/en/challenges/", label = "Desafios — inglês"},
                {url = "https://roadrunners.run/es/desafios/", label = "Desafios — espanhol"}
            ],
            stateLabel = "Corrigido e verificado em produção"
        },
        {
            resolved = false,
            id = "SH-01",
            sites = ["roadrunners", "openresults"],
            priority = "p3",
            priorityLabel = "P3 · Melhoria de estrutura",
            title = "Revisar hierarquia de títulos",
            summary = "Revisar os títulos das páginas sem aplicar uma correção mecânica pela quantidade de H1.",
            impact = "Oportunidade de melhorar estrutura e acessibilidade. A contagem isolada não impõe alteração nem prova penalidade de ranking.",
            owner = "RoadRunners — templates; OpenResults — home",
            rule = "h1.multiple; h1.missing",
            evidence = "Na auditoria RoadRunners das 21:26, 89 avisos indicam H1 múltiplos e três indicam H1 ausente. O H1 promocional se soma ao título da página, e uma notícia pode ter três H1. A home do OpenResults não possui H1 no HTML recebido.",
            acceptance = "Conferir se os títulos descrevem a página e se a hierarquia faz sentido. Eventuais ajustes devem preservar o visual pretendido e passar por verificação de acessibilidade, desktop e celular.",
            urls = [
                {url = "https://openresults.run/", label = "Home OpenResults"},
                {url = "https://roadrunners.run/busca/", label = "Busca RoadRunners"},
                {url = "https://roadrunners.run/noticias/gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio/", label = "Notícia RoadRunners conferida"}
            ],
            stateLabel = "Pendente de revisão"
        },
        {
            resolved = false,
            id = "OR-02",
            sites = ["openresults"],
            priority = "review",
            priorityLabel = "Revisão de política",
            title = "Conferir intenção da política Googlebot",
            summary = "O grupo específico Googlebot não herda as restrições publicadas no grupo geral.",
            impact = "Há diferença de acesso entre agentes, sem prova de que seja acidental. Robots não substitui controle de acesso; as páginas públicas da amostra estavam permitidas.",
            owner = "OpenResults — conteúdo público e política de rastreamento",
            rule = "Revisão manual de robots.txt por agente",
            evidence = "O grupo Googlebot contém apenas Disallow: /nogooglebot/. As restrições /perfil e /resultados aparecem somente no grupo *. O grupo específico não herda essas regras.",
            acceptance = "Documentar a intenção por caminho e agente antes de alinhar e testar as regras. Não alterar automaticamente política de treinamento de IA nem acesso autenticado.",
            urls = [
                {url = "https://openresults.run/robots.txt", label = "Robots OpenResults"}
            ],
            stateLabel = "Aguardando decisão de política"
        }
    ]
};
</cfscript>
