# Extensão proposta: SEO para IA

Objetivo: facilitar descoberta, leitura correta e citação de informações públicas de eventos, resultados e conteúdo editorial por assistentes. Este documento registra o plano e seu andamento; não autoriza alterar políticas de treinamento ou proteções de infraestrutura.

Status em 04/10/2026: o painel contém 24 itens, 18 entregues e seis pendentes. RR-16 acompanha a revisão de soft 404: o redirect genérico de eventos inexistentes já foi corrigido; revalidação de 96 URLs encontrou 51 respostas 200 e 45 respostas 404, e a inspeção individual confirmou DC Run 2022 já indexado. Outros exemplos ainda exigem análise. RR-14 registra divergências nos resultados históricos de São Paulo; a correção depende de reconciliar as fontes completas, pois a base não conserva os registros temporários nem logs detalhados dessas importações. Estatísticas de 2025 e filtros regionais recuperados (RR-13); cinco URLs públicas verificadas com HTTP 200. A recuperação de indexação ainda depende de nova evidência do Google. A nota técnica está recolhida e separada da situação no Google (SH-03). RoadRunners tem consulta direta ao Search Console em 04/10 com sitemap processado e 103.030 URLs descobertas. O lote static.xml ainda exibe leitura de 30/09 com 49 URLs, anterior à ampliação regional. Consulta direta ao relatório de indexação, atualizado em 20/09/2026: cerca de 14,1 mil indexadas no RoadRunners; zero no OpenResults, com 135.791 URLs bloqueadas por 403. Esses dados antecedem as mudanças de 03/10. OpenResults teve processamento confirmado em 04/10: índice XML e quatro lotes, 34.319 URLs descobertas (OR-04 concluído). Indexação atual ainda não confirmada; nova pendência OR-05 acompanha a recuperação sem reabrir páginas pessoais. O 100/100 da amostra abaixo não representa saúde geral nem acesso Google. Road Runners tem nova auditoria de 04/10 às 01:02 (Brasília), com 104.006 URLs descobertas, 100 inspecionadas e nota 70/100. A regra de comparação de escapes percentuais foi corrigida e versionada; o novo método preserva os pesos e não atribui essa mudança à melhoria do site. Open Results tem nova auditoria às 19:14, com 34.321 URLs, 100 inspecionadas e nota 100/100, após expirar o robots em cache. OR-02 está concluído na entrega, sem comprovar desindexação efetiva. Há novas medições complementares de descrições, logs e audiência, cada uma com data e escopo próprios. Evidências e publicação em 2026-10-03_seo_evidencias.md e 2026-10-03_seo_evidencias_release.json; lotes anteriores preservados. SEO regional e atualização de painel registrados em 2026-10-03_seo_regional_painel.md.

## Prioridade comercial — Road Runners (03/10/2026)

Entrega regional em 03/10: filtro completo de cidades publicado; títulos, descrições e H1 por localidade, texto factual curto e breadcrumb visível/JSON-LD nas páginas de estado e cidade. Sitemap estático com 22 rotas anteriores, 27 estados e 977 cidades com provas no calendário padrão. Eventos históricos preservados. RR-12 concluído no painel. Verificação pública, desktop/celular e revisão final Astra concluídas; a nova auditoria inspecionou 100 páginas, sem achados novos. Nota técnica permanece 70/100. Este lote não mede aumento de tráfego, receita, posição ou citações.

Decisão explícita do usuário: concentrar o plano no Road Runners porque é o site que gera receita. Open Results conserva as correções e evidências já entregues; não entra nos próximos lotes de expansão de SEO. O Business continua como ferramenta de cadastro, medição e acompanhamento do Road Runners.

A primeira consulta de priorização cobre somente roadrunners.run, produção e sem tráfego interno, de 26/09 às 21:40 a 03/10 às 21:40 (Brasília), sete dias móveis. Conta page_view_id e sessões distintos por família, sem exportar IDs, caminhos pessoais ou nomes de atletas. Foram 17.236 visualizações medidas: eventos 5.446; home 1.978; estados 1.748; circuitos 1.254; busca 863. Outras famílias permanecem na fonte, sem exclusão do total. Estados tiveram 1.602 páginas com ad_viewable e eventos 1.532 na janela. Isso mede exposição observada, não receita, clique cobrado ou conversão; não calcular rendimento financeiro a partir dessas contagens. A consulta não filtra apenas aquisição orgânica; a exposição também pode envolver anúncios HOUSE. Evidência agregada em `_codex/staging/seo-priority-roadrunners-20261003/audience.json`.

**Ordem de trabalho:**

1. Eventos e descoberta regional em português: selecionar provas mais acessadas e páginas de estado com audiência, conferir indexabilidade, título, descrição, links internos, datas, distâncias, organizador e inscrição com fonte. Priorizar futuros e preservar as URLs históricas úteis; não preencher dados presumidos.
2. Conteúdo principal em português: priorizar a fila de descrições e lacunas das páginas com audiência, antes de expansão geral EN/ES. O cron permanece pausado até esclarecer a intenção e conferir saldo atual; rejeições continuam para revisão.
3. Conectar acompanhamento de aquisição ao inventário comercial existente: entradas nas páginas públicas e exposição observada. Escolher receita/cliques Ads ou encaminhamentos de inscrição conforme a fonte de receita principal informada pelo usuário. Por enquanto, fonte principal não confirmada; pergunta assíncrona enviada. Não modificar carteira, cobrança, campanhas ou instrumentação sem especificar a mudança.
4. SEO para IA como extensão dessas páginas: fatos, fonte e atualização claros, mantendo referências medidas separadas de citações e conversões. Questões editoriais das notícias entram depois de eventos e descoberta regional.

Critérios de progresso: correções verificadas nas páginas selecionadas, audiência medida no mesmo recorte e ação comercial adequada à receita principal. A nota técnica de 70/100 mantém seu método; 404 editorial, login privado e canonical legítimo precisam de contexto e não devem motivar alterações só para elevar a nota. Não há previsão de aumento de receita sem atribuição e série comparável.

Este trecho reprioriza o plano existente. Não publica código, ativa cron, altera Ads nem reinicia auditorias dos dois sites. A implementação seguinte deve delimitar o lote Road Runners e preservar as frentes já publicadas.

## Base existente

O coletor já registra `robots_policy` para OAI-SearchBot e PerplexityBot, além de Googlebot. A nota atual usa Googlebot. A avaliação de robots é uma interpretação das regras declaradas; não comprova acesso real a partir da infraestrutura do provedor, indexação ou citação. Road Runners já tem código para JSON-LD; é preciso validar o HTML entregue antes de acrescentar outra marcação.

## Ordem de implementação

1. **Auditoria e painel Business.** Aba “SEO para IA”, preservando filtros, links diretos e teclado. Exibir por agente permissão declarada, conteúdo HTML disponível, falhas de entrega e itens não medidos. Separar preparação técnica de evidência real de citação. Reutilizar snapshots datados e o coletor; não executar auditoria longa dentro de uma requisição CFML. Começar com checks, cobertura e histórico; qualquer nota futura será interna, versionada e sem equivalência com probabilidade de recomendação.
2. **Conteúdo e dados nos sites públicos.** Conferir uma amostra de eventos futuros e passados, notícias e páginas de resultados. Nome, edição, data com fuso, cidade, distâncias, organizador, inscrição, situação e fonte devem estar disponíveis em texto e coerentes entre idiomas. Resultados precisam de edição, categoria, unidade e status provisório/oficial claros, respeitando acesso e privacidade existentes. Usar dados estruturados apropriados somente quando sustentados pelo conteúdo visível; validar marcação existente antes de ampliar.
3. **Descoberta e atualização.** Validar sitemaps, canonicals, links internos, páginas históricas e datas reais de atualização. Auditar meta description, hreflang e JSON-LD, hoje fora da coleta. Corrigir primeiro os erros HTTP e identificadores já conhecidos. Não acrescentar arquivos ou endpoints duplicados sem demonstrar utilidade e manutenção.
4. **Acesso efetivo dos provedores.** Analisar logs existentes para visitas e bloqueios, verificando identidade pelos mecanismos oficiais dos provedores. Um teste local com user-agent não comprova acesso de um bot real. Eventuais mudanças de CDN/WAF devem ser específicas e revisadas, preservando autenticação e proteções. Permissão para busca e uso em treinamento são decisões separadas.
5. **Medição.** Registrar visitas identificáveis vindas de assistentes, conversões e observações datadas de citações para perguntas fixas, como “corridas de 10 km em Salvador em outubro”. Registrar provedor, pergunta, data, URL citada e correção dos fatos. Ausência em um teste não demonstra ausência geral. Sem fonte conectada, mostrar “não medido”.

## Fontes oficiais consultadas em 29/09/2026

- [OpenAI — crawlers](https://developers.openai.com/api/docs/bots): OAI-SearchBot para busca; GPTBot para conteúdo que pode ser usado em treinamento; ChatGPT-User para ações iniciadas por usuários. Controles independentes. Não exigir GPTBot como condição para aparecer na busca.
- [Google — recursos de IA e seu site](https://developers.google.com/search/docs/appearance/ai-features): fundamentos de SEO, texto acessível, links internos e dados estruturados coerentes continuam relevantes. Não exige arquivo de IA ou marcação especial; inclusão não é garantida.
- [Perplexity — crawlers](https://docs.perplexity.ai/docs/resources/perplexity-crawlers): distinguir PerplexityBot de requisições iniciadas por usuários; verificar identidade e acesso efetivo.

`llms.txt` pode ser avaliado como experimento documentado, sem tratá-lo como requisito universal ou fator de pontuação. Nenhum desses ajustes garante que um assistente citará ou recomendará o site.

## Pendências após a entrega de conteúdo

- **Rotas e retirada editorial:** RR-01 corrigido e validado nos três idiomas; o 404 de RR-05 pertence a notícia rejeitada/não publicada e ausente do sitemap. Não reabrir esses itens apenas pelos achados brutos de rechecagem. A diferença de caixa nos escapes percentuais gerava avisos na regra técnica legada; a regra v2, publicada no painel em 04/10, reconhece a equivalência e preserva os relatórios anteriores.
- **SH-02:** conferir fatos e organizadores: há lacunas em 37 de 38 eventos Road Runners e 96 de 99 Open Results na cobertura atual. Consulta anterior confirmou organizador nomeado em 1.332 de 34.320 eventos ativos. Não preencher com cronometrador nem inferir disponibilidade pela data; validar fontes, fusos, distâncias, edições e imagens.
- **Idiomas:** reciprocidade técnica preservada: 27 aprovados, nenhum com atenção e 73 sem evidência no Road Runners. Busca e institucionais corrigidos em PT/EN/ES. RR-08 tem técnica coerente, com política editorial pendente. A conferência de descrições às 19:28 tem cinco versões com idioma esperado/texto diferente, um fallback PT e seis inconclusivas; não mede fidelidade. RR-11 acompanha a fila e o cron pausado: 654 EN e 655 ES prontas, 2.497 EN e 257 ES rejeitadas, além de 1.535 PT prontas. Últimas falhas em 25/09: HTTP 424/provider_quota_exhausted. Esclarecer a pausa e conferir saldo atual antes de retomar.
- **Acesso e medição:** nove logs existentes e faixas oficiais atuais conferidos. Logs combined compartilhados sem hostname e normalização IP desigual impedem prova por site; Apache/CDN/WAF preservados. A audiência própria Road Runners registrou 66 visualizações em 36 sessões com referência exata do ChatGPT, entre 17.329 visualizações e 6.981 sessões distintas nos sete dias medidos. Não comprova citação, recomendação ou conversão. Open Results sem cobertura nessa fonte: manter não medido. Citações por perguntas fixas e conversões permanecem pendentes.

- **Privacidade Open Results (OR-02):** entrega concluída e revalidada em 03/10. O cache expirou; robots público permite /resultados e mantém /perfil bloqueado. Dois caminhos individuais com noindex; home e evento sem noindex. Remoção efetiva do índice não verificada; nomes em listagens de eventos continuam possíveis.

Fonte adicional consultada em 03/10: [Google — versões localizadas e reciprocidade](https://developers.google.com/search/docs/specialty/international/localized-versions).

## Entrega: situação no Google — 03/10/2026

Publicado o registro externo datado, separado da auditoria técnica, em `seo_search_evidence.cfm`. SH-03 concluído; OR-04 P1 aberto. Fórmula, históricos e snapshots técnicos preservados. Quatro templates compilados; 51 testes Node e renderização Adobe aprovados; desktop e celular sem transbordamento e expansão por teclado funcional. Backup `/var/backups/seo-search-status-20261003/baseline`. Detalhes em `2026-10-03_seo_search_status.md`.

### Evidência direta do Search Console

Consulta autenticada somente leitura em 03/10/2026, relatório atualizado em 20/09/2026, todas as páginas conhecidas. RoadRunners: 14,1 mil indexadas/109 mil não indexadas (valores arredondados); 167 soft404, 52 HTTP404, 23 5xx e cinco 403 entre os motivos. Primeiros exemplos 5xx: `/desafiocna/estatisticas/2025/` com filtros regionais. A primeira rechecagem da URL de VALINHOS excedeu 35 s, sem confirmação de status HTTP. Em 04/10, o backend e os filtros foram corrigidos (RR-13); cinco URLs responderam 200. A primeira carga levou 5,2 s e os filtros cerca de 0,2 s com cache. A comparação no Google continua pendente. OpenResults: zero indexadas,135.791 bloqueadas403,3.286 rastreadas não indexadas,35canonicalalternativo,2canonicaldivergente. Evidência no painel atualizada sem confundir esses totais com sitemap ou recuperação atual. Artefatos em `_codex/staging/seo-google-index-20261003/evidence.json`; backup `/var/backups/seo-google-index-20261003/baseline`. Nenhum botão de validar correção/indexação acionado.


## Entrega: estatísticas de 2025 — 04/10/2026

RR-13 concluído na entrega técnica. Otimizadas as leituras anuais de atividades e doações, preservando regras e totais. A comparação de cidade, estado e região no QoQ passou a ignorar caixa; estados vazios e ausência de atividades deixaram de provocar divisões inválidas. Rótulos de filtro usam parâmetros explícitos com escape HTML. Dois arquivos publicados no RoadRunners com backup `/var/backups/seo-stats-20261004-v2/baseline` e hashes verificados; quatro dependências preservadas.

Validação: oito comparações sintéticas e quatro comparações reais sem divergência (2.126 linhas e 365 dias; tolerância de 1 mm para somas DOUBLE), sete renders Adobe, cinco URLs públicas 200 e desktop/mobile sem overflow. Consulta principal medida em 2,967 s sem cache; banco em 0,950 s. O banco agora compartilha a janela de cache de uma hora da consulta principal. Revisão Astra validou a semântica após comprovação de PRIMARY KEY/NOT NULL das atividades.

Business: evidência de disponibilidade atualizada e item RR-13 registrado. São 20 itens, 16 resolvidos na entrega e quatro pendentes; relatório Google continua warning para RoadRunners e error para OpenResults. Dois templates compilados/publicados, render candidato e publicado aprovados e 51 testes Node passando. Notas técnicas e snapshots da auditoria ampla preservados. Backup `/var/backups/seo-stats-panel-20261004/baseline`.

Registros: `RoadRunners/_codex/docs/2026-10-04_seo_estatisticas_2025.md`, `_codex/staging/seo-stats-20261004/` e `_codex/staging/seo-stats-panel-20261004/`. Sem nova auditoria ampla, pedido de indexação ou validação no Search Console. Próximo lote: continuar a revalidação dos erros reais do RoadRunners e as lacunas de fatos dos eventos com audiência. Permanecem dependentes de decisão/dados: política editorial, retomada do cron pago e fonte principal de receita.


## Entrega: organizador informado — 04/10/2026

O RoadRunners passou a exibir o campo legado `organizador` quando não existe relação formal nomeada de organizador. O vínculo formal tem prioridade; cronometragem não é usada como organizador. O nome informado aparece em HTML com rótulo PT/EN/ES e link seguro da página do evento, quando disponível. Não foi inferido o tipo Person/Organization nem ampliado o JSON-LD.

Inventário somente leitura: 34.318 eventos ativos, 14.335 com texto, 1.332 com vínculo nomeado e 13.068 com texto sem vínculo. O último número indica potencial de cadastro, não páginas individualmente verificadas nem fatos confirmados. A fonte Sympla do BMFIT foi conferida; nenhuma alegação de validação universal.

Dois arquivos publicados e verificados, com backup `/var/backups/seo-event-facts-20261004-v2/baseline`. Sessenta verificações CFML e 13 renders sintéticos passaram; revisão Astra corrigiu tratamento de arroba em query de URL válida. Doze páginas públicas em três idiomas responderam 200, com JSON-LD e canonical idênticos ao baseline. Include direto403. Desktop e mobile conferidos. Uma diferença preexistente no cabeçalho de tema foi preservada tanto na produção quanto no checkout.

SH-02 permanece aberto para revisão factual e cadastro. O painel registra a entrega nesse item, sem criar mais um item resolvido e sem alterar os snapshots técnicos ou a situação histórica do Google. Continuam 20 itens, 16 resolvidos na entrega e quatro pendentes. Artefatos: `_codex/staging/seo-event-facts-20261004/` e `_codex/staging/seo-event-facts-panel-20261004/`.


## Entrega: comparação de URLs e auditoria — 04/10/2026

O coletor RoadRunners e o scorecard Business reconhecem diferenças de caixa hexadecimal em escapes percentuais, conforme RFC3986 §6.2.2.1. A reciprocidade já fazia isso; alinhamento de canonical e referência hreflang à própria página agora usam a mesma equivalência. Não decodificam escapes, nem alteram caixa do caminho ou query. URLs brutas continuam no relatório.

Regras do coletor v2 e método `technical-checks-v2`, com os mesmos pesos. O histórico existente foi preservado e o novo ponto está marcado como não comparável ao método anterior. Não publicar scripts operacionais no docroot. Testes RED reproduziram os dois falsos avisos; 81 testes focais e 89 do coletor/orquestrador passaram (há sobreposição entre suítes). Revisão Astra sem achados acionáveis.

Auditoria completa dentro da amostra: execução `2026-10-04T04-02-59-664Z-aa93a0fd`, 04/10 às01:02 Brasília, 104.006 URLs descobertas,100 inspecionadas,zero erros operacionais,1erro20avisos. Nota70/100:9 critérios certos,4atenção,1erro,2não medidos. Exit2 corresponde a achados SEO numa execução completa. Reaplicação da regra antiga às mesmas observações demonstrou exatamente dois falsos canonical.mismatch retirados: Operário e Corrida Fit UFC Crateús. Não é evidência de mudança nas páginas.

Publicados os snapshots de score e fila após compilação Adobe e render candidato. Situação no Google preservada: RoadRunners com pendências, OpenResults com falha de sitemap ainda não revalidada. OpenResults sem nova coleta; medições e data anteriores idênticas, apenas ponto de histórico sob método v2, sem delta comparável. Vinte itens/16resolvidos/4pendentes permanecem.

Backup `/var/backups/seo-url-comparison-20261004/baseline`; artefatos em `_codex/staging/seo-url-comparison-20261004/`. Esta entrega melhora a confiabilidade do acompanhamento, não comprova tráfego, indexação, receita ou citação por IA.


## Entrega: fontes e conferência dos eventos com audiência — 04/10/2026

A medição própria dos sete dias até04/10às01:08 priorizou5eventos históricos: Salvador147visualizações, CorreRD108, Criciúma105, Garoto79 e Goiânia65; total504. Conta visualizações distintas de páginas, não receita nem somente aquisição orgânica. Dados agregados sem identificadores de visitantes em `_codex/staging/seo-top-events-20261004/audience-top.json`.

Conferidos os regulamentos de Salvador/Criciúma/CorreRD e fontes primárias Motiva/Yescom para Goiânia/Garoto. Revisão parcial por campo, registrada em review.json. Salvador tem divergência27Sepversus26–27Sep. Goiânia tem4,28km adicional à divulgação4/8km. A distância16km de Garoto é chave nominal ligada a17.606resultados, enquanto fonte informa16.090m: não renomear automaticamente. Criciúma confirma26–27Sep comKids no primeiro dia; descrição contém unidade sem número para revisão. Sem alterações no cadastro, nas distâncias ou em resultados.

Publicado link Regulamento do evento nas páginas RoadRunners com url_regulamento válida, nos três idiomas. Ajuda o leitor a consultar a fonte e não implica validação de todos os fatos. Novo include e index publicados com backup `/var/backups/seo-event-regulation-20261004/baseline`. RED15falhas/GREEN30checks10renders, compilação2templates e revisãoAstra semachados. QuinzeURLs200,9comlink/6semfonte, canonical/JSON-LD preservados; include direto403; desktop/mobile conferidos; hashes2/dependências5 confirmados.

Painel registra entrega e divergências no SH-02, ainda aberto. Contagem20/16/4 e auditoria das01:02 preservadas. Backup do painel `/var/backups/seo-event-regulation-panel-20261004/baseline`. Próxima ação factual: distinguir medidas nominais de percursos e corrigir texto com unidade sem valor após rastrear a origem, sem modificar chaves ligadas a resultados. Evidências em seo-top-events-20261004, seo-event-regulation-20261004 e seo-event-regulation-panel-20261004.


## Entrega: categorias e unidades dos eventos — 04/10/2026

Rastreada e corrigida a unidade vazia observada em Criciúma: o cadastro continha kids, mas o resumo removia letras e acrescentava km. O mesmo bloco podia alterar metros/milhas, cortar vírgulas decimais e duplicar km no caso único. Agora preserva o texto cadastrado com escape HTML e rótulos neutros PT/EN/ES; treino continua sem bloco e categoria vazia usa aviso existente. Não houve alteração no banco, nas chaves de percursos ou nos resultados.

Publicado novo include categorias.cfm e seu ponto de chamada. RED17falhas, GREEN40checks11renders, compilação2templates, revisãoAstra sem achados. Quinze URLs reais nos três idiomas responderam200 com categorias corretas e canonical/JSON-LD idênticos ao baseline. Include direto403; desktop/mobile sem overflow. Dois hashes e seis dependências verificados. Backup /var/backups/seo-event-distances-20261004/baseline. Fontes locais receberam somente o hunk publicado, preservando diferenças anteriores. Artefatos em seo-event-distances-20261004/.

A correção trata apresentação, não resolve as divergências factuais de Salvador, Goiânia ou Garoto. SH-02 permanece aberto e não se deve renomear a chave nominal16km ligada aos17.606resultados. Próximo passo factual deve confirmar a programação por percurso em Salvador e a origem da medida4,28km em Goiânia antes de qualquer alteração de cadastro.

Painel atualizado e verificado:20itens,16resolvidos,4pendentes; SH-02aberto; estados Google e auditorias preservados. Backup /var/backups/seo-event-distances-panel-20261004/baseline; compilação1template, renders candidato/publicado aprovados,1hash e5dependências confirmados.


## Entrega: correção factual de Salvador e revisão de Goiânia — 04/10/2026

A página oficial da TicketSports e o regulamento atualmente vinculado confirmaram Salvador em 26 e 27/09/2026. A descrição oficial distribui 5/10 km no sábado e 21/42 km no domingo; a reportagem de programação do GE de 23/09 confirma também os 3 km no sábado. Corrigidos o início do evento 36245, a fonte do regulamento e as datas dos percursos 3/5/10. Final 27/09, medidas nominais, IDs, categorias, descrições, organizador e resultados preservados. Há conflito de local entre endereço e descrição na própria fonte oficial; localização permanece pendente. Fontes em `_codex/staging/seo-factual-followup-20261004/source-review.json`.

O portal da Agência Municipal de Turismo e Eventos de Goiânia explica que a modalidade de 4 km tem aproximadamente 4,28 km em função dos retornos da pista. Essa divergência foi esclarecida; não excluir nem renomear percursos. A antiga página da TFSports retornou “Página não encontrada” após carregamento.

A correção de dados teve backup privado em `/var/backups/seo-factual-followup-20261004/`, dois ensaios transacionais revertidos (incluindo a rotina inversa), comparação de hashes completos sob locks e verificação de resultados inalterados. Revisão Astra solicitou melhorias de recuperação e reversão, ambas implementadas e revalidadas. O modo reconcile aceita somente o estado integral anterior ou o esperado, permitindo recuperar uma resposta perdida após commit sem repetir a mutação.

Painel publicado: SH-02 atualizado e mantido aberto, com 20 itens/16 resolvidos/4 pendentes. Compilação de um template, renders candidato/publicado e hash confirmados; cinco dependências, notas técnicas e estados Google preservados. Backup `/var/backups/seo-factual-followup-panel-20261004/baseline`.

Verificação pública concluída: quatro páginas HTTP200 (RoadRunners PT/EN/ES e evento OpenResults); canonical preservado; JSON-LD mudou somente startDate e as frases localizadas de data esperadas. OpenResults refletiu a alteração depois do cache normal de três minutos. Desktop e celular conferidos. Sem mudanças de runtime ou privacidade no OpenResults.

Próximo lote priorizado por audiência própria: entre os 300 eventos mais vistos de 27/09 às01:34 a04/10 às01:34, 156 estão ativos com data final a partir de04/10. Cinco primeiros: LIVE! RUN XP Rio2026 (51 visualizações), Bonito2026 (38), Maratona Internacional do Paraná2027 (33), São Paulo2027 (31) e Floripa2027 (25). Medição inclui todos os canais e não representa receita. Dados em `_codex/staging/seo-upcoming-priority-20261004/priority.json`; fatos desses eventos ainda serão conferidos nas fontes.


## Entrega: cinco próximos eventos prioritários — 04/10/2026

Conferência concluída nas páginas e regulamentos oficiais do lote de 178 visualizações: LIVE Rio/Bonito2026, Paraná/SP/Floripa2027. Bonito corrigido de6para5km nas descrições PT/EN/ES; a URL oficial com slug jurer é válida. São Paulo tinha descrição da edição2026: agora informa a31ªedição em04/04/2027, com7/14/21/42km e a Corrida das Nações separada em03/04. Descrições nos três idiomas e metadados de tradução atualizados juntos. Vínculo formal Yescom já existente, preservado.

Paraná: data do percurso10km corrigida de26para28/03/2027. Floripa: início do evento e meia maratona corrigidos de29para28/08;5/42km continuam29/08. Cinco links de regulamento publicados: PDF atual deSP/Floripa, documento Drive oficial doParaná e páginas LIVE com botão de regulamento HTML. Sem mudanças de horários, preços, disponibilidade ou inscrição.

Backup `/var/backups/seo-upcoming-priority-20261004-v2/`. Ensaios de aplicação e inversão revertidos, hashes de5eventos/11percursos,13tabelas de dependências preservadas. Nenhum percurso excluído/recriado; flags finais preservados. Astra identificou comparação apóscommit; movida para dentro da transação e teste negativo confirmou rejeição semgravarpersistente. Revisão final sem achados.

18URLs públicasHTTP200; canonical preservado. JSON-LD só alterou data inicial e frase de data deFloripa. OpenResults refletiu alterações após cache normal, sem mudanças de runtime ou privacidade. Desktop1440/mobile390verificados, semoverflow.

Painel SH-02 atualizado e aberto:20itens/16resolvidos/4pendentes. Compilação1template, renders candidato/publicado,1hash e5dependências verificados. Google e histórico técnico preservados. Backup `/var/backups/seo-upcoming-panel-20261004-v2/baseline`. Artefatos `_codex/staging/seo-upcoming-priority-20261004/` e `seo-upcoming-panel-20261004/`. Sem nova auditoria ampla ou alegação de indexação/citação em IA.

Próximo ponto observado: verificar a consistência das marcas históricas exibidas como recordes da prova principal no agregado deSãoPaulo; a página mostrou01:42:19/2008, ainda sem diagnóstico de distância/edição. Não alterar resultados por inferência.


## Investigação: recordes históricos de São Paulo — 04/10/2026

Confirmadas divergências entre os resultados armazenados selecionados para os recordes e a fonte oficial de campeões Yescom: masculino2008,01:42:19versus02:17:07; feminino1998,02:16:54versus02:39:58. O vencedor masculino oficial consta em segundo na base. A origem da divergência ainda não foi determinada; faltam a lista completa e o histórico de processamento. Athlinks não acessível pelas ferramentas usadas. Nenhuma classificação, resultado ou atributo pessoal alterado.

RR-14 registrado como pendente no painel:21itens/16entregues/5pendentes. O primeiro candidato continha links externos vedados pelo contrato; houve publicação indevida após falha de renderização, seguida de rollback e verificação da versão restaurada. A versão corrigida usa somente a URL pública RoadRunners no campo permitido. Fontes externas preservadas na documentação.

Compilação1template, renderizações das abas relatório/fila candidata e publicada,1hash e5dependências aprovados. Publicação agora exige recibo de render aprovado e vinculado aos hashes. Notas técnicas e evidência Google preservadas. Backup /var/backups/seo-record-panel-20261004-v2/baseline. Detalhes em 2026-10-04_seo_recordes_historicos.md. Próxima ação: rastrear a origem antes de preparar correção de dados reversível.

Rastreamento posterior de RR-14: três importações em17/04/2026 sem erro de execução; nenhuma linha temporária ou log detalhado retido para as duas edições. Nenhum webhook correspondente encontrado na janela01–17/04. A escolha de intervals[0] no coletor atual é um ponto de revisão, não causa comprovada. Não executar reimportação sem fonte completa/payload e revisão da versão histórica. Localização dos arquivos solicitada ao usuário. Evidências em seo-record-evidence-20261004/trace-conclusion.json.


## Entrega: identidade estruturada da home — 04/10/2026

RR-15 concluído: WebSite Road Runners e Organization RunnerHub Inteligência Esportiva relacionados por publisher e IDs estáveis. O conteúdo público de /sobre/ declara essa relação. Grafo nas homes PT/EN/ES, somente em prod, sem parâmetros de URL ou dados de sessão. Nenhum dado legal, contato, logo ou sameAs inferido; marcação preexistente tem prioridade. O include é chamado somente pela home, antes do head existente.

Dois templates publicados com backup /var/backups/seo-site-identity-20261004/baseline. RED confirmou três falhas nas homes; GREEN23checks/8cenários Adobe, compilação2templates, revisãoAstra sem achados,6URLs públicas200, acesso direto ao include403. Canonical, alternates, robots e marcação anterior idênticos ao baseline. Dois hashes e seis dependências preservadas. Sem alteração visual, layout ou autenticação; dev/beta verificados na fixture sem modificar proteções reais.

Painel atualizado e verificado:22itens/17entregues/5pendentes. Compilação1template, renders candidato/publicado das abas relatório/fila,1hash e5dependências confirmados. Google, auditorias e notas técnicas preservados. Backup /var/backups/seo-site-identity-panel-20261004/baseline. Não houve teste de resultado enriquecido nem evidência de escolha do nome pelo Google, indexação ou citação por IA.

Fontes: https://roadrunners.run/sobre/ e https://developers.google.com/search/docs/appearance/site-names, consultadas04/10. Detalhes em RoadRunners/_codex/docs/2026-10-04_seo_identidade_site.md; artefatos Business/_codex/staging/seo-site-identity-20261004/ e seo-site-identity-panel-20261004/.


## Entrega: idioma HTML da listagem de vídeos — 04/10/2026

Corrigida a interpolação do atributo lang em RoadRunners/videos/index.cfm. Antes, as três versões publicavam literalmente #REQUEST.htmlLang#; agora retornam pt-BR, en e es. Alteração de uma linha, com saída escapada, sem mudanças de conteúdo, layout ou rotas.

Baseline local/produção idêntico, backup /var/backups/seo-video-language-20261004/baseline, compilação de um template e três verificações no Adobe ColdFusion aprovadas. Verificação pelo navegador nas três URLs públicas confirmou os idiomas e a preservação de canonical e quatro alternates. Hash publicado e três dependências compartilhadas conferidos. Artefatos em _codex/staging/seo-video-language-20261004/.

O cliente Python urllib recebeu Cloudflare 403/1010, enquanto o navegador carregou a página; isso não comprova bloqueio do Google. Nenhuma regra Cloudflare alterada. VideoObject permanece pendente: a página atual agrega vídeos abertos em modal e ainda não possui páginas individuais de reprodução. A correção de lang não demonstra indexação nem resultado enriquecido. Não houve nova auditoria ampla; contadores e notas históricas do painel permanecem inalterados.


## Entrega: breadcrumb dos eventos — 04/10/2026

Publicado caminho visível e BreadcrumbList nas páginas de evento RoadRunners: Início localizado → Corridas em UF → evento canônico. O estado só entra para país BR e UF válida; outros casos ficam com início/evento. Links regionais apontam para as páginas existentes em português e indicam hreflang. Sem consultas ou alterações de dados; SportsEvent preservado.

Sessenta verificações Adobe, compilação2templates e revisão independente sem achados. Comparação pública PT/EN/ES da Maratona de SãoPaulo2027 preservou canonical, robots, alternates e SportsEvent. Desktop1440/celular390 sem overflow; navegação ao estado via Tab/Enter confirmada. Backup /var/backups/seo-event-breadcrumb-20261004/baseline. Divergência preexistente do cabeçalho de tema mantida nos respectivos ambientes.

Painel: evidência acrescentada ao RR-12, mantendo22itens/17entregues/5pendentes. Compilação1template, renderizações candidata/publicada das duas abas e hashes verificados; notas e evidência Google inalteradas. Backup /var/backups/seo-event-breadcrumb-panel-20261004/baseline. Detalhes em RoadRunners/_codex/docs/2026-10-04_seo_breadcrumb_evento.md. Sem recrawl, Rich Results Test ou comprovação de indexação/citação.


## Entrega: segundo lote de próximos eventos — 04/10/2026

Cinco eventos priorizados por 108 visualizações na medição própria: Porto Alegre 2027, Corrida de Impacto, Aracaju 2026, LIVE Juiz de Fora e Jurerê 2026. Corrigidas nove datas de percursos, a data inicial de Jurerê e as menções de data nas descrições PT/ES de Impacto. Quatro links de regulamento atualizados. Impacto EN permanece com fallback português, sem tradução inventada.

Fontes oficiais e regulamentos atuais conferidos; divergências de endereço/horário e disponibilidade ficam pendentes. Nenhuma alteração de resultados, distâncias, categorias, horários ou inscrição. Cinco eventos e dezesseis IDs de percursos protegidos por comparação integral; treze tabelas dependentes preservadas. Aplicação e inversão ensaiadas com rollback, teste negativo de drift aprovado e revisão independente sem achados. Backup privado /var/backups/seo-upcoming-second-20261004/.

Quinze páginas públicas PT/EN/ES comparadas antes/depois: canonical e alternates preservados; SportsEvent mudou somente a data inicial e a frase correspondente de Jurerê. Painel publicado e verificado nas abas relatório/fila: 22 itens, 17 entregues, 5 pendentes; SH-02 permanece aberto. Compilação de um template, renders candidato/publicado, hash do arquivo e cinco dependências confirmados. Backup /var/backups/seo-upcoming-second-panel-20261004/baseline. Notas técnicas e evidência Google mantidas; sem nova auditoria ampla ou comprovação de indexação.

Detalhes em 2026-10-04_seo_segundo_lote_futuro.md. Próxima investigação: origem das divergências entre datas de evento, percurso e descrição, preservando eventos de vários dias.


## Entrega: preservar percursos editados manualmente — 04/10/2026

Investigação das rotinas reais do banco confirmou que uma mudança exclusiva de data do evento não sincroniza os percursos. Ao alterar categorias, a geração usa uma heurística por distância: menores que 21 no primeiro dia, de 21 até menos de 42 no segundo dia, 42 ou mais no último. Isso não representa a programação oficial de todas as provas. A origem histórica de cada divergência ainda não foi comprovada.

Defeito reproduzido e corrigido: o trigger poupa da exclusão os percursos marcados percurso_bloqueado=true, porém seu ON CONFLICT sobrescrevia data/unidade dessa mesma linha. A procedure de geração também sobrescrevia. Ambas agora só atualizam conflitos quando o percurso existente não está bloqueado. O Business já marca como bloqueada a edição manual pela ação salvar_evento_percurso. Não houve mudança de formulário nem sincronização genérica de datas.

Doze cenários PostgreSQL em tabelas e rotinas pg_temp, com sequence temporária e rollback: baseline apresentou as duas falhas esperadas; candidato e definições publicadas passaram 12/12. Incluem preservação integral de linha bloqueada e seu ID, geração/atualização de linhas automáticas, inclusão de distância, categorias nulas, vínculo de organizador e prova de um dia. O cenário de alteração exclusiva de data documenta a limitação existente, não afirma sua correção.

SQL em _codex/sql/2026-10-04_preservar_percursos_bloqueados.sql; artefatos e executor em _codex/staging/seo-route-date-origin-20261004/. Backup privado /var/backups/seo-route-date-origin-20261004/. Baseline conferido, ensaios de aplicação/inversão e falha forçada antes do commit aprovados. Publicação de duas definições sob transação e locks com timeout, comparação integral de todos os eventos/percursos antes/depois e preservação de owner, ACL, configuração e triggers. Revisão independente sem achados bloqueadores. Nenhum registro de evento, percurso ou resultado corrigido nesta entrega; privacidade e runtime OpenResults preservados.

Consulta de 04/10: 169 percursos em 86 eventos futuros ativos fora do intervalo cadastrado do evento, entre 4.164 percursos de 2.012 eventos com percursos. Nenhum dos 169 estava bloqueado; esta proteção não resolve esses casos automaticamente. Listagem datada para revisão em date-divergences.json, sem dados de atletas. As discrepâncias incluem casos legítimos de programação separada, portanto não são 169 erros factuais confirmados. Próxima ação: conferir fontes por audiência antes de corrigir qualquer valor, preservando eventos de vários dias e histórico de resultados.

Painel SH-02 atualizado e mantido aberto: 22 itens, 17 entregues, cinco pendentes. Compilação de um template, renderizações candidata/publicada de relatório/fila, hash e cinco dependências verificados. Backup /var/backups/seo-route-date-panel-20261004/baseline. Evidência Google e notas técnicas históricas inalteradas.


## Entrega: datas de percursos prioritários — 04/10/2026

Cruzamento da listagem de divergências com os 300 eventos mais vistos na janela 27/09 às 01:34–04/10 às 01:34. Selecionados os cinco primeiros: LIVE Rio (51 visualizações), LIVE Niterói (19), Night Run Curitiba (16), Night Run Maceió (9) e Corrida do 5º BEC (8), total 103, todos os canais; não representa receita nem aquisição orgânica isolada.

Fontes oficiais confirmaram as datas já cadastradas nos eventos; onze percursos guardavam datas diferentes. Corrigidos: Rio 5/10/21 km de 15/11 para 02/11/2026; Niterói 5/10 de 13/12 para 01/11; Curitiba 5/10 de 17/10 para 31/10; Maceió 5/10 de 12/11 para 21/11; 5º BEC 5/10 de 01/07 para 11/10. As onze linhas foram marcadas como edição manual bloqueada, conforme comportamento existente do Business, para preservar as datas conferidas na geração automática. IDs, distâncias e demais campos dos percursos mantidos.

LIVE: datas confirmadas na página e Artigos 1/3 dos regulamentos HTML. Running Land: páginas oficiais carregadas no navegador, com data, ano e distâncias; não foi localizado regulamento separado. BEC: descrição do produtor na Sympla informa 11/10/2026, com kits 08–10/10 e provas 5/10 km; a reportagem de 02/07 do Informa Rondônia corrobora. O cabeçalho da Sympla mostra 03–14/08, conflito registrado; não inferir cancelamento nem disponibilidade. Niterói também tem divergências de local/horário entre página e regulamento, fora deste lote.

Adicionado somente o link de regulamento de Niterói ao cadastro do evento. Nas três páginas PT/EN/ES, novo link confirmado e canonical, alternates, SportsEvent e BreadcrumbList preservados. As correções de percurso foram verificadas no banco; não são mudanças das datas principais exibidas na página. Nenhuma descrição foi alterada.

Artefatos: _codex/staging/seo-date-priority-20261004/, incluindo baseline, fontes, patch, ensaios, revisão, verificação e listagem restante. Backup privado /var/backups/seo-date-priority-20261004/. Aplicação/inversão com rollback e teste negativo antes do commit aprovados; revisão independente sem impeditivos. Publicação e verificação de cinco eventos, onze IDs de percursos e treze tabelas dependentes. Nenhuma classificação ou resultado alterado. Sem publicação de runtime RoadRunners/OpenResults ou mudança de privacidade.

Recontagem após publicação: 158 percursos em 81 eventos futuros ativos fora do intervalo do evento (antes 169/86). Isso não significa 158 erros confirmados; inclui casos que exigem conferir programação específica, como atividades separadas. A revisão factual SH-02 permanece aberta.

Painel publicado: evidência em SH-02; 22 itens, 17 entregues, cinco pendentes. Compilação de um template, renderizações candidata/publicada das abas relatório/fila, hash publicado e cinco dependências verificados. Backup /var/backups/seo-date-priority-panel-20261004/baseline. Google e notas técnicas históricas preservados.


## Entrega: recuperação do sitemap confirmada pelo Google — 04/10/2026

Consulta autenticada somente leitura, diretamente no Search Console. OpenResults: /sitemap.xml Processado, última leitura do índice em 03/10; quatro lotes Processado com leitura em 04/10 (10.000 + 10.000 + 10.000 + 4.319 = 34.319 URLs). Não foi necessário novo envio. OR-04 concluído; OR-05 aberto para acompanhar indexação. Relatório de páginas ainda atualizado em 20/09: zero indexadas, 135.791 bloqueadas por 403. Esse relatório antecede as mudanças de acesso e não comprova bloqueio atual nem recuperação.

RoadRunners: índice processado, 103.030 URLs; sete lotes processados. static.xml ainda tem 49 URLs e leitura de 30/09, anterior à ampliação regional. Demais lotes lidos em 02/03 de outubro. Relatório de páginas permanece em 20/09: 14,1 mil indexadas e 109 mil não indexadas (arredondados). Nenhuma nova auditoria técnica foi executada nesta entrega.

Business: publicados somente seo_queue_data.cfm e seo_search_evidence.cfm. Evidência atualizada, estado OpenResults em atenção (sitemap recuperado; indexação a confirmar), notas técnicas preservadas e recolhidas. Fila 23 itens, 18 concluídos, cinco pendentes. Dois templates compilados; relatório e fila renderizados em Adobe antes/depois, dois hashes e quatro dependências verificados. Backup recuperável em /var/backups/seo-google-recovery-20261004/baseline. Artefatos, evidência estruturada e recibos em _codex/staging/seo-google-recovery-20261004/. Sem mudanças Cloudflare, privacidade, banco, sites públicos ou Git.


Conferência final pela sessão administrativa real no Chrome confirmou os novos textos em /portal/seo/. Encontrada e corrigida a data fixa de 03/10 no título da evidência: agora remete à consulta e às datas apresentadas abaixo. Alteração de uma linha em seo_report.cfm, compilada, renderizada antes/depois e recarregada no navegador; cinco dependências preservadas. Backup adicional /var/backups/seo-google-recovery-heading-20261004/baseline. Total final de três templates Business alterados nesta entrega; nenhuma mudança nos sites públicos.


## Entrega: resposta correta de eventos inexistentes — 04/10/2026

Consulta direta ao Search Console: 167 exemplos soft 404 no relatório de 20/09, classificados por caminho (121 eventos, nove buscas, 36 perfis, um endpoint interno). Trinta e dois exemplos possuem parâmetros de ações, não executados. Amostra de 13 URLs sem ações: nove eventos e uma busca respondem 200; três tags ausentes enviavam 301 para busca genérica. Corrigido somente o ramo qEvento vazio para usar o handler 404 existente e abortar. Retorna orientação PT/EN/ES e status correto; eventos históricos encontrados continuam acessíveis. Registro operacional tb_log preservado; sem mutações nos cadastros/resultados ou alterações de privacidade/auth/WAF.

Um backend RoadRunners compilado, revisado e publicado. Teste Adobe: seis cenários, 33 verificações antes/depois; baseline reproduziu o defeito. Vinte URLs públicas após publicação: nove ausentes responderam 404 localizado, sem redirect e com documento único; onze válidas permaneceram 200 e conservaram H1/canonical/alternates/JSON-LD. Controle histórico Floripa incluído pelos chamadores adicionais do backend. Navegador confirmou orientação em inglês. Hash e oito dependências verificados. Backup /var/backups/seo-soft404-20261004/baseline; registro RoadRunners/_codex/docs/2026-10-04_seo_eventos_ausentes.md.

Business: RR-16 novo item parcial para a revisão dos demais exemplos, evitando declarar os 167 casos resolvidos. Fila24itens/18concluídos/6pendentes. Dois templates compilados, renderizados antes/depois, publicados com hashes e quatro dependências verificados; notas técnicas e estados Google preservados. Backup /var/backups/seo-soft404-panel-20261004/baseline. Fonte/evidência da consulta e amostra HTTP em _codex/staging/seo-soft404-20261004; recibos do painel em seo-soft404-panel-20261004. Nenhuma validação/indexação acionada no Google e nenhuma alegação de recuperação total.


## Entrega: fontes das datas de quatro eventos — 04/10/2026

RoadRunners: LIVE Rio, LIVE Niterói, Night Run Curitiba e Night Run Maceió agora apresentam fonte oficial, datas conferidas e conferência em 04/10. Bloco PT/EN/ES delimita a revisão a início/término; local, horários e inscrições não foram conferidos nessa revisão. Recibo manual desaparece se as datas do cadastro mudarem. 5º BEC excluído por conflito na fonte. Não houve alteração de dados de eventos, percursos, resultados ou JSON-LD.

Três templates compilados e publicados com baseline/backup, hashes e quatro dependências verificados. 54 verificações CFML aprovadas após baseline negativo; revisão independente sem bloqueadores. Quinze URLs públicas 200 com canonical/alternates/JSON-LD preservados, dois includes diretos 403. Desktop e mobile conferidos no navegador. Artefatos: seo-event-provenance-20261004; backup /var/backups/seo-event-provenance-20261004/baseline. Documentação RoadRunners: _codex/docs/2026-10-04_seo_fontes_datas_eventos.md.

Business: somente seo_queue_data.cfm atualizado/publicado. SH-02 permanece aberto e documenta recibos, escopo e limitações; 24 itens, 18 concluídos, seis pendentes. Um template compilado, relatório/fila renderizados antes/depois, hash e cinco dependências verificados. Notas técnicas e situação Google preservadas. Backup /var/backups/seo-event-provenance-panel-20261004/baseline.

A conferência é histórica e manual, sem detecção automática de alterações nas fontes. Histórico por campo e gestão dos recibos no cadastro continuam pendentes. Nenhuma alegação de exatidão geral, ganho de ranking ou citação por assistentes. Próxima etapa factual mantém 158 percursos em 81 eventos futuros para revisão, sem tratá-los como erros antes de consultar as respectivas fontes.


## Entrega: revalidação ampliada de soft 404 — 04/10/2026

Consultados os 96 endereços de eventos sem query presentes nos 167 exemplos do Google: 51 respondem 200 com H1/canonical/SportsEvent e 45 respondem 404, sem erros CFML/5xx ou JSON-LD inválido. Consulta de tags e aliases não encontrou correspondência para os 45 ausentes; nenhum redirect por semelhança foi criado. Nove URLs sem barra final já apontam canonical para a variante com barra. Não foram executadas as 25 URLs de evento com parâmetros de ação nem buscas, perfis ou endpoint interno.

Inspeção individual autenticada de /en/event/2022-2-dc-run/: página indexada, rastreamento Googlebot Smartphone em 24/09 às 11:12:49 com êxito, canonical reconhecido. O relatório agregado de 20/09 ainda lista esse exemplo como soft 404. A evidência contradiz uma leitura de falha atual para esta URL; não comprova indexação dos outros 50 endereços 200. Nenhuma solicitação de indexação, teste ao vivo ou validação global foi executada.

Painel Business: RR-16 atualizado e mantido aberto. Um template compilado, abas relatório/fila renderizadas antes/depois, hash publicado e cinco dependências verificados. Fila conserva 24/18/6 e notas históricas. Backup /var/backups/seo-soft404-census-panel-20261004/baseline. Não houve alteração de runtime RoadRunners/OpenResults ou cadastro. Documento: _codex/docs/2026-10-04_seo_soft404_revalidacao.md; evidências em seo-soft404-census-20261004. Próxima investigação deve considerar a inspeção individual e o atraso do relatório antes de tratar páginas válidas como ausentes.


## Entrega: canal de correção contextual de eventos — 04/10/2026

RoadRunners: link Informar correção junto às fontes, com rótulos PT/EN/ES, ligado ao atendimento existente. O ID validado do evento é preservado no retorno de login. Formulário autenticado recebe nome, URL localizada e prompts para erro/fonte; somente GET faz prefill. POST preserva o texto do usuário, sem criação automática de chamados ou edição de fatos. Fluxo creator-verificacao e regras de autenticação preservados.

Quatro arquivos publicados após compilação Adobe e revisão independente; 37 verificações de serviço/link e 60 de integração focal aprovadas. Nove páginas de eventos conservam canonical/alternates/JSON-LD; nove retornos de login e um bloqueio direto403 conferidos. Formulários reais autenticados em PT/EN/ES confirmados no navegador, com link desktop/mobile legível. Nenhum chamado enviado nem novo ciclo OAuth executado; callback inspecionado e sessão existente utilizada. Override beta anterior preservado; verificação funcional em produção. Backup /var/backups/seo-event-correction-20261004/baseline, quatro hashes e nove dependências verificados.

Business: SH-02 registra a entrega, permanece pendente; 24 itens, 18 concluídos, seis pendentes. Um template compilado/publicado, abas relatório/fila renderizadas antes/depois, hash e cinco dependências verificados. Notas técnicas e evidência Google preservadas. Backup /var/backups/seo-event-correction-panel-20261004/baseline. Nenhuma alteração no OpenResults. Documento RoadRunners: _codex/docs/2026-10-04_seo_canal_correcao_eventos.md. Histórico de alterações por campo e continuidade da revisão factual permanecem no plano.


## Entrega: quarto lote de datas futuras — 04/10/2026

RoadRunners: dez datas de percursos corrigidas em LIVE Fortaleza (20/11), Primavera Campo Grande (11/10), TGS Run (22/11) e Reis Magos (18/10). Dois links de regulamento adicionados e descrição TGS ajustada conforme aviso oficial de adiamento. Quatro eventos priorizados por 23 visualizações nos sete dias até 01:34; todos os canais. IDs e 13 tabelas dependentes preservados, proteção manual ativada nos dez percursos. Ensaio, inversa, teste de drift, revisão independente e verificação pós-publicação aprovados. Doze URLs PT/EN/ES 200 com canonical/alternates preservados e JSON-LD coerente. Backup /var/backups/seo-date-next-20261004.

Restam 148 percursos em 77 eventos futuros fora do intervalo, a conferir. IZ1 foi excluída: página 01/11 versus PDF 25/10, com conflito adicional de local. Nenhuma alteração nesse cadastro. Business: SH-02 atualizado e parcial, 24/18/6 mantidos; um template compilado, renderizado antes/depois, hash e cinco dependências verificados. Backup /var/backups/seo-date-next-panel-20261004/baseline. Notas técnicas e evidência Google preservadas; sem alterações no OpenResults. Documento: _codex/docs/2026-10-04_seo_datas_quarto_lote.md.
