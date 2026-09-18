# Dois patrocinados nas listagens — 16/09/2026

## Correção publicada

- Estado e busca antes solicitavam uma única seleção; agora solicitam duas.
- Ambas usam o placement canônico existente e o ranking vigente. A segunda exclui a campanha vencedora da primeira. Não foi criado placement de banco nem alterado lance, segmentação ou cobrança.
- As posições físicas possuem chaves distintas de audiência (`-secondary` na segunda), mantendo a mesma chave de placement. Renderer compartilhado conserva fallback para home/sidebar.
- Somente `RoadRunners/includes/eventos_ads.cfm` e `RoadRunners/includes/ads_v1/native_event_slot.cfm` foram publicados. Alteração anterior de banner_context preservada.

## Verificação

- Teste CFML `_codex/tests/ads-listing-two-slots.cfm`: falhou com uma posição antes da correção; passou após correção, cobrindo estado/busca/home, 2/1/0 candidatos, exclusão do vencedor, região, placements e identidade física distinta.
- RoadRunners `_codex/tests/audience-tracker.test.js`: 67 testes passaram, incluindo duas posições com o mesmo placement e métricas independentes.
- Compilação nativa ColdFusion dos dois arquivos aprovada; diff sem erros de whitespace.
- Produção `/estado/ba/`: Live! Salvador primeiro, Maratona Internacional de São Paulo 2027 segundo; campanhas e deliveries distintos. Layout conferido no desktop e em 390px, sem overflow dos cards. Viewport restaurado.
- Produção `/busca/?distancia_inicio=5&distancia_fim=5&busca_mode=ai`: contexto SC mostrou Live! Jaraguá e Avaí, duas posições distintas, layout conferido.
- Nenhum link de anúncio clicado nos testes; nenhuma campanha alterada.
- Hashes publicados verificados e 114 arquivos protegidos preservados.

## Recuperação

- Backup servidor: `/var/backups/house-banner-scope.0ac510fba4da`.
- Manifesto e recibos: `_codex/staging/ads-listing-two-slots-20260916/`.
- Publicador: `_codex/scripts/deploy_house_banner_scope.py`, com caminho do renderer explicitamente permitido.
- Sem migration, restart, commit ou push.
