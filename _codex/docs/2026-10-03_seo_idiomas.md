# SEO: idiomas, nova auditoria e painel publicado

Lote concluído em 03/10/2026. Continuação do plano de SEO e SEO para IA; revisão final com Astra e publicação de três arquivos de runtime após validação.

## Entrega

- Novo check de **reciprocidade entre idiomas** na aba SEO para IA. Compara os conjuntos de hreflang, a própria página, links de retorno e a entrega/canonical dos destinos presentes na mesma auditoria. Não faz requests adicionais e não considera destinos fora da amostra como aprovados.
- A busca em português não identificava a rota para o head compartilhado. Foi acrescentada somente `REQUEST.currentRouteKey = "search"` em `busca/index.cfm`. As três versões agora entregam PT/EN/ES e x-default, com canonical próprio. Termo e estado foram preservados no teste CFML.
- Tradução do conteúdo principal aparece como item separado e não medido. A reciprocidade não prova que a descrição está traduzida; o cron de tradução continua com seu acompanhamento próprio.
- Exemplos de erro e atenção precedem casos com evidência incompleta. Os pesos e a fórmula da nota técnica foram preservados.

## Auditorias datadas

| Site | Auditoria em Brasília | URLs descobertas | Páginas inspecionadas | Erros / avisos brutos | Nota técnica |
|---|---|---:|---:|---:|---:|
| Road Runners | 03/10, 16:21 | 103.049 | 100 | 1 / 12 | 70,0 |
| Open Results | 03/10, 16:05 | 34.321 | 100 | 0 / 0 | 100,0 |

Descoberta completa: índice e sete filhos Road Runners; índice e quatro lotes Open Results. As amostras não cobrem todo o acervo. Sem nova reconciliação com o banco. Road Runners continua com 95.037 URLs nos três lotes históricos, além de eventos futuros e demais páginas.

O único erro HTTP Road Runners é o 404 da notícia retirada editorialmente, cuja ausência no sitemap já foi conferida. Os avisos incluem três caminhos privados que levam ao login, dois canonicals de notícias para a fonte externa e a diferença de caixa `%0D`/`%0d`. As regras técnicas legadas e seus achados brutos foram mantidos. Esses achados não autorizam remover autenticação ou republicar conteúdo rejeitado.

O histórico técnico do Open Results confirmou a mesma amostra e cobertura: 95,0 → 100,0, +5,0 pontos. Road Runners apresenta amostra diferente, sem comparação direta de progresso. A nota é interna, baseada no pior resultado de cada critério; não é nota Google/WooRank nem chance de citação por IA.

Reciprocidade Road Runners: **18 páginas aprovadas, 8 com atenção, 74 sem evidência suficiente**. Os oito avisos correspondem às duas notícias com canonical externo e seis versões EN/ES de Sobre/Ajuda/Privacidade sem retorno nas versões PT. As três buscas passaram na auditoria posterior à publicação. Open Results não declara alternates na amostra e permanece não medido nesse check, sem penalidade na nota técnica.

## Fila atual

**14 itens: 10 concluídos e 4 pendentes.**

- **OR-02:** noindex publicado e robots correto na origem, mas cache público Cloudflare ainda entrega `/resultados` bloqueado. O cabeçalho `max-age=3600` não confirmou o TTL efetivo da borda: a resposta antiga persistiu com Age superior a 3600. Ainda é necessária limpeza ou expiração efetiva. A remoção do índice depende de nova leitura pelos buscadores; Search Console privado não foi consultado.
- **SH-02:** completar e conferir fatos dos eventos com fonte comprovada. A cobertura atual pede revisão em 41 de 42 eventos Road Runners e 96 de 99 Open Results. A consulta anterior confirmou organizador nomeado nesse papel em 1.332 de 34.320 eventos ativos. Não preencher com cronometrador ou informação presumida.
- **RR-08:** conferir a intenção editorial dos canonicals externos nas duas notícias; preservados até essa decisão.
- **RR-09:** completar os links de idioma das páginas institucionais em português. A correção da busca foi encerrada em RR-07 e não resolve essas outras rotas.

Etapas seguintes do plano: conferir traduções entregues, verificar identidade/acesso real dos provedores nos logs e reunir evidências datadas de citações e visitas. Permanecem não medidas; permissões declaradas e sucesso do nosso coletor não substituem essas evidências.

## Verificação e publicação

- 53 testes Node aprovados; regressões novas observadas falhando antes da implementação.
- Teste CFML da busca nos três idiomas aprovado; baseline falhou com zero alternates em PT.
- Dois testes Python com cinco cenários de publicação/evidência rejeitados corretamente. A revisão Astra identificou as duas lacunas; os ajustes tiveram falha reproduzida antes da correção.
- Nove cenários CFML de contrato, renderização, dados inválidos e acesso negado aprovados. O teste passou a reconhecer corretamente os acentos escapados pelo encoder HTML.
- Compilação Adobe de três templates aprovada antes da publicação; hashes dos três arquivos publicados confirmados. Oito arquivos de dependência/outras frentes permaneceram iguais aos baselines.
- Renderização real dos templates publicados no Adobe confirmou as duas auditorias, notas, novos checks e totais 14/10/4. Fixture administrativa temporária, restrita a GET + loopback + chave efêmera, removida no final. Isso não valida o login real de um usuário.
- Prévia do HTML produzido pelo Adobe conferida em 1280 px e 390 px, sem rolagem horizontal. Detalhe abre por clique e fecha por Enter. Capturas em `../staging/seo-languages-20261003/panel-desktop.png` e `panel-mobile.png`; viewport restaurado e prévia encerrada.

Runtime publicado: Road Runners `busca/index.cfm`; Business `portal/includes/seo_score_data.cfm` e `portal/includes/seo_queue_data.cfm`. O template de busca veio do baseline de produção, que difere do checkout; só a nova linha foi aplicada em cada versão. Outros arquivos locais não foram sobrescritos. Sem commit, branch, push ou PR.

Backups recuperáveis:

- `/var/backups/seo-hreflang-roadrunners-20261003/baseline`
- `/var/backups/seo-languages-business-20261003/baseline`

Evidências locais em `../staging/seo-languages-20261003/`: manifestos de preparação/publicação, hashes, verificações pública e da auditoria, snapshots, resultado do painel, testes e revisão Astra. Relatórios completos e histórico permanecem privados em `/Users/Shared/RunnerHubReports/seo`, fora de Git e docroot.

Referência do check: [Google — versões localizadas](https://developers.google.com/search/docs/specialty/international/localized-versions), consultada em 03/10/2026.
