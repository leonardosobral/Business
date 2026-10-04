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
    Posição curada manualmente; última auditoria em _codex/docs/2026-10-03_seo_idiomas.md.
    Atualizar data, medições e evidências juntas após uma nova conferência.
    Este snapshot não é uma coleta ao vivo nem contém acesso aos relatórios privados.
    Textos e URLs são dados; a view deve aplicar o escape do contexto de saída.
--->
<cfscript>
VARIABLES.seoQueueSnapshot = {
    updatedAt = "2026-10-03T19:25:50.789279Z",
    updatedLabel = "03/10/2026 às 16:25 (Brasília)",
    runs = [
        {
            siteId = "roadrunners",
            label = "Road Runners",
            auditLabel = "03/10/2026, 16:21 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 103049,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 1,
            warnings = 12,
            coverageNote = "Foram analisadas 100 de 103.049 URLs descobertas nos sitemaps. A amostra não representa todas as páginas do site. Descoberta completa dos sitemaps; sem nova reconciliação com o banco. O histórico informa mudança de amostra quando necessário. O 404 observado pertence à notícia retirada editorialmente, ausente do sitemap. A rechecagem também inclui três rotas privadas com login intencional, dois canonicals para fonte externa e um aviso por diferença de caixa nos escapes %0D/%0d. Os achados brutos e a nota técnica permanecem preservados."
        },
        {
            siteId = "openresults",
            label = "Open Results",
            auditLabel = "03/10/2026, 16:05 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 34321,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 0,
            warnings = 0,
            coverageNote = "Foram analisadas 100 de 34.321 URLs descobertas nos sitemaps. A amostra não representa todas as páginas do site. Descoberta completa dos sitemaps; sem nova reconciliação com o banco. O histórico informa mudança de amostra quando necessário."
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
            acceptance = "Concluído nos quatro casos: HTTP 200, evento e canonical corretos nos três idiomas, sem mudar tags ou o cadastro. Teste com Apache real confere caracteres especiais e preserva caminhos sensíveis. A auditoria de 03/10 rechecou Operário com HTTP 200; seu aviso de canonical compara %0D com %0d, equivalentes, e foi mantido como evidência da regra legada.",
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
            evidence = "A correção de barras permanece validada. A nova auditoria de 03/10 incluiu a notícia de Gleison em PT/EN/ES, com canonical próprio e conjuntos hreflang recíprocos. Duas outras notícias continuam declarando a fonte Corrida no Ar como canonical externo; a intenção editorial foi separada no item RR-08, sem atribuir esse comportamento ao defeito de barras corrigido.",
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
            evidence = "Conferência focal de 13 páginas e nova auditoria de 100 páginas por site em 03/10: busca Road Runners e home Open Results entregam H1. O slogan compartilhado é parágrafo nas páginas internas. As três URLs privadas de desafios, fora do sitemap e rechecadas intencionalmente, chegam ao login sem H1 e continuam gerando avisos brutos; não desfazem a correção dos templates públicos. Desktop, celular, compilação e teste CFML da estrutura foram verificados no lote anterior.",
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
            summary = "As páginas individuais /resultados recebem noindex, follow. O robots correto está na origem, mas a Cloudflare ainda entrega a versão antiga com bloqueio; /perfil permanece bloqueado.",
            impact = "A estratégia passa a impedir indexação da página individual nos buscadores que respeitam noindex, preservando descoberta das provas. Nomes nas listagens de eventos podem continuar aparecendo; pedidos individuais precisam de atendimento próprio.",
            owner = "OpenResults — conteúdo público e política de rastreamento",
            rule = "Revisão manual de robots.txt por agente",
            evidence = "Decisão explícita em 03/10/2026: evitar exposição de históricos individuais com nomes, mantendo resultados nas listagens de eventos. O usuário aprovou noindex após esclarecer que robots não garante desindexação. A tag noindex, follow foi publicada no head somente do template /resultados/ e validada no HTML público, inclusive no acesso direto ao template. Só depois dessa conferência o robots deixou de bloquear /resultados, permitindo ler a instrução. /perfil permanece bloqueado. Sete casos CFML verificaram a separação de templates; sessenta casos do interpretador local verificaram as regras por agente. A origem já contém a nova política, mas a borda Cloudflare ainda entrega o robots anterior com /resultados bloqueado, em cache HIT. O cabeçalho anuncia max-age=3600, mas a versão antiga continuou com Age superior a 3600; isso não confirma o TTL efetivo da borda. A conclusão aguarda limpeza ou expiração efetiva desse cache. O Google ainda precisa rastrear as páginas para aplicar a remoção; não foi verificado o índice privado do Search Console.",
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
            stateLabel = "Retirada editorial confirmada; ausência no sitemap verificada"
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
            evidence = "Auditoria de 03/10: 42 páginas de eventos Road Runners, com 41 casos que pedem revisão dos campos; 99 eventos Open Results, com 96 casos que pedem revisão. A checagem cobre nome, data válida, local e organizador, além de nome/cidade no texto, sem comprovar exatidão factual. O cadastro compartilhado consultado no lote anterior tem 34.320 eventos ativos, dos quais 1.332 possuem organizador nomeado nesse papel. Não usar cronometrador como organizador nem inferir dados ausentes.",
            acceptance = "Conferir os dados com fontes dos organizadores; completar somente informação comprovada e exibi-la de forma coerente em cada idioma. Manter indicação de resultado em processamento/indisponível e acesso existente. Registrar fonte e data da revisão.",
            urls = [{url = "https://roadrunners.run/evento/2026-maratona-salvador-2026/", label = "Evento Road Runners sem vínculo de organizador"}, {url = "https://openresults.run/evento/2026-maratona-salvador-2026/", label = "Evento OpenResults sem vínculo de organizador"}],
            stateLabel = "Revisão editorial e cadastro pendentes"
        }
        ,{
            resolved = true,
            id = "RR-07",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Idiomas",
            title = "Completar hreflang da busca em português",
            summary = "A busca precisa identificar a rota search para emitir os links de idioma também em português.",
            impact = "Permite que PT, EN e ES declarem o mesmo conjunto de alternates e os links de retorno.",
            owner = "RoadRunners — metadados da busca",
            rule = "hreflang-reciprocity",
            evidence = "A auditoria inicial de 03/10 encontrou quatro alternates em EN/ES e nenhum em PT. Uma linha no template identifica a rota, sem alterar filtros ou o bootstrap. Teste CFML falhou antes e passou nos três idiomas após a correção. A rechecagem pública e o snapshot após publicação registram o resultado real.",
            acceptance = "HTTP 200, canonical próprio, os três idiomas e x-default em todas as versões; termos e filtro de estado preservados. O teste de reciprocidade não comprova tradução do conteúdo.",
            urls = [{url = "https://roadrunners.run/busca/", label = "Busca em português"}, {url = "https://roadrunners.run/en/search/", label = "Busca em inglês"}, {url = "https://roadrunners.run/es/busqueda/", label = "Busca em espanhol"}],
            stateLabel = "Corrigido e rechecado em 03/10/2026"
        },{
            resolved = false,
            id = "RR-08",
            sites = ["roadrunners"],
            priority = "review",
            priorityLabel = "Revisão editorial",
            title = "Conferir canonical externo nas notícias traduzidas",
            summary = "Duas notícias apontam para a fonte Corrida no Ar enquanto declaram versões próprias de idioma.",
            impact = "A atribuição à fonte pode ser intencional; decidir como as versões traduzidas devem participar da indexação antes de mudar o canonical.",
            owner = "RoadRunners — política editorial e atribuição à fonte",
            rule = "canonical.mismatch; hreflang-reciprocity",
            evidence = "Amostra de 03/10: os artigos sobre Nike e sobre trocas de camiseta no pódio declaram canonical externo e alternates próprios. O novo check aponta atenção para esse conjunto. A intenção editorial e os termos de reprodução não foram confirmados; os metadados foram preservados.",
            acceptance = "Conferir política e fonte, escolher canonical e alternates coerentes com essa intenção e validar as versões entregues. Não substituir canonical externo automaticamente.",
            urls = [{url = "https://roadrunners.run/noticias/o-que-aconteceu-com-a-nike-no-mundo-da-corrida-e-na-bolsa/", label = "Notícia sobre Nike"}, {url = "https://roadrunners.run/noticias/por-que-ele-trocou-de-camiseta-tantas-vezes-no-podio/", label = "Notícia sobre pódio"}],
            stateLabel = "Intenção editorial pendente de conferência"
        },{
            resolved = false,
            id = "RR-09",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Idiomas",
            title = "Completar hreflang das páginas institucionais em português",
            summary = "Sobre, Ajuda e Privacidade em PT ainda não declaram os links de idioma anunciados pelas versões EN/ES.",
            impact = "A falta de retorno interrompe a reciprocidade dos conjuntos de idioma dessas páginas.",
            owner = "RoadRunners — metadados das páginas institucionais",
            rule = "hreflang-reciprocity",
            evidence = "Na auditoria final de 03/10, as páginas PT entregaram HTML utilizável sem alternates; as versões EN/ES inspecionadas declaram essas URLs em seus conjuntos. Seis páginas EN/ES pedem atenção por falta de retorno em PT. A correção da busca foi revalidada separadamente e não resolve essas outras rotas.",
            acceptance = "Identificar a rota no template ou corrigir a identificação compartilhada, preservar o conteúdo institucional e verificar canonical e alternates PT/EN/ES em HTML público.",
            urls = [{url = "https://roadrunners.run/sobre/", label = "Sobre em português"}, {url = "https://roadrunners.run/ajuda/", label = "Ajuda em português"}, {url = "https://roadrunners.run/privacidade/", label = "Privacidade em português"}],
            stateLabel = "Reciprocidade incompleta; correção pendente"
        }
    ]
};
</cfscript>
