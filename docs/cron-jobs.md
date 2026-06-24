# Gerenciador de Cron Jobs

Atualizado em: 2026-06-22

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
