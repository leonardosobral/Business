# Gerenciador de Cron Jobs

Atualizado em: 2026-07-25

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
- `https://conteudo.roadrunners.run/admin/importer_correriacampinas`

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
