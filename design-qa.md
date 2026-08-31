# Design QA — criação de campanha de evento

## Resultado

**Aprovado.** O fluxo publicado mantém a direção visual escolhida e deixa a criação da primeira campanha concentrada em quatro passos objetivos.

## Fontes comparadas

- Referência aprovada: `/Users/leonardosobral/.codex/generated_images/01a0301d-89b6-7b33-9881-3c78051713b7/exec-bb5fd31e-8ecc-4ebe-9e5c-ea87d6bec219.png` — 1487 × 1058 px.
- Implementação, investimento: `_codex/audits/2026-08-25-campaign-wizard/implementation-step2.png` — 1609 × 1946 px.
- Implementação, prévia: `_codex/audits/2026-08-25-campaign-wizard/implementation-step4.png` — 1609 × 1946 px.
- Comparação conjunta: `.superpowers/brainstorm/15351-1787667935/content/qa-campaign-wizard.html`.

## Estado verificado

- Conta em análise, com evento vinculado selecionado.
- Evento: LIVE! RUN XP Brasília 2026.
- CPC selecionado: R$ 0,94.
- Orçamento: R$ 100,00.
- Estimativa apresentada: 80–106 cliques.
- Data final sugerida: 10/12/2026, três dias antes do evento.
- Uma posição de exibição selecionada por padrão.

## Comparação visual

- A hierarquia da referência foi preservada: explicação do leilão e controles à esquerda, impacto estimado e prévia à direita.
- Cores, contraste, bordas, tipografia e densidade seguem o sistema visual atual do Business.
- A prévia usa imagem e dados reais do evento vinculado; não há upload de criativo genérico.
- CPC, orçamento e estimativa permanecem visíveis no mesmo passo, conforme solicitado.
- As diferenças de largura e espaçamento são intencionais para acomodar a navegação lateral e o contêiner reais do produto.

## Ajuste identificado durante o QA

Na primeira comparação, métricas e listas antigas ainda apareciam acima do formulário quando a conta possuía uma campanha finalizada. O modo de criação foi corrigido para manter apenas o contexto necessário e o assistente de campanha, inclusive nesse caso.

## Interações verificadas

- Seleção do evento e preenchimento automático do nome interno.
- Avanço e retorno entre os quatro passos.
- Troca do CPC entre R$ 0,56, R$ 0,94 e R$ 1,32.
- Recálculo da faixa estimada de cliques para cada CPC.
- Sugestão da data final baseada na data do evento.
- Renderização da prévia nativa com o evento escolhido.
- Console do navegador sem erros.

O formulário não foi enviado durante o QA, evitando criar uma campanha de teste na conta.
