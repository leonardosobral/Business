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
    updatedAt = "2026-10-04T19:30:42-03:00",
    updatedLabel = "04/10/2026 às 19:30 (Brasília)",
    runs = [
        {
            siteId = "roadrunners",
            label = "Road Runners",
            auditLabel = "04/10/2026, 01:02 (Brasília)",
            completionLabel = "Amostra concluída",
            discoveryComplete = true,
            discovered = 104006,
            inspected = 100,
            operationalErrors = 0,
            pageErrors = 1,
            warnings = 20,
            coverageNote = "Foram analisadas 100 de 104.006 URLs descobertas nos sitemaps. A amostra não representa todas as páginas do site. Descoberta completa; sem nova reconciliação com o banco. Regras v2 reconhecem escapes percentuais equivalentes, como %0D e %0d; dois falsos avisos de canonical deixaram de ser emitidos. Nota técnica 70/100, com pesos preservados. O método v2 inicia comparação separada; a troca de regra não comprova melhora do site. Permanecem o 404 da notícia retirada e avisos de rotas privadas e canonical na fonte. Conferências complementares de conteúdo, traduções, logs e audiência mantêm suas datas e escopos próprios. Não comprova indexação no Google."
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
            id = "RR-25",
            sites = ["roadrunners"],
            priority = "p1",
            priorityLabel = "P1 · Edição e adiamento",
            title = "Reconciliar as edições da Corrida do Turismo ABAVSE",
            summary = "A edição antiga redireciona para o evento adiado em 2027, com preservação de idioma e retirada da URL antiga do sitemap.",
            impact = "Evita duas páginas com título igual para o mesmo evento adiado e mantém uma referência pública coerente.",
            owner = "RoadRunners — eventos e descoberta",
            rule = "event.rescheduled; semrush.104",
            evidence = "Fonte TicketSports 87181 confirmou adiamento de 09/08/2026 para 02/05/2027 e validade das inscrições. Alterado somente o alias tag_301 do evento antigo 43049 para o destino existente 44821; dois eventos, seis percursos e treze tabelas dependentes preservados. Redirect restrito a leitura, com destino único, existente, ativo e sem encadeamento; idiomas preservados e ações protegidas não redirecionadas. Quatro arquivos e um ajuste de normalização da barra final publicados, 37 verificações privadas aprovadas. Seis URLs públicas e quatro sitemaps conferidos: origem 301, destino 200, origem fora do sitemap, destino nas três línguas. SportsEvent apresenta EventRescheduled e previousStartDate. Ensaio, inversão, rejeição de drift, backups e hashes verificados. O regulamento antigo não foi apresentado como confirmação da data nova.",
            acceptance = "Entrega publicada e verificada em 04/10. Confirmar efeito nos dois títulos duplicados na próxima coleta Semrush; não reduzir manualmente os nove erros históricos.",
            urls = [{url = "https://roadrunners.run/evento/2027-4-corrida-do-turismo-abavse-2026/", label = "Evento adiado — destino atual"}],
            stateLabel = "Publicado e verificado — nova coleta Semrush pendente"
        },
        {
            resolved = true,
            id = "RR-26",
            sites = ["roadrunners"],
            priority = "p3",
            priorityLabel = "P3 · Experimento de descoberta",
            title = "Disponibilizar diretório público llms.txt",
            summary = "Arquivo experimental aponta conteúdo público e delimita leitura de eventos, edições históricas e fatos conferidos.",
            impact = "Oferece um diretório adicional para ferramentas que reconheçam o formato; não demonstra uso por assistentes.",
            owner = "RoadRunners — descoberta e conteúdo público",
            rule = "semrush.137; experiment.llms",
            evidence = "Ausência HTTP404 confirmada na URL apontada pelo Semrush. Publicado arquivo estático /llms.txt: HTTP200 text/plain e hash conferido; quatorze destinos públicos responderam 200. Formato baseado na proposta llmstxt.org. Políticas robots, autorização de treinamento, autenticação e privacidade preservadas. Links dos circuitos passaram a apontar diretamente às URLs canônicas com barra final. Dois arquivos publicados, um template compilado e seis dependências preservadas. Arquivo não entra na nota técnica nem equivale a indexação, recomendação ou citação.",
            acceptance = "Experimento publicado e documentado em 04/10. Uso efetivo e efeito não medidos; não tratar como requisito universal nem fator de pontuação.",
            urls = [{url = "https://roadrunners.run/llms.txt", label = "Diretório experimental"}],
            stateLabel = "Publicado e verificado — uso efetivo não medido"
        },
        {
            resolved = true,
            id = "RR-27",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Imagens e estrutura",
            title = "Acrescentar ALT aos cartazes e H1 às páginas agregadas",
            summary = "Cartazes recebem o nome do evento como alternativa; organizadores, cronometradores e circuitos têm título principal sem alterar a aparência.",
            impact = "Melhora a alternativa acessível de imagens e a estrutura do conteúdo apontadas nas amostras Semrush 110 e 103.",
            owner = "RoadRunners — apresentação pública",
            rule = "semrush.110; semrush.103; accessibility",
            evidence = "Dez cartazes sem ALT e quatro páginas sem H1 reproduzidos com HTTP200 antes da correção. Publicados três templates, todos compilados. Vinte e quatro renders privados antes/depois cobriram contextos org/timer/circuito/evento e temas com logo, logo ausente e sem tema. Escape do ALT com aspas, marcação e ampersand verificado. Quatorze URLs públicas passaram com metadados iguais; três hashes e oito dependências preservados. Organizador em desktop/celular conservou estilos e dimensões medidos; circuito com logo carregado, um H1 e sem overflow nas duas larguras. Login conserva título visível e aparência h6, agora H1; autenticação e indexabilidade preservadas. Nenhum H1 adicional nas páginas de evento. Totais históricos de 172 ocorrências ALT e 10 H1 não foram editados; dependem de nova coleta.",
            acceptance = "Entrega publicada e verificada em 04/10. Revalidar os alertas na próxima auditoria; subdomínio GoRunners e outras aplicações não estão abrangidos por estes templates.",
            urls = [{url = "https://roadrunners.run/org/sportsland/", label = "Organizador"}, {url = "https://roadrunners.run/circuito/live-run-xp/", label = "Circuito"}],
            stateLabel = "Publicado e verificado — totais do fornecedor históricos"
        },
        {
            resolved = false,
            id = "RR-24",
            sites = ["roadrunners"],
            priority = "p1",
            priorityLabel = "P1 · Disponibilidade",
            title = "Estabilizar o servidor após saturação recorrente",
            summary = "O acesso foi recuperado após saturação dos trabalhadores Apache; a causa permanente da recorrência ainda precisa ser demonstrada.",
            impact = "Indisponibilidade pode impedir a entrega de páginas a usuários e rastreadores, mesmo quando metadados e sitemaps estão corretos.",
            owner = "RunnerHub — infraestrutura e desempenho da aplicação",
            rule = "availability.apache-workers",
            evidence = "Em 04/10 houve três ocorrências de saturação e recuperação do Apache. Na terceira, conexão HTTPS tinha fila 512/511 e o log registrou limite MaxRequestWorkers 150; início e arquivo estático não responderam e o acesso público devolveu 522. Amostra agregada: 118 trabalhadores W e 32 R; idade máxima desde início de requisição 1.984 s, com grupos API, resultados, eventos e busca. Carga 1,62 e memória disponível aproximada de 9,6 GB não demonstram a causa. Configuração validada; reinício somente do Apache conforme autorização anterior. Depois da recuperação, nove URLs de conteúdo e quatorze de acessibilidade responderam 200. Configuração, ColdFusion, Cloudflare e credenciais preservados. Runtime Java sem jcmd/jstack; tentativa de introspecção foi impedida por módulos e não se alteraram essas proteções. Snapshot de banco sem SQL ativo não elimina outras causas. Não foi criado reinício automático nem ajustado o limite às cegas. Recuperação pontual não encerra esta frente.",
            acceptance = "Identificar a origem da retenção dos trabalhadores, corrigir a causa comprovada dentro do escopo autorizado e verificar disponibilidade sob tráfego real. Registrar períodos e fontes das medições; não prometer estabilidade com uma única resposta rápida.",
            urls = [{url = "https://roadrunners.run/", label = "Início — controle de disponibilidade"}],
            stateLabel = "Parcial — acesso recuperado; causa e estabilidade pendentes"
        },
        {
            resolved = true,
            id = "RR-23",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Recursos compartilhados",
            title = "Compactar cinco recursos próprios compartilhados",
            summary = "Cinco arquivos CSS/JavaScript passaram a ser entregues em versões compactadas, preservando fontes originais e comportamento.",
            impact = "Reduz bytes dos recursos próprios apontados na amostra Semrush de arquivos sem minificação.",
            owner = "RoadRunners — recursos de interface",
            rule = "semrush.135; first-party-assets",
            evidence = "Amostra de dez ocorrências do alerta 135 identificou cores.css, rr-audience-privacy.css/js, runnerhub-footer.css e runnerhub-entry-prompts.js, repetidos em diversas páginas. Versões geradas com compactação de espaços; arquivos originais preservados. Total bruto dos cinco arquivos: 42.208 para 33.932 bytes, redução aproximada de 19,6%; não é medição de transferência comprimida nem de Core Web Vitals. Vinte e dois cenários de comportamento passaram nos originais e nas versões compactadas; quatro templates compilados e nove verificações Adobe de referências aprovadas. Nove arquivos publicados com baseline e backup. Sete páginas e cinco recursos públicos responderam 200, com hashes dos recursos e metadados das páginas verificados. Estilos de desktop e celular permaneceram iguais nos elementos comparados; consentimento de privacidade preservado. O total de 2.809 ocorrências do fornecedor continua histórico e depende de nova auditoria.",
            acceptance = "Entrega publicada e verificada em 04/10. Confirmar redução das ocorrências em nova auditoria Semrush, sem alterar o snapshot nem atribuir automaticamente ganho de ranking ou pontuação.",
            urls = [{url = "https://roadrunners.run/circuitocatarinense/corridaderua/", label = "Controle de recursos publicados"}],
            stateLabel = "Publicado e verificado — efeito na auditoria ainda não medido"
        },
        {
            resolved = true,
            id = "RR-22",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Intenção e estrutura",
            title = "Distinguir as páginas de corrida de rua e trail run",
            summary = "Os rankings catarinenses têm títulos e descrições próprios por modalidade e ano, com um único H1 por página.",
            impact = "Explicita a intenção das páginas de ranking e diferencia as modalidades relacionadas à oportunidade SR-03.",
            owner = "RoadRunners — Circuito Catarinense",
            rule = "metadata.modality; heading.primary; semrush.opportunity.SR-03",
            evidence = "Antes da alteração, as duas páginas tinham o mesmo título, a mesma descrição e dois H1 cada. Publicados títulos e descrições específicos de corrida de rua e trail run para 2026, ano já apresentado pelo ranking. O nome do logo deixou de ser H1; o título principal recebeu prefixo acessível do circuito, preservando aparência. Dois templates compilados e expressões de metadados renderizadas. Ambas as páginas públicas responderam 200, com um H1 e metadados distintos. Consultas, classificação, seis tabelas de cada página, canonical e robots preservados. Desktop e celular conferidos. Nenhum dado ou URL foi alterado; não comprova melhora de posição para SR-03. Conferência adicional: unidade incorreta 21.0975m corrigida para 21,0975 km, conforme distância oficial de meia maratona; classificação e dados preservados. Links de navegação do circuito passaram a usar barra final canônica, com HTTP200 direto. Compilação, hashes e páginas publicados verificados.",
            acceptance = "Entrega técnica publicada e verificada em 04/10. Acompanhar a página regional de Santa Catarina e efeito nas buscas separadamente; esta entrega não encerra toda a oportunidade SR-03.",
            urls = [{url = "https://roadrunners.run/circuitocatarinense/corridaderua/", label = "Corrida de rua"}, {url = "https://roadrunners.run/circuitocatarinense/trailrun/", label = "Trail run"}],
            stateLabel = "Publicado e verificado — intenção por modalidade e ano"
        },
        {
            resolved = true,
            id = "RR-21",
            sites = ["roadrunners"],
            priority = "p1",
            priorityLabel = "P1 · Desempenho",
            title = "Acelerar o ranking catarinense de corrida de rua",
            summary = "A pontuação dos inscritos é calculada uma vez por etapa, reduzindo o tempo da página e preservando a classificação.",
            impact = "Remove uma consulta repetida que atrasava a entrega do ranking apontado pelo Semrush como não rastreado.",
            owner = "RoadRunners — Circuito Catarinense",
            rule = "semrush.9; query.repeated-score",
            evidence = "O snapshot Semrush 6ac29b3456eeefef0a3ff73b, de 04/10 às 15:40, aponta corridaderua como não rastreada. Perfil da consulta no datasource runnerhub usado pelo site: 7.150 ms antes e 36 ms depois; 401 linhas iguais em todos os campos, incluindo multiplicidade, sem diferenças reais ou sintéticas. Consumidores Adobe preservaram 135 linhas femininas, 266 masculinas e sete equipes; caso vazio também validado. Um template compilado e revisão independente concluída. Após publicar, página HTTP 200 em 0,30 s e 0,31 s, contra 8,06 s no baseline. Hashes das seis tabelas públicas, incluindo conteúdo e ordem, idênticos; title, canonical e robots preservados. Controle de trail run, busca em inglês e início HTTP 200. Nenhuma atualização de banco, pontuação, autenticação ou proteção Cloudflare. A causa exata da falha de rastreamento do fornecedor não foi provada; redução de latência não comprova indexação.",
            acceptance = "Entrega técnica publicada e verificada em 04/10/2026. Confirmar a baixa da página não rastreada em uma nova auditoria Semrush, sem alterar artificialmente a nota ou os nove erros do snapshot recebido.",
            urls = [{url = "https://roadrunners.run/circuitocatarinense/corridaderua/", label = "Ranking otimizado"}],
            stateLabel = "Publicado e verificado — Baixa no Semrush depende de nova auditoria"
        },
        {
            resolved = true, id = "RR-19", sites = ["roadrunners"], priority = "p2", priorityLabel = "P2 · Média",
            title = "Corrigir avatares inválidos nos rankings catarinenses",
            summary = "Os rankings de trail run e corrida de rua passam a ignorar o placeholder relativo do Strava e usar a próxima imagem válida ou o avatar padrão.",
            impact = "Evita gerar endereços de imagem inexistentes a partir de um valor legado, preservando os dados e a ordem do ranking.",
            owner = "RoadRunners — Circuito Catarinense",
            rule = "semrush.13; image.relative-placeholder",
            evidence = "O snapshot Semrush 6ac28c9356eeefef0a15555c apontou uma imagem quebrada em trailrun; a mesma origem foi confirmada em corridaderua. Corrigida somente a expressão de escolha da imagem nas duas páginas, usando a validação já existente no feed. Teste Adobe/PostgreSQL com valores sintéticos: baseline falhou em 16 de 26 cenários; candidato passou nos 26 cenários. Dois templates compilados. As duas páginas públicas retornaram HTTP 200 sem o caminho relativo inválido; imagem padrão respondeu 200. Nenhuma alteração de cadastro, pontuação ou ordenação. Reauditoria Semrush concluída em 04/10 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b: imagens quebradas passaram de 1 para 0. A página de corrida de rua ainda aparece como não rastreada; a validação pública da imagem nela não foi substituída por uma confirmação de rastreamento do fornecedor.",
            acceptance = "Ambas as páginas sem avatar/athlete/large.png relativo; HTTP(S), caminhos absolutos e fallback preservados. Compilação, revisão independente e verificação pública concluídas em 04/10/2026.",
            urls = [{url = "https://roadrunners.run/circuitocatarinense/trailrun/", label = "Ranking de trail run"}, {url = "https://roadrunners.run/circuitocatarinense/corridaderua/", label = "Ranking de corrida de rua"}],
            stateLabel = "Semrush: zero imagens quebradas na amostra de 04/10 às 15:40"
        },
        {
            resolved = false, id = "RR-20", sites = ["roadrunners"], priority = "p2", priorityLabel = "P2 · Média",
            title = "Resolver os nove erros restantes da reauditoria Semrush",
            summary = "Ranking, reconciliação ABAVSE e correções de recursos/estrutura foram publicados após a coleta. Restam confirmar os alertas com nova auditoria e estabilizar a entrega do servidor.",
            impact = "Mantém visíveis os problemas ainda não encerrados e evita tratar uma resposta 200 isolada como prova de estabilidade ou indexação.",
            owner = "RoadRunners — desempenho, conteúdo e rastreamento",
            rule = "semrush.2; semrush.6; semrush.8; semrush.9; semrush.111",
            evidence = "Reauditoria concluída em 04/10/2026 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b: 500 páginas, Site Health 76, nove erros, 6.356 avisos e 126 observações. Mesma última coleta confirmada novamente pela API; nenhum recrawl em execução e nenhuma nova pontuação. Os nove erros históricos abrangem dois títulos ABAVSE, um ranking não rastreado, busca em inglês com filtro de 5 km lenta e cinco ocorrências ligadas a /cdn-cgi/l/email-protection. Ranking corrigido em RR-21, com 401 linhas preservadas e verificações públicas de 8,06 s para 0,30–0,31 s. Fonte atual e identidade ABAVSE confirmadas; redirect e sitemap corrigidos em RR-25. Navegador real confirmou links mailto em privacidade PT/EN/ES, sem placeholders, e ausência de link protegido na página atual do evento da amostra; proteção mantida e nenhum contato enviado. Busca respondeu 200 em 2,11 s, porém disponibilidade recorrente continua em RR-24. Entregas de metadados, recursos, diretório experimental, ALT e H1 registradas em RR-22, RR-23, RR-26 e RR-27. O grupo de conteúdo duplicado caiu de quatro para zero na coleta, mas verificações mudaram de 1.272 para oito; não prova correção global dos vídeos. Amostra de redirecionamentos temporários contém login/suporte esperados: acesso preservado. Recurso grande e parte do H1 pertencem a GoRunners, fora do runtime principal. Títulos longos de notícias não foram truncados automaticamente. Essas verificações não substituem auditoria do fornecedor.",
            acceptance = "Confirmar as entregas em nova auditoria de 500 páginas com parâmetros comparáveis; preservar o snapshot até essa coleta. Investigar causa e estabilidade em RR-24. Não desligar proteção de e-mail, login ou regras da auditoria para elevar a nota.",
            urls = [{url = "https://roadrunners.run/evento/2026-4-corrida-do-turismo-abavse-2026/", label = "ABAVSE — URL 2026"}, {url = "https://roadrunners.run/evento/2027-4-corrida-do-turismo-abavse-2026/", label = "ABAVSE — URL 2027"}, {url = "https://roadrunners.run/circuitocatarinense/corridaderua/", label = "Ranking não rastreado"}, {url = "https://roadrunners.run/en/search/?distancia_inicio=5&distancia_fim=5&busca_mode=ai", label = "Busca apontada como lenta"}, {url = "https://roadrunners.run/privacidade/", label = "Origem de link protegido"}],
            stateLabel = "Entregas publicadas — nova auditoria e estabilidade pendentes"
        },
        {
            resolved = true, id = "RR-18", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Alta",
            title = "Alinhar hreflang das buscas ao canonical",
            summary = "As três buscas principais preservam seus alternates de idioma. Variantes com filtros ou termos mantêm o canonical da busca principal e deixam de anunciar um conjunto de traduções para uma página diferente.",
            impact = "Elimina sinais inconsistentes de idioma nas cópias de busca sem promover combinações de filtros a páginas indexáveis independentes.",
            owner = "RoadRunners — metadados da busca",
            rule = "semrush.24; search.hreflang-canonical",
            evidence = "Os 32 exemplos de busca do snapshot Semrush 6ac28c9356eeefef0a15555c foram conferidos em produção. Canonical apontava para a raiz localizada enquanto a própria variante emitia hreflang. Publicada somente a condição de emissão dos alternates em busca/index.cfm, identificando parâmetros recebidos antes dos valores padrão e preservando os parâmetros internos de idioma do Apache, preservando duas alterações de rodapé já presentes em produção. Testes Adobe: 99 cenários em PT/EN/ES e hosts prod/beta/dev; o baseline falhou em 72 casos e o candidato passou em todos. Verificação pública de 37 URLs: 32 exemplos do fornecedor, três raízes, uma busca textual e um parâmetro de campanha. HTTP, títulos, descrições, canonical e robots preservados. Não houve execução da busca por IA, alteração de filtros, banco, noindex ou robots.txt. Reauditoria Semrush concluída em 04/10 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b: grupo de conflitos hreflang passou de 42 para 0 na amostra de 500 páginas, reunindo o efeito dos lotes RR-17 e RR-18. Não comprova correção em URLs fora da amostra nem indexação.",
            acceptance = "Entrega pública validada e nenhum conflito hreflang apontado na nova amostra Semrush de 500 páginas. Manter validação dos alternates e canonicals ao ampliar a cobertura.",
            urls = [{url = "https://roadrunners.run/busca/?distancia_inicio=5&distancia_fim=5&busca_mode=ai", label = "Busca filtrada — 5 km"}, {url = "https://roadrunners.run/en/search/", label = "Busca principal em inglês"}, {url = "https://roadrunners.run/es/busqueda/", label = "Busca principal em espanhol"}],
            stateLabel = "Reauditoria confirmada em 04/10 às 15:40 — hreflang sem ocorrências na amostra"
        },
        {
            resolved = true, id = "RR-17", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Alta",
            title = "Corrigir metadados e sitemap das listagens editoriais",
            summary = "Notícias e vídeos preservam a página nos links de idioma. Títulos e descrições identificam o canal e a paginação. Notícias com canonical na fonte externa deixam de entrar no sitemap.",
            impact = "Alinha os sinais de idioma e descoberta ao conteúdo e ao endereço principal de cada página, preservando a atribuição às fontes.",
            owner = "RoadRunners — notícias, vídeos e sitemap",
            rule = "semrush.24; semrush.6; semrush.15; semrush.18",
            evidence = "Auditoria Semrush concluída em 04/10/2026 às 14:39: 500 páginas, snapshot 6ac28c9356eeefef0a15555c. Revisão editorial posterior: dez URLs paginadas entre os 42 conflitos de hreflang; 27 URLs nos grupos de títulos e descrições duplicados; quatro notícias não canônicas no sitemap. Publicação validada em 36 URLs, com 32 cenários Adobe e compilação de quatro arquivos. Metadados das quatro notícias e canonical externo preservados. Os 32 conflitos de hreflang em buscas ficaram fora deste lote; foram tratados posteriormente em RR-18, preservando as diferenças de produção. Reauditoria Semrush concluída em 04/10 às 15:40, snapshot 6ac29b3456eeefef0a3ff73b, 500 páginas: descrições duplicadas 27 para 0, problemas de sitemap 4 para 0 e títulos duplicados 27 para 2. Os dois títulos restantes são das URLs 2026 e 2027 da Corrida do Turismo ABAVSE, fora das listagens editoriais corrigidas; seguem no RR-20. Mesmos limites e configurações observáveis, sem prova de que todas as URLs amostradas são idênticas. Não comprova indexação.",
            acceptance = "Entrega técnica validada e baixa dos grupos editoriais confirmada na amostra Semrush de 04/10 às 15:40. Os dois títulos restantes de eventos estão separados no RR-20; a confirmação vale para esta coleta de 500 páginas.",
            urls = [{url = "https://roadrunners.run/videos/?page=3", label = "Vídeos — página 3"}, {url = "https://roadrunners.run/noticias/canal/chelso/", label = "Notícias — canal Chelso"}, {url = "https://roadrunners.run/sitemaps/news-recent.xml", label = "Sitemap de notícias"}],
            stateLabel = "Reauditoria confirmada em 04/10 às 15:40 — pendências de eventos no RR-20"
        },
        {
            resolved = false, id = "RR-16", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Alta",
            title = "Revalidar as URLs sinalizadas como soft 404",
            summary = "Corrigido o redirect genérico de eventos inexistentes para a busca. Os demais exemplos históricos exigem revisão própria; eventos válidos não foram retirados.",
            impact = "Evita indicar uma busca genérica como substituição permanente de uma página ausente. Preserva o acervo histórico que continua disponível.",
            owner = "RoadRunners — backend de eventos e acompanhamento no Search Console",
            rule = "google.soft404; missing-event.http",
            evidence = "Consulta direta em 04/10/2026: relatório de 20/09 com 167 exemplos, sendo 121 eventos, nove buscas, 36 perfis e um endpoint interno. Há 32 URLs com parâmetros de ações; não foram executadas nesta análise. Amostra pública de 13 URLs: nove eventos válidos e uma busca responderam 200, três eventos ausentes redirecionavam com 301 para busca genérica. Corrigido somente o ramo sem evento encontrado para reutilizar a página 404 localizada. Nove URLs ausentes em PT/EN/ES responderam 404 sem redirect; onze controles válidos permaneceram 200, com H1, canonical, alternates e JSON-LD preservados. Testes Adobe: 33 verificações em seis cenários, antes e após publicar; revisão independente, compilação e backup concluídos. O handler conserva o registro operacional de 404. Não houve alteração dos cadastros ou resultados, nem comprovação de reprocessamento pelo Google. Revalidação ampliada em 04/10: os 96 endereços de eventos sem query entre os 121 exemplos foram consultados; 51 retornaram 200 com H1, canonical e SportsEvent, e 45 retornaram 404. Nenhum 5xx, erro CFML ou erro de leitura JSON-LD nessa coleta. Nos nove endereços sem barra final que retornaram 200, o canonical aponta para a variante com barra; isso não foi tratado como erro. Os 45 endereços ausentes não têm tag exata nem alias cadastrado; nenhuma equivalência ou redirect foi inventado. As 25 URLs de evento com parâmetros de ação não foram executadas; buscas, perfis e endpoint interno ficaram fora desta coleta. Inspeção individual autenticada de /en/event/2022-2-dc-run/ informa página indexada, Googlebot Smartphone com êxito em 24/09/2026 às 11:12:49 e canonical selecionado igual ao inspecionado. A lista soft 404 ainda é de 20/09: esse exemplo já está superado na inspeção individual. A evidência de indexação vale somente para essa URL; HTTP 200 não comprova indexação das outras 50. Sem pedido de indexação nem validação global.",
            acceptance = "Correção do redirect de evento inexistente entregue. Ainda conferir as demais páginas válidas, buscas e exemplos do relatório, identificar equivalentes reais quando houver e acompanhar nova coleta do Google. Não devolver 404 a um evento existente por ser antigo e não abrir páginas pessoais por motivo de SEO.",
            urls = [{url = "https://roadrunners.run/evento/2026-grand-premium-brasil-recife/", label = "Exemplo ausente — agora HTTP 404"}, {url = "https://roadrunners.run/evento/2025-maratona-internacional-de-floripa/", label = "Controle histórico preservado"}],
            stateLabel = "Parcial — redirect genérico corrigido; demais casos em revisão"
        },
        {
            resolved = true, id = "RR-13", sites = ["roadrunners"], priority = "p1", priorityLabel = "P1 · Disponibilidade",
            title = "Recuperar as estatísticas de 2025 e seus filtros",
            summary = "Consultas repetidas e comparação de cidade após normalização causavam lentidão e erros. A consulta anual foi otimizada; filtros sem participantes agora têm estado vazio.",
            impact = "Permite que usuários e rastreadores acessem novamente exemplos de URLs presentes no relatório histórico de erros 5xx.",
            owner = "RoadRunners — estatísticas do Desafio 365",
            rule = "http.5xx; response-time; filter-empty-state",
            evidence = "Publicado em 04/10/2026. Cinco URLs públicas com HTTP 200 e sem erro CFML: geral, Valinhos, Sul/RS, AM e filtro inexistente. Primeira carga 5,2 s; demais cerca de 0,2 s com cache. Comparação SQL real: 2.126 linhas e 365 dias preservados; oito fixtures sem divergências. Seis renders de filtros e um cenário com 79 participantes sem atividades passaram. Desktop 1280 e celular 390 sem transbordamento. Não houve nova auditoria ampla nem confirmação de reindexação.",
            acceptance = "HTTP 200, filtros em caixa alta ou baixa equivalentes, totais e doações preservados, estado vazio sem divisão inválida e dependências intactas. Aguardar evidência posterior do Google antes de encerrar a recuperação de indexação.",
            urls = [{url = "https://roadrunners.run/desafiocna/estatisticas/2025/", label = "Estatísticas de 2025"}, {url = "https://roadrunners.run/desafiocna/estatisticas/2025/?estado=SP&cidade=VALINHOS", label = "Estatísticas de Valinhos"}],
            stateLabel = "Publicado e verificado em 04/10/2026; Google ainda não revalidado"
        },
        {
            resolved = true, id = "OR-04", sites = ["openresults"], priority = "p1", priorityLabel = "P1 · Alta",
            title = "Confirmar processamento do sitemap pelo Google",
            summary = "O Search Console confirmou o processamento de /sitemap.xml e dos quatro lotes, com 34.319 URLs descobertas.",
            impact = "Confirma a recuperação da leitura do sitemap pelo Google. A recuperação da indexação permanece acompanhada separadamente em OR-05.",
            owner = "OpenResults — entrega pública e acompanhamento no Search Console",
            rule = "google.sitemap.fetch",
            evidence = "Consulta autenticada em 04/10/2026: índice Processado, última leitura em 03/10; quatro lotes Processado, todos com leitura em 04/10, com 10.000, 10.000, 10.000 e 4.319 URLs. Total 34.319. Esta evidência do leitor de sitemaps supera a falha informada em 03/10 após publicar o XML. Não é inferência a partir de HTTP 200 local e não comprova indexação das páginas.",
            acceptance = "Concluído: índice e quatro lotes processados no Search Console. Indexação acompanhada em OR-05; páginas pessoais permanecem protegidas.",
            urls = [{url = "https://openresults.run/sitemap.xml", label = "Índice XML processado"}], stateLabel = "Concluído — processamento confirmado no Google em 04/10"
        },
        {
            resolved = false, id = "OR-05", sites = ["openresults"], priority = "p1", priorityLabel = "P1 · Alta",
            title = "Confirmar recuperação da indexação dos eventos",
            summary = "A leitura do sitemap foi recuperada, mas o relatório de páginas ainda antecede as mudanças de acesso de 03/10.",
            impact = "Evita confundir descoberta de URLs com retorno dos eventos aos resultados do Google.",
            owner = "OpenResults — acompanhamento no Search Console",
            rule = "google.index.recovery",
            evidence = "Consulta direta de 04/10/2026: relatório atualizado em 20/09, com zero indexadas, cerca de 139 mil não indexadas e 135.791 bloqueadas por 403. Os quatro sitemaps de eventos já foram processados, com 34.319 URLs descobertas. Não há nova posição de indexação que confirme recuperação após as mudanças de 03/10.",
            acceptance = "Registrar nova posição do relatório de páginas após as mudanças, conferir exemplos de /evento e evolução das páginas indexadas. Não inferir indexação de HTTP 200 ou sitemap processado. Manter noindex em /resultados e bloqueio de /perfil.",
            urls = [{url = "https://openresults.run/", label = "OpenResults"}], stateLabel = "Pendente — nova evidência de indexação no Google"
        },
        {
            resolved = true, id = "SH-03", sites = ["roadrunners","openresults"], priority = "p1", priorityLabel = "P1 · Alta",
            title = "Separar nota técnica e situação no Google",
            summary = "A situação no Google aparece antes da pontuação. A nota técnica da amostra fica recolhida com seus limites; não há nota geral de SEO.",
            impact = "Evita interpretar 100/100 na amostra como comprovação de indexação ou ausência de bloqueios ao Google.",
            owner = "Business — relatório SEO e evidências externas",
            rule = "report.search-evidence",
            evidence = "Registro manual datado das capturas: RoadRunners com índice processado e 103.036 URLs descobertas; OpenResults com falha de busca reportada em 03/10 e processamento confirmado em 04/10 (OR-04). Consulta direta posterior ao Search Console, posição de 20/09: RoadRunners com cerca de 14,1 mil indexadas e OpenResults com zero; esses números não refletem as mudanças de 03/10. A fórmula e o histórico técnico foram preservados.",
            acceptance = "Cartões exibem evidência/fonte/data, diferenciam descoberta e indexação, mantêm a recuperação de indexação do OpenResults pendente mesmo com 100/100 técnico e preservam filtros e histórico.",
            urls = [], stateLabel = "Publicado — nota técnica com limites explícitos"
        },
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
            acceptance = "Concluído nos quatro casos: HTTP 200, evento e canonical corretos nos três idiomas, sem mudar tags ou o cadastro. Teste com Apache real confere caracteres especiais e preserva caminhos sensíveis. A auditoria de 03/10 rechecou Operário com HTTP 200 e registrou aviso da regra legada por %0D versus %0d. Na nova auditoria de 04/10, a regra v2 reconhece essa equivalência: o evento continua HTTP 200 e sem esse falso aviso. O relatório anterior permanece preservado.",
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
            evidence = "Rechecagem em 29/09/2026: o sitemap estático contém 49 URLs e os três destinos privados continuam ausentes dos sitemaps. Eles entraram na amostra pela rechecagem de pendências antigas e ainda retornam HTTP 302 para login. Esses avisos não indicam que os destinos voltaram ao sitemap nem que a autenticação deva ser removida. Conferência pública em 03/10, após SEO regional: sitemap estático com 1.026 URLs (22 rotas anteriores, 27 estados e 977 cidades), sem os destinos privados. As 49 rotas anteriores continuam presentes.",
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
            resolved = true,
            id = "RR-15",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Identidade do site",
            title = "Declarar a identidade estruturada na página inicial",
            summary = "A home identifica Road Runners como WebSite e sua relação com a RunnerHub Inteligência Esportiva como Organization.",
            impact = "Ajuda mecanismos a interpretar a identidade do site e a empresa responsável, com base nas informações públicas da página Sobre e do rodapé.",
            owner = "RoadRunners — metadados da home",
            rule = "Identidade WebSite e Organization sustentada pelo conteúdo público",
            evidence = "Publicado e conferido em 04/10/2026: homes PT/EN/ES e uma URL com parâmetro de campanha entregam um único grafo com IDs estáveis. Canonical, alternates, robots e JSON-LD anterior preservados em seis URLs públicas, incluindo Sobre e evento como controles. Vinte e três verificações Adobe passaram; ambientes dev/beta não recebem o grafo, e dados estruturados preexistentes são preservados. Dois templates compilados, revisão Astra sem achados e hashes publicados conferidos. O nome RunnerHub corresponde à identificação pública; não foram inferidos razão social, CNPJ, endereço, contato, logo ou perfis externos.",
            acceptance = "Concluído no escopo da home: WebSite e Organization válidos como JSON-LD, identidade coerente entre idiomas e publisher vinculado por ID. Esta entrega não comprova escolha do nome pelo Google, indexação, resultado enriquecido ou citação por IA; a extensão a outras entidades continua separada.",
            urls = [{url = "https://roadrunners.run/", label = "Página inicial"}, {url = "https://roadrunners.run/en/", label = "Home em inglês"}, {url = "https://roadrunners.run/es/", label = "Home em espanhol"}, {url = "https://roadrunners.run/sobre/", label = "Identidade pública da plataforma"}],
            stateLabel = "Publicado e verificado em produção"
        },{
            resolved = false,
            id = "RR-14",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Confiabilidade dos resultados",
            title = "Conferir recordes históricos de São Paulo com a fonte oficial",
            summary = "Os recordes exibidos derivam de classificações históricas divergentes da fonte oficial. Conferência focada identificou os casos de 2008 masculino e 1998 feminino.",
            impact = "Informações históricas incorretas podem ser reproduzidas por leitores e assistentes. A divergência exige revisão da origem dos resultados, sem presumir fraude, deficiência ou desclassificação de atletas.",
            owner = "RoadRunners — importação de resultados e resumo das edições",
            rule = "Coerência factual entre resultados, campeão da edição e recorde",
            evidence = "Conferência em 04/10/2026: o bloco público da Maratona de São Paulo mostra 01:42:19/2008 no masculino e 02:16:54/1998 no feminino. Consulta somente leitura encontrou esses tempos em tb_resultados, percurso 42, classificacao_sexo=1, pcd=false, homologado=true. A página oficial de campeões da Yescom informa 02:17:07 para o vencedor masculino de 2008 e 02:39:58 para a vencedora feminina de 1998, com nomes diferentes dos selecionados. O registro de 02:17:07 existe na base de 2008 como segundo colocado. As URLs de origem cadastradas são Athlinks; ainda falta confrontar a lista completa e o histórico de processamento para determinar a origem da divergência. Não basta trocar o título do bloco ou filtrar por limite arbitrário de tempo. Nenhum resultado, classificação, atributo pessoal ou vínculo foi alterado nesta investigação.",
            acceptance = "Reconciliar as duas edições com fontes completas, identificar e corrigir a regra de importação ou cadastro responsável, testar a reexecução sem perda de vínculos e verificar campeões, recordes e gráficos nos três idiomas. Preservar resultados pessoais e registrar fonte, data e backup; não substituir tempos por inferência nem anunciar novo recorde sem comprovação.",
            urls = [{url = "https://roadrunners.run/evento/2027-maratona-internacional-de-sao-paulo-2027/", label = "Resumo público das edições"}],
            stateLabel = "Divergência confirmada; correção dos dados pendente"
        },{
            resolved = false,
            id = "SH-02",
            sites = ["roadrunners", "openresults"],
            priority = "p3",
            priorityLabel = "P3 · Qualidade dos dados",
            title = "Completar e conferir fatos dos eventos",
            summary = "Doze lotes de datas e fontes conferidos. Restam 31 percursos em 18 eventos com fontes conflitantes, ausentes ou sem identidade suficiente; cidade Fla Resenha e resumo PT/EN/ES Aracaju corrigidos. Demais fatos e organizadores continuam em revisão.",
            impact = "Lacunas dificultam atribuição e respostas precisas. Campo ausente não comprova erro factual nem autoriza adivinhar organizadores.",
            owner = "Business — cadastro; RoadRunners e OpenResults — apresentação pública",
            rule = "Revisão factual; campos de eventos",
            evidence = "Auditorias datadas no painel: Road Runners: 38 eventos avaliados, 37 com lacunas; Open Results: 99 eventos avaliados, 96 com lacunas. Verifica presença de nome, data válida, local e organizador, além de nome/cidade no texto; não comprova exatidão factual. Consulta de 04/10: 34.318 eventos ativos; 1.332 com vínculo de organizador nomeado e 13.068 com texto de organizador sem esse vínculo. Esse total é potencial de cadastro, não contagem de páginas verificadas. Publicado no RoadRunners o bloco Organizador informado, com prioridade ao vínculo formal, escape e rótulos PT/EN/ES. Doze URLs públicas retornaram 200; JSON-LD e canonical ficaram idênticos ao baseline. Não houve promoção automática do texto para Person/Organization, revisão factual de todos os nomes nem alteração do OpenResults. Não usar cronometrador como organizador nem inferir dados ausentes. Conferência focal em 04/10: cinco eventos mais acessados na medição própria dos sete dias até 01:08, com 504 visualizações agregadas; todos históricos. Regulamentos conferidos para Salvador, Criciúma e Corre RD; fontes primárias para Goiânia e Garoto. Link Regulamento do evento publicado quando cadastrado: 15 URLs PT/EN/ES testadas, nove com link e seis sem fonte, sem alteração de JSON-LD/canonical. Conferência complementar de 04/10: Salvador corrigido para 26–27/09, com datas dos percursos 3/5/10 em 26/09 e 21/42 em 27/09, mantendo chaves e resultados. Regulamento atualizado para o PDF atualmente ligado na página oficial. Página TicketSports e regulamento confirmam intervalo e programação de 5/10/21/42; reportagem GE de 23/09 confirma também 3 km no sábado. Alteração ensaiada com rollback, hashes e backup. Goiânia: a Agência Municipal de Turismo explica que a categoria nominal 4 km tem aproximadamente 4,28 km devido aos retornos da pista; não excluir nem renomear percursos. Página antiga da TFSports retorna Página não encontrada após carregar. Salvador ainda tem conflito de local entre trechos da própria fonte oficial (Centro de Convenções versus Arena O Canto da Cidade); endereço preservado até esclarecer. Distância nominal 16 km de Garoto ligada a 17.606 resultados; não renomear automaticamente para 16,09. Criciúma conserva 26–27/09, incluindo Kids. Corrigida a apresentação de categorias: o bloco agora preserva texto e unidades cadastradas, incluindo kids, caminhada, metros e decimais, sem acrescentar km indevidamente. Quarenta verificações CFML, 11 cenários e 15 URLs públicas PT/EN/ES aprovados; canonical/JSON-LD e dados de percursos/resultados preservados. Lote de próximos eventos conferido em 04/10: LIVE Rio, LIVE Bonito, Paraná 2027, São Paulo 2027 e Floripa 2027, priorizados por audiência própria (178 visualizações na janela de sete dias até 01:34; todos os canais). São Paulo: edição e descrição corrigidas em PT/EN/ES; percursos 7/14/21/42 km em 04/04, com Corrida das Nações explicada separadamente. Bonito: descrição corrigida de 6 para 5 km nos três idiomas; o slug jurer da fonte é válido. Paraná: percurso 10 km corrigido para 28/03. Floripa: início e meia maratona corrigidos para 28/08; 5/42 km permanecem em 29/08. Cinco links de regulamento adicionados ou atualizados, incluindo páginas LIVE com regulamento HTML. Onze IDs de percursos e dependências preservados; ensaio e inversão transacionais validados antes da publicação. Dezoito URLs públicas verificadas, com canonical preservado. São Paulo já exibe o vínculo formal com Yescom; o campo legado vazio não representa ausência de organizador. Segundo lote futuro conferido em 04/10: Porto Alegre 2027, Corrida de Impacto, Aracaju, LIVE Juiz de Fora e Jurerê, com 108 visualizações na mesma janela de sete dias. Corrigidas nove datas de percursos e início de Jurerê para 10/10; quatro links de regulamento atualizados. Impacto: data 14/11 corrigida em PT/ES; EN permanece com fallback português. Quinze páginas PT/EN/ES conferidas no navegador, com canonical e alternates preservados. Dezesseis IDs de percursos e 13 tabelas de dependências preservados; backup, ensaio, inversão, rejeição de drift e revisão independente aprovados. Fontes de Juiz de Fora divergem sobre local/horário e as de Aracaju sobre horários; esses campos não foram alterados. Diagnóstico de 04/10: 169 percursos em 86 eventos futuros ativos têm datas fora do intervalo do evento (consulta de 4.164 percursos em 2.012 eventos com percursos); são divergências para revisão, não 169 erros confirmados. Corrigida nas duas rotinas de geração a sobrescrita de percursos bloqueados por edição manual. Doze cenários PostgreSQL aprovados antes e após publicação; aplicação, inversão e rollback forçado ensaiados. Eventos e percursos não foram alterados nesta publicação. A mudança exclusiva de data do evento ainda não sincroniza percursos; a distribuição automática por distância permanece e não substitui o regulamento. Lote de divergências conferido em 04/10: LIVE Rio, LIVE Niterói, Night Run Curitiba, Night Run Maceió e Corrida do 5º BEC (103 visualizações na janela já indicada). Corrigidas onze datas de percursos e ativada a proteção de edição manual desses onze registros. Link do regulamento de Niterói adicionado e verificado em PT/EN/ES; canonical, alternates e JSON-LD preservados. Na fonte do 5º BEC, a descrição e a programação de kits sustentam 11/10, mas o cabeçalho Sympla mostra agosto; disponibilidade não foi inferida. Aplicação, inversão, rejeição de drift e revisão independente aprovadas; cinco eventos, onze IDs e treze tabelas dependentes verificados. Recontagem após publicação: 158 percursos em 81 eventos futuros ainda fora do intervalo do evento, pendentes de conferência factual. Revisão parcial, sem selo de exatidão universal; demais campos do cadastro e resultados preservados. Fontes das datas publicadas em quatro eventos: LIVE Rio, LIVE Niterói, Night Run Curitiba e Night Run Maceió. Bloco PT/EN/ES informa início/término conferidos, fonte oficial e conferência em 04/10/2026; declara que local, horários e inscrições não foram verificados nessa conferência. A indicação desaparece se as datas do cadastro mudarem. Recibos manuais: mudanças posteriores nas fontes não são detectadas automaticamente; histórico por campo e gestão pelo cadastro ainda pendentes. O 5º BEC permanece excluído por conflito na fonte. 54 verificações CFML e 15 URLs públicas aprovadas; canonical, alternates e JSON-LD preservados. Includes diretos retornam 403; apresentação desktop e mobile conferida. Nenhum dado de evento ou resultado alterado nesta entrega. Canal de correção contextual publicado nas páginas de eventos RoadRunners: link Informar correção em PT/EN/ES abre o atendimento existente, preserva o evento no retorno do login e prepara assunto/mensagem com nome e URL do cadastro. A pessoa descreve o erro, informa a fonte e envia pelo fluxo existente. Identificador validado e consulta parametrizada; rascunho somente em GET, sem sobrescrever texto de POST. Quatro arquivos compilados, 37 verificações de serviço/links e 60 de integração focal aprovadas; 19 casos públicos conferidos, com metadados de nove páginas preservados. Formulários autenticados reais PT/EN/ES e link desktop/mobile conferidos; nove dependências preservadas. Nenhum chamado de teste enviado, nenhuma edição automática de evento. Histórico público de correções por campo permanece pendente. Novo lote factual de 04/10: LIVE Fortaleza (20/11), Primavera Campo Grande (11/10), TGS Run (22/11) e Reis Magos (18/10), com 23 visualizações na janela de sete dias até 01:34. Dez datas de percursos corrigidas e protegidas como edição manual; dois links de regulamento adicionados e descrição TGS atualizada para 22/11 conforme aviso de adiamento do organizador. Quatro eventos, dez IDs e treze tabelas dependentes verificados, com ensaio, inversão, rejeição de drift, backup e revisão independente. Doze páginas PT/EN/ES retornam 200, com canonical e alternates preservados e dados estruturados coerentes com a descrição corrigida. Recontagem: 148 percursos em 77 eventos futuros ainda fora do intervalo, pendentes de revisão. IZ1 Telecom excluída deste lote: página informa 01/11, mas PDF ligado continua em 25/10; fonte também diverge sobre local. Demais campos e resultados preservados; datas conferidas não equivalem a revisão integral do evento. Histórico público de correções publicado em oito eventos: nove registros de datas anteriores e corrigidas, data da revisão e fonte consultada. Inclui os quatro eventos do último lote e os quatro já conferidos anteriormente; fontes de datas ampliadas de quatro para oito. Seção recolhida em PT/EN/ES diferencia correção do cadastro de adiamento; histórico permanece quando o cadastro muda, enquanto a conferência atual desaparece ao divergir. Registros derivados de baselines e alterações publicadas, sem dados pessoais; IZ1 e 5º BEC excluídos por conflito de fonte. Quatro templates compilados, 181 verificações Adobe, revisão independente, 27 URLs públicas e dois includes diretos403 aprovados. Canonical, alternates e JSON-LD preservados; desktop/celular e teclado conferidos. Histórico público ainda curado manualmente. Captura automática privada publicada em 04/10 para INSERT/UPDATE/DELETE de eventos e percursos: guarda campos públicos acompanhados, valores antes/depois e horário na mesma transação. Inclui datas, local, status, distâncias, horários e links cadastrados; ignora alterações sem diferença nesses campos. Sem backfill, dados de atletas, IP, operador ou publicação automática. Registro de mudança não significa fonte conferida nem revisão factual. Vinte e sete cenários PostgreSQL aprovados antes e após publicação; escrita real como usuário da aplicação ensaiada com rollback nos dois cadastros, permissões privadas verificadas, instalação/inversão/falha forçada e revisão independente aprovadas. Hashes integrais de eventos e percursos preservados na implantação. Aba administrativa Fontes e revisões publicada no cadastro Business: permite conferir datas do evento, local e situação com URL de fonte, confirmação explícita, valores revisados e horário de Brasília. Rejeita formulário obsoleto e reenvio com conteúdo diferente; retirada preserva o registro. Consulta as últimas dez conferências e vinte alterações automáticas. Distingue cadastro igual, alterado e conferência retirada; igualdade não garante fonte atual. Administração interna, POST e CSRF obrigatórios; acesso delegado preservado sem ampliação. Seis arquivos compilados e publicados; 68 verificações de serviço e cinco casos de controller passaram antes e depois, com fixtures revertidas. Aba real autenticada, link direto, alternância entre abas, desktop/celular e teclado conferidos. Nenhum cadastro ou resultado alterado nem conferência de teste persistida. Integração das conferências de datas com o RoadRunners publicada: administrador pode publicar explicitamente fonte, data da conferência e início/término, ou retirar somente a publicação preservando o registro interno. Somente a última conferência não retirada e igual ao cadastro pode ser publicada. Nova revisão de datas oculta a publicação anterior até nova aprovação; mudança nas datas oculta o bloco e retirada não reativa recibos manuais antigos. Local e situação continuam internos; não inclui horários/datas dos percursos. Projeção pública restrita no cadastro, sem liberar acesso à tabela privada nem ampliar permissões. Cinco arquivos compilados, 22 verificações de serviço, oito casos de controller, quatro estados de tela e 283 verificações de renderização PT/EN/ES aprovados. Revisão independente e interface desktop/celular/teclado aprovadas. A revisão dos percursos e demais divergências factuais permanece pendente. Quinto lote factual publicado em 04/10: sete datas de percursos corrigidas em Prime Night Run (10/10), Track&Field ParkShoppingBarigüi, Central Gym Run e Corrida por Patas (11/10). Proteção de edição manual ativada nos sete percursos, IDs e demais campos preservados. Descrição Track&Field corrigida em português e espanhol, com hashes da tradução atualizados; inglês mantém fallback. Regulamento HTML da Prime ligado no cadastro. Fontes oficiais conferidas; etapa TF validada também no navegador normal. Aplicação, inversão e rejeição de conflito ensaiadas; backup, revisão independente, quatro eventos, sete percursos e treze dependências conferidos após commit. Histórico privado capturou as sete alterações de datas e o link de regulamento; descrições permanecem documentadas no backup e recibo do lote. Doze páginas PT/EN/ES conferidas antes e depois; canonical e alternates preservados, descrição estruturada coerente com a correção. Recontagem atual: 141 percursos em 73 eventos futuros ainda fora do intervalo, pendentes de conferência; não representam 141 erros confirmados. Sexto lote factual publicado em 04/10: seis datas de percursos corrigidas em Comerciário Manacapuru (11/10), Serrinha Runners e Correr é Massa Apucarana (17/10), e Bota Pra Correr Rio (18/10). Páginas oficiais e regulamentos conferidos, incluindo aviso explícito de alteração em Serrinha. Proteção de edição manual ativada nos seis percursos; quatro eventos, seis IDs e treze dependências preservados. Aplicação, inversão, rejeição de conflito e revisão independente aprovadas. Histórico privado capturou as seis correções. Doze páginas PT/EN/ES retornaram 200; canonical, alternates e JSON-LD preservados. Recontagem atual: 135 percursos em 69 eventos futuros fora do intervalo, pendentes de revisão factual. Corre pela Formatura e ARDAP têm fontes conflitantes; Nossa Senhora do Rosário e Itamaracá permanecem sem confirmação suficiente. Esses quatro cadastros não foram alterados; a revisão factual continua parcial. Sétimo lote factual publicado em 04/10: nove datas de percursos corrigidas em Empório Prime, 10 Milhas de Marília e Patinhas Run (18/10), além do 3º Circuito Run (24/10). Descrições de Marília corrigidas em PT/EN/ES, incluindo corrida 5km, caminhada 3km e Kids separado; removida categoria caminhada 16.09km não sustentada pela fonte. Patinhas corrigido em PT/ES, mantendo fallback inglês. Hashes de traduções atualizados. Proteção de edição manual, nove IDs e treze dependências preservados; aplicação, inversão, conflito e revisão independente aprovados. Doze páginas PT/EN/ES verificadas com metadados preservados; regressão dos textos reproduzida antes e resolvida após publicação. Histórico privado registrou nove datas e uma categoria; descrições documentadas no backup. Recontagem atual: 126 percursos em 65 eventos futuros fora do intervalo, pendentes de conferência. RCC Bragança não alterada por datas conflitantes dentro da fonte; Toca Raul e Q2 Americana exigem conferência própria. Nenhuma conclusão sobre indexação decorre dessas correções. Oitavo lote factual publicado em 04/10: doze datas de percursos corrigidas em Toca Raul Barra Mansa (24/10), Blue Run Santos, Corrida Águia, Legado Run e Morro Beach Run (01/11). Datas gerais de início e término preservadas. Descrição Toca Raul atualizada em PT/ES para corrida em 24/10 e kits em 23/24, com hashes da tradução corrigidos e fallback inglês preservado. Horários dos kits divergentes entre fontes não foram considerados conferidos nem alterados. Regulamento de Legado atualizado para o PDF atualmente vinculado à inscrição. Cinco eventos, doze IDs e treze dependências verificados; aplicação, inversão, rejeição de conflito e revisão independente aprovadas. Quinze páginas PT/EN/ES retornaram 200, com textos e link corrigidos e metadados preservados; histórico privado registrou doze datas e um regulamento. Recontagem atual: 114 percursos em 60 eventos futuros fora do intervalo, ainda para conferência factual. A revisão permanece parcial e não representa alerta do Google. Nono lote factual publicado em 04/10: 29 datas de percursos em 15 eventos, conforme páginas e regulamentos oficiais individualmente conferidos. Início e término gerais e demais campos dos eventos preservados. Trinta e um IDs mantidos, incluindo dois percursos excluídos da correção por ausência de comprovação da distância/identidade: UNINTA Itapipoca 21 km e AB Run 2,6 km. Aplicação, inversão e rejeição de conflito ensaiadas; hashes dos eventos e percursos e treze tabelas de dependências conferidos. Quarenta e cinco URLs PT/EN/ES responderam 200 com canonical, alternates e JSON-LD preservados. Recontagem atual: 86 percursos em 48 eventos futuros fora do intervalo, para revisão factual; não são 86 erros confirmados nem alertas do Google. Continuação em 04/10: décimo lote corrigiu 16 datas de percursos em 11 eventos e início/término de Palmas para 22/11, conforme fonte; décimo primeiro corrigiu 30 datas em 15 eventos; décimo segundo corrigiu 12 datas em seis eventos e três links de regulamentos vigentes. Proteção manual ativada em todos esses percursos e reforçada nos 29 do nono lote; IDs e treze dependências preservados, aplicação/inversão/drift ensaiados. Verificadas 33, 45 e 18 URLs PT/EN/ES, respectivamente. Última recontagem: 31 percursos em 18 eventos futuros, todos classificados por fonte conflitante, ausente ou sem identidade suficiente; não são 28 erros confirmados nem alertas do Google. Fla Resenha: cidade Piraí corrigida para Barra do Piraí e id_localidade 3056 para 3006, pela dimensão existente e fonte oficial; endereço, coordenadas vazias e datas preservados, três URLs aprovadas. Aracaju: resumo factual PT/EN/ES publicado com programação de 31/10 (10/21 km) e 01/11 (5 km/maratona), traduções manuais vinculadas ao texto PT, sem chamada paga. Horários conflitantes preservados. Nove URLs de Aracaju, LIVE Porto Alegre e SP City verificadas; traduções válidas dos dois últimos não foram reescritas. Revisão final Astra identificou três percursos de IZ1 e ARDAP corrigidos sem conciliar PDF ainda ligado; valores anteriores e proteção manual anterior restaurados com guardas, sem declarar a data antiga correta. Q2 recebeu novo PDF atualmente ligado, que confirma 25/10 e revezamento de duas voltas de 5 km; duas datas mantidas, resumo factual PT/EN/ES e hash de traduções atualizados. Onze testes, inversão, drift, treze dependências, nove URLs públicas e quatro registros históricos conferidos. Última recontagem real após a correção: 31 percursos em 18 eventos. A revisão geral de organizadores, demais fatos e edições históricas continua parcial.",
            acceptance = "Conferir os dados com fontes dos organizadores; completar somente informação comprovada e exibi-la de forma coerente em cada idioma. Manter indicação de resultado em processamento/indisponível e acesso existente. Registrar fonte e data da revisão.",
            urls = [{url = "https://roadrunners.run/evento/2026-maratona-salvador-2026/", label = "Evento Road Runners sem vínculo de organizador"}, {url = "https://openresults.run/evento/2026-maratona-salvador-2026/", label = "Evento OpenResults sem vínculo de organizador"}],
            stateLabel = "Parcial — 31 percursos em 18 eventos dependem de fonte; demais fatos pendentes"
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

        ,{
            resolved = true,
            id = "RR-12",
            sites = ["roadrunners"],
            priority = "p2",
            priorityLabel = "P2 · Descoberta regional",
            title = "Ampliar navegação e descoberta por cidade",
            summary = "Filtro completo de cidades publicado; estados e cidades agora têm metadados por localidade, contexto visível e breadcrumb com JSON-LD correspondente.",
            impact = "Ajuda corredores e rastreadores a encontrar o calendário local e compreender a relação entre estado e cidade.",
            owner = "Road Runners — páginas regionais e sitemap",
            rule = "Conferência focal de navegação, metadados, BreadcrumbList e sitemap",
            evidence = "Publicado e conferido em 03/10/2026: Bahia, Alagoinhas com filtros e Florianopolis retornam HTTP200, título por localidade, canonical sem filtros e breadcrumb visível correspondente ao JSON-LD. Sitemap estático com 977 cidades, 27 estados e 22 rotas anteriores. Cidades elegíveis têm eventos ativos BR entre hoje e 360 dias; sitemaps históricos preservados. Compilação Adobe, fixtures CFML, testes Node e desktop/celular verificados; revisão final Astra sem achados. A auditoria das 22:57 inspecionou 100 páginas e descobriu 104.021 URLs, sem achados novos. Em 04/10, páginas de evento receberam breadcrumb visível e BreadcrumbList: início localizado, estado somente com país BR e UF válida, e evento canônico. PT/EN/ES conferidos no navegador; SportsEvent, canonical, robots e alternates preservados. Sessenta verificações Adobe, compilação de dois templates, revisão independente e desktop/celular aprovados; link regional acionado por teclado. A validação regional é complementar; não comprova indexação, posição ou citações por assistentes.",
            acceptance = "Calendário local acessível, filtros preservados e estados/cidades identificados em títulos, descrições e H1. Breadcrumb visível e JSON-LD coerentes com canonical. Sitemap com cidades não vazias no calendário padrão, sem combinações de filtros nem lastmod inventado.",
            urls = [
                {url = "https://roadrunners.run/estado/ba/", label = "Calendário da Bahia"},
                {url = "https://roadrunners.run/estado/ba/alagoinhas/", label = "Calendário de Alagoinhas"},
                {url = "https://roadrunners.run/sitemaps/static.xml", label = "Sitemap de estados e cidades"}
            ],
            stateLabel = "Publicado e verificado; 977 cidades no sitemap"
        }
    ]
};
</cfscript>
