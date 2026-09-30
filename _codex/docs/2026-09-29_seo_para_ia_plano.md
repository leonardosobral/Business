# Extensão proposta: SEO para IA

Objetivo: facilitar descoberta, leitura correta e citação de informações públicas de eventos, resultados e conteúdo editorial por assistentes. Este documento registra o plano e seu andamento; não autoriza alterar políticas de treinamento ou proteções de infraestrutura.

Status em 29/09/2026 às 21:22 (Brasília): etapa 1 publicada no Business e primeira entrega de conteúdo das etapas 2–3 publicada nos dois sites. O coletor passou a medir descrição, hreflang, sintaxe JSON-LD e campos dos eventos. Duas novas amostras de 100 páginas, coletadas após a publicação, atualizaram o painel. Open Results entrega SportsEvent; Road Runners preserva URLs com aspas e usa o papel de organizador do evento. Revisão factual ampla, reciprocidade entre idiomas, histórico específico de IA e etapas 4–5 permanecem pendentes. Evidências em `2026-09-29_seo_ia_conteudo.md`; a primeira entrega da interface está em `2026-09-29_seo_ia.md`.

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

- **RR-01 / RR-05:** a URL Operário com CRLF no identificador ainda retorna 403, mesmo após o usuário desligar Bot Fight Mode. A notícia antiga também permanece 404. Identificar a origem de cada falha e corrigir rotas/dados sem atribuir o 403 a uma regra específica ainda não demonstrada.
- **SH-02:** conferir fatos em fontes oficiais e completar o vínculo de organizador: ausente em 40 dos 42 eventos Road Runners e 96 dos 99 eventos Open Results inspecionados. Não preencher com o cronometrador ou inferir disponibilidade de inscrição pela data. Validar períodos longos, horários/fusos, distâncias, edições, imagens e fontes antes de ampliar a marcação.
- **Idiomas:** checar reciprocidade do hreflang e traduções na página entregue. O check básico atual não valida essas duas condições.
- **Acesso e medição:** analisar logs com identidade verificada e conectar evidências de citações/referrals. Permissão declarada no robots e resposta ao nosso coletor não substituem esses dados.
