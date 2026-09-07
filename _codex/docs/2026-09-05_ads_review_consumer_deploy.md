# Publicação pontual do consumidor de aprovação — 05/09/2026

Autorizada pelo usuário após informar a aplicação da migration `2026-09-04_ads_review_activation_invariants.sql`. Publicação concluída às 19:47:07 UTC.

## Escopo publicado

- Somente `ads/includes/backend.cfm`, em `/var/www/business.roadrunners.run/ads/includes/backend.cfm`.
- A verificação de disponibilidade e a chamada de `ads.review_campaign` usam a assinatura de seis argumentos, incluindo o ID da solicitação exibida.
- O arquivo anterior correspondia exatamente ao HEAD local; a diferença publicada contém apenas esse ajuste.
- Não foram publicados os demais patches de autenticação, formulários ou RoadRunners. Nenhuma migration, aprovação de campanha ou alteração de saldo foi executada nesta publicação.

## Recuperação e integridade

- Servidor confirmado pelo vhost Apache habilitado de `business.roadrunners.run`, com a raiz acima, no host SSH `ssh.runnerhub.run`.
- Backup privado: `/var/backups/business-ads-review-20260905.bFATpG/backend.before.cfm`.
- SHA-256 anterior: `8bb52969824cd836775e9a313ae13a723cd1af29455609aa09e6974fe5fae2dd`.
- SHA-256 publicado: `1392b2fdd99deeed5de360dbfc8ff3bcb17710e22793355697034b2b02506e2e`.
- Substituição por rename no mesmo filesystem, após conferir os hashes do arquivo vigente, candidato e backup. Preservados modo `0644` e UID:GID `501:50`.

## Verificações executadas

- Contratos estáticos `test_ads_phase2_business_access.sh` e `test_ads_pending_onboarding_approvals.sh`: PASS.
- Assertivas da assinatura: duas verificações de disponibilidade com seis argumentos e chamada com seis parâmetros, sendo o último o ID da revisão: PASS.
- `git diff --check -- ads/includes/backend.cfm`: PASS.
- Adobe ColdFusion: compilação de `ads/includes`, incluindo o backend publicado, com `successful 13 / total 13`.
- GET sem autenticação em `/ads/?view=admin`: HTTP 302 para a home, sem erro HTTP 500.

Não foi enviada decisão real de aprovação/recusa nem realizado teste autenticado da revisão. A execução da migration foi informada pelo usuário; esta publicação não a reaplicou nem consultou sua instalação diretamente no banco. Os gates de homologação e rollout completo continuam no relatório de correções de 04/09.
