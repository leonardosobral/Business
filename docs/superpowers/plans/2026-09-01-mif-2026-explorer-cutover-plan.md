# MIF 2026 Explorer and Cutover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar o explorador controlado, substituir com segurança o relatório público antigo e validar a versão autenticada em produção.

**Architecture:** O explorador opera somente sobre cubos anônimos pré-calculados e bloqueia combinações de grãos incompatíveis. O deploy envia dados para armazenamento privado, publica código/ativos no webroot e troca a entrada pública por uma página CFML autenticada depois dos testes.

**Tech Stack:** CFML, JavaScript sem framework, Node.js `node:test`, SSH, rsync, curl.

**Spec:** `docs/superpowers/specs/2026-09-01-mif-2026-modular-sales-report-design.md`

## Global Constraints

- Trabalhar diretamente no checkout atual; não criar worktree.
- Não alterar `/inscricoes/`.
- O explorador aceita uma dimensão principal e no máximo uma comparação.
- Métricas incompatíveis são bloqueadas antes da renderização.
- Mais de dez categorias vira Top 10 + Outros; a tabela permanece completa.
- Preservar o HTML monolítico no histórico antes de removê-lo do webroot.
- Fazer backup remoto antes do corte.
- Não publicar dados privados no webroot.

---

### Task 1: Motor controlado do explorador

**Files:**
- Create: `relatorios/maratona-floripa-2026/assets/explorer.js`
- Create: `_codex/tests/mif-report-explorer.test.js`

**Interfaces:**
- Produces: `MifExplorer.validateSelection`, `filterRows`, `aggregateRows`, `buildShareUrl`, `render`.
- Consumes: `explorer.json` com `registration_cube`, `product_cube`, métricas e dimensões permitidas.

- [ ] **Step 1: Write failing explorer tests**

Cover one dimension, two dimensions, rejection of a third dimension, product/order incompatibility, filters, ratio-of-totals ticket, Top 10 + Outros, table completeness and deterministic URL parameters.

- [ ] **Step 2: Run tests and confirm missing module failure**

Run: `node --test _codex/tests/mif-report-explorer.test.js`

Expected: FAIL because `explorer.js` does not exist.

- [ ] **Step 3: Implement validation and aggregation**

Metric contracts explicitly name source cube, numerator, denominator and formatter. `aggregateRows` sums components first and computes rates/tickets last. `validateSelection` rejects fields outside the manifest and combinations using different source cubes.

- [ ] **Step 4: Run explorer tests**

Run: `node --test _codex/tests/mif-report-explorer.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add relatorios/maratona-floripa-2026/assets/explorer.js _codex/tests/mif-report-explorer.test.js
git commit -m "feat: add controlled MIF explorer engine"
```

### Task 2: Protected explorer page

**Files:**
- Create: `relatorios/maratona-floripa-2026/explorador/index.cfm`
- Create: `relatorios/maratona-floripa-2026/assets/explorer.css`
- Create: `_codex/tests/mif-report-explorer-page.test.js`

- [ ] **Step 1: Write failing page contract tests**

Assert authentication, private `explorer.json` loading, metric/dimension controls, reference selector, filter controls, visible grain/coverage, share link and local assets only.

- [ ] **Step 2: Run the test and confirm missing page failure**

Run: `node --test _codex/tests/mif-report-explorer-page.test.js`

Expected: FAIL because the explorer page does not exist.

- [ ] **Step 3: Implement page and accessible controls**

Use labeled native selects and buttons. Restore valid URL parameters, show a clear validation message for rejected combinations, render chart plus full table, and include a link back to the analysis general.

- [ ] **Step 4: Run all report tests**

Run: `node --test _codex/tests/mif-report-*.test.js`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add relatorios/maratona-floripa-2026/explorador relatorios/maratona-floripa-2026/assets/explorer.css _codex/tests/mif-report-explorer-page.test.js
git commit -m "feat: add protected MIF explorer"
```

### Task 3: Final privacy, regression and build verification

**Files:**
- Create: `_codex/tests/mif-report-deployment-contract.test.js`
- Modify: `_codex/analyses/mif_2026_channels/run.py`

- [ ] **Step 1: Write deployment contract tests**

Assert no raw JSON exists beneath `relatorios/maratona-floripa-2026`, every data consumer includes auth, no external script/style URL is present, no `/inscricoes/` file changed in the feature diff, and the modular manifest passes hashes/anonymity.

- [ ] **Step 2: Run test and confirm the expected contract gaps**

Run: `node --test _codex/tests/mif-report-deployment-contract.test.js`

Expected: FAIL until the final entrypoint replaces the public HTML.

- [ ] **Step 3: Remove the public monolith from the deploy tree**

Delete only `relatorios/maratona-floripa-2026/index.html`; the identical committed/internal artifact remains at `_codex/analyses/mif_2026_channels/report_app/dist/shareable.html` and in Git history.

- [ ] **Step 4: Run complete verification**

Run:

```bash
python3 -m unittest discover -s _codex/tests/mif_2026_channels
node --test _codex/tests/mif-report-*.test.js
node --test tests/*.test.js
git diff --check
git diff --name-only HEAD~1 -- inscricoes
```

Expected: all tests PASS, no diff-check output and no `/inscricoes/` path.

- [ ] **Step 5: Commit**

```bash
git add relatorios/maratona-floripa-2026 _codex/tests/mif-report-deployment-contract.test.js _codex/analyses/mif_2026_channels/run.py
git commit -m "feat: finalize protected MIF report"
```

### Task 4: Staged production deployment

**Files:**
- Deploy code: `relatorios/maratona-floripa-2026/**`
- Deploy private data: `_codex/analyses/mif_2026_channels/modular_dist/**`

- [ ] **Step 1: Back up the current remote report**

Create `/var/backups/business-mif-2026-before-modular-<timestamp>.tar.gz` from `/var/www/business.roadrunners.run/relatorios/maratona-floripa-2026`.

- [ ] **Step 2: Upload private data to a staging directory**

Rsync modular data to `/var/lib/runnerhub/reports/.mif-2026-<commit>`; verify manifest hashes remotely, then rename it atomically to `/var/lib/runnerhub/reports/mif-2026` while preserving the previous directory as a rollback copy.

- [ ] **Step 3: Upload code to a staging directory**

Rsync CFML and assets to `/var/www/business.roadrunners.run/relatorios/.maratona-floripa-2026-<commit>`; set owner `root:root`, directories `0755`, files `0644`, then atomically replace the production directory.

- [ ] **Step 4: Compile CFML and validate the origin**

Run `cfcompile.sh` for the report directory. Without authentication, expect a redirect to the Business login and confirm no JSON/private file returns `200`. With an authenticated browser session, expect `200` for general report, channel index, ROADRUNNERS dossier and explorer.

- [ ] **Step 5: Validate print and unaffected registrations page**

Generate the general PDF and ROADRUNNERS PDF from production, inspect representative pages, and verify `https://business.roadrunners.run/inscricoes/` still returns its pre-deploy behavior.

- [ ] **Step 6: Record deployment evidence**

Record commit, remote manifest hash, HTTP results and backup path in the final handoff. Do not delete the rollback copy during the deployment turn.
