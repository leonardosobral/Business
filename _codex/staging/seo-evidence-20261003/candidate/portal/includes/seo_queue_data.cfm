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
    Posição curada manualmente; última auditoria em _codex/docs/2026-10-03_seo_evidencias.md.
    Atualizar data, medições e evidências juntas após uma nova conferência.
    Este snapshot não é uma coleta ao vivo nem contém acesso aos relatórios privados.
    Textos e URLs são dados; a view deve aplicar o escape do contexto de saída.
--->
<cfscript>
VARIABLES.seoQueueSnapshot = {
    updatedAt = "2026-10-03T22:29:43.169671+00:00",
    updatedLabel = "03/10/2026 às 19:29 (Brasília)",
    runs = [
        {
            siteId = "roadrunners",
            label = "Road Runners",
            auditLabel = "03/10/2026, 17:12 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 103050,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 1,
            warnings = 22,
            coverageNote = "Foram analisadas 100 de 103.050 URLs descobertas nos sitemaps. A amostra não representa todas as páginas do site. Descoberta completa dos sitemaps; sem nova reconciliação com o banco. Conferências complementares de traduções, logs e audiência têm datas e escopos próprios na aba SEO para IA. A amostra preserva o 404 da notícia retirada e avisos brutos de rotas privadas, canonical na fonte e escapes percentuais. Correções institucionais, da busca e de Maratonas permanecem verificadas."
        },
        {
            siteId = "openresults",
            label = "Open Results",
            auditLabel = "03/10/2026, 19:14 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 34321,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 0,
            warnings = 0,
            coverageNote = "Foram analisadas 100 de 34.321 URLs descobertas nos sitemaps. A amostra não representa todas as páginas do site. Descoberta completa dos sitemaps; sem nova reconciliação com o banco. Conferências complementares de traduções, logs e audiência têm datas e escopos próprios na aba SEO para IA. Rodada realizada após a entrega pública do robots atualizado; noindex das páginas individuais foi conferido separadamente."
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
            resolved = true,
            id = "OR-02",
            sites = ["openresults"],
            priority = "review",
            priorityLabel = "Revisão de política",
            title = "Evitar indexação das páginas individuais de atletas",
            summary = "Páginas individuais /resultados entregam noindex, follow. O cache expirou e o robots público permite sua leitura; /perfil permanece bloqueado.",
            impact = "A estratégia passa a impedir indexação da página individual nos buscadores que respeitam noindex, preservando descoberta das provas. Nomes nas listagens de eventos podem continuar aparecendo; pedidos individuais precisam de atendimento próprio.",
            owner = "OpenResults — conteúdo público e política de rastreamento",
            rule = "Revisão manual de robots.txt por agente",
            evidence = "Política aprovada pelo usuário e publicada no lote anterior. Rechecagem pública em 03/10/2026 confirmou HTTP 200 com noindex em /resultados/ e no acesso direto ao template; home e evento continuam sem noindex. O robots público agora coincide com a origem, sem bloqueio de /resultados para Googlebot ou regra geral, e mantém /perfil bloqueado. Dois hashes e seis dependências de runtime foram preservados. Não foi alterada a Cloudflare neste lote. A remoção efetiva do índice exige nova leitura pelos buscadores e não foi comprovada no Search Console.",
            acceptance = "Concluído no escopo de entrega: noindex nas páginas individuais, robots público atualizado, eventos sem a restrição e dados preservados. A remoção efetiva do índice não foi verificada; pedidos urgentes podem exigir Remoções do Search Console junto à regra permanente. Nomes nas listagens de eventos podem continuar aparecendo.",
            urls = [
                {url = "https://openresults.run/robots.txt", label = "Robots OpenResults"}
            ],
            stateLabel = "Publicado e rechecado em 03/10/2026"
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
            evidence = "Auditorias datadas no painel: Road Runners: 38 eventos avaliados, 37 com lacunas; Open Results: 99 eventos avaliados, 96 com lacunas. Verifica presença de nome, data válida, local e organizador, além de nome/cidade no texto; não comprova exatidão factual. A consulta anterior encontrou organizador nomeado em apenas 1.332 de 34.320 eventos ativos. Não usar cronometrador como organizador nem inferir dados ausentes.",
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
            summary = "Links de idioma ajustados à regra editorial de canonical na fonte. O cadastro do canal ainda tem campos editoriais divergentes.",
            impact = "A atribuição à fonte pode ser intencional; decidir como as versões traduzidas devem participar da indexação antes de mudar o canonical.",
            owner = "RoadRunners — política editorial e atribuição à fonte",
            rule = "canonical.mismatch; hreflang-reciprocity",
            evidence = "A API pública confirma original_url Corrida no Ar e publication_mode=licensed_full para as duas notícias; authorized_republication=false e license_expires_at=null também estão cadastrados. A regra de canonical na fonte foi preservada. O head omite hreflang quando esse canonical difere do próprio, mantendo a navegação de idiomas e o noindex existente de external_only. As seis versões públicas foram verificadas; doze páginas de controle, incluindo as três versões da notícia própria, preservam seus alternates.",
            acceptance = "A coerência técnica dos alternates foi corrigida. Conferir com o responsável editorial o modo de publicação, a autorização cadastrada e a política de canonical/idiomas; só depois alterar a atribuição à fonte. A API não comprova licença de reprodução.",
            urls = [{url = "https://roadrunners.run/noticias/o-que-aconteceu-com-a-nike-no-mundo-da-corrida-e-na-bolsa/", label = "Notícia sobre Nike"}, {url = "https://roadrunners.run/noticias/por-que-ele-trocou-de-camiseta-tantas-vezes-no-podio/", label = "Notícia sobre pódio"}],
            stateLabel = "Alternates corrigidos; cadastro editorial pendente"
        },{
            resolved = true,
            id = "RR-09",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Idiomas",
            title = "Completar hreflang das páginas institucionais em português",
            summary = "Sobre, Ajuda e Privacidade em PT ainda não declaram os links de idioma anunciados pelas versões EN/ES.",
            impact = "A falta de retorno interrompe a reciprocidade dos conjuntos de idioma dessas páginas.",
            owner = "RoadRunners — metadados das páginas institucionais",
            rule = "hreflang-reciprocity",
            evidence = "Sobre, Ajuda e Privacidade identificam a rota também em PT. Testes CFML RED → GREEN cobrem nove destinos, preservando o conteúdo institucional. Publicação conferida em nove URLs públicas: HTTP 200 direto, canonical próprio, PT/EN/ES e x-default; a auditoria posterior confirma reciprocidade aprovada em todas.",
            acceptance = "Identificar a rota no template ou corrigir a identificação compartilhada, preservar o conteúdo institucional e verificar canonical e alternates PT/EN/ES em HTML público.",
            urls = [{url = "https://roadrunners.run/sobre/", label = "Sobre em português"}, {url = "https://roadrunners.run/ajuda/", label = "Ajuda em português"}, {url = "https://roadrunners.run/privacidade/", label = "Privacidade em português"}],
            stateLabel = "Corrigido e rechecado em 03/10/2026"
        }
        ,{
            resolved = true,
            id = "RR-10",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Estrutura",
            title = "Identificar o título principal de Maratonas",
            summary = "O título visível Maratonas do Brasil passou de h3 para h1, preservando a aparência existente.",
            impact = "A página pública passa a identificar o seu título principal depois da correção do slogan compartilhado.",
            owner = "RoadRunners — página de Maratonas",
            rule = "h1.missing",
            evidence = "A auditoria ampliada encontrou HTTP 200 e nenhum H1 em /maratonas/. Teste RED → GREEN verifica o título; a alteração é somente h1 class=h3 e seu fechamento. Publicado e rechecado no HTML público; a auditoria posterior do mesmo snapshot confirma um H1.",
            acceptance = "HTTP 200 direto, canonical próprio e um H1 no HTML público, preservando texto, consultas, filtros, autenticação e aparência.",
            urls = [{url = "https://roadrunners.run/maratonas/", label = "Maratonas do Brasil"}],
            stateLabel = "Corrigido e rechecado em 03/10/2026"
        }
        ,{
            resolved = false,
            id = "RR-11",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Idiomas",
            title = "Concluir a fila de descrições e traduções",
            summary = "A entrega de descrições já é medida em amostra. O cron está pausado e suas últimas falhas indicaram créditos da API esgotados.",
            impact = "Descrições traduzidas ajudam leitores e assistentes a usar o conteúdo no idioma escolhido. O fallback mantém português identificado até haver tradução aprovada.",
            owner = "Business — cron de descrições; Road Runners — entrega de idiomas",
            rule = "Conferência complementar de descrições entregues e fila",
            evidence = "Conferência pública em 03/10/2026: seis eventos em PT/EN/ES, doze versões alvo — 5 com idioma esperado e texto diferente, 1 em português, 6 sem descrição marcada suficiente. Isso não valida fidelidade. Consulta somente de leitura: cron15 inativo, intervalo10min, última execução25/09 às21:14 (horário gravado sem fuso). As cinco últimas execuções retornaram HTTP424 com provider_quota_exhausted; saldo atual da API não foi consultado. A fila existente tem 654 EN e 655 ES prontas; 2497 EN e 257 ES em revisão por rejeição. Há 1535 descrições PT prontas. Não foram consumidos créditos nem removidas rejeições.",
            acceptance = "Esclarecer a pausa e conferir saldo atual antes de retomar o cron. Preservar a revisão de rejeitados e as proteções de fatos; validar uma execução controlada e o texto entregue contra a fonte. Ampliar a cobertura com amostra explícita, sem inferir fidelidade por tamanho ou idioma anotado.",
            urls = [{url = "https://roadrunners.run/en/event/2026-6-rustica-da-assgapa-alusiva-ao-dia-da-forca-aerea/", label = "Descrição com fallback em português"}],
            stateLabel = "Cron pausado; últimas falhas por créditos da API"
        }
    ]
};
</cfscript>
