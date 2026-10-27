# Plano de crescimento do Road Runners com páginas regionais e calculadora de pace

Proposta de 25/10/2026. A prioridade é aumentar a entrada por buscas úteis ao corredor e transformar parte dessa audiência em visitas às provas, inscrições e uso de cupons. Começar pelas páginas regionais que já têm posições relevantes e por uma calculadora pública de pace; depois, aprofundar fichas de provas e circuitos. Este documento detalha a [análise dos concorrentes](2026-10-25_seo_concorrentes_estrategia.md).

## Andamento da implementação

Implementação autorizada em 25/10/2026. Base local revalidada depois da atualização do Git informada pelo usuário: os seis arquivos existentes do escopo coincidem com a produção. Não há conflitos Git nesses arquivos. Alterações de outras frentes ficam fora da publicação.

| Entrega | Situação |
| --- | --- |
| Regionais: resumo sincronizado com filtros, cidades no mobile, vazio e breadcrumb com cidade | Publicado e conferido em 25/10/2026 |
| Calculadora pública com três modos, parciais e ligação ao calendário | Publicada em 25/10/2026; incluída no rodapé e sitemap |
| Testes e conferência pública das entregas acima | Concluídos: Node, Adobe ColdFusion, HTTP público e navegador desktop/mobile |
| Baseline GSC das regionais | Registrado e publicado no painel em 25/10; 316 cliques no período anterior às melhorias |
| Medição da calculadora | Encaminhamento pela tag Google publicado; recebimento no GA4 pendente de comprovação e autorização de leitura no Business |
| Paginação rastreável e períodos exatos | Publicados e conferidos em 25/10/2026; lote 3 concluído |
| Curadoria aprofundada de fichas, Floripa/circuitos e pós-prova | Triagem de PR/DF registrada; revisão nas fontes oficiais e correções ainda pendentes |

Evidências operacionais desta rodada: `../staging/seo-regionais-pace-20261025/`. Publicação inicial às 17:46 (Brasília), seguida de ajuste para “Todo o Brasil” manter o contexto nacional. Backup recuperável e 14 arquivos de runtime conferidos; código sincronizado com o RoadRunners preservando a atualização trazida pelo usuário. Sem alteração no banco e sem commit/push.

Verificações: 10 testes Node (fonte/minificado), 8 templates CFML compilados, 9 cenários no Adobe incluindo 15 asserções de regionais/breadcrumb. A calculadora foi recompilada após o ajuste nacional. HTTP público, sitemap e três assets conferidos. No navegador: três modos, erro/recuperação, parciais, link para calendário, cidades mobile e atualização por filtro. Curitiba exibiu 16 provas, 11 ao escolher 5 km e 0 com cupom; números refletem o inventário no momento da conferência.

A estrutura compartilhada alcança todas as regionais; PR/Curitiba e DF/Brasília foram conferidos como prioridades. A revisão editorial das fichas do lote 1 continua pendente. A ferramenta do lote 2 está funcional, mas sua coleta analítica ainda precisa ser comprovada. A entrega técnica não comprova melhora de tráfego, ranking ou Site Health.

Detalhamento técnico no RoadRunners: `../../../RoadRunners/_codex/docs/2026-10-25_regionais_pace.md`.

### Rodada seguinte concluída: paginação e períodos exatos

Lote 3 publicado em 25/10/2026 às 18:09 (Brasília), com ajuste complementar do controle de distância encontrado na conferência visual. As páginas regionais têm links HTML anterior/próxima, canonical por página e consultas limitadas a 50 provas com desempate por ID. O resumo e as contagens de cidades representam o conjunto filtrado completo. Combinações não padrão recebem `noindex,follow`; páginas além do fim retornam 404 e parâmetros inválidos, 400.

O seletor de período oferece fim de semana, até o fim do mês, próximo mês, próximo ano e intervalo personalizado. As datas são inclusivas, usam referência de hoje no fuso de Brasília e incluem provas de vários dias por sobreposição do intervalo. Cidade, distância e cupom conservam o período. O padrão legado de meses de 30 dias continua disponível para URLs existentes. A data da próxima prova é calculada, mas ainda não foi exibida no resumo.

Validação concluída: **42 testes Node**, **10 templates compilados**, **21 cenários no Adobe ColdFusion**, **14 casos HTTP públicos** e **quatro assets** comparados por conteúdo. No snapshot de PR, 128 provas distribuídas em 50/50/28, sem IDs repetidos entre páginas. Desktop e mobile de 390 px conferidos: paginação, presets, datas personalizadas, distância, cupom, cidade e vazio. PR, DF, SC, RS e SP foram verificados; o template compartilhado atende as demais regionais.

Publicação de 18 arquivos, backup recuperável em `/var/backups/seo-regionais-pagination-20261025/baseline` e ajuste complementar em `slider-fix/baseline`; hashes finais e cinco dependências compartilhadas conferidos. Sincronização local protegida por hashes, preservando as mudanças do usuário e uma correção do cache da agenda que já existia em produção. Sem escrita no banco, DataGrip, commit ou push. Evidências: `../staging/seo-regionais-pagination-20261025/`. Detalhes: `../../../RoadRunners/_codex/docs/2026-10-25_regionais_paginacao_periodos.md`.

### Rodada de medição publicada

Em 25/10 às 18:48 (Brasília), foi publicado o baseline do grupo PR/Curitiba e DF/Brasília em [SEO → Audiência Google](https://business.roadrunners.run/portal/seo/?aba=ga4&site=roadrunners): **316 cliques**, 10,7 mil impressões, CTR 2,9% e posição média 7,4 entre **26/09 e 23/10**. É um snapshot manual do Search Console, anterior às melhorias; não representa seu impacto. PR teve 197 cliques, DF 119 e Curitiba 0; Brasília cidade não teve linha retornada, sem inferir desindexação.

A calculadora agora encaminha cálculo e clique para calendário pela tag Google existente, com destino GA4 explícito. O antigo objeto no dataLayer não tinha encaminhamento correspondente no GTM público inspecionado. O envio respeita elegibilidade de audiência, acessos internos e opt-out, sem valores livres do cálculo. **O recebimento no GA4 continua pendente de comprovação.** O Business solicita “Autorizar Google Analytics”; a leitura exige consentimento da conexão existente. Não houve alteração de permissões.

Validação: 20 testes Node, 3 templates compilados, 6 cenários ColdFusion, 5 verificações HTTP e conferência visual desktop/mobile. Cinco arquivos de runtime publicados com backup e hashes verificados. Detalhes e evidências em `../staging/seo-measurement-editorial-20261025/` e `../../../RoadRunners/_codex/docs/2026-10-25_medicao_regionais_pace.md`. Nenhuma alteração no banco, DataGrip, commit ou push.

**Próximas prioridades:** comprovar recebimento no GA4 após autorização; conferir nas fontes oficiais as distâncias ausentes das maratonas de Curitiba e Monumental de Brasília, condições da LIVE! Brasília e possível divergência entre duas fichas Night Run Curitiba. A triagem não alterou fatos nem concluiu a curadoria. Depois vêm Floripa/circuitos e pós-prova. Lote 0 tem baseline concluído e medição parcialmente concluída; infraestrutura regional e lote 3 entregues; parte editorial dos lotes 1/4 e comprovação de impacto seguem pendentes.

## Evidências que orientam as prioridades

A lista mensal do Semrush, base Brasil, coletada em 25/10, mostra RR com cerca de 3,2 mil de tráfego orgânico estimado, alta de 191,3%. Comparar escala e crescimento separadamente:

| Referência | Tráfego estimado e variação mensal | Aprendizado para o RR |
| --- | --- | --- |
| CorridasBR | 21,9 mil; −3,26% | Referência direta de calendário regional, apesar da queda mensal. |
| Ticket Sports | 169,9 mil; −3,05% | Busca pela marca e por provas específicas; fichas práticas e acesso à inscrição. |
| Ativo | 118,7 mil; −21,48% | Circuitos e conteúdo conectado às provas; escala não comprova crescimento atual. |
| Foco Radical | 474,7 mil; +12,36% | Utilidade depois da prova e rede de parceiros; negócio de fotos tem intenção diferente da de um calendário. |
| Sua Corrida | 1,8 mil; +160,26% | Duas consultas da calculadora respondem por 74,8% da estimativa do domínio no relatório consultado. |

Os relatórios de posições BR/Computador de 24/10 reforçam a prioridade regional. As atualizações das SERPs individuais variam; são posições registradas pelo fornecedor, não uma conferência ao vivo de cada busca.

| Mesma consulta | CorridasBR | Road Runners | Oportunidade |
| --- | ---: | ---: | --- |
| corridas parana | 1 | 2 | Preservar a entrada estadual já forte; melhorar navegação para cidades/provas. |
| corridas em sc | 1 | 8 | Melhorar a utilidade e descoberta do calendário de SC. |
| corrida sc | 1 | 7 | Trabalhar a mesma página estadual, sem criar outra para a variante. |
| corridas de rua rs | 3 | 8 | Fortalecer RS e a conexão entre lista e provas. |
| corridas rs | 2 | 11 | Oportunidade próxima da primeira página. |

No Ticket Sports, a linha orgânica com sitelinks de “ticket sports” representa 23,30% da estimativa. Há também provas em 1º, como “corrida do bob esponja” e “meia de alphaville 2026”. Isso favorece aprender com a organização da ficha, sem tratar todo o tráfego da plataforma como público genérico disputável. Recursos de SERP e variantes não foram somados como visitantes independentes.

Fontes: [posições do CorridasBR](https://pt.semrush.com/analytics/organic/positions/?q=corridasbr.com.br&db=br&searchType=domain), [Ticket Sports](https://pt.semrush.com/analytics/organic/positions/?q=ticketsports.com.br&db=br&searchType=domain), [Sua Corrida](https://pt.semrush.com/analytics/organic/positions/?q=suacorrida.com.br&db=br&searchType=domain). Snapshots novos em `../analyses/seo_growth_plan_20261025/`; anteriores em `../analyses/seo_competitors_20261025/` e `../analyses/seo_domains/`. A estrutura observada sustenta hipóteses de melhoria, não prova qual mudança causou a variação mensal.

## Páginas regionais

### Piloto e expansão

Começar a curadoria e a medição com **PR/Curitiba e DF/Brasília**, quatro páginas existentes, acompanhando estado e cidade em conjunto. O RR já aparece em 6º para “corridas em curitiba” e em 7º para “corridas em brasilia”, em ambos os casos com a página estadual. Depois, ampliar para SC e RS; SP entra com seleção das cidades pelo acervo, impressões e potencial comercial. Uma página estadual atender uma busca de cidade não comprova erro de canonical.

O template regional e o breadcrumb são compartilhados. Correções gerais de navegação e estado vazio terão alcance maior que essas quatro páginas e exigem regressão em outras regiões. A curadoria específica fica concentrada no piloto; não tratar regiões que receberam alterações compartilhadas como grupo de controle intocado.

As rotas `/estado/{uf}/` e `/estado/{uf}/{cidade}/`, seletor de cidade, filtros, canonicals locais e sitemap regional já existem. A proposta preserva essa estrutura.

### Experiência proposta

| Posição na página | Conteúdo e comportamento |
| --- | --- |
| Entrada | H1 específico, estado/cidade lado a lado e resumo curto do calendário. A lista continua próxima do início. |
| Resumo | Quantidade de provas cadastradas para o recorte, próxima data e distâncias presentes, usando os mesmos critérios da lista. Não contar somente os primeiros 50 cards nem prometer cobertura de todas as provas da região. |
| Atalhos | Período e distâncias mais úteis com acervo: 5 km, 10 km, meia e maratona. Reutilizar filtros existentes e indicar seleção. |
| Lista | Cronológica, reaproveitando cards com data, local, distância e cupom. A ação principal leva ao detalhe da prova. |
| Navegação regional | Cidades relevantes também no corpo mobile; cidade aponta para estado; evento aponta para cidade e estado. |
| Informação complementar | Texto curto e específico quando houver algo útil e verificável a acrescentar. Dúvidas reais sobre calendário, inscrição e resultados, sem texto genérico repetido por município. |
| Lista vazia | Explicar que não há provas cadastradas naquele recorte, oferecer limpar filtros, ampliar período e consultar o estado. Não afirmar que não existe corrida na cidade. |

Exemplo de intenção de título: **“Corridas em Curitiba: calendário de provas | Road Runners”**. Exemplo de resumo, com valores preenchidos pelo acervo: “Consulte as provas cadastradas para [período], com datas, distâncias e informações de inscrição.” O conteúdo deve ser útil mesmo sem um parágrafo editorial longo.

### Melhorias concretas identificadas no código

- O breadcrumb do evento está em **Início → Estado → Evento**. Incluir cidade quando existir vínculo/slug validado; não gerar URLs pelo nome bruto.
- O destaque das cidades fica em uma lateral exclusiva de desktop. Levar um conjunto compacto ao conteúdo principal, aproveitando os links e contagens existentes.
- O estado vazio do include de eventos está tratado para `/busca/`, sem explicação equivalente na página regional.
- A lista inicial é renderizada no servidor, limitada a 50 registros, e a continuação depende de interação JavaScript. Planejar navegação HTML complementar para que eventos posteriores possam ser descobertos pelos links da lista.

A paginação é um lote técnico próprio: URL por página, ordem determinística com desempate, links anterior/próxima, limite de consulta e canonical coerente com conteúdo distinto. Preservar a experiência de “carregar mais” se útil, sem exigir que o crawler acione o botão. [Orientação do Google sobre paginação](https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading).

### Regras que evitam uma expansão problemática

1. **Períodos exatos:** o filtro legado `tempo=0,12` usa meses de 30 dias. “Neste fim de semana”, “este mês” e “2027” só entram quando houver intervalos exatos, fuso e tratamento consistente de provas com início/fim. Primeiro lote pode manter os períodos atuais corretamente descritos.
2. **Indexação seletiva:** cidade e estado mantêm URLs estáveis. Filtros de distância, cupom e período não entram automaticamente no sitemap. Definir a política de cada tipo de URL antes de ampliar a navegação; não aplicar canonical da primeira página a toda paginação. Combinações inválidas e páginas além do fim têm tratamento próprio, distinto de uma cidade legítima temporariamente sem provas. [Navegação por filtros no Google](https://developers.google.com/crawling/docs/faceted-navigation).
3. **Informação comercial confirmada:** URL de inscrição e texto de cupom não provam inscrição aberta nem validade da oferta. Usar condições verificadas; quando não houver status confiável, “ver inscrição” e “ver condições”. Não ocultar provas úteis por não terem cupom.
4. **Cobertura geográfica:** não chamar outra cidade de “próxima” só porque pertence à mesma UF. Reaproveitar o Radar existente em uma expansão posterior, quando localização e link de contexto estiverem validados.
5. **Atualidade factual:** não alterar data de prova para captar buscas; manter edições passadas e cancelamentos identificados. Data de revisão e `lastmod` devem corresponder a mudanças reais.

### Aceite do piloto

Conteúdo principal e links presentes no HTML anônimo; contagens iguais às facetas/lista; cidade correta no breadcrumb; filtros e compartilhamento de URL preservados; vazio explicativo; navegação por teclado e mobile; nenhuma multiplicação de consultas por card. Comparar tempo de resposta antes/depois nos mesmos recortes e rejeitar regressões relevantes. Revisar estado/cidade juntos no Search Console para distinguir mudança de URL vencedora de perda efetiva de cliques.

## Calculadora de pace

### Produto inicial

Uma página pública **`/calculadora-de-pace/`**, inicialmente em português, com três modos acessíveis: **calcular pace**, **calcular tempo** e **calcular distância**. A referência de demanda é a [ferramenta do Sua Corrida](https://www.suacorrida.com.br/calculadoras/); texto, funcionamento e apresentação do RR serão próprios.

- Distâncias rápidas: 5 km, 10 km, meia de 21,0975 km e maratona de 42,195 km, além de valor livre.
- Tempo com horas/minutos/segundos; pace em minutos/segundos por quilômetro. Distância aceita vírgula ou ponto decimal. Não interpretar `5,30` como `5:30` automaticamente.
- Resultado com unidade, resumo das entradas e possibilidade de recalcular. Velocidade em km/h pode aparecer como informação secundária.
- Parciais em bloco expansível, com acumulado por quilômetro e trecho final fracionário. Limitar a quantidade de linhas geradas para valores extremos, sem travar o navegador.
- Explicação curta, fórmula, exemplos e tabela de referência no HTML. O formulário fica antes do conteúdo longo.
- Ação após o resultado: **“Encontrar provas desta distância”**, com região opcional. Confirmar que meia/maratona conduzem às categorias existentes, mesmo quando o cadastro usa 21/42 em vez de 21,0975/42,195.

O texto deve dizer **“tempo mantendo este pace”**. O resultado é aritmético: não prevê capacidade de sustentar o ritmo, não usa histórico pessoal e não prescreve treino.

### Matemática e casos de aceite

Distância `d` em quilômetros, tempo `t` em segundos e pace `p` em segundos por quilômetro: `p=t/d`, `t=p×d`, `d=t/p`. Se exibida, velocidade `v=3600/p` em km/h. Manter a precisão dos valores originais e arredondar só ao apresentar, para o segundo mais próximo, com meio segundo para cima. Parciais acumuladas usam os valores originais, não o pace já arredondado.

| Entrada | Saída esperada |
| --- | --- |
| 5 km em 00:30:00 | 6:00 min/km |
| 10 km a 5:30 min/km | 00:55:00 |
| 00:45:00 a 6:00 min/km | 7,5 km |
| 21,0975 km a 5:00 min/km | 01:45:29 |
| 42,195 km a 5:00 min/km | 03:30:59 |
| Tempo acima de 24 horas | Preservar horas acumuladas; não formatar como horário do dia. |
| Zero, negativo, vazio, valor não finito ou segundos ≥60 | Mensagem junto ao campo, sem apagar as outras entradas. |

O último acumulado deve coincidir com o resultado final; segundos arredondados para 60 devem avançar o minuto. Conferir ponto/vírgula, teclado mobile, mudança de modo e valores grandes. Sem JavaScript, explicação e tabela continuam disponíveis e o requisito do cálculo interativo fica claro.

### Implementação e descoberta

CFML para página e conteúdo inicial, JS puro para matemática e CSS do componente, aproveitando shell/head/footer. Sem nova consulta ao banco, API, biblioteca pesada ou chamada de IA para calcular. O helper de resultados que usa `timeFormat` não é apropriado para durações acumuladas.

Uma canonical para a ferramenta; estados e resultados do formulário não criam páginas indexáveis. Incluir no sitemap e em navegação pertinente depois de validar a publicação. Versões em outros idiomas só recebem URLs/alternates quando realmente traduzidas. Atalhos contextuais em provas e regionais devem ajudar a tarefa, sem competir com inscrição ou esconder a lista.

Uso medido por modo/conclusão e clique para calendário, respeitando a medição e consentimento existentes, sem enviar pace, tempo, distância livre ou perfil do visitante. Confirmar recebimento na ferramenta analítica: emitir um evento JS sozinho não prova coleta.

Milhas, exportação/compartilhamento das parciais e páginas editoriais adicionais ficam para uma evolução orientada pelo uso. IMC, calorias, zonas de treino e previsão de desempenho não são necessários para atender a intenção inicial.

## Outras oportunidades dos concorrentes

| Prioridade | Aplicação ao RR | Referência e condição |
| --- | --- | --- |
| Alta, junto ao piloto | Melhorar uma pequena seleção de fichas de provas com data/local, distâncias, inscrição, cupom, kit, regulamento e fonte. Separar abas como informações e resultados quando a página for extensa. | A [ficha de Joinville no Ticket Sports](https://www.ticketsports.com.br/Evento/87159/Cadastro) e a [ficha de Ilhota no Catarina Run](https://www.catarinarun.com.br/evento/2a-corrida-dos-bombeiros-de-ilhota-2026) reúnem informações práticas. Usar o cadastro/fonte oficial para fatos; reaproveitar seções já existentes. |
| Alta após as primeiras entregas | Enriquecer o agregador permanente de Floripa e até dois circuitos com acervo completo, ligando próxima edição, etapas, cidades, histórico e condições comerciais. | O [guia do Netshoes Run Tour no Ativo](https://www.ativo.com/netshoes-run-tour-2026-anuncia-etapas-em-brasilia-sao-paulo-e-recife/) exemplifica a organização por etapas. Floripa já possui página permanente, próxima edição e histórico; melhorar essa entrada. |
| Média | Reorganizar a página depois da prova: resultado oficial, fotos de parceiros quando disponíveis e próxima edição confirmada. | A [FAQ da Foco Radical](https://www.focoradical.com.br/site/faq) orienta localizar o evento antes das fotos. Preservar política de noindex/privacidade para resultados pessoais; aquisição centrada na prova. |
| Média, recorrente | Melhorar confirmação de informações por organizadores no Business e facilitar compartilhamento da ficha/calendário. | A [rede de fotógrafos da Foco](https://www.focoradical.com.br/conteudo/fotografos) ilustra contribuição de parceiros ao produto. Adaptar à manutenção do acervo, sem inferir que isso explica sozinho a alta mensal. |
| Exploratória | Transformar recortes já aprovados do Brasil que Corre em conteúdo público original, com metodologia, período e ligação ao calendário regional. | É uma vantagem própria do RR: informação que não depende de reescrever notícias. Respeitar revisão editorial e a política atual de distribuição do estudo; não retirar `noindex` de prévias nem divulgar recortes ainda restritos. Crescimento da base coletada não equivale a crescimento do mercado. |

Adiar um novo portal editorial amplo, outro mapa e milhares de páginas de cidade × distância × mês. As primeiras entregas devem explorar o acervo e as rotas existentes. Textos claros, fontes identificadas, links rastreáveis e fatos visíveis também ajudam a compreensão por buscadores com IA; o [Google não exige uma marcação especial para seus recursos de IA](https://developers.google.com/search/docs/appearance/ai-features).

## Execução e responsabilidade

| Lote | Entrega | Esforço relativo | Dependência para concluir |
| --- | --- | --- | --- |
| 0 | Baseline de URLs/consultas regionais e de ações comerciais; confirmar medição. | Pequeno | Acesso/fonte válida; ausência de medição fica explícita, não vira zero. |
| 1 | Piloto PR/Curitiba e DF/Brasília: resumo, ligações, cidades mobile, vazio e revisão das fichas prioritárias. | Médio | Igualdade de contagens, informações verificadas e validação pública. |
| 2 | Calculadora pública com três modos, parciais, conteúdo HTML e ligação ao calendário. | Médio | Casos matemáticos, acessibilidade, performance e medição. Pode ser desenvolvida em paralelo ao lote 1. |
| 3 | Continuação rastreável da lista regional e intervalos de data exatos. | Médio | Contrato de paginação/canonical/filtros, ordem estável e consultas limitadas. |
| 4 | Expandir regionais para SC/RS e cidades selecionadas de SP; Floripa e dois circuitos. | Médio por rodada | Resultados e regressões dos primeiros lotes, inventário e fonte oficial. |
| 5 | Retorno pós-prova, colaboração com organizadores e recortes públicos de dados próprios. | Variável | Disponibilidade dos vínculos, manutenção e política editorial do produto. |

**RoadRunners** é dono das páginas, filtros, links e cálculo. Pontos prováveis: `estado/index.cfm`, include regional próprio, `evento/parts/breadcrumb.cfm`, backend/facetas do calendário, assets locais, nova rota da calculadora e catálogo do sitemap. Evitar mudanças amplas em autenticação, `Application.cfc` e backend central. Conferir produção antes de editar arquivos compartilhados.

**Business** mantém documentação, evidências e acompanhamento do SEO. Uma área de acompanhamento por iniciativa pode reutilizar as abas do painel e distinguir entrega técnica de impacto observado. Criar um CMS de textos ou nova integração entre projetos não é pré-requisito. O MVP proposto não demanda migração nem operação manual no DataGrip.

Para cada implementação: baseline de produção e backup, pacote restrito, verificações CFML/JS pertinentes, acesso anônimo, desktop/mobile, publicação e conferência real. O planejamento inicial foi autorizado para implementação em 25/10/2026; as entregas publicadas e as pendências estão discriminadas no andamento acima.

## Como decidir se expandimos

- **Aquisição:** cliques e impressões do Search Console para o conjunto de URLs e consultas, separando marca, região, prova e pace. Avaliar estado/cidade juntos.
- **Uso e negócio:** entrada orgânica → evento → inscrição/cupom; calculadora → calendário → evento. Clique de saída é intenção, não venda confirmada; receita só entra quando houver atribuição confiável.
- **Qualidade:** ausência de erros, conteúdo/canonical correto, resposta e experiência mobile sem regressão. Site Health é controle técnico, não a medida de sucesso comercial.
- **Ritmo de avaliação:** marcar data de cada publicação, conferir indexação e coleta na primeira semana, comparar janelas completas de 28 dias e reavaliar em 56 dias quando o volume for pequeno. Considerar sazonalidade e datas das provas. Isso é janela de avaliação, não promessa de prazo para ranquear.

Expandir quando houver conteúdo/cobertura sustentáveis e sinal favorável de cliques ou ações comerciais. Se as impressões subirem e o CTR cair, rever consulta, posição e apresentação; se entrar tráfego sem chegar às provas, rever a ponte de navegação; se nada ganhar exposição, checar descoberta/indexação e relevância antes de produzir mais páginas. Comparações antes/depois não isolam todas as causas, especialmente quando outras mudanças ocorrem no mesmo período.
