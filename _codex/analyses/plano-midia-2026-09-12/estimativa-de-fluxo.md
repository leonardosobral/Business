# Estimativa de fluxo — piloto de 30 dias

**Referência de planejamento: 2.250 sessões, 5.400 páginas vistas e 1.125 sessões qualificadas com R$ 2.700 de mídia.** Se os R$ 300 de reserva também forem usados, mantendo a mesma eficiência, a simulação central passa para 2.500 sessões, 6.000 páginas vistas e 1.250 sessões qualificadas.

São simulações condicionais, preparadas em 12/09/2026. Não são resultados já obtidos, previsões do gerenciador de anúncios ou garantia de entrega. O retorno aqui é fluxo medido, sem depender de pedidos, inscrições ou receita.

## Investimento considerado

R$ 1.800 em Meta + R$ 900 em Google Pesquisa = R$ 2.700. A reserva de R$ 300 permanece fora da tabela principal. A campanha precisa efetivamente consumir o valor simulado; se for interrompida, o volume deve ser recalculado pelo gasto real. A janela é o piloto de 30 dias, incluindo preparação e veiculação conforme o plano.

## Premissas e resultados

| Cenário ilustrativo | Custo por sessão medida | Páginas por sessão | Taxa qualificada | Sessões | Páginas vistas | Sessões qualificadas |
|---|---:|---:|---:|---:|---:|---:|
| Cauteloso | R$ 1,80 | 1,8 | 40% | 1.500 | 2.700 | 600 |
| Central | R$ 1,20 | 2,4 | 50% | 2.250 | 5.400 | 1.125 |
| Favorável | R$ 0,75 | 3,0 | 55% | 3.600 | 10.800 | 1.980 |

Todos os custos e taxas da tabela são premissas escolhidas para explorar sensibilidade, não benchmarks de mercado nem custos consultados nas contas. Não há probabilidade atribuída a cada cenário. A faixa pode ser ultrapassada em qualquer direção; os três cenários não constituem intervalo de confiança.

O custo por sessão é o gasto combinado dos dois canais dividido pelas sessões medidas atribuídas ao piloto. Não equivale ao CPC externo. Cliques podem não se transformar em sessões medidas por desistência antes do carregamento, bloqueio de coleta, repetição ou diferença de definição. Se usarmos CPC para uma previsão posterior, será necessário estimar também a relação entre cliques e sessões confirmadas.

Fórmulas:

- Sessões = investimento efetivo ÷ custo por sessão medida.
- Páginas vistas = sessões × páginas por sessão.
- Sessões qualificadas = sessões × taxa de qualificação.
- Custo por sessão qualificada = investimento ÷ sessões qualificadas.

No cenário central: R$ 2.700 ÷ R$ 1,20 = 2.250 sessões; 2.250 × 2,4 = 5.400 páginas vistas; 2.250 × 50% = 1.125 sessões qualificadas. O custo por sessão qualificada seria R$ 2,40. A distribuição real ao longo dos dias não será necessariamente uniforme.

## Como a audiência atual informa as premissas

O snapshot autenticado do portal, consultado em 12/09/2026 com última recepção às 11:26 Brasília, mostrou 4.490 aberturas e 1.329 sessões: **3,38 páginas por sessão**. Também mostrou 752 sessões qualificadas: **56,6%**. Esses índices usam todo o período observado desde 08/09 às 20:56, incluindo os dias parciais 08 e 12; há somente três dias completos dentro desse intervalo.

Os dados observados abrangem todas as regiões e origens mensuradas. Não representam exclusivamente público novo adquirido por mídia em SC. A premissa central usa 2,4 páginas/sessão e 50% de qualificação para admitir uma navegação menor que a mistura atual; essa escolha não comprova que o cenário será conservador na prática.

Sessão qualificada mantém a definição do painel próprio: pelo menos 30 segundos ativos OU duas páginas distintas no recorte. Não exige compra e não é automaticamente equivalente à sessão engajada do GA4. Páginas vistas usa aberturas confirmadas, não o campo separado de páginas com atividade. Sessões não são visitantes únicos; retornos e duplicidades entre canais precisam de tratamento antes de falar em novos corredores.

## Medição e recalibração

1. Identificar cada anúncio com UTM de campanha e criativo, preservando a origem nos links internos.
2. No Business, registrar sessões e qualificadas da campanha; conciliar gasto no mesmo período e fuso. O painel atual trabalha com janelas 7/30/90 dias, incluindo dia corrente parcial.
3. A seção Aquisição exibe **páginas com atividade**, não pageviews exatos por UTM. Para verificar a projeção de páginas vistas da campanha, acrescentar uma leitura agregada de `pageviews` por campanha a partir da consulta existente ou usar outra fonte já validada com a mesma definição. O agregado geral de aberturas não isola o resultado pago. Essa leitura adicional ainda não foi executada ou implementada nesta tarefa.
4. Recalcular após uma primeira parcela de R$ 300–500 efetivamente gasta, desde que a coleta esteja íntegra. É um checkpoint de calibração, não amostra suficiente para declarar vencedor. Atualizar separadamente custo por sessão, páginas por sessão e qualificação; pequenas amostras devem continuar identificadas.
5. Relatar o fluxo atribuído às campanhas separado do fluxo total do site. Não adicionar automaticamente esses números ao tráfego atual nem chamá-los de incremento causal: parte pode substituir acessos que aconteceriam organicamente. Não há estimativa de retornos futuros adicionais nesta simulação.

Para tornar a previsão mais informada antes do lançamento, a etapa seguinte é consultar as estimativas das palavras-chave e segmentação na conta Google Ads e os sinais disponíveis na conta Meta. O Google explica que previsões dependem de orçamento, lances, sazonalidade e outros fatores; esta simulação não utilizou uma previsão de conta ([Google Ads — previsões do Planejador](https://support.google.com/google-ads/answer/3022575)).

## Fontes e registro

- [Painel de audiência](https://business.roadrunners.run/portal/audiencia/), snapshot da análise anterior, não uma nova consulta ao vivo.
- [Evidências observadas](/Users/Shared/Projects/RunnerHub/Business/_codex/analyses/plano-midia-2026-09-12/evidencias.json).
- [Consulta de aquisição](/Users/Shared/Projects/RunnerHub/Business/portal/audiencia/queries/acquisition.sql:1): calcula `pageviews` e `active_pages` separadamente.
- [Cenários e cálculos](/Users/Shared/Projects/RunnerHub/Business/_codex/analyses/plano-midia-2026-09-12/estimativa-de-fluxo.json).

Nenhuma campanha foi ativada e nenhum gasto foi realizado.
