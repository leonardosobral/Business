# Home canônica e aumento de orçamento — 24/10/2026

## Diagnóstico
A home consultava `ads.tb_ad_vouchers` e `ads.tb_ad_eventos` legados. Para STC mostrava saldo de R$ 72.000 e uma campanha Floripa 2026 com total R$ 20.000 e teto diário R$ 100. O Ads atual tem saldo R$ 50.652,75 e Floripa 2027 com total R$ 100, gasto R$ 99,70, lance R$ 0,94 e sem teto diário. O restante de R$ 0,30 não cobre o lance. A campanha está ACTIVE e APPROVED, porém inelegível por orçamento.

## Mudanças
- Home lê saldo, campanhas e limites canônicos no escopo da conta. Status traduzido, aviso de orçamento esgotado, datas com ano, botão Gerenciar por linha e link direto com ações expandidas.
- Aumento do orçamento total de campanha EVENT/CPC aprovada (ACTIVE ou PAUSED) sem alterar status, aprovação, lance, datas ou segmentação. PAUSED permanece PAUSED. Não credita carteira.
- Rota POST, CSRF e autorização de gestão/delegação existentes. Validação monetária e proteção contra orçamento desatualizado. API bloqueia linha e grava auditoria old/new atomicamente.
- Trigger mantém aprovação apenas quando o total aumenta e todos os outros dados materiais permanecem idênticos. Outras edições continuam exigindo nova revisão.

## Migração aplicada e conferida
`_codex/sql/2026-10-24_ads_increase_campaign_budget.sql`: somente schema ads. Guarda o hash do trigger existente e rejeita drift/reaplicação. Cria API e histórico; não altera valores de campanhas ou saldos. Runtime é compatível antes da migração e esconde a nova ação até a função estar disponível com EXECUTE.
O usuário aplicou a migração pelo cliente SQL. Conferência posterior confirmou registro, tabela de auditoria, funções equivalentes ao SQL testado (apenas indentação diferente), owner ads_owner, SECURITY DEFINER, search_path pg_catalog e EXECUTE para ads_business. Readiness do ColdFusion retornou 1. O navegador autenticado STC exibiu Novo orçamento total e Aumentar orçamento. Aumento real de orçamento não foi executado.

## Evidências
- `_codex/scripts/test_ads_budget_increase.mjs`: PostgreSQL 16 descartável com migrations canônicas, fixture sintética. Passou: aprovação/status/saldo preservados; auditoria; aumentos em ativa e pausada; recusa de redução/igual/NaN/Infinity/overflow/decimais extras; concorrência por expected budget; usuários sem gestão/conta alheia/delegação; alterações materiais; rollback de falha de auditoria; encerradas; drift.
- CF2025: seis templates compilados; testes de rota POST/GET/ação ambígua, link somente leitura e números com vírgula/ponto passaram.
- Consultas canônicas testadas somente leitura no servidor. Navegador autenticado STC confirmou saldo, campanhas e link Gerenciar correto. Não foram submetidos formulários de orçamento ou status. Teste visual mobile não concluído nesta rodada.
- Artefatos em `_codex/staging/ads-budget-increase-20261024/`, incluindo hashes e comprovantes de publicação. Baseline de seis arquivos comparado com fontes conhecidas; seis dependências preservadas.
- Backup original: `/var/backups/ads-budget-increase-20261024-u2edme08/baseline`. Ajuste final de texto/datas: `/var/backups/ads-budget-increase-20261024-dkcenzqk/baseline`. Reverter ambos em ordem inversa se necessário, conferindo hashes.
- Sem commit/push ou alterações em campanhas, carteira e conta selecionada.

## Conferência após migração
O formulário de aumento apareceu em Gerenciar no STC. Corrigida também a largura do painel: o contêiner de ações herdava white-space nowrap e o novo texto estendia o painel sobre a tabela. O painel agora tem largura limitada e texto com quebra. Publicação adicional somente ads/home.cfm; backup `/var/backups/ads-budget-width-20261024-zh64c6jk/baseline`.
