# Publicidade Fase 2 no Business

Data: 2026-08-21  
Status: implementação local e banco de produção aprovados; publicação do
Business e homologação Pagar.me pendentes

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

## Estado implementado

- `/ads/` é o painel único Publicidade; `/ads/canonical/` redireciona e o legado
  permanece somente como histórico e contingência read-only.
- OWNER/ADMIN podem comprar saldo; OPERADOR administra campanha sem ação
  financeira; administração financeira manual continua exclusiva do admin
  interno real.
- checkout hospedado Pagar.me aceita PIX e cartão de crédito em 1x, com compra
  mínima de R$ 50,00 e taxas absorvidas pela RunnerHub.
- cliente, serviço, status autenticado, webhook público e reconciliação periódica
  usam DTOs sanitizados e funções controladas do schema `ads`.
- o job `Business - Reconciliacao de pagamentos Ads` foi definido para cinco
  minutos, com uma repetição, mas nasce inativo.
- config-check e dashboard administrativo exibem prontidão, pendências antigas,
  REVIEW, holds e divergências financeiras sem mostrar segredo.

O Codex não executou banco nem publicação. Em 2026-08-23, o operador aplicou a
migration de pagamentos no banco de produção, obteve `PASSED` nos contract tests
rollback-only e `PASS` sem blockers na auditoria compacta. As tabelas de
pagamento permaneciam vazias antes da homologação; o código do Business ainda
aguarda publicação.

## Ordem de aplicação

Executar no PostgreSQL principal, nesta ordem:

1. migration `2026-08-21_ads_phase2_payments.sql`;
2. contract tests `2026-08-21_ads_phase2_payments_contract_tests.sql`;
3. auditoria `2026-08-21_ads_phase2_payments_audit.sql`.

Só continuar se os contract tests terminarem em `PASSED` e a auditoria compacta
retornar `PASS` sem blockers. Depois:

1. instalar `config/pagarme.local.cfm` no RoadRunners e Business com
   `enabled = false`;
2. publicar o Business e validar `/ads/`, status, webhook e reconcile ainda
   desabilitados;
3. cadastrar no Pagar.me o webhook HTTPS do Business e marcar
   `webhookRegistered = true` no arquivo local;
4. rodar manualmente a reconciliação e configurar no job um administrador para
   alerta de erro;
5. ativar o job;
6. habilitar checkout inicialmente em modo test e realizar os testes previstos;
7. somente após reconciliação limpa, mudar coordenadamente para production.

## Operação e alertas

- `paid_without_ledger` e `ledger_without_intent` devem permanecer em zero;
- intenção em `REVIEW` ou hold aberto exige decisão humana;
- pendência com mais de 30 minutos indica webhook/job atrasado;
- HTTP não-2xx do reconcile passa por uma repetição; se ambas falharem, o cron
  grava erro e notifica os administradores escolhidos no painel;
- o webhook não persiste payload bruto e reconsulta o pedido no provedor antes
  de creditar, estornar ou abrir revisão.

## Recuo

O rollback comercial é desligar `enabled` em `config/pagarme.local.cfm`. Isso
bloqueia somente novas compras: status, webhook e reconciliação continuam
processando intenções já criadas. Se houver incidente:

1. desabilitar novas compras;
2. manter webhook e job ativos até zerar intenções não terminais;
3. pausar campanhas afetadas e resolver `REVIEW`/holds pelo admin interno;
4. não apagar ledger, intent, recibo ou histórico legado;
5. reabilitar somente quando as duas divergências financeiras voltarem a zero.

O banco permanece no schema `ads` do PostgreSQL principal. Banco dedicado, AWS,
FDW e fila são opções futuras condicionadas a volume, não gates desta fase.

## Correção financeira de vouchers — 23/08/2026

Foi identificada uma lacuna entre o histórico de vouchers e o saldo canônico:
o sistema anterior marcava o voucher como resgatado, mas o corte canônico não
levava o saldo líquido restante ao ledger. A correção local está pronta:

- `/ads/` oferece resgate de voucher a `OWNER`/`ADMIN`;
- o backend chama `ads.redeem_voucher` pelo datasource `runnerhub`;
- criação, cancelamento e reativação chamam funções controladas, sem DML direto
  de `runner` em `ads.tb_ad_vouchers`;
- voucher e ledger mudam na mesma transação, com retry idempotente;
- o banco bloqueia qualquer novo `status = 2` sem o crédito canônico
  correspondente;
- a aprovação de cadastro reutiliza a mesma função e não faz mais `UPDATE`
  direto para simular resgate;
- readiness exige as nove funções necessárias, incluindo administração e
  resgate de vouchers;
- histórico de campanhas e métricas continua somente leitura.

Arquivos Business alterados:

- `ads/includes/backend.cfm`;
- `ads/includes/payments_home.cfm`;
- `ads/home.cfm` (alerta e status visível quando a campanha ativa não tem
  saldo suficiente para o CPC);
- `administracao/contas/includes/backend.cfm`;
- `_codex/scripts/test_ads_voucher_balance_bridge.sh`.

Antes de publicar esses arquivos, aplicar no RoadRunners a sequência descrita
em
[2026-08-23_ads_legacy_voucher_balance_bridge.md](../../../RoadRunners/_codex/docs/2026-08-23_ads_legacy_voucher_balance_bridge.md)
e exigir `PASS` no audit compacto. Se o voucher de R$ 50.000 já tiver sido
marcado como resgatado depois do corte sem ledger, o audit o listará para a
recuperação administrativa explícita; não criar outro lançamento manual.

O voucher de R$ 50.000 deve ser resgatado somente depois de migration, contract
tests e audit `PASS`. O resultado esperado é um único lançamento
`VOUCHER/CREDIT`, aumento exato de R$ 50.000 no saldo e a campanha voltando a
ser elegível sem alterar seu status manualmente.
