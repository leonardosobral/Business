# Audiência e inventário — plano de implementação

**Goal:** Mensurar navegação e todas as posições publicitárias renderizadas, mesmo sem campanha, e apresentar origem e potencial comercial no Business.

**Architecture:** RoadRunners produz contexto assinado e eventos de navegador; um endpoint próprio valida e persiste eventos idempotentes em PostgreSQL. Business lê as informações exclusivamente em uma rota administrativa. Contratos de cobrança Ads permanecem separados.

**Tech Stack:** ColdFusion/CFML, PostgreSQL 16, JavaScript sem dependências, Node test runner e navegador para validação.

**Spec:** `_codex/docs/estrategia_audiencia_inventario_e_midia_proposta.md`, com a correção regional aprovada pelo usuário.

**Estado atual:** `_codex/docs/2026-09-07_audiencia_painel_finalizacao.md` registra o painel final e os controles implementados após a rodada HTTP inicial. O usuário confirmou opt-out e 90 dias de eventos detalhados; produção permanece desligada. A configuração escalar mencionada na tarefa 1 é histórica e foi substituída pelo mapa exato por host na tarefa 5.

## Restrições e decisões de execução

- Contexto SC conta como audiência comercial SC, inclusive com acesso/perfil SP. `market_uf = context_uf`, depois perfil e acesso como fallback; campos preservados separadamente. Não alterar o leilão/segmentação existente.
- Trabalho preparado em `/private/tmp/rr-audience-7rMMoU/{RoadRunners,Business}` a partir do checkout atual, incluindo alterações preexistentes. Somente arquivos da entrega serão aplicados de volta, após revisão do diff. Não criar commits/branches nem publicar sem solicitação.
- Esta etapa entrega coleta, inventário, audiência, conteúdo e atribuição de entrada. Aquisição paga depende de verba/acesso e fica no plano de mídia. Previsão de entrega não deve inventar histórico ainda inexistente.
- Visibilidade: 50%, 1 segundo contínuo, documento visível, imagem carregada; reentrada e beacons repetidos não duplicam. Espaço colapsado registra oportunidade, sem alegar exposição visível.
- Um mesmo page-view/slot tem identidade estável; partial não cria novo page-view. Cada slot físico terá chave estável; layout oculto não produz impressão.
- Busca assíncrona preserva a abertura original e reassina somente o contexto regional dos slots retornados. Chave física/contextual estável por UF; nova entrega tem exposição de anúncio própria. Business distingue abertura de página de página com atividade na UF, deduplicando o total geral.
- Placeholders assíncronos começam em `pending`, nunca em vazio presumido. A oportunidade evolui uma única vez para estado final. Eventos da posição não carregam IDs financeiros; eventos do anúncio preservam delivery/campaign.
- Sem IP bruto, e-mail, CPF, query string livre ou tokens de anúncio na telemetria. Tokens assinados vinculam o contexto da página. Limites de payload/lote, origem, expiração, validação e falha isolada da navegação.
- Produção, beta/dev e acesso interno identificados; painel padrão exclui teste/interno. Sem amostra silenciosa nos totais do período.

## Contrato compartilhado v1

`window.RoadRunnersAudienceConfig = { endpoint, context, contextToken, signature }` é emitido no layout. `context` é um objeto com chaves camelCase: `schemaVersion:1, pageViewId` UUID RFC4122, `issuedAt` Unix segundos, `siteHost, environment, pageFamily, pagePath, contentType, contentId, visitorUf, profileUf, contextUf, marketUf, geoSource, isInternal`. URL/path somente canônico permitido, sem query. Contexto assinado por serviço no servidor. A serialização exata assinada trafega também como `contextToken` base64 UTF-8, sem reserialização para validar.

`POST /api/analytics/collect.cfm` recebe JSON `{ contextToken, signature, visitorId, sessionId, source, medium, campaign, creative, referrerHost, events:[...] }`. IDs cliente são UUID RFC4122. Atribuição é normalizada/truncada. Cada evento tem `{ kind, key, slotKey, placementKey, slotState, deliveryId, campaignId, contentType, contentId, activeMs, visibleMs, maxContinuousMs, ratio, deviceClass }`. Campos opcionais têm defaults, nenhum JSON livre fica armazenado. `key` tem no máximo 160 caracteres e é estável por evento lógico.

Tipos: `page_view`, `page_engagement`, `slot_opportunity`, `slot_request`, `slot_served`, `slot_render`, `ad_render`, `slot_viewable`, `ad_viewable`, `content_open`, `video_start`, `video_progress`, `video_complete`, `outbound_click`.

Estados: `pending`, `filled`, `house`, `empty`, `disabled`, `error`, `hidden`, `not_applicable`. Dispositivos: `MOBILE`, `TABLET`, `DESKTOP`, `UNKNOWN`. Slots via `[data-audience-slot]`, com atributos `data-audience-placement`, `data-audience-state`, `data-audience-requested`, `data-audience-served`, `data-audience-delivery`, `data-audience-campaign`; elemento de criativo usa o marcador Ads existente `[data-ads-v1-viewable]` quando houver. Marcador sem área nunca é considerado render/visível.

Tabela `audience.events`: `page_view_id uuid`, `event_key text`, `event_kind text`, `received_at timestamptz`, `occurred_at timestamptz`, `visitor_id uuid`, `session_id uuid`, `site_host text`, `environment text`, `is_internal boolean`, `page_family text`, `page_path text`, `content_type text`, `content_id text`, `visitor_uf text`, `profile_uf text`, `context_uf text`, `market_uf text`, `geo_source text`, `source text`, `medium text`, `campaign text`, `creative text`, `referrer_host text`, `device_class text`, `slot_key text`, `placement_key text`, `slot_state text`, `delivery_id uuid NULL`, `campaign_id uuid NULL`, `active_ms integer`, `visible_ms integer`, `max_continuous_ms integer`, `view_ratio numeric`. PK `(page_view_id,event_key)`. Reenvio mantém contagem; durações podem subir monotonamente. SQL não toca no schema Ads.

Contrato SQL: `audience.ingest_events(p_context jsonb,p_client jsonb,p_events jsonb) RETURNS integer`. CFML só chama após validar assinatura e normalizar o lote. `p_context` e `p_client` usam camelCase do payload; eventos também. Business lê a tabela com filtros parametrizados. Migração aditiva idempotente, índices por período/ambiente/UF/família e visitor/session para retenção. Sem dependência em tabelas de domínio para aplicar/testar.

## Tarefa 1 — persistência, contrato e endpoint

Arquivos RoadRunners: `_codex/sql/2026-09-07_audience_inventory.sql`, `services/AudienceMeasurementService.cfc`, `includes/analytics/bootstrap.cfm`, `api/analytics/collect.cfm`, `_codex/scripts/test_audience_inventory_local.mjs` e testes SQL/CFML correspondentes.

- [x] Escrever fixtures SQL que demonstrem SP/contextoSC → marketSC; idempotência de evento, duração monotônica, exclusão de lote inválido e nenhuma mutação financeira.
- [x] Executar contra banco PostgreSQL local descartável e confirmar falha pela ausência do contrato.
- [x] Implementar esquema/ingestão validando os campos; reaplicar migração e confirmar invariantes.
- [x] Criar contexto a partir das variáveis da página/REQUEST e token HMAC expiráveis. Assinar contexto canônico e validar Host/Origin/Fetch-Site no endpoint; rejeitar lote grande, assinatura alterada e entrada malformada.
- [x] Bootstrap disponível sem consultar o banco; endpoint indisponível não interrompe página. Flag `APPLICATION.audienceMeasurementEnabled` tem default false até migração/validação; `APPLICATION.audienceMeasurementSecret` ou env `RR_AUDIENCE_MEASUREMENT_SECRET` necessário. Não gravar segredo em arquivos.
- [x] Retornar inventário de arquivos e comandos executados; não aplicar migração de produção.

## Tarefa 2 — navegador e instrumentação das posições

Arquivos RoadRunners: `assets/js/rr-audience.js`, `includes/estrutura/seo-web-tools-body-end.cfm`, `includes/eventos_ads.cfm`, `includes/ads_v1/banner_delivery.cfm`, `includes/estrutura/home_sidebar_promos.cfm`, `includes/ads_v1/viewability.cfm`, partials laterais estritamente necessárias, `_codex/tests/audience-tracker.test.js` e fixture de navegador.

- [x] Testar 999ms vs 1000ms, mudança de aba, imagem quebrada, slot vazio/oculto, reentrada e repetição de beacon com o código executável.
- [x] Implementar coletor sem dependências, identificadores pseudônimos, sessão de 30min, captura UTM/referrer normalizada, page-view único, tempo ativo e batches limitados/retries idempotentes. Respeitar opt-out (`rr-audience-opt-out`/GPC); falha de storage usa memória e não bloqueia navegação.
- [x] Inserir bootstrap uma vez no body-end compartilhado. Instrumentar lista de slots antes da seleção; vazio registra oportunidade, sem impressão inventada. Mutations assíncronas usam contexto pai.
- [x] Rastrear páginas/famílias e conteúdos, incluindo abertura de vídeo no modal; início/progresso somente a partir de eventos reais do player disponíveis. Não confundir modal aberto com reprodução.
- [x] Corrigir viewability Ads para aba ativa e imagem carregada, preservando regra de cobrança e observação DOM-ready existente.
- [x] Verificar fixture real em desktop/mobile, passando pela região comercial SC com origem SP.

## Tarefa 3 — painel Business

Arquivos Business: `portal/audiencia/index.cfm`, `portal/audiencia/home.cfm`, `portal/includes/audience_backend.cfm`, `includes/estrutura/sidenav.cfm` e testes focados das consultas.

- [x] Criar rota com `backend_login.cfm` e `require_admin.cfm`, seguindo estrutura de eventos-analytics.
- [x] Consultas parametrizadas por 7/30/90 dias, ambiente, UF, dimensão regional (comercial default, acesso, perfil, contexto), família e dispositivo. Detectar tabela ausente e mostrar estado de instalação pendente sem produzir zeros de audiência.
- [x] KPIs de páginas/sessões/visitantes estimados, oportunidades e exposições; tabelas por slot×família, região, conteúdo e aquisição. Distinguir preenchimento, render e visível. Exibir cobertura, primeira/última coleta, exclusões e critério de região. Dados desconhecidos explícitos.
- [x] Totais usam período completo; detalhamentos com limite declarado, sem afetar os totais. Não somar visitantes únicos entre grupos como total geral.
- [x] Adicionar navegação somente para admin, preservando diff anterior do sidenav.

## Tarefa 4 — integração, revisão e entrega

- [x] Executar testes Node/SQL e validar sintaxe/compilação CFML quando runtime disponível; caso indisponível, documentar e deixar gate de homologação explícito.
- [x] Revisão independente dos contratos, coleta/privacidade, precisão das métricas, permissão administrativa e preservação das alterações existentes.
- [x] Aplicar somente os arquivos da entrega aos checkouts locais após conferir diferenças; RoadRunners exige autorização do sandbox por ser diretório irmão.
- [x] Registrar ordem de publicação: migração, endpoint/serviço, frontend, Business, flag de coleta. Sem ativação de produção ou compra de mídia nesta etapa sem parâmetros operacionais.

## Progresso

O progresso abaixo registra as tarefas 1–4 na primeira entrega; a continuação está na tarefa 5 e no documento de fechamento indicado no início.

Implementação local e verificação das tarefas 1–4 concluídas. Aplicados 13 arquivos ao Business e 32 ao RoadRunners, conferidos byte a byte contra as versões revisadas. O registro de conclusão e dos gates operacionais fica em `_codex/docs/2026-09-07_audiencia_inventario_entrega.md`.

Evidência final: 37 assertivas de consultas Business; 27 assertivas da migração/ingestão reais com as sete consultas Business; 25 testes Node do tracker; contrato PostgreSQL com reaplicação da migração e isolamento financeiro; regressão Ads DOM-ready; Chrome real desktop/mobile, troca SP→SC, busca vazia e controlador real de filtros/paginação; compilação Adobe ColdFusion de 20 arquivos RoadRunners e 4 Business. As suítes finais de consultas, integração, tracker e navegador foram repetidas sobre os checkouts aplicados. A revisão independente não encontrou P1/P2 remanescentes nos pontos corrigidos.

Homologação HTTP/CFML integrada, produção, retenção/controles operacionais e mídia paga não foram executadas. Nenhum commit ou branch criado. Backups locais dos arquivos substituídos: `/private/tmp/rr-audience-before-PnTQsl` (temporários, não substituem versionamento).

## Tarefa 5 — painel final, preferências e controles de operação

- [x] Hierarquia resumo-primeiro no Business, gráficos MDB nativos sem empilhamento, filtros e tabelas completas; layout desktop/mobile e fallback sem JavaScript.
- [x] Sessões qualificadas por tempo ativo ou páginas de conteúdo distintas; reabertura do mesmo perfil/modal não cria uma segunda página distinta.
- [x] Recusa acessível, GPC prioritário, preferência entre abas e limpeza/expiração de identificadores; fila respeita HTTP 429 e Retry-After.
- [x] Configuração `APPLICATION.audienceMeasurement.hosts[hostname]` exata por ambiente, defaults desligados; bots/prefetch excluídos, limite por host/cliente com memória limitada.
- [x] Rotina privada de exclusão em lotes após 90 dias, com estado operacional opcional no painel; sem retenção agregada indefinida.
- [x] Encerrar a regressão integrada final e registrar a evidência no documento de fechamento: 73 verificações Adobe/HTTP, 51 consultas, 27 integração, 43 cliente/privacidade, 5 dashboard, Chrome desktop/mobile, contratos CFML e retenção/ACLs PostgreSQL.

### Gates de ativação — não confundir com implementação local

- [ ] Operador de DDL aplica inventário e retenção, valida permissões reais e provisiona a identidade/agenda horária do job.
- [ ] Responsável de infraestrutura configura proxy confiável nos hosts públicos e comprova IP de cliente correto, sem confiar em headers arbitrários.
- [ ] Publicar somente arquivos runtime e configurar todos os webroots coerentemente; homologar páginas completas e acesso administrativo real antes de habilitar o host.
- [ ] Após linha de base confiável, definir teto de verba e autorizar o piloto SC A/B. Nenhum gasto foi autorizado ou realizado.
