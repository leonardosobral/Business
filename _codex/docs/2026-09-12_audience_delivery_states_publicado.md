# Estados de entrega — publicação de 12/09/2026

## Resultado

Publicado em **12/09/2026 às 09:47:50 de Brasília** (`2026-09-12T12:47:50Z`,
relógio do servidor), após o usuário dizer “publique”. Última conferência remota:
09:53:08 de Brasília. Sem reinício de serviço, SQL ou acesso direto ao banco.

No RoadRunners, apenas os quatro arquivos do [manifesto](2026-09-12_audience_delivery_states_manifest.json)
foram publicados, nesta ordem: `includes/analytics/slot_marker.cfm`,
`includes/ads_v1/banner_delivery.cfm`, `includes/estrutura/home_sidebar_promos.cfm`
e `includes/eventos_ads.cfm`. Business: nenhum arquivo runtime alterado.

O pacote tem SHA-256 `7e93720b0bff35e2dc554ace1c2f341acb55075862c6ba0a2396e7ca440b1f7d`
e exatamente esses quatro membros. As respostas de ausência de candidato seguem
como `empty`; falhas/respostas inválidas passam a `error`; desativação e tráfego
filtrado ficam indisponíveis. O contrato completo está na [entrega](2026-09-12_audience_estados_entrega.md).

## Backup e integridade

- Host: `ssh.runnerhub.run`; webroot: `/var/www/roadrunners.com.br`.
- Backup privado: `/var/backups/rr-audience-delivery.lumqNj`.
- Contém pacote, candidato, `before/`, hashes/metadados anteriores, 34 hashes
  de arquivos protegidos, `runtime.tsv`, `publish.sh` e `published.log`.
- Publicador local: `/private/tmp/rr-delivery-release.nZx7le/publish.sh`, adaptado
  do publicador anterior. A sintaxe Bash passou. Arquivos são preparados na pasta
  privada, no mesmo filesystem, antes de cada substituição atômica no webroot.
- Os quatro hashes anteriores coincidiram com produção; backups foram conferidos
  antes das substituições. Proprietário, grupo e modo foram preservados.
- Após publicar e novamente após navegar no site: **4/4 hashes e metadados
  corretos; 34 arquivos protegidos inalterados**. Apache e `cf2023` ativos.
- Proteções abrangem configurações, autenticação, Ads/serviços de entrega,
  cobrança, coletor, tracker, localização, backend de evento e relatório Business.

Se necessário, restaurar exclusivamente os três emissores de `before/` e depois
o marcador, preservando metadados e conferindo os hashes do manifesto. Não
restaurar diretórios completos. Não há reversão SQL nem exclusão de eventos.
Nenhum rollback foi necessário.

## Validação em produção

Chrome já autenticado; a home apresentou contexto de audiência `prod`, `home`,
`isInternal=true`. Não houve login, troca de conta, clique em anunciante ou
alteração de configuração para forçar cenários. Foram feitas abertura e rolagem
normais da home e navegação pelo atalho 5K para a busca.

- Home desktop: os três anúncios nativos continuaram `filled`; o banner lateral
  continuou `house`. Criativos carregados e dimensões positivas. O banner Avaí Run
  e os anúncios do feed foram conferidos visualmente. Nenhum erro de console.
- Busca desktop: `rr-search-events-native` veio `empty`, `requested=true`,
  `served=false`, `hidden=true` e área zero. Isso exercitou o novo caminho sem
  entrega no ColdFusion real. A lateral manteve anúncio e banner renderizados.
  A posição mobile presente no HTML continuou sem área no viewport desktop.
- Os testes não provocaram falhas no motor de Ads. A matriz de erros/inválidos
  permanece coberta pelos 26 casos CFML locais, não por falhas forçadas em prod.

Business: recorte de 7 dias, contexto comercial, todas as UFs, Home, produção,
incluindo acessos internos. Depois da navegação, as quatro linhas desktop
avançaram nas contagens abaixo; última recepção exibida às **09:51 de Brasília**.

| Posição desktop da home | Registradas antes → depois | Montadas antes → depois | Visíveis antes → depois |
| --- | ---: | ---: | ---: |
| Banner lateral | 202 → 203 | 175 → 176 | 78 → 79 |
| Nativo lateral | 202 → 203 | 13 → 14 | 9 → 10 |
| Nativo principal | 199 → 200 | 59 → 60 | 30 → 31 |
| Nativo secundário | 200 → 201 | 13 → 14 | 7 → 8 |

São números agregados do recorte, compatíveis com a navegação interna observada,
não um relatório individual por visitante nem projeção de inventário comercial.
No recorte Busca, o painel manteve a coluna de vazias disponível e exibiu 65
vazias para o nativo desktop; não houve baseline desse recorte para atribuir um
delta isolado à navegação desta publicação.

A aba temporária do site foi fechada. O Business ficou no endereço original,
autenticado, com 7 dias, contexto comercial, todas as UFs/páginas/dispositivos,
produção e **internos desmarcados**. Nenhum viewport foi sobrescrito. Duas leituras
por seletor de formulário excederam o prazo da ferramenta; o estado final foi
conferido pelos campos do formulário no DOM, sem alterar sessão ou aplicação.

## Preflight e limites

Conferência independente: sete hashes locais, quatro membros/payloads do pacote,
SHA-256 do arquivo, **26/26 casos CFML e 87/87 testes Node**, mais sintaxe do runner.
Os hashes locais continuaram idênticos ao candidato após a publicação. Não houve
novo patch de produto durante o deploy. As alterações de CPC/Ads preexistentes
nos checkouts não entraram no pacote.

Esta publicação não adiciona área a slots colapsados, não reclassifica histórico
e não altera contadores de cobrança. A validação visual desta publicação foi em
desktop; a regra de mídia mobile possui cobertura local, mas não houve nova
homologação móvel ponta a ponta neste lote. Opt-out/GPC, DSN `runner`, permissões
de `runner_dba`, retenção e todo `tb_log` permanecem como estavam.

A UF física continua com a pendência já diagnosticada do provedor; o cache
negativo local não foi publicado. O piloto de área institucional, a operação
de retenção pelo DBA e as demais etapas do plano continuam separados deste lote.
