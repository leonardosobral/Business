# Jornada LIVE!: vínculo atual e etapas de cupom

## Correção

A classificação de provas em `portal/audiencia/queries/live_journey.sql` usava
`tb_evento_corridas.id_agrega_evento`, vínculo legado que não representa todas as
provas exibidas na página atual do circuito. Visitas sem saída registrada podiam
ficar ausentes da etapa “prova LIVE!”.

O catálogo agora consulta `tb_agregadores_eventos` e `tb_agregadores`, restringindo
o tipo a `circuito`. A identificação segue o caminho canônico já usado no produtor
RoadRunners: `coalesce(nullif(tb_agrega_eventos.tag,''), agregador_tag) =
'live-run-xp'`. `EXISTS` mantém uma linha por prova mesmo quando há múltiplos
vínculos. O campo legado da prova deixa de determinar a participação no circuito.

Filtros, denominadores, limites, colunas anteriores e o contrato de saída
`outbound_click:live_registration:<id>` permanecem iguais. Saídas válidas continuam
visíveis quando a prova não existe no catálogo.

## Etapas adicionais

O relatório adiciona contagens de sessões por campanha/prova com cupom visível,
tentativa de cópia, cópia confirmada, erro de cópia e saída ao site oficial.
Seleção de cidade aparece somente por campanha. Cada etapa deduplica as sessões;
não exige que outra etapa tenha sido observada e não comprova ordem temporal.
Interações sem abertura permanecem observáveis sem fabricar visitas. As taxas
anteriores de visita e saída para inscrição não incluem saída ao site oficial.

Contrato aditivo do produtor RoadRunners:

| Etapa | `event_kind` e `event_key` |
| --- | --- |
| Cupom visível | `content_open`, `content_open:live_coupon_viewable:<id>` |
| Tentativa de cópia | `content_open`, `content_open:live_coupon_copy_attempt:<id>` |
| Cópia confirmada | `content_open`, `content_open:live_coupon_copy_success:<id>` |
| Erro de cópia | `content_open`, `content_open:live_coupon_copy_error:<id>` |
| Site oficial | `outbound_click`, `outbound_click:live_information:<id>` |
| Escolha de cidade | `content_open`, `content_open:live_city_select:<circuit_id>:<cidade-uf ou all>` |

As cinco primeiras etapas exigem `content_type='event'` e ID positivo coincidente
com a chave. A seleção de cidade exige `content_type='circuit'` e ID coincidente.
O produtor valida a visibilidade de pelo menos 50% por 1 segundo; o consumidor
usa o evento aceito. Cópia confirmada significa sucesso informado pelo navegador,
sem afirmar uso do cupom, inscrição ou compra.

Como essas interações reutilizam `content_open`, `queries/content.sql` exclui o
namespace reservado `content_open:live_` das métricas editoriais, sem restringir
as chaves históricas de abertura. O painel explica que zero significa nenhum
evento recebido, sem comprovar cobertura ou criar histórico anterior à coleta.
A view preserva renderização com o resultado SQL antigo durante transição.

## Verificação

O runner `_codex/scripts/test_audience_live_report_local.mjs` executa a consulta
real em PostgreSQL 16 temporário, com dados sintéticos e sem acesso à produção.
Os novos cenários reproduziram a falha antes da correção e passaram depois:

- vínculo atual sem campo legado e sem saída que pudesse mascarar o erro;
- aliases resolvidos pelo caminho canônico, sem duplicar a prova;
- campo legado obsoleto sem prevalecer sobre o vínculo atual;
- agregador sem registro legado, identificado pela própria tag;
- agregador de outro tipo excluído da classificação de circuito.

Resultado: **40 asserções SQL aprovadas**, incluindo deduplicação entre provas,
interações sem visita, chave divergente, internos, seleção isolada de cidade e
preservação do denominador ao filtrar o detalhe. Os testes Node de gráficos, navegação
regional/LIVE e compatibilidade SQL Adobe passaram: **9 testes**.
O runner geral `test_audience_report_local.mjs` também passou: **56 asserções
SQL**, cobrindo as demais consultas e a separação entre interações e aberturas
editoriais. As regressões novas falharam antes das correções.

`test_audience_live_cfml_local.mjs`: **23 asserções renderizadas** no Lucee local,
incluindo compatibilidade com o contrato SQL anterior durante publicação.
O home temporário padrão não existia; foi usada uma cópia exclusiva do runtime
disponível em `/private/tmp/runnerhub-business-live-commandbox`, regenerando o
cache Felix somente nessa cópia. O runner browser passou em **1440px e 390px**,
sem JavaScript, preservando filtros e rolagem local das tabelas sem overflow da
página. Capturas inspecionadas visualmente.

A consulta candidata foi executada via Adobe/datasource `runnerhub`, em transação
`READ ONLY`, para 13–19/10/2026 BRT, produção, sem internos, Google e campanha
`live_cupom_2026_retomada`: **585 sessões, 65 sessões com prova, 18 saídas e
18 visita + saída**. As etapas novas retornaram zero, sem histórico retroativo.
Execução: **8.487 ms**. Evidência agregada:
`_codex/staging/live-funnel-20261020/business-candidate-read.json`.

## Publicação coordenada

Arquivos de runtime:
`portal/audiencia/queries/live_journey.sql`,
`portal/audiencia/queries/content.sql` e
`portal/audiencia/live_journey.cfm`. Testes e documentação são locais.

Antes da publicação, conferir o baseline, criar backup recuperável e confirmar
SELECT do datasource `runnerhub` nas duas novas dependências desta consulta
(já comprovado na leitura da candidata):
`public.tb_agregadores_eventos` e `public.tb_agregadores`. Não é necessária
migration nem alteração automática de permissões.

Publicar os SQLs antes da view; conferir o painel autenticado após publicação.
A prova de publicação depende dessa verificação. Rollback restaura a view antes
dos SQLs anteriores. A coleta nova pode começar depois do consumidor sem migration;
publicar `content.sql` antes do produtor evita inflar aberturas editoriais.
Este documento registra a implementação e a leitura da candidata, sem afirmar
publicação.
