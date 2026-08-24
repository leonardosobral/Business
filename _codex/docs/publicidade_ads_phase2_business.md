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

## Onboarding progressivo de publicidade — 24/08/2026

O fluxo local foi ampliado para que o OWNER de uma conta nova continue
trabalhando enquanto conta e evento são analisados. Preparar não significa
efetivar:

- a conta provisória pode solicitar o evento, reservar voucher e salvar a
  campanha como rascunho;
- a reserva não cria saldo e é aplicada somente quando a conta nova é aprovada;
- a campanha enviada permanece `DRAFT` enquanto aguarda conta, evento ou
  revisão;
- pedidos de acesso a uma conta já existente continuam sem workspace de
  publicidade até aprovação do OWNER da conta ou de um administrador geral;
- somente administrador real da RunnerHub decide a revisão da publicidade;
- o cliente não possui action nem botão para ativar campanha;
- a aprovação RunnerHub usa `ads.review_campaign`, que revalida conta, evento,
  placement, saldo, período e campanha antes de chamar a ativação canônica.

### Matriz operacional

| Conta | Evento | Revisão | Campanha | Resultado |
|---|---|---|---|---|
| Pendente | Pendente | `WAITING_PREREQUISITES` | `DRAFT` | Preparável, fora do ar |
| Ativa | Pendente | `WAITING_PREREQUISITES` | `DRAFT` | Aguarda o evento |
| Pendente | Ativo | `WAITING_PREREQUISITES` | `DRAFT` | Aguarda a conta |
| Ativa | Ativo | `PENDING_REVIEW` | `DRAFT` | Aguarda a RunnerHub |
| Ativa | Ativo | `CHANGES_REQUESTED` | `DRAFT` | Usuário corrige e reenvia |
| Ativa | Ativo | `APPROVED` | `ACTIVE` | Elegível ao delivery conforme saldo e período |

Uma solicitação de acesso a conta existente só entra nos fluxos normais depois
que o vínculo do usuário for aprovado.

### Persistência e transições

A migration local `_codex/sql/2026-08-24_ads_pending_onboarding.sql` cria:

- reservas de voucher com estados `RESERVED`, `APPLIED`, `RELEASED` e
  `EXPIRED`;
- solicitações de revisão com estados `WAITING_PREREQUISITES`,
  `PENDING_REVIEW`, `CHANGES_REQUESTED`, `APPROVED` e `CANCELED`;
- histórico de revisão somente leitura para os papéis da aplicação; o append é
  feito exclusivamente pelas funções controladas;
- funções transacionais para reserva, aplicação/liberação, salvamento pendente,
  envio, reavaliação, cancelamento e decisão administrativa.

A aprovação da conta usa sempre a conta provisória gravada na solicitação. O
voucher não escolhe nem substitui a conta de destino.

### Estado de validação e rollout

Em 24/08/2026, a migration foi aplicada pelo responsável e o fluxo foi publicado
no webroot de produção. A compilação final passou em todos os diretórios
afetados (`ads`: 20, contas: 3, eventos: 18, estrutura: 13 e backend
compartilhado: 22). A validação autenticada com a conta provisória `Projeto
Cauã` confirmou:

- reserva de voucher disponível sem criar saldo;
- evento pendente `LIVE! RUN XP Salvador 2026` disponível no formulário;
- criação restrita a `Salvar rascunho`, sem ativação pelo cliente;
- mensagem explícita de que conta, evento e RunnerHub precisam aprovar antes da
  veiculação;
- ausência de novos erros do módulo nos logs do ColdFusion após as leituras.

O script `assets/js/business-sidenav.js` também foi publicado e a referência foi
versionada para invalidar o 404 que havia ficado em cache. O backup dos 12
arquivos anteriores ao rollout está em
`/var/backups/business-pending-ads-before-deploy-20260824-100909.tar.gz`.

Ordem obrigatória de rollout:

Os passos 1 a 4 foram concluídos. Restam como validação operacional controlada:

1. reservar um voucher real de teste e confirmar sua aplicação somente após a
   aprovação da conta;
2. salvar e enviar uma campanha de teste ligada ao evento pendente;
3. aprovar conta e evento e confirmar a entrada na fila RunnerHub;
4. decidir a campanha como administrador e confirmar que não houve ativação
   antes dessa decisão;
5. repetir o caminho de pedido de acesso a uma conta existente.

## Vouchers globais e restritos — 24/08/2026

O produto passa a distinguir dois tipos de voucher:

- `PROMOTIONAL`: criado globalmente, sem conta; fica vinculado de forma
  atômica à primeira conta que o reservar ou resgatar;
- `ACCOUNT`: criado para uma conta específica e rejeitado em qualquer outra.

Registros existentes com conta são preservados como `ACCOUNT`. Registros
legados sem conta são classificados como `PROMOTIONAL`. A liberação de uma
reserva promocional devolve o voucher ao estado sem conta; aplicação ou resgate
mantém o vínculo definitivo e o ledger canônico continua idempotente.

A administração ganhou a rota global `/ads/?view=vouchers`, separada da fila de
revisão de anúncios. O formulário sugere R$ 100, permite gerar o código
automaticamente e só solicita uma conta quando o tipo escolhido é `ACCOUNT`.

Em 24/08/2026, `_codex/sql/2026-08-24_ads_global_vouchers.sql` foi aplicada e os
arquivos foram publicados. A compilação de produção passou em `ads` (21) e
contas (3). A validação autenticada em `/ads/?view=vouchers` confirmou a API
disponível, o formulário promocional com R$ 100, a navegação separada da revisão
de anúncios e a classificação dos oito vouchers anteriores como `ACCOUNT`.
Nenhum voucher novo foi criado durante a validação. Backup anterior ao rollout:
`/var/backups/business-global-vouchers-before-deploy-20260824-111500.tar.gz`.
