# Publicidade Fase 2 no Business

Data: 2026-08-21  
Status: desenho aprovado; implementação pendente

A especificação canônica da Fase 2 está no RoadRunners:

- [2026-08-21_ads_phase2_business_payments_design.md](../../../RoadRunners/_codex/docs/2026-08-21_ads_phase2_business_payments_design.md)
- [2026-08-21_ads_phase2_business_payments_implementation_plan.md](../../../RoadRunners/_codex/docs/2026-08-21_ads_phase2_business_payments_implementation_plan.md)

O roadmap não deve ser duplicado neste projeto. Este arquivo registra apenas o
impacto local esperado.

## Estado de partida

- `/ads/` ainda apresenta o Turbinados legado como produto principal.
- `/ads/canonical/` contém a administração canônica, mas está rotulada como
  “Ads V1/Piloto” e restrita a administradores internos.
- crédito canônico só pode ser lançado manualmente por administrador interno.
- menu e dashboards ainda apontam para `/ads/` com a linguagem Turbinados.
- a chave Pagar.me legada não pode continuar versionada no código.

## Resultado esperado

- `/ads/` torna-se o único painel **Publicidade**;
- campanhas canônicas ficam disponíveis conforme o papel na conta;
- histórico legado aparece no painel novo, somente leitura;
- `/ads/legacy/` fica oculto por 30 dias como contingência interna;
- `/ads/canonical/` redireciona para `/ads/`;
- `OWNER` e `ADMIN` compram crédito; `OPERADOR` não executa ações financeiras;
- checkout externo Pagar.me oferece PIX e cartão 1x a partir de R$ 50,00;
- webhook e job reconciliam pagamento antes de chamar funções controladas do
  schema `ads`;
- toda consulta e função Ads usa o datasource `runnerhub`/role `runner`;
- segredos ficam em `config/pagarme.local.cfm`, lido por requisição e ignorado
  pelo Git.

## Responsabilidade local

O Business implementa interface, controle de acesso, cliente HTTP Pagar.me,
webhook, tela de status, histórico de pagamentos, job de reconciliação e
observabilidade. Regras de saldo, ledger, estorno e hold permanecem em funções
PostgreSQL versionadas pelo RoadRunners. O Business não recebe DML direto nas
tabelas financeiras.
