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
    updatedAt = "2026-10-03T18:33:48.927318Z",
    updatedLabel = "03/10/2026 às 15:33 (Brasília)",
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
            coverageNote = "100 páginas auditadas de 34.144 URLs descobertas em quatro lotes válidos. A amostra não cobre todo o acervo. Nenhum erro HTTP foi encontrado; a home estava sem H1 nessa auditoria; a correção focal de 03/10 é registrada na fila. O histórico sinaliza diferenças de configuração ou amostra em relação à base anterior."
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
            resolved = true,
            id = "SH-01",
            sites = ["roadrunners", "openresults"],
            priority = "p3",
            priorityLabel = "P3 · Melhoria de estrutura",
            title = "Revisar hierarquia de títulos",
            summary = "A busca Road Runners e a home OpenResults receberam título principal. O texto promocional da busca compartilhada passou a ser parágrafo nas páginas internas.",
            impact = "Oportunidade de melhorar estrutura e acessibilidade. A contagem isolada não impõe alteração nem prova penalidade de ranking.",
            owner = "RoadRunners — templates; OpenResults — home",
            rule = "h1.multiple; h1.missing",
            evidence = "Rechecagem focal em 03/10/2026: 13 páginas públicas retornaram HTTP 200 e um H1 principal coerente — home, busca, evento e notícia Road Runners em PT/EN/ES, além da home OpenResults. No evento e na notícia, o título principal descreve o conteúdo; o slogan do bloco de busca não disputa esse papel. O OpenResults mantém o tamanho visual de sua introdução. Conferência de apresentação e título acessível no desktop e celular; teste CFML cobre 12 combinações de template e idioma. A amostra geral de 29/09 não foi refeita.",
            acceptance = "Concluído nos templates e casos rechecados. Formulário e seletor de estado preservados; compilação Adobe e conferência do HTML real após publicação. Outros templates e resultados de ranking não são comprovados por este lote.",
            urls = [
                {url = "https://openresults.run/", label = "Home OpenResults"},
                {url = "https://roadrunners.run/busca/", label = "Busca RoadRunners"},
                {url = "https://roadrunners.run/noticias/gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio/", label = "Notícia RoadRunners conferida"}
            ],
            stateLabel = "Corrigido e rechecado em 03/10/2026"
        },
        {
            resolved = false,
            id = "OR-02",
            sites = ["openresults"],
            priority = "review",
            priorityLabel = "Revisão de política",
            title = "Evitar indexação das páginas individuais de atletas",
            summary = "As páginas individuais /resultados recebem noindex, follow. O robots permite lê-lo, enquanto eventos e sitemaps continuam indexáveis; /perfil segue bloqueado.",
            impact = "A estratégia passa a impedir indexação da página individual nos buscadores que respeitam noindex, preservando descoberta das provas. Nomes nas listagens de eventos podem continuar aparecendo; pedidos individuais precisam de atendimento próprio.",
            owner = "OpenResults — conteúdo público e política de rastreamento",
            rule = "Revisão manual de robots.txt por agente",
            evidence = "Decisão explícita em 03/10/2026: evitar exposição de históricos individuais com nomes, mantendo resultados nas listagens de eventos. O usuário aprovou noindex após esclarecer que robots não garante desindexação. A tag noindex, follow foi publicada no head somente do template /resultados/ e validada no HTML público, inclusive no acesso direto ao template. Só depois dessa conferência o robots deixou de bloquear /resultados, permitindo ler a instrução. /perfil permanece bloqueado. Sete casos CFML verificaram a separação de templates; sessenta casos do interpretador local verificaram as regras por agente. A origem já contém a nova política, mas a borda Cloudflare ainda entrega o robots anterior com /resultados bloqueado, em cache HIT com TTL de uma hora. A conclusão aguarda limpeza ou expiração desse cache. O Google ainda precisa rastrear as páginas para aplicar a remoção; não foi verificado o índice privado do Search Console.",
            acceptance = "Noindex publicado e conferido; a entrega pública da política nova de robots está pendente de atualização do cache: páginas individuais públicas com noindex, páginas de eventos sem essa restrição, robots acessível e sitemap sem páginas de histórico pessoal. Dados e acesso preservados. A remoção efetiva do índice depende de nova leitura pelos buscadores; para pedidos urgentes, avaliar Remoções do Search Console junto à regra permanente.",
            urls = [
                {url = "https://openresults.run/robots.txt", label = "Robots OpenResults"}
            ],
            stateLabel = "Noindex publicado; cache do robots pendente"
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
            stateLabel = "Seleção corrigida; revisão editorial e cadastro pendentes"
        }
        ,{
            resolved = true,
            id = "RR-06",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Correção técnica",
            title = "Preservar aspas no canonical e nos idiomas do evento",
            summary = "A seleção do organizador no Road Runners publicado foi corrigida para exigir esse papel no evento. A principal lacuna continua no cadastro compartilhado.",
            impact = "Canonical e alternates completos voltam a identificar a mesma página. O JSON-LD também recebe escape seguro do elemento script.",
            owner = "RoadRunners — cabeçalho e metadados do evento",
            rule = "canonical.mismatch; hreflang; JSON-LD",
            evidence = "Publicação e auditoria em 29/09/2026 às 21:13: IX Encontro dos Amigos Correm Pôr do Sol retornou 200 com canonical completo e alternates PT/EN/ES. As 77 páginas com declarações hreflang passaram na verificação básica, sem o aviso anterior. Em 03/10, a rechecagem do runtime identificou seleção do primeiro fornecedor no bloco de organizador; este lote reaplicou a seleção pelo papel 1, com prova de ausência quando há somente cronometragem. A disponibilidade de inscrição continua dependendo de confirmação recente para o link exato, sem inferência pela data.",
            acceptance = "Correção de seleção publicada, sem alterar os cadastros. Completar vínculos e fatos somente com fontes comprovadas; manter consistência do HTML e JSON-LD, status de resultados e acesso existentes. Registrar fonte e data de cada revisão.",
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
