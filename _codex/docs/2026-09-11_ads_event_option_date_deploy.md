# Data final no seletor de eventos — publicação

Publicação autorizada pelo usuário e concluída em 11/09/2026 às 17:38:57 UTC.

- Único arquivo publicado: `ads/includes/workspace_campaign_form.cfm`.
- Destino: `/var/www/business.roadrunners.run/ads/includes/workspace_campaign_form.cfm`, em `ssh.runnerhub.run`.
- Mudança: opções mostram `Nome — Cidade/UF — dd/mm/aaaa`, usando `data_final`; datas ausentes não geram separador vazio e o aviso de vínculo em análise permanece.
- Comparação prévia com produção: somente a linha do texto da opção diferia.
- Backup privado: `/var/backups/business-event-date-20260911.7ftny2/workspace_campaign_form.before.cfm`.
- SHA-256 anterior: `439805c0173fd6cee0ababb30627f0f78536c00431d180a57a862e5e760fe32c`.
- SHA-256 publicado: `2c9bccdd3b82422ec19171cb9d292a0858afb500fc42f4cf29eca380eb69ed8a`.
- Substituição atômica com verificação dos hashes do destino/candidato/backup; modo `0644` e UID:GID `501:50` preservados.

## Verificação

- Teste local CFML de renderização: passou para data final distinta da inicial, data ausente e vínculo pendente.
- Compilação Adobe ColdFusion de `ads/includes`: `successful 13 / total 13`.
- Navegação autenticada em aba separada, conta Live!: seletor exibiu, entre outros, `LIVE! RUN XP Salvador 2026 — Salvador/BA — 20/12/2026` e `LIVE! RUN XP Itaipu 2026 — Foz do Iguaçu/PR — 13/12/2026`.
- Nenhum formulário enviado, campanha criada, voucher resgatado ou saldo alterado nesta publicação. Nenhuma migration ou reinicialização de serviço.
- O teste CFML não foi publicado. A aba original do usuário não foi recarregada.

Para recuperação, verificar que o destino ainda corresponde ao hash publicado antes de restaurar o backup, preservando alterações posteriores.

## Segunda publicação — data primeiro, crescente e somente eventos não encerrados

Publicação autorizada novamente pelo usuário, concluída em 11/09/2026 às 17:49:06 UTC.

- Arquivos publicados: `ads/includes/backend.cfm` e `ads/includes/workspace_campaign_form.cfm`.
- Seletor: `dd/mm/aaaa — Nome — Cidade/UF`, ordenado por `data_final ASC NULLS LAST`, com desempate pelo nome.
- Filtro: `evt.data_final >= CURRENT_DATE`; inclui eventos que terminam hoje e exclui encerrados ou sem data final. Vínculos e permissões existentes foram preservados.
- Produção correspondia ao HEAD local antes do ajuste; somente as três linhas de consulta e o texto da opção diferiam.
- Backup privado: `/var/backups/business-event-selector-20260911.QyY1h0/`, arquivos `backend.before.cfm` e `workspace_campaign_form.before.cfm`.
- SHA-256 backend anterior: `1392b2fdd99deeed5de360dbfc8ff3bcb17710e22793355697034b2b02506e2e`.
- SHA-256 backend publicado: `a9b31c3b77763ea06528e88996d00b9fc0c3a9b3229b2b32a3a63664a5893195`.
- SHA-256 formulário anterior: `2c9bccdd3b82422ec19171cb9d292a0858afb500fc42f4cf29eca380eb69ed8a`.
- SHA-256 formulário publicado: `c1ff2f66333cd5abede6b8c2ebc5b92ffaec36699fee8803a6a72da568b4f07b`.
- Substituição atômica por arquivo, com hashes anteriores/candidatos/backups verificados e modo `0644`, UID:GID `501:50` preservados.
- Verificação local: 16 testes Node passaram, incluindo ordenação e filtro executados em SQLite em memória; teste CFML de renderização também passou.
- Compilação Adobe ColdFusion em produção: `successful 13 / total 13`.
- Verificação autenticada no Chrome, conta Live!, em aba separada: 16 eventos disponíveis, todos de 13/09/2026 a 20/12/2026, em ordem crescente e com data primeiro. Eventos antigos não apareceram.
- Sem migration, reinicialização, envio de formulário, criação/alteração de campanha ou movimentação de saldo. Aba original do usuário preservada.

Rollback desta segunda publicação: conferir os dois hashes publicados antes de restaurar os respectivos `.before.cfm`, para não sobrescrever alterações posteriores.
