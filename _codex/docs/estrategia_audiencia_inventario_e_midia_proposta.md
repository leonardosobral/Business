# Plano — audiência e inventário do RoadRunners no Business

**Revisão de escopo — 12/09/2026:** por solicitação do usuário, a segunda parte do plano, de mídia e crescimento, foi retirada desta tarefa e está sendo tratada em outra frente. Não fazem parte das próximas entregas aqui: criação ou compra de mídia, verba, criativos externos, testes A/B de aquisição, escolha de canais, remarketing ou expansão regional. A mensuração de origem/UTM já existente permanece; nenhuma funcionalidade, coleta ou dado é removido por esta revisão. A outra frente não foi alterada.

**Simplificação aprovada em 12/09/2026:** o usuário dispensou o versionamento persistido de layout. Não criar campo, filtro, migração ou subsistema para distinguir versões de apresentação; mudanças podem ser tratadas como nova campanha ou otimização da campanha existente. Prosseguir as demais pendências de mensuração. Não atribuir uma campanha fictícia às peças institucionais sem campanha.

Estado e próximas entregas: [escopo e pendências de audiência em 12/09](2026-09-12_audiencia_escopo_e_pendencias.md). A coleta e o painel estão ativos em produção; a execução da rotina de retenção e a resolução da UF física são pendências independentes, não bloqueios para exibir contagens.

Decisões preservadas desde 07/09: **opt-out**, respeitando GPC e oferecendo recusa, e **90 dias de retenção para eventos detalhados**. Uma política maior para agregados não foi aprovada nem implementada. O [fechamento de 07/09](2026-09-07_audiencia_painel_finalizacao.md) é histórico, não o estado atual de implantação.

Este documento conserva as definições e requisitos de mensuração da proposta original. O diagnóstico inicial abaixo não é uma medição atual do tráfego de produção nem uma lista de falhas ainda abertas. Itens propostos, como retorno em sete dias e previsão de entrega, não estão implicitamente incluídos no painel atual. Funil de aquisição paga e importação de gastos não são entregas desta tarefa.

## Decisão recomendada

Consolidar no Business a área de **Audiência e inventário**, com coleta própria no RoadRunners e ligação com os anúncios existentes. Estabelecer uma base confiável de audiência, posições e exposição para conhecer a capacidade real do site, com recortes por UF e família de página. A previsão comercial de inventário observado continua neste plano; planejar ou executar aquisição de público, não.

O resultado operacional deve responder:

- Quantas visitas qualificadas recebemos de SC, SP e das demais UFs?
- Quantas oportunidades cada posição teve, com ou sem campanha, e quantas atingiram o critério de visibilidade?
- Que parte da capacidade veio de home, estado, busca, evento, perfil, notícia e vídeo, em cada dispositivo?
- Por que uma campanha entrega pouco: audiência, posição inexistente/oculta, falta de elegibilidade, disputa, erro ou exposição curta?
- Qual capacidade observada podemos oferecer a um anunciante, distinguindo exposição medida de projeção?

## Diagnóstico inicial do código — referência histórica

| Evidência local | Consequência para a estratégia |
| --- | --- |
| O painel Ads soma impressões visíveis, cliques válidos, cliques faturáveis e custo de campanhas EVENT/CPC. Entregas aparecem separadamente. | Já existe parte da base comercial; o painel não representa toda a audiência nem os espaços sem campanha. |
| O código de visibilidade usa 50% por 1 segundo, mas não trata a aba oculta nem confirma que a imagem carregou. | A regra precisa de validação e ajustes antes de servir de base à previsão comercial. |
| A UF passada ao Ads pode vir da página estadual, filtro de busca, perfil ou localização inferida. | Não equivale exclusivamente à localização do visitante. |
| “Eventos visitados” lê os últimos 500, 1.000 ou 3.000 registros de eventos e aplica filtros depois. Cidade/estado vêm do cadastro do evento. | É diagnóstico amostral de acessos a eventos, inadequado como total do site ou audiência por UF. |
| Os banners HOUSE também têm métricas canônicas, mas vinculadas a campanhas; várias superfícies reutilizam a mesma chave de banner. | É necessário identificar cada posição física e registrar oportunidades sem anunciante. |
| Há posições simuladas em desenvolvimento ou comentadas no código; o nativo lateral também tem condição de login. | A existência de um nome de slot em documentação não comprova capacidade ativa. |
| A estimativa do assistente deriva de orçamento dividido pelo lance, com uma faixa inferior de 75% desse resultado. | Ela informa quantos cliques o orçamento poderia pagar, sem prever quantos o site consegue entregar. |
| Notícias têm IDs próprios e vídeos podem abrir em modal sem mudar a URL. | Pageviews isolados não cobrem consumo editorial e reprodução de vídeos. |

A baixa entrega da Avaí justifica investigar o funil, mas não permite atribuir toda a diferença a falta de visitantes. Esta proposta não usa os pequenos snapshots históricos dessa campanha como previsão de SC.

## Escopo ativo — medir e tornar o inventário utilizável

### Escolha de abordagem

Recomendo ampliar a infraestrutura existente com uma coleta própria e agregados consumidos pelo Business. Ela permite medir posições vazias, regras locais e campanhas no mesmo contexto. Exige manutenção do coletor e validação das métricas, mas atende diretamente à decisão comercial.

Uma alternativa é integrar relatórios de um serviço de analytics ao Business. Pode acelerar métricas gerais de navegação, porém ainda exigiria instrumentação própria de posições e integração com Ads. O GA existente pode funcionar como comparação auxiliar; o uso operacional não deve depender de abrir sua interface.

Usar somente logs do servidor ajuda a diagnosticar robôs, erros e requisições, mas não comprova renderização ou visibilidade no navegador. Deve ser fonte complementar.

### Vocabulário do painel

| Métrica | Regra proposta | Decisão que apoia |
| --- | --- | --- |
| Página visualizada | Navegação identificada e confirmada no navegador, quando a página se torna visível; chamadas de partial/API não criam outra página. | Audiência e jornada. |
| Posição prevista | Posição declarada no template, com estado aplicável, oculta, desativada ou não aplicável. | Cobertura e capacidade potencial do layout. |
| Oportunidade aplicável | Uma ocorrência de posição que pode existir naquele layout, dispositivo e condição de acesso. Independe de campanha. | Base do inventário. |
| Requisição de anúncio | Tentativa de seleção/entrega, com ID ligado à oportunidade. Retentativas ficam identificadas. | Diagnóstico de entrega; não é impressão. |
| Entrega | Servidor selecionou e registrou um anúncio para responder. | Preenchimento e operação. |
| Posição montada | Área de dimensões válidas confirmada no layout do navegador. Pode conter anúncio ou conteúdo institucional. | Diferença entre oportunidade e montagem real. |
| Anúncio renderizado | Criativo foi montado e seus recursos essenciais carregaram. | Falhas de carregamento e denominador de visibilidade. |
| Oportunidade visível | Área da posição cumpre proporção e tempo definidos, incluindo quando ocupada por conteúdo institucional. | Potencial observável do espaço. |
| Impressão visível | Anúncio renderizado cumpre proporção e tempo definidos. | Exposição da campanha. |
| Clique válido / faturável | Eventos com as validações e regras financeiras próprias do Ads. | Interesse e consumo de créditos. |

Adotar inicialmente, para os formatos display/nativos atuais, **pelo menos 50% da área durante 1 segundo contínuo, com a página visível**. Reiniciar a contagem contínua se sair da área ou ocultar a aba; não somar duas passagens de meio segundo para atingir esse marco. É referência de oportunidade de ver, não comprovação de atenção humana nem certificação da medição. A referência MRC distingue entrega e visibilidade: [diretriz desktop](https://www.mediaratingcouncil.org/sites/default/files/Standards/081815%20Viewable%20Ad%20Impression%20Guideline_v2.0_Final.pdf), [diretriz mobile](https://www.mediaratingcouncil.org/sites/default/files/Standards/062816%20Mobile%20Viewable%20Guidelines%20Final.pdf).

Guardar também tempo visível acumulado e marcos de 2, 5 e 10 segundos como diagnóstico. Esses marcos não criam novas impressões. Se no futuro houver publicidade em vídeo, definir sua regra específica; a reprodução de vídeo editorial é outra métrica.

Cada posição conta uma vez por visualização de página na base de capacidade. Rolar para fora e voltar, repetir um beacon ou remontar uma partial não deve multiplicar o inventário. Trocas de criativo, quando existirem, precisam de identificação própria e relatório distinto.

### Como medir posições sem campanha

Registrar a posição antes da seleção de anúncio, com campanha opcional. Usar os estados preenchida por anunciante, institucional, vazia, oculta, desativada, não aplicável e erro; motivo de ausência de candidato deve ser persistido quando disponível.

Existe uma limitação física: uma posição removida do layout por estar vazia não tem exposição observável. Nesse caso, registrar sua oportunidade lógica e sinalizar exposição como **não medida**. Para medir o espaço real, usar uma peça institucional de tamanho equivalente — por exemplo, chamada para agenda, conteúdo ou recurso do próprio site — na mesma área. Não atribuir impressão publicitária ao anunciante nem consumo de crédito a essa peça.

Um marcador sem área não comprova que um banner inteiro ficaria visível. Reservar espaços também pode mudar a navegação; validar mobile/desktop e considerar mudanças de apresentação ao comparar períodos, sem implementar versionamento de layout, conforme decisão do usuário.

### Recortes obrigatórios

- **Audiência:** UF inferida do acesso, país, fonte da localização e estado desconhecido/exterior. UF do perfil e UF de interesse/contexto da página permanecem campos separados. Conforme definição comercial aprovada pelo usuário, uma pessoa em SP consultando corridas em SC **conta como audiência comercial de SC**, pois pode consumir um anúncio de SC, e também permanece identificada como origem geográfica SP. A visão principal de potencial usa o contexto comercial; a visão de origem mostra a localização. A mesma visita não se duplica no total geral.
- **Página:** família e variante — home, estado, busca, evento, perfil, notícias/listagem, notícia/detalhe, vídeos/listagem, vídeo/detalhe ou modal e demais rotas públicas descobertas no inventário.
- **Posição:** chave comercial, posição física e variante desktop/tablet/mobile. “Banner lateral” pode ser consolidado, preservando o desdobramento por família de página. Versionamento de layout foi dispensado pelo usuário.
- **Conteúdo:** tipo e ID estável para notícia, vídeo, evento ou perfil; título/slug como atributos. O ID serve ao relatório editorial, sem fragmentar a visão comercial principal.
- **Origem do tráfego:** preservar origem, meio, campanha e criativo por UTM e referência de entrada já coletados. Links internos não devem sobrescrever a origem da aquisição. Esses dados continuam disponíveis para análise por outras frentes; não implicam implementar aqui um funil de mídia paga.
- **Contexto:** sessão, identificador pseudônimo de navegador, page-view ID, idioma, ambiente e condição anônimo/logado.

Localização é uma inferência e visitantes únicos são uma estimativa por navegador/identidade disponível. Não prometer contagem perfeita entre dispositivos. Informar a parcela sem localização ou sem medição; não atribuir uma UF por suposição. Usar agregados e dados mínimos, sem e-mail, CPF ou URLs com dados pessoais no evento analítico.

### Audiência e conteúdo

Medir páginas, sessões, visitantes estimados, entrada/saída, tempo ativo, navegação interna e retorno. Proposta inicial: sessão encerra após 30 minutos de inatividade; sessão qualificada tem pelo menos 30 segundos ativos de uso do conteúdo/serviço, duas páginas de conteúdo distintas ou uma ação útil previamente definida. Espera em login, carregamento e redirecionamentos não qualificam sozinhos a sessão. Esses critérios são escolhas do produto, a calibrar com os dados, e precisam ser versionados.

Ações úteis incluem abrir detalhes a partir de uma busca, usar agenda/favorito e acessar inscrição. Cliques pagos de anunciantes ficam reportados separadamente para evitar que o próprio faturamento defina toda a qualidade da audiência.

Notícias: separar exposição do card na listagem, abertura da matéria, tempo ativo e profundidade de leitura. Rolagem não comprova leitura integral.

Vídeos: separar exposição do card, abertura do modal/página, início real, tempo reproduzido e conclusão. Identificar autoplay e reprodução iniciada pelo usuário. Abertura de modal não significa reprodução; usar eventos do player quando disponíveis.

### Organização dentro do Business

1. **Audiência:** evolução diária, sessões qualificadas, visitantes estimados, origens, UFs, dispositivos e retorno.
2. **Inventário:** linhas por posição × família de página; colunas de oportunidades, montagem, anúncios renderizados, exposição visível, exposição curta, preenchimento e ausência/erro. Filtros comuns de período, UF do visitante, UF de contexto e dispositivo.
3. **Conteúdo:** notícias e vídeos individuais, com aquisição, consumo e continuação da navegação.
4. **Origem do tráfego:** preservar os recortes existentes de fonte, meio e campanha/UTM. A criação de um painel de custos, ativação e retorno de campanhas externas saiu deste escopo.

As visões globais de audiência e inventário pertencem à administração do Business. Anunciantes veem apenas seus próprios resultados e previsões pertinentes à contratação.

Os totais devem considerar o período inteiro, sem limite silencioso de linhas. Amostras para investigação ficam explicitamente rotuladas. Exibir atualização dos dados, cobertura por template e eventuais falhas de coleta.

### Previsão comercial

Após obter semanas completas de base, estimar por período, UF, posição, dispositivo e elegibilidade. Separar capacidade observada, projeção e capacidade ainda não instrumentada.

Para CPC, combinar oportunidades disponíveis, probabilidade de preenchimento/seleção, visibilidade e taxa de clique de coortes comparáveis. Uma estimativa simplificada é:

`cliques associados a exposições visíveis ≈ oportunidades visíveis elegíveis × participação esperada da campanha × taxa de clique dessas exposições`

`consumo estimado ≈ cliques faturáveis previstos × CPC efetivo previsto`, limitado por saldo, orçamento e período.

Cliques rápidos que não tenham atingido o marco de 1 segundo precisam de coorte própria; sua validade financeira não deve depender automaticamente de uma impressão anterior. Não usar indiscriminadamente o CTR agregado atual como probabilidade de todo o site.

Considerar concorrência, restrições de repetição, login, dispositivo e compromissos existentes. Somar oportunidades de dois spots é válido para inventário, mas não duplica o número de pessoas alcançadas nem significa que uma única campanha possa ocupar ambos. Mostrar faixa conservadora/base e alerta de orçamento acima da capacidade projetada. Orçamento dividido pelo CPC continua útil como teto de compra, não como promessa de entrega.

### Entrega e validação da primeira etapa

RoadRunners deve produzir o contexto de página e eventos, identificar posições e manter o contrato de coleta/agregação. Business deve consumir os agregados e apresentar os painéis. O vínculo com Ads usa IDs opcionais de campanha/entrega; eventos de audiência e posição não percorrem o débito financeiro.

Validar home, estado, busca, notícia, vídeo, evento e perfil; variantes móveis e desktop; anônimo/logado; posição sem campanha; criativo quebrado; exposição abaixo de 1 segundo; aba oculta; retorno à posição; repetição de beacon; partial assíncrona; localização desconhecida e visitante de uma UF consultando outra.

Robôs conhecidos, acessos internos de teste e tráfego suspeito precisam ficar identificados e fora da base comercial principal. Confrontar coleta do navegador com logs operacionais para encontrar lacunas, sem esperar igualdade entre requisições e visualizações. Falha de medição não é o mesmo que exposição zero.

Começar a linha de base após essa validação: duas semanas completas dão uma primeira leitura; quatro semanas ajudam a observar variação por dia e eventos. São janelas de observação propostas, não prazo prometido de desenvolvimento. Visibilidade histórica não coletada não pode ser reconstruída a partir de entregas.

## Sequência operacional — somente mensuração

1. Mapear templates e posições ativas, definir métricas, separar as UFs e validar o coletor em conjunto com Ads.
2. Entregar a visão do Business e formar a linha de base, incluindo posições sem campanha e conteúdo editorial.
3. Fechar lacunas de mensuração e exposição física identificadas, distinguindo implementação, validação local e comprovação em produção. O piloto institucional lateral pertence a esta etapa: mede uma área sem campanha e não é uma campanha de aquisição.
4. Com semanas completas e cobertura identificada, apresentar a previsão comercial baseada em capacidade observada. Não condicionar este trabalho à verba ou execução de mídia externa.
5. Somente no final, avaliar a retirada da gravação específica de visualização de página de evento em `tb_log`, com cobertura, leitores e histórico preservados, conforme o [plano de transição condicional](2026-09-10_tb_log_eventos_transicao.md). Não desligar a tabela ou os outros logs.

O [registro de pendências de 12/09](2026-09-12_audiencia_escopo_e_pendencias.md) diferencia os lotes já publicados do trabalho restante. Não solicitar orçamento nem acesso a plataformas de mídia nesta tarefa. A definição regional permanece aprovada: interesse/contexto que torna o anúncio elegível participa da audiência comercial da UF, independentemente da origem física do visitante. A coleta preserva os campos de origem, perfil e contexto para explicar essa composição.

## Evidências locais principais

- [Performance CPC no Business](/Users/Shared/Projects/RunnerHub/Business/ads/includes/backend.cfm:497).
- [Fórmulas do painel](/Users/Shared/Projects/RunnerHub/Business/ads/includes/workspace_performance.cfm:47).
- [Amostra de acessos e UF do evento](/Users/Shared/Projects/RunnerHub/Business/portal/includes/event_analytics_backend.cfm:98).
- [Estimativa do assistente](/Users/Shared/Projects/RunnerHub/Business/assets/js/ads-campaign-wizard.js:18).
- [Medição atual de visibilidade](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/ads_v1/viewability.cfm:81).
- [Escolha da UF de contexto](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/eventos_ads.cfm:26).
- [Registro separado da impressão](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-08-19_ads_v1_cpc_delivery.sql:161) e [cobrança por clique](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-08-19_ads_v1_cpc_delivery.sql:261).
- [Vídeo aberto em modal](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/modal/modal_youtube.cfm:85).

A paridade entre checkout e produção, números atuais de audiência, geografia efetiva e cobertura de coleta precisam ser comprovadas nas etapas operacionais. O diagnóstico inicial refere-se ao código inspecionado na origem da proposta; os recibos posteriores registram as mudanças e seus limites de validação.
