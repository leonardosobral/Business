# Auditoria do passo 4 — locais de exibição

Data: 2026-09-02

## Escopo

Tela de edição de campanha, passo 4 de 4, na resolução fornecida pelo usuário.

## Objetivo do usuário

Entender onde a campanha poderá aparecer e escolher superfícies de divulgação sem precisar conhecer a estrutura interna dos slots.

## Passo auditado

1. **Escolher locais de exibição — saúde ruim.** A grade em duas colunas combina checkbox, miniatura e texto em um espaço estreito, quebrando palavras e impedindo leitura rápida. “Página inicial” e “Página inicial - segunda posição” parecem escolhas comerciais independentes, embora sejam posições de uma mesma superfície. A prévia mostra somente uma posição e não explica a consequência da seleção.

## Regra observada no código

- Os dois slots da home são placements independentes.
- A home seleciona o primeiro slot e depois o segundo, excluindo do segundo a campanha entregue no primeiro.
- O seletor atual usa prioridade administrativa e sorteio ponderado. O CPC é preço de clique e requisito de elegibilidade, não fator de ranking.
- País, dispositivo e região são filtros de elegibilidade, não componentes de score.

## Recomendações

1. Expor “Página inicial” uma única vez para o anunciante e mapear internamente a seleção para os dois slots.
2. Preencher primeiro e segundo lugares a partir do mesmo conjunto elegível, usando a ordem do leilão.
3. Apresentar quatro superfícies simples: Página inicial, Busca, Página do estado e Página do evento.
4. Trocar a grade atual por linhas ou cards largos, com ícone/miniatura menor, título, descrição curta e uma prévia vinculada à superfície.
5. Explicar antes do salvamento que o anunciante escolhe onde concorrer, mas a posição final é determinada pelo ranking.

## Acessibilidade e limites

A captura confirma problema de reflow e legibilidade. Ela não permite confirmar navegação por teclado, foco visível, leitura por tecnologia assistiva nem contraste calculado; esses pontos exigem teste funcional após a alteração.

## Evidência

- `01-step-4-atual.png`
