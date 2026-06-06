# Runner Apps API

## Objetivo

O `Runner Apps` centraliza no `Business` o cadastro do menu de aplicacoes da plataforma, antes mantido de forma estatica no projeto `Road Runners` em:

- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm)
- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm)

O objetivo da API e permitir que `Road Runners` e outros sites da plataforma consumam a mesma lista dinamica de apps, com grupos/linhas ordenaveis.

## Gestao no Business

Admin:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/index.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/home.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/home.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/includes/runner_apps_backend.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/runner_apps_backend.cfm)

API:

- [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/runner-apps/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/runner-apps/index.cfm)

Banco:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/runner_apps_schema.sql`](/Users/geraldoprotta/IdeaProjects/Business/portal/runner-apps/runner_apps_schema.sql)

## Endpoint

```text
GET https://business.roadrunners.run/api/portal/runner-apps/
```

O endpoint e publico, somente leitura, e retorna apenas grupos e itens ativos por padrao.

## Parametros

| Parametro | Obrigatorio | Padrao | Descricao |
| --- | --- | --- | --- |
| `incluir_ocultos` | Nao | `0` | Quando `1`, retorna tambem grupos e itens ocultos. Deve ser usado apenas para diagnostico/admin. |

Exemplo:

```text
https://business.roadrunners.run/api/portal/runner-apps/?incluir_ocultos=1
```

## Resposta

Formato principal:

```json
{
  "success": true,
  "status": "ok",
  "groups": [
    {
      "id": 1,
      "name": "Linha principal",
      "description": "Primeira linha do menu Runner Apps.",
      "order": 1,
      "active": true,
      "items": [
        {
          "id": 1,
          "groupId": 1,
          "groupName": "Linha principal",
          "name": "Road Runners",
          "href": "/",
          "target": "",
          "rel": "",
          "imgSrc": "https://roadrunners.run/assets/rr_icon.jpg",
          "imgAlt": "Road Runners",
          "label": "Road Runners",
          "labelHtml": "Road Runners",
          "order": 1,
          "active": true
        }
      ]
    }
  ],
  "items": [],
  "poweredBy": {
    "label": "powered by",
    "href": "https://runnerhub.run/",
    "name": "RunnerHub"
  }
}
```

Campos importantes:

- `groups`: estrutura recomendada para renderizar o menu por linhas/categorias.
- `groups[].items`: apps daquela linha, ja ordenados.
- `items`: lista plana dos mesmos apps, mantida para compatibilidade.
- `target`: `"_blank"` quando o app deve abrir em nova aba; vazio quando deve abrir na mesma janela.
- `rel`: complemento opcional para links externos, como `noopener`.
- `imgSrc`: URL absoluta ou caminho convertido para URL absoluta pelo Business.
- `labelHtml`: texto pronto para renderizacao quando o consumidor aceitar HTML simples.

## Recomendacao de consumo

O consumidor deve:

1. chamar a API server-side, quando possivel;
2. manter cache curto, como 5 minutos;
3. preservar fallback local estatico;
4. renderizar por `groups`, nao por divisao fixa de quantidade;
5. usar `items` apenas como compatibilidade.

No `Road Runners`, o fallback estatico continua existindo no proprio `menu_apps_data.cfm`.

## Exemplo CFML

```cfml
<cfset runnerAppsMenuApiUrl = "https://business.roadrunners.run/api/portal/runner-apps/"/>

<cftry>
    <cfhttp url="#runnerAppsMenuApiUrl#" method="get" timeout="3" result="runnerAppsMenuApiResponse">
        <cfhttpparam type="header" name="Accept" value="application/json"/>
    </cfhttp>

    <cfif left(runnerAppsMenuApiResponse.statusCode, 3) EQ "200"
        AND isJSON(runnerAppsMenuApiResponse.fileContent)>

        <cfset runnerAppsPayload = deserializeJSON(runnerAppsMenuApiResponse.fileContent)/>

        <cfif isStruct(runnerAppsPayload)
            AND structKeyExists(runnerAppsPayload, "success")
            AND runnerAppsPayload.success
            AND structKeyExists(runnerAppsPayload, "groups")
            AND isArray(runnerAppsPayload.groups)>

            <cfset REQUEST.runnerAppsMenuGroups = runnerAppsPayload.groups/>
            <cfset REQUEST.runnerAppsMenuItems = runnerAppsPayload.items/>
            <cfset REQUEST.runnerAppsMenuPoweredBy = runnerAppsPayload.poweredBy/>
        </cfif>
    </cfif>
<cfcatch type="any">
    <!-- usar fallback local -->
</cfcatch>
</cftry>
```

## Renderizacao recomendada

```cfml
<cfloop array="#REQUEST.runnerAppsMenuGroups#" index="menuGroup">
    <div class="row">
        <cfloop array="#menuGroup.items#" index="menuApp">
            <a href="#menuApp.href#"<cfif len(menuApp.target)> target="#menuApp.target#"</cfif><cfif len(menuApp.rel)> rel="#menuApp.rel#"</cfif>>
                <img src="#menuApp.imgSrc#" alt="#menuApp.imgAlt#"/>
                #menuApp.labelHtml#
            </a>
        </cfloop>
    </div>
</cfloop>
```

## Estado atual no Road Runners

O projeto `Road Runners` ja foi adaptado para:

- consumir a API do `Business`
- manter cache de 5 minutos
- preservar fallback estatico
- renderizar por grupos em `menu_apps.cfm`
- renderizar por grupos tambem em `header_slim.cfm`

Arquivos envolvidos:

- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm)
- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm)
- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/header_slim.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/header_slim.cfm)

## Cuidados

- Nao remova o fallback estatico do consumidor.
- Nao use `incluir_ocultos=1` em producao publica.
- Em sites multilíngues, o consumidor pode sobrescrever o item de home localmente quando `href = "/"`.
- A ordenacao vem pronta da API: `groups[].order` e `items[].order`.
- O Business nao registra metricas de impressao/clique para Runner Apps; esta API e apenas catalogo.
