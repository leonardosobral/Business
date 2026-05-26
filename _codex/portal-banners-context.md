# Contexto Portal Banners

## O que este modulo resolve

O projeto `Business` agora tem um gerenciador de banners para consumo via API, pensado para substituir blocos hardcoded como o sidebar banner do `Road Runners`.

Nao e um sistema de anuncios pagos como `/ads`, mas reaproveita a mesma filosofia operacional:

- estado e datas de campanha
- priorizacao
- limites de entrega
- metricas de impressoes e cliques

## Onde editar

Admin:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/index.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/home.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/home.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/includes/banner_management_backend.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/banner_management_backend.cfm)

API publica:

- [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/index.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm)

Banco:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/portal_banner_schema.sql`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/portal_banner_schema.sql)

## Contrato da API

Parametros principais:

- `canal`
- `local`
- `tamanho`
- `largura`
- `altura`
- `site_url`
- `path`

Comportamento:

- o endpoint escolhe apenas banners `status = 2`
- usa `peso_exibicao` para randomizacao ponderada
- registra `view` na propria entrega
- gera `clickUrl` para registrar clique antes do redirect

## Detalhe importante de links internos

Se o banner tem `link_tipo = interno` e o destino e relativo, o click tracker precisa saber em qual site ele esta sendo consumido.

Hoje isso e resolvido por `site_url`.

Exemplo:

```text
/api/portal/banners/?canal=roadrunners&local=home-side-banner&site_url=https://beta.roadrunners.run
```

Sem `site_url`, o fallback atual monta links internos em `https://roadrunners.run`.

## Riscos conhecidos

- Sem deploy no site consumidor, o front continua hardcoded.
- O endpoint e publico e pensado para leitura server-side ou client-side. Ele ja retorna `Access-Control-Allow-Origin: *`.
- O sistema nao deduplica views por sessao. Cada entrega da API conta como impressao.
- O peso de exibicao e manual. Nao existe otimizacao automatica por CTR nesta primeira versao.
