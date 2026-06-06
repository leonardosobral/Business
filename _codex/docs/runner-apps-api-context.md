# Contexto Runner Apps API

## O que este modulo resolve

O `Business` centraliza o menu `Runner Apps`, antes mantido como lista estatica no `Road Runners`.

Agora a lista fica em banco e e exposta por API para qualquer site da plataforma.

## Onde fica no Business

Admin:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/index.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/home.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/home.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/includes/runner_apps_backend.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/runner_apps_backend.cfm)

API:

- [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/runner-apps/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/runner-apps/index.cfm)

Schema:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/runner_apps_schema.sql`](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/runner_apps_schema.sql)

## Contrato publico

Endpoint:

```text
GET https://business.roadrunners.run/api/portal/runner-apps/
```

Resposta:

- `success`
- `status`
- `groups`
- `items`
- `poweredBy`

Consumidores devem preferir `groups`, porque o menu e organizado por linhas/categorias ordenaveis.

`items` existe para compatibilidade com consumidores que ainda renderizam lista plana.

## Banco

Tabelas:

- `tb_portal_runner_app_groups`
- `tb_portal_runner_apps`

Principais campos de grupo:

- `nome`
- `descricao`
- `ordem`
- `ativo`

Principais campos de app:

- `id_group`
- `nome`
- `url`
- `imagem_url`
- `alt_text`
- `abrir_nova_aba`
- `rel`
- `ordem`
- `ativo`

## Road Runners

O `Road Runners` consome a API em:

- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm)

Renderizadores:

- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm)
- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/header_slim.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/header_slim.cfm)

Comportamento esperado:

- tentar API do Business
- cachear por 5 minutos em `APPLICATION.runnerAppsMenuCache`
- preservar fallback estatico
- renderizar por `REQUEST.runnerAppsMenuGroups`
- manter `REQUEST.runnerAppsMenuItems` para compatibilidade

## Regras importantes

- Itens ocultos nao saem na API padrao.
- Grupos ocultos nao saem na API padrao.
- `incluir_ocultos=1` e apenas para diagnostico.
- Links com `target = "_blank"` devem abrir em nova aba.
- Links com `target = ""` devem abrir na mesma janela.
- O item local da home pode ser normalizado pelo consumidor se vier como `/`.
- Nao ha tracking de clique/impressao nesta API.

## Validacao recomendada

1. Abrir `/portal/runner-apps/` no Business.
2. Confirmar API em `/api/portal/runner-apps/`.
3. Ocultar um app.
4. Confirmar que o app some do JSON padrao.
5. Confirmar que aparece em `?incluir_ocultos=1`.
6. No consumidor, aguardar cache ou limpar `APPLICATION.runnerAppsMenuCache`.
7. Confirmar renderizacao agrupada.

## Cuidado ao portar para outro site

Nao copie apenas o HTML do menu antigo. O consumidor precisa adaptar a origem de dados para:

- `REQUEST.runnerAppsMenuGroups`
- `REQUEST.runnerAppsMenuItems`
- `REQUEST.runnerAppsMenuPoweredBy`

O fallback local deve continuar existindo para proteger o header quando o Business estiver indisponivel.
