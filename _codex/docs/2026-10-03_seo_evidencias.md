# SEO e SEO para IA — evidências de 03/10/2026

Publicado e verificado em produção, com revisão Astra e backup recuperável. O painel tem **16 itens: 13 concluídos e 3 pendentes**.

## Novas medições

**Descrições Road Runners.** Foram conferidas 18 URLs de seis eventos (quatro históricos e dois futuros) em PT/EN/ES, em 03/10 às 19:28 (Brasília). Das 12 versões alvo, cinco entregaram descrição anotada no idioma esperado e texto diferente da fonte, uma usou português como fallback e seis ficaram inconclusivas porque a página PT não tinha uma descrição marcada. A amostra foi selecionada e não representa todo o site. Idioma anotado e texto diferente não comprovam fidelidade; esse critério aparece separadamente como não medido. Conflitos explícitos de idioma dentro da descrição também ficam inconclusivos.

**Referências de IA na audiência.** A fonte própria, em produção e sem tráfego interno, registrou 17.329 visualizações e 6.981 sessões distintas no domínio roadrunners.run entre 26/09 às 19:13 e 03/10 às 19:13 (Brasília). Referências exatas do ChatGPT corresponderam a **66 visualizações em 36 sessões**. Nenhum outro assistente da lista apresentou referência nessa cobertura. A referência é declarada pelo navegador e não comprova citação, recomendação ou conversão. Open Results não teve cobertura nessa fonte; ausência de dados não significa zero visitas.

**Acesso de bots.** Foram lidos nove arquivos existentes, com 3.013.612 linhas, e consultadas as faixas IP oficiais atuais de cinco agentes. Ambos os sites usam access.log no formato combined, sem hostname; other_vhosts_access.log está vazio. A normalização de IP difere entre os vhosts. Os totais globais não foram atribuídos aos sites: acesso real por provedor e domínio continua não medido. Logs da origem também não mostram bloqueios anteriores na CDN/WAF.

**Privacidade Open Results.** O cache expirou. O robots público permite a leitura de /resultados e mantém /perfil bloqueado. Dois caminhos individuais entregaram noindex, enquanto home e evento de controle não entregaram essa restrição. Dois hashes e seis dependências foram preservados na verificação existente. OR-02 foi concluído somente no escopo de entrega; a desindexação efetiva não foi consultada no Search Console. Nomes nas listagens de eventos ainda podem aparecer.

## Pendências concretas

- **RR-11 — descrições e traduções.** O cron 15 foi encontrado inativo; última execução em 25/09/2026 às 21:14, em registro sem fuso. As cinco últimas falhas retornaram HTTP 424 e provider_quota_exhausted. Isso explica as falhas históricas; saldo atual não foi consultado. A fila tinha 654 versões EN e 655 ES prontas, 2.497 EN e 257 ES rejeitadas para revisão, além de 1.535 descrições PT prontas. É necessário esclarecer a pausa e conferir saldo antes de uma retomada controlada, preservando rejeições e a validação de fatos.
- **SH-02 — fatos e organizadores.** Completar informações com fontes comprovadas. Cobertura do JSON-LD não equivale a validação factual; não usar cronometrador como organizador.
- **RR-08 — política editorial.** Alinhar campos e política do canal antes de alterar a atribuição canonical à fonte.

Acesso por domínio precisa de uma fonte que identifique host e IP de forma confiável, ou de evidência na CDN, com avaliação própria de infraestrutura. Citações por perguntas fixas e atribuição de conversões ainda não foram medidas.

## Método e validação

Pesos e histórico technical-checks-v1 foram preservados. Road Runners mantém **70/100**, na auditoria de 03/10/2026, 17:12 (Brasília); Open Results tem **100/100**, na nova auditoria de 03/10/2026, 19:14 (Brasília), realizada após a expiração do cache. Conferências complementares têm suas próprias datas e escopos e não alteram a nota técnica.

A evidência privada agregada está em /Users/Shared/RunnerHubReports/seo/evidence/2026-10-03-evidence-v2.json. Próximas gerações leem evidence/latest.json por padrão, preservando a data original. Evidência malformada interrompe a geração. O snapshot público não contém corpos de páginas, nomes individuais, IPs, caminhos de requisição, prompts ou credenciais.

**Validação:** 67 testes Node, 10 Python e nove cenários CFML passaram. Astra identificou um falso positivo com idioma aninhado divergente; testes demonstraram a falha e a correção. Não houve outros findings Critical/Important. A mesma amostra foi recolhida após a correção.

**Publicação:** somente seo_score_data.cfm, seo_queue_data.cfm e o parágrafo introdutório de seo_ai.cfm. Os três templates compilaram no Adobe ColdFusion. Backup recuperável em /var/backups/seo-evidence-business-20261003/baseline. Três hashes publicados e cinco dependências fora do escopo foram conferidos. O Adobe renderizou os 16 itens, 13 concluídos, três pendentes e 32 checks com datas/notas exatas. A fixture temporária restrita a loopback foi removida; essa verificação não representa login real de administrador. O preview desse HTML em 1280 px e 390 px não teve overflow horizontal; viewport restaurado, aba e servidor temporários encerrados.

Cron, dados de descrições, Cloudflare, Apache e políticas de treinamento foram preservados. Não houve consumo de créditos, reprocessamento de rejeitados ou operação Git.

Fontes primárias consultadas em 03/10: [OpenAI — bots](https://developers.openai.com/api/docs/bots) e [Perplexity — crawlers](https://docs.perplexity.ai/docs/resources/perplexity-crawlers). URLs e hashes dos cinco JSONs oficiais constam no staging/ranges.json; faixas IP não substituem o hostname ausente nos logs.
