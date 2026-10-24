# LIVE funnel tracking — 20/10/2026

Candidatos apenas; sem publicação nem operação Git nesta frente.

Runtime: `assets/js/rr-audience.js`, `assets/js/rr-audience.min.js`, `services/AudienceMeasurementService.cfc`, `includes/analytics/bootstrap.cfm` (versão `20261020livefunnel1`). Testes: `_codex/tests/audience-live-registration.test.js`, `_codex/tests/audience-live-contract.cfm`.

## Contrato final

- `content_open:live_coupon_viewable:EVENT_ID`: kind `content_open`, contentType `event`, contentId ID; seção `[data-live-coupon-view="ID"]` visível >=50% por >=1s contínuo; visibleMs/maxContinuousMs/ratio comprovam limiar. Usa content_open porque SQL restringe content_viewable a news/video. Não é abertura de evento (essa permanece `content_open:event:ID`).
- `content_open:live_coupon_copy_attempt:EVENT_ID`: clique capturado em `[data-live-coupon-copy="ID"]`.
- `content_open:live_coupon_copy_success:EVENT_ID` e `content_open:live_coupon_copy_error:EVENT_ID`: evento de window `rr-live-funnel` detail `{action:'coupon_copy_success'|'coupon_copy_error',eventId:'ID'}`; requer tentativa observada, consumida pelo resultado.
- `content_open:live_city_select:CIRCUIT_ID:CITY-UF`: kind `content_open`, type circuit, ID circuito do contexto; evento de window `rr-live-funnel` detail `{action:'city_select',citySlug:'campinas-sp'}`. Opção todas usa `all`; select `[data-live-city-select]` usa value vazio. Slug deve ser opção existente e atualmente selecionada, letras/hífens + UF conhecida, até 80 caracteres.
- `outbound_click:live_information:EVENT_ID`: links HTTPS sem marker de inscrição em contexto event para hosts exatos liverun.com.br/www e appliveexperience.com.br/www; exclui credenciais/porta alternativa. A URL não é transmitida.
- `outbound_click:live_registration:EVENT_ID` e Google `rr_live_registration_outbound` permanecem inalterados. Nenhuma nova ação vira compra/conversão.

IDs novos devem coincidir com conteúdo do contexto assinado. Servidor rejeita action/kind/key/tipo/ID inconsistentes e campos de Ads/engajamento incompatíveis. Ações são deduplicadas por pageView+key, não quantidade bruta de tentativas; relatório deve agregar sessões conforme contrato existente. Controles GPC/recusa/UTM/limites/env/interno continuam no envelope existente. Nunca envia código cupom, label livre, URL/query, identificador Google ou usuário.

## Verificação executada

- RED Node: 5 falhas esperadas para novos efeitos ausentes; GREEN 15/15 LIVE.
- Suite Node `node --test _codex/tests/audience-*.test.js`: 126/126, zero falhas. Overlay local em `/private/tmp/rr-live-funnel-verify-p5jc4z4u`; log `tracking-node-tests.log`.
- Mesmo teste LIVE contra arquivo minificado usando AUDIENCE_TRACKER_PATH: 15/15.
- `node --check` fonte e minificado: PASS. Minificado regenerado com Terser local já instalado (sem baixar dependências).
- CFML LIVE RED AudienceLiveTestFailure por visibilidade inválida aceita no baseline; GREEN PASS após validação aditiva.
- CFML editorial regressão: PASS (contrato/limiares preservados).
- Browser legado offline CFML+Chrome: 8 PASS (1280/390, edição/modal/link/barra, navegação nova aba/teclado/repetição/recusa). Sandbox inicial abortou Chrome; execução escalada autorizada passou. Nenhuma rede real para parceiro/produção nesse teste. UI nova é validada pelo root via CUA.

## Publicação/compatibilidade

Sem SQL/migração. Publicar serviço primeiro; JS/min, bootstrap atualizado e UI juntos. Servidor anterior já aceita content_open/outbound genéricos novos, mas a nova validação deve preceder emissão. Consumidor Business pode chegar antes/depois; dados novos são aditivos. Rollback reverte 4 runtimes; dados gravados não mudam. Root confirma baseline de produção, backup e resultado HTTP/ingestão reais antes de declarar publicado. Confira manifesto `tracking-manifest.json` e patch `tracking.patch`.

Revisão independente de integração UI: sem achado bloqueante. qAgrega/qCupom e view vw_cupom suportam seleção ativa/evento atual; ramos pai preservam data, cancelamento/esgotado. Capture de tentativa precede listener bubble de cópia e aceita erro síncrono. Campo readonly/label/status/fallback, link real e filtros por option permanecem compatíveis. Não houve teste de banco/produção nesta frente.
