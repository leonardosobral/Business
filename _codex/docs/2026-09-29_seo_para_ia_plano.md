# Extensão proposta: SEO para IA

Objetivo: facilitar descoberta, leitura correta e citação de informações públicas de eventos, resultados e conteúdo editorial por assistentes. Este documento registra o plano e seu andamento; não autoriza alterar políticas de treinamento ou proteções de infraestrutura.

Status em 03/10/2026: o painel foi publicado com 16 itens, 13 concluídos e três pendentes. Road Runners conserva a auditoria das 17:12 (Brasília), com 103.050 URLs descobertas, 100 inspecionadas e nota 70/100. Open Results tem nova auditoria às 19:14, com 34.321 URLs, 100 inspecionadas e nota 100/100, após expirar o robots em cache. OR-02 está concluído na entrega, sem comprovar desindexação efetiva. Há novas medições complementares de descrições, logs e audiência, cada uma com data e escopo próprios. Evidências e publicação em 2026-10-03_seo_evidencias.md e 2026-10-03_seo_evidencias_release.json; lotes anteriores preservados.

## Prioridade comercial — Road Runners (03/10/2026)

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

- **Rotas e retirada editorial:** RR-01 corrigido e validado nos três idiomas; o 404 de RR-05 pertence a notícia rejeitada/não publicada e ausente do sitemap. Não reabrir esses itens apenas pelos achados brutos de rechecagem. A diferença de caixa nos escapes percentuais ainda gera um aviso na regra técnica legada, sem diferença de destino.
- **SH-02:** conferir fatos e organizadores: há lacunas em 37 de 38 eventos Road Runners e 96 de 99 Open Results na cobertura atual. Consulta anterior confirmou organizador nomeado em 1.332 de 34.320 eventos ativos. Não preencher com cronometrador nem inferir disponibilidade pela data; validar fontes, fusos, distâncias, edições e imagens.
- **Idiomas:** reciprocidade técnica preservada: 27 aprovados, nenhum com atenção e 73 sem evidência no Road Runners. Busca e institucionais corrigidos em PT/EN/ES. RR-08 tem técnica coerente, com política editorial pendente. A conferência de descrições às 19:28 tem cinco versões com idioma esperado/texto diferente, um fallback PT e seis inconclusivas; não mede fidelidade. RR-11 acompanha a fila e o cron pausado: 654 EN e 655 ES prontas, 2.497 EN e 257 ES rejeitadas, além de 1.535 PT prontas. Últimas falhas em 25/09: HTTP 424/provider_quota_exhausted. Esclarecer a pausa e conferir saldo atual antes de retomar.
- **Acesso e medição:** nove logs existentes e faixas oficiais atuais conferidos. Logs combined compartilhados sem hostname e normalização IP desigual impedem prova por site; Apache/CDN/WAF preservados. A audiência própria Road Runners registrou 66 visualizações em 36 sessões com referência exata do ChatGPT, entre 17.329 visualizações e 6.981 sessões distintas nos sete dias medidos. Não comprova citação, recomendação ou conversão. Open Results sem cobertura nessa fonte: manter não medido. Citações por perguntas fixas e conversões permanecem pendentes.

- **Privacidade Open Results (OR-02):** entrega concluída e revalidada em 03/10. O cache expirou; robots público permite /resultados e mantém /perfil bloqueado. Dois caminhos individuais com noindex; home e evento sem noindex. Remoção efetiva do índice não verificada; nomes em listagens de eventos continuam possíveis.

Fonte adicional consultada em 03/10: [Google — versões localizadas e reciprocidade](https://developers.google.com/search/docs/specialty/international/localized-versions).
