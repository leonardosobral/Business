# Revisões SEO — 06/10/2026

Escopo: .htaccess RoadRunners com cinco aliases legados de assessoria; evidência Business, sem Git e sem cadastro. Fonte histórica: snapshot Semrush6ac31bf647d73ceec1b0b861,5.000URLs. Semrush não está disponível como ferramenta nesta sessão; nenhum dado atribuído a nova coleta.

34URLs relidas: cinco assessorias /assessoria ainda404, apesar de novoslinks já usarem/timer. SELECT confirmou tag única de cinco fornecedores. Regra limitada aos cinco caminhos exatos, GET/HEAD, query vazia. Formulários, POST, filtros, ações e outros slugs permanecem no fluxo anterior404. Não criar redirects genéricos de nomes/eventos incompletos.

Demais achados: oito páginas de conteúdo representam eventos distintos (LIVE em duas datas; Farmelhor em duas cidades/datas) e aliasFCAjá301. Quatro descrições antigas foram diferenciadas/consolidadas no lote anterior. CostaEsmeralda temcanonical/alternatesPT/EN/ESrecíprocos eHTTP200; verificarcanonicalPTbarra. Sitemap histórico200eXML; TrailinMotion200,medição pontual. ProteçãoCloudflaree403atleta permanecem sem desativarWAF/auth; atleta requerloginno código. Nenhuma conclusãoGoogle.

Plano: baselineporhash; teste nativoApache do bloco isolado incluindo GET/HEAD e controles negativos; backuprecuperável; publicarum.htaccess e verificarrealmente cinco cadeias301->200/metadadospreservados e regressão34URLs; evidenciarRR-31 e classificaçãoRR-20; testar ecompilar2templatesBusiness; publicar/verificar19cenários.

TesteApache: previsão inicial de404paraPUT/DELETE era incorreta: Apache responde405paraarquivos nesse método. Ampliado com baseline e candidato lado a lado: controles devem conservar o retorno real, sem forçar métodos indisponíveis. Nenhuma produção alterada nessa etapa.

Verificações finais:35cenários nativosApache passaramcomparando baseline/candidato; 20formas de alias(GET/HEAD,com/sembarra) passaramna produção. Cinco cadeiasseguidas efetivamentesóum301comdestino200. Cinco controlesnegativos e metadadosdoscincodestinospreservados. Na amostra34URLs,29foraaliasespreservaramstatus/meta. CanonicalPTdeCostaEsmeralda combarra foi conferidoe os3idiomas200têmalternatesrecíprocosecanonicalpróprio. SitemapXMLhistórico válido5265URLs. Primeiropaineltestefalhouporesperar numeral35quandoaredaçãoeraTrintaecinco;assertajustadosàredaçãofinal,candidato19cenáriospassou. RuntimeRoadRunnerspublicadocombackup/17dependências;2templatesBusinesscompilados.

Business publicado: 19 cenários passaram após publicação, oito controles de acesso, dois hashes e dez dependências conferidos. Snapshot preservado. Documentação final em `_codex/docs/2026-10-06_seo_assessorias_revisoes.md`.
