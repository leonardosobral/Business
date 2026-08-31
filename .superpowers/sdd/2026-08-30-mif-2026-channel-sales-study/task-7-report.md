# Task 7 — pipeline, CLI, notebook e Data App canônico

## Status

Implementação concluída na branch `main` com fixture sintética de desenvolvimento. O snapshot canônico é `_codex/analyses/mif_2026_channels/report_app/src/data.json`; não existe `artifact.json` nem segundo renderer. O status do snapshot permanece `fixture`, e nenhuma leitura é apresentada como resultado final de 2026.

## Arquivos da Task 7

- Produção: `artifact.py`, `pipeline.py` e `run.py` no pacote MIF.
- Testes/fixtures: `test_artifact_pipeline.py` e extensões reproduzíveis em `fixtures.py`.
- Data App: starter canônico completo em `report_app/`, com autoria restrita a `src/content/report/`, `src/theme.css` e `src/data.json`; recibos `aggregates.json`, `reconciliation.json` e `source_notes.json` ficam na raiz do app.
- Outputs: `report_app/dist/index.html` (preview local) e `report_app/dist/shareable.html` (cópia sanitizada).
- Notebook: `notebooks/mif_2026_channel_study.ipynb`, executado com 13 células, 6 células de código e zero erros.

## Evidência TDD RED/GREEN

1. Snapshot/anonimidade/raw facts: RED por `ModuleNotFoundError` de `artifact.py`; GREEN com 2 testes passando para UUID estável, `surface=report`, `status=fixture`, 31 queries, fontes agregadas e ausência de identifiers/facts.
2. Pipeline/escrita atômica: RED por ausência de `pipeline.py`; GREEN com escrita por arquivo irmão `.tmp` + replace, inode substituído, quatro outputs anônimos e nenhum `artifact.json`/facts.
3. CLI: RED com os 3 testes falhando porque `run.py` não existia; GREEN para `draft-mappings`, `analyze` e `verify`, inclusive verify sem raw exports e rejeição de facts/identificadores injetados.
4. Shareable: RED por ausência de `sanitize_shareable_html`; GREEN removendo meta local, UUID de task e deep link de task, preservando `index.html` e o conteúdo do app.

## Pipeline, snapshot e fontes

- Sequência implementada: load sources → facts → mappings revisados → métricas → small-cell/privacy → narrativa → anonimidade → snapshot/recibos.
- O snapshot usa o UUID estável `4551d11e-c315-4402-be71-218fa11e3148`, 31 IDs da Task 5, componentes/query IDs estáveis e definições de métrica escopadas por componente.
- SQL visível é somente agregado (`COUNT(*) ... GROUP BY cod_evento`); tabelas, evento `72611`, regra de pago, freshness, hashes e contagens de fonte permanecem honestos nos metadados/recibos.
- A leitura cobre visão geral, tempo/lote/modalidade, geografia, perfil/cobertura, produtos, índice, dossiês alfabéticos, long tail, seis overlaps, perguntas, metodologia, limitações, reconciliação e fontes. Não há score mestre, ordenação comercial ou keep/cut.

## Notebook

- O notebook chama `run_analysis` e a fixture de testes; não copia cálculos de produção.
- Checks executados: status/surface/31 queries, qualidade, cobertura de mapeamento, reconciliação aditiva, headlines sentinela e fronteira sem PII/raw facts.
- O runtime Python fornecido não contém `nbformat`, `nbclient` ou Jupyter. Sem instalar dependências, foi usado executor sequencial de stdlib que registrou `execution_count` e outputs; a estrutura nbformat 4.5 e a ausência de outputs de erro foram validadas em seguida.

## Build, sanitização e fronteira protegida

- Build oficial, sem npm install e sem `--source`: prebuilt runtime aprovado, 4 módulos, 0 assets externos; HTML SHA-256 final `14b2bcaa879e242296a9acdbae10269c6087beb8622924c6b6012cd39ad866d1`.
- `dist/index.html` permanece autocontido e conserva somente a meta local esperada para o preview. `dist/shareable.html` remove essa meta, o UUID da task e links direcionados à task.
- Os 140 arquivos listados em `protected-runtime.json` foram recalculados: zero divergências. `src/theme.css` é byte a byte idêntico ao `codex-classic/theme.css` instalado.

## Gates e self-review

- Focados: 8/8; suíte MIF cumulativa: 93/93 (baseline 85); CLI verify final: passou.
- Notebook: reexecução top-to-bottom e validação estrutural passaram; build final passou; scan de shareable, PII, raw facts e metadados de task passou; `git diff --check` passou.
- Self-review confirmou status fixture, 31 queries, quatro outputs apenas, IDs/fonte de cada componente, seis overlaps separados, cobertura geográfica condicional ≥70%, narrativa via `RichNarrative`, ausência de publicação e preservação das mudanças concorrentes.

## Limitações

- A fixture é intencionalmente sintética e pequena; a Task 8 precisa substituir dados, mapeamentos e qualquer leitura quantitativa.
- Não houve broad browser QA, screenshots, DOM inspection ou sweep responsivo, conforme o suplemento. O preview foi aberto uma única vez; build/runtime e fronteira autoral foram validados pelo helper oficial.
- Patrocínio, espaço de expo, permutas e valoração de cortesias continuam não mensurados.

## Fix Round 1 — proveniência, verify, contrato visual e diff gate

### TDD RED/GREEN

- RED real contra `677060c`: `13` testes focados executados, com `6` falhas esperadas — inscrições/alocações sem a tabela de pedidos, adulterações de `weekly_sales`, campo `score` e component ID inexistente aceitos pelo verify, contrato visual ausente e HTML sem normalização de whitespace.
- GREEN: `13/13` focados. As novas regressões comprovam as duas tabelas na linhagem de métricas de inscrição/alocação, definições distintas para pedidos, inscrições, gross e ticket, comparação exata das 31 query rows com `aggregates.datasets`, catálogo de componentes, rejeição de linguagem/campos de decisão e normalização atômica dos dois HTMLs.

### Correções e validação

- `artifact.py` agora cita `public.tb_ticketsports_pedidos` e `public.tb_ticketsports_participantes` em todo agregado derivado de inscrições pagas ou valores alocados; `payment_mix` e `device_mix` permanecem corretamente no grão exclusivo de pedido. O SQL exposto continua agregado e sem identificadores.
- `run.py verify` valida os 31 IDs exatos, igualdade de todas as linhas do snapshot com o recibo agregado, catálogo real de componentes por query, reconciliação de contagem/valor, coberturas, hashes e metadados das duas fontes. Rejeita `score`, `rank` e `keep-cut` em campos ou texto e continua sem argumentos de dados brutos.
- O relatório usa stacked bar para lote, barras horizontais preservadas para país/UF/cidade e produto, além da tabela de produto. Todo gráfico recebe descrição calculada com período, unidade e denominador; `CHART_RATIONALES` reflete os renders reais.
- `sanitize_shareable_html` normaliza whitespace do `index.html` preservando sua meta local e cria `shareable.html` normalizado sem session/task metadata. Ambos terminam em exatamente uma quebra de linha e têm zero linhas com whitespace final. `run.py` não tem linha vazia extra no EOF.

### Gates finais do round

- Suíte MIF cumulativa: `98/98`; CLI canônico: `verification passed`; casos adulterados de `weekly_sales`, `score` e component ID inexistente: rejeitados nas regressões.
- Notebook: reexecução top-to-bottom de `6` células de código, `0` erros, `31` queries, status `fixture`, reconciliação e checks de privacidade completos.
- Build oficial prebuilt: `5` módulos, `0` assets externos, snapshot SHA-256 `25d9833fdaddfb435b8790c2d4bf089df0f709ee53beb13e6b61b9d773ae36fb`. O hash informado pelo builder antes da normalização foi `1bfb4722f8564458bdce0098827291a931c2e999de8598d07e8ee19563c329c0`.
- HTML final normalizado: `dist/index.html` SHA-256 `f66856e2445de6b422ee9aa4ca5768b98a6b02946a60cd94811ed4daa9f360ca`; `dist/shareable.html` SHA-256 `32b8aa80f124653403c7ec78430c5d0655afb88d08bf280b06eaff9b1f40cbfc`.
- Scan do shareable: zero assets externos, metadados/UUID de task, raw facts ou tokens de PII; autocontido. Runtime protegido: `140` arquivos verificados sem divergência; tema `codex-classic` byte a byte idêntico; `git diff --check`: saída vazia.

### Self-review e limites

- O status continua `fixture`; não há afirmação final de 2026, publicação, segunda preview, browser QA amplo ou alteração em `/inscricoes/`.
- A autoria ficou restrita a `src/content/report/` e `src/data.json`; a infraestrutura protegida não mudou. As alterações concorrentes de result-import permaneceram fora do escopo e do staging.

## Fix Round 2 — suficiência semântica e proveniência canônica no verify

### TDD RED/GREEN

- RED real contra `e636669`: `16` testes focados executados, com exatamente `3` falhas. O verify aceitou (1) `weekly_sales=[]` simultaneamente no snapshot e em `aggregates.datasets`, (2) `weekly_sales.source.tables` reduzido a participantes e (3) `channel_mapping_coverage_pct=0`.
- GREEN: `16/16` focados e `101/101` na suíte MIF. As três adulterações agora são rejeitadas pelo CLI com mensagens específicas para dataset, fonte ou cobertura.

### Correção e contratos

- `artifact.py` expõe um único builder determinístico de metadados de fonte. `analyze` e `verify` compartilham esse contrato; por query, o verify compara exatamente tabelas, SQL agregado, filtros/evento, freshness, definições, linhagem e component IDs.
- O verify aplica contratos por dataset: partições globais obrigatórias de inscrições e pedidos reconciliam seus totais e denominadores; aliases reconciliam a base assistida; partições de dossiês reconciliam cada canal completo; cauda longa, catálogo de dossiês, cobertura de perfil e qualidade também são validados. Produtos, overlaps e demais datasets condicionais continuam autorizados a ficar vazios quando sua evidência não existe.
- As coberturas `channel_mapping_coverage_pct`, `product_mapping_coverage_pct` e `registration_join_coverage_pct` devem ser exatamente `100%`; canal e produto também são conferidos no overview. Contagens de fonte não podem ser inferiores às contagens pagas.
- Rejeições anteriores de raw facts, PII, `score`, `rank`, `keep-cut`, divergência snapshot/receipt e component ID inexistente foram preservadas.

### Gates e impacto em artefatos

- CLI canônico: `verification passed`; runtime protegido: `140` arquivos sem divergência; tema `codex-classic` byte a byte idêntico; `git diff --check`: saída vazia.
- Uma regeneração em diretório temporário confirmou igualdade byte a byte dos quatro outputs canônicos (`src/data.json`, `aggregates.json`, `reconciliation.json`, `source_notes.json`). Como snapshot e outputs não mudaram, notebook, build e sanitização não precisaram ser refeitos neste round; permanecem válidos os hashes e gates registrados no Fix Round 1.
- O status permanece `fixture`; nenhuma afirmação final de 2026 foi introduzida. Nenhum arquivo de result-import, `/inscricoes/` ou infraestrutura protegida foi alterado.
