# MIF 2026 Protected Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar análise geral e dossiês separados, autenticados, leves e próprios para impressão em PDF.

**Architecture:** ColdFusion aplica a autenticação padrão do Business e incorpora somente o JSON pré-calculado necessário. HTML, CSS e JavaScript compartilhados renderizam uma leitura editorial; dados privados não ficam em arquivos servidos diretamente.

**Tech Stack:** Adobe ColdFusion/CFML, HTML5, CSS, JavaScript sem framework, Node.js `node:test`.

**Spec:** `docs/superpowers/specs/2026-09-01-mif-2026-modular-sales-report-design.md`

## Global Constraints

- Trabalhar diretamente no checkout atual; não criar worktree.
- Não alterar `/inscricoes/`.
- Reutilizar `includes/backend/backend_login.cfm`.
- Redirecionar usuário não autenticado para `/?login=1&redirect=<rota local segura>`.
- Ativos públicos não podem conter dados, conclusões ou recomendações.
- Dados são lidos de `MIF_REPORT_DATA_ROOT`, com padrão `/var/lib/runnerhub/reports/mif-2026`.
- A análise geral não carrega dossiês; um dossiê carrega apenas um canal.
- O modo de impressão esconde navegação e produz PDF geral ou individual.

---

### Task 1: Contrato de autenticação e carregamento privado

**Files:**
- Create: `relatorios/maratona-floripa-2026/includes/auth.cfm`
- Create: `relatorios/maratona-floripa-2026/includes/data.cfm`
- Create: `_codex/tests/mif-report-auth-contract.test.js`

**Interfaces:**
- Produces: `REQUEST.mifReportAuthorized`, `mifReportDataRoot`, `mifReadDataset(relativePath)`.
- Consumes: `qPerfil` do backend de login e nomes de arquivo permitidos pelo manifesto.

- [ ] **Step 1: Write failing source-contract tests**

Assert that auth includes the shared login backend, rejects missing/empty `qPerfil`, validates a local return path, and that data loading rejects `..`, absolute paths and names absent from the manifest.

- [ ] **Step 2: Run test and confirm missing files**

Run: `node --test _codex/tests/mif-report-auth-contract.test.js`

Expected: FAIL because the CFML files do not exist.

- [ ] **Step 3: Implement auth and allowlisted data loading**

`auth.cfm` sets `VARIABLES.template`, includes the backend, redirects when `qPerfil` is absent, then sets `REQUEST.mifReportAuthorized=true`. `data.cfm` requires that flag, resolves the environment variable with the production default, reads `manifest.json`, and exposes only manifest paths matching `^[a-z0-9/_-]+\.json$` without traversal.

- [ ] **Step 4: Run the contract tests**

Run: `node --test _codex/tests/mif-report-auth-contract.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add relatorios/maratona-floripa-2026/includes _codex/tests/mif-report-auth-contract.test.js
git commit -m "feat: protect MIF report data"
```

### Task 2: Shared editorial renderer

**Files:**
- Create: `relatorios/maratona-floripa-2026/assets/report.css`
- Create: `relatorios/maratona-floripa-2026/assets/report.js`
- Create: `_codex/tests/mif-report-renderer.test.js`

**Interfaces:**
- Produces browser functions `MifReport.renderGeneral(root, data)`, `renderChannel(root, data)`, `renderBarChart`, `renderLineChart`, `renderStackedChart`, `renderTable`.
- Consumes: JSON embedded in `<script type="application/json" id="mif-report-data">`.

- [ ] **Step 1: Write failing renderer tests**

Test pure helpers exported under Node: Top 10 + Outros ordering, currency/percentage formatting, ratio-of-totals ticket, HTML escaping, channel ordering and print-section completeness.

- [ ] **Step 2: Run tests and confirm missing renderer failure**

Run: `node --test _codex/tests/mif-report-renderer.test.js`

Expected: FAIL because `report.js` does not exist.

- [ ] **Step 3: Implement the minimal dependency-free renderer**

Use semantic HTML and inline SVG for bar, line and stacked charts. Every chart receives title, description, denominator and source note. Render at most ten categories plus Outros; tables use the complete rows. Export pure helpers through `module.exports` when Node is present and `window.MifReport` in the browser.

- [ ] **Step 4: Implement responsive and print CSS**

Use a readable editorial column, wide evidence sections when needed, internal table overflow on screen, `@media print` page breaks, repeated table headers, hidden navigation/actions and visible source notes. Do not hide overflow in print.

- [ ] **Step 5: Run renderer tests**

Run: `node --test _codex/tests/mif-report-renderer.test.js`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add relatorios/maratona-floripa-2026/assets _codex/tests/mif-report-renderer.test.js
git commit -m "feat: render modular MIF reports"
```

### Task 3: Protected general analysis

**Files:**
- Create: `relatorios/maratona-floripa-2026/index.cfm`
- Create: `_codex/tests/mif-report-general-contract.test.js`

**Interfaces:**
- Consumes: `general.json`, `cycle.json`, `territories.json`, `products.json`, `channels/index.json`.
- Produces: the eight approved editorial chapters and print button.

- [ ] **Step 1: Write failing page contract tests**

Assert the page includes auth/data, embeds only the five general datasets, does not read `channels/<slug>.json`, declares all eight chapter anchors, loads shared assets locally and has a print action.

- [ ] **Step 2: Run the test and confirm missing page failure**

Run: `node --test _codex/tests/mif-report-general-contract.test.js`

Expected: FAIL because `index.cfm` does not exist.

- [ ] **Step 3: Implement the general page**

Embed the reviewed bundles after replacing `</` with `<\/` inside the JSON script. Render title, generated date, navigation, chapter containers, coverage notes and print button. Call `MifReport.renderGeneral` after DOM ready.

- [ ] **Step 4: Run general page and renderer tests**

Run: `node --test _codex/tests/mif-report-general-contract.test.js _codex/tests/mif-report-renderer.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add relatorios/maratona-floripa-2026/index.cfm _codex/tests/mif-report-general-contract.test.js
git commit -m "feat: add protected MIF general report"
```

### Task 4: Channel index and individual dossiers

**Files:**
- Create: `relatorios/maratona-floripa-2026/canais/index.cfm`
- Create: `relatorios/maratona-floripa-2026/canais/dossie.cfm`
- Create: `_codex/tests/mif-report-channel-contract.test.js`

**Interfaces:**
- Index consumes `channels/index.json`.
- Dossier accepts `URL.canal`, resolves it through the manifest and consumes exactly `channels/<slug>.json`.

- [ ] **Step 1: Write failing channel page tests**

Assert commercial ordering, escaped links, slug allowlist, 404 for absent channel, one-dossier loading, seven sections, recommendation category, sample warning, alias/coupon table and print action.

- [ ] **Step 2: Run tests and confirm missing page failure**

Run: `node --test _codex/tests/mif-report-channel-contract.test.js`

Expected: FAIL because channel pages do not exist.

- [ ] **Step 3: Implement channel index**

Render gross-descending rows with registrations, ticket, recommendation and executive highlight. Link to `dossie.cfm?canal=<urlEncodedFormat(slug)>`.

- [ ] **Step 4: Implement dossier page**

Validate `URL.canal` against `^[a-z0-9-]+$`, require an exact manifest path, embed one dataset and call `MifReport.renderChannel`. Return 404 without exposing filesystem paths when absent.

- [ ] **Step 5: Run channel and security tests**

Run: `node --test _codex/tests/mif-report-channel-contract.test.js _codex/tests/mif-report-auth-contract.test.js`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add relatorios/maratona-floripa-2026/canais _codex/tests/mif-report-channel-contract.test.js
git commit -m "feat: add protected MIF channel dossiers"
```

### Task 5: Browser and PDF validation

**Files:**
- Modify: `relatorios/maratona-floripa-2026/assets/report.css`
- Modify: `_codex/tests/mif-report-renderer.test.js`

- [ ] **Step 1: Run all static contracts**

Run: `node --test _codex/tests/mif-report-*.test.js`

Expected: PASS.

- [ ] **Step 2: Validate locally through a temporary authenticated fixture wrapper**

Serve generated fixture pages from a temporary directory, inspect desktop 1280px and mobile 390px, and confirm no root overflow, readable legends, Top 10 + Outros and correct channel ordering.

- [ ] **Step 3: Validate print mode**

Print the general fixture and ROADRUNNERS dossier to PDF. Render pages to PNG and confirm titles, page breaks, repeated headers, source notes and absence of clipped charts.

- [ ] **Step 4: Fix only observed layout defects and rerun tests**

Run: `node --test _codex/tests/mif-report-*.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add relatorios/maratona-floripa-2026/assets _codex/tests/mif-report-renderer.test.js
git commit -m "fix: verify MIF report print layout"
```
