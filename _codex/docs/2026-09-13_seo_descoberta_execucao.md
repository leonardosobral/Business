# Recuperação do inventário SEO — 13/09/2026

Autorização: após o diagnóstico de que as 1.090 URLs eram uma descoberta parcial, o usuário pediu “prossiga”. Escopo: corrigir a descoberta dos sitemaps RoadRunners, reconciliar eventos com o cadastro e atualizar/publicar a apresentação no Business. OpenResults permanece com sua rodada anterior.

## Decisão e sequência

1. RoadRunners: manter consultas, cortes de data e paginação. Substituir a concatenação acumulativa do XML por fragmentos unidos uma única vez; codificar cada tag bruta como segmento de URL, preservando seus bytes e o escape XML posterior.
2. Validar CFML, equivalência do XML e caracteres especiais. Conferir baseline de produção, compilar em diretório privado, preparar backup e publicar somente `sitemaps/index.cfm`.
3. Medir os sete filhos com o deadline original de 15 segundos; reconciliar contagens e hashes de tags por idioma com uma consulta somente leitura. Executar uma nova auditoria de 100 páginas sem ampliar orçamento.
4. Business: distinguir URLs coletadas, páginas analisadas e cadastro de eventos; mostrar datas por site e atualizar RR-01/RR-02 conforme evidência. Publicar somente os templates alterados após testes, backup e conferência real.

## Diagnóstico anterior à correção

- Banco, transação somente leitura às 00:15 UTC de 14/09: 33.145 registros, 33.095 ativos, todos com tag e data; 30.400 históricos e 2.695 futuros/recentes segundo o corte do sitemap. São 99.285 variantes de evento em três idiomas, antes de somar páginas institucionais/editoriais.
- Históricos 1 e 2: timeout público de 45 segundos, sem recebimento de headers. A consulta SQL do histórico 1 executou em 58,84 ms nesta medição, sem escrita.
- Benchmark CFML local (Lucee): 45 mil URLs com concatenação acumulativa demoraram cerca de 31 segundos somente no render. A versão com fragmentos preservou bytes e hash do XML e executou em aproximadamente 0,1 segundo. Isso não substitui a verificação no Adobe ColdFusion de produção.
- A data do banco já era 14/09 UTC; o sitemap anterior ainda tinha 2.756 futuros, compatível com cache anterior ao corte de data. A reconciliação final usará evidência nova e também comparará o conjunto total, não apenas as divisões por data.

## Limites explícitos

Codificar tags permite descobrir e auditar suas URLs, mas não repara rotas já quebradas: as três variantes da tag com LF retornaram 403; as duas tags com `#` redirecionaram para a busca. RR-01 continuará aberto para esses problemas. Não alterar banco, proteções HTTP, autenticação, Application.cfc ou regras globais de roteamento neste lote. O cadastro contém outras tags com controles/delimitadores; elas não serão ocultadas do inventário.

Não criar commit, branch, tag, push ou PR. Preservar a rodada original e as alterações preexistentes.

Evidências de trabalho: `/private/tmp/runnerhub-seo-discovery-20260913/`. Evidências preservadas, fora do docroot e do Git: `/Users/Shared/RunnerHubReports/seo/discovery-review-20260913/`, com diretórios 0700, arquivos 0600 e manifesto de hashes. A lista completa de URLs fica em `discovered-urls.jsonl`; o CSV da auditoria contém as 100 páginas analisadas.

## Resultado verificado em produção

O sitemap RoadRunners foi publicado às **21:22:37 de 13/09 (Brasília)**, com backup em `/var/backups/seo-discovery-RoadRunners-fu2l3k4g`. A compilação Adobe ColdFusion aprovou o único template; os hashes publicados foram conferidos, preservando Application.cfc, .htaccess e evento/index.cfm. O teste de regressão instalado aprovou 262 assertivas CFML, 36 URLs e XML com 45.000 entradas.

| Sitemap | URLs | Tempo observado após publicação |
| --- | ---: | ---: |
| Estáticas | 52 | 1,01 s |
| Notícias recentes | 16 | 1,24 s |
| Vídeos | 7 | 1,10 s |
| Eventos futuros/recentes | 8.268 | 1,31 s |
| Histórico 1 | 45.000 | 1,55 s |
| Histórico 2 | 45.000 | 1,00 s |
| Histórico 3 | 1.017 | 0,19 s |
| **Total** | **99.360** | todos abaixo de 15 s |

Os tempos incluem a espera do limitador de uma requisição por segundo; não são somente tempo do servidor. Os dois lotes maiores têm cerca de 5,5 MB descomprimidos cada. Os headers indicaram `CF-Cache-Status: DYNAMIC`; não foi necessário aumentar timeout, reduzir paginação ou alterar cache.

### Reconciliação do cadastro

Uma segunda consulta com **fuso explicitamente definido como America/Sao_Paulo somente na transação de leitura**, às 21:26, correspondeu ao corte dos sitemaps: **30.339 históricos + 2.756 futuros/recentes = 33.095 eventos ativos**. As contagens e hashes das tags coincidiram por divisão e por idioma. Nenhum evento desse conjunto ficou ausente, duplicado ou com a tag modificada no inventário.

A medição anterior em UTC tinha outra divisão (30.400/2.695), mas o mesmo conjunto total. A diferença desapareceu ao alinhar o corte de data; não era perda de eventos. O sitemap usa a categoria futuro/recente a partir de ontem, não apenas provas ainda não realizadas. As 99.285 variantes de eventos, somadas a 75 páginas institucionais/editoriais, explicam o total de 99.360. Isso não mede todos os tipos de página existentes no site nem confirma indexação no Google.

### Nova auditoria

- Rodada `2026-09-14T00-26-50-435Z-23615362`, encerrada às **21:26 de 13/09 em Brasília**.
- Descoberta completa, **100/100 páginas analisadas**, 0 falhas operacionais, 1 erro HTTP, 111 avisos. Exit 2 indica achado de página, não falha de descoberta.
- Erro: HTTP 403 em `/es/evento/2026-operario%0D%0Anight%0D%0Arun/`. O inventário agora revela esse caso; não houve alteração das proteções que rejeitam controles na URL.
- Avisos: 89 H1 múltiplos, 16 divergências de canonical, 3 H1 ausentes e 3 redirecionamentos. Não representam páginas distintas ou score de saúde.
- Relatório íntegro e ponteiro `latest-complete` RoadRunners conferidos. A rodada parcial anterior permanece imutável. Esta é a primeira referência completa RoadRunners; não há comparação longitudinal conclusiva.
- OpenResults não foi novamente coletado nem alterado neste lote; a tela preserva sua auditoria de 15:25.

### Fila

RR-02 passa a concluído pela geração rápida, XML válido e reconciliação completa. RR-01 passa a “descoberta corrigida / rotas pendentes”, cobrindo as tags problemáticas que continuam bloqueadas ou desviam para busca. As outras cinco frentes permanecem pendentes. O Business mostra 7 frentes acompanhadas: 6 pendentes, 1 concluída e 1 pendente de prioridade alta.

### Validação reproduzível

No RoadRunners: `node _codex/scripts/test_sitemap_cfml_local.mjs`. O runner usa CFML existente, dados sintéticos e os helpers reais do sitemap; não consulta banco nem rede.

No Business: `node _codex/scripts/test_seo_queue_cfml_local.mjs`. O cenário de resolução mantém o item nos filtros, remove-o dos totais pendentes e conserva as verificações de acesso e escape de conteúdo.

Consulta de reconciliação: `_codex/sql/2026-09-13_seo_inventory_reconcile_readonly.sql`. A publicação não envolve essa consulta, somente os templates de runtime selecionados.

### Publicação e verificação do Business

Os três templates `seo_queue_data.cfm`, `seo_queue_backend.cfm` e `portal/conteudo/seo.cfm` foram publicados às **21:32:23 de 13/09 (Brasília)**. Backup: `/var/backups/seo-discovery-Business-hobudpeo`. A compilação Adobe aprovou os três arquivos. O teste CFML passou 13 cenários, incluindo 138 verificações de contrato, 10 de resolução, acesso negado e escape de conteúdo.

O navegador autenticado confirmou 99.360 URLs RoadRunners e a data de sua nova auditoria, mantendo OpenResults com a data anterior; sete frentes, seis pendentes e uma concluída; o filtro RoadRunners/P1 conserva RR-01 e RR-02. Desktop de 1530 px e celular de 390 px, inclusive detalhes com URL longa, ficaram sem transbordamento horizontal. A aba de entrega ficou aberta com os sete itens e o viewport normal restaurado.

Acesso anônimo: `/portal/conteudo/?visao=seo` continua em 302 para a raiz; view e includes diretos retornam 403 sem conteúdo da fila. A conferência posterior confirmou hashes e metadados dos quatro arquivos publicados nos dois projetos e oito arquivos protegidos inalterados. Não houve alteração de banco, credenciais, permissões, regras de acesso, OpenResults ou Git.

Recibo agregado: [2026-09-13_seo_descoberta_publicacao.json](2026-09-13_seo_descoberta_publicacao.json). Para reverter, comparar o hash atual ao hash publicado no recibo e restaurar somente o arquivo correspondente de `before/` no backup de cada projeto, com os metadados registrados. Não restaurar diretórios inteiros nem sobrepor alterações posteriores.

O limite de descoberta continua em 100.000 URLs, com margem de 640 nesta rodada. Planejar o orçamento de futuras coletas antes de atingi-lo; uma execução truncada continuará sendo marcada como parcial. Nenhuma agenda automática foi criada.
