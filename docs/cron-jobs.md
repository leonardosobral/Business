# Gerenciador de Cron Jobs

Atualizado em: 2026-10-12

## Objetivo

O modulo `/administracao/cron-jobs/` transforma o `Business` em um orquestrador operacional para chamadas recorrentes de APIs da plataforma.

Ele permite acionar:

- APIs do proprio Business
- APIs do Road Runners
- APIs do projeto Conteudo
- endpoints externos controlados pela equipe

## Arquivos

- [administracao/cron-jobs/index.cfm](/Users/geraldoprotta/IdeaProjects/Business/administracao/cron-jobs/index.cfm)
- [administracao/cron-jobs/home.cfm](/Users/geraldoprotta/IdeaProjects/Business/administracao/cron-jobs/home.cfm)
- [administracao/cron-jobs/includes/backend.cfm](/Users/geraldoprotta/IdeaProjects/Business/administracao/cron-jobs/includes/backend.cfm)
- [administracao/cron-jobs/cron_jobs_schema.sql](/Users/geraldoprotta/IdeaProjects/Business/administracao/cron-jobs/cron_jobs_schema.sql)
- [cron-jobs/runner.cfm](/Users/geraldoprotta/IdeaProjects/Business/cron-jobs/runner.cfm)
- [includes/backend/cron_jobs_service.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/cron_jobs_service.cfm)

## Modelo de dados

Tabelas:

- `tb_cron_jobs`: cadastro do job, endpoint, agenda, metodo HTTP, autenticacao e ultimo estado.
- `tb_cron_job_runs`: historico de execucoes, status, HTTP status, duracao, erro e preview da resposta.
- `tb_cron_job_notification_recipients`: administradores que recebem notificacoes de erro e/ou novos itens por job.

O schema fica em:

- [cron_jobs_schema.sql](/Users/geraldoprotta/IdeaProjects/Business/administracao/cron-jobs/cron_jobs_schema.sql)

## Runner

Endpoint:

```text
https://business.roadrunners.run/cron-jobs/runner.cfm
```

Autenticacao:

- Header recomendado: `X-Business-Cron-Token: {token}`
- Alternativa: query string `?token={token}`

Configuracao:

- `RR_BUSINESS_CRON_RUNNER_TOKEN`, preferencial em variavel de ambiente
- ou `businessLocalConfig.cronRunnerToken` em `config/business.local.cfm`

Exemplo de cron do servidor:

```bash
* * * * * curl -fsS -H "X-Business-Cron-Token: TOKEN_FORTE" "https://business.roadrunners.run/cron-jobs/runner.cfm?limit=5" >/dev/null
```

Depois de configurar o token, acesse `/?resetApp` para recarregar `APPLICATION.cronJobs`.

### Migração de servidor — 12/10/2026

O disparador do runner passou a operar somente no crontab de `root` em
`172.233.2.76` (ColdFusion 2025). A entrada correspondente foi desativada em
`172.233.26.63` (ColdFusion 2023), preservando o serviço cron e os demais
agendamentos. Os três agendamentos legados do ColdFusion antigo não foram
alterados nem copiados.

O token estava correto no crontab e no arquivo privado, mas ausente de
`APPLICATION.cronJobs` em memória. A recarga pelo mecanismo `/?resetApp`,
aplicada no origin novo, resolveu o HTTP 503 `not_configured` do runner.
Nessa primeira etapa, não houve alteração dos arquivos de runtime nem troca
de credenciais.

Na verificação às 09:35 de Brasília, seis chamadas automáticas consecutivas
do runner retornaram HTTP 200. Todos os 19 jobs ativos tiveram execução
`scheduled`: dez concluíram com sucesso e nove falharam nas integrações.
Os cinco importadores de notícias retornaram `misconfigured` (HTTP 500);
os quatro jobs de CRM retornaram `invalid_signature` ou `service_unavailable`
(HTTP 503). Os três jobs inativos permaneceram inativos. O HTTP 200 do runner
não implica sucesso de cada job do lote.

Backups privados e verificados foram mantidos em cada servidor. Os caminhos,
hashes e resultados individuais estão no
[recibo da migração](../_codex/staging/cron-migration-20261012/cutover-receipt.json).
Para desfazer a troca de disparador, desative primeiro a entrada no novo e
restaure o `root.crontab.before` do backup no antigo com `crontab`; nunca
mantenha os dois disparadores ativos durante a recuperação.

### Recuperação dos importadores e CRM — 12/10/2026

O Business orquestra as chamadas; o projeto Conteúdo executa os importadores;
o Road Runners executa os workers de CRM. Após autorização para corrigir os
nove jobs, foram aplicados os seguintes ajustes no servidor novo:

- **Business / CRM:** o campo privado `notificationDispatchSecret` estava
  divergente da chave aceita pelo Road Runners. Foi alinhado à referência
  existente `cronSecrets.road_runners_handoff`, previamente validada com uma
  ação inexistente que não executa trabalho. A recarga de `APPLICATION`
  aplicou a configuração. Nenhuma credencial nova foi gerada e nenhum arquivo
  do Road Runners precisou ser alterado.
- **Conteúdo / autenticação:** a recarga por `/reset.cfm` recuperou o segredo
  existente `importerHandoffSecret`. Os cinco endpoints voltaram a rejeitar
  pedidos sem assinatura ou com assinatura inválida, aceitando a assinatura
  do Business.
- **Conteúdo / banco:** inicializações incondicionais com `CREATE TABLE IF
  NOT EXISTS` e `CREATE INDEX IF NOT EXISTS` eram bloqueadas pelo datasource
  do CF2025, mesmo com as estruturas já criadas. A consulta parametrizada
  `inc.db.relationExists()` passou a verificar tabelas e índices antes dessas
  instruções. Foram ajustados os importadores Corrida No Ar, Contra Relógio
  (também usado pelo Jornal da Corrida), CBAt e SixComm, além dos componentes
  de configuração e persistência SixComm. As restrições do servidor foram
  preservadas; não houve migração de schema.

A correção do carregamento de configuração também recuperou o refresh token
Gmail cifrado do SixComm que já estava no banco, sem nova autorização Google.
As próximas execuções dos jobs que ainda falhavam foram antecipadas com backup
e comparação do estado anterior; seus intervalos e parâmetros foram mantidos.

O código do Conteúdo foi preparado a partir de um snapshot dos sete arquivos
de produção, pois não havia checkout local desse projeto. O
[diff da publicação](../_codex/staging/cron-migration-20261012/news-source/patch.diff)
e o [recibo com hashes e backup](../_codex/staging/cron-migration-20261012/news-published.json)
registram o escopo exato. O backup privado do Business está identificado no
[recibo da correção CRM](../_codex/staging/cron-migration-20261012/crm-repair.json).
Para rollback, compare os hashes atuais com os publicados antes de restaurar
os arquivos correspondentes do backup. Após restaurar configuração privada,
recarregue a aplicação pelo mecanismo do projeto.

Durante a validação, a JVM atingiu seu limite de heap de 1 GB e a thread
`AJP Acceptor` encerrou com `OutOfMemoryError: Java heap space`. O Apache
ficou com suas filas HTTPS e AJP saturadas, embora o host de 24 GB ainda
tivesse memória livre. O heap em
`/opt/coldfusion2025/cfusion/bin/jvm.config` foi ajustado de
`-Xms256m -Xmx1024m` para `-Xms2048m -Xmx8192m`, preservando os demais
argumentos. Foi aplicado um reinício controlado pelo serviço existente
`cf2025`, que passou de inativo (JVM iniciada fora do serviço) para ativo.
O limite de 150 workers do Apache não foi alterado.

A JVM confirmou 8 GB de heap máximo após a partida. Às 10:08 de Brasília,
Road Runners, RunnerHub, Conteúdo e Business responderam HTTP 200 tanto no
origin quanto no domínio público. As filas de entrada zeraram e o Apache
apresentou 73 workers livres e dois ocupados. O backup da configuração e o
[recibo do reinício](../_codex/staging/cron-migration-20261012/heap-recovery.jsonl)
permitem auditar a alteração. Restaurar o limite antigo de 1 GB também
restauraria o risco de esgotamento observado; qualquer rollback de heap
exige nova reinicialização do ColdFusion.

#### Dimensionamento definitivo solicitado — 19.200 MiB

Às 11:08 de Brasília, após comparar os dois servidores, o máximo do novo
foi elevado novamente, de `-Xmx8192m` para **`-Xmx19200m`** (18,75 GiB),
igual ao valor confirmado na configuração e no processo do servidor antigo.
O heap inicial permaneceu em `-Xms2048m`. A configuração de 8 GiB acima
registra a primeira recuperação do incidente; o máximo vigente é 19.200 MiB.

Ambos os hosts têm cerca de 23,47 GiB de RAM visível ao Linux. Esse teto
deixa aproximadamente 4,72 GiB fora do heap para memória nativa da JVM,
Apache e sistema. Antes da alteração, o Apache consumia cerca de 137 MiB
de PSS, havia 18,77 GiB disponíveis no host novo e a swap estava sem uso.
Não foram encontrados limites de memória nos cgroups da JVM. O teto não
representa consumo imediato nem comprova capacidade sob carga de pico;
a avaliação seguiu o consumo observado e o dimensionamento já existente.

Foi alterado somente o `-Xmx` em
`/opt/coldfusion2025/cfusion/bin/jvm.config`, após conferir o hash de baseline.
Backup recuperável:
`/var/backups/cf2025-heap-19200-20261012T140824Z-ubrfd4df/jvm.config.before`.
O reinício por `systemctl stop/start cf2025` terminou com ambos os comandos
em código zero. O processo novo confirmou `MaxHeapSize=20132659200` bytes
e `InitialHeapSize=2147483648` bytes; os demais argumentos, inclusive o
coletor de lixo, e a configuração do Apache foram preservados.

Após a partida, os quatro sites responderam HTTP 200 no origin e nos
domínios públicos. O Apache apresentou 9 workers ocupados e 66 livres.
Evidências: [comparação de memória do novo](../_codex/staging/cron-migration-20261012/memory-capacity-new.json),
[comparação do antigo](../_codex/staging/cron-migration-20261012/memory-capacity-old.json),
[recibo do reinício](../_codex/staging/cron-migration-20261012/heap-19200-restart.jsonl),
[flags efetivas da JVM](../_codex/staging/cron-migration-20261012/vm-flags-after-19200.json),
[verificação dos sites](../_codex/staging/cron-migration-20261012/sites-after-19200.json)
e [memória após a alteração](../_codex/staging/cron-migration-20261012/memory-capacity-after-19200.json).
Para rollback deste segundo ajuste, conferir o hash vigente
`100138aafc4ece911e468478c6f2e8e952e7e14d31f34a00fac4dede03c2aa3b`,
restaurar o backup de 8 GiB acima preservando dono e permissões, reiniciar
o ColdFusion e repetir as verificações de disponibilidade.

#### Fuso America/Sao_Paulo e preservação da agenda — 12/10/2026

Após autorização do usuário, foi acrescentado somente
`-Duser.timezone=America/Sao_Paulo` à linha `java.args` do servidor novo.
O heap de `-Xms2048m -Xmx19200m`, classpath e todos os demais argumentos
foram preservados. O reinício pelo serviço `cf2025` terminou às 11:28:06
de Brasília, com parada e partida em código zero. A JVM em execução
confirmou o novo fuso; o sistema operacional permaneceu em UTC.

A validação detectou que o driver PostgreSQL também adota o fuso da JVM.
A conexão passou de UTC para `America/Sao_Paulo`, enquanto `next_run_at`,
`last_run_at` e `started_at` são `timestamp without time zone` e os horários
operacionais anteriores estavam gravados em UTC. Sem correção, o runner
considerava esses agendamentos três horas adiantados e não os executava.

Para preservar os instantes existentes sem migrar dados, foram publicados
quatro arquivos do Business às 11:35:05 de Brasília:

- `cron-jobs/runner.cfm`: seleção dos jobs devidos com `now() AT TIME ZONE 'UTC'`.
- `includes/backend/cron_jobs_service.cfm`: início, fim, última/próxima execução
  e reconciliação de execuções interrompidas usam o mesmo relógio UTC.
- `administracao/cron-jobs/includes/backend.cfm`: filtros de vencimento e
  estatísticas usam UTC; horários informados no formulário são convertidos
  do fuso local para UTC antes da gravação.
- `administracao/cron-jobs/home.cfm`: horários de agenda e histórico são
  convertidos de UTC para o fuso local na apresentação e edição.

Os quatro arquivos locais correspondiam ao baseline de produção antes da
alteração. A publicação conferiu hashes, preservou dono/permissões e criou
backup recuperável. Não houve atualização em massa do histórico, alteração
de schema, de intervalos ou de ativações. Os 19 jobs ativos e os três
inativos foram preservados, assim como o crontab do novo. O antigo continua
sem entrada ativa do runner Business.

Uma validação em transação somente de leitura confirmou a mesma seleção de
jobs devidos em UTC e São Paulo, preservação dos intervalos e durações,
detecção de execução expirada, conversão de datas na virada do dia e ida e
volta do horário de edição via parâmetro JDBC. Todos os testes passaram.
O painel autenticado abriu normalmente e apresentou os horários convertidos.
Os quatro sites responderam HTTP 200 no origin e nos domínios públicos.
Às 11:36, as filas HTTPS e AJP estavam zeradas, a swap sem uso e havia
71 workers livres no Apache. Novos lotes `scheduled` foram observados após
a publicação, sem disparos manuais de validação.

Às 11:40:04, havia 20 execuções automáticas de 14 jobs após a publicação e
nenhum job vencido naquele instante. Os intervalos e ativações conferiram
com o snapshot anterior. O agendador registrou 19 execuções `success` e
uma `http_error`: o job 19, de resumos de notícias, já apresentava falha do
provedor antes da alteração (créditos OpenAI esgotados). O job 23 retornou
HTTP 200, mas seu resultado interno continuou `deferred` com três falhas;
isso não resolve a pendência Pagar.me diagnosticada anteriormente. Os cinco
importadores de notícias tinham sucesso nas últimas execuções, anteriores
à troca do fuso; seu próximo intervalo horário não foi antecipado.

Backups:

- JVM: `/var/backups/cf2025-timezone-sao-paulo-20261012T142754Z-a9hhvd3x`.
- Runtime dos crons: `/var/backups/business-cron-timezone-20261012T143505Z-vv02txti`.

Evidências: [reinício](../_codex/staging/cron-migration-20261012/timezone-restart.jsonl),
[fuso efetivo](../_codex/staging/cron-migration-20261012/jvm-after-timezone.json),
[testes de horários](../_codex/staging/cron-migration-20261012/cron-timezone-validation.json),
[publicação](../_codex/staging/cron-migration-20261012/cron-timezone-published.json),
[verificação de runtime](../_codex/staging/cron-migration-20261012/timezone-runtime-verification.json),
[sites](../_codex/staging/cron-migration-20261012/sites-after-timezone-final.json)
e [execuções automáticas](../_codex/staging/cron-migration-20261012/jobs-after-timezone-final.json).

Para rollback do fuso, conferir o hash vigente de `jvm.config`
`8682709d037f67dd5398dba3cdaee776c083c3e3a1f182d9c293702f9e428617`,
restaurar o backup correspondente e reiniciar ColdFusion. O código dos crons
é compatível com ambos os fusos. Não restaurar o código anterior mantendo a
JVM em São Paulo: isso reintroduziria o atraso de três horas.

#### Resultado dos jobs após a primeira recuperação

Na verificação das 10:15 de Brasília, Corrida No Ar, CBAt, Jornal da Corrida
e SixComm tinham execuções `scheduled` com `success=true` e zero erros.
Notificações, e-mail e histórico do CRM também concluíram com sucesso.
Permaneceram duas dependências externas sem recuperação integral:

- **Contra Relógio:** o importador registrou timeout HTTP 408 ao ler o feed;
  uma consulta direta ao feed público retornou HTTP 429 tanto do servidor
  novo quanto do antigo. Não foram contornadas as limitações da origem.
- **Compras Todo Santo Dia:** a autenticação entre Business e Road Runners
  foi recuperada, mas os logs HTTP das consultas ao Pagar.me registraram 403.
  O worker retorna HTTP 200 mesmo com falhas internas ou histórico em `retry`;
  esse retorno não confirma conciliação de compras. Os arquivos privados de
  configuração Pagar.me nos dois servidores têm o mesmo hash. Já havia
  histórico em `retry` antes da intervenção. Após autorização específica do
  usuário, uma única consulta autenticada de leitura, limitada a um pedido
  (`GET /core/v5/orders?page=1&size=1`), confirmou **403 Forbidden** com a
  mensagem `Authorization has been denied for this request.` Foram registrados
  somente status e mensagem; nenhum pedido ou cobrança foi alterado.
  A [documentação de erros do Pagar.me](https://docs.pagar.me/reference/erros-1)
  associa 403 a bloqueio de IP/domínio. A hipótese principal é uma restrição na
  [IP Allowlist](https://docs.pagar.me/docs/ip-allowlist), que precisa ser
  conferida nas configurações de conta/merchant do provedor. A lista atual
  não foi inspecionada nem alterada. As rotas do novo servidor para o provedor
  usam IPv4 `172.233.2.76` e IPv6 `2600:3c0d::2000:faff:fef5:7c01`; a inspeção
  das rotas não determina qual família foi usada pela chamada ColdFusion.
  O [resultado da consulta autorizada](../_codex/staging/cron-migration-20261012/pagarme-authorized-diagnostic.json)
  preserva o status e a mensagem recebidos, sem dados de pedidos.

Os status e contadores, sem payloads de pedidos, estão no
[registro de validação](../_codex/staging/cron-migration-20261012/latest-integrations-5.json).
A [verificação de runtime](../_codex/staging/cron-migration-20261012/integrations-runtime-verification.json)
confirma os hashes dos sete arquivos publicados, o heap persistido, o serviço
`cf2025` ativo e habilitado e um único disparador Business no servidor novo.
O disparador antigo continuou desativado. Os jobs inativos e as alterações
locais de outras frentes foram preservados.

## Autenticacao dos jobs

O painel nao grava segredos reais no banco. Cada job guarda apenas `secret_ref`.

### Ticket Sports no RunnerHub

O importador automatizado usa um endpoint separado da pagina manual:

- endpoint: `POST https://runnerhub.run/api/ticketsports/jobs/import.cfm`
- autenticacao: `X-API-Key` (`auth_mode = api_key_header`)
- secret ref no Business: `runnerhub_ticketsports`
- token correspondente no RunnerHub: campo `jobToken` de `ticketsports.local.cfm`
- schema de estado no RunnerHub: `/api/ticketsports/jobs/ticketsports_job_schema.sql`
- cadastro inicial do evento 72611: `/administracao/cron-jobs/ticketsports_72611_job.sql`

O job nasce inativo e em `dryRun`. Depois de validar a resposta, altere `dryRun`
para `false`, execute uma pagina manualmente e somente entao ative o agendamento.
O cursor e salvo por evento, portanto o corpo do cron nao precisa informar a pagina.

### Vinculacao de eventos da Foco Radical

O vinculador automatizado roda no Business. O endpoint original no RunnerHub
permanece disponível temporariamente para compatibilidade, mas não é mais usado
pelo cron do Business:

- endpoint: `POST https://business.roadrunners.run/api/foco/jobs/match-events.cfm`
- autenticacao: Bearer
- secret ref no Business: `business_foco_eventos`
- token da Competition API: `focoApiToken` em `config/business.local.cfm`
- schema no Business: `/api/foco/jobs/foco_match_schema.sql`
- cadastro inicial: `/administracao/cron-jobs/foco_event_match_job.sql`

Sem acesso direto ao banco ou ao arquivo local, um administrador DEV pode
configurar os tokens em `/administracao/config-check/`, na seção
`Integração Foco Radical`. O formulário grava `business.local.cfm` com backup
automático e não exige reinício do ColdFusion. Se o token Bearer for deixado
vazio na primeira configuração, o Business reutiliza o token legado do
RunnerHub quando disponível ou gera um valor forte automaticamente.

O job nasce inativo, mas pronto para gravar candidatos de revisao
(`dryRun=false`) e com `autoLink=true`. Ele percorre toda a paginacao retornada
pela Foco, ignora candidatos abaixo de `minReviewScore` 60, manda candidatos de
60 ate 84,99 para revisao manual e vincula automaticamente candidato(s) com
score 85 ou superior, desde que data e UF sejam compativeis.
Candidatos de cidade diferente da cidade do evento Road Runners nao entram na
fila de revisao.

Na revisao manual feita em producao, candidatos acima de 80 pontos se mostraram
equivalentes ao mesmo evento, enquanto alguns candidatos pouco acima de 60 tambem
eram corretos, mas precisavam de avaliacao humana. Por isso, a configuracao
padrao revisa a faixa intermediaria e automatiza a faixa alta.

Os casos `review` e `conflict` sao tratados no painel administrativo
`/administracao/foco-revisao/`. A vinculacao manual valida novamente o candidato,
bloqueia candidatos abaixo de 60 pontos e impede reutilizacao da mesma competicao
Foco em outro evento Road Runners. Candidatos incorretos podem ser ignorados
individualmente, ficando fora da fila mesmo depois de novos processamentos do
job.

O vinculo principal agora fica em `tb_evento_foco_vinculos`, permitindo multiplas
galerias Foco para um unico evento Road Runners. O `tb_badges` continua sendo
atualizado com uma galeria principal por compatibilidade com telas antigas.
Quando uma galeria e vinculada manualmente, o caso permanece em revisao enquanto
existirem outros candidatos elegiveis ainda nao vinculados para o mesmo evento.

### Importacao de videos do YouTube

O importador tecnico roda no Business:

- endpoint: `POST https://business.roadrunners.run/api/youtube-import.cfm`
- autenticacao: HMAC-SHA256 (`auth_mode = hmac_sha256`)
- secret ref: `business_youtube`
- chave externa: `youtubeApiKey` em `config/business.local.cfm`
- schema de referencia: `/api/youtube/jobs/schema.sql`
- cadastro inicial: `/administracao/cron-jobs/youtube_import_job.sql`

Durante a migracao, `runnerhub_youtube` e aceito como fallback da chave do job. A API
original `https://runnerhub.run/api/youtube/` permanece disponivel, mas somente
um agendamento deve ficar ativo.

Se a chave Google local estiver ausente ou invalida, o importador reutiliza
automaticamente `RUNNERHUB_YOUTUBE_API_KEY` do ambiente legado ou de
`/var/www/runnerhub.run/jobs/runnerhub-jobs.env`. A origem efetivamente usada
aparece em `api_key_source` na resposta, sem expor a credencial.
As consultas também enviam `Referer: https://business.roadrunners.run/`, que já
está autorizado na restricao da chave legada.

O body inicial recomendado usa `dryRun=true` e `maxPages=1`. Depois de validar
o historico, altere `dryRun` para `false` e aumente o limite de paginas de forma
gradual. Os tokens podem ser configurados em `/administracao/config-check/`
sem reiniciar o ColdFusion.

Os segredos reais devem ficar em:

```cfm
businessLocalConfig = {
  "cronRunnerToken" = "TOKEN_FORTE",
  "cronSecrets" = {
    "road_runners_handoff" = "SEGREDO_COMPARTILHADO",
    "business_internal" = "SEGREDO_INTERNO"
  }
};
```

Modos suportados:

- `none`: sem autenticacao adicional
- `bearer`: envia `Authorization: Bearer {secret}`
- `api_key_header`: envia `X-API-Key: {secret}`
- `api_key_query`: adiciona `api_key={secret}` na URL
- `hmac_sha256`: envia `X-RR-Handoff-Timestamp` e `X-RR-Handoff-Signature`

O modo `hmac_sha256` usa a mesma logica ja usada na plataforma de notificacoes:

```text
signature = HMAC_SHA256(timestamp + "." + body, secret)
```

## Execucao e seguranca

- O runner executa apenas jobs ativos e vencidos (`next_run_at <= now()`).
- Cada job usa `pg_try_advisory_lock` para evitar execucao simultanea.
- Execucoes `running` que excedem `max_runtime_seconds` sao reconciliadas automaticamente como `timeout`.
- Cada execucao grava log antes e depois da chamada HTTP.
- O tempo de resposta, HTTP status e preview da resposta sao armazenados.
- `retry_limit` permite ate 3 novas tentativas.
- Falhas de uma API nao bloqueiam os demais jobs.

## Notificacoes web e push

Cada job possui uma matriz de administradores, com nome, e-mail e ID, na qual
podem ser marcadas duas preferências independentes:

- erro: dispara para `error`, `http_error`, `failed` e `timeout`;
- novos itens: dispara quando uma resposta JSON de sucesso possui contador positivo
  de novos registros.

A identificação de novos registros usa grupos alternativos em ordem de
precedência:

1. `new_items` ou `novos_itens`;
2. `created`, `criados`, `inserted` ou `inseridos`;
3. `imported` ou `importados`.

Somente o primeiro grupo presente na resposta é considerado. Os valores não são
somados entre grupos. Isso evita falsos positivos em APIs que retornam
`importados = created + updated`. Os campos `linked` e `vinculados` não são
considerados, pois podem representar vínculos já existentes.

As opcoes sao carregadas de `tb_usuarios.is_admin = true` e os IDs continuam
sendo validados no salvamento. Um administrador pode receber os dois tipos. A
interface também oferece busca por nome/e-mail e seleção/limpeza em massa para
cada tipo de notificação.

O clique usa destinos distintos:

- erro: destino fixo em
  `https://business.roadrunners.run/administracao/cron-jobs/`;
- novos itens: caminho interno configurado individualmente no job, sempre
  montado sob `https://business.roadrunners.run/`.

O cadastro aceita somente um caminho interno, como
`/administracao/foco-revisao/`; URLs externas não são aceitas.

O envio usa a API central de notificacoes configurada em
`APPLICATION.notificationDispatch`, com `sendPush = true`. Assim, a mesma
operacao materializa a notificacao web e solicita o push. Falhas no dispatch sao
acessorias: ficam isoladas e nao alteram o status da execucao do job.

## Endpoints ja mapeados como bons candidatos

Catalogo operacional completo:

- [Mapa de APIs para Cron Jobs](/Users/geraldoprotta/IdeaProjects/Business/docs/cron-jobs-api-map.md)

Business:

- `https://business.roadrunners.run/health/`
- `https://business.roadrunners.run/api/portal/runner-apps/`
- `https://business.roadrunners.run/api/portal/banners/?canal=roadrunners&local=home-side-banner&tamanho=sidebar-300x250&site_url=https://roadrunners.run`

Projeto Conteudo:

- `https://conteudo.roadrunners.run/admin/importer_corridanoar`
- `https://conteudo.roadrunners.run/admin/importer_contrarelogio`
- `https://conteudo.roadrunners.run/admin/importer_jornalcorrida`
- `https://conteudo.roadrunners.run/admin/importer_sixcomm_email`
- `https://conteudo.roadrunners.run/admin/importer_correriacampinas`

O job do Jornal da Corrida pode ser cadastrado ou atualizado de forma idempotente com `administracao/cron-jobs/jornalcorrida_import_job.sql`. Ele executa a cada 60 minutos, usa HMAC com `secret_ref = conteudo_internal`, atribui os autores importados a Roberta Palma (ID 28) e envia novos conteúdos para a fila de curadoria.

O job do SixComm fica em `administracao/cron-jobs/sixcomm_import_job.sql`. Ele consulta a caixa a cada 15 minutos, usa a mesma referência HMAC e envia os releases autenticados para a curadoria do canal SixComm. Configure e teste a senha de aplicativo na tela do News antes de aplicar esse SQL.

Ao publicar conteúdos importados pela curadoria, o Business prioriza a data canônica registrada em `news.tb_content_imports.detail_json` e a reaplica em `news.tb_content.published_at`, inclusive para corrigir itens importados antes deste ajuste. A data atual só é aplicada a conteúdos sem metadados de importação e sem data de publicação.

Road Runners:

- Endpoints Road Runners que aceitam handoff devem usar `auth_mode = hmac_sha256` e `secret_ref = road_runners_handoff`.
- Health checks publicos podem usar `auth_mode = none`.
- A fila Strava usa `POST /api/integrations/strava/batch-refresh.cfm`; consulte `docs/strava-batch-cron.md`.

## Operacao recomendada

1. Aplicar o SQL do schema.
2. Configurar `cronRunnerToken` e `cronSecrets` no ambiente.
3. Acessar `/?resetApp`.
4. Criar jobs no painel `/administracao/cron-jobs/`.
5. Configurar cron real do servidor para chamar `/cron-jobs/runner.cfm` a cada minuto.
6. Acompanhar falhas pelo historico do proprio painel.
