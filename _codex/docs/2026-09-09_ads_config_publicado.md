# Ads e banners — publicação confirmada

Publicado em **09/09/2026 às 11:11:33 Brasília (14:11:33 UTC)**, após autorização explícita `publique`.

## Resultado observado em produção

- Antes da troca, home: banner e native finais em `disabled`, `requested=false`, `served=false`.
- Depois: home desktop e `/estado/sc/` desktop entregaram banner HOUSE Mizuno Neo Vista 3, imagem carregada (`complete=true`, `naturalWidth>0`) e área 316×316. Home native e estado native passaram a `filled`, `requested=true`, `served=true`; campanha Avaí Run observada.
- SC mobile, viewport 390×844: `rr-state-banner-mobile` em `house/requested=true/served=true`, banner **Avaí Run** carregado, área 366×177,9 e presente no screenshot.
- Home mobile, 390×844: `rr-sidebar-banner-mobile` em `house/requested=true/served=true`, imagem **Mizuno Neo Vista 3** carregada, área 364×176,9 e presente no screenshot.
- Sessão do usuário permaneceu logada. Override de viewport foi removido ao terminar.
- Algumas posições ficam `empty/requested=true`: seleção ativa sem campanha elegível naquela posição; isso não é mais desabilitação global. Placeholders AJAX `pending` continuam existindo junto do slot final.

## Escopo e preservação

Somente estes cinco arquivos foram publicados, nesta ordem: serviço `services/AdsV1ConfigService.cfc`, include `includes/ads_v1/runtime_config.cfm`, `includes/ads_v1/banner_delivery.cfm`, `includes/eventos_ads.cfm`, `includes/estrutura/home_sidebar_promos.cfm`.

Configuração Ads passa a ser snapshot de REQUEST, carregada do arquivo do próprio site por include relativo ao componente. Nenhum acesso do renderizador ou SHADOW a `APPLICATION.adsV1`. Writer legado em settings permanece sem mudança. Execução real no Adobe foi confirmada pelos renders acima; qual request havia sobrescrito o global anteriormente permanece sem atribuição.

Backup privado: `/var/backups/rr-ads-request-config.kNW8w9/`, com três originais em `before`, candidatos em `candidate`, `before.sha256`, `candidate.sha256` e `guards.sha256`. Dois arquivos novos não existiam antes. Não houve restart/reset da aplicação.

Hashes conferidos antes, depois da troca e após navegador: Application.cfc, settings.cfm, ads.local.cfm, audience.local.cfm, viewability.cfm, quatro endpoints click/viewable HOUSE/CPC, tracker de audiência, marker, bootstrap e sw.js permaneceram intactos. Sem SQL, alteração de permissões, mudanças de regras de cobrança, cliques em anúncios ou eventos manuais.

## Pacote e verificações

Pacote correto: `Business/_codex/releases/2026-09-09_ads_request_config_linux.tar.gz`, SHA-256 `7e2dc3b6c70746431c443cd8fb273e1478b687d74f3dd276c7468f09b22b1688`. Cinco membros idênticos ao checkout por comparação de bytes; hashes individuais no plano.

O pacote anterior sem sufixo `_linux` contém AppleDouble `._*` do macOS, ocultos na listagem padrão do BSD tar. A allowlist do GNU tar rejeitou esse pacote **antes da extração e da troca**, preservando produção. Não reutilizar esse pacote anterior. O pacote Linux foi gerado com `COPYFILE_DISABLE=1 tar --format=ustar`; lista exata reconferida no Linux antes da instalação.

Reexecução local: 16 verificações CFML de request config, 36 banner render, 23 native render, 14 native service, 22 HOUSE banner estático: **111 PASS**, comandos exit 0. Teste CFML usa harness temporária sem banco/rede; produção validada no CUA, desktop/mobile, sem cliques em anúncios.

Rollback, se necessário: conferir hashes atuais contra `candidate.sha256`, restaurar somente os três consumidores de `before` antes de retirar os dois arquivos novos. Não restaurar settings/config privadas. Nenhum rollback foi necessário.
