# Audiência — banners e cobertura após ativação

Atualização 09/09 11:11 Brasília: **banners restaurados em produção**, confirmados na home/SC em desktop e mobile. A configuração Ads foi isolada por request/site, sem alterar config privada, login, billing ou tracker. Ver [publicação e evidência atual](2026-09-09_ads_config_publicado.md). A evidência abaixo documenta a implantação de audiência anterior.

## Publicado em produção

Coleta permanece ATIVA. Esta continuação não alterou banco, permissões, DSN, credenciais, autenticação, cobrança ou retenção; não reiniciou Apache/ColdFusion.

Backup privado dos quatro arquivos: `/var/backups/roadrunners-audience-viewport.FVGgyQ/before/`.

| Arquivo RoadRunners | Correção | SHA-256 publicado |
| --- | --- | --- |
| `assets/js/rr-audience.js` | Não emitir inventário de posições ausentes no layout do viewport; manter markers colapsados aplicáveis e reiniciar continuidade ao sair do viewport aplicável | `044c88c14bf2f6ea676446029589da0a00667d0012a2f64a8fffb338e0c1ff28` |
| `includes/analytics/slot_marker.cfm` | Media `<768px` nos markers de banner mobile que ficam fora do wrapper responsivo | `36a8b60876fb6e1246c353354fdc1c19565d32687f07fc01e34a9c81b616fcf8` |
| `includes/analytics/bootstrap.cfm` | URL `/assets/js/rr-audience.js?v=044c88c14bf2` para não reutilizar o cache público antigo de 31 dias | `213df459b988617bde45447db77476f04525aadf383b420d3450b83390e3de1c` |
| `sw.js` | Listas editoriais também usam o network-first existente, com fallback offline preservado; versão dos caches v18 mantida | `8194621b6aa793b0f80bb8d6b5e1f9331272b54135a31b3c24a1b0dcece79db3` |

Primeiros dois arquivos aplicados em 2026-09-09T00:39:33Z; bootstrap em 00:45:50Z. O beacon de cobrança `includes/ads_v1/viewability.cfm` foi conferido intacto: `6824fabb64fc6715d6e48464113560636e78ded7f1004b6a2c1557c1eb37bc20`.

Worker aplicado em 2026-09-09T00:54:54Z. Hashes públicos do worker e do tracker versionado conferidos. O worker público tem `Cache-Control: no-cache, no-store, must-revalidate` e CF cache BYPASS. Após atualização normal, a primeira navegação testada em `/videos/` já trouxe família `videos` e o tracker novo. Não houve purge geral nem troca de versão dos caches.

## Evidência

- 47 testes tracker/privacidade passaram; quatro regressões novas falharam antes da correção do viewport. Quatro casos de marker foram renderizados no Lucee local, sem banco.
- 12 testes do service worker real passaram; oito casos editoriais retornavam HTML antigo antes do ajuste. Offline com/sem cache, assets e imagens preservados.
- CUA em produção: home mobile 390×844 mostrou banner Avaí com área real; estado mobile mostrou `rr-state-banner-mobile`; estado desktop 1630px mostrou `rr-sidebar-banner-desktop`, com banner mobile oculto. URL versionada confirmada no HTML.
- Business, filtros prod/7 dias/SC/home/MOBILE/internos=1: uma abertura nova após receber o JS corrigido aumentou posições de 5 para 8. Cada um dos três slots mobile aplicáveis aumentou de 1 para 2; os dois slots desktop permaneceram em 1. Exposições do banner mobile aumentaram de 1 para 2. Este é tráfego interno de validação, não crescimento orgânico.
- Dados anteriores ao ajuste não foram apagados nem recalculados. Linhas desktop/mobile indevidas antigas ainda podem aparecer no período agregado.
- A lista de notícias abriu uma cópia PWA anterior à instrumentação; no reload veio o bootstrap atual. A notícia individual foi confirmada como `news_detail` com identificador de conteúdo. Esse achado motivou o ajuste do worker.
- Reexecução final integrada: 59 testes passaram, JS/worker syntax e diff-check sem erro. Business `news_detail`, incluindo internos, confirmou duas aberturas da notícia usada no teste, separadas de outras duas aberturas já existentes.
- Leitura final do painel NORMAL, internos desmarcado, última recepção 08/09 21:57 Brasília: 34 visitantes estimados, 118 aberturas, 33 sessões (20 qualificadas), 203 posições registradas, 17 posições visíveis e 17 anúncios visíveis (25 renderizados). Os totais do período incluem registros anteriores ao ajuste; não representam inventário já saneado retroativamente.

## Cobertura e limites

Banners ativos do motor AdsV1 são medidos na home, estado, busca e sidebar de evento/perfil quando essa posição existe no dispositivo. News/lista/detalhe e vídeos têm medição de página/conteúdo, mas seus layouts atuais não têm slots AdsV1 ativos; os mocks editoriais estão comentados. Promos estáticos Maratonas/Strava no perfil ainda não têm marcadores de audiência. Falhas de AJAX ainda podem deixar inventário aplicável em `pending`; isso não é exposição nem vaga comprovadamente vazia.

UF comercial funciona conforme contexto da página/busca, depois perfil, depois acesso. UF do acesso continua com lacuna: na leitura inicial normal havia 68 aberturas e todas sem visitorUf. O site retornou país BR/UF BR e origem server-cache numa consulta anônima; `BR` não é uma UF válida e é corretamente convertido em desconhecida. `includes/location.cfm` e `LocationResolver.cfc` publicados têm os mesmos hashes locais. A rota `/atleta/` também não inicializa o contexto de localização. Não foi atribuída causa ao proxy ou provedor sem evidência CF-native.

Após autorização explícita do usuário, o diagnóstico CF-native isolado foi executado em 09/09 UTC (08/09 Brasília), restrito a loopback + token, sem DSN/sessão da aplicação principal. O CFHTTP recebeu HTTP 403 do provedor padrão `free.freeipapi.com`; o resolver retornou BR/BR/fallback e a repetição reutilizou esse fallback em cache. `curl` no mesmo servidor/provedor recebeu HTTP 200/BR/SP. Isso comprova diferença entre as requisições, mas ainda não identifica qual característica provoca o 403. Não há evidência de falha TLS neste teste.

O teste público autenticado foi bloqueado pelo auto-review antes de alteração. A versão executada permaneceu restrita ao próprio servidor. O CGI observado era loopback, com cabeçalhos de IP ausentes, inclusive no controle de forwarding. Portanto ainda NÃO comprova o CGI do visitante público nem as configurações da aplicação principal: usou o componente atual copiado, seus defaults e cache isolado.

Diagnóstico retirado: `/var/www/roadrunners.com.br/rr-geo-native-KzDVW2` removido da área web e HTTP 404 confirmado; cópia recuperável privada em `/var/tmp/rr-geo-native-KzDVW2-closed`, root/0700. Nenhum arquivo existente de produção, banco, login, proxy ou configuração foi alterado. Leitura atual do Business normal após reload: 35 visitantes estimados, 124 aberturas, 17 posições/anúncios visíveis; última recepção 08/09 22:03 Brasília. Todas as 124 aberturas ainda sem UF do acesso; 39 sem UF comercial.

### Refinamento do diagnóstico — 08/09 22:17 Brasília

- Duas consultas complementares com curl, padrão e `User-Agent: ColdFusion`, receberam 200/JSON. A hipótese de User-Agent isolado causar o bloqueio não foi reproduzida.
- Segunda rodada CF-native, mesmas barreiras local + token, fez exatamente duas consultas ao mesmo provedor: endpoint padrão e controle fixo público. Ambas receberam 403/HTML, `serverCloudflare=true`, indicadores de desafio/CAPTCHA no corpo; sem `Retry-After` ou indicadores de rate limit/autorização entre os termos testados. `cf-mitigated` não informou challenge. A evidência indica página de desafio Cloudflare, mas não identifica qual característica da requisição acionou a proteção. Nenhum desafio foi resolvido nem contornado.
- As três variáveis `RR_LOCATION_PROVIDER_URL`, `RR_LOCATION_PROVIDER_PRIMARY_URL` e `RR_LOCATION_PROVIDER_SECONDARY_URL` estavam ausentes no processo CF. Não houve leitura de configurações privadas, APPLICATION principal ou credenciais.
- Segunda rota `/var/www/roadrunners.com.br/rr-geo-native-4HPzYA` também retirada; HTTP 404 confirmado. Cópia recuperável em `/var/tmp/rr-geo-native-4HPzYA-closed`, root/0700. Primeiro par de hashes de localização permanece intacto. Nenhuma correção de runtime foi publicada nesta continuação.
- Receipt filtrado, com saídas exatas e timestamps: `/private/tmp/rr-geo-native-local-bLT90Y/receipt-2026-09-08.md`.

Próximo ajuste proposto, NÃO implementado: uma fonte geográfica que não dependa de resolver esse desafio, mais cache negativo curto de cinco minutos para BR/BR. Cookies BR/BR antigos não podem continuar impedindo reconsulta; países estrangeiros válidos e UFs brasileiras válidas devem manter seu comportamento. Não confundir fallback desconhecido com audiência brasileira comprovada. A alternativa de receber somente país/UF da Cloudflare que já atende o site exige configuração explícita e validação da origem confiável; não habilitar cegamente cabeçalhos nem coletar cidade/coordenadas para este objetivo.

Referências oficiais consultadas: [contrato GET/JSON do FreeIPAPI](https://app.freeipapi.com/docs/api-reference/get-ip-info), [gratuito sem autenticação](https://app.freeipapi.com/docs/api-reference/api-introduction), [cabeçalhos de localização da Cloudflare](https://developers.cloudflare.com/rules/transform/managed-transforms/reference/). Estas referências descrevem capacidades, não comprovam configuração atual da zona.

Retenção permanece pendente com DBA e não impede a contagem. Não solicitar novamente criação de role nem retirar privilégios de `runner_dba`.
