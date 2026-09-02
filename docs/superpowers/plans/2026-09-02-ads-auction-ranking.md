# Ads Auction Ranking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restaurar ranking regional + CPC, cobrança pelo concorrente seguinte e uma única escolha de Página inicial.

**Architecture:** O RoadRunners mantém toda a regra do leilão em funções SQL canônicas e registra o preço imutável na entrega. O Business apenas apresenta superfícies de anúncio e expande a escolha lógica de Página inicial para os dois placements técnicos.

**Tech Stack:** PostgreSQL, Adobe ColdFusion/CFML, JavaScript/Node para testes de interface.

**Spec:** `docs/superpowers/specs/2026-09-02-ads-auction-ranking-design.md`

## Global Constraints

- Não criar branch, worktree ou commit sem solicitação do usuário.
- Preservar campanhas antigas e as assinaturas canônicas já publicadas.
- `cpc_bid` é teto; `price_snapshot` é o valor efetivamente cobrável.
- A UI não calcula ranking nem preço.

---

### Task 1: Contrato de leilão no RoadRunners

**Files:**
- Create: `../RoadRunners/_codex/sql/2026-09-02_ads_event_auction_ranking.sql`
- Create: `../RoadRunners/_codex/sql/2026-09-02_ads_event_auction_ranking_contract_tests.sql`

**Interfaces:**
- Consumes: `ads.campaigns`, `ads.campaign_placements`, `ads.advertisements`, `ads.creatives`, `ads.placements`, saldos e orçamentos canônicos.
- Produces: seletor canônico com ordem por pontuação regional/CPC e preço candidato limitado ao lance.

- [ ] Criar testes transacionais com campanhas nacionais e regionais de lances literais R$ 0,56, R$ 0,94 e R$ 1,32.
- [ ] Executar os testes contra o contrato atual e confirmar falha na ordem e no preço.
- [ ] Implementar pontuação com multiplicadores 2,0, 1,2 e 1,2 e desempate aleatório apenas depois da pontuação.
- [ ] Implementar preço pelo próximo concorrente + R$ 0,01, piso R$ 0,51 e teto no próprio lance.
- [ ] Executar novamente os testes e confirmar os resultados literais de ranking e preço.

### Task 2: Recibo de entrega com preço do leilão

**Files:**
- Modify: `../RoadRunners/_codex/sql/2026-09-02_ads_event_auction_ranking.sql`
- Modify: `../RoadRunners/_codex/sql/2026-09-02_ads_event_auction_ranking_contract_tests.sql`
- Modify: `../RoadRunners/services/AdsV1CpcDeliveryService.cfc`

**Interfaces:**
- Consumes: `price_candidate` retornado pelo seletor.
- Produces: `price_snapshot` validado e imutável usado por `ads.charge_cpc_click`.

- [ ] Adicionar teste que prova que uma entrega de lance R$ 1,32 pode registrar preço menor, sem ultrapassar o teto.
- [ ] Confirmar que o teste falha porque `serve_delivery` grava hoje o lance máximo.
- [ ] Criar snapshot transacional opt-in que recalcula o vencedor e valida `0 < preço <= cpc_bid` sem mudar a assinatura pública.
- [ ] Atualizar o serviço CPC para passar o mesmo contexto ao snapshot e rejeitar divergência entre candidato e recibo.
- [ ] Executar os testes de entrega, clique, saldo, orçamento e idempotência.

### Task 3: Superfície única de Página inicial no Business

**Files:**
- Modify: `ads/home.cfm`
- Modify: `ads/includes/backend.cfm`
- Modify: `ads/includes/workspace_campaign_form.cfm`
- Modify: `_codex/tests/ads-campaign-wizard.test.js`
- Modify: `_codex/scripts/test_ads_v1_multi_placement_business.sh`

**Interfaces:**
- Consumes: quatro escolhas lógicas do formulário.
- Produces: cinco placement keys técnicos, expandindo Página inicial para os dois spots.

- [ ] Adicionar teste de formulário que espera apenas quatro superfícies e uma única opção Página inicial.
- [ ] Adicionar teste de persistência que espera a expansão da home para os dois placement keys.
- [ ] Executar os testes e confirmar que falham com a UI atual de cinco opções.
- [ ] Agrupar a home na consulta e no formulário; normalizar campanhas antigas na edição.
- [ ] Atualizar resumo e contagem para não duplicar Página inicial.
- [ ] Atualizar a explicação: o anunciante escolhe onde concorrer; região e lance definem posição e frequência.
- [ ] Executar testes Node e shell da área de publicidade.

### Task 4: Validação integrada e entrega

**Files:**
- Modify: documentação operacional somente se a verificação encontrar diferença do contrato.

**Interfaces:**
- Consumes: migration, serviço e formulário concluídos.
- Produces: ordem segura de aplicação e evidências verificáveis.

- [ ] Executar `git diff --check` nos dois repositórios.
- [ ] Executar todos os testes focados de publicidade disponíveis localmente.
- [ ] Validar desktop e mobile do passo 4 no navegador autenticado.
- [ ] Informar a migration a aplicar antes do deploy dos arquivos RoadRunners e Business.

### Task 5: Encerrar a trava do piloto

**Files:**
- Modify: `../RoadRunners/services/AdsV1CpcDeliveryService.cfc`
- Modify: `../RoadRunners/includes/eventos_ads.cfm`
- Modify: `../RoadRunners/_codex/scripts/test_ads_v1_native_service_contract.sh`

- [x] Remover a dependência runtime da allowlist manual `cpcCampaignIds`.
- [x] Manter `cpcPlacements` como kill switch operacional por superfície.
- [x] Confirmar que campanha ativa e aprovada é entregue pelo seletor canônico.
