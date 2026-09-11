# Proposta — audiência, inventário e crescimento do RoadRunners

Atualização de 07/09/2026: o usuário definiu **opt-out**, respeitando GPC e oferecendo recusa, e **90 dias de retenção para eventos detalhados**. O painel nativo e os controles de interface, coleta e expurgo foram implementados; implantação, agenda de retenção e configuração do proxy confiável continuam sendo pré-requisitos para ativar. Uma política maior para agregados não foi aprovada nem implementada. Estado atual em [Fechamento da implementação](2026-09-07_audiencia_painel_finalizacao.md).

Status: documento estratégico de origem; a parte de mensuração avançou para implementação local conforme o registro acima. O diagnóstico e as recomendações abaixo não são uma medição atual do tráfego de produção. A mídia paga permanece proposta: nenhuma campanha ou verba externa foi criada/gasta. Itens propostos como retorno em sete dias, funil de ativação, gasto importado e previsão de entrega não estão implicitamente incluídos no painel atual.

## Decisão recomendada

Construir no Business uma área de **Audiência e inventário**, com coleta própria no RoadRunners e ligação com os anúncios existentes. Primeiro estabelecer uma base confiável de audiência, posições e exposição; depois executar um piloto de aquisição e retenção. O objetivo é crescimento nacional. Conforme direcionamento do usuário, SC pode ser o piloto menor e controlado; SP é uma possível prioridade de expansão regional. O orçamento permanece em aberto.

O resultado operacional deve responder:

- Quantas visitas qualificadas recebemos de SC, SP e das demais UFs?
- Quantas oportunidades cada posição teve, com ou sem campanha, e quantas atingiram o critério de visibilidade?
- Que parte da capacidade veio de home, estado, busca, evento, perfil, notícia e vídeo, em cada dispositivo?
- Por que uma campanha entrega pouco: audiência, posição inexistente/oculta, falta de elegibilidade, disputa, erro ou exposição curta?
- Quanto custa adquirir audiência que usa e volta ao site, e que retorno comercial ela produz?

## O que o código atual permite afirmar

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

## Passo 1 — medir e tornar o inventário utilizável

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

Um marcador sem área não comprova que um banner inteiro ficaria visível. Reservar espaços também pode mudar a navegação; por isso, guardar a versão do layout e validar mobile/desktop antes de comparar períodos.

### Recortes obrigatórios

- **Audiência:** UF inferida do acesso, país, fonte da localização e estado desconhecido/exterior. UF do perfil e UF de interesse/contexto da página permanecem campos separados. Conforme definição comercial aprovada pelo usuário, uma pessoa em SP consultando corridas em SC **conta como audiência comercial de SC**, pois pode consumir um anúncio de SC, e também permanece identificada como origem geográfica SP. A visão principal de potencial usa o contexto comercial; a visão de origem mostra a localização. A mesma visita não se duplica no total geral.
- **Página:** família e variante — home, estado, busca, evento, perfil, notícias/listagem, notícia/detalhe, vídeos/listagem, vídeo/detalhe ou modal e demais rotas públicas descobertas no inventário.
- **Posição:** chave comercial, posição física, variante desktop/tablet/mobile e versão do layout. “Banner lateral” pode ser consolidado, preservando o desdobramento por família de página.
- **Conteúdo:** tipo e ID estável para notícia, vídeo, evento ou perfil; título/slug como atributos. O ID serve ao relatório editorial, sem fragmentar a visão comercial principal.
- **Aquisição:** origem, meio, campanha e criativo por UTM; referência de entrada; sessão de aquisição e sessões posteriores. Links internos não devem sobrescrever a origem da aquisição.
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
4. **Aquisição:** campanha externa → visita → sessão qualificada → retorno → inventário visível e resultado comercial, com gasto importado ou integrado.

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

## Passo 2 — adquirir e reter audiência regional

### Destino e conteúdo do piloto

Comparar as duas propostas indicadas pelo usuário: **“Ache sua corrida”** e **“Monte seu histórico”**. SC limita a área do primeiro experimento; a proposta da plataforma continua nacional. Antes de comprar mídia, validar os dois destinos, informações atualizadas, navegação mobile, velocidade, cobertura das posições e próximos passos úteis.

| Variante | Mensagem inicial proposta | Destino e ação útil | Hipótese a testar |
| --- | --- | --- | --- |
| A — Ache sua corrida | “Qual vai ser sua próxima largada? Ache sua corrida no RoadRunners.” | Busca/agenda, podendo iniciar na [agenda de SC](https://roadrunners.run/estado/sc/); consultar uma prova e seguir para uma ação útil. | A descoberta de eventos traz mais primeiras visitas qualificadas. |
| B — Monte seu histórico | “Cada chegada faz parte da sua história. Monte seu histórico de corridas.” | Entrada em `/resultados/`, login e vinculação válida do primeiro resultado ao usuário. | O histórico pessoal traz maior ativação e retorno ao site. |

Essas são hipóteses, não resultados esperados comprovados. Validar a jornada B e a persistência do histórico antes de usar a promessa no anúncio; visita a perfil ou login isolado não comprovam histórico montado. Para A, clique em inscrição não comprova inscrição concluída.

O código atual permite começar a busca sem login, enquanto `/resultados/` exige autenticação e preserva o destino no redirecionamento. Portanto B tem uma barreira inicial diferente. Medir separadamente chegada, início/conclusão do login e primeiro resultado vinculado no servidor; se B perder nesse ponto, investigar a jornada antes de descartar o apelo “histórico”. Uma apresentação pública do benefício pode ser avaliada como melhoria posterior. Em A, salvar um evento na agenda/interesse também é uma ação persistida, após login.

O primeiro teste compara a **proposta completa, mensagem mais destino**, e não permite atribuir uma diferença só ao texto. Depois, dentro da proposta promissora, testar criativos com o mesmo destino. Campanhas da plataforma precisam gerar interesse recorrente no RoadRunners. Promoção direta da Avaí é uma frente comercial distinta, com sua própria atribuição.

### Desenho do A/B inicial

Começar em um único canal, propondo Meta/Instagram/Facebook, com o mesmo público elegível de SC, período, formatos, posicionamentos e objetivo de otimização. Planejar divisão equilibrada de verba/exposição entre A e B, usando experimento com grupos separados e atribuição estável quando disponível. Duas peças entregues livremente pelo algoritmo são comparação exploratória, não comprovação causal de um A/B.

O resultado principal para comparar as propostas será custo por primeira sessão qualificada pós-clique, usando a mesma definição nos dois grupos. Mostrar também chegada confirmada ao site, custo por visitante qualificado estimado, retorno em sete dias e oportunidades visíveis geradas por visitante. As ativações específicas de A e B ajudam a entender a jornada, mas suas taxas brutas não são diretamente equivalentes porque as ações têm esforços diferentes.

Manter a janela e os critérios de comparação definidos antes do início. Após a base inicial, dimensionar amostra conforme frequência do resultado e diferença mínima relevante. Se o volume não permitir conclusão, registrar resultado inconclusivo e a faixa de incerteza. Não declarar vitória apenas pelo menor CPC externo ou por poucos cliques; a opção com menos visitas pode ter melhor retorno.

Depois de aprender com SC, validar a proposta em SP ou ampliar para outras regiões, mantendo relatórios por UF. O desempenho de SC não deve ser presumido igual ao nacional. Comparar canais e cidades em uma etapa posterior evita misturar o teste de mensagem com o de público.

### Distribuição proposta

| Frente | Experimento | Critério de avaliação |
| --- | --- | --- |
| Meta / Instagram / Facebook | Primeiro A/B entre “Ache sua corrida” e “Monte seu histórico”, com destinos correspondentes. | Custo por sessão qualificada, inventário visível gerado, ativação específica e retorno. |
| Google Pesquisa | Termos com intenção explícita, como agenda de corridas em SC e corridas em Florianópolis, com destino correspondente. | Qualidade regional e uso do site, além do clique. |
| Parceiros e canais próprios | Distribuição com organizadores, assessorias e canais locais; links identificados; comunicações para base que optou por recebê-las. | Visitas, retorno e custo total da parceria/conteúdo. |
| Conteúdo e busca orgânica | Agenda atualizada, informações originais, guias úteis e ligações entre eventos, notícias e vídeos. | Crescimento de visitas qualificadas e recorrentes ao longo do tempo. |

A [orientação oficial da Meta](https://developers.meta.com/horizon/resources/launch-ad-campaign/) diferencia objetivos de campanha e cita tráfego para levar público a um destino. A configuração exata de otimização deve ser conferida na conta ao preparar o piloto. Na Pesquisa Google, usar presença na região se o objetivo é audiência localizada em SC; a opção padrão também pode incluir interesse na região, conforme a [documentação de localização do Google Ads](https://support.google.com/google-ads/answer/1722038?hl=pt-BR). A localização inferida pelo Business será uma verificação independente, com limitações próprias.

Para conteúdo orgânico, priorizar utilidade, informação original e experiência satisfatória, alinhadas à [orientação do Google Search Central](https://developers.google.com/search/docs/fundamentals/creating-helpful-content). Não estabelecer promessa de volume ou prazo de SEO antes da linha de base.

Concentrar a verba inicial no teste A/B de um canal, com divisão planejada de 50% para cada proposta. Não presumir que isso produzirá exatamente o mesmo número de impressões ou visitas. Abrir Pesquisa e outros testes depois de obter uma leitura interpretável, conforme teto de investimento. A execução depende da definição do gasto e acesso às contas. Em testes futuros na Pesquisa Google, a [documentação de experimentos](https://support.google.com/google-ads/answer/6261395/set-up-a-campaign-experiment) também recomenda divisão de 50% para comparação; isso não substitui a configuração e validação do experimento na plataforma escolhida.

### Retenção e leitura semanal

Conectar a chegada a uma próxima ação útil: consultar outro evento, salvar agenda, acompanhar resultado ou assinar atualização regional, conforme recursos existentes e implementação aprovada. E-mails e comunicações regionais usam base optante. Remarketing pode entrar depois, se houver público suficiente e mensuração adequada.

Três KPIs principais propostos:

1. **Oportunidades visíveis válidas por UF/semana:** base do potencial comercial, após filtros de tráfego inválido; não depende de a sessão ter sido classificada como engajada. Acompanhar posições ativas, exposição por sessão e parcela não preenchida como explicadores.
2. **Retorno em sete dias:** visitantes adquiridos que retornam em D1–D7, dividido pelos visitantes da coorte que já completaram a janela e são mensuráveis. Avaliar por canal e conteúdo; não comparar coorte madura com a recém-adquirida.
3. **Custo por primeira sessão qualificada da região:** gasto do canal no período dividido pelas primeiras sessões pós-clique que se qualificaram na UF-alvo, com a mesma janela e regra de atribuição. Sessões de retorno ficam no indicador de retenção. Mostrar também visitantes únicos estimados para detectar crescimento por repetição excessiva.

Guardas para a decisão: qualidade do tráfego/experiência e resultado econômico. Manter visível a parcela de UF desconhecida, falhas de carregamento e suspeita de automação. Crescimento comprado deve produzir uso e recorrência sem piorar a navegação ou multiplicar impressões artificialmente.

Toda campanha terá UTM, destino, gasto, período e criativo identificados. Inicialmente o gasto pode ser importado no Business; APIs podem automatizar isso depois. Não confundir a atribuição das plataformas com a atribuição interna: regras e janelas precisam estar nomeadas. Quando houver volume, usar comparação controlada para avaliar incremento, pois atribuição sozinha não demonstra causalidade.

Revisar semanalmente; corrigir imediatamente erro de destino, gasto fora da região ou falha de coleta. Durante o A/B, preservar a divisão prevista até o encerramento ou uma condição de interrupção predefinida. Realocar verba na fase posterior, depois de comparar volume e coortes equivalentes; não escolher vencedor por dois ou três cliques. Definir limites monetários depois da linha de base e do teto do piloto, sem inventar CPC/CPM esperado.

### Viabilidade econômica

A receita para o RoadRunners depende da monetização efetiva, da recorrência e de outras receitas possíveis. Consumo de voucher promocional não equivale a receita recebida; comparar aquisição com receita líquida reconhecida, preservando essa distinção.

Exemplo exclusivamente ilustrativo, não previsão: uma sessão com duas exposições de anúncios pagos, taxa de clique de 1% em cada e CPC recebido de R$ 0,50 produz R$ 0,01 de receita bruta esperada. Comprar essa sessão por R$ 0,30 exige retorno futuro ou outras receitas para se sustentar. Ainda faltariam custos, preenchimento e elegibilidade reais.

Assim, o piloto precisa de um teto de investimento e deve ser avaliado como aquisição de público. Escalar quando houver evidência de qualidade, retorno e caminho econômico plausível; desacelerar se a melhora se limitar a cliques externos ou gasto de créditos subsidiados.

## Sequência operacional proposta

1. Mapear templates e posições ativas, definir métricas, separar as UFs e validar o coletor em conjunto com Ads.
2. Entregar a visão do Business e formar a linha de base, incluindo posições sem campanha e conteúdo editorial.
3. Corrigir perdas de exposição/layout identificadas; publicar a previsão comercial baseada em capacidade observada.
4. Validar os fluxos “Ache sua corrida” e “Monte seu histórico”, preparar os dois anúncios, definir teto financeiro e iniciar o A/B em SC, com janela inicial proposta de até 30 dias e critérios de amostra definidos antes do início.
5. Revisar qualidade e custos semanalmente; medir retorno das coortes e decidir continuidade/escala. Havendo evidência, validar em SP ou expandir nacionalmente; se faltar volume, declarar o teste inconclusivo.

Decisões ainda em aberto: teto de gasto e duração comercial pretendida para campanhas regionais. A definição regional foi aprovada: interesse/contexto que torna o anúncio elegível participa da audiência comercial da UF, independentemente da origem física do visitante. A coleta preserva os campos de origem, perfil e contexto para explicar essa composição.

## Evidências locais principais

- [Performance CPC no Business](/Users/Shared/Projects/RunnerHub/Business/ads/includes/backend.cfm:497).
- [Fórmulas do painel](/Users/Shared/Projects/RunnerHub/Business/ads/includes/workspace_performance.cfm:47).
- [Amostra de acessos e UF do evento](/Users/Shared/Projects/RunnerHub/Business/portal/includes/event_analytics_backend.cfm:98).
- [Estimativa do assistente](/Users/Shared/Projects/RunnerHub/Business/assets/js/ads-campaign-wizard.js:18).
- [Medição atual de visibilidade](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/ads_v1/viewability.cfm:81).
- [Escolha da UF de contexto](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/eventos_ads.cfm:26).
- [Registro separado da impressão](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-08-19_ads_v1_cpc_delivery.sql:161) e [cobrança por clique](/Users/Shared/Projects/RunnerHub/RoadRunners/_codex/sql/2026-08-19_ads_v1_cpc_delivery.sql:261).
- [Vídeo aberto em modal](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/modal/modal_youtube.cfm:85).
- [Busca disponível ao visitante](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/estrutura/busca.cfm:10), [entrada autenticada de resultados](/Users/Shared/Projects/RunnerHub/RoadRunners/resultados/index.cfm:18) e [vinculação persistida do resultado](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/backend/backend_perfil_publico.cfm:751).

A paridade entre checkout e produção, números atuais de audiência, geografia efetiva, cobertura de coleta e performance dos canais precisam ser comprovadas nas etapas operacionais. As conclusões acima sobre funcionamento referem-se ao código inspecionado, sem extrapolar documentos históricos de incidentes.
