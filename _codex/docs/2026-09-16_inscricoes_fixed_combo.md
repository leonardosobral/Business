# Combo de eventos — 16/09/2026

Publicado somente `inscricoes/includes/backend.cfm` e `inscricoes/home.cfm`.
Lista fixa, na ordem solicitada: 72611, 37071, 72266, 70020, 72357. Padrão 72611; mudança no select envia GET `cod_evento` e recarrega os dados. Parâmetro limitado aos cinco códigos; filtros de conta mantidos.

Ajustes necessários na consulta existente: NULLIF no denominador auxiliar para não interromper eventos antigos por divisão por zero; vínculo pedido/participante também pelo código do evento. Demais cálculos e interface mantidos.

Validação: cinco seleções e fallback executados em CFML local; compilação Adobe CF dos dois arquivos aprovada; Chrome autenticado confirmou combo selecionado 70020 e resultados (18.154 inscrições, vendas R$ 3.648.365,00). Arquivos publicados conferidos por hash. Nenhuma alteração de banco ou Git.

Backup recuperável: `/var/backups/business-inscricoes-event-selector.9a02def81585`. Recibos `2026-09-16_inscricoes_fixed_combo{,-publish,-verify}.json`. A preparação anterior `2026-09-16_inscricoes_event_selector.json` foi substituída por este escopo e não foi publicada.

## Inclusão de 88278

A pedido do usuário, incluído 88278 como primeira opção e novo padrão. Publicado somente `inscricoes/includes/backend.cfm`, com baseline da publicação anterior conferido, compilação Adobe CF aprovada e backup `/var/backups/business-inscricoes-default-88278.12e1a3a8a9e9`. Recibos `2026-09-16_inscricoes_default_88278{,-publish,-verify}.json`. Chrome autenticado confirmou `/inscricoes/` sem parâmetro selecionando 88278, com vendas e ticket R$ 0,00 no momento da verificação.
