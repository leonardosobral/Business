# Wizard de campanha — estado, término e campanhas por evento

Publicação autorizada pelo usuário e concluída em 11/09/2026 às 18:13:14 UTC.

## Comportamento

- Em novas campanhas, a região sugerida acompanha a troca de evento (ex.: DF → SP).
- Alterar manualmente o estado, inclusive deixá-lo vazio, impede futuras sobrescritas automáticas.
- O término sugerido usa `data_final` do evento às 23:59. Datas manuais, campanhas existentes e valores reapresentados após erro de envio são preservados.
- Texto explicativo atualizado para contemplar a consulta de resultados no dia da prova.
- O seletor apresenta data, resumo de campanhas e nome/local do evento. Sem campanha, status único ou contagem e status distintos quando houver várias.
- As campanhas vêm da consulta existente da conta selecionada, com conferência adicional do `account_id` e deduplicação por campanha. Sem consulta adicional, migration ou alteração de permissões.

## Publicação

Destino: `/var/www/business.roadrunners.run/`, em `ssh.runnerhub.run`.

| Arquivo | SHA-256 publicado |
| --- | --- |
| `assets/js/ads-campaign-wizard.js` | `6bf30981e60d5219e9cfb44a8cd09b95fa4a775ddad21e45a8435429d4de8da2` |
| `ads/includes/workspace_campaign_form.cfm` | `d3d41b2453708182e07fb174940967fb270f114595331eed93dd538fc24003a5` |
| `ads/includes/event_campaign_summary.cfm` (novo) | `eb2283db03f54338b2cf438ac46d65dfb9149e7817b0aea0c057c3afb48d1d2a` |

Backup privado: `/var/backups/business-campaign-wizard-20260911.t5qEKg/`.

- `ads-campaign-wizard.before.js`: SHA anterior `201e5325f6e8014d45b4b04831adfe9008ea0694dccb4b7511aecf0b67e824b4`.
- `workspace_campaign_form.before.cfm`: SHA anterior `c1ff2f66333cd5abede6b8c2ebc5b92ffaec36699fee8803a6a72da568b4f07b`.
- Hashes anteriores, candidatos, backups e destinos conferidos. Publicação atômica por arquivo, dependência nova antes do formulário. Modo `0644`, UID:GID `501:50`.
- URL do JavaScript versionada como `?v=20260911-1`.

## Verificação e limites

- TDD: testes do wizard reproduziram estado retido e data três dias antes; passaram após o ajuste.
- 22 testes Node passaram. Os testes de interação chamam o `initWizard` real com doubles da fronteira DOM, sem dados de produção.
- Teste CFML de renderização passou: data final, estado sem campanhas da própria conta apesar de haver campanha de outra conta, múltiplas campanhas, status de revisão e vínculo pendente.
- Suítes de onboarding pendente e acesso Business passaram.
- Adobe ColdFusion de produção: `successful 14 / total 14`.
- Aba separada autenticada abriu sem erro, mas a seleção atual era “Todas as contas”, exibindo o painel global. A seleção do usuário foi preservada; não foi realizada interação com o formulário autenticado nesta publicação.
- Nenhum formulário enviado, campanha alterada/criada, anúncio clicado, saldo movimentado ou serviço reiniciado.

Rollback: conferir os hashes publicados para não sobrescrever atualizações posteriores, restaurar primeiro o formulário e depois o JavaScript dos backups. O helper novo pode permanecer sem referência. Não remover ou restaurar outros arquivos.
