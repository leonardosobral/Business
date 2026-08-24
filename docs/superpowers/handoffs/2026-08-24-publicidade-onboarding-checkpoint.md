# Checkpoint — onboarding de publicidade com conta/evento pendentes

Data: 24/08/2026

> Atualização após a retomada: as etapas 4, 5, 6 e 7 descritas abaixo foram
> concluídas localmente. A suíte estática integrada e os testes Node passaram.
> Resta a etapa 8: validar/aplicar a migration, publicar/compilar ColdFusion e
> executar a jornada real controlada. O estado operacional atualizado está em
> `_codex/docs/publicidade_ads_phase2_business.md`.

## Objetivo aprovado

Permitir que o novo cliente continue trabalhando enquanto a conta e o evento estão em análise:

- entrar no Business imediatamente após o cadastro;
- solicitar o vínculo do evento;
- reservar o voucher sem consumir/aplicar o crédito ainda;
- preparar a campanha como rascunho para evento próprio ainda pendente;
- enviar a campanha para a esteira de análise;
- efetivar voucher, elegibilidade e veiculação somente após as aprovações necessárias;
- manter a aprovação final do anúncio exclusivamente com a RunnerHub, como ocorre em Google/Meta.

Para pedido de acesso a uma conta já existente, o usuário continua bloqueado até aprovação do OWNER dessa conta ou de um administrador geral da RunnerHub.

## Decisões de produto confirmadas

1. O voucher fica dentro do Business, depois da criação da conta.
2. Conta nova pendente recebe um workspace limitado, mas funcional.
3. Evento próprio pendente pode ser usado para montar a campanha.
4. Reserva de voucher não altera saldo.
5. Aprovação da conta aplica a reserva do voucher.
6. Aprovação do evento libera a campanha para análise da RunnerHub.
7. Cliente nunca ativa anúncio diretamente.
8. A campanha só entra no ar após aprovação explícita da RunnerHub.

## Implementação concluída

### 1. Persistência e máquina de estados

Criados:

- `_codex/sql/2026-08-24_ads_pending_onboarding.sql`
- `_codex/scripts/test_ads_pending_onboarding_schema.sh`

A migração define:

- `ads.voucher_reservations`;
- `ads.campaign_review_requests`;
- `ads.campaign_review_history`;
- proteção para impedir resgate indevido de voucher reservado;
- `ads.reserve_voucher(...)`;
- `ads.apply_voucher_reservation(...)`;
- `ads.release_voucher_reservation(...)`;
- `ads.save_pending_event_campaign(...)`;
- `ads.submit_campaign_review(...)`;
- `ads.refresh_campaign_review_prerequisites(...)`;
- `ads.cancel_open_campaign_reviews(...)`;
- `ads.review_campaign(...)`.

Status: código criado e testes estáticos aprovados. A migração ainda não foi aplicada no banco de produção.

### 2. Autorização da conta pendente

Alterados:

- `includes/backend/backend_login.cfm`
- `ads/includes/access.cfm`
- `ads/includes/backend.cfm`
- `_codex/scripts/test_ads_pending_onboarding_access.sh`

Implementado:

- conta nova pendente pode acessar `/`, `/eventos/`, `/ads/`, `/faq/` e `/suporte/`;
- solicitação para conta já existente continua limitada a `/`, `/faq/` e `/suporte/`;
- contexto pendente só é válido para o próprio solicitante, com papel OWNER e solicitação que não seja de acesso a conta existente;
- backend revalida esse contexto antes de qualquer mutação;
- conta pendente pode reservar voucher e preparar campanha;
- conta pendente não pode comprar crédito nem administrar finanças;
- revisão de anúncios permanece restrita a administrador real da RunnerHub.

Testes aprovados:

- `test_ads_pending_onboarding_access.sh`
- `test_business_login_routing.sh`
- `test_business_pending_workspace.sh`
- `test_ads_phase2_business_access.sh` (antes das mudanças ainda incompletas da etapa de campanhas)

### 3. Reserva do voucher

Alterados:

- `ads/includes/backend.cfm`
- `ads/includes/payments_home.cfm`
- `_codex/scripts/test_ads_voucher_balance_bridge.sh`

Implementado:

- ações separadas `reserve_voucher` e `redeem_voucher`;
- conta pendente chama `ads.reserve_voucher(...)` e não recebe saldo imediatamente;
- painel pendente mostra “Reservar voucher”, valor, validade e código mascarado;
- compra de crédito adicional continua indisponível enquanto a conta está pendente;
- textos explicam que o crédito será aplicado após a aprovação da conta.

Testes aprovados:

- `test_ads_pending_onboarding_access.sh`
- `test_ads_voucher_balance_bridge.sh`
- `test_ads_phase2_payment_panel.sh`

## Implementação iniciada, ainda não finalizada

### 4. Campanha para evento pendente e envio para análise

Criado:

- `_codex/scripts/test_ads_pending_onboarding_campaigns.sh`

Alterado parcialmente:

- `ads/includes/backend.cfm`

Já feito no backend:

- ações do cliente agora são `save_campaign`, `submit_campaign_review` e `change_campaign_status`;
- removido o `case` de `activate_campaign`;
- seleção de eventos considera `ATIVO` e `PENDENTE`;
- evento pendente precisa pertencer ao usuário solicitante;
- conta pendente salva por `ads.save_pending_event_campaign(...)`;
- conta ativa continua usando `ads.save_event_campaign(...)`;
- adicionado envio por `ads.submit_campaign_review(...)`;
- consultas de campanhas carregam `review_status`, `review_reason`, datas da revisão, status da conta e status do vínculo do evento.

Ainda falta nesta etapa:

1. Ajustar `ads/includes/workspace_campaigns.cfm`:
   - remover o botão/formulário “Ativar” do cliente;
   - adicionar “Enviar para análise”;
   - exibir “Aguardando pré-requisitos”, “Em análise pela RunnerHub” e “Ajustes solicitados”;
   - mostrar `review_reason` quando houver pedido de ajustes.
2. Ajustar `ads/includes/workspace_campaign_form.cfm`:
   - trocar “Salvar campanha” por “Salvar rascunho”;
   - informar que eventos ativos ou pendentes autorizados podem ser usados.
3. Corrigir dois padrões do teste novo:
   - regex do status `ATIVO/PENDENTE`;
   - regex multilinha de `adsAccessCanReviewCampaign`.
4. Atualizar testes antigos que ainda esperam `activate_campaign`:
   - `_codex/scripts/test_ads_phase2_business_access.sh`;
   - `_codex/scripts/test_ads_phase2_business_routes.sh`.
5. Executar:
   - `bash _codex/scripts/test_ads_pending_onboarding_campaigns.sh`
   - `bash _codex/scripts/test_ads_phase2_business_routes.sh`
   - `bash _codex/scripts/test_ads_phase2_business_access.sh`
   - `bash _codex/scripts/test_ads_advertiser_workspace_ui.sh`

## Próximas etapas ainda não iniciadas

### 5. Transições nas aprovações

- aprovação da conta nova aplica o voucher reservado;
- aprovação da conta reavalia campanhas aguardando pré-requisitos;
- recusa da conta libera a reserva e cancela análises abertas;
- aprovação do evento reavalia a campanha e a move para análise da RunnerHub;
- recusa do evento move a campanha para ajustes, com motivo;
- pedido de acesso a conta existente não deve aplicar essas regras de conta nova.

Arquivos esperados:

- `administracao/contas/includes/backend.cfm`;
- backend de aprovação/vínculo de eventos;
- novo teste `_codex/scripts/test_ads_pending_onboarding_approvals.sh`.

Observação importante: a aprovação de conta atualmente precisa ser revista para não escolher a conta-alvo a partir do voucher. Para conta nova provisória, a conta-alvo deve ser a própria `id_conta` da solicitação; o voucher apenas será aplicado nela.

### 6. Fila administrativa de revisão de anúncios

- criar fila agrupada de campanhas para administrador RunnerHub;
- permitir aprovar, pedir ajustes e cancelar;
- exigir motivo para ajustes/recusa;
- nenhum endpoint de aprovação pode ficar disponível ao cliente;
- revisar acesso ao painel global quando o admin não tiver uma conta Business selecionada.

Arquivo principal esperado:

- `ads/includes/workspace_admin.cfm`.

### 7. Home e navegação do onboarding

- liberar visualmente voucher e publicidade como etapas preparáveis;
- retirar aparência de bloqueio absoluto;
- explicar em cada etapa o que está preparado e o que aguarda aprovação;
- revisar cards da home pendente e menu lateral.

Arquivos esperados:

- `home_pending_account.cfm`;
- componentes do menu lateral da home/Business.

### 8. Validação final e implantação

- executar toda a suíte relacionada;
- validar sintaxe/compilação ColdFusion;
- validar a migração em banco antes de produção;
- testar ponta a ponta com conta nova, conta existente, evento pendente, voucher e revisão do anúncio;
- somente depois aplicar migração e publicar, mediante decisão explícita.

## Ponto exato para retomada

Retomar pela interface da etapa 4:

1. editar `ads/includes/workspace_campaigns.cfm`;
2. editar `ads/includes/workspace_campaign_form.cfm`;
3. atualizar os três testes de campanhas/rotas/acesso;
4. rodar os quatro comandos de teste listados acima;
5. só então seguir para as transições de aprovação da etapa 5.

Não há necessidade de criar worktree, branch ou commit intermediário. As mudanças estão no workspace principal.

## Atualização de produção — 24/08/2026 10:30 BRT

Este checkpoint histórico foi superado pelas etapas seguintes: implementação,
testes, migration e publicação foram concluídos.

- migration aplicada pelo responsável;
- 13 arquivos do fluxo publicados, incluindo o JavaScript do menu;
- compilação de produção aprovada em `ads` (20), contas (3), eventos (18),
  backend compartilhado (22) e estrutura (13);
- conta pendente `Projeto Cauã` acessa reserva de voucher e preparação de
  campanha;
- evento pendente aparece no formulário e o cliente possui apenas `Salvar
  rascunho`, sem ação de ativação;
- backup anterior ao rollout:
  `/var/backups/business-pending-ads-before-deploy-20260824-100909.tar.gz`.

Não foram usados voucher nem campanha reais na validação automática. O próximo
passo é a jornada controlada com dados de teste: reservar, salvar/enviar,
aprovar conta e evento, revisar como RunnerHub e confirmar que a ativação só
ocorre na decisão administrativa final.
