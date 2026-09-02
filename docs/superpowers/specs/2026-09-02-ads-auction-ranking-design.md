# Ranking e cobrança do leilão de publicidade

## Objetivo

Restaurar no fluxo canônico de publicidade a inteligência que existia no
modelo legado: relevância regional e lance por clique determinam a ordem dos
anúncios, e as posições da página inicial são consequência do ranking, não uma
escolha do anunciante.

## Problema confirmado

O seletor canônico atual filtra campanhas por região, mas ordena por
`campaign_placements.priority` e sorteio ponderado. O `cpc_bid` não participa
do ranking. A página inicial também executa dois leilões independentes, um para
cada placement, e o preço gravado na entrega é sempre o lance máximo.

Com isso, uma campanha de R$ 0,56 pode ocupar a primeira posição enquanto uma
campanha de R$ 1,32 ocupa a segunda, sem que aderência regional ou lance tenham
explicado essa ordem.

## Contrato restaurado

### Elegibilidade

- Campanha nacional (`target_region_code IS NULL`) pode concorrer em qualquer
  contexto brasileiro.
- Campanha regional só pode concorrer quando `target_region_code` coincide com
  a UF do contexto.
- Permanecem todas as travas atuais de conta, status, período, dispositivo,
  saldo, orçamento, frequência, evento, criativo e placement.

### Pontuação

Para campanhas CPC de evento:

```text
pontuação = lance máximo
          × 2,0 se a segmentação regional coincide com a UF do contexto
          × 1,2 se a campanha é nacional
          × 1,2 se a UF do evento coincide com a UF do contexto
```

Os multiplicadores preservam o comportamento do modelo legado. Uma campanha
regional aderente recebe vantagem real, mas um lance suficientemente maior
ainda pode superar outra campanha. Empates usam sorteio apenas como último
critério.

### Posições

- O anunciante escolhe a superfície **Página inicial** uma única vez.
- Ao salvar, o Business associa a campanha aos dois placements técnicos da
  home para compatibilidade.
- O RoadRunners seleciona primeiro a maior pontuação e depois a próxima,
  excluindo a campanha já entregue. Assim o spot 1 e o spot 2 refletem uma
  única ordem de leilão.
- Busca, lista por estado e página do evento continuam superfícies separadas.

### Preço do clique

- `cpc_bid` é o teto, não o preço obrigatório.
- A entrega guarda o menor lance que a campanha vencedora precisaria ter para
  superar a pontuação da próxima campanha elegível, acrescido de R$ 0,01 e
  ajustado pelo fator de relevância da vencedora. O preço nunca supera o
  próprio lance.
- Sem concorrente inferior, aplica-se o piso legado equivalente a R$ 0,51.
- A elegibilidade reserva capacidade para o lance máximo; o clique debita
  exatamente o `price_snapshot` calculado e imutável da entrega.
- O serviço de entrega ativa o snapshot de leilão dentro da própria transação.
  Chamadores antigos continuam usando o comportamento anterior durante a
  transição, sem mudança de assinatura.

## Responsabilidades

### RoadRunners

É dono da regra de elegibilidade, pontuação, seleção, preço e recibo imutável
da entrega. A migration preserva a assinatura canônica do seletor e torna o
novo snapshot opt-in durante o deploy.

`cpcPlacements` continua sendo o kill switch por superfície. A antiga lista
manual `cpcCampaignIds` deixa de autorizar campanhas: depois do piloto, a
aprovação da RunnerHub e os estados canônicos de conta, evento, campanha,
saldo e orçamento são a autorização efetiva para participar do leilão.

### Business

É consumidor do contrato. Mostra quatro superfícies compreensíveis, expande a
seleção de Página inicial para os dois placements técnicos e explica que a
posição resulta de região + lance. Não calcula ranking nem preço.

## Compatibilidade e deploy

1. Aplicar a migration do RoadRunners, que adiciona o novo contrato sem remover
   o anterior.
2. Publicar o serviço RoadRunners usando o novo contrato.
3. Publicar o Business com a superfície única de Página inicial.

Campanhas antigas que tenham apenas um placement de home continuam elegíveis e
são normalizadas pela migration para receber os dois placements técnicos.

## Critérios de aceite

- Em uma mesma UF e com a mesma aderência, o maior lance ocupa a posição
  superior.
- Uma campanha regional aderente recebe os multiplicadores legados.
- O spot 2 nunca repete a campanha entregue no spot 1.
- O preço nunca supera o lance e usa o concorrente seguinte ou o piso.
- O Business não oferece escolha entre primeira e segunda posição da home.
- O resumo conta Página inicial como um único local.
- Campanhas e contratos antigos continuam funcionando durante o deploy.
