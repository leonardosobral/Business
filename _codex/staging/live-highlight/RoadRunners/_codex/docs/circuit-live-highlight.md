# Destaque de etapa na agregadora LIVE!

## Comportamento aprovado — 12/09/2026

Em `/circuito/live-run-xp/`, a aba Próximos pode promover uma única etapa para o
primeiro lugar, com o rótulo **Etapa em destaque** e uma borda discreta. Todas as
outras provas continuam na mesma listagem, uma vez cada, na ordem original de
data. As contagens, os links, a aba Realizados e os demais circuitos são mantidos.
Não há seletor de cidade, filtro, nova tela nem redirecionamento automático.

A seleção usa o `REQUEST.LocationContext` existente, resolvido pelo include
`includes/location.cfm` quando ainda não está disponível. A localização é uma
estimativa do serviço já usado pelo portal; pode diferir de onde o visitante está
e não representa a cidade segmentada pelo Google Ads.

1. Escolher a próxima prova da cidade e UF estimadas.
2. Sem essa correspondência, escolher a próxima prova da mesma UF.
3. Sem localização brasileira utilizável ou prova elegível no estado, manter a
   ordem de datas sem destaque.

A comparação de cidade ignora acentos, caixa, espaços nas extremidades e separa
pontuação por espaços. Exige a mesma UF para não confundir cidades homônimas.
O candidato precisa ter datas válidas, início hoje ou no futuro, término não
anterior ao início, ID/tag válidos e não estar cancelado. Isso não é uma nova
validação de disponibilidade de inscrições. Em empate, a data de início e depois
o ID determinam a escolha. Provas não elegíveis continuam na listagem original.

## Implementação e limites

- `circuito/index.cfm`: resolve o contexto apenas no circuito LIVE!, antes do
  `head`, e envia `Cache-Control: private, no-store` para não compartilhar HTML
  personalizado. Falha de resolução mantém a lista sem personalização.
- `circuito/live_highlight.cfm`: seleciona um índice por requisição e reutiliza
  `includes/card_evento_live.cfm`, sem modificar a query compartilhada em cache.
  O card promovido é omitido do segundo loop, preservando a ordem dos restantes.
- A compilação de acentos usa `java.text.Normalizer` e `String.replaceAll` para
  remover marcas Unicode; não depende do suporte de `reReplace` a `\p{M}`.
- Não há alteração de banco, configuração de geolocalização, Google Ads, coleta
  de audiência ou atribuição de vendas. A cidade do evento continua distinta da
  localização aproximada do visitante. O fluxo segue agregadora → evento → LIVE!.
- Os ajustes de rodapé existentes em produção no `index.cfm` foram preservados.

## Verificação

O teste offline usa o card real e uma query sintética, sem bootstrap da aplicação,
banco ou rede. Cobre cidade, acentos, estado, homônimos, ausência de localização,
país estrangeiro, fallback, entrada inválida, outro circuito e lista vazia.
Confere identidade e posição do destaque, unicidade de todos os links, ordem dos
demais e imutabilidade da query.

```sh
bash _codex/scripts/test_circuit_live_highlight.sh
```

O harness requer o runtime CommandBox já instalado na máquina de desenvolvimento
e imprime a pasta temporária dos HTMLs usados na revisão visual desktop/mobile.
Compilar os dois templates no Adobe ColdFusion de produção em diretório privado
antes de publicar. A publicação deve colocar o include novo antes do `index.cfm`,
conferindo hashes e guardando backup do arquivo existente; rollback restaura o
`index.cfm` antes de retirar o include. Não publicar o checkout inteiro.
