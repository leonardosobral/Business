# SEO — correções de canonical e sitemap público

Lote autorizado por “prossiga com o plano”. As correções públicas RR-03, RR-04 e OR-01 foram publicadas e verificadas em 14/09/2026. A tradução foi solicitada em outra frente e não foi duplicada aqui.

## Escopo e resultado

- **RoadRunners:** o detalhe da notícia usa a tag já normalizada também nos parâmetros que alimentam canonical e alternates. Foram verificadas 12 notícias: 20 consultas de notícias, incluindo nove variantes PT/EN/ES com e sem barra e com parâmetro de campanha. Todos os casos declararam canonical com uma barra final e quatro alternates coerentes. As três listagens com page=2 preservaram seus canonicals.
- **RoadRunners:** o sitemap estático passou de 52 para 49 URLs, retirando exclusivamente /desafios/, /en/challenges/ e /es/desafios/. Os mesmos redirecionamentos HTTP 302 para login foram preservados.
- **OpenResults:** a tag bruta é codificada uma vez como segmento de URL; canonical, twitter:site e og:url recebem escape no atributo HTML. Atleta de Cristo Run preservou %3F no canonical, sem query ou fragmento acidental. Dois eventos de controle e a home preservaram seus canonicals.
- **Business:** snapshot publicado e tela verificada: sete frentes, quatro concluídas, três pendentes e uma P1 pendente. RR-03, RR-04 e OR-01 passam a concluídos, junto ao RR-02 anterior. As datas e métricas das auditorias antigas foram preservadas.

## Verificação

- Teste CFML focado RR-03/RR-04: 69 assertivas; baseline reproduziu // e os destinos privados.
- Teste CFML OpenResults: 9 tags e 6 atributos; baseline reproduziu ? transformado em query.
- Compilação Adobe: dois templates RoadRunners e dois OpenResults, todos aprovados. O snapshot Business também compilou (1/1).
- Verificação pública posterior: 31 URLs distintas, 32 solicitações de páginas/XML. Uma consulta ao desafio português excedeu 20 segundos; a repetição isolada concluiu em 1,20 s e manteve o mesmo 302 para login. As evidências originais e a repetição foram preservadas.
- Hashes e metadados de produção conferidos depois; Application.cfc e .htaccess preservados em ambos os sites, além do head e evento RoadRunners.
- O executor original de testes do Business sofreu timeout em etapas diferentes. O diagnóstico de energia confirmou períodos de Maintenance Sleep durante a execução, inclusive com temporizadores externos sem disparar. Limitar heap não resolveu; caffeinate -i também não impediu esse tipo de suspensão, e o host estava em bateria. Não houve mudança de runtime ou asserções para contornar os testes. Os 13 cenários passaram em grupos curtos: 42,386 segundos ao todo, zero retries e timeouts. Preservadas as 26 linhas de asserção JS, fixture CFML, guard real e timeout por processo de 60 segundos. Os hashes testados coincidiram com a fonte publicada; nenhum runner do repositório precisou ser alterado.

Não houve nova auditoria de 100 páginas nem novo censo dos sitemaps neste lote. Os números 99.360/33.096 e os avisos exibidos nos cartões continuam pertencendo às auditorias de 13/09. Esta conferência direcionada comprova as correções descritas, sem demonstrar a indexação escolhida pelo Google.

## Arquivos publicados

| Projeto | Runtime | SHA-256 publicado |
| --- | --- | --- |
| RoadRunners | `noticias/index.cfm` | `5bee969a731c3d7402f83aa7ea4a9ba0065ad468936c025584639a823cd25306` |
| RoadRunners | `sitemaps/index.cfm` | `8bf341c8f8b00a0c7b849b43541c821e57b43305bf610283c5239544debc6d20` |
| OpenResults | `evento/index.cfm` | `2c5c70aae6aa1f141a70d8ea620a3995844533f3fcc0e32576f592fe8fa5af73` |
| OpenResults | `includes/head.cfm` | `cbba7d3bdcf18527d60ac4ee2ece7a6911dc7488e3bbdc00330b4ccef750528b` |
| Business | `portal/includes/seo_queue_data.cfm` | `293cf2983497de7526ce13381c12b31349e96b2bac8f658f5d734b20d96da97e` |

## Recuperação

RoadRunners: backup privado `/var/backups/seo-metadata-RoadRunners-8ccxc5e0`. Conferir o hash atual contra o publicado antes de restaurar somente o arquivo necessário de before/, com seus metadados. A versão anterior do sitemap contém a recuperação do inventário e deve ser preservada.

OpenResults: recuperar os dois arquivos do commit `e769528c34b23beb6fc3a16ea615184849ce5e5c` com git show e republicar somente esses arquivos após comparar hashes. A produção anterior correspondia exatamente a essa referência. Nenhum backup avulso de deploy foi criado; a pasta temporária de compilação/transporte foi removida.

## Próximas frentes

RR-01: tags especiais ainda bloqueadas ou desviando para busca, além de canonical com aspas no RoadRunners. SH-01: hierarquia de títulos. OR-02: intenção da política Googlebot. Traduções: validar geração e salvamento, consumo por idioma e cobertura de eventos antigos na frente já solicitada. Agenda recorrente e dados Search Console/GA4 permanecem separados.

Sem alterações de banco, políticas de acesso, credenciais ou rotas globais. Sem commit, branch, tag, push ou PR. Mudanças preexistentes foram preservadas.


## Conclusão da fila no Business

Publicado em 2026-09-14T12:46:37.989132+00:00 (UTC), com recuperação em `/var/backups/seo-metadata-Business-vprnt2rk`. Somente portal/includes/seo_queue_data.cfm foi substituído. Hash, proprietário e permissões confirmados; backend, view, Application.cfc e guards de autenticação permaneceram inalterados.

Navegador autenticado confirmou quatro concluídas e três pendentes, incluindo a evidência expandida de RR-03. Desktop 1530 px e celular 390 px sem transbordamento horizontal; viewport restaurado e aba marcada como entrega. Sem sessão: rota principal 302 e os três templates diretos 403, sem exposição de dados da fila.

Revisão independente com Astra aprovou os diffs e o procedimento de publicação. As falhas ambientais e a repetição pública foram preservadas no registro; não são apresentadas como execuções aprovadas. Nenhuma pendência deste lote de três correções permanece. As outras frentes do plano continuam abertas.

Evidências privadas: `/Users/Shared/RunnerHubReports/seo/metadata-review-20260914/`.
Recibo consolidado: [2026-09-14_seo_canonicals_publicacao.json](/Users/Shared/Projects/RunnerHub/Business/_codex/docs/2026-09-14_seo_canonicals_publicacao.json).
