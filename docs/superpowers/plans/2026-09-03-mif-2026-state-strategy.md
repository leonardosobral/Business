# MIF 2026 State Strategy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar e publicar uma tela territorial que classifique alcance, detalhe cada UF e compare parceiros, com navegação global completa e destaque da tela atual.

**Architecture:** Um transformador Python puro deriva `states/strategy.json` dos artefatos congelados e registra dependências no manifesto. Uma página CFML autenticada carrega somente esse agregado; JavaScript local renderiza três visões e CSS local mantém impressão e responsividade. A navegação existente usa links absolutos consistentes e estado atual por `aria-current`/classe.

**Tech Stack:** Python 3.12, `unittest`, CFML, JavaScript UMD testado com `node:test`, CSS, manifesto JSON SHA-256.

**Spec:** `docs/superpowers/specs/2026-09-03-mif-2026-state-strategy-design.md`

## Global Constraints

- Trabalhar diretamente em `main`, conforme autorização explícita do usuário; não criar worktree.
- Não tocar em `/inscricoes/`.
- Preservar alterações preexistentes em `ads/` e caches não rastreados.
- Não reprocessar pedidos brutos para esta atualização.
- O detalhe estado × canal exige no mínimo cinco inscrições.
- A classificação territorial exige 30 inscrições e 70% de cobertura válida de UF.
- Apresentar canais em caixa alta e ordenar rankings de forma decrescente.
- Não afirmar incrementalidade, canibalização ou vendas perdidas.

---

### Task 1: Contrato analítico territorial

**Files:**
- Create: `_codex/analyses/mif_2026_channels/state_strategy.py`
- Create: `_codex/tests/mif_2026_channels/test_state_strategy.py`

**Interfaces:**
- Consumes: `overview`, `channel_index`, dossiês, observações territoriais e benchmark geográfico.
- Produces: `build_state_strategy(...) -> dict`, `classify_reach(...) -> str` e `compare_channels(...) -> dict`.

- [ ] **Step 1: Write failing tests for reach thresholds, state reconciliation, suppression and pair overlap**
- [ ] **Step 2: Run the focused Python test and confirm failures are caused by the missing module**
- [ ] **Step 3: Implement deterministic aggregations, transparent classifications and pair evidence**
- [ ] **Step 4: Run the focused Python test until it passes**
- [ ] **Step 5: Reconcile the canonical ROADRUNNERS and MANIADECORRIDA metrics**

### Task 2: Artefato modular incremental e verificação

**Files:**
- Modify: `_codex/analyses/mif_2026_channels/modular_artifact.py`
- Modify: `_codex/analyses/mif_2026_channels/run.py`
- Modify: `_codex/tests/mif_2026_channels/test_modular_artifact.py`
- Modify: `_codex/tests/mif-report-deployment-contract.test.js`
- Create: `_codex/tests/mif_2026_channels/test_state_strategy_incremental.py`

**Interfaces:**
- Consumes: `build_state_strategy(...)` from Task 1.
- Produces: `states/strategy.json`, dependency receipt, full verification and `refresh-state-strategy` CLI.

- [ ] **Step 1: Write failing manifest, verifier and incremental-refresh tests**
- [ ] **Step 2: Run focused tests and confirm missing artifact/command failures**
- [ ] **Step 3: Add transform version, dependency receipt, manifest integration and exact-contract verification**
- [ ] **Step 4: Implement refresh that reads frozen bundles and rewrites only state strategy plus manifest**
- [ ] **Step 5: Run focused and full Python suites**

### Task 3: Tela territorial e interações

**Files:**
- Create: `relatorios/maratona-floripa-2026/estados/index.cfm`
- Create: `relatorios/maratona-floripa-2026/assets/states.js`
- Create: `relatorios/maratona-floripa-2026/assets/states.css`
- Create: `_codex/tests/mif-report-states.test.js`
- Create: `_codex/tests/mif-report-states-page.test.js`

**Interfaces:**
- Consumes: `states/strategy.json` e utilitários de `MifReport`.
- Produces: `MifStates.render`, `MifStates.selectState`, `MifStates.compareSelection` e a rota autenticada.

- [ ] **Step 1: Write failing page and renderer tests for the three views and default overview**
- [ ] **Step 2: Run focused Node tests and confirm missing page/module failures**
- [ ] **Step 3: Implement the CFML shell loading only the territorial bundle**
- [ ] **Step 4: Implement static overview, state detail and up-to-three partner comparison**
- [ ] **Step 5: Add printable responsive styling and accessible controls**
- [ ] **Step 6: Run focused Node tests until they pass**

### Task 4: Navegação global completa

**Files:**
- Modify: `relatorios/maratona-floripa-2026/index.cfm`
- Modify: `relatorios/maratona-floripa-2026/canais/index.cfm`
- Modify: `relatorios/maratona-floripa-2026/canais/dossie.cfm`
- Modify: `relatorios/maratona-floripa-2026/explorador/index.cfm`
- Modify: `relatorios/maratona-floripa-2026/portfolio/index.cfm`
- Modify: `relatorios/maratona-floripa-2026/portfolio/simulador.cfm`
- Modify: `relatorios/maratona-floripa-2026/assets/report.css`
- Create: `_codex/tests/mif-report-navigation.test.js`
- Modify: existing MIF page-contract tests whose prior expectations intentionally conflict with the new global navigation.

**Interfaces:**
- Produces: os mesmos seis destinos globais em cada página, um único `aria-current="page"` e topo responsivo sem itens ocultos.

- [ ] **Step 1: Write a failing cross-page navigation contract test**
- [ ] **Step 2: Run it and confirm failures identify missing links/current state**
- [ ] **Step 3: Replace header actions with a consistent absolute-route navigation set**
- [ ] **Step 4: Add current-state and wrapping/mobile CSS**
- [ ] **Step 5: Update superseded expectations and run all MIF Node tests**

### Task 5: Geração, QA e deploy incremental

**Files:**
- Generate: `_codex/analyses/mif_2026_channels/modular_dist/states/strategy.json`
- Modify: `_codex/analyses/mif_2026_channels/modular_dist/manifest.json`
- Modify: version strings in changed CFML pages.

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces: artefato verificável, UI compilável e publicação de arquivos estritamente relacionados.

- [ ] **Step 1: Run `refresh-state-strategy` against the frozen modular root**
- [ ] **Step 2: Verify hashes, privacy, reconciliation, size and canonical pair evidence**
- [ ] **Step 3: Run all Python and MIF Node tests plus `git diff --check`**
- [ ] **Step 4: Compile the affected CFML directory locally or remotely with the established compiler**
- [ ] **Step 5: Inspect desktop and narrow layouts, including default tab and current navigation**
- [ ] **Step 6: Back up the remote report code and private data**
- [ ] **Step 7: Deploy only changed report files, the new state artifact and the manifest**
- [ ] **Step 8: Verify authenticated production routes and confirm `/inscricoes/` is unchanged**
