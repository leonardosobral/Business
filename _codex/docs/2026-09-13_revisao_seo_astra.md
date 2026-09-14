# Revisão Astra — auditoria e acompanhamento SEO

Data: 13/09/2026. Revisão técnica e de contexto executada por dois subagentes **gpt-6-astra**, com validação local adicional pelo agente principal. Status: revisão e proposta de implementação; nenhuma correção de runtime ou publicação executada.

## Parecer

O `seo_inventory.mjs` é uma base reaproveitável para inventariar URLs declaradas nos sitemaps. Ainda não deve ser usado como aprovação automática de SEO. A primeira entrega deve corrigir a confiabilidade da coleta e produzir observações, achados e relatórios datados para os dois domínios. Search Console complementa essa coleta; audiência, indexação e saúde técnica são fontes diferentes.

O pedido foi interpretado como revisão do script mencionado e dos documentos que descrevem sua finalidade e operação. A auditoria histórica foi preservada como registro, sem substituir seus números por uma medição atual inexistente.

## Material e baseline de código

- [Script revisado](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs), 150 linhas; SHA-256 `8aae6497f5de87a7c9e621b795dd62540d1788d4f80d4b5ad6d0da6900425403`.
- [Plano AIO/GEO de setembro](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/plano_aio_geo_road_runners_2026.md).
- [Operação da fase 1](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/aio_geo_fase_1_operacao.md).
- [Fontes da auditoria histórica de julho](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/docs/auditoria_seo_2026_fontes.md).
- [Entrega de eventos e sitemap OpenResults](/Users/Shared/Projects/RunnerHub/OpenResults/_codex/docs/eventos-antes-dos-resultados.md).
- [Contexto de audiência do Business](/Users/Shared/Projects/RunnerHub/Business/README.md:20).
- Checkouts observados: Business `1423c5b`; RoadRunners `17cc7ab5`; OpenResults `e769528`. RoadRunners e OpenResults estavam limpos. Business tinha apenas diretórios `__pycache__` preexistentes não rastreados, preservados.

## Achados priorizados

### P1 — O timeout não cobre o corpo da resposta

Em [linhas 33–48](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:33), o timer termina quando `fetch` entrega os cabeçalhos. As chamadas a `response.text()` ocorrem depois, nas linhas 57 e 83. Um corpo lento ou que não termina pode bloquear o worker e impedir o relatório final.

**Evidência:** com `--timeout-ms 1000`, corpos simulados de sitemap e HTML com atraso de 1.250 ms foram aceitos; a execução levou aproximadamente 1.252/1.255 ms, sem abort. Corrigir o deadline para cobrir a leitura/cancelamento do corpo, limitar bytes e testar também stream que nunca termina.

### P1 — Sitemap inválido pode resultar em sucesso com zero URLs

A [extração por regex](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:29) não valida XML nem sua raiz. A [finalização](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:148) aprova a lista vazia.

**Evidência:** HTML HTTP 200 no lugar do sitemap e XML truncado resultaram em zero URLs e exit `0`. XML válido com prefixo `sm:` também resultou em zero URLs, pois o extrator não reconhece a forma qualificada. Usar parser XML com namespace e distinguir documento inválido, sitemap legitimamente vazio, execução truncada e queda de cobertura frente ao histórico.

### P2 — Metadados SEO são coletados, mas não avaliados

A [condição de falha](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:148) considera apenas HTTP, redirecionamento e exceção. Não avalia canonical, `X-Robots-Tag`, meta robots nem content type.

**Evidência:** página HTTP 200 com `noindex` no header e na meta, além de canonical para outra URL, terminou com zero falhas e exit `0`. Isso é uma limitação do contrato atual de inventário, não descumprimento da promessa estreita do manual. Para auditoria, separar observação bruta e achados classificados. HEAD deve informar metadados HTML como **não avaliados**.

### P2 — Regex de HTML perde marcação válida e captura marcação inativa

Na [leitura de canonical e robots](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:84), o parser:

- ignora atributos válidos com espaços ao redor de `=`;
- aceita `rel="notcanonical"` como canonical;
- captura um canonical dentro de comentário antes da tag ativa;
- ignora `meta name="googlebot"` e considera apenas a primeira meta genérica robots.

**Evidência:** os quatro casos foram reproduzidos com HTML simulado. Usar parser de HTML; tratar `rel` como lista de tokens, múltiplas diretivas e escopo por agente. Preservar valor bruto e valor normalizado, resolvendo URLs relativas contra a URL final e respeitando `<base>` válido.

### P2 — O domínio e o orçamento da coleta não estão delimitados

[`--base`](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:12) define o sitemap padrão; não limita hosts descobertos. `--limit` só é aplicado [depois de carregar todos os sitemaps](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/scripts/seo_inventory.mjs:132).

**Evidência:** um sitemap com URL de outro host fez o script solicitar esse host; um índice com dois filhos e `--limit 1` carregou os dois filhos antes de selecionar a primeira página. A amostra também se concentra no início da lista. Não é uma demonstração de exploração remota: a ferramenta atual é uma CLI operada localmente. É um limite operacional relevante para a futura agenda.

Definir hosts permitidos, política para redirects, limites independentes de sitemaps/URLs/bytes/tempo e amostragem explícita. Domínio externo pode ser registrado como evidência sem ser solicitado. Concorrência limita requisições simultâneas, mas não substitui limite de requisições por segundo.

### P2 — Falta rastreabilidade para comparar execuções

O CSV não registra sitemap de origem, duplicatas, `lastmod`, instante da observação, versão, configuração, modo e completude. A saída guarda apenas URL final, sem cadeia ou status inicial dos redirects. O script tampouco solicita `robots.txt`; “robots” hoje significa apenas header/meta capturados.

Uma auditoria de sitemap também não descobre URLs ausentes de todos os sitemaps. Acrescentar uma lista de URLs estratégicas por site; cobertura completa do acervo depende de uma referência mantida pelo dono do domínio, não de consultas de negócio duplicadas no Business.

## Ajustes no diagnóstico anterior

| Assunto | Estado sustentado pela evidência |
| --- | --- |
| Sitemap RoadRunners com 390 URLs/2023 | Diagnóstico histórico. Código atual contém índice dinâmico e segmentos; a publicação completa dessa fase não foi comprovada nesta revisão. |
| Implementação RoadRunners | O plano registra fase 1 implementada em 09/09. Conferir produção antes de refazer trabalho. Há notícias recentes, mas o XML comum não comprova sitemap especializado Google News. |
| Sitemap OpenResults | Registro de publicação de 13/09: 33.096 URLs únicas em quatro lotes. É evidência daquela entrega, não contagem atual obtida nesta revisão. |
| Eventos sem resultados no OpenResults | Página legítima pode retornar 200 antes da prova. Ausência de resultados não significa soft 404. |
| Robots OpenResults | Há grupo Googlebot específico e restrições separadas em `*`; testar política efetiva por agente. O registro anterior também menciona cache CDN antigo ao final da entrega. |
| Search Console | Acesso e propriedades ainda precisam ser confirmados. O registro OpenResults diz que aquela entrega não enviou o sitemap. |
| IA no Search Console | A documentação Google consultada descreve AI Overviews/AI Mode dentro de Performance, tipo Web. Não prometer relatório isolado de IA. |
| Audiência | Business já tem audiência própria RoadRunners. Snippets Google nos dois sites não comprovam propriedades corretas, coleta válida ou acesso aos relatórios. |

## Decisão de arquitetura proposta

Comparadas três alternativas: apenas ajustar o CSV; evoluir a CLI com regras e histórico; construir de imediato um painel com serviço e banco. Recomenda-se **CLI com regras e histórico**, pois corrige os falsos sucessos e permite operar nos dois sites sem criar infraestrutura permanente antes de validar a coleta.

- **RoadRunners:** mantém a entrada existente `seo_inventory.mjs` e a implementação do coletor. Seus templates, sitemaps e robots continuam pertencendo ao próprio projeto.
- **OpenResults:** mantém suas regras públicas; recebe correções somente para achados comprovados.
- **Business:** configura os dois sites, executa a CLI como processo operacional e compara artefatos versionados. Não importa código CFML do vizinho nem consulta regras internas para inferir publicação.
- **Execução inicial:** Node no ambiente operacional já disponível, fora do request ColdFusion. Não supor Node instalado no servidor web. O cron Business atual é HTTP e não executa `.mjs` diretamente.
- **Persistência inicial:** arquivos privados por execução, sem migration, serviço novo ou painel obrigatório. Históricos reais e exports privados ficam fora do docroot e do Git.
- **Fontes posteriores:** Search Console e GA4 entram por exportação validada e depois APIs somente leitura, preservando fonte, período, granularidade e limitações.

O pacote do coletor deve ser instalável isoladamente e identificado por versão/hash. Um caminho operacional configurado para sua CLI é aceitável; o runtime CFML do Business não deve depender de um checkout irmão ou de caminho desta máquina.

## Contrato mínimo para implementação

1. Uma execução tem `schema_version`, `run_id`, `site_id`, datas UTC, versão/hash, configuração, cobertura de descoberta e cobertura de inspeção.
2. Observações guardam fatos coletados; achados guardam regra, gravidade, estado e evidência. Ausente, não avaliado, bloqueado e falha de coleta são estados distintos.
3. JSON é o contrato de comparação; CSV mantém as dez colunas originais na mesma ordem, com extensões aditivas. A CLI antiga mantém suas flags: padrão HEAD, `--deep` coleta HTML por GET. O modo explícito `--audit` implica GET e habilita regras SEO; `--deep` sozinho não habilita auditoria.
4. Exit `0`: execução válida sem falha segundo o modo; `2`: achados/falhas de páginas; `1`: erro operacional/integridade/configuração, com precedência `1 > 2 > 0`. Amostragem intencional concluída é `complete/sample`; interrupção de descoberta ou da amostra por orçamento é parcial.
5. Comparações usam mesmo site, modo, versão das regras e escopo compatível. Uma coleta incompleta nunca resolve automaticamente achados anteriores.
6. HTTP 200 e canonical declarado não comprovam indexação. URL Inspection informa a versão conhecida pelo índice, não um teste live.
7. Primeira operação: piloto limitado nos dois sites, depois rotina semanal e relatório de mudanças. Alertas não devem repetir achados inalterados.

## Verificação executada e limites

Foram executados **12 cenários locais**, com Node v22.21.1 e `fetch` simulado, sem requisições aos sites. [Resultados preservados](/Users/Shared/Projects/RunnerHub/Business/_codex/analyses/seo_review_20260913/evidence.json). Eles comprovam o comportamento da versão revisada; não são testes de produção nem validação de uma correção.

Os harnesses temporários foram mantidos em `/private/tmp/astra-seo-review-tests.mjs` e `/private/tmp/runnerhub-seo-review-20260913/compatibility-probe.mjs`. Não houve auditoria completa dos sites, consulta ao banco, verificação de contas GSC/GA4, validação de WAF ou medição de Core Web Vitals. As oportunidades em robots, sitemaps e dados continuam candidatas para verificação, não ordens automáticas de mudança.

## Referências oficiais consultadas

- [Google: robots meta e X-Robots-Tag](https://developers.google.com/search/docs/crawling-indexing/robots-meta-tag): interpretação e escopo de diretivas; bloqueio de crawl impede leitura da meta.
- [Google: canonical](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls): canonical declarado e sitemap são sinais, não garantia da escolha pelo Google.
- [Google: sitemaps](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap): descoberta e URLs preferidas; envio não garante indexação.
- [Google: robots.txt](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec): grupos por agente e correspondência de regras.
- [Google: Search Analytics API](https://developers.google.com/webmaster-tools/v1/searchanalytics/query): autorização, granularidade, paginação, fuso e limitação de cobertura.
- [Google: URL Inspection](https://developers.google.com/webmaster-tools/v1/urlInspection.index/inspect): informação da versão no índice.
- [Google: experiências de IA](https://developers.google.com/search/docs/appearance/ai-features): fundamentos SEO e medição agregada em Web.

Plano executável: [auditoria e acompanhamento SEO](/Users/Shared/Projects/RunnerHub/Business/docs/superpowers/plans/2026-09-13-seo-auditoria-acompanhamento.md).
