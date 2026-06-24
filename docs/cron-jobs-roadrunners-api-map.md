# Mapa de APIs Road Runners para Cron Jobs

Atualizado em: 2026-06-22

Este documento mapeia especificamente as APIs existentes no projeto `RoadRunners` e indica como elas se relacionam com o gerenciador de cron jobs do Business.

## Resumo executivo

O Road Runners tem quatro tipos principais de API:

- APIs publicas read-only, boas para monitoramento funcional.
- APIs autenticadas do usuario, que dependem de sessao real e nao devem ser acionadas por cron.
- APIs de integracao HMAC, boas para disparos tecnicos sob demanda.
- APIs legadas/operacionais, que precisam ser revisadas antes de virar job recorrente.

## APIs prontas para cadastro no cron

### Monitoramento funcional read-only

Estas podem ser cadastradas como `GET`, `auth_mode = none`, com intervalo entre 5 e 30 minutos.

| Nome sugerido | URL | Intervalo | Observacao |
|---|---|---:|---|
| RR API docs | `https://roadrunners.run/api/` | 30 min | Valida se a camada API principal responde HTML/documentacao. |
| RR OpenAPI | `https://roadrunners.run/api/openapi.json` | 30 min | Valida contrato OpenAPI publicado. |
| RR Eventos calendario | `https://roadrunners.run/api/events/calendar.cfm?state=SC&limit=5` | 15 min | Health funcional do catalogo de eventos. |
| RR Eventos resultados | `https://roadrunners.run/api/events/results.cfm?q=maratona&limit=5` | 30 min | Health funcional de eventos com resultados. |
| RR Busca discovery | `https://roadrunners.run/api/discovery/search.cfm?q=maratona&sections=all&limit=5` | 30 min | Busca publica unificada sem IA. |
| RR Editorial noticias | `https://roadrunners.run/api/editorial/news.cfm?limit=5` | 30 min | Valida integracao editorial/News pelo Road Runners. |
| RR Editorial videos | `https://roadrunners.run/api/editorial/videos.cfm?limit=5` | 30 min | Valida consulta de videos. |
| RR Canais noticias | `https://roadrunners.run/api/editorial/news-channels.cfm` | 60 min | Canais editoriais. |
| RR Canais videos | `https://roadrunners.run/api/editorial/video-channels.cfm` | 60 min | Canais de video. |
| RR Desafios catalogo | `https://roadrunners.run/api/challenges/catalog.cfm?status=active&limit=10` | 30 min | Catalogo publico de desafios ativos. |
| RR Treinos eventos | `https://roadrunners.run/api/training/events.cfm?status=upcoming&limit=10` | 30 min | Lista publica de treinos futuros. |
| RR Cupons catalogo | `https://roadrunners.run/api/coupons/catalog.cfm?type=all&limit=10` | 60 min | Metadados publicos de cupons, sem codigo de ativacao. |

### Integracao tecnica sob demanda

Estas nao sao "cron recorrente" classico, mas podem ser chamadas por jobs pontuais do Business quando houver payload.

| Nome sugerido | URL | Metodo | Auth | Observacao |
|---|---|---:|---|---|
| RR Notification Dispatch DEV | `https://dev.roadrunners.run/api/notifications/integrations/dispatch.cfm` | POST | `hmac_sha256` | API central de notificacoes. Requer body JSON e headers `X-RR-Handoff-*`. |
| RR Notification Dispatch BETA | `https://beta.roadrunners.run/api/notifications/integrations/dispatch.cfm` | POST | `hmac_sha256` | Mesmo contrato, quando disponivel no ambiente beta. |
| RR Notification Dispatch PROD | `https://roadrunners.run/api/notifications/integrations/dispatch.cfm` | POST | `hmac_sha256` | Mesmo contrato para producao. |
| RR Push send | `https://roadrunners.run/api/push/send.cfm` | POST | `hmac_sha256` | Envio Push tecnico. Normalmente deve ser chamado indiretamente pelo dispatch central, nao por cron direto. |

## APIs publicas read-only mapeadas

### Atletas

| Endpoint | Uso |
|---|---|
| `/api/athletes/profile.cfm?tag={tag}` | Perfil publico por tag. |
| `/api/athletes/followers.cfm?tag={tag}&limit=25` | Seguidores validados. |
| `/api/athletes/following.cfm?tag={tag}&limit=25` | Quem o atleta segue. |
| `/api/athletes/results.cfm?tag={tag}&limit=25` | Resultados vinculados ao atleta. |
| `/api/athletes/agenda.cfm?tag={tag}` | Agenda publica do atleta. |
| `/api/athletes/game-snapshot.cfm?tag={tag}` | Payload agregado para jogos/integracoes. |
| `/api/athletes/suggested-results.cfm?tag={tag}` | Sugestoes publicas quando aplicavel. |

Recomendacao: usar apenas para monitoramento com uma tag conhecida de teste. Nao agendar varreduras de todos os atletas por estes endpoints.

### Eventos

| Endpoint | Uso |
|---|---|
| `/api/events/calendar.cfm?q={termo}&state={UF}&limit=10` | Busca calendario publico. |
| `/api/events/results.cfm?q={termo}&limit=10` | Eventos com resultados. |
| `/api/events/detail.cfm?tag={eventTag}` | Detalhe por tag. |
| `/api/events/detail.cfm?id={id_evento}` | Detalhe por ID. |
| `/api/eventos.cfm` | API legada/listagem de eventos. |
| `/api/eventos_busca.cfm` | Busca legada de eventos. |

Recomendacao: monitorar `calendar`, `results` e `detail` com parametros pequenos. Evitar endpoints legados para cron novo, salvo necessidade de compatibilidade.

### Resultados

| Endpoint | Uso |
|---|---|
| `/api/results/event.cfm?tag={eventTag}&limit=25` | Lista de concluintes oficiais. |
| `/api/results/summary.cfm?tag={eventTag}` | Resumo por distancia/modalidade. |
| `/api/results/detail.cfm?id={id_resultado}` | Detalhe publico de um resultado. |
| `/api/resultados_busca.cfm` | Busca legada. |
| `/api/resultados_sugeridos.cfm` | Sugestoes legadas. |

Recomendacao: monitoramento read-only com evento conhecido. Nao usar como rotina de processamento.

### Busca e discovery

| Endpoint | Uso |
|---|---|
| `/api/discovery/search.cfm?q={termo}&sections=all&limit=10` | Busca publica unificada sem IA. |
| `/api/search.cfm?busca={termo}` | Busca IA/interpretacao; exige usuario verificado. |
| `/api/atletas_busca.cfm` | Busca legada de atletas. |
| `/api/noticias_busca.cfm` | Busca legada de noticias. |
| `/api/videos_busca.cfm` | Busca legada de videos. |

Recomendacao: usar `discovery/search.cfm` para monitoramento. Nao cadastrar `/api/search.cfm` como cron, pois exige contexto de usuario verificado e pode chamar IA.

### Editorial

| Endpoint | Uso |
|---|---|
| `/api/editorial/news.cfm?q={termo}&limit=10` | Lista/busca de noticias. |
| `/api/editorial/news-detail.cfm?slug={slug}` | Detalhe de noticia. |
| `/api/editorial/news-channels.cfm` | Canais de noticias. |
| `/api/editorial/videos.cfm?q={termo}&limit=10` | Lista/busca de videos. |
| `/api/editorial/video-detail.cfm?id={id_media}` | Detalhe de video. |
| `/api/editorial/video-channels.cfm` | Canais de videos. |
| `/api/noticias_infinite.cfm` | Feed legado/infinite de noticias. |
| `/api/videos_infinite.cfm` | Feed legado/infinite de videos. |

Recomendacao: bons para monitoramento funcional da integracao com conteudo/videos.

### Feed

| Endpoint | Uso |
|---|---|
| `/api/feed/athlete.cfm?tag={tag}&limit=25` | Feed publico de atleta. |
| `/api/feed.cfm` | Feed legado. |

Recomendacao: monitoramento apenas com tag conhecida; nao varrer atletas.

### Desafios e badges

| Endpoint | Uso |
|---|---|
| `/api/challenges/catalog.cfm?status=active` | Catalogo publico. |
| `/api/challenges/detail.cfm?tag={challengeTag}` | Detalhe do desafio. |
| `/api/challenges/athlete.cfm?tag={tag}` | Desafios publicos do atleta. |
| `/api/challenges/badges.cfm?tag={tag}` | Badges publicos/computados. |

Recomendacao: monitorar catalogo e um detalhe conhecido. Nao usar para recalculo de ranking.

### Treinos

| Endpoint | Uso |
|---|---|
| `/api/training/events.cfm?status=upcoming&state=SC` | Treinos futuros. |
| `/api/training/detail.cfm?id={id_evento}` | Detalhe do treino. |

Recomendacao: bom para monitoramento de disponibilidade da API de treinos.

### Cupons

| Endpoint | Uso |
|---|---|
| `/api/coupons/catalog.cfm?type=all&limit=25` | Catalogo publico sem codigo. |
| `/api/coupons/detail.cfm?id={id_cupom}` | Detalhe publico sem codigo. |

Recomendacao: monitoramento eventual.

## APIs autenticadas de usuario

Estas dependem de sessao real (`REQUEST.Usuario.logado`) e nao devem ser cadastradas como cron global.

| Grupo | Endpoints |
|---|---|
| Sessao | `/api/session/me.cfm`, `/api/session/permissions.cfm` |
| Meu perfil | `/api/me/profile.cfm`, `/api/me/summary.cfm`, `/api/me/results.cfm`, `/api/me/suggested-results.cfm`, `/api/me/agenda.cfm`, `/api/me/training.cfm` |
| Social e desafios | `/api/feed/me.cfm`, `/api/me/challenges.cfm`, `/api/me/badges.cfm`, `/api/me/coupon-activation.cfm` |
| Notificacoes | `/api/me/notifications.cfm`, `/api/notifications/inbox.cfm`, `/api/notifications/unread-count.cfm`, `/api/notifications/mark-read.cfm`, `/api/notifications/open.cfm` |
| Push do usuario | `/api/me/push-status.cfm`, `/api/me/push-preferences.cfm`, `/api/me/push-pending.cfm`, `/api/push/status.cfm`, `/api/push/pending.cfm`, `/api/push/subscribe.cfm`, `/api/push/unsubscribe.cfm`, `/api/push/reset.cfm`, `/api/push/test.cfm` |
| Atendimento | `/api/me/support-sectors.cfm`, `/api/me/support-tickets.cfm`, `/api/me/support-ticket.cfm` |
| Strava privado | `/api/me/strava-status.cfm`, `/api/me/strava-activities.cfm` |

Recomendacao: nao cadastrar no cron. Para monitorar estes contratos, criar um endpoint tecnico separado de smoke test que nao dependa de usuario real.

## APIs de integracao e processamento

### Notificacoes

| Endpoint | Status para cron | Observacao |
|---|---|---|
| `/api/notifications/integrations/dispatch.cfm` | Pronto sob demanda | POST com HMAC. Materializa notificacoes e pode acionar Push. |
| `/api/push/send.cfm` | Pronto sob demanda, mas preferir dispatch | Include de `send-notifications.cfm`. |
| `/api/push/send-notifications.cfm` | Pronto sob demanda | Envio Push tecnico com HMAC. |

### Strava

| Endpoint | Status para cron | Observacao |
|---|---|---|
| `/api/integrations/strava/batch-refresh.cfm` | Pronto para cron | POST HMAC, lote limitado, dry-run, locks e resposta JSON. Substitui a fila em navegador. |
| `/api/strava/atualizar/index.cfm?id_usuario={id}&token=...` | Legado, nao agendar | Fluxo manual por usuario. Nao deve ser usado pelo gerenciador de cron. |
| `/api/strava/fetch/index.cfm?verification_key={key}&token=...` | Candidato com refatoracao | Atualiza por `verification_key`. Precisa virar batch/fila. |
| `/api/strava/activities/index.cfm` | Nao agendar | API de leitura/apoio de atividades. |
| `/api/strava/segments/index.cfm` | Nao agendar | API especifica de segmentos. |
| `/api/strava/index.cfm` | Nao agendar | Fluxo OAuth/retorno. |

Configuracao operacional: consulte `docs/strava-batch-cron.md` e aplique `administracao/cron-jobs/strava_batch_job.sql`.

## APIs de telemetria, ads e eventos de interacao

Nao cadastrar como cron porque alteram metricas ou simulam interacoes.

| Endpoint | Motivo |
|---|---|
| `/api/ads/view/view.cfm` | Registra visualizacao. |
| `/api/ads/click/click.cfm` | Registra clique. |
| `/api/ads/ping/ping.cfm` | Telemetria/ping de anuncio. |
| `/api/seguidores.cfm` | Acao social legada/sensivel. |
| `/api/incluir_evento.cfm` | Cria solicitacao/evento a partir de form. |
| `/api/upload_foto_atleta.cfm` | Upload/altera imagem de perfil. |

## APIs legadas e CFCs

| Endpoint | Status para cron | Observacao |
|---|---|---|
| `/api/Auth.cfc`, `/api/Util.cfc`, `/api/Objeto.cfc`, `/api/ReturnObject.cfc` | Nao cadastrar | CFCs de apoio/legados. |
| `/api/correriacampinas/*.cfc` | Nao cadastrar direto | API legada com token fixo. Usar apenas se houver contrato externo especifico. |
| `/api/eventos.cfm`, `/api/eventos_busca.cfm`, `/api/resultados_busca.cfm`, `/api/noticias_busca.cfm`, `/api/videos_busca.cfm`, `/api/atletas_busca.cfm` | Monitoramento opcional | Preferir APIs novas versionadas por pasta. |

## Jobs recomendados para cadastrar agora

| Nome | URL | Metodo | Auth | Intervalo |
|---|---|---:|---|---:|
| RR OpenAPI prod | `https://roadrunners.run/api/openapi.json` | GET | `none` | 30 min |
| RR OpenAPI beta | `https://beta.roadrunners.run/api/openapi.json` | GET | `none` | 30 min |
| RR Eventos calendario prod | `https://roadrunners.run/api/events/calendar.cfm?state=SC&limit=5` | GET | `none` | 15 min |
| RR Editorial noticias prod | `https://roadrunners.run/api/editorial/news.cfm?limit=5` | GET | `none` | 30 min |
| RR Desafios catalogo prod | `https://roadrunners.run/api/challenges/catalog.cfm?status=active&limit=10` | GET | `none` | 30 min |
| RR Treinos futuros prod | `https://roadrunners.run/api/training/events.cfm?status=upcoming&limit=10` | GET | `none` | 30 min |
| RR Notification dispatch dev smoke | `https://dev.roadrunners.run/api/notifications/integrations/dispatch.cfm` | POST | `hmac_sha256` | manual/sob demanda |

## Ajustes recomendados antes de novos crons

1. Criar health tecnico em `RoadRunners`, por exemplo `/api/health.cfm`, retornando banco, ambiente, VAPID configurado, API de conteudo acessivel e versao.
2. Criar batch Strava com HMAC, limite e fila, substituindo chamadas individuais com token fixo.
3. Criar smoke test autenticado interno para APIs `/me/*`, sem depender de cookie de usuario real.
4. Expor health tecnico do Push separado de `/api/push/status.cfm`, porque o status atual depende de usuario logado.
5. Evitar cron em endpoints que gravam view/click/upload/social/action.
