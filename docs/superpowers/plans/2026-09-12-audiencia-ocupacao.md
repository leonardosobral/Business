# Resumo de ocupação — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Responder no topo quanto espaço teve visibilidade, quanto foi preenchido e quanto ficou vazio, separando Ads e banners e agrupando visitantes e sessões.

**Architecture:** Consulta opcional e somente leitura de `audience.events`, isolada dos relatórios existentes. Uma observação física é página + posição; a primeira oportunidade fixa metadados por UF, e o total deduplica a posição após os filtros. Um include CFML apresenta contagens, percentuais e barras HTML, sem biblioteca nova.

**Tech Stack:** PostgreSQL, CFML, CSS existente, Node para testes, PostgreSQL/Lucee locais isolados.

**Spec:** Decisão aprovada na conversa: potencial observado = posições com visibilidade comprovada; preenchidas = anúncio comercial ou institucional; vazias = sem anúncio; crédito/pago fora desta etapa; visitantes e sessões juntos; registros sem visibilidade em segundo plano.

## Global Constraints

- Apenas Business; RoadRunners consultado como fonte, sem alteração do produtor.
- A etapa original era somente local. A publicação foi posteriormente autorizada por “no final sempre publique” e concluída no checkpoint abaixo. Não criar branch/commit, modificar permissões/DSN nem instalar SQL.
- Preservar os arquivos já modificados antes desta etapa, inclusive correção Adobe em capacity.sql.
- Reutilizar filtros período (Brasília), ambiente, internos, dimensão regional, UF, família e dispositivo.
- Desconhecido não vira vazio. Erro de consulta não vira zero.
- Não usar ad_views / opportunities. Trocas de entrega não aumentam o denominador físico.
- Filled/house em slot_viewable comprovam preenchimento registrado; ad_viewable com IDs pode complementar essa evidência quando a mesma observação possui slot_viewable. Não reconstruir transições que o produtor não reteve.
- Empty somente quando há sinal visível empty e nenhum sinal visível incompatível ou preenchimento confirmado. Disabled e estados não classificáveis ficam em sem classificação.
- Classificação Ads/banner por chaves e placements explícitos existentes, não substring genérica. Chaves não reconhecidas ficam em outros formatos, visíveis quando presentes.

### Task 1: Consulta e contrato de ocupação

**Files:** Create `portal/audiencia/queries/occupancy.sql`; create `_codex/scripts/test_audience_occupancy_report_local.mjs`.

**Interfaces:** Retorna quatro linhas com `format` = `all`, `ads`, `banners`, `other`; colunas inteiras `registered`, `potential`, `filled`, `empty`, `unclassified`. `potential = filled + empty + unclassified`. `all` deduplicado fisicamente, cada posição em uma categoria de formato.

- [x] Criar teste PostgreSQL isolado com fixtures literais: vazio, três filled (house incluído), dois empty, um disabled; ad-only sem slot_viewable não cria potencial; rotação e várias UFs não duplicam total; não somar linhas limitadas; filtros e fronteiras temporais.
- [x] Executar teste e registrar falha pela consulta ausente/contrato ausente.
- [x] Implementar agregação: `slot_events -> opportunity_identity + signals -> regional_slots -> physical_slots -> format_totals`.
- [x] Executar o teste real como papel SELECT-only e comparar o total do recorte comercial ao capacity.sql nas fixtures compartilhadas. Verificar `node --test _codex/tests/audience-sql-adobe.test.cjs`.

### Task 2: Integração e topo legível

**Files:** Create `portal/audiencia/occupancy.cfm`; modify `portal/includes/audience_backend.cfm`, `portal/audiencia/home.cfm`, `assets/css/audience-dashboard.css`; create `_codex/tests/audience-occupancy/fixture.cfm`, `_codex/scripts/test_audience_occupancy_cfml_local.mjs` and backend fixture/check.

**Interfaces:** Backend expõe `audienceOccupancyStatus` (`ready`/`unavailable`) e `audienceOccupancyQuery`. Include usa esses campos e `audStats` com visitantes, sessões, páginas e sinais técnicos. Não altera os sete relatórios existentes.

- [x] Testar renderização do include inexistente/contrato ausente com números sintéticos: 100 de potencial = 60 preenchidos, 30 vazios, 10 sem classificação; percentuais usam 100 em cards e barras; zero não gera NaN nem 100% vazio; erro não gera número substituto.
- [x] Implementar três indicadores de ocupação + bloco Audiência com visitantes/sessões juntos. Barras separadas Ads e banners, texto acessível com contagens e percentuais; outras posições e incerteza condicionais. Detalhes recolhidos para sinais antigos, sem apagá-los.
- [x] Acrescentar leitura opcional com `datasource="runnerhub"`, timeout 15s, cache 1min e erro genérico seguro. A falha de ocupação preserva os demais relatórios.
- [x] Substituir apenas a antiga faixa de seis KPIs em home.cfm; preservar filtros, tabs e capacidade. Explicar no detalhe o grão e a diferença entre sinais técnicos e espaços físicos.
- [x] Validar CFML real local, integração do backend com DB simulado só na fronteira, regressões Node/SQL, desktop/mobile e sem JavaScript.

### Task 3: Revisão e entrega local

- [x] Revisão independente de semântica, compatibilidade Adobe e UI; corrigir achados materiais.
- [x] Conferir diff e documentação com resultados executados, sem alegar leitura de produção.
- [x] Deixar preview local da tela e lista de arquivos para publicação posterior; nenhum deploy nesta etapa.

## Execution notes

- Trabalho em continuação no checkout compartilhado; instrução AGENTS proíbe branch/commit sem solicitação. Nenhuma operação Git mutante.
- SQL e apresentação têm interface fixa acima e serão desenvolvidos em paralelo, com revisão conjunta ao final. Testes locais não acessam DSN/prod.

## Publicação autorizada posteriormente

- [x] Publicar somente os cinco arquivos de runtime, com baseline/backup e proteção das demais frentes.
- [x] Conferir resumo real no Business autenticado, composição dos totais, CSS servido, proteção HTTP do SQL e serviços ativos.
- [x] Registrar recibo em `_codex/docs/2026-09-12_audience_occupancy_publicado.md`. Concluído em 12/09/2026 às 22:36:23 BRT; sem migração ou alteração de cobrança.
