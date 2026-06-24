# Fila Strava por Cron

Atualizado em: 2026-06-23

## Objetivo

Substituir o ciclo em navegador de `/bi/desafio/fila.cfm` por uma chamada tecnica do Business para o Road Runners.

Endpoint:

```text
POST https://roadrunners.run/api/integrations/strava/batch-refresh.cfm
```

## Seguranca

- Autenticacao `hmac_sha256` com `X-RR-Handoff-Timestamp` e `X-RR-Handoff-Signature`.
- Segredo compartilhado referenciado no Business por `road_runners_handoff`.
- O Road Runners exige `RR_HANDOFF_SECRET` explicitamente configurado.
- Trava PostgreSQL global impede lotes simultaneos.
- Trava por usuario impede atualizacao concorrente dentro do lote.
- O endpoint aceita somente `POST` e limita tamanho do lote e janela de consulta.

## Credenciais Strava

Use preferencialmente no Road Runners:

```text
RR_STRAVA_CLIENT_ID
RR_STRAVA_CLIENT_SECRET
```

Alternativamente, crie `/config/strava.local.cfm` a partir de `config/strava.local.example.cfm`:

```cfm
<cfscript>
localStravaConfig = {
    "clientId" = "CLIENT_ID",
    "clientSecret" = "CLIENT_SECRET",
    "handoffSecret" = "MESMO_VALOR_DE_road_runners_handoff_NO_BUSINESS"
};
</cfscript>
```

O endpoint le esse arquivo em cada chamada, sem exigir reinicio do ColdFusion.

O `handoffSecret` permite que o endpoint batch valide o HMAC diretamente do arquivo local, sem reiniciar o ColdFusion. O fluxo legado `/api/strava/atualizar/` permanece inalterado durante a homologacao.

## Payload

```json
{
  "limit": 5,
  "lookbackDays": 2,
  "desafios": ["todosantodia", "desafiofoco"],
  "dryRun": false
}
```

Limites internos:

- `limit`: entre 1 e 10 atletas.
- `lookbackDays`: entre 1 e 7 dias.
- `desafios`: somente `todosantodia` e `desafiofoco`.
- ate tres paginas de 100 atividades por atleta.

## Processamento

1. Localiza atletas com atividades `processed = false` dentro da janela.
2. Renova o token apenas quando faltar menos de cinco minutos para expirar.
3. Consulta atividades recentes no Strava.
4. Consulta individualmente IDs pendentes que nao apareceram na listagem recente.
5. Atualiza `tb_strava_activities` com `ON CONFLICT`.
6. Encerra como ignorados webhooks de exclusao e atividades definitivamente inexistentes (`404/410`).
7. Confirma somente IDs resolvidos com seguranca e mantem falhas transitorias pendentes.
8. Retorna JSON com candidatos, processados, atualizados, ignorados e erros.

## Cadastro

Execute primeiro no banco compartilhado o schema de controle de tentativas do Road Runners:

```text
/api/integrations/strava/strava_batch_schema.sql
```

Depois execute no Business:

```text
/administracao/cron-jobs/strava_batch_job.sql
```

O script e idempotente e cadastra o job inicialmente inativo, com intervalo de cinco minutos, timeout de 120 segundos e sem repeticao HTTP automatica.

Falhas por atleta usam backoff exponencial de 2 a 60 minutos em `tb_strava_batch_attempts`, evitando que credenciais invalidas bloqueiem os demais atletas.

Teste primeiro alterando temporariamente o body para `"dryRun": true` e executando manualmente. Depois do retorno `dry_run`, restaure `false` e ative o job.
