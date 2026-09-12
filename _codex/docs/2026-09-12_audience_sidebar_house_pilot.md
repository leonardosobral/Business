# Piloto de exposição do banner lateral sem campanha

Data: 2026-09-12. **Publicado às 11:48:22 de Brasília**, com verificação final às 11:50:40.

[Recibo de publicação](2026-09-12_audience_sidebar_house_publicado.md).

O usuário autorizou manter uma peça institucional no espaço lateral desktop
quando não houver campanha elegível. Foram preparados dois arquivos de runtime
no RoadRunners; nenhum runtime ou SQL do Business foi alterado.

Detalhes, comandos de teste, limites e ordem de publicação:
[documentação RoadRunners](../../../RoadRunners/_codex/docs/audience-sidebar-house-pilot.md).

No Business, acompanhar a posição `rr-sidebar-banner-desktop`, placement
`rr-sidebar-banner-300x250`, nas colunas atuais de institucional, solicitações,
renders e exposição qualificada. A peça local não registra entrega ou eventos de
anúncio, não possui campanha/IDs Ads e não consome créditos.

A identificação visual `sidebar-marathons-300x250-v1` fica apenas no DOM. Este
lote não adiciona um filtro exclusivo por versão ou grupos A/B no painel, nem
implementa o versionamento persistido de layout do plano amplo. Antes/depois
depende do horário real de publicação e deve considerar a mudança de altura.

Validação: 25 cenários CFML e 17 com coletor real, 87 testes existentes de audiência,
prévia Chrome em desktop/mobile e revisão independente. Publicados somente os
dois arquivos de runtime, com backup. Campanhas existentes e coleta preservadas
em produção; o ramo institucional sem campanha não foi observado no smoke test,
pois havia campanha elegível. Ele foi exercitado localmente, sem forçar alterações
de campanha/configuração em produção.
