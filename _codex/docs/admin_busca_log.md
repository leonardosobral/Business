# Admin de Busca Inteligente

Atualizado em: 2026-06-04

## Objetivo

Este documento serve como contrato para construir uma pagina de administracao e analise da busca em outro projeto, consumindo os logs gravados pelo portal Road Runners.

Fonte principal dos dados:

- tabela `tb_busca_log`
- DDL nova em [_codex/sql/2026-06-04_adicionar_tb_busca_log.sql](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-06-04_adicionar_tb_busca_log.sql)
- referencia completa em [_codex/sql/schema.sql](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/schema.sql)

## Fluxo Gravado

Cada busca com IA deve gerar uma linha pai e varias linhas filhas.

Linha pai:

- `etapa = 'interpretacao'`
- `origem = 'api/search.cfm'`
- guarda a frase digitada, modelo usado, resposta compacta da IA e filtros interpretados
- o id dessa linha volta para o frontend como `searchLogId`

Linhas filhas:

- `etapa = 'execucao'`
- `id_busca_log_parent` aponta para a linha pai
- guardam o que cada aba executou: `eventos`, `resultados`, `atletas`, `noticias`, `videos`
- para eventos/resultados, quando reaproveitam a interpretacao pai, `ia_json.reusedInterpretation = true` e `ia_json.modelCalled = false`

Busca tradicional:

- pode gravar `etapa = 'legado'`
- nao depende de IA
- nao precisa ter linha pai

## Semantica Das Colunas

Campos de identificacao:

- `id_busca_log`: id da linha
- `id_busca_log_parent`: id da interpretacao pai, quando for execucao de uma aba
- `log_timestamp`: horario do registro
- `site`: codigo do site em `APPLICATION.codSite`
- `ambiente`: `dev`, `beta` ou `prod`, inferido pelo host
- `origem`: arquivo que gravou o log
- `etapa`: `interpretacao`, `execucao` ou `legado`

Campos da busca:

- `busca_modo`: modo da busca, normalmente `ai` ou `plain`
- `busca_tipo`: tipo pedido pela interface, como `todos`, `eventos`, `resultados`, `atletas`, `noticias`, `videos`
- `busca_scope`: escopo efetivamente executado pela linha
- `tipo_termo`: interpretacao do termo livre, como `descricao`, `prova` ou `pessoa`
- `termo_original`: texto digitado pelo usuario
- `termo_livre`: texto usado como busca textual dura, quando existir
- `modelo`: modelo configurado, ex. `gpt-5-mini`

Campos de estado:

- `usou_ia`: `true` somente quando aquela linha chamou o modelo; linhas filhas que so reaproveitam a interpretacao devem ficar `false`
- `fallback_usado`: `true` quando a interpretacao da IA falhou e o backend usou fallback local
- `fallback_motivo`: motivo resumido do fallback
- `erro`: erro tecnico conhecido
- `http_status`: status retornado pela chamada da IA, quando houver

Campos do usuario:

- `id_usuario`: usuario logado
- `id_pagina`: pagina/perfil do usuario logado
- `usuario_verificado`: se tinha acesso ao modo IA
- `ip`
- `user_agent`

Campos JSONB:

- `filtros_json`: filtros finais usados pela busca, ja normalizados para a API
- `contagens_json`: contagens retornadas pela execucao daquela linha
- `request_json`: request resumido; parametros default da busca sao removidos para nao poluir analise
- `ia_json`: dados da interpretacao ou marcador de reaproveitamento
- `payload_json`: dados auxiliares para UI/debug, como mensagem, resumo, filtros, query debug e flags

## JSONs Importantes

`filtros_json` costuma ter:

```json
{
  "cidade": "Salvador",
  "estado": "BA",
  "estados": ["BA"],
  "tipo_termo": "descricao",
  "termo_livre": "",
  "distancia_inicio": 21,
  "distancia_fim": 21,
  "periodo_inicio": "",
  "periodo_fim": ""
}
```

`ia_json` na linha pai costuma ter:

```json
{
  "success": true,
  "usedAi": true,
  "fallbackReason": "",
  "rawFilters": {},
  "normalizedFilters": {},
  "rawResponse": {
    "id": "resp_xxx",
    "model": "gpt-5-mini-2025-08-07",
    "status": "completed",
    "usage": {},
    "outputText": "{\"estado\":\"BA\"}"
  }
}
```

`ia_json` em execucao que reaproveitou a interpretacao:

```json
{
  "reusedInterpretation": true,
  "parentLogId": 25,
  "modelCalled": false
}
```

`payload_json` em eventos/resultados pode ter:

```json
{
  "message": "Entendi que voce quer corridas de 21 km. em Salvador/BA.",
  "summary": "Salvador/BA • meia maratona • tipo: descricao",
  "filtersApi": {},
  "queryDebug": [],
  "ignoredFreeTerm": false,
  "reusedInterpretation": true,
  "searchUsedAi": true
}
```

## Consultas Uteis Para O Admin

Ultimas buscas com filhos agregados:

```sql
select
    p.id_busca_log,
    p.log_timestamp,
    p.ambiente,
    p.termo_original,
    p.tipo_termo,
    p.termo_livre,
    p.modelo,
    p.usou_ia,
    p.fallback_usado,
    p.filtros_json,
    coalesce(filhos.execucoes, '[]'::jsonb) as execucoes
from tb_busca_log p
left join lateral (
    select jsonb_agg(
        jsonb_build_object(
            'id_busca_log', c.id_busca_log,
            'busca_scope', c.busca_scope,
            'busca_tipo', c.busca_tipo,
            'contagens', c.contagens_json,
            'request', c.request_json,
            'ia', c.ia_json,
            'payload', c.payload_json
        )
        order by c.id_busca_log
    ) as execucoes
    from tb_busca_log c
    where c.id_busca_log_parent = p.id_busca_log
) filhos on true
where p.etapa = 'interpretacao'
order by p.log_timestamp desc
limit 50;
```

Buscas sem nenhum resultado nas abas principais:

```sql
with execucoes as (
    select
        id_busca_log_parent,
        sum(coalesce((contagens_json->>'eventos')::numeric, 0)) as eventos,
        sum(coalesce((contagens_json->>'resultados')::numeric, 0)) as resultados,
        sum(coalesce((contagens_json->>'atletas')::numeric, 0)) as atletas,
        sum(coalesce((contagens_json->>'noticias')::numeric, 0)) as noticias,
        sum(coalesce((contagens_json->>'videos')::numeric, 0)) as videos
    from tb_busca_log
    where etapa = 'execucao'
    group by id_busca_log_parent
)
select
    p.id_busca_log,
    p.log_timestamp,
    p.termo_original,
    p.filtros_json,
    e.*
from tb_busca_log p
join execucoes e on e.id_busca_log_parent = p.id_busca_log
where p.etapa = 'interpretacao'
  and (e.eventos + e.resultados + e.atletas + e.noticias + e.videos) = 0
order by p.log_timestamp desc
limit 100;
```

Termos mais buscados:

```sql
select
    lower(trim(termo_original)) as termo,
    count(*) as buscas,
    max(log_timestamp) as ultima_busca
from tb_busca_log
where etapa = 'interpretacao'
  and log_timestamp >= now() - interval '30 days'
group by lower(trim(termo_original))
order by buscas desc, ultima_busca desc
limit 100;
```

Falhas de IA e fallbacks:

```sql
select
    id_busca_log,
    log_timestamp,
    termo_original,
    modelo,
    http_status,
    fallback_usado,
    fallback_motivo,
    erro,
    ia_json
from tb_busca_log
where etapa = 'interpretacao'
  and (fallback_usado = true or erro is not null or coalesce(http_status, '') not in ('', '200 OK'))
order by log_timestamp desc
limit 100;
```

Busca por filtro JSON:

```sql
select
    id_busca_log,
    log_timestamp,
    termo_original,
    filtros_json
from tb_busca_log
where etapa = 'interpretacao'
  and filtros_json @> '{"estado": "BA"}'::jsonb
order by log_timestamp desc
limit 100;
```

## Telas Recomendadas

Lista de buscas:

- termo digitado
- data/hora
- usuario
- ambiente
- modelo
- filtros interpretados
- totais por aba
- flags `fallback_usado`, `usou_ia`, `tipo_termo`

Detalhe da busca:

- linha pai de interpretacao
- timeline das execucoes filhas
- mensagem mostrada ao usuario
- filtros enviados para cada endpoint
- contagens por aba
- `queryDebug` por aba, quando existir
- erro/fallback, quando existir

Dashboards:

- volume por dia
- top termos
- termos com zero resultado
- filtros mais usados por cidade/estado/distancia
- taxa de fallback
- chamadas reais de IA por modelo
- usuarios que mais usam a busca

## Cuidados

- Para contar chamadas reais de modelo, use `usou_ia = true`, nao `payload_json.searchUsedAi`.
- Para saber se a busca inteira nasceu de IA, olhe a linha pai ou `payload_json.searchUsedAi` nas filhas.
- Para montar uma busca completa, sempre agrupe por `id_busca_log` da linha `interpretacao` e junte as filhas por `id_busca_log_parent`.
- `request_json` e `payload_json` sao sanitizados antes de gravar; nao espere encontrar o envelope completo da OpenAI.
- Erro ao gravar log nao derruba a busca do usuario; durante a request ele fica em `REQUEST.buscaLogErrors`.
- Se o admin usar outro usuario de banco, ele precisa de `SELECT` em `tb_busca_log`.
