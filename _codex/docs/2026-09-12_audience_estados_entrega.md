# Audiência — classificação de entrega sem anúncio

## Estado do lote

**Publicado em 12/09/2026 às 09:47:50 de Brasília**, após autorização do usuário.
Os quatro arquivos foram conferidos em produção e houve validação no site e no
Business: [recibo, backup e limites](2026-09-12_audience_delivery_states_publicado.md).
Nenhum SQL novo ou acesso direto ao banco de produção. As promoções estáticas
publicadas em 11/09 permanecem no ar e não integram este lote.

Pacote restrito aos quatro arquivos runtime:
`_codex/releases/2026-09-12_audience_delivery_states_linux.tar.gz`, SHA-256
`7e93720b0bff35e2dc554ace1c2f341acb55075862c6ba0a2396e7ca440b1f7d`.
Conteúdo e hashes individuais conferidos contra o candidato revisado:
[manifesto](2026-09-12_audience_delivery_states_manifest.json).

## Correção

Os três emissores de posições sem anúncio tratavam todo retorno diferente do
texto literal `error` como vazio. Os serviços, porém, retornam `fallback` quando
há exceção, além de estados de rejeição de contexto/candidato e filtragem. Isso
podia apresentar problemas de entrega como falta de campanha disponível.

A tradução passa a usar o contrato de audiência existente:

| Situação sem entrega válida | Estado de audiência | Coluna no Business |
| --- | --- | --- |
| Nenhuma campanha elegível (`no_candidate`) | `empty` | Vazias |
| Posição desabilitada, inclusive retorno `disabled` | `disabled` | Indisponíveis |
| Tráfego filtrado antes do leilão (`filtered_traffic`) | `not_applicable` | Indisponíveis |
| Falha, resposta inválida/desconhecida ou criativo servido que não passou na validação | `error` | Erros |

A requisição ao serviço continua sendo contada quando tentada. Não se transforma
uma oportunidade em renderização: o marcador continua oculto e sem área. Ads
válidos mantêm seleção, criativo, IDs, token, renderização e exposição anteriores.
Não há impressão faturável nem consumo de créditos criado por esta correção.

Os números antigos não serão reclassificados: não há informação detalhada
suficiente nos eventos de audiência já gravados para separar com segurança os
`empty` legítimos das falhas classificadas anteriormente como vazias.

## Escopo

RoadRunners: três emissores e marcador compartilhado, testes e documentação.
Business: somente documentação; consultas e tela existentes já recebem esses
estados. Opt-out/GPC, retenção, DSN `runner`, permissões, autenticação, configuração,
cobrança, histórico e todos os writers de `tb_log` ficam preservados.

Runtime RoadRunners: `includes/analytics/slot_marker.cfm`,
`includes/ads_v1/banner_delivery.cfm`, `includes/estrutura/home_sidebar_promos.cfm`
e `includes/eventos_ads.cfm`. Suporte local: `_codex/docs/audience-delivery-states.md`,
`_codex/scripts/test_audience_delivery_states_local.mjs` e
`_codex/tests/audience-delivery-state-contract.cfm`.

Este lote **não** reserva altura nem acrescenta banners institucionais às posições
colapsadas. Portanto não resolve a observação visual de uma área que não existe
no layout. Essa etapa precisa definir uma área real e como separar a nova amostra
da medição histórica de slots colapsados.

## Publicação e reversão

Foram enviados somente os quatro arquivos runtime, após comparação com a versão
do servidor e backup privado. Marcador compartilhado primeiro, emissores depois.
Os emissores preservam um estado conservador para tolerar sobreposição com a
versão anterior do marcador. Reversão: emissores anteriores primeiro, marcador
anterior depois, sem migração ou reinicialização de sessões.

Não incluir o cache geográfico pendente: [rechecagem do provedor](2026-09-12_audience_geo_diagnostico.md).

## Validação local, anterior à publicação

- Business, sem mudanças runtime: 5/5 testes JavaScript e 51 assertivas SQL
  passaram. PostgreSQL descartável local, sem acesso ao banco de produção.
- A primeira tentativa SQL foi impedida pelo sandbox ao criar memória
  compartilhada; a execução local autorizada passou e encerrou o cluster.
- TDD CFML: no snapshot anterior, os três fragmentos reais reproduziram `fallback`
  ou `invalid_candidate` como `empty`. No candidato, 26 casos passaram, incluindo
  todos os status retornados pelos serviços, estado desconhecido/vazio, posição
  desabilitada, `served` reprovado, os três emissores, chamadores comuns sem o
  novo campo e atributos HTML preservados. A fixture extrai os fragmentos reais
  e executa o marcador real; não reimplementa o classificador.
- Controlador repetiu o CFML no candidato e novamente nos arquivos aplicados:
  26/26, exit 0. Runtime de teste: Lucee/CommandBox local, sem Application da
  aplicação, datasource, servidor HTTP ou rede. Não equivale à homologação do
  Adobe ColdFusion de produção ou de uma página completa.
- Após a aplicação: 87/87 testes Node do RoadRunners; sintaxe do runner e
  `git diff --check` passaram. Os sete arquivos aplicados conferem, byte a byte,
  com os hashes do candidato revisado. Alterações preexistentes em CPC/Ads não
  fizeram parte do patch.
- Revisão independente de especificação/qualidade e revisão final integrada:
  aprovadas, sem achados acionáveis. Compatibilidade conferida entre marcador
  antigo/novo, chamadores, tracker, coletor e agregação existente do Business.
- O pacote tem exatamente quatro membros runtime, todos com hashes conferidos.
  O preflight somente leitura confirmou que os quatro arquivos de produção
  coincidiam com o snapshot anterior. Repetir essa comparação no momento do
  deploy: o preflight não autoriza sobrescrever mudanças posteriores.
- Na etapa local, nenhum evento novo foi enviado para produção. Não houve
  validação de ingestão nem leitura autenticada do Business nessa etapa; a aba
  temporária sem sessão foi fechada sem tentar login. A navegação autenticada e
  a conferência do Business na publicação posterior estão no recibo acima.

Snapshot anterior e candidato: `/private/tmp/rr-audience-empty-state.nIlvuC`.
Evidência de execução e revisões preservada no ledger específico em
`.superpowers/sdd/2026-09-12-audiencia-estados-entrega/`. Nenhum branch, commit,
push ou reinício de serviço foi realizado.
