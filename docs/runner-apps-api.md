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
GET https://api.roadrunners.run/v1/discovery/runner-apps.cfm
```

O endpoint é público, somente leitura, e retorna exclusivamente grupos e itens ativos. `GET` e `HEAD` são permitidos, `OPTIONS` retorna 204 e outros métodos retornam 405. Outros endpoints da API conservam sua autenticação.

O endereço legado `https://business.roadrunners.run/api/portal/runner-apps/` responde 308 para o endereço canônico. Não consulta o banco nem inicializa o portal administrativo. O cadastro e as regras permanecem no Business, no componente `api/portal/runner-apps/Catalog.cfc`. A API pública usa esse componente por mapeamento local, sem requisição HTTP ao Business.

## Parametros

| Parametro | Obrigatorio | Padrao | Descricao |
| --- | --- | --- | --- |
| `incluir_ocultos` | Não aceito | — | Qualquer presença retorna 400; dados ocultos nunca fazem parte do catálogo público. |
| `linha` | Nao | todas | Quando `principal`, retorna somente o grupo `Apps Principais` e seus aplicativos. |

Para exibir somente os Apps Principais:

```text
https://api.roadrunners.run/v1/discovery/runner-apps.cfm?linha=principal
```

O filtro preserva o contrato da resposta: `groups` contém apenas `Apps Principais` e `items` contém somente os aplicativos desse grupo. Outros valores para `linha` retornam HTTP `400` com `status = "invalid_parameter"`.

## Resposta

Formato principal:

```json
{
  "success": true,
  "status": "ok",
  "groups": [
    {
      "id": 1,
      "name": "Apps Principais",
      "description": "Primeira linha do menu Runner Apps.",
      "order": 1,
      "itemsPerRow": 3,
      "active": true,
      "items": [
        {
          "id": 1,
          "groupId": 1,
          "groupName": "Apps Principais",
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
- `groups[].itemsPerRow`: quantidade configurada de icones por linha (`3`, `4` ou `5`). Consumidores antigos devem assumir `3` quando o campo nao existir.
- `items`: lista plana dos mesmos apps, ordenada primeiro pelo grupo e depois pelo app. O Road Runners usa esta lista para renderizar todos os apps em um unico grid, sem separacao visual entre `Apps Principais` e `Apps Secundários`.
- `target`: `"_blank"` quando o app deve abrir em nova aba; vazio quando deve abrir na mesma janela.
- `rel`: complemento opcional para links externos, como `noopener`.
- `imgSrc`: URL absoluta ou caminho convertido para URL absoluta pelo Business.
- `labelHtml`: texto pronto para renderizacao quando o consumidor aceitar HTML simples.

## Recomendacao de consumo

O consumidor deve:

1. chamar a API server-side, quando possivel;
2. manter cache curto, como 5 minutos;
3. preservar fallback local estatico;
4. usar `groups` quando precisar preservar categorias na interface;
5. usar `items` quando precisar de um grid visual unico, pois a lista ja preserva a ordem dos grupos e dos apps;
6. no grid unico, usar `itemsPerRow` do primeiro grupo ativo e assumir `3` como fallback.

No `Road Runners`, o fallback estatico continua existindo no proprio `menu_apps_data.cfm`.

## Cache e configuração

O cabeçalho entrega imediatamente o último catálogo válido ou o fallback estático. Uma única atualização em background é iniciada por aplicação quando o cache de 300 segundos vence. Falhas preservam o catálogo anterior e aguardam 60 segundos antes da próxima tentativa. O HTTP tem timeout de 3 segundos e nunca bloqueia a renderização da página.

Implementação no RoadRunners: `services/RunnerAppsMenuCache.cfc`, `services/RunnerAppsHttpSource.cfc` e `services/runner_apps_menu_factory.cfm`. A factory resolve os componentes ao lado dela; isso também permite o uso do cabeçalho pelo OpenResults.

No bootstrap da API, `RR_RUNNER_APPS_CATALOG_PATH` pode substituir o caminho padrão `/var/www/business.roadrunners.run/api/portal/runner-apps`. O componente usa o datasource existente `runner_dba`; não foram alteradas permissões do banco. Instalações separadas precisam fornecer o componente pelo processo de deployment antes de ativar esse endpoint.

A resposta pública usa `Cache-Control: public, max-age=60, s-maxage=300, stale-if-error=86400`.

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

- consumir o catálogo público em `api.roadrunners.run`
- manter cache de 5 minutos com atualização única em background e intervalo de 60 segundos após falha
- preservar fallback estatico
- manter os dois grupos para gestao e ordenacao
- renderizar a lista plana em um unico grid em `menu_apps.cfm` e `header_slim.cfm`
- usar a quantidade de colunas configurada no primeiro grupo ativo para o grid unico

Arquivos envolvidos:

- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps_data.cfm)
- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/menu_apps.cfm)
- [`/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/header_slim.cfm`](/Users/geraldoprotta/IdeaProjects/RoadRunners/includes/estrutura/header_slim.cfm)

## Cuidados

- Nao remova o fallback estatico do consumidor.
- `incluir_ocultos` não é permitido no contrato público.
- Em sites multilíngues, o consumidor pode sobrescrever o item de home localmente quando `href = "/"`.
- A ordenacao vem pronta da API: `groups[].order` e `items[].order`.
- A quantidade de icones e configurada individualmente em cada grupo e vem em `groups[].itemsPerRow`.
- O Business nao registra metricas de impressao/clique para Runner Apps; esta API e apenas catalogo.
