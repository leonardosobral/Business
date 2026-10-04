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
    Posição curada manualmente; última auditoria em _codex/docs/2026-09-29_seo_auditoria.md.
    Atualizar data, medições e evidências juntas após uma nova conferência.
    Este snapshot não é uma coleta ao vivo nem contém acesso aos relatórios privados.
    Textos e URLs são dados; a view deve aplicar o escape do contexto de saída.
--->
<cfscript>
VARIABLES.seoQueueSnapshot = {
    updatedAt = "2026-10-03T17:09:58.529789Z",
    updatedLabel = "03/10/2026 às 14:09 (Brasília)",
    runs = [
        {
            siteId = "roadrunners",
            label = "Road Runners",
            auditLabel = "29/09/2026 às 21:13 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 102509,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 2,
            warnings = 99,
            coverageNote = "Descoberta completa: 102.509 URLs nos sitemaps, incluindo 95.043 URLs nos lotes históricos de eventos. Foram analisadas 100 páginas, com prioridade para rechecagem de pendências. O teto do inventário é de 150 mil URLs; o coletor agora mede metadados adicionais, portanto a comparação histórica sinaliza mudança de método ou cobertura. Não houve nova reconciliação com o banco."
        },
        {
            siteId = "openresults",
            label = "Open Results",
            auditLabel = "29/09/2026 às 21:13 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 34144,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 0,
            warnings = 1,
            coverageNote = "100 páginas auditadas de 34.144 URLs descobertas em quatro lotes válidos. A amostra não cobre todo o acervo. Nenhum erro HTTP foi encontrado; a home continua sem H1. O histórico sinaliza diferenças de configuração ou amostra em relação à base anterior."
        }
    ],
    items = [
        {
            resolved = true,
            id = "RR-01",
            sites = ["roadrunners"],
            priority = "p1",
            priorityLabel = "P1 · Alta",
            title = "Preservar caracteres especiais nas rotas de eventos",
            summary = "As rotas passaram a codificar a tag ao repassá-la à consulta interna. Identificadores e dados dos eventos foram preservados.",
            impact = "Eventos antes bloqueados por 403 ou desviados à busca passam a abrir a página correta nos três idiomas.",
            owner = "RoadRunners — manutenção das rotas e dos identificadores de eventos",
            rule = "http.error / http.redirect / canonical.mismatch — corrigidos nos casos rechecados",
            evidence = "Rechecagem focal em 03/10/2026: o cadastro confirmou as tags de Operário Night Run, Rock N Run Nashville e das duas provas Atibaia. A origem reproduziu os erros; o Apache registrou AH10411 por consulta interna com caracteres sem escape. As regras agora codificam os identificadores, e os parâmetros usados para construir canonical e links de idioma recebem codificação de URL uma única vez. As URLs dos quatro eventos foram conferidas em português, inglês e espanhol após a publicação, com HTTP 200 e canonical coerente.",
            acceptance = "Concluído nos quatro casos: HTTP 200, evento e canonical corretos nos três idiomas, sem mudar tags ou o cadastro. Teste com Apache real também confere caracteres especiais e mantém as restrições de caminhos sensíveis. As medições gerais do relatório permanecem datadas de 29/09.",
            urls = [
                {url = "https://roadrunners.run/sitemaps/events-upcoming-1.xml", label = "Sitemap de eventos futuros"},
                {url = "https://roadrunners.run/es/evento/2026-operario%0D%0Anight%0D%0Arun/", label = "Operário Night Run — caso rechecado"}
            ],
            stateLabel = "Corrigido e rechecado em 03/10/2026"
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
            evidence = "Rechecagem em 29/09/2026: índice e sete sitemaps filhos retornaram HTTP 200 e XML válido, sem falhas operacionais. Os três lotes históricos somaram 95.043 URLs; o inventário completo chegou a 102.509 URLs após ampliar o teto do coletor de 100 mil para 150 mil. A reconciliação de 33.095 eventos com o banco pertence à auditoria de 13/09 e não foi repetida nesta rodada.",
            acceptance = "Entrega revalidada nesta rodada: XML válido e todos os filhos concluídos no limite de 15 segundos por recurso. A reconciliação com o cadastro permanece datada de 13/09; manter a verificação da entrega nas próximas auditorias.",
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
            evidence = "A revisão de 14/09 validou 12 notícias e variantes de idioma, barra e parâmetros. Em 29/09, a notícia de Gleison em Maceió e outras notícias rechecadas mantiveram canonical com uma barra final. Dois artigos apontam para a fonte externa Corrida no Ar; isso exige avaliar a intenção editorial e não reproduz o defeito de barra duplicada. Alternates e paginação não foram reavaliados nesta rodada.",
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
            evidence = "Rechecagem em 29/09/2026: Atleta de Cristo Run retornou HTTP 200 e canonical idêntico à URL, preservando %3F dentro da tag. Nenhum aviso de canonical apareceu nas 100 páginas analisadas do Open Results. A bateria CFML de caracteres especiais pertence à validação da publicação de 14/09.",
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
            evidence = "Rechecagem em 29/09/2026: o sitemap estático contém 49 URLs e os três destinos privados continuam ausentes dos sitemaps. Eles entraram na amostra pela rechecagem de pendências antigas e ainda retornam HTTP 302 para login. Esses avisos não indicam que os destinos voltaram ao sitemap nem que a autenticação deva ser removida.",
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
            evidence = "Auditoria de 29/09/2026: Road Runners teve 88 avisos de H1 múltiplos e três de H1 ausente, nas buscas em PT, EN e ES. A home do Open Results continua sem H1 no HTML recebido. H1 múltiplo é revisão editorial e não reduz a nota; H1 ausente gera atenção no critério de título principal.",
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
            evidence = "Robots.txt reconferido em 29/09/2026, com HTTP 200: o grupo Googlebot contém apenas Disallow: /nogooglebot/. As restrições /perfil e /resultados aparecem somente no grupo *. O grupo específico não herda essas regras; a decisão de política continua pendente.",
            acceptance = "Documentar a intenção por caminho e agente antes de alinhar e testar as regras. Não alterar automaticamente política de treinamento de IA nem acesso autenticado.",
            urls = [
                {url = "https://openresults.run/robots.txt", label = "Robots OpenResults"}
            ],
            stateLabel = "Aguardando decisão de política"
        },
        {
            resolved = true,
            id = "RR-05",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Correção técnica",
            title = "Confirmar retirada editorial da notícia histórica",
            summary = "O CMS registra a notícia como rejeitada e não publicada. O HTTP 404 é coerente com esse estado editorial.",
            impact = "O item foi encerrado após conferir o cadastro; a retirada editorial permanece respeitada.",
            owner = "RoadRunners — conteúdo editorial e rotas de notícias",
            rule = "http.error — retirada editorial confirmada",
            evidence = "Rechecagem focal em 03/10/2026: news.tb_content, id 2380, mantém a mesma slug, published=false e editorial_status=rejected, com atualização em 20/09/2026. A URL pública retorna HTTP 404 e continua ausente do sitemap atual. A consulta não encontrou referências a esse endereço no corpo ou resumo de conteúdos publicados; a busca nos arquivos de runtime locais também não encontrou links estáticos. Não foi identificado conteúdo equivalente para redirect.",
            acceptance = "Concluído: estado editorial e ausência no sitemap conferidos; nenhuma republicação, troca de slug ou redirect genérico foi realizada. Links externos e conteúdos não cobertos por essa consulta não foram avaliados.",
            urls = [
                {url = "https://roadrunners.run/noticias/ranking-atualizado-com-maceio-live-inter-j-pessoa-taubate-floripa-goiania-movi-e-vitoria/", label = "Notícia com HTTP 404"}
            ],
            stateLabel = "Retirada editorial conferida em 03/10/2026"
        }
        ,{
            resolved = true,
            id = "RR-06",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Correção técnica",
            title = "Preservar aspas no canonical e nos idiomas do evento",
            summary = "Os atributos de URL passaram a receber escape HTML, preservando identificadores com aspas e ampersand.",
            impact = "Canonical e alternates completos voltam a identificar a mesma página. O JSON-LD também recebe escape seguro do elemento script.",
            owner = "RoadRunners — cabeçalho e metadados do evento",
            rule = "canonical.mismatch; hreflang; JSON-LD",
            evidence = "Publicação e auditoria em 29/09/2026 às 21:13: IX Encontro dos Amigos Correm Pôr do Sol retornou 200 com canonical completo e alternates PT/EN/ES. As 77 páginas com declarações hreflang passaram na verificação básica, sem o aviso anterior. O organizador agora usa o papel 1 no evento; disponibilidade de inscrição deixou de ser inferida pela data.",
            acceptance = "Concluído: atributos preservados, teste CFML com caracteres especiais e script, compilação Adobe e conferência do HTML público. Reciprocidade entre idiomas e tradução integral não são comprovadas pelo check básico.",
            urls = [{url = "https://roadrunners.run/es/evento/2025-ix-encontro-dos-amigos-correm-%22por-do-sol%22/", label = "Evento com aspas — metadados corrigidos"}],
            stateLabel = "Corrigido e verificado em produção"
        },{
            resolved = true,
            id = "OR-03",
            sites = ["openresults"],
            priority = "p2",
            priorityLabel = "P2 · Preparação para IA",
            title = "Publicar dados estruturados dos eventos",
            summary = "As páginas de evento passaram a entregar SportsEvent em JSON-LD com nome, datas, local e organizador quando cadastrado nesse papel.",
            impact = "Os dados do evento podem ser lidos de forma estruturada; não há promessa de citação ou rich result.",
            owner = "OpenResults — evento e cabeçalho",
            rule = "JSON-LD; coerência com conteúdo visível",
            evidence = "Após publicação, 99 páginas de evento na amostra de 100 entregaram JSON-LD válido, sem falha de sintaxe. A home permanece fora desse check. Nome e cidade foram encontrados no HTML; datas de vários dias também aparecem como intervalo visível. O include direto retorna 403.",
            acceptance = "Concluído: dados sustentados pelo cadastro e pelo texto; sem horário, preço, imagem ou disponibilidade inventados. Testes CFML de cancelamento, datas e papel do fornecedor, compilação e HTML público verificados. Validação completa de Schema.org e fatos exige revisão própria.",
            urls = [{url = "https://openresults.run/evento/2026-maratona-salvador-2026/", label = "Evento com resultados e JSON-LD"}],
            stateLabel = "Publicado e verificado em produção"
        },{
            resolved = false,
            id = "SH-02",
            sites = ["roadrunners", "openresults"],
            priority = "p3",
            priorityLabel = "P3 · Qualidade dos dados",
            title = "Completar e conferir fatos dos eventos",
            summary = "A leitura básica de nome, data e cidade avançou. O vínculo de organizador continua ausente em muitos eventos da amostra.",
            impact = "Lacunas dificultam atribuição e respostas precisas. Campo ausente não comprova erro factual nem autoriza adivinhar organizadores.",
            owner = "Business — cadastro; RoadRunners e OpenResults — apresentação pública",
            rule = "Revisão factual; campos de eventos",
            evidence = "Nova amostra: Road Runners apresentou 42 SportsEvent, com nome/data/cidade e 40 lacunas de organizador; OpenResults apresentou 99, com 96 lacunas de organizador. O papel de organização agora é respeitado na marcação. Há eventos futuros, passados e resultados na amostra. Edição, fonte, unidade, cancelamento e traduções precisam de revisão editorial ampliada.",
            acceptance = "Conferir os dados com fontes dos organizadores; completar somente informação comprovada e exibi-la de forma coerente em cada idioma. Manter indicação de resultado em processamento/indisponível e acesso existente. Registrar fonte e data da revisão.",
            urls = [{url = "https://roadrunners.run/evento/2026-maratona-salvador-2026/", label = "Evento Road Runners sem vínculo de organizador"}, {url = "https://openresults.run/evento/2026-maratona-salvador-2026/", label = "Evento OpenResults sem vínculo de organizador"}],
            stateLabel = "Revisão editorial e cadastro pendentes"
        }
    ]
};
</cfscript>
