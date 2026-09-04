# Estratégia territorial — Maratona de Floripa 2026

Data: 2026-09-03

## Decisão apoiada

A nova tela deve ajudar a direção a escolher parceiros com alcance nacional e parceiros regionais complementares, identificando onde cada canal tem escala, concentração ou ausência observada.

Ela deve responder:

1. quais canais têm alcance nacional, multirregional ou regional observado;
2. quais canais lideram ou complementam a venda em cada UF;
3. se uma combinação de parceiros amplia a cobertura territorial ou repete o mesmo perfil;
4. como ROADRUNNERS e MANIADECORRIDA se complementam ou se sobrepõem.

As conclusões descrevem as inscrições pagas de 2026. Associação por cupom não prova incrementalidade, canibalização ou vendas que seriam perdidas sem o parceiro.

## Entrega aprovada

- rota autenticada e imprimível `/relatorios/maratona-floripa-2026/estados/`;
- resumo executivo territorial quase estático;
- classificação transparente de alcance dos canais;
- visão detalhada por UF;
- matriz estado × canal;
- comparação interativa de até três parceiros;
- aprofundamento fixo ROADRUNNERS × MANIADECORRIDA;
- navegação global completa em todas as telas, com a tela atual destacada;
- botão `Visão geral` sempre visível;
- na tela territorial, a aba `Visão geral` fica selecionada inicialmente;
- geração incremental de um único agregado territorial, sem reprocessar pedidos brutos nem reconstruir dossiês.

## Universo e regras

- totais do evento preservam todas as 15.713 inscrições pagas;
- comparações comerciais usam canais com ticket por inscrição acima de R$ 10,00;
- classificação territorial exige ao menos 30 inscrições e cobertura válida de UF de 70%;
- UF relevante para capilaridade tem ao menos cinco inscrições do canal;
- região relevante tem ao menos cinco inscrições do canal;
- `nacional`: pelo menos 10 UFs relevantes, quatro regiões relevantes e no máximo 40% das inscrições válidas na principal UF;
- `multirregional`: pelo menos cinco UFs relevantes, três regiões relevantes e no máximo 60% na principal UF;
- `regional`: demais canais com base e cobertura suficientes;
- `evidência insuficiente`: menos de 30 inscrições ou cobertura de UF abaixo de 70%;
- células estado × canal abaixo de cinco inscrições não aparecem em detalhes;
- nomes de canais são apresentados em caixa alta;
- rankings são decrescentes por inscrições ou valor, conforme o indicador;
- gráficos com mais de dez categorias usam Top 10 + `Outros`, mantendo `Outros` no final.

## Conteúdo da tela

### Visão geral

- KPIs do evento e do universo territorial válido;
- distribuição de inscrições por UF;
- ranking de alcance dos parceiros;
- matriz das dez UFs e dez canais de maior volume;
- leitura executiva de parceiros âncora, reforços e lacunas.

### Estado

- seletor de UF;
- total de inscrições, valor bruto, participação no evento e ticket;
- canais líderes por inscrições e valor;
- participação de cada canal no total e no universo comercial da UF;
- mix de distância e fase;
- células abaixo do limite permanecem apenas nos totais agregados.

### Comparar parceiros

- seleção de um a três canais;
- capilaridade conjunta;
- UFs relevantes compartilhadas e exclusivas;
- semelhança geográfica;
- tabela por UF com inscrições e participação de cada parceiro;
- URL compartilhável com a seleção.

### ROADRUNNERS × MANIADECORRIDA

- ROADRUNNERS será apresentado como âncora nacional de maior escala e capilaridade;
- MANIADECORRIDA será avaliado como reforço de Sudeste, especialmente SP e MG;
- a forte sobreposição territorial e de perfil será explícita;
- a recomendação condicionará a manutenção dos dois a mandatos territoriais diferentes, sem alegação causal.

## Dados, privacidade e atualização

O novo `states/strategy.json` será derivado somente de:

- `general.json` para os totais do evento;
- `channels/index.json` e dossiês para escala, cobertura, escopo e semelhança geográfica;
- `territories.json` para as células estado × canal × distância × fase;
- `portfolio/summary.json` para o benchmark publicado de semelhança geográfica.

O artefato não conterá cidade, semana, pedido, inscrição individual ou dado pessoal. Um recibo no manifesto fixará hashes das dependências e da regra de transformação. Uma atualização territorial reescreverá apenas `states/strategy.json` e `manifest.json` quando as demais fontes congeladas permanecerem iguais.

## Navegação

Todas as páginas principais mostrarão, no mesmo grupo de ações:

- Visão geral;
- Estados;
- Portfólio 2027;
- Simulador;
- Dossiês;
- Explorador;
- Gerar PDF.

O destino correspondente à tela atual terá `aria-current="page"` e destaque visual. Em telas estreitas, o topo deixa de ser fixo e os botões quebram em linhas para que todos permaneçam visíveis.

## Critérios de aceite

- ROADRUNNERS e MANIADECORRIDA são classificados e comparados com números reconciliados;
- o par expõe sobreposição forte quando sua similaridade superar o p90 geográfico;
- totais de UF reconciliam com as inscrições válidas e não alteram o total geral;
- toda classificação expõe os limiares usados;
- detalhes pequenos são suprimidos sem apagar os totais;
- a nova tela carrega apenas `states/strategy.json`;
- todas as páginas autenticadas exibem a navegação completa e destacam a atual;
- desktop, celular, impressão, hashes, privacidade e CFML são verificados;
- `/inscricoes/` permanece byte a byte inalterada.
