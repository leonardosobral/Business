# Audiência — continuação de implantação

## Estado atual — Business e runtime RoadRunners publicados; coleta ativa

Os **15 arquivos Business foram publicados** em `https://business.roadrunners.run/portal/audiencia/` após autorização explícita. Em 07/09/2026 às 11:35:30 UTC, a verificação independente confirmou os 15 hashes/modos/proprietários, os três hashes de autenticação inalterados, as 15 entradas `applied` do journal e o backup íntegro do menu anterior. O guard retornou403 na origem antes de qualquer SQL ser publicado.

Backup/pacote privado: `/var/backups/business-audience-20260907.FAjmqn` no servidor `ssh.runnerhub.run`, diretório0700. Arquivo substituído: somente `includes/estrutura/sidenav.cfm`; os outros14 eram novos. Nenhuma exclusão, restart/reload, alteração de login, migração ou ativação de coleta foi realizada. Apache manteve PID1780160 e ColdFusion PID1780425, ambos iniciados em01/09; configuração Apache `Syntax OK` após publicação.

A revisão do executor concluiu os ajustes de backup, journal, recuperação, permissões e `curl --disable` como primeira opção para ignorar configurações externas. Os11 testes passaram; revisão sem P1/P2 abertos. SHA revisado `7b02ac5a9b4c6cb94d4f014427bc1dc6aa8fe43083f74af8dab510280f0525ef`; a cópia operacional altera somente `APPLY_REVIEW_APPROVED=False` para `True`, com SHA `4907fec64a4b7fb6ef47ff75c4d2311b37ced3e360daf36e31c176e90685c67e`. Manifesto original preservado (`f247b76f01f47556ba7dc6bc6b4a213de1272d046aa4af81aeb5a7b7bb8616ae`); seu rótulo anterior é histórico, não o estado atual.

Atualização posterior de banco, informada pelo operador via conexão confiável do DataGrip: base `runnerhub` em PostgreSQL 17.6, duas tabelas e duas funções de audiência presentes; estado de retenção `retention_days=90`, `last_status=never`, `last_run_at=NULL`, `last_success_at=NULL`, `has_more=false`. Os grants de runtime de `runner` conferem com o contrato. `runner_dba` foi confirmado como `rolsuper=true`, o que explica suas permissões efetivas; o usuário proibiu explicitamente alterar esse papel. As consultas de audiência usam o datasource explícito `runnerhub`, mapeado a `runner`; datasource global e autenticação Business foram preservados. O agente não executou DDL. O problema histórico de identidade SSH do banco não bloqueia o caminho SQL executado pelo operador no DataGrip e não foi contornado nem corrigido nesta etapa.

Após o inventário, [backup](2026-09-07_audiencia_backup_roadrunners.md), [reconciliação](2026-09-07_audiencia_reconciliacao_roadrunners.md) e autorização explícita **“publique”**, os30 arquivos do [candidato RoadRunners](2026-09-07_audience_roadrunners_publication_candidate.json) foram publicados na raiz `/var/www/roadrunners.com.br`:18 substituições e12 novos. `includes/ads_v1/viewability.cfm` permaneceu fora do pacote e inalterado, preservando o beacon Ads independente existente. Bundle/backup privado: `/var/backups/roadrunners-audience-publish-20260907.IG8snn`.

A verificação independente pós-publicação confirmou os30 hashes e metadados, os18 backups, os seis guards e a ausência dos três overrides locais. O coletor retornou `503` com corpo `disabled` antes e depois; as páginas exercitadas não carregaram o tracker. Foram104/104 verificações HTTP PASS em cinco rotas públicas, suas chamadas diretas à origem e três assets. Apache PID1780160 e ColdFusion PID1780425 permaneceram os mesmos, sem restart. Evidência por arquivo: `/private/tmp/rr-audience-publish.j1Jkad/files-postpublish.json`, SHA-256 `366d3761f355cb7d6bcc731024f6fa2a28e87a77cf51b8b61c513881a1c8bce5`; evidência HTTP: `/private/tmp/rr-audience-publish.j1Jkad/http-postpublish.json`, SHA-256 `5b84f1addee11ac7313990bc07e81ac354482ce30cb7ae2bd3db0f2e363c74d2`. Consulte também o [registro específico da publicação RoadRunners](2026-09-07_audiencia_publicacao_roadrunners.md) e o [recibo correspondente](2026-09-07_audience_roadrunners_publication_receipt.json).

Em 08/09/2026 às23:53:19.083536 UTC (20:53 em Brasília), a coleta foi ativada por override local em `/var/www/roadrunners.com.br/config/audience.local.cfm`, modo0600 e UID/GID65534. O estado anterior `503 disabled` permanece como evidência da publicação de 07/09, não como estado corrente. A ativação tem backup privado em `/var/backups/roadrunners-audience-activation-20260908.az0scvhm`; consulte o [recibo definitivo](2026-09-08_audience_activation_receipt.json). O usuário autorizou especificamente a recarga compartilhada de settings e decidiu que a retenção não bloquearia a coleta. A role de runtime e a identidade `rr_audience_retention_job` já existem e foram validadas; somente senha, conexão privada e agenda de retenção serão providenciadas pelo DBA.

Antes do deploy RoadRunners, a revalidação autenticada do Business após a instalação SQL reconheceu a base de audiência e mostrou **“Aguardando os primeiros eventos”**; a retenção apareceu instalada, sem execução. O recorte SC,30 dias, contexto comercial passou em desktop1460px e mobile390px, sem novo login Google. Depois do deploy, a mesma sessão autenticada persistiu no RoadRunners em desktop1460px: controle de privacidade presente e tracker ausente. Mobile RoadRunners pós-deploy não foi validado e não é alegado. Esses resultados são o baseline anterior à ativação.

Às20:56 de 08/09, o painel Business, com acessos internos desmarcados, confirmou ingestão:2 visitantes,2 páginas/aberturas,2 sessões,7 posições,2 posições visíveis e2 anúncios visíveis. Uma das visitas é anônima e foi produzida pela validação; os números não devem ser apresentados como tráfego orgânico. Uma leitura administrativa anterior, com internos incluídos, havia mostrado1 visita e5 posições e não deve ser comparada diretamente com esse recorte.

O proxy confiável já estava aplicado e foi verificado em08/09/2026 às16:34:43 UTC; consulte o [recibo correspondente](2026-09-08_audience_proxy_receipt.json). Permanecem pendentes somente a senha, a conexão privada e a agenda/prova do job de retenção pelo DBA, além da homologação operacional completa. A retenção ainda não teve execução comprovada, mas não bloqueia a coleta ativa. A ativação não executou DDL nem alterou grants, `runner_dba`, autenticação, beta/dev ou o beacon Ads independente. As seções seguintes preservam o histórico e os limites de cada etapa; estados antigos “não publicado”, “coleta desligada” e “aguardando eventos” continuam apenas como registro cronológico, não como situação atual.

HTTP público pós-publicação, sem login/cookies nem seguir redirects: raiz200; painel302 para landing raiz; includes backend/home403; `.htaccess` e oitoSQLs403; CSS/JS200. [Recibo de publicação](2026-09-07_audience_business_publication_receipt.json). Relatório HTTP em `/private/tmp/rr-audience-rollout.Ts2glm/business-postpublish-http.md`, SHA `8769cc02e4f24084bbadf5fece6953fceb7f21c3f43fe0b01f4056806110613c`.

Na validação histórica anterior à instalação, após nova autorização explícita para o login normal do Business, uma conta Google preexistente abriu o painel publicado sem alterar credenciais, permissões ou código de autenticação. Menu **“Audiência e inventário”**, rota e filtros foram exibidos. O estado permaneceu **“Medição aguardando instalação”** em todos os recortes, que era o comportamento esperado sem schema/coleta naquele momento; nenhum número, gráfico ou dado real de audiência foi validado ou inferido.

Filtros exercitados e persistidos na URL/interface: 90 dias + região do acesso + SP + notícia detalhe + mobile + produção; atalho do piloto SC (30 dias, SC, mercado); avançados com DEV e acessos internos; e limpeza para os defaults 7 dias, mercado, todas as UFs/famílias/dispositivos, produção e internos desligados. Desktop em1571px manteve `documentWidth=1571`; mobile390×844, após reload, manteve `documentWidth=390`, sem corte horizontal. Reduzir apenas o viewport desktop causou sobreposição breve do menu; o layout mobile ficou correto após reload, portanto não se afirma que o resize dinâmico de todo o shell passou. A sessão permaneceu autenticada durante navegações, submits e reloads desta validação; continuidade através do deploy não foi testada nem alegada.

Recuperação: o menu anterior está preservado em `before/includes/estrutura/sidenav.cfm` dentro do backup privado, com hash/mode/uid/gid verificados. O pacote original e o manifesto permanecem disponíveis. Não reexecutar `--apply`: o journal existente interrompe uma segunda execução para reconciliação dos15alvos. Qualquer rollback deve revisar os hashes atuais, recuperar o menu de forma atômica e manter o guard enquanto houver SQLs no diretório; não remover o guard primeiro nem sobrescrever alterações concorrentes. Nenhum rollback foi necessário.

## Autorização e limites

### Continuação autorizada — 07/09/2026

O usuário respondeu **“prossiga”** à pergunta explícita sobre enviar/publicar os 15 arquivos Business (CFML e SQLs internos protegidos) em `ssh.runnerhub.run:/var/www/business.roadrunners.run`, com backup e sem login, migrações ou coleta. A autorização cobre esse pacote/destino de produção; não autoriza o harness de upload de desenvolvimento anteriormente negado nem contornar a mudança de chave SSH do banco.

Plano desta continuação: concluir/revisar o executor local; revalidar os 15 baselines e os três arquivos de autenticação; criar pacote/backup privado; provar HTTP403 do guard antes dos oito SQLs; publicar dependências, rota e menu; conferir hashes, HTTP e tela no navegador; registrar limitações. RoadRunners, proxy, banco e jobs não serão alterados. O checkout `main` e seus diffs preexistentes são preservados, conforme a instrução do projeto de não criar branches/commits sem pedido; o executor e fixtures ficam isolados em diretório temporário.

Verificação inicial desta continuação: 5 testes do painel e 51 assertivas SQL passaram; guard Apache local retornou403 preservando leitura em filesystem. Os testes PostgreSQL/Apache usaram elevação apenas para recursos locais (memória compartilhada/loopback), sem transferência externa. A primeira rodada do executor encontrou falhas nas fixtures com caminhos temporários macOS; correção/revisão em andamento antes de permitir a publicação.

Preflight remoto atualizado registrado em `/private/tmp/rr-audience-rollout.Ts2glm/business-preflight-authorized.md`: 14 alvos ausentes, menu e três hashes de autenticação correspondentes, Apache válido/ativo e ColdFusion ativo. Python remoto3.10.12; `/var/backups` e webroot no mesmo filesystem. Probe de origem com TLS validado (`curl --noproxy '*' --resolve business.roadrunners.run:443:127.0.0.1`) retornou404 antes do guard, sem desativar verificação de certificado.

Histórico da primeira tentativa de validação autenticada: uma nova aba abriu somente a página pública do Business. O clique em “Entrar” foi negado pelo reviewer por exigir autorização específica para autenticação; não foi repetido nem contornado por outra aba, cookie ou método. Posteriormente, o usuário respondeu **“prossiga”** à pergunta explícita sobre usar o login normal, satisfazendo esse gate. A validação descrita no estado atual foi então executada pelo fluxo Google já existente, sem registrar dados pessoais, cookies, tokens ou URL de autenticação.

O usuário pediu “prossiga” após a entrega local informar explicitamente os gates de publicação, migração, retenção e proxy. Esta continuação avança na implantação desse pacote. Não inclui mudança de autenticação, compra de mídia, commits/branches/push, exposição de fixtures ou uso de credenciais fora do fluxo operacional autorizado.

Mantidos os checkouts existentes e seus diffs; não foi criada uma branch. Preparação operacional isolada em `/private/tmp/rr-audience-rollout.Ts2glm`. O manifesto SHA-256 da entrega anterior continua sendo a referência de conteúdo até que uma alteração revisada exija nova versão.

## Etapas

- [x] Confirmar docroots, hashes remotos e baseline HTTP; parar nos arquivos com diferenças concorrentes não explicadas.
- [x] Registrar a confirmação do operador via DataGrip: base `runnerhub`, PostgreSQL 17.6, duas tabelas e duas funções presentes, grants de `runner` conferidos e retenção ainda `never`. Nenhum DDL foi executado pelo agente.
- [x] Publicar o Business com backup privado e substituição verificada, sem alterar código de autenticação; validar a UI autenticada no estado “aguardando instalação”. A sessão persistiu durante a validação pré-instalação, mas continuidade através do deploy não foi exercitada.
- [x] Inventariar os 31 alvos RoadRunners de produção e concluir o [backup privado dos 19 existentes](2026-09-07_audiencia_backup_roadrunners.md), com conteúdo/metadados e comparação independente verificados.
- [x] Reconciliar as diferenças dos 14 arquivos RoadRunners e preparar candidato privado de30 arquivos:18 substituições e12 novos; preservar `includes/ads_v1/viewability.cfm` e o beacon Ads independente.
- [x] Publicar os30 arquivos RoadRunners com coleta efetivamente desligada; conferir hashes/metadados,18 backups, seis guards, três overrides ausentes,104/104 checks HTTP e processos sem restart.
- [x] Revalidar o Business autenticado após a instalação dos objetos: “Aguardando os primeiros eventos”, retenção instalada sem execução, recorte SC/30 dias/comercial em desktop e mobile.
- [x] Ativar a coleta em08/09/2026 com override local protegido e backup; confirmar ingestão no Business sem incluir acessos internos, preservando a visita anônima de validação como tal.
- [x] Aplicar e verificar o proxy confiável no escopo necessário, sem alterar outros vhosts.
- [ ] Provisionar senha e conexão privada para a identidade `rr_audience_retention_job` já validada e instalar/provar a agenda de retenção; comprovar execução e estado de saúde. Preservar `runner_dba` conforme proibição explícita do usuário.
- [ ] Homologar os runtimes completos, incluindo RoadRunners mobile pós-deploy e o estado operacional da coleta ativa.

Os registros abaixo são históricos. Em particular, o bloqueio SSH do banco relatado na primeira tentativa não substitui a evidência posterior do operador pelo DataGrip nem exige alterar a identidade SSH para continuar por esse caminho autorizado.

## Preflight inicial

O servidor SSH web responde e possui Apache/ColdFusion, mas não foi encontrado `psql`, Node, instalação ou socket local de PostgreSQL, nem libpq service padrão para root/sistema. Isso não comprova ausência de acesso de DDL em outro ambiente: o próximo passo é conferir apenas os metadados dos datasources e o mecanismo operacional existente, sem imprimir senhas.

Revisões paralelas somente leitura conferem (1) Apache/proxy e (2) correspondência dos arquivos runtime. A implantação de painel pode permanecer útil e segura sem coleta: ausência de schema deve aparecer como instalação pendente, jamais como zero de audiência comprovado.

## Bloqueio de identidade do servidor de banco

Metadados filtrados de `neo-datasource.xml` confirmaram os datasources `runnerhub` (papel `runner`) e `runner_dba` (papel homônimo), ambos para a base `runnerhub` em `db.runnerhub.run:5432`. Nenhuma senha ou URL de conexão foi exibida.

A tentativa SSH somente leitura, com `StrictHostKeyChecking=yes`, foi interrompida por **REMOTE HOST IDENTIFICATION HAS CHANGED** antes da autenticação. A chave ED25519 apresentada tem fingerprint `SHA256:mAUIxEox3HC1wLKRIqfzuVzVvudv3sAWN+sIlDCUehA`. Não foi aceita/substituída a chave registrada, não foi desativada a verificação e não se tentou contornar o bloqueio por outro nome/IP ou por DDL através da aplicação.

O responsável precisa validar o fingerprint por um canal administrativo independente. Os runbooks anteriores de Ads indicam migrações via DataGrip conectado como DBA, não um executor DDL genérico no servidor web. Até resolver identidade/acesso operacional, migrações, provisionamento do job e ativação de coleta permanecem bloqueados. Não há razão para alterar o Apache compartilhado antecipadamente enquanto esse gate está aberto.

## Preflight do Business e proteção de SQL

Os 14 arquivos do manifesto inicial foram conferidos: 13 estão ausentes no servidor e `includes/estrutura/sidenav.cfm` existe com hash `77fee4b002de40ce24dd6d4168213c97e807aaed3117df4ca08c73073a9581a4`, modo `0644`, UID:GID `501:50`. A comparação integral com o candidato local contém somente as seis linhas que adicionam o item “Audiência e inventário”; essa diferença foi reconciliada, sem mudanças alheias a sobrescrever.

O vhost e diretórios públicos do Business não têm bloqueio de arquivos `.sql`. É necessário adicionar `portal/audiencia/queries/.htaccess` antes dos oito templates SQL, mantendo a leitura pelo CFML. Isso amplia o pacote Business para 15 arquivos, não altera regras globais do Apache nem autenticação. O executor one-off de publicação permanece um rascunho local, não aprovado para uso: a revisão identificou ajustes necessários no journal/recuperação, preservação de metadados do backup, validação dos três baselines de autenticação e permissões dos novos diretórios. Sua preparação não equivale a publicação. Antes de qualquer uso futuro, concluir esses ajustes, obter revisão e autorização, revalidar hashes remotos e preservar a ordem guard→dependências→rota→menu. Nenhuma execução de publicação foi feita.

### Bloqueio explícito de autorização de envio

O reviewer de permissões rejeitou uma nova execução do harness nativo, porque ela envia código Business e templates SQL privados ao SSH de desenvolvimento e exige autorização explícita do usuário para esse envio/destino. Não houve repetição ou contorno após a rejeição. A prova do bloqueio SQL foi concluída em Apache local com conteúdo sintético, sem transferência externa: RED HTTP200 antes do guard, GREEN HTTP403 após o guard, com leitura pelo filesystem preservada. Isso não substitui homologação do novo guard em ambiente publicado.

Também não será usado o deploy de produção como caminho alternativo para o envio rejeitado. É necessária autorização expressa para o pacote/destino antes de enviar/publicar os 15 arquivos no servidor `ssh.runnerhub.run`, raiz `/var/www/business.roadrunners.run`, usado por `business.roadrunners.run`. A coleta continua desligada e os SQLs não podem ficar disponíveis para download. Os templates serão enviados apenas como dependências privadas de leitura do painel; nenhum SQL será executado como migração por esse deploy.

### Baselines preservados

Apache `Syntax OK`; processo Java ColdFusion PID `1780425`, em execução desde 01/09/2026. Nenhum reload/restart efetuado. Hashes remotos de autenticação registrados para comparação antes/depois:

- `Application.cfc`: `7320a875a9055dda24cd709fb2edc65aa37f96e1b41df0e363eb956c14a01ec8`.
- `includes/backend/backend_login.cfm`: `514b8246fa95340c511389b1deaa18431c0537239ef5cd82c7892a574dfe0add`.
- `includes/backend/require_admin.cfm`: `d7212311a34ad583b6b7311984f53b9dfe6c065f8bf7a2060cbbae5dfed655e0`.

Esses arquivos não integram o pacote de publicação.

## Verificação local concluída nesta continuação

- Dashboard: 5 testes Node PASS; consultas reais: 51 assertivas PASS em PostgreSQL local descartável.
- Guard SQL: `_codex/scripts/test_audience_sql_http_guard.mjs` PASS no Apache2.4.66 local, confirmado também pelo root após integração. Somente conteúdo sintético em loopback; temporário removido e processo de teste encerrado.
- Revisão independente aprovou os quatro arquivos do guard sem P1/P2: `.htaccess`, runner local, calibração/assertivas do native e lista runtime. `git diff --check` passou.
- A primeira tentativa nativa teve 75 checks, mas o 403 era incidental por modo0640 dos arquivos; **não** é evidência de proteção HTTP. A fixture foi fechada em `/var/tmp/rr-audience-http-21hVks-closed`. O runner agora usa0644 apenas nos SQLs/guard da fixture protegida para evitar esse falso positivo; a nova rodada nativa permanece pendente de autorização.

Pacote específico desta etapa: [15 arquivos, hashes e baselines](2026-09-07_audience_business_publication_candidate.json). Estado explícito: preparado, aguardando autorização, **não publicado**. Guard SHA-256: `ee3276aea9a68b0453d91bb5456d8947b2dd6780a18a344af9c0b370933163a1`. O manifesto anterior de 49 artefatos permanece preservado como registro histórico.

Relatório detalhado/patch focal: `/private/tmp/rr-audience-rollout.Ts2glm/task-sql-guard-report.md` e `task-sql-guard-focused.patch`. O último tem SHA-256 `5fc1dffb9b8ca53eb5c31220385332f9264375fa5337b3f814d10a0187edb29c`.

Checkpoint do executor: `/private/tmp/rr-audience-rollout.Ts2glm/publish-review-fixes.md`. Helpers/testes de revisão preparados, mas a versão final não foi revalidada nem aprovada. `--apply` está explicitamente desabilitado; uma invocação local confirmou o bloqueio antes de acesso ao destino. Esse rascunho não integra os 15 arquivos runtime nem deve ser usado para publicar até concluir os gates descritos.

## Resultado das revisões paralelas

Preflight completo de 45 arquivos em `/private/tmp/rr-audience-rollout.Ts2glm/runtime-preflight.json`. HTTP Business sem cookies: `/` retornou 200; painel, includes novos e oito templates SQL retornaram 404 por ausência. Isso não é validação do painel publicado. RoadRunners: 12 arquivos ausentes, 5 iguais ao HEAD local e 14 diferentes; a futura publicação exige reconciliar esses diffs, não copiar o checkout inteiro.

No proxy, apenas a API já tem `RemoteIPHeader CF-Connecting-IP` e 22 prefixos Cloudflare trusted. Os quatro hosts de audiência usam Cloudflare→Apache TLS→mod_jk/AJP→ColdFusion, sem normalização equivalente. O escopo técnico proposto, ainda não executado, é incluir o mesmo bloco somente nos quatro vhosts TLS (principal, www, beta, dev), validar configuração, reload sem restart e testes de origem legítima/header falsificado. Não mudar API, HTTP redirects, configuração global, conector ou firewall nessa etapa.

Referências oficiais conferidas na revisão: [Apache mod_remoteip](https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html), [CF-Connecting-IP](https://developers.cloudflare.com/fundamentals/reference/http-headers/#cf-connecting-ip), listas [IPv4](https://www.cloudflare.com/ips-v4/) e [IPv6](https://www.cloudflare.com/ips-v6/). Os prefixos devem ser revalidados no momento de uma alteração futura; nenhum bloco foi aplicado antecipadamente.
