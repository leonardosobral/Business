# Importador YouTube no Business

O endpoint tecnico importa videos dos canais e playlists cadastrados em
`tb_youtube_canais`, atualiza `tb_media` e, quando configurado, cria o vinculo
em `tb_paginas_feed`.

## Endpoint

```http
POST https://business.roadrunners.run/api/youtube-import.cfm
X-RR-Handoff-Timestamp: {timestamp}
X-RR-Handoff-Signature: HMAC-SHA256(timestamp + "." + corpo)
Content-Type: application/json
```

```json
{
  "channel": "",
  "maxResults": 10,
  "maxPages": 1,
  "dryRun": true
}
```

- `channel`: codigo do canal; vazio processa todas as fontes ativas.
- `maxResults`: itens por pagina, entre 1 e 50.
- `maxPages`: limite de paginas por fonte, entre 1 e 20.
- `dryRun`: consulta e classifica os videos sem gravar no banco.

O cron usa HMAC-SHA256, portanto o segredo não trafega na requisição. O endpoint
mantém `X-API-Key` e `Authorization: Bearer` por compatibilidade. O segredo vem
de `cronSecrets.business_youtube` e, durante a migracao, usa
`cronSecrets.runnerhub_youtube` como fallback. A chave da YouTube Data API deve
ser configurada como `youtubeApiKey` em `config/business.local.cfm`.

Para preservar o funcionamento durante a migracao, se `youtubeApiKey` estiver
ausente ou invalida o endpoint reutiliza `RUNNERHUB_YOUTUBE_API_KEY` do ambiente
ou de `/var/www/runnerhub.run/jobs/runnerhub-jobs.env`. A resposta informa
`api_key_source` e um fingerprint, nunca o valor da chave.
As consultas enviam `Referer: https://business.roadrunners.run/`, dominio que
ja esta autorizado na restricao da chave legada.

Os valores podem ser gravados pelo administrador em
`/administracao/config-check/`, sem reiniciar o ColdFusion.

## Banco

O script `jobs/schema.sql` documenta a estrutura usada:

- `tb_youtube_canais`;
- `tb_media.youtube_duration_iso`;
- `tb_media.youtube_duration_seconds`;
- `tb_media.pub_status`;
- `tb_paginas_feed`.

O endpoint valida a estrutura antes de iniciar. O limite editorial utilizado
para publicacao automatica e 210 segundos, alinhado ao Portal do Business.

## Cron

O cadastro sugerido fica em
`/administracao/cron-jobs/youtube_import_job.sql`. Sem acesso SQL, edite o job
existente pelo painel e use:

- URL: `https://business.roadrunners.run/api/youtube-import.cfm`;
- metodo: `POST`;
- autenticacao: `hmac_sha256`;
- secret ref: `business_youtube`;
- body inicial: `{"channel":"","maxResults":10,"maxPages":1,"dryRun":true}`.

Depois de validar a simulacao, altere `dryRun` para `false` e aumente
`maxPages` gradualmente.

## Compatibilidade

O endpoint original `https://runnerhub.run/api/youtube/` e seus scripts
permanecem inalterados. Apenas um agendamento deve ficar ativo para evitar
concorrencia e consumo duplicado da quota do YouTube.

O arquivo publico plano inclui a implementacao mantida em
`/api/youtube/jobs/import.cfm`. Isso evita depender de uma liberacao adicional
do subdiretorio `/api/youtube/jobs/` no Apache.
