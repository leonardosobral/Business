# Portal Banners

## Objetivo

O modulo [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/) centraliza o cadastro e a governanca de banners visuais consumidos por `Road Runners` ou qualquer outro site da plataforma.

Ele substitui o modelo antigo de banners hardcoded e randomizados no front por uma API com:

- cadastro obrigatorio de criativos desktop e mobile em `jpg`, `png` ou `gif`
- segmentacao por `canal` e `local_layout`
- campos de tamanho e prioridade
- janela de exibicao por data/hora
- limites de entrega
- rastreamento de impressoes e cliques

## Estrutura

Arquivos principais:

- [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/index.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/home.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/home.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/includes/banner_management_backend.cfm`](/Users/geraldoprotta/IdeaProjects/Business/portal/includes/banner_management_backend.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/index.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/index.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm)
- [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/portal_banner_schema.sql`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/portal_banner_schema.sql)

## Banco

Tabelas novas:

- `tb_portal_banners`
- `tb_portal_banners_log`

O SQL fica em [`/Users/geraldoprotta/IdeaProjects/Business/portal/banners/portal_banner_schema.sql`](/Users/geraldoprotta/IdeaProjects/Business/portal/banners/portal_banner_schema.sql).

Campos relevantes do cadastro:

- `nome`
- `canal`
- `local_layout`
- `tamanho_nome`
- `largura` e `altura` para desktop
- `arquivo_path`, `arquivo_original` e `formato` para desktop
- `largura_mobile` e `altura_mobile`
- `arquivo_mobile_path`, `arquivo_mobile_original` e `formato_mobile`
- `link_destino`
- `link_tipo`
- `abrir_nova_aba`
- `peso_exibicao`
- `prioridade`
- `limite_impressoes`
- `limite_cliques`
- `limite_diario`
- `inicio_exibicao`
- `fim_exibicao`
- `status`

## Logica de entrega

A API:

1. filtra banners por `canal` e `local_layout`
2. exige `status = 2`
3. respeita datas de inicio e fim
4. respeita limites totais e diarios
5. aceita compatibilidade por `tamanho`, `largura` e `altura`
6. seleciona um banner elegivel por randomizacao ponderada via `peso_exibicao`
7. registra `view`
8. devolve `clickUrl` rastreavel

O clique nao aponta direto para o destino final. Ele passa por [`/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm`](/Users/geraldoprotta/IdeaProjects/Business/api/portal/banners/click.cfm), que:

- registra `click`
- resolve o destino interno ou externo
- redireciona para o link final

## Consumo externo

Consulta JSON:

```text
GET /api/portal/banners/?canal=roadrunners&local=home-side-banner&tamanho=sidebar-300x250&site_url=https://beta.roadrunners.run
```

Resposta esperada para os arquivos responsivos:

- `banner.images.desktop.imageUrl`
- `banner.images.desktop.width`
- `banner.images.desktop.height`
- `banner.images.desktop.format`
- `banner.images.mobile.imageUrl`
- `banner.images.mobile.width`
- `banner.images.mobile.height`
- `banner.images.mobile.format`
- `banner.clickUrl`
- `banner.target`
- `banner.alt`
- `banner.linkType`

Os campos `banner.imageUrl`, `banner.desktopImageUrl`, `banner.width`, `banner.height` e `banner.format` continuam representando a peca desktop por compatibilidade com consumidores anteriores. Novas integracoes devem usar `banner.images`.

Exemplo de renderizacao no consumidor:

```html
<a href="banner.clickUrl" target="banner.target">
  <picture>
    <source media="(max-width: 767px)" srcset="banner.images.mobile.imageUrl">
    <img src="banner.images.desktop.imageUrl" alt="banner.alt">
  </picture>
</a>
```

O breakpoint pertence ao layout do site consumidor; a API apenas identifica e entrega as duas versoes.

`site_url` e importante quando o banner usa `link_tipo = interno`, porque o redirect de clique usa esse host para montar a URL final relativa do site consumidor.

Sem `site_url`, o fallback atual para links internos aponta para `https://roadrunners.run`.

## Uploads

Os dois arquivos enviados pelo Business sao gravados em:

- URL publica: `/portal/banners/assets/`
- pasta local esperada: `portal/banners/assets/`

O backend tenta criar essa pasta automaticamente quando o modulo e carregado.
