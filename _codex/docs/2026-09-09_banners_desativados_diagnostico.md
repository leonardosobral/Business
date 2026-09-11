# Banners ausentes — diagnóstico sem alteração de produção

**Atualização 09/09 11:11 Brasília:** correção autorizada e **publicada**, após restabelecimento do SSH. Banners voltaram na home/SC, desktop/mobile, com imagens carregadas e sessão preservada. Ver [registro da publicação](2026-09-09_ads_config_publicado.md). O texto abaixo preserva os achados anteriores à correção.

Pedido: verificar a ausência de banners e se houve novo deploy ou efeito das mudanças de audiência. Não houve autorização para implementar correção nesta etapa. A proposta anterior de mudar a origem geográfica para Cloudflare também não foi executada.

## Confirmado

- Na home aberta pelo usuário, após reload, e em uma abertura nova de `/estado/sc/`, o DOM contém os slots de banner/native com `data-audience-state="disabled"`, `requested=false`, `served=false`; não há imagem de banner entregue. A home utiliza o tracker versionado `044c88c14bf2`.
- `includes/ads_v1/banner_delivery.cfm:13–20` habilita a entrega somente se `APPLICATION.adsV1.housePlacements` contém `rr-sidebar-banner-300x250`. O branch de `:113–114` gera exatamente `disabled/requested=false` quando isso não acontece. Native depende das listas CPC/HOUSE. UF desconhecida ou ausência de candidato não explicam esse branch: a seleção nem começou.
- O tracker de audiência consulta geometria/estado e não remove banners nem muda CSS. O marker responsivo não altera as flags de habilitação. Bootstrap apenas versiona o JS. O worker não intercepta os endpoints AJAX da home. Esses quatro arquivos em produção continuam idênticos ao candidato publicado e conferido ontem.
- Renderizadores/carregadores/APIs de banner verificados continuam correspondendo ao local. `index.cfm`, `Application.cfc`, `settings.cfm` correspondem ao payload publicado em 08/09 01:48 UTC. Não foi identificado deploy inesperado nos caminhos examinados. Isso não equivale a uma auditoria de todos os arquivos do servidor.
- `viewability.cfm` permanece com SHA-256 `6824fabb64fc6715d6e48464113560636e78ded7f1004b6a2c1557c1eb37bc20`, igual à referência anterior; a divergência com o checkout local é preexistente.
- `/config/ads.local.cfm` de produção existe, é legível pelo usuário do CF e mantém o hash `dd3ff39886efec603025a331c596c644f803bddf0794ba3b9166fd8e2259b927`, 486 bytes, root/0644. É idêntico ao local e ao guard pré-publicação. O arquivo local habilita banner HOUSE e cinco posições CPC; o conteúdo privado remoto não foi impresso.

## Hipótese principal: configuração compartilhada entre ambientes

Produção, beta e dev usam `THIS.Name="RoadRunners"` na mesma instalação CF. Beta não possui `ads.local.cfm`; dev possui versão diferente. Cada ambiente pode incluir seu próprio `settings.cfm`, cujo único writer conhecido substitui `APPLICATION.adsV1` inteiro após iniciar as listas como vazias.

O guard de produção `ensureAppSettings()` não valida `adsV1`/`housePlacements`. Portanto uma configuração vazia pode persistir. Dev ainda tem um gatilho adicional de recarga por `seoVerification`. Os helpers Meta também podem reincluir settings por condição de configuração.

Isso explica um mecanismo possível de sobrescrita sem deploy, mas ainda não prova qual request/ambiente foi o último writer. Não foi instalado endpoint para ler ou modificar o escopo APPLICATION principal. Não chamar `/config/settings.cfm`, `ensureAppSettings()` ou `resetApp` como se fossem diagnósticos somente leitura.

## Limites e segurança

- Processo CF Java atual iniciou em 01/09 21:31:22 UTC; não houve restart na noite investigada.
- O log Apache identificado não contém chamadas diretas a `/config/settings.cfm` nem parâmetro `resetApp` desde 09/09 00:54 UTC. O formato combined é compartilhado e não registra vhost; não permite atribuir a origem da recarga indireta.
- Nenhuma alteração em produção, configuração, banco, autenticação, billing, proxy ou Cloudflare. Não foram executados SQL, beacons de cobrança manuais ou rotinas de reload.
- Correção ainda pendente de autorização: restaurar de forma isolada as flags Ads corretas e impedir sobrescrita entre ambientes, sem reinício global nem mudança do nome da aplicação que derrube sessões.
