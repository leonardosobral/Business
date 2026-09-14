# Piloto SEO e fila de correções — 13/09/2026

**Atualização às 21:29 (Brasília):** a descoberta RoadRunners foi recuperada e publicada. A nova rodada encontrou **99.360 URLs**, com os **33.095 eventos ativos** reconciliados nos três idiomas, e analisou 100 páginas. RR-02 foi concluído; RR-01 segue aberto para rotas/canonicals de tags especiais. Ver [execução e evidências posteriores](2026-09-13_seo_descoberta_execucao.md). Os números abaixo preservam o piloto anterior.

O primeiro ciclo instalou o coletor 2.0.0, as regras e os relatórios privados. A coleta real mostrou problemas acionáveis nos dois sites. O RoadRunners ainda precisa de correções na descoberta para formar uma baseline completa; o OpenResults já tem uma primeira amostra completa. Não foram alterados runtimes públicos neste ciclo.

A fila também pode ser consultada no [Portal de Conteúdo → SEO e correções](https://business.roadrunners.run/portal/conteudo/?visao=seo), com acesso administrativo. A tela mostra a revisão mais recente, que pode ser posterior a este piloto; abrir a página não executa nova auditoria.

## Medição observada

| Site | Início–fim UTC | URLs descobertas e aceitas | Páginas GET | Resultado |
| --- | --- | ---: | ---: | --- |
| RoadRunners | 18:18:48–18:21:10 | 1.090, descoberta incompleta | 100/100 | parcial, exit 1; 3 erros operacionais, 0 erros SEO/página, 111 avisos |
| OpenResults | 18:23:29–18:25:15 | 33.096, descoberta concluída | 100/100 | amostra completa, exit 0; 0 erros operacionais/SEO, 2 avisos |

Os avisos RoadRunners são 90 H1 múltiplos, 15 divergências de canonical (12 notícias e 3 destinos de login), 3 H1 ausentes e 3 redirects. OpenResults tem um H1 ausente na home e uma divergência de canonical. Quantidade de avisos não é quantidade de páginas distintas nem score de saúde.

O RoadRunners retornou um índice com sete filhos. Um lote inválido e dois timeouts impediram a descoberta completa. As 1.090 URLs correspondem aos lotes aceitos integralmente; não estimam o acervo. Um GET diagnóstico adicional do lote futuro retornou 8.268 entradas, incluindo nove URLs inválidas; essas entradas não foram acrescentadas retroativamente ao relatório do piloto. A contagem parcial 828 desse lote no manifesto é o ponto alcançado antes da primeira URL inválida, não URLs aceitas para seleção.

O OpenResults retornou quatro lotes válidos com 10.000, 10.000, 10.000 e 3.096 URLs. Somente 100 páginas tiveram o HTML auditado. Sitemap, HTTP 200 e canonical não comprovam indexação no Google.

## Evidência preservada

- [Manifesto RoadRunners](/Users/Shared/RunnerHubReports/seo/roadrunners/2026-09-13T18-21-10-289Z-75e99782/manifest.json) e [resumo](/Users/Shared/RunnerHubReports/seo/roadrunners/2026-09-13T18-21-10-289Z-75e99782/summary.md).
- [Manifesto OpenResults](/Users/Shared/RunnerHubReports/seo/openresults/2026-09-13T18-25-15-052Z-05353aa2/manifest.json) e [resumo](/Users/Shared/RunnerHubReports/seo/openresults/2026-09-13T18-25-15-052Z-05353aa2/summary.md).
- Extratos das conferências manuais: `/Users/Shared/RunnerHubReports/seo/pilot-review-20260913/`. Guardam status, headers pertinentes, canonical e trechos necessários, sem corpos HTML completos. O manifesto de extratos registra hashes.

Os hashes dos dois relatórios foram validados; diretórios 0700, arquivos 0600. O RoadRunners não possui ponteiro de última rodada completa. O OpenResults possui ponteiro válido. Os artefatos do piloto permanecem imutáveis; a apresentação do gerador foi melhorada depois para destacar erros operacionais antes da lista de avisos.

## Fila priorizada

### RR-01 — Corrigir URLs inválidas no sitemap futuro — P1

**Site/dono:** RoadRunners, manutenção do sitemap e dos identificadores de eventos.

**URL/regra:** `https://roadrunners.run/sitemaps/events-upcoming-1.xml`; `INVALID_SITEMAP` por `loc` inválido.

**Evidência:** nove URLs em três idiomas, correspondentes às tags abaixo. `\n` representa uma quebra de linha real:

```text
2026-rock-n-run\n----nashville-2026
2026-atibaia-run-fest-trail-mode-#03-socorro-pico-do-gaviao
2026-atibaia-run-fest-x-chopp-germania-corre-pela-breja-#01
```

**Impacto:** o lote não passa a validação integral; `#` produz fragmento e a quebra de linha invalida o identificador publicado. Não foi estimado o efeito no Google.

**Arquivo candidato:** [sitemaps/index.cfm:45](/Users/Shared/Projects/RunnerHub/RoadRunners/sitemaps/index.cfm:45) concatena tag sem codificar; [linha 156](/Users/Shared/Projects/RunnerHub/RoadRunners/sitemaps/index.cfm:156) só faz trim externo.

**Aceite:** URLs absolutas sem controle/fragmento nos três idiomas; codificação coerente com roteamento e canonical; casos especiais e duplicatas testados. Preservar identidade dos eventos; eventual mudança de tag em dados exige tratamento próprio, não alteração silenciosa pelo crawler.

### RR-02 — Investigar tempo de entrega dos lotes históricos — P1

**Site/dono:** RoadRunners, sitemap e infraestrutura responsável pela entrega.

**URLs/regra:** `https://roadrunners.run/sitemaps/events-history-1.xml` e `https://roadrunners.run/sitemaps/events-history-2.xml`; `TIMEOUT` de 15.000 ms.

**Evidência:** ambos excederam o deadline de recurso no piloto; não foram solicitados repetidamente. O lote 3 foi obtido.

**Impacto:** descoberta incompleta. Uma ocorrência não prova indisponibilidade permanente nem identifica se a demora está em consulta, geração, transferência ou CDN.

**Arquivos candidatos:** [sitemaps/index.cfm:11](/Users/Shared/Projects/RunnerHub/RoadRunners/sitemaps/index.cfm:11), lotes de 15 mil eventos × três idiomas; [geração XML:51](/Users/Shared/Projects/RunnerHub/RoadRunners/sitemaps/index.cfm:51) e [consulta:136](/Users/Shared/Projects/RunnerHub/RoadRunners/sitemaps/index.cfm:136).

**Aceite:** medir geração/bytes/cache e reduzir custo onde necessário; todos os filhos devem concluir dentro do orçamento operacional definido, com XML validado e contagens reconciliadas. Aumentar timeout isoladamente não demonstra a causa resolvida.

### RR-03 — Normalizar canonical das notícias — P2

**Site/dono:** RoadRunners, conteúdo editorial e metadados da rota.

**URL/regra:** `https://roadrunners.run/noticias/gleison-da-silva-santos-e-tricampeao-do-circuito-caixa-em-maceio/`; `canonical.mismatch`.

**Evidência:** HEAD e GET 200; o HTML declara a mesma URL terminando em `maceio//`. Doze notícias da amostra têm o padrão.

**Impacto:** sitemap e HTML indicam versões diferentes da URL; não comprova qual versão o Google escolheu.

**Arquivos candidatos:** [noticias/index.cfm:378](/Users/Shared/Projects/RunnerHub/RoadRunners/noticias/index.cfm:378), [normalização:14](/Users/Shared/Projects/RunnerHub/RoadRunners/noticias/index.cfm:14). O [head:38](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/estrutura/head.cfm:38) imprime o valor recebido. Rastrear captura em Application.cfc antes de ampliar escopo nesse arquivo sensível.

**Aceite:** canonical absoluto com uma barra final, coerente com rota final/sitemap; variantes com e sem barra, parâmetros e idiomas testadas, sem regressão de autenticação ou roteamento.

### OR-01 — Codificar a tag no canonical do evento — P2

**Site/dono:** OpenResults, metadados da página de evento.

**URL/regra:** `https://openresults.run/evento/2026-venha-viver-a-2-atleta-de-cristo-run-correndo-com-proposito%3F/`; `canonical.mismatch`.

**Evidência:** HEAD/GET 200 na URL com `%3F`; canonical contém `proposito?/`, transformando parte do identificador em query string.

**Impacto:** a declaração canônica não representa o mesmo caminho que o sitemap e o evento solicitado.

**Arquivos candidatos:** [evento/index.cfm:31](/Users/Shared/Projects/RunnerHub/OpenResults/evento/index.cfm:31), tag concatenada sem codificação; [includes/head.cfm:20](/Users/Shared/Projects/RunnerHub/OpenResults/includes/head.cfm:20), emissão. [sitemap.cfm:68](/Users/Shared/Projects/RunnerHub/OpenResults/sitemap.cfm:68) já codifica o segmento e serve de referência local.

**Aceite:** tratar tag como segmento, escapar o atributo HTML e manter codificação consistente; testar `?`, `#`, espaços e acentos, sem dupla codificação; a URL com `%3F` continua retornando o evento e declara o caminho correto.

### RR-04 — Retirar destinos privados do sitemap público — P2

**Site/dono:** RoadRunners, seleção do sitemap; autenticação permanece com o dono da rota.

**URLs/regra:** `/desafios/`, `/en/challenges/`, `/es/desafios/`; `http.redirect` e `canonical.mismatch`.

**Evidência:** amostra registra redirect para login nas três rotas; HEAD e GET adicionais de `/desafios/` confirmaram 302.

**Impacto:** sitemap anuncia URLs que exigem sessão e cujo destino final é login.

**Arquivos candidatos:** [sitemaps/index.cfm:119](/Users/Shared/Projects/RunnerHub/RoadRunners/sitemaps/index.cfm:119) e [desafios/index.cfm:18](/Users/Shared/Projects/RunnerHub/RoadRunners/desafios/index.cfm:18).

**Aceite:** sitemap contém destinos públicos canônicos; preservar a exigência de login e verificar as três variantes. Não abrir conteúdo privado para satisfazer a auditoria.

### SH-01 — Revisar hierarquia de títulos — P3

**Sites/donos:** templates RoadRunners e home OpenResults.

**URLs/regras:** home OpenResults (`h1.missing`), eventos/notícias RoadRunners (`h1.multiple`) e busca RoadRunners (`h1.missing`).

**Evidência:** o H1 promocional RoadRunners se soma ao título da página; notícia pode conter três H1. As homes/buscas indicadas não possuem H1 no HTML recebido.

**Impacto:** oportunidade de melhorar estrutura e acessibilidade; contagem isolada não impõe alteração e não prova penalidade de ranking.

**Arquivos candidatos:** [home_hero_busca.cfm:265](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/estrutura/home_hero_busca.cfm:265), [noticias/index.cfm:1243](/Users/Shared/Projects/RunnerHub/RoadRunners/noticias/index.cfm:1243), [busca_home.cfm:114](/Users/Shared/Projects/RunnerHub/RoadRunners/includes/busca_home.cfm:114) e [OpenResults/index.cfm:329](/Users/Shared/Projects/RunnerHub/OpenResults/index.cfm:329).

**Aceite eventual:** títulos descrevem a página e a hierarquia faz sentido; verificar acessibilidade, desktop e celular, preservando o visual pretendido. Não aplicar correção mecânica por número de tags.

### OR-02 — Conferir intenção da política Googlebot — revisão de política

**Site/dono:** OpenResults, responsável pelo conteúdo público e política de rastreamento.

**URL/evidência:** `https://openresults.run/robots.txt` possui grupo específico Googlebot com apenas `Disallow: /nogooglebot/`; as restrições `/perfil` e `/resultados` estão somente no grupo `*`. O grupo específico não herda essas restrições.

**Impacto:** diferença de acesso entre agentes. Não há prova de que seja acidental, e robots não substitui controle de acesso. As páginas públicas da amostra estavam permitidas.

**Arquivo candidato:** [robots.txt:1](/Users/Shared/Projects/RunnerHub/OpenResults/robots.txt:1).

**Aceite:** documentar a intenção por caminho e agente; só depois alinhar regras e testar. Não alterar política de treinamento IA ou acesso autenticado automaticamente.

## Conferência manual e limites

Foram conferidas seis páginas por site com HEAD e GET. RoadRunners: home, Alcance, notícia de Gleison, busca, desafios e Salvador. OpenResults: home, Bonito, Avenida Brasil, Ceap, o evento com `%3F` e Salvador. As páginas de Salvador em ambos os sites representam prova futura em 27/09/2026; OpenResults exibiu a mensagem de prova prevista e canonical correto. Avenida Brasil é de 13/09/2026 e ainda não tinha resultados publicados; essa ausência não virou soft 404.

Não houve diferença de status entre HEAD e GET nesses casos; os metadados foram verificados exclusivamente no GET. A seleção não incluiu um evento cancelado identificado com segurança; esse caso fica para uma próxima amostra. As verificações adicionais respeitaram o limite de taxa e não são contabilizadas como parte das 100 páginas de cada manifesto.

Os registros RoadRunners incluem canonical localizado em EN/ES e lastmod bruto; isso não comprova tradução integral nem que lastmod coincide com a última alteração de conteúdo. O código usa `COALESCE(data_processamento, data_inclusao, data_inicial::timestamp)`; validar a semântica exige histórico de dados autorizado. O OpenResults não inventa lastmod. Não houve acesso ao banco neste ciclo.

A leitura pública de robots OpenResults já entregou o sitemap correto, sem repetir o cache antigo descrito na publicação anterior. As respostas HTML adicionais OpenResults vieram com `CF-Cache-Status: DYNAMIC`. Não houve acesso direto à origem, purga CDN, simulação de Googlebot autenticado ou validação de WAF por faixa de IP.

Após a conferência manual, Salvador foi incluído na lista estratégica OpenResults para garantir um caso futuro nas próximas rodadas. Isso muda o hash de configuração: a próxima rodada será uma nova baseline, sem comparação automática com política diferente. O manifesto do primeiro piloto conserva a seleção original.

## Próxima entrega

Priorizar RR-01/RR-02 e os canonicals RR-03/OR-01 em lotes por projeto, com conferência de produção, backup recuperável, testes das rotas afetadas e verificação pública após publicação. Depois obter duas rodadas completas com configuração estável antes de ativar acompanhamento recorrente.

A ferramenta local já permite análise técnica sem contratar uma plataforma. Agenda, Search Console/GA4, painel, dados de concorrência e monitoramento de posições continuam entregas próprias. Nenhuma conta Google foi conectada e nenhum agendamento foi criado neste ciclo.
