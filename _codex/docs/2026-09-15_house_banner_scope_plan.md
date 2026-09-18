# Banners HOUSE regionais — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Sem commits: preferência explícita do projeto prevalece.

**Goal:** Cadastro de banners legível com segmentação por páginas/UFs; publicar e restringir somente o banner Avaí Run a SC, conforme autorização do usuário.

**Architecture:** Metadata versionada de campanha e predicado SQL canônico, aplicado antes da escolha e novamente sob lock na entrega. Business salva pelo contrato versionado; consumidores RoadRunners carregam família e UF separadas da identidade física do slot.

**Tech Stack:** PostgreSQL 16, CFML Adobe/Lucee, JS sem dependências adicionais.

**Spec:** `2026-09-15_house_banner_scope_design.md`.

## Global Constraints

- Não executar commit, branch, push ou PR; trabalhar no checkout solicitado preservando mudanças alheias.
- HOUSE/BANNER sem cobrança; não mudar seleção/ranking EVENT/CPC, autenticação ou métricas históricas.
- Somente schema `ads` na migration incremental; não alterar `public`.
- `metadata.banner_scope_v1 = {"regions_mode":"ALL|SELECTED","regions":[],"pages_mode":"ALL|SELECTED","pages":[]}`. Ausente = legado; inválido = não entregar.
- Famílias: `home,search,state,event,athlete`; UFs: 27 siglas oficiais. `SELECTED` exige array não vazio, sem valores inválidos. `ALL` exige array vazio.
- Restrições de região/página se combinam por AND. UF/página desconhecida não corresponde a seleção específica.
- Não criar novos slots. Placement suportado `rr-sidebar-banner-300x250`.
- Publicação autorizada ao terminar e verificar; alteração de dados autorizada apenas para regionalizar Avaí Run em SC, deixando demais banners sem restrição geográfica.

### Task 1: Contratos SQL canônicos e testes

**Files:** RoadRunners `_codex/sql/2026-09-15_ads_house_banner_scope.sql`, `_codex/sql/2026-09-15_ads_house_banner_scope_contract_tests.sql`; Business `_codex/scripts/test_ads_house_banner_scope.mjs`.

**Interfaces:** `ads.banner_scope_matches(metadata jsonb, region text, page text) returns boolean`; `ads.save_house_banner_campaign_v2` recebe os 19 argumentos atuais mais `p_scope jsonb`; `ads.select_house_banner_candidate` recebe placement/time/device/country/region/page, retorna o mesmo contrato do seletor v2. `ads.serve_delivery` mantém assinatura e lê `request_context.banner_page` para validar escopo HOUSE/BANNER sob lock. Seleção v2 sem página não permite banners restritos a páginas.

- [x] Criar testes SQL reais de SC/SP/UF nula, páginas, legado e JSON inválido; RED: contrato ausente ou seleção regional incorreta.
- [x] Implementar validação e salvamento atômico: wrapper antigo preserva escopo na edição; novo rejeita SELECTED vazio. Bloquear edição sem admin/owner correto/DRAFT ou PAUSED conforme contrato existente.
- [x] Implementar filtragem antes de LIMIT/sorteio e revalidação de entrega; preservar retornos e permissões das funções atuais. Migration idempotente com preconditions; falhar se baseline do contrato for incompatível.
- [x] Testar com PostgreSQL isolado: candidatos incompatíveis não ocultam compatíveis, concorrência seleção/edição/entrega, APIs legadas, CPC inalterado e HOUSE sem débito. Executar migration duas vezes e SQL de contrato com rollback.
- [x] Registrar evidência RED/GREEN, arquivos, assinaturas exatas e revisar diff antes de consumidores.

### Task 2: Cadastro Business e consumidores RoadRunners

**Files Business:** `portal/includes/banner_management_backend.cfm`, `portal/banners/home.cfm`; novos helpers focados em `portal/includes/` e `assets/js/portal-banners.js`; testes `_codex/tests/banner-scope-form.cfm`, `_codex/tests/banner-scope-ui.test.js`.

**Files RoadRunners:** `services/AdsV1BannerDeliveryService.cfc`, `includes/ads_v1/banner_delivery.cfm`; helper `includes/ads_v1/banner_context.cfm`; consumidores `includes/eventos_ads.cfm`, `includes/estrutura/home_sidebar_promos.cfm`, `includes/estrutura/home_sidebar_mobile_banner.cfm`, `includes/estrutura/home_sidebar_async_slot.cfm`, `includes/estrutura/home_sidebar_mobile_banner_slot.cfm`, `includes/estrutura/feed_lateral.cfm`, `api/home_sidebar.cfm`, `api/home_mobile_banner.cfm`; testes contextuais offline.

**Interfaces:** Serviço `deliver(..., pageKey="")` adiciona argumento final; envia família para seleção e `request_context.banner_page`. `adsV1BannerPageKey` separado de `adsV1BannerRoute`; rota física e identidade de audiência permanecem estáveis. Business envia JSON de escopo normalizado pelo contrato v2.

- [x] RED em CFML/JS: salvar escopo específico, preservar edição, rejeitar seleção vazia e medir dimensões reais; consumidor envia família separada de sidebar, herda UF explícita antes de perfil/acesso e respeita fallback nacional.
- [x] Criar helper de formulário/validação, extrair metadados de upload decodificado em staging privado (10 MiB por imagem, máximo 40 megapixels), preservar GIF sem conversão. Sem buscar URL remota para medir.
- [x] Simplificar formulário em Conteúdo/Onde exibir/Período; default ALL, nome legível do slot, descrições de acessibilidade, preview, avançados peso/prioridade/aba, início agora e fim explícito. Sem campos manuais de canal/tamanho/dimensões/tipo de link.
- [x] Atualizar salvamento transacional e listagem, guard de contrato instalado, escapar valores, preservar erros e imagens antigas autorizadas.
- [x] Atualizar contextos dos consumidores e endpoints AJAX com allowlist; não confundir página de origem com template home interno. Seleção específica desconhecida falha fechada. Preservar contrato antigo de `route` usado em audiência.
- [x] GREEN: render CFML, JS, seleção/entrega, contratos existentes, layout desktop/mobile e revisão independente de escopo/qualidade.

### Task 3: Publicação, configuração Avaí e verificação real

**Files:** Business `_codex/scripts/deploy_house_banner_scope.py`, `_codex/docs/2026-09-15_house_banner_scope_release.json`, `_codex/docs/2026-09-15_house_banner_scope_deploy.md`.

- [x] Preflight read-only de servidor e banner atual, identificar ID exato HOUSE/BANNER Avaí e baseline de todos os alvos. Não tocar campanha EVENT/CPC.
- [x] Aplicar migration somente por caminho autorizado disponível; se precisar do operador, entregar SQL e informar bloqueio sem publicar consumidor incompleto.
- [x] Compilar candidato em Adobe e publicar apenas arquivos desta tarefa com backup/hash, consumidores RoadRunners antes do Business. SQL protetor fica instalado em rollback.
- [x] Pela operação administrativa autorizada, preservar imagens/destino/período/peso/estado do Avaí e ajustar somente região para SC; outros banners mantêm ALL e demais propriedades. Se ativo, pausar/editar/retomar explicitamente com proteção de versão.
- [x] Verificar hashes publicados, tela real, resumo do escopo salvo e elegibilidade SC versus outra UF/UF desconhecida sem criar cliques/beacons artificiais. Não prometer impressão física a partir de mera entrega SQL.
- [x] Registrar evidências, limitações e rollback; atualizar checklist. Sem commit/push.

## Rulings e progresso

- Ruling: executar no checkout atual, sem worktree/branch — instrução do projeto e preferência reiterada do usuário; preservar alterações concorrentes e comparar baseline antes de cada edição/publicação.
- Task 1: concluída; review independente aprovado; testes SQL regionais + leilão + financeiro PASS. Melhoria menor do teste de concorrência registrada no ledger (observar espera explícita do follower).
- Task 2: concluída, review aprovado após correção de dimensões de canvas GIF; CFML, Node6/6 e segurança76/76 PASS. Formulário real verificado em1280/820/390px e salvamento multipart de edição com imagens preservadas confirmado; novos uploads binários cobertos em testes automatizados.
- Task 3: concluída em16/09/2026. Migration aplicada pelo DataGrip com COMMIT confirmado e leitura independente dos contratos; publicação e verify retornaram published com backup/111guards. Avaí ACTIVE/SC, demais sem restrição e estados preservados. Banner Avaí visto na home SC; página SP desktop/mobile exibiu Mizuno. Matriz SQL confirmou SC=true, SP/UF desconhecida=false para Avaí. Evidências e limites no deploy handoff. Nenhum clique/beacon sintético, commit ou push.
