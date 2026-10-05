# Operação da auditoria SEO — ciclo 1

## Integração Semrush — 04/10/2026

Atualização posterior: auditoria concluída às 14:39, consultada às 14:45 (Brasília), snapshot `6ac28c9356eeefef0a15555c`. Estado `FINISHED`, 500 páginas rastreadas (limite 500), 114 ocorrências de erro, 6.293 avisos e 60 observações. Totais reconciliados entre `info` e a soma das categorias do `snapshot`; não são páginas únicas. A nota técnica 68 retornada pelo fornecedor não foi promovida a nota geral do site. Estado e totais finais publicados na aba Semrush, preservando integralmente a coleta de palavras-chave/concorrentes. Evidências privadas em `20261004T174533Z/audit-state.json` e `evidence.json`, sob a raiz Semrush indicada abaixo. O relatório detalhado `snapshot` consumiu 10.000 unidades conforme a resposta; evitar repetir sua consulta para apenas conferir estado, usando `info`.

Triagem inicial da auditoria: 42 ocorrências de conflitos de hreflang; 27 de títulos duplicados; 27 de descrições duplicadas; quatro de URLs inadequadas em sitemap; quatro de links internos quebrados. Foram consultados três exemplos por categoria para hreflang, sitemap e links internos. Exemplos de hreflang incluem `/videos/?page=3`, `4` e `5`; exemplos de sitemap vêm de `/sitemaps/news-recent.xml`; os três links internos retornados apontam a `/cdn-cgi/l/email-protection`. São apontamentos Semrush ainda sujeitos a validação pública, não confirmação de defeito factual nem correções aplicadas. Os avisos mais volumosos são arquivos não minificados (2.786) e redirecionamentos temporários (2.762); não inferir prioridade comercial pelo volume.

Release da conclusão: `_codex/staging/seo-semrush-finished-20261004/`, dois templates compilados e publicados (`seo_semrush_data.cfm` e `seo_semrush.cfm`), 19 cenários Adobe antes/depois, hashes verificados e nove dependências preservadas. Backup `/var/backups/seo-semrush-finished-20261004/baseline`. Recuperação guardada: `python3 _codex/staging/seo-semrush-finished-20261004/release.py rollback`. Gerador e seis testes existentes passam; para reproduzir a versão final, usar o `--audit-state` da pasta `20261004T174533Z`. As informações a seguir registram a publicação inicial, enquanto a auditoria ainda rodava.

Publicada a aba administrativa `/portal/seo/?aba=semrush`, com seções de oportunidades, palavras-chave e concorrentes. Escopo inicial: RoadRunners, base Brasil, desktop; consulta importada às 14:15 (Brasília). O gerador offline `_codex/scripts/seo_semrush_snapshot.py` consome as respostas MCP salvas e gera `portal/includes/seo_semrush_data.cfm`. A view `portal/conteudo/seo_semrush.cfm` preserva a exigência de administrador, nega acesso direto e métodos diferentes de GET. `portal/conteudo/seo.cfm` apenas acrescenta a navegação e a inclusão da nova view.

A primeira referência contém 993 palavras-chave informadas pelo fornecedor, 75 nas posições 1–10 e tráfego mensal estimado de 1.234. As duas consultas limitadas a 30 linhas resultaram em 51 pares palavra-chave/URL e 49 termos distintos após deduplicação; não representam a lista completa de palavras nem a cobertura do índice Google. A tela mantém o timestamp próprio de cada posição. Seis oportunidades curadas aparecem como “A investigar”, sem presumir falha ou correção aplicada. Os dez domínios concorrentes retornados são sobreposição de busca, não uma seleção automática de concorrentes comerciais.

Respostas originais ficam fora do Git e do docroot, em `/Users/Shared/RunnerHubReports/seo/semrush/roadrunners/`. Baseline: `20261004T171554Z/baseline.json`. Consulta de estado da auditoria: `20261004T173901Z/audit-state.json`. Às 14:39, o projeto 26661911 estava `CHECKING`, com 500 páginas rastreadas e limite de 500. A última auditoria concluída retornada era de 07/10/2025. Os contadores antigos de erros/avisos não foram promovidos a resultados atuais. O painel registra o estado consultado, não monitora progresso ao vivo.

Para reproduzir o snapshot, passar os arquivos privados ao gerador:

```sh
python3 _codex/scripts/seo_semrush_snapshot.py \
  --baseline /Users/Shared/RunnerHubReports/seo/semrush/roadrunners/20261004T171554Z/baseline.json \
  --audit-state /Users/Shared/RunnerHubReports/seo/semrush/roadrunners/20261004T173901Z/audit-state.json \
  --output /private/tmp/seo_semrush_data.cfm
python3 -m unittest _codex.tests.test_seo_semrush_snapshot
```

Atualizações exigem nova consulta MCP, preservação da resposta privada, geração, revisão e publicação do snapshot. Não há cron, chamadas ao fornecedor no runtime ou integração automática ao Search Console. A consulta inicial de Position Tracking retornou `targets: null`; acompanhamento diário não foi confirmado. Nenhuma migração, credencial ou dado factual de evento foi alterado.

Release: `_codex/staging/seo-semrush-20261004/`; backup do servidor em `/var/backups/seo-semrush-20261004/baseline`. Três templates compilados e publicados, hashes verificados e oito dependências preservadas. Dezenove cenários Adobe foram executados antes e depois da publicação, incluindo oito verificações de acesso (anônimo, delegado, acesso direto e POST), busca, escape, vazio, OpenResults sem dados e regressão das abas anteriores. Revisão visual do HTML renderizado em 1280 px e 390 px; tabela com rolagem interna sem overflow da página. Rota pública sem sessão redireciona à entrada; não foi usada sessão administrativa real no navegador. Recuperação: `python3 _codex/staging/seo-semrush-20261004/release.py rollback`, com guardas de concorrência.

Implementação: 13/09/2026. Escopo: coletor, regras, relatórios privados, piloto nos dois sites e painel administrativo com revisão curada. Agenda recorrente e integrações de contas Google continuam etapas posteriores.

Às 21:26 de 13/09 (Brasília), o RoadRunners obteve sua primeira descoberta completa: 99.360 URLs, 100 páginas analisadas, 0 falhas operacionais, 1 erro de página e 111 avisos. O cadastro de 33.095 eventos ativos foi reconciliado nos três idiomas. Ver [recuperação do inventário](2026-09-13_seo_descoberta_execucao.md). A tela distingue URLs coletadas e páginas analisadas; uma rodada completa pode conter erros.

## Componentes

- RoadRunners: `_codex/scripts/seo_inventory.mjs` mantém a CLI; `_codex/scripts/seo/` contém o pacote Node isolado, parsers e testes. Requer Node.js >=22; dependências exatas no lockfile. Não publicar esse diretório no docroot.
- Business: `_codex/scripts/seo_run.mjs` executa uma rodada por site, aplica orçamento e lock; `seo_report.mjs` escreve/verifica artefatos e compara com a última rodada completa.
- Configuração pública: `_codex/analyses/seo_monitoramento/sites.json`. Domínios separados e URLs estratégicas reais selecionadas das homes em 13/09. O runner não depende de consultas ao banco nem importa runtime CFML de outro projeto.
- Relatórios privados instalados para este ambiente: `/Users/Shared/RunnerHubReports/seo`. Diretórios 0700, arquivos 0600, fora do workspace Git e do docroot. Não copiar exports privados ou observações para o repositório.

## Executar manualmente

No diretório Business, com Node disponível:

```sh
SEO_INVENTORY_CLI=/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs SEO_REPORT_ROOT=/Users/Shared/RunnerHubReports/seo node _codex/scripts/seo_run.mjs roadrunners
SEO_INVENTORY_CLI=/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs SEO_REPORT_ROOT=/Users/Shared/RunnerHubReports/seo node _codex/scripts/seo_run.mjs openresults
```

Esses caminhos são configuração do executor local, não dependências do runtime web. Em outro host, instalar a distribuição do coletor e definir as duas variáveis para caminhos próprios. Não presumir Node no servidor web. O cron HTTP existente no Business não executa `.mjs` diretamente.

Cada comando faz uma rodada; **nenhuma agenda é criada**. Executar os sites sequencialmente. O piloto usa no máximo 100 páginas, concorrência 2 e 1 request/s, incluindo cada hop de redirect. Recurso: deadline de 15 s incluindo corpo; rodada: até 10 min; descoberta: até 100 sitemaps e 150 mil URLs. Sitemaps/robots são solicitações adicionais contabilizadas no orçamento temporal e de taxa. Limites alcançados não são ampliados automaticamente.

Em 29/09/2026, a descoberta RoadRunners ultrapassou o teto anterior de 100 mil URLs. O teto foi revisado manualmente para 150 mil para comportar o inventário, preservando todos os demais limites. A tentativa parcial foi mantida nos relatórios privados. A alteração de configuração interrompe a comparação numérica com a base anterior; não tratar a diferença de notas como progresso comprovado.

O próprio coletor respeita robots, inclusive em redirects, sem sessão/cookies e sem simular crawler autenticado. Host e porta precisam corresponder à origem permitida. Três respostas consecutivas 429/5xx interrompem o host; 429 tem até duas novas tentativas respeitando Retry-After dentro do orçamento.

## Ler o resultado

O comando imprime `run_id`, estado, exit code e caminhos. Em `<raiz>/<site>/<run_id>/`:

- `manifest.json`: versões/hashes, horários, limites, cobertura, modo e integridade dos arquivos.
- `observations.jsonl`: evidência por URL e sitemap de origem; sem guardar HTML completo por padrão.
- `inventory.csv`: dez colunas legadas na mesma ordem; texto protegido contra fórmulas de planilha.
- `findings.json`: achados atuais com regra, gravidade e evidência.
- `comparison.json`: novos, persistentes, resolvidos e não rechecados. Pendências sobrevivem a amostras rotativas compatíveis.
- `summary.md`: relatório legível em português.

`counts.errors` conta erros SEO/página; a lista `errors` contém falhas operacionais, como XML inválido ou timeout na descoberta. Zero erros SEO pode coexistir com uma rodada parcial por falha operacional.

`latest-complete.json` aponta somente para uma rodada completa com manifesto verificado. Completa significa que o escopo planejado terminou; pode haver erros SEO (`exit 2`). Não significa site saudável ou auditado integralmente. Uma rodada parcial conserva os dados anteriores; recuperar prefixo JSONL válido permite registrar evidência após interrupção.

| Estado/código | Interpretação |
| --- | --- |
| `complete/sample`, exit 0 | Amostra planejada concluída, sem erros da modalidade; warnings podem existir |
| `complete`, exit 2 | Coleta concluída e problemas encontrados |
| `partial` ou `failed`, exit 1 | Falha operacional ou orçamento/cobertura incompleta; não resolver pendências antigas |
| `already_running`, exit 1 | Lock existente; uma segunda coleta não foi iniciada |

HTTP 200, sitemap e canonical declarado não comprovam indexação. `--deep` captura HTML no contrato legado; `--audit` implica GET e aplica as regras. HEAD não avalia metadados HTML. Respostas sem Content-Type ou sem conteúdo ficam explícitas; latência de request não é Core Web Vitals.

## Amostragem e comparação

O conjunto inclui URLs estratégicas, pendências da última rodada completa e seleção determinística por família de rota/idioma. A lista e seu hash ficam no manifesto. O piloto mantém o conjunto de base; não há rodízio periódico ativado. O comparador aceita conjuntos diferentes quando a política continua compatível, mas nunca resolve achados de URLs ausentes ou sem rechecagem válida.

Mudanças de site, modo, schema, versão de regras ou hash de configuração tornam os snapshots incompatíveis. O relatório explica a diferença. Não somar resultados de amostras como se fossem cobertura integral. A descoberta por sitemap não detecta todo conteúdo que falta no próprio sitemap.

## Incidentes e recuperação

- `SIGINT`/`SIGTERM` pedem cancelamento controlado; dados concluídos são preservados. Se o processo for morto antes do JSON final, o runner recupera linhas JSONL completas e registra cauda truncada.
- Se houver crash do executor, verificar o PID em `<raiz>/.locks/<site>.lock` e se ainda existe uma coleta antes de remover o lock abandonado. O lock de gravação `<raiz>/<site>/.report-write.lock` também exige inspeção; não há tomada automática de lock.
- Se algum hash divergir, não utilizar o relatório como baseline. Preservar o arquivo para diagnóstico e gerar nova rodada válida. Hash detecta corrupção; a autenticidade depende do diretório privado.
- Reinstalação do pacote: `npm ci --ignore-scripts --no-audit` em `RoadRunners/_codex/scripts/seo`. Não restaurar o workspace inteiro nem alterar código público para resolver problema do executor.
- Não há rotina de descarte instalada. Retenção deve ser configurada explicitamente após medir o volume; este ciclo apenas grava relatórios.

## Testes

```sh
node --test _codex/tests/seo_report.test.mjs _codex/tests/seo_run.test.mjs
npm --prefix /Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo test
```

As fixtures do coletor usam servidor HTTP apenas em loopback; sandboxes que bloqueiam listen exigem autorização específica para executar os testes. Os testes não acessam os sites de produção.

## Piloto de 13/09/2026

- RoadRunners: 100 páginas inspecionadas; descoberta parcial com 1.090 URLs aceitas, um lote com URLs inválidas e dois timeouts de 15 segundos. Sem baseline completa para comparação.
- OpenResults: 33.096 URLs descobertas, amostra completa de 100 páginas, zero erros operacionais/SEO e dois warnings. É uma baseline técnica da amostra, não aprovação do acervo inteiro.
- Critérios e fila de correções: `2026-09-13_seo_piloto_fila.md`. A primeira comparação longitudinal real ainda não foi realizada.

## Próxima etapa

Usar os relatórios do piloto para uma fila com URL, evidência, regra, impacto, projeto responsável e critério de aceite. Correções de conteúdo e runtime público precisam ser verificadas na origem e publicadas em lotes restritos conforme as instruções de cada projeto. O coletor e a futura agenda não corrigem produção automaticamente.

Search Console e GA4 entram por fontes autorizadas, primeiro com exportações validadas. Acesso ausente é “não conectado”, não zero. Manter cliques/impressões GSC, sessões GA4 e audiência própria com suas definições. Não há conexão dessas contas nesta entrega.


## Consulta no Business

Desde 13/09/2026, a fila revisada está disponível em `/portal/conteudo/?visao=seo`, ligada a Conteúdo das provas e restrita a administradores. É uma apresentação datada de sete frentes, com filtros e critérios de conclusão. Não sincroniza os relatórios automaticamente nem dispara coleta. Ver `2026-09-13_seo_fila_publicacao.md` para arquivos, validação e atualização do snapshot. O painel com ingestão de auditorias e integrações Google permanece uma evolução posterior.

## Relatório visual e nota interna (14/09/2026)

A tela `/portal/conteudo/?visao=seo` apresenta os critérios aprovados, avisos, erros e verificações não medidas, além da fila de correções. A nota interna usa dez critérios com pesos fixos e o pior resultado de cada critério. O contrato completo está em `2026-09-14_seo_relatorio_pontuacao.md`.

Depois de concluir novas rodadas válidas dos dois sites, gere o snapshot do relatório, a partir do repositório Business:

```sh
node _codex/scripts/seo_scorecard.mjs \
  --reports-root /Users/Shared/RunnerHubReports/seo \
  --history-root /Users/Shared/RunnerHubReports/seo/score-history \
  --output /Users/Shared/Projects/RunnerHub/Business/portal/includes/seo_score_data.cfm
```

O gerador valida os relatórios e seus ponteiros de integridade antes de produzir dados. O histórico privado é idempotente por execução/método e precisa ser preservado entre rodadas. Não mover esse diretório para o docroot. A nota inicial usa a auditoria de 13/09; verificações direcionadas de correções não reescrevem a nota anterior. Diferenças de amostra, método, coletor ou cobertura interrompem a comparação numérica de progresso.

Revisar o snapshot gerado e publicar somente `portal/includes/seo_score_data.cfm` pelo procedimento de baseline, backup, compilação e verificação real. A página não inicia coleta ao recarregar. Gerar o arquivo local não atualiza a produção, e esta entrega não instala agendamento automático.

Validação dos cálculos e preservação do contrato operacional:

```sh
node --test _codex/tests/seo_scorecard.test.mjs _codex/tests/seo_report.test.mjs _codex/tests/seo_run.test.mjs
node _codex/scripts/test_seo_queue_cfml_local.mjs --list
node _codex/scripts/test_seo_queue_cfml_local.mjs score-contract render-score-filtered
```

O runner CFML também aceita um nome de cenário por execução para evitar que suspensão do host interrompa uma bateria longa. Isso não substitui a compilação Adobe nem a conferência autenticada do resultado publicado.

### Endereço próprio de SEO

Desde14/09/2026, acessar `/portal/seo/` pelo menu **Marketing e audiência → SEO**. Conteúdo das provas permanece em `/portal/conteudo/`, em **Conteúdo e portal**. O endereço anterior com `?visao=seo` redireciona preservando os filtros permitidos. Detalhes e recuperação em `2026-09-14_seo_navegacao.md`.

### SEO para IA (29/09/2026)

O painel agora separa `?aba=relatorio`, `?aba=ia` e `?aba=fila`. O mesmo gerador acima inclui `aiChecks` no snapshot: permissão declarada para OAI-SearchBot e PerplexityBot e entrega de HTML pelo coletor. Ausência de evidência é “não medido”; permissão não comprova acesso efetivo nem citação. A nota e o histórico técnicos permanecem independentes, sem nota ou série histórica de IA nesta etapa. Filtros e links antigos de itens da fila são preservados. Ver `2026-09-29_seo_ia.md`.

### Metadados e eventos (29/09/2026, 21:22 Brasília)

Nas novas coletas GET, o coletor acrescenta `metadata_version: 1`, `description_values`, `html_lang`, `hreflang`, `jsonld` e `event_metadata`. Usa o parser HTML já instalado. A checagem JSON-LD reconhece objetos, arrays e `@graph`; não é um validador completo de Schema.org. Eventos guardam somente nome/data/cidade e indicadores de presença/coincidência, sem corpo HTML, texto integral ou resultados de atletas.

O gerador Business mede descrição única e não vazia; alternates básicos com idioma/URL/duplicatas/autorreferência; JSON-LD analisável; e cobertura de campos de evento. Reciprocidade, tradução e confirmação dos fatos continuam revisões próprias. Ausência de hreflang em página de idioma único não é classificada automaticamente como erro. Auditorias antigas sem a versão de metadados continuam “não medidas”. “Medição parcial” distingue checks com evidência em parte da amostra.

Os três critérios técnicos adicionais têm peso zero; os dez pesos existentes e `technical-checks-v1` permanecem. O hash novo do coletor interrompe a comparação com coletas anteriores; a nota igual não prova ausência de melhorias. Uma nova coleta só atualiza a produção depois de gerar, conferir e publicar o snapshot. A fila é curada separadamente; não inferir resolução de URLs que não foram rechecadas.

As amostras de 29/09 às 21:13 descobriram 102.509 URLs Road Runners e 34.144 Open Results, inspecionando 100 por site. Publicação, limites, pendências e evidências em [entrega de conteúdo](2026-09-29_seo_ia_conteudo.md).


## Lote editorial derivado do Semrush — 04/10/2026

Fonte: projeto 26661911, snapshot 6ac28c9356eeefef0a15555c, concluído às 14:39 de Brasília. Quatro consultas `issue_details` (IDs 24, 18, 6 e 15, limite 50) retornaram a lista completa desses grupos; uso informado 0 unidades. A triagem não iniciou outra auditoria. Evidências operacionais em `_codex/staging/seo-semrush-fixes-20261004/`.

Causas confirmadas em GET público: dez URLs de notícias/vídeos tinham canonical paginado e hreflang para a página 1; 27 URLs de listagens/canais compartilhavam títulos e descrições; quatro notícias do sitemap declaravam canonical externo. O restante dos 42 conflitos de hreflang era composto por 32 URLs de busca. A busca apresentou divergência entre local e produção e foi preservada, com hash observado durante a publicação.

RoadRunners publicou quatro arquivos: `includes/estrutura/head.cfm`, `videos/index.cfm`, `noticias/index.cfm`, `sitemaps/index.cfm`. O head recebe paginação apenas quando a listagem editorial a informa; página 1 continua sem query. Metadados incluem canal real e a tradução existente de página/total. O sitemap exclui `external_only` e `licensed_full` com canonical diferente da URL local; preserva `summary_link`, conteúdo sem fonte externa e URL autocanônica. A política de atribuição das notícias permanece intacta. Não houve mudança de banco, datas, conteúdo, traduções ou regras da Cloudflare.

Verificações: teste público falhou antes e passou depois nas mesmas 36 URLs; 32 cenários Adobe (24 combinações editoriais e oito políticas de sitemap), quatro templates compilados, revisão independente sem bloqueadores e 22 controles públicos adicionais. As 14 notícias restantes no sitemap retornaram 200 e canonical próprio. Três controles de vídeo com página 2 em canal de uma única página mantiveram a normalização já existente para página 1, de forma consistente entre canonical e alternates. Home e evento preservados. O runner local legado de sitemap não executou porque o runtime Lucee temporário não existe mais; a validação CFML deste lote foi executada em Adobe, sem instalação alternativa.

Business: item RR-17 registra entrega técnica e limitações; o aviso na aba Semrush liga à evidência. A fila passa a 25 frentes, 19 concluídas e seis pendentes; RR-17 cobre somente o lote editorial, não os 32 alertas de busca. Contadores Semrush 114/6.293/60 e métricas históricas não foram recalculados. Reauditoria do fornecedor e confirmação de indexação continuam pendentes. Dois templates compilados e 19 cenários do painel verificados, incluindo oito checks de acesso.

Backups recuperáveis: `/var/backups/seo-semrush-editorial-20261004/baseline` (RoadRunners) e `/var/backups/seo-semrush-editorial-panel-20261004/baseline` (Business). Os scripts `release.py rollback` de cada staging conferem hashes e recusam sobrescrever alterações concorrentes. Publicação restrita a quatro e dois arquivos; seis e nove dependências, respectivamente, preservadas. Sem operações Git.

Referência de critérios: https://developers.google.com/search/docs/specialty/international/localized-versions e https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading . HTTP e metadados não comprovam indexação.


## Segundo lote Semrush: buscas — 04/10/2026

RR-18 registra a correção dos 32 conflitos restantes de hreflang do snapshot 6ac28c9356eeefef0a15555c. Apenas `RoadRunners/busca/index.cfm` mudou em produção: o template decide a emissão dos alternates antes de adicionar parâmetros padrão ou derivados de localização. Permite GET sem parâmetros extras e os dois parâmetros internos do Apache (`i18n_lang`, `i18n_route`); outros parâmetros recebidos suprimem o conjunto nesta resposta. Preserva canonical da raiz localizada, robots, busca assíncrona, filtros e tradução. Não amplia indexação de combinações dinâmicas nem adiciona noindex. Duas alterações de rodapé presentes apenas em produção foram preservadas e sincronizadas localmente.

Validação: 99 cenários Adobe (baseline falhou em 72, candidato final passou), compilação e revisão independente. GET público de 37 URLs: 32 exemplos do fornecedor, três raízes e dois controles. Todos 200; raízes com quatro alternates recíprocos e 34 variantes sem alternates. Canonical, title, description e robots coincidem com o baseline. A primeira abordagem baseada em CGI.REQUEST_URI não passou na conferência pública das três raízes e foi imediatamente revertida; a versão final foi novamente conferida nos mesmos endereços. Esse incidente e o rollback estão documentados no staging, sem exposição de dados ou mudança de banco.

Stagings: `seo-search-language-20261004` e `seo-search-language-panel-20261004`. Backups finais: `/var/backups/seo-search-language-v2-20261004/baseline` e `/var/backups/seo-search-language-panel-v2-20261004/baseline`. Hashes de seis dependências RoadRunners e nove Business preservados. O painel registra RR-18 e atualiza a referência de RR-17; 26 frentes, 20 concluídas e seis pendentes. Os 19 cenários de painel incluem oito controles de acesso e mantêm filtros, 51 palavras-chave e seis oportunidades. Nenhuma nova consulta Semrush ou auditoria foi iniciada: 114 erros, 6.293 avisos e 60 observações continuam sendo os números históricos do fornecedor. Não afirmar redução ou indexação sem nova evidência.

Próximas frentes: reauditar no Semrush para confirmar os dois lotes; verificar o restante das ocorrências do snapshot por URL, especialmente erros de rastreamento/4xx e conteúdo duplicado. Manter oportunidades de palavras-chave e correções factuais em suas filas próprias. Não contar links de proteção de e-mail Cloudflare como páginas quebradas antes de verificar o comportamento real.


## Terceiro lote Semrush: avatares e triagem de acesso — 04/10/2026

Fonte: mesmo projeto 26661911 e snapshot 6ac28c9356eeefef0a15555c. Seis consultas issue_details completas (2, 7, 8, 9, 13 e 111), uso informado zero unidades; nenhuma nova auditoria. Evidências sem nomes/resultados de atletas em `_codex/staging/seo-semrush-access-20261004/`.

RR-19: Semrush apontava imagem 404 no ranking catarinense de trail run. O valor legado `avatar/athlete/large.png` do Strava era selecionado como URL relativa; também ocorria uma vez em corrida de rua. Alterada apenas a expressão SQL de seleção da imagem em `circuitocatarinense/trailrun/index.cfm` e `circuitocatarinense/corridaderua/index.cfm`, com o padrão já adotado no feed. Ignora placeholders relativos e vazios; mantém HTTP(S), caminhos iniciados por barra e fallback existente. Sem mudança de banco, pontuação, filtros ou ordem do ranking.

Validação: 26 casos sintéticos Adobe/PostgreSQL (16 falhas no baseline, todos passaram no candidato), dois templates compilados, revisão independente sem bloqueadores. Depois da publicação, ambas as páginas responderam 200, sem avatar relativo inválido e com title/canonical/robots preservados; o fallback respondeu 200 image/png. Trail run levou 0,98 s e corrida de rua 7,36 s nesta medição. Isso não resolve a latência. Cinco dependências preservadas por hash. Backup: `/var/backups/seo-semrush-avatar-20261004/baseline`; release.py rollback recusa sobrescrever mudanças concorrentes.

RR-20 mantém pendente a triagem restante. As três páginas não rastreadas responderam 200, mas corrida de rua levou 12,43 s na primeira checagem. O evento Lupo apontado como lento respondeu em 0,45 s: acesso pontual não prova estabilidade. As quatro páginas de vídeos acusadas de duplicidade têm títulos e conjuntos de vídeos distintos (3, 5, 6 e 9 itens); não foram removidas, redirecionadas nem receberam noindex. Um 404 e quatro links internos referem-se ao endpoint de proteção de e-mail Cloudflare. Páginas de origem 200 com script decodificador; comportamento do link no navegador ainda pendente. Nenhuma proteção foi desativada.

Business: publicados somente `portal/includes/seo_queue_data.cfm` e `portal/conteudo/seo_semrush.cfm`. RR-19 concluído tecnicamente; RR-20 pendente. Fila: 28 frentes, 21 concluídas e sete pendentes. Dois templates compilados, 19 cenários antes e após publicar (oito de acesso), nove dependências preservadas por hash. Backup `/var/backups/seo-semrush-access-panel-20261004/baseline`. Staging `seo-semrush-access-panel-20261004`. Totais históricos Semrush 114 erros, 6.293 avisos e 60 observações preservados; baixa dos alertas e indexação não foram confirmadas. Sem operações Git.


## Reauditoria Semrush com 500 páginas — 04/10/2026, 15:40 Brasília

Nova evidência: projeto 26661911, snapshot `6ac29b3456eeefef0a3ff73b`, concluído às 15:40. Comparação com `6ac28c9356eeefef0a15555c` das 14:39: Site Health 68 → 76, erros 114 → 9 (−92,1%), avisos 6.293 → 6.356 e observações 60 → 126. As duas execuções têm 500 páginas, mesmo limite, agente, política de subdomínios, máscaras, parâmetros removidos e checks excluídos. Não foi comprovada identidade entre os conjuntos de URLs; o número de verificações varia. Não é evidência de indexação, tráfego ou receita.

Grupos da API: hreflang 42 → 0; descrições duplicadas 27 → 0; sitemap não canônico 4 → 0; imagens quebradas 1 → 0; títulos duplicados 27 → 2; páginas não rastreadas 3 → 1. Conteúdo duplicado 4 → 0, porém com oito checks contra 1.272 antes: não declarar correção global desse grupo, cujo conteúdo não foi alterado. A busca lenta mudou de URL; não tratar o contador estável como o mesmo caso.

Nove erros restantes: dois títulos nas URLs 2026/2027 da Corrida do Turismo ABAVSE; ranking catarinense de corrida de rua não rastreado; busca inglesa filtrada por 5 km lenta; um 404 e quatro links para proteção de e-mail Cloudflare. A identidade das edições precisa ser verificada antes de mudar dados ou redirecionar. Priorizar rastreamento e latência, depois os maiores grupos de avisos: 2.809 ocorrências de recursos sem minificação e 2.786 redirecionamentos temporários, que não equivalem a páginas únicas ou correções independentes.

Evidência privada em `/Users/Shared/RunnerHubReports/seo/semrush/roadrunners/20261004-reaudit-500/` (diretório 0700, arquivos 0600). Consultas info, snapshots, history e dez issue_details: uso agregado informado 50.200 unidades. O custo informado de history foi 20.000 e os grupos vazios 18/24 reportaram 20.000/10.000; as outras consultas detalhadas reportaram zero. Reusar esses dados e evitar consultar novamente grupos zerados. Nenhuma auditoria foi iniciada por ferramenta nesta etapa.

Preparado staging `seo-semrush-reaudit-20261004`: snapshot regenerado pelo gerador existente; evidência orgânica, 51 linhas de palavras-chave e seis oportunidades preservadas integralmente. Fila RR-17/18/19 recebe confirmação limitada à amostra; RR-20 lista os nove erros atuais. Não foram alterados site público, cadastros de eventos ou Cloudflare. A primeira validação Adobe do painel expirou no cenário competitors; a rota pública Business também expirou em 15 s. Candidatos compilados (três templates), sem publicação nessa tentativa. Revalidação em andamento; registrar abaixo o resultado final antes de declarar a atualização entregue.


Resultado desta etapa: a segunda renderização Adobe também expirou, desta vez em opportunities. Publicação não executada. Os três arquivos locais de runtime ainda correspondem ao baseline; comparação e atualização estão preparadas no staging, com três hashes iguais aos templates compilados, seis testes do gerador aprovados e revisão das fontes/guards concluída. Frases antigas de reauditoria pendente foram retiradas dos itens atualizados. Backup preparado em `/var/backups/seo-semrush-reaudit-20261004/baseline`. Retomar pelo `handoff.json`: repetir `verify_panel.py candidate`; somente após sucesso publicar, verificar hashes, executar os 19 cenários publicados e sincronizar os arquivos locais sob guarda de baseline. Não confundir o relatório novo recebido com painel já atualizado.


## Recuperação do Apache e conclusão da importação — 04/10/2026

O usuário autorizou o reinício do Apache com “prossiga” após pergunta explícita sobre a ação. Diagnóstico anterior: Chrome com 522; probes públicos e HTTPS local expiravam; SSH normal; 149 workers ocupados de 150; fila HTTPS 508/511. Não houve esgotamento de memória observado (cerca de 11 GB disponíveis), mas disco raiz estava em 91%. A porta interna 8500 respondeu 404 rapidamente; isso é evidência de resposta da porta, não validação funcional completa do ColdFusion.

Executado `apache2ctl configtest` (Syntax OK, aviso preexistente de DocumentRoot ausente de dev.espacocomunicar.com.br), seguido de `systemctl restart apache2`, com saída zero. Não foram alterados limites, regras Cloudflare, credenciais ou serviço ColdFusion. Após 22 s, 23 workers ocupados/27 livres; após 91 s, 3 ocupados/72 livres. Duas rodadas públicas: RoadRunners e OpenResults HTTP 200; Business SEO HTTP 302 sem sessão, CSS 200. Na segunda rodada tempos totais foram aproximadamente 0,29 s / 0,31 s / 0,11 s / 0,07 s. O Chrome autenticado também exibiu novamente a página SEO. Causa imediata confirmada: saturação do Apache; gatilho do acúmulo de requisições ainda não demonstrado. Não atribuir à auditoria Semrush nem declarar correção permanente sem evidência. Diagnóstico agregado em `_codex/staging/incident-20261004/`; não foram persistidos nomes, consultas ou conteúdo de resultados de atletas.

Com o acesso restaurado, retomada a atualização de `seo-semrush-reaudit-20261004`: 19 cenários Adobe candidatos passaram, três arquivos publicados sob guarda de baseline e backup, três hashes verificados e oito dependências preservadas. Mais 19 cenários passaram sobre a versão publicada, incluindo oito verificações de acesso. Arquivos locais sincronizados somente após verificar igualdade com o baseline. Snapshot gerado mostra 9 erros, 6.356 avisos e 126 observações; notas registram Site Health 68 → 76 e redução de 92,1% nos erros. Palavras-chave e métricas orgânicas anteriores preservadas. Backups em `/var/backups/seo-semrush-reaudit-20261004/baseline`; rollback guardado pelo script release.py. A fila continua com 28 frentes, 21 concluídas e sete pendentes. Sem operações Git.


## Ranking catarinense: otimização de consulta — 04/10/2026

RR-21 trata a página `/circuitocatarinense/corridaderua/`, apontada como não rastreada pelo snapshot Semrush `6ac29b3456eeefef0a3ff73b` de 15:40. Perfil no datasource real `runnerhub`: consulta anterior 7.149,512 ms, final 36,095 ms; 401 linhas idênticas por `EXCEPT ALL` bidirecional e hash integral, incluindo multiplicidade. A consulta calculava as seis somas repetidamente nos totais e participações. Agora materializa os inscritos distintos e seus resultados das seis etapas/percurso 21, agrega pontos uma vez e mantém o JOIN final original. A primeira tentativa, sem restringir os inscritos, foi mais lenta e descartada antes de qualquer publicação. Nenhum banco, índice, pontuação, cadastro, autenticação ou Cloudflare alterado.

Adobe/PostgreSQL: zero diferenças reais e sintéticas; consumidores preservam 135 linhas femininas, 266 masculinas e sete equipes, hash integral de equipes igual; caso sem inscrições vazio. Um template compilado, revisão independente aprovada. Testes finais repetidos explicitamente na conexão usada pelo RoadRunners, sem pressupor equivalência com o helper runner_dba. Transações dos testes somente leitura. Após publicação, página HTTP 200 em 0,298 s e 0,312 s, contra 8,057 s antes. Hashes das seis tabelas públicas incluem conteúdo e ordem e coincidem com o baseline; metadados preservados. Trail run, busca inglesa de 5 km e início retornam 200. Apenas metadados/contagens/hashes persistidos; nenhum nome ou HTML de resultados de atletas.

RoadRunners: um runtime publicado sob baseline, backup e substituição atômica; hash confirmado e cinco dependências preservadas. Backup `/var/backups/seo-ranking-performance-20261004/baseline`, staging `seo-ranking-performance-20261004`. Runtime local sincronizado após igualdade com baseline; documentação em RoadRunners `_codex/docs/2026-10-04_seo_ranking_catarinense.md`. Rollback guardado por `release.py`, sem sobrescrever alterações concorrentes.

Business: dois arquivos publicados (`portal/includes/seo_queue_data.cfm` e `portal/conteudo/seo_semrush.cfm`). RR-21 concluído tecnicamente, baixa do alerta Semrush ainda pendente; RR-20 mantém os nove erros do snapshot e aponta a entrega posterior. Fila 29 frentes, 22 concluídas e sete pendentes. Nota 76, nove erros, 6.356 avisos, 126 observações e snapshot gerado permanecem intactos; 51 linhas de palavras-chave e seis oportunidades preservadas. Dois templates compilados, revisão independente, 19 cenários candidatos e 19 publicados aprovados, incluindo oito controles de acesso. Hashes confirmados e nove dependências preservadas. Backup `/var/backups/seo-ranking-performance-panel-20261004/baseline`, staging `seo-ranking-performance-panel-20261004`. Sincronização local guardada.

Nenhuma nova consulta paga Semrush nem auditoria foi iniciada nesta etapa. Próximo: reauditar para confirmar rastreamento; investigar identidade e fontes das URLs ABAVSE 2026/2027, busca lenta e comportamento real dos links protegidos antes de encerrar os demais casos. Redução de latência e HTTP 200 não comprovam indexação ou a causa exata da falha do fornecedor. Sem operações Git.
