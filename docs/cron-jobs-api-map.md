# Mapa de APIs para Cron Jobs

Atualizado em: 2026-06-22

Este mapa lista endpoints encontrados nos projetos da plataforma que podem ser monitorados ou acionados pelo gerenciador de cron jobs do Business.

## Criterios

- `Pronto`: pode ser cadastrado agora no painel de cron jobs.
- `Candidato`: faz sentido operacional, mas precisa de ajuste antes de virar cron seguro.
- `Nao agendar`: endpoint de consulta publica, webhook receptivo, acao manual sensivel ou dependencia de parametro dinamico.

## Business

### Prontos

| Nome sugerido | URL | Metodo | Auth | Intervalo | Observacao |
|---|---|---:|---|---:|---|
| Health Business | `https://business.roadrunners.run/health/` | GET | `none` | 5 min | Health simples para validar HTTP e disponibilidade do host. |
| API Runner Apps | `https://business.roadrunners.run/api/portal/runner-apps/` | GET | `none` | 15 min | Valida API consumida pelo menu Runner Apps nos sites da plataforma. |
| API Banners home sidebar | `https://business.roadrunners.run/api/portal/banners/?canal=roadrunners&local=home-side-banner&tamanho=sidebar-300x250&site_url=https://roadrunners.run` | GET | `none` | 15 min | Valida elegibilidade de banners; cuidado porque cada chamada registra `view`. Use com intervalo moderado. |

### Nao agendar

| Endpoint | Motivo |
|---|---|
| `https://business.roadrunners.run/api/portal/banners/click.cfm` | Registra clique; nao deve ser chamado por cron. |
| APIs de leaderboard em `/leaderboard/api/...` | Sao endpoints de consulta/widget. Use apenas se houver necessidade de monitoramento por prova especifica. |

## Road Runners

Catalogo detalhado especifico do projeto:

- [Mapa de APIs Road Runners para Cron Jobs](/Users/geraldoprotta/IdeaProjects/Business/docs/cron-jobs-roadrunners-api-map.md)

### Prontos

| Nome sugerido | URL | Metodo | Auth | Intervalo | Observacao |
|---|---|---:|---|---:|---|
| API central de notificacoes DEV | `https://dev.roadrunners.run/api/notifications/integrations/dispatch.cfm` | POST | `hmac_sha256` | sob demanda | Endpoint central ja aceita `X-RR-Handoff-Timestamp` e `X-RR-Handoff-Signature`. Nao e cron recorrente classico; usar para jobs de materializacao/dispatch quando houver payload. |
| API central de notificacoes PROD | `https://roadrunners.run/api/notifications/integrations/dispatch.cfm` | POST | `hmac_sha256` | sob demanda | Mesmo contrato do DEV, quando estiver disponivel no ambiente alvo. |

### Candidatos

| Endpoint | Ajuste recomendado | Observacao |
|---|---|---|
| `https://beta.roadrunners.run/api/push/runtime.cfm` | Criar endpoint de health publico ou HMAC que retorne se VAPID esta configurado. | O arquivo atual e include/runtime helper, nao um health tecnico completo. |
| `https://beta.roadrunners.run/api/push/status.cfm` | Nao usar como cron global; depende de usuario autenticado. | Bom para debug de usuario logado, ruim para monitoramento. |
| `https://roadrunners.run/api/strava/atualizar/?id_usuario={id}&token=...` | Substituir token fixo por HMAC/API dedicada e criar endpoint de fila. | Hoje atualiza um usuario especifico e tem acoes destrutivas via query string. Nao cadastrar em cron generico. |
| `https://roadrunners.run/api/strava/fetch/?verification_key={key}&token=...` | Criar endpoint batch por fila/limite. | Atualiza por `verification_key`; nao e rotina recorrente segura sem fila. |

### Nao agendar

| Endpoint | Motivo |
|---|---|
| `/api/ads/view/...`, `/api/ads/click/...`, `/api/ads/ping/...` | Sao telemetria de interacao; cron poluiria metricas. |
| `/api/me/*`, `/api/session/*`, `/api/push/subscribe.cfm`, `/api/push/unsubscribe.cfm`, `/api/push/reset.cfm` | Dependem de sessao/usuario ou alteram estado de dispositivo. |
| `/api/events/*`, `/api/results/*`, `/api/editorial/*`, `/api/feed/*`, `/api/search.cfm` | Consultas publicas. So usar para health especifico, nao para job de processamento. |

## Conteudo / News

Projeto local identificado como `News`; ambiente publico esperado: `https://conteudo.roadrunners.run`.

### Prontos

| Nome sugerido | URL | Metodo | Auth | Intervalo | Observacao |
|---|---|---:|---|---:|---|
| Health Conteudo | `https://conteudo.roadrunners.run/healthz/` | GET | `none` | 5 min | Retorna JSON com status de banco, upload e fonte REST. |

### Candidatos prioritarios

Os importadores abaixo sao bons candidatos, mas hoje os arquivos em `/admin/` exigem sessao de admin. Para cron, crie endpoints tecnicos com HMAC, por exemplo `/api/admin/importers/{fonte}.cfm`, reaproveitando a logica dos arquivos atuais.

| Fonte | Endpoint admin atual | Endpoint tecnico sugerido | Intervalo sugerido |
|---|---|---|---:|
| Corrida no Ar | `https://conteudo.roadrunners.run/admin/importer_corridanoar` | `https://conteudo.roadrunners.run/api/admin/importers/corridanoar.cfm` | 60 min |
| Contra Relogio | `https://conteudo.roadrunners.run/admin/importer_contrarelogio` | `https://conteudo.roadrunners.run/api/admin/importers/contrarelogio.cfm` | 60 min |
| Correria Campinas | `https://conteudo.roadrunners.run/admin/importer_correriacampinas` | `https://conteudo.roadrunners.run/api/admin/importers/correriacampinas.cfm` | 120 min |
| CBAt Corrida de Rua | `https://conteudo.roadrunners.run/admin/importer_cbat_corridaderua` | `https://conteudo.roadrunners.run/api/admin/importers/cbat-corrida-de-rua.cfm` | 180 min |

Recomendacao de auth: `hmac_sha256` com `secret_ref = road_runners_handoff` ou uma nova `secret_ref = conteudo_internal`.

### Nao agendar

| Endpoint | Motivo |
|---|---|
| `/admin/update_content_status*.cfm`, `/admin/save_*.cfm`, `/admin/delete_*.cfm` | Acoes editoriais manuais protegidas por sessao/CSRF. |
| `/publico/content.cfm` e `/publico/index.cfm` | Renderizacao/consulta publica de conteudo. |
| `/status-api/`, `/integracao-api/`, `/faq-api/` | Documentacao HTML, nao rotina tecnica. |

## RunnerHub

### Prontos ou quase prontos

| Nome sugerido | URL | Metodo | Auth | Intervalo | Observacao |
|---|---|---:|---|---:|---|
| RunnerHub Update Feed | `https://runnerhub.run/admin/mnt/update_feed.cfm` | GET | `bearer` | 10 min | Pronto para o Business. Usa `RUNNERHUB_UPDATE_FEED_JOB_TOKEN`, retorna JSON e possui advisory lock. |
| Importador YouTube RunnerHub | `https://runnerhub.run/api/youtube/` | GET | `bearer` | 60 min | Requer adaptar o endpoint ao mesmo contrato do `update_feed.cfm`: validar `RUNNERHUB_YOUTUBE_JOB_TOKEN` por Bearer antes do bloqueio por cookie, retornar JSON e usar advisory lock. Nao armazenar `jobToken` na URL. |

### Candidatos

| Endpoint | Ajuste recomendado | Observacao |
|---|---|---|
| `/admin/api/importacao/` | Criar API tecnica para processar fila de `tb_evento_corridas_temp` por lote. | O arquivo atual e pagina admin/HTML e executa acoes por `acao` e `id_evento`. |
| `/api/crawler/*_action.cfm` | Adicionar HMAC/token e separar rotinas de execucao de rotinas de callback. | Hoje sao endpoints de apoio da interface/crawler; muitos recebem payload POST de ferramentas externas. |
| `/api/chiptiming/`, `/api/excel/`, `/api/racezone/`, `/api/wiclax/`, `/api/tf/`, `/api/o2/`, `/api/ngtechno/` | Exigir `id_evento` ou fonte especifica e autenticar. | Bons para jobs por evento, nao para cron global sem parametros. |

### Nao agendar

| Endpoint | Motivo |
|---|---|
| `/api/webhook/*` | Sao receptores de terceiros; cron chamaria sem evento real. |
| `/api/strava/webhook/*` | Gerenciamento/webhook Strava, nao rotina recorrente do Business. |
| `/api/vimeo/` | Endpoint de teste/upload com credenciais hardcoded e acoes sensiveis. Nao cadastrar. |
| `/api/openai/`, `/api/gemini/`, `/api/ai/*` | Chamadas IA sob demanda; cron pode gerar custo sem necessidade. |

## OpenResults e Brasil Gigante

### Candidatos

| Projeto | Endpoint | Observacao |
|---|---|---|
| OpenResults | `https://openresults.run/api/eventos.cfm` | Consulta publica; pode ser usado como health funcional se necessario. |
| OpenResults | `https://openresults.run/api/eventos_por_estado.cfm` | Consulta publica; usar apenas para monitoramento. |
| Brasil Gigante | `https://circuitobrasilgigante.com.br/api/atletas_ranking.cfm` | Consulta publica do ranking; pode ser monitorada, mas nao processa rotina. |
| Brasil Gigante | `https://circuitobrasilgigante.com.br/api/resultados_sugeridos.cfm` | Consulta publica; usar apenas para health funcional. |

## Ordem recomendada de cadastro

1. `Health Business`
2. `Health Conteudo`
3. `API Runner Apps`
4. `API Banners home sidebar`
5. `RunnerHub Update Feed`, com Bearer e segredo fora do banco
6. `Importador YouTube RunnerHub`, se o token estiver configurado
7. Criar endpoints tecnicos HMAC para importadores do Conteudo
8. Criar endpoint batch/fila para atualizacao Strava no Road Runners
9. Criar endpoint batch/fila para importacao de eventos no RunnerHub

## Padrao recomendado para novos endpoints de cron

- Responder JSON sempre.
- Aceitar apenas `POST` para acoes que alteram dados.
- Proteger com `hmac_sha256` ou token forte fora do banco.
- Ter parametros `limit`, `dryRun` e `source`, quando fizer sentido.
- Retornar contadores: `processed`, `created`, `updated`, `skipped`, `errors`.
- Ser idempotente: chamar duas vezes nao deve duplicar dados.
- Nao depender de cookie, sessao ou login web.
