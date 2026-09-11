# Audiência — candidato RoadRunners reconciliado

## Resultado desta etapa

Os 14 arquivos divergentes do inventário de produção foram revisados contra o backup privado e o histórico Git. Foi preparado **somente localmente** um candidato com **30 arquivos: 18 substituições e 12 novos**. Nenhum arquivo RoadRunners ou Business foi publicado nesta etapa; coleta, banco, proxy, agenda e autenticação não foram alterados. `runner_dba` permanece intocado.

A única exclusão em relação à lista original de 31 arquivos é `includes/ads_v1/viewability.cfm`. O delta desse arquivo modifica o beacon de exposição dos Ads existentes, independentemente da flag de audiência. Ele não é necessário ao novo tracker: os eventos de audiência usam `data-audience-*` e o coletor próprio. Preservá-lo evita mudar a contabilização da campanha durante esta instalação. A alteração local não foi descartada nem modificada; fica para uma revisão/publicação separada.

O [manifesto do candidato](2026-09-07_audience_roadrunners_publication_candidate.json) registra os hashes e os baselines exatos. Ele não é recibo de publicação e não substitui o [manifesto original](2026-09-07_audience_release_manifest.json), preservado como histórico.

## Reconciliação dos 14 arquivos

| Arquivo | Decisão e evidência |
| --- | --- |
| `api/eventos_busca.cfm` | Incluir; live igual a `HEAD^`; somente inclusão do inventário sem resultados. |
| `assets/js/runnerhub-busca-page.js` | Incluir; live igual a `HEAD^`; apenas propagação/adoção do contexto assinado. |
| `assets/js/runnerhub-event-filters.js` | Incluir; live igual a `HEAD^`; apenas contexto de audiência em substituição/paginação assíncrona. |
| `includes/estrutura/seo-web-tools-body-end.cfm` | Incluir; live igual a `HEAD^`; somente controles de privacidade e bootstrap de audiência. |
| `includes/eventos_ads.cfm` | Incluir; live→candidato acrescenta somente nove linhas de contexto/marcador. A alteração do gate CPC presente no histórico já existe no live e não será introduzida por este pacote. |
| `includes/ads_v1/banner_delivery.cfm` | Incluir; chave da posição e marcador sem entrega; chamada de delivery existente preservada. |
| `includes/ads_v1/banner_slot.cfm` | Incluir; somente atributos `data-audience-*`; publicar junto do caller que define a chave física. |
| `includes/ads_v1/native_event_slot.cfm` | Incluir; atributos de audiência e marcador de erro; URLs e tokens Ads preservados. |
| `includes/ads_v1/viewability.cfm` | **Não publicar**; manter bytes de produção, SHA-256 `6824fabb64fc6715d6e48464113560636e78ded7f1004b6a2c1557c1eb37bc20`. |
| `includes/estrutura/home_sidebar_promos.cfm` | Incluir; somente marcadores nos ramos sem posição preenchida/aplicável. |
| `includes/estrutura/home_sidebar_async_slot.cfm` | Incluir; inventário oculto anterior ao placeholder. |
| `includes/estrutura/home_sidebar_mobile_banner_slot.cfm` | Incluir; marcador pendente, sem mudança de fetch/hidratação. |
| `includes/modal/modal_youtube.cfm` | Incluir; abertura YouTube e eventos HTML5 sob guard do tracker; não altera playback. |
| `index.cfm` | Incluir; somente inventário lateral e ramo sem eventos. |

Dos 19 arquivos já existentes no backup, 17 são byte a byte iguais ao commit anterior ao início da instrumentação (`f4e83cf0`). As duas exceções são `eventos_ads.cfm` e `viewability.cfm`, reconciliadas explicitamente acima. Os cinco arquivos iguais à base do manifesto — `Application.cfc`, `config/settings.cfm` e os três catálogos i18n — têm deltas locais restritos a inicialização/configuração/privacidade de audiência. O delta de `Application.cfc` não muda nome da aplicação, sessão, datasource ou funções de autenticação.

Os 12 novos são o coletor, dois serviços, três assets de tracker/privacidade e seis includes de analytics. Seus bytes são os mesmos do manifesto original. Não houve alteração de código-fonte nesta etapa.

## Artefatos privados e verificação

- Diretório local: `/private/tmp/rr-audience-reconcile.iCyecF`, modo `0700`.
- Backup baixado: cópia do [backup anterior](2026-09-07_audiencia_backup_roadrunners.md), SHA-256 `5035a71b74d125dc6dc54dfc029b8ba500f75faaa337f1dc9b9337f107333ab3`; 19 arquivos extraídos conferidos individualmente.
- Candidato: `candidate.tar.gz` nesse diretório, modo `0600`, 184.320 bytes; SHA-256 `5983a424b6ca50bb803d63290699b1a197684b9dcf0a14fac4d720f8cacea3d6`.
- Conteúdo runtime aprovado: 30 arquivos regulares, com nomes e hashes de conteúdo verificados; nenhum teste, fixture, SQL, job ou configuração `.local`. **Correção apurada na publicação:** o archive também contém 30 entradas auxiliares AppleDouble `._*` do macOS, que a listagem local BSD tar não mostrou. A extração GNU tar na pasta privada revelou 60 arquivos; nenhum foi publicado nesse estado. A extração inicial foi preservada em pasta privada separada e a preparação foi refeita seletivamente pelos 30 caminhos do manifesto, com hashes e lista exata conferidos. O archive original e seu hash foram preservados; os auxiliares não integram o payload de publicação.
- O pacote inclui configuração runtime compartilhada e deve permanecer privado; não é um download público e não deve ser anexado ao site.
- A preparação foi executada por helper local revisado, sem recursos de rede/DB/deploy. Uma falha de criação não exclusiva do archive foi corrigida antes da execução: usa descritor aberto com `wx`, modo `0600`, além de preflight dos destinos.
- Os 31 hashes do source original permanecem iguais ao manifesto; os dois repositórios e seus diffs preexistentes foram preservados.

## Testes atuais e limite importante

Foi criada uma árvore de validação privada com os 30 arquivos do pacote e **o `viewability.cfm` original do backup**, fora do pacote. Nessa composição:

- **42 testes de audiência/privacidade passaram**, sem falhas, executando `node --test --test-reporter=spec --test-skip-pattern='Ads billing beacons'` nos três testes de tracker, controles e i18n.
- Os dois contratos CFML locais passaram: contexto/assinatura/origem/payload e flags por host/GPC/rate limiting. Executados em Lucee local, sem Application, datasource ou rede.
- O teste DOM-ready dos Ads passou usando o script original de produção. Sintaxe dos dois controllers JavaScript de busca conferida.
- O pacote e os arquivos fonte foram conferidos por SHA-256; `git diff --check` passou.

**Não afirmar que a suíte completa de 43 passou no candidato.** Uma tentativa de seleção por regex incluiu também o teste de hardening Ads: os 42 de audiência passaram, e esse teste falhou com `broken creative must not fire billing beacon` (observado 1, esperado 0). Os hashes comprovaram que o teste executou o script inalterado do backup. A seleção focada foi então feita explicitamente por `--test-skip-pattern`; nenhum teste ou código foi alterado para mascarar o resultado. A limitação preexistente dos Ads — imagem quebrada ainda podendo produzir beacon — permanece pendente. O tracker de audiência tem medição própria e seus testes de imagem carregada e segundo contínuo passaram.

Antes da montagem, a suíte de 43 e o teste DOM-ready também passaram contra o checkout local completo, que contém o hardening Ads excluído. Essa evidência não deve ser confundida com a composição candidata. A revisão paralela conferiu os três grupos de arquivos, e o diagnóstico sistemático separou a falha preexistente dos Ads da medição nova.

Não foram executados render completo Adobe ColdFusion, navegador desktop/mobile, requisições ao coletor em produção, nova validação autenticada do Business ou qualquer teste no banco remoto nesta etapa. O painel Business já está publicado, mas a revalidação após instalação SQL continua pendente.

## Próximo checkpoint: publicação com coleta desligada

O candidato **tem defaults desligados**; isso não comprova o estado efetivo de `APPLICATION` ou de eventual override `.local` no servidor. Antes de publicar:

1. Confirmar o pacote/destino de produção e revisar um executor de publicação específico. Este helper apenas prepara artefatos.
2. Revalidar os 31 baselines imediatamente antes da publicação, inclusive a ausência dos 12 novos e o arquivo Ads preservado. Interromper qualquer drift; preservar owner/mode existentes. O backup não autoriza sobrescrever alterações posteriores.
3. Verificar configuração efetiva desligada por host e eventuais overrides, sem imprimir segredos. Os ambientes compartilham o nome de aplicação; não assumir isolamento de estado entre roots. Não ativar coleta, instalar segredo habilitante ou alterar beta/dev implicitamente.
4. Publicar dependências antes de callers: assets/serviços/helpers e catálogos/configuração; depois integrações de slots/busca/modal/home; bootstrap compartilhado e guard de inicialização por último. `banner_delivery` e `banner_slot` exigem publicação coordenada. Definir estratégia para consistência durante substituições, backup/journal e rollback antes de executar.
5. Comprovar hash/HTTP, ausência de coleta e funcionamento das páginas principais. Validar desktop/mobile e continuidade de sessão pelo fluxo autorizado; não reiniciar aplicação/serviços como atalho.

Os controles de privacidade são visíveis mesmo com a coleta desligada e podem guardar a preferência de recusa; isso não significa que o tracker esteja coletando. O bootstrap não emite tracker/contexto se o host não está permitido.

Ativação, proxy confiável, retenção operacional de 90 dias e métricas reais continuam em etapas posteriores. As operações de audiência usarão o DSN `runnerhub`, já confirmado como papel PostgreSQL `runner`. Não alterar `runner_dba` nem o datasource global do Business.
