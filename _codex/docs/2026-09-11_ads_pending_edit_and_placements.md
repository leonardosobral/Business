# Edição durante análise e locais de exibição

Implementação de 11/09/2026. **Publicada às 20:03:32 UTC**, após o usuário informar que aplicou a migration.

## Comportamento

- `Gerenciar → Editar` retira da análise campanhas `DRAFT` com revisão `PENDING_REVIEW` ou `WAITING_PREREQUISITES`. A API existente `ads.prepare_campaign_for_edit(uuid,bigint,integer)` cancela a revisão com histórico e mantém a campanha fora do ar.
- Campanhas aprovadas continuam usando Pausar e editar / Editar e reenviar, com nova aprovação obrigatória.
- O formulário abre a campanha selecionada. Enviar para análise salva e reencaminha; Salvar como rascunho não reencaminha.
- Acesso direto ao formulário e POST de salvamento permanecem bloqueados enquanto a revisão não for retirada, inclusive em `WAITING_PREREQUISITES`.
- Todas as quatro áreas selecionáveis são defaults de novas campanhas. Edição e reapresentação após erro preservam a seleção salva/enviada, inclusive seleção vazia inválida. Página inicial continua habilitando os dois placements físicos no backend.
- “Página do evento” passa a “Lateral do site”. A descrição corresponde ao consumidor atual no RoadRunners: sugestão patrocinada na lateral da home para usuários logados. A chave técnica `rr-sidebar-event-native` não muda.

## Ordem de publicação

1. Aplicar `_codex/sql/2026-09-11_ads_prepare_pending_campaign_edit.sql` com o procedimento de migrations existente.
2. Publicar `ads/home.cfm`, `ads/includes/backend.cfm`, `ads/includes/workspace_campaigns.cfm` e `ads/includes/workspace_campaign_form.cfm`, conferindo mudanças concorrentes e mantendo backups.
3. Compilar os templates ColdFusion e verificar a interface autenticada, desktop/mobile. Envio, edição ou aprovação de campanhas reais somente quando autorizado.

A migration substitui uma função e registra sua versão em `ads.schema_migrations`. Não altera estruturas nem registros do schema `public`; apenas mantém consultas de permissão às tabelas de usuários/vínculos. A aplicação da migration, por si, não cancela nem altera campanhas existentes. Não há alteração de código no RoadRunners.

## Testes executados

- RED/GREEN CFML: reproduzidos e corrigidos botões ausentes em análise, defaults incompletos e atalho indevido durante espera de pré-requisitos.
- `_codex/tests/ads-campaign-submit-flow.cfm`: fragmentos reais de CFML/HTML; banco simulado na fronteira. Verifica opções de salvamento/envio, permissões, retirada antes da edição, guard do POST e preservação de seleção.
- 23 testes Node de wizard, ordenação de eventos e símbolos CFML passaram.
- Suítes shell de onboarding, acesso Business e edição aprovada passaram. Esta última ainda testa o contrato da migration histórica de 02/09; o comportamento novo é coberto pelo teste PostgreSQL abaixo.
- PostgreSQL 16 local isolado, socket Unix sem TCP, dados sintéticos: aplicada migration histórica; contrato novo falhou por recusar `DRAFT`. Aplicada migration nova; `_codex/tests/ads-review-edit-contract.sql` passou com usuário owner/admin, revisão pendente/aguardando pré-requisitos/aprovada, cancelamento auditado, bloqueio cross-account, leitor, vínculo pendente, usuário desconhecido e campanha finalizada. Fixture contém tabelas mínimas, não replica todos os triggers/RLS de produção.
- Não houve migration de produção, publicação ou alteração de campanha real nesta implementação. A validação visual final depende da publicação após a migration.

Para repetir o teste SQL, use **somente um cluster local vazio**, execute com `psql -X -v ON_ERROR_STOP=1`: fixture `_codex/tests/ads-review-edit-fixture.sql`, migration de 02/09, migration de 11/09, contrato `_codex/tests/ads-review-edit-contract.sql`. Nunca aplique a fixture num banco existente.

Rollback: restaurar primeiro a interface anterior; a função nova é aditiva e pode permanecer. Caso seja necessário restaurar a função antiga, usar a definição de 02/09 após retirar os novos botões. Preservar históricos de revisão e não reativar campanhas automaticamente.

## Recibo de publicação

Destino: `/var/www/business.roadrunners.run`, host `ssh.runnerhub.run`.
Backup privado: `/var/backups/business-pending-edit-20260911.c74hYc/`. Arquivos anteriores preservados como `<basename>.before`. Hashes anteriores, candidatos, backups e destinos conferidos; troca atômica por arquivo, modo 0644, UID:GID 501:50.

| Arquivo | SHA-256 publicado |
| --- | --- |
| `ads/home.cfm` | `c09540fa4f48a1c9f7470196150a2c2c1dddc39e9ccc0762c59d1a8bfaee0007` |
| `ads/includes/backend.cfm` | `3455c42d670f27631e7e651ada0c51d8a108103e6ccfee8a66fcfb33b54732a6` |
| `ads/includes/workspace_campaigns.cfm` | `d85b66ba16893dbaff9806ae4c4258f7b023a4cdad8f0742db4477645d62eebc` |
| `ads/includes/workspace_campaign_form.cfm` | `99360d8c78c2f46798706e0f56efac9833064801f90e84f7434ad59e51fc1cf8` |

- Teste CFML de fluxo executado novamente: PASS.
- Adobe ColdFusion compilou **24/24** templates/componentes de `ads`.
- Aba separada autenticada abriu sem erro. A sessão estava em Todas as contas, com zero campanhas na fila; não foi alterada a seleção global nem criada uma pendência artificial. Verificação ponta a ponta do clique Editar em análise não realizada em produção. Defaults e permissões permanecem cobertos pelos testes locais anteriores.
- Aba de conferência fechada, original preservada. Nenhuma campanha enviada, editada ou aprovada; nenhum saldo movimentado ou serviço reiniciado. Migration não reaplicada pelo agente.
