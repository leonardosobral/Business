# Plano de crescimento do Road Runners com páginas regionais e calculadora de pace

Proposta de 25/10/2026. A prioridade é aumentar a entrada por buscas úteis ao corredor e transformar parte dessa audiência em visitas às provas, inscrições e uso de cupons. Começar pelas páginas regionais que já têm posições relevantes e por uma calculadora pública de pace; depois, aprofundar fichas de provas e circuitos. Este documento detalha a [análise dos concorrentes](2026-10-25_seo_concorrentes_estrategia.md).

## Andamento da implementação

### Preservação Semrush antes do fim da assinatura — 04/11/2026

- [concluído] Preservados 62 CSVs originais das duas auditorias de 20.000 páginas e das posições orgânicas BR/desktop. Cópias privadas local e no Business, 67 arquivos com hashes conferidos; sem nova auditoria ou compra de recursos.
- [concluído] Resumos de 101 tipos de verificação por site, inventários de 40.000 URLs com metadados e detalhes dos problemas. Totais por URL reconciliados. Um relatório de idiomas não ofereceu CSV específico; suas 167 URLs estão no inventário geral.
- [concluído] Posições preservadas: Road Runners 1.376 linhas/1.117 termos distintos; Open Results 535/357. Datas e estimativas mantidas, valores ausentes não convertidos em zero.
- [concluído] Publicado no Business em 04/11 às 13:35:43 (Brasília): consulta por verificações, URLs, palavras-chave e arquivos originais, com filtros, paginação, downloads administrativos e histórico preservado. Quatro templates compilados; 31 cenários ColdFusion e 62 downloads aprovados antes e depois da publicação. Hashes, cinco dependências e 67 arquivos privados conferidos; revisão autenticada Chrome desktop e celular 393 px. [Recibo e escopo](2026-11-04_seo_semrush_preservacao.md).
- [próxima revisão] Road Runners: 72% Site Health, 305 ocorrências de erro; verificar primeiro 165 respostas 4xx e 66 links internos quebrados, depois duplicidades. Open Results: 76%, 1.166 erros; maiores frentes são descrições/títulos duplicados e lentidão. Mudança de amostra/configuração impede atribuir toda a variação da nota a regressão. Indexação e tráfego continuam com fontes próprias.

### Prioridade imediata — Aracaju / Sergipe / Maratona, 31/10/2026

Por solicitação do usuário, esta frente precede agora as demais correções gerais: páginas de Aracaju e Sergipe, ficha da Maratona de Aracaju 2026, histórico permanente no Road Runners e consulta da edição no OpenResults. Objetivo: facilitar acesso às informações confirmadas, resultados efetivamente disponíveis e fotos durante o fim de semana de 31/10–01/11. Não presumir pico de audiência sem medição, publicação de resultados ou garantia de ranking/indexação.

- [concluído] Conferidas sete URLs públicas nos dois sites, HTTP 200, canonicals, acesso à edição de 2026 e programação no regulamento da organização. Na leitura inicial: zero resultados importados de 2026; o histórico de 2025 é identificado separadamente.
- [concluído] Publicado em **31/10 às 13:58:53 (Brasília)**: chamadas de Aracaju/Sergipe e Maratona no Road Runners, página de resultados e regionais no OpenResults; canonical, título, descrição e h1 específicos para Aracaju no OpenResults. Preservados filtros, idiomas, demais localidades e política das páginas pessoais.
- [concluído] Complemento de fotos publicado às **14:07:15**: acesso confirmado à galeria de sábado, 10/21 km, além do vínculo já existente de domingo, agora identificado por nome/data. Disponibilidade de resultados consulta o banco com cache de um minuto, sem iniciar importações nem prometer atualização ao vivo.
- [concluído] Sete templates compilados e 17 cenários no Adobe ColdFusion; revisão Astra; sete páginas públicas verificadas e conferência Chrome desktop/celular 393 px. Sete hashes e 14 dependências conferidos. [Recibo técnico](2026-10-31_seo_aracaju.md), fontes e evidências em `../staging/seo-aracaju-20261031/`.
- [pendente de evidência] Confirmar resultados após a importação operacional, medir procura/cliques desta janela e conferir indexação no Google. Nenhum pico de audiência, melhoria de ranking ou resultado esportivo foi inferido. As demais correções gerais ficam depois desta prioridade.

### Auditoria ampliada — resultado conferido em 31/10/2026

Campanha Semrush 26661911, móvel e renderização JS desativada. A coleta concluída em **30/10 às 16:56 (Brasília)** alcançou **80% Site Health e 17 erros em 5.000 páginas**. A seguinte, concluída em **31/10 às 02:39**, alcançou **74% Site Health, 81% IA, 40 erros, 12.870 advertências e 6.003 avisos em 10.000 páginas**. O fornecedor sinaliza mudança de configurações: a diferença de cobertura impede interpretar toda a queda como regressão. Comparação direta: três erros corrigidos e 26 novos, reconciliando 17−3+26=40.

Pendências atuais: 17 links internos quebrados, seis títulos duplicados, seis descrições duplicadas, quatro ocorrências de conteúdo duplicado, seis páginas lentas e uma resposta 4xx. Três pares de títulos para verificar antes de consolidar: Estações Inverno São Paulo 2023, Estações Inverno Salvador 2025 e Empório Prime 2026/2027. Há também 791 títulos longos. Os 3.853 avisos de bloqueio exigem classificação: o exemplo regional filtrado conferido respondeu 200 e a implementação prevê noindex intencional, sem demonstrar bloqueio Cloudflare. Não liberar todos indiscriminadamente.

Fontes: [comparação Semrush](https://pt.semrush.com/siteaudit/campaign/26661911/review/compare) e `../staging/seo-reaudit-10000-20261031/source.json`. A consulta detalhada MCP esgotou o saldo da API; notas e comparação foram confirmadas pela interface autenticada do Chrome. O painel Business ainda preserva a coleta importada anterior; esta anotação não altera o snapshot publicado.

Implementação autorizada em 25/10/2026. Base local revalidada depois da atualização do Git informada pelo usuário: os seis arquivos existentes do escopo coincidem com a produção. Não há conflitos Git nesses arquivos. Alterações de outras frentes ficam fora da publicação.

| Entrega | Situação |
| --- | --- |
| Regionais: resumo sincronizado com filtros, cidades no mobile, vazio e breadcrumb com cidade | Publicado e conferido em 25/10/2026 |
| Calculadora pública com três modos, parciais e ligação ao calendário | Publicada em 25/10/2026; incluída no rodapé e sitemap |
| Testes e conferência pública das entregas acima | Concluídos: Node, Adobe ColdFusion, HTTP público e navegador desktop/mobile |
| Baseline GSC das regionais | Registrado e publicado no painel em 25/10; 316 cliques no período anterior às melhorias |
| Medição da calculadora | Encaminhamento pela tag Google publicado; leitura GA4 ainda negada pelo Google em 30/10, recebimento pendente de comprovação |
| Paginação rastreável e períodos exatos | Publicados e conferidos em 25/10/2026; lote 3 concluído |
| Regionais → páginas permanentes de maratonas | Publicado e conferido em 30/10: histórico regional recolhido, vínculos existentes e somente edições ativas |
| Páginas permanentes de maratonas, incluindo Floripa | Publicado e conferido em 30/10: próxima edição/intervalo, última realizada, calendários locais, metadados e CollectionPage |
| Curadoria do piloto Curitiba/Brasília | Publicada e conferida em 30/10: vínculo de Curitiba 2026, 42 km, percursos da Monumental e consolidação da Night Run |
| Conteúdo específico de Floripa e dois circuitos | Publicado e conferido em 30/10: informações práticas de Floripa/Curitiba/Monumental; guias LIVE!/Estações e dois vínculos confirmados de etapas |
| Revisão dos vínculos das próximas etapas dos dois circuitos | Publicada e conferida em 30/10: 21 vínculos no Estações e um na LIVE!; listas com 24 e 12 próximas etapas; Ribeirão Preto corrigido e duplicidade de Fortaleza consolidada |
| Retorno pós-prova nas fichas e páginas permanentes | Publicado e conferido em 30/10: resultados importados, fonte cadastrada, fotos independentes da importação, próxima edição cadastrada e atalhos das três edições/etapas recentes |
| Reauditoria e correção das novas duplicidades | Coleta de 29/10 importada em 30/10: 73%/84% IA, 64 erros; corrigidas 30 descrições regionais e duas duplicatas confirmadas. Nova auditoria iniciada para medir o resultado |
| Medição Google e experiência móvel | Publicado em 30/10: comparação Web, indexação e grupos INP/LCP com escopos separados; mapas das fichas otimizados. Prioridade das imagens da home aplicada, mas LCP ainda sem melhora comprovada |
| Mapas das fichas sob demanda | Publicado e conferido em 30/10: simulação móvel da abertura de Aracaju passou de 33 para 64; TBT de 8.030 para 250 ms. Impacto no INP real ainda não comprovado |
| Imagens de destaque da home | Prioridade e adiamento publicados em 30/10; peso da simulação de 8.330 para 6.324 KiB, mas LCP de 8,9 para 10,8 s. Variantes menores e formatos modernos seguem pendentes |
| Expansão editorial e colaboração | Pendente: confirmação de Imperatriz, revisão histórica/outros circuitos, atualização de kits quando anunciada e evolução da confirmação de informações por organizadores |

### Rodada de 30/10: prioridade das imagens da home publicada; LCP ainda aberto

O PageSpeed anterior apontou a primeira imagem do carrossel como LCP e ausência de prioridade alta. Na home real havia 12 imagens sem prioridade diferenciada. Publicada uma alteração somente no elemento `<img>` do loop de destaques: primeiro registro com `loading="eager" fetchpriority="high"`, demais com `loading="lazy" fetchpriority="low" decoding="async"`. Não se dá prioridade alta a uma imagem fora da primeira posição caso o primeiro registro não tenha imagem. URLs, consulta, carrossel, estilos, textos e filtros preservados. Referência técnica: [Fetch Priority, Google](https://web.dev/articles/fetch-priority).

**Resultado pontual, mesma configuração móvel/Moto G Power/4G lento/Lighthouse 13.6.0:** [antes, 16:14](https://pagespeed.web.dev/analysis/https-roadrunners-run/kjlhssb5d7?form_factor=mobile) → [depois, 16:39](https://pagespeed.web.dev/analysis/https-roadrunners-run/15mutoos0l?form_factor=mobile).

| Métrica | Antes | Depois |
| --- | --- | --- |
| Desempenho Lighthouse | 60 | 56 |
| LCP | 8,9 s | 10,8 s |
| TBT | 320 ms | 450 ms |
| Payload | 8.330 KiB | 6.324 KiB |
| CLS | 0,073 | 0,073 |

**Não houve melhora de LCP nessa observação.** O achado de prioridade foi atendido e o peso da abertura foi menor, mas isso não encerra a otimização da home. Uma comparação isolada não demonstra que a marcação causou a diferença de LCP; não anunciar ganho de campo, ranking ou Site Health. O detalhamento identificou 413,1 KiB no PNG principal de Aracaju, 726,9 KiB no PNG de Curitiba e 824,4 KiB no JPG de 3840 px da Pampulha. Continuam grandes para os cards, mesmo com o carregamento adiado.

Consulta em transação **somente de leitura**, reutilizando o vínculo da home entre `vw_evento_corridas` e `tb_evento_corridas`, confirmou que Aracaju tem a **mesma URL grande** nos campos de imagem principal e de listagem. Curitiba tem um thumbnail diferente, ainda sem revisão visual para substituição. Nenhum campo foi alterado. A próxima etapa precisa examinar/reutilizar representações adequadas e preparar variantes responsivas em formatos modernos, com fallback para a origem, preservação da arte e rastreabilidade da URL original. Evitar proxy aberto ou mudança no banco apenas para silenciar a auditoria.

Publicado em **30/10 às 16:38:27 (Brasília)**, somente `index.cfm`. Um template compilado, **seis cenários Adobe** (PT/EN/ES, várias imagens, primeira ausente, vazio), três páginas públicas com 200/canonicals próprios/12 imagens, conferência Chrome desktop e **390 px**, navegação do carrossel e proporções mantidas, sem overflow da página. Um hash de runtime e seis dependências preservadas; backup `/var/backups/seo-home-images-20261030/baseline`. Código e documentação sincronizados com guardas de hash. Fontes/recibos em `../staging/seo-home-images-20261030/`; detalhes no RoadRunners em `_codex/docs/2026-10-30_home_imagens_prioridade.md`. Sem alterações de dados das provas, credenciais, permissões, configurações Cloudflare, commit ou push.

A mesma auditoria Semrush passou de **4.988/5.000** para **“Analisando recursos e links”** ao fim desta etapa. Continua viva e ainda não há resultado concluído novo. Não iniciar outra por timeout. O painel mantém 73% da última coleta concluída. Baseline novo preparado em `../staging/seo-semrush-20261030-final/panel/` para importar a fonte completa quando disponível, preservando Google, domínios e coleta orgânica anterior.

### Rodada de 30/10 concluída: mapas das fichas sob demanda

O diagnóstico oficial do PageSpeed confirmou uma causa de trabalho desnecessário na abertura: **Mapbox consumiu 14.797 ms de CPU** na simulação móvel da ficha de Aracaju. Na navegação real, os canvases dos dois mapas já existiam a 1.862 e 2.616 px do topo, fora do viewport de 834 px.

Publicado em **30/10 às 16:24:42 (Brasília)**: `evento/index.cfm` passa a usar `assets/js/event-maps-lazy.min.js`, com fonte mantida em `event-maps-lazy.js`. A biblioteca pesada só é carregada ao aproximar-se da seção (margem de 300 px) ou ao focar/tocar/clicar nela. Uma Promise compartilha o carregamento da biblioteca entre percursos e localização; seus scripts existentes e a implementação do embed foram preservados. A última aba escolhida durante o download é mantida; navegadores sem IntersectionObserver carregam de imediato. Falhas e timeout usam os estados de erro e fallbacks já existentes. Endereço e navegação continuam no HTML.

**Comparação pontual de laboratório, mesma URL e configuração móvel/4G lento/Moto G Power/Lighthouse 13.6.0:** [antes, 16:14](https://pagespeed.web.dev/analysis/https-roadrunners-run-evento-2026-maratona-de-aracaju-2026/8h9yx3klom?form_factor=mobile) → [depois, 16:25](https://pagespeed.web.dev/analysis/https-roadrunners-run-evento-2026-maratona-de-aracaju-2026/c4zwyu0fz6?form_factor=mobile).

| Métrica da abertura | Antes | Depois |
| --- | --- | --- |
| Desempenho Lighthouse | 33 | 64 |
| Tempo total de bloqueio (TBT) | 8.030 ms | 250 ms |
| LCP | 8,3 s | 7,1 s |
| Speed Index | 12,5 s | 5,4 s |
| CLS | 0,038 | 0,038 |
| Payload | 5.741 KiB | 4.083 KiB |
| Tarefas longas | 20 | 8 |

O trabalho do mapa continua necessário quando ele é acessado. Esses dois testes de abertura **não comprovam melhora do INP real, ranking ou Site Health**, e o LCP continua alto. O CrUX mostrado pelo PageSpeed nessa ficha usa fallback da **origem** (191 ms de INP), não uma medida individual da ficha nem o grupo GSC de 926 URLs/293 ms atualizado em 28/10. Não substituir um escopo pelo outro. Referência de diagnóstico: [otimização de tarefas longas e INP, Google](https://web.dev/articles/optimize-inp).

Validação: **14 testes Node**, fonte/minificado; um template compilado e **cinco cenários Adobe** (PT/EN/ES, pós-prova e localização); oito conferências públicas, incluindo embed e assets por hash; Chrome desktop e celular **390 px**, sem overflow da página. Conferidos aba escolhida durante download, fallback do percurso sem geometria, mapa de 42 km, marcações, elevação e navegação por setas do teclado. Build padrão com 21 assets confirmou o novo minificado, gerado por esbuild 0.28.2, somente espaços. **Três hashes de runtime e dez dependências preservadas**, backup em `/var/backups/seo-mobile-maps-20261030/baseline`. Código, gerador, teste e documentação sincronizados localmente com guardas. Evidências: `../staging/seo-mobile-maps-20261030/`; detalhes no RoadRunners em `_codex/docs/2026-10-30_mapas_sob_demanda.md`. Sem banco, credenciais, permissões, commit ou push; nada para executar no DataGrip.

**Próximo recorte confirmado:** a home teve simulação 60, LCP 8,9 s e TBT 320 ms. O PageSpeed identificou a imagem de destaque como LCP e a falta de `fetchpriority=high`. Revisar a prioridade da primeira imagem e o carregamento das demais, respeitando o carrossel e a proporção. A home ainda não foi alterada nesta rodada. Continuar depois com exemplos de indexação e expansão editorial/colaboração.

**Semrush:** mesma execução 26661911, móvel e JS desativado, observada em **3.879/5.000** páginas ao fim desta rodada. A configuração não foi alterada e não houve reinício. Ela não mede o comportamento interativo dos mapas nem a pontuação Lighthouse acima; a alteração dos scripts pode mudar os recursos encontrados, sem autorizar atribuir eventual mudança de Site Health a essa otimização. A última coleta concluída continua 73%; **meta acima de 80% aberta**.

### Rodada de 30/10 concluída: medição Google e prioridades móveis

Atualizada a leitura manual do Search Console no Business, sem confundir a propriedade de domínio com o site principal e sem alterar a nota técnica ou o Site Health:

- **Buscas Web no site principal:** 01/10 a 28/10, todos os países/dispositivos, filtro `^https://(www\.)?roadrunners\.run/`. **10.026 cliques contra 3.220** nos 28 dias anteriores (**+211,4%**); **461.935 contra 125.907 impressões**; CTR 2,2% contra 2,6%; posição média 7,4 contra 8,0. Outros subdomínios ficam fora desse recorte. Totais filtrados podem ser parciais conforme o Google. Não inclui tráfego direto ou referências de IA, nem comprova impacto das publicações de 25/10 e 30/10: a maior parte do período as antecede.
- **Indexação da propriedade de domínio, incluindo subdomínios:** relatório atualizado em **22/10**, observado em 30/10: **21.335 indexadas e 116.687 não indexadas**. As 13 categorias foram lidas e reconciliam o total. Destaques para revisão: 87.026 detectadas e 5.025 rastreadas sem indexação, 225 soft 404, 80 não encontradas, 34 erros 5xx e cinco 403. Canonical, redirects, robots e noindex também compõem o total; exclusão não equivale automaticamente a erro. Esse relatório antecede as mudanças recentes.
- **Sitemap do site principal:** **107.352 URLs descobertas**, índice lido em 26/10, sete lotes processados entre 28 e 30/10. O lote estático mostra 990 URLs, lido em 28/10. Descoberta não comprova indexação.
- **Core Web Vitals, atualizado em 28/10:** celular com 1.317 URLs que precisam melhorar e 173 boas, nenhuma ruim; computador com 1.490 boas. Grupo de **INP: 926 URLs, 293 ms**, exemplo Maratona de Aracaju 2026. Grupo de **LCP: 391 URLs, valor arredondado 2,5 s**, exemplo home. São grupos da experiência real do Chrome, não medições individuais de todas as URLs.

Publicado em **30/10 às 16:09:42 (Brasília)** em `portal/includes/seo_search_evidence.cfm` e `portal/conteudo/seo_growth_baseline.cfm`. O registro antigo do piloto PR/DF com 316 cliques e a evidência do OpenResults foram preservados integralmente. Detalhes recolhidos e tabelas com rolagem própria; conferidos Chrome desktop, celular 390 px e expansão por teclado, sem overflow da página. Dois templates compilados, **15 cenários Adobe antes e depois**, incluindo oito controles de acesso; dois hashes publicados e 14 dependências preservadas. Backup: `/var/backups/seo-gsc-20261030-panel/baseline`. Fontes, valores exatos, screenshots e recibos: `../staging/seo-gsc-20261030/`. Nenhuma escrita no banco, mudança de credenciais/permissões, commit ou push.

**Diagnóstico dos links da auditoria anterior:** as 18 ocorrências se dividem em 16 para a proteção de e-mail da Cloudflare e duas para a mesma notícia do ranking de maratonistas. A notícia e sua API de conteúdo responderam HTTP 200 em 30/10; as duas páginas de origem continuam com links válidos. A causa do 404 anterior não foi demonstrada. Proteção de e-mail e notícia preservadas; nenhum achado encerrado apenas para aumentar a nota. As duas respostas 4xx do fornecedor correspondem a esses mesmos destinos. Fonte: `../staging/seo-links-20261030/public-diagnostic.json` e relatórios por URL em `../staging/seo-reaudit-20261030/`.

**Próxima sequência:** concluir a mesma auditoria de 5.000 páginas e importar o resultado real; diagnosticar as interações nas fichas do grupo INP e o carregamento da home no grupo LCP, implementando apenas causas confirmadas; revisar exemplos de indexação por relevância e intenção. A inicialização dos mapas abaixo da dobra é uma hipótese de investigação, ainda sem mudança publicada ou efeito comprovado. Depois, retomar colaboração com organizadores e a expansão editorial. O GA4 continua com leitura negada pelo Google; não foi tratado como audiência zero.

**Auditoria em curso:** campanha 26661911, mesma execução móvel/JS desativado, observada em **2.359/5.000 páginas** ao fim desta rodada. A aba de acompanhamento foi preservada; não reiniciar por timeout. **Site Health permanece 73% da coleta concluída em 29/10; a meta acima de 80% continua aberta.**

### Rodada de 30/10 concluída: reauditoria e duplicidades

Revalidação do estado externo encontrou uma auditoria concluída em **29/10 às 09:32 (Brasília)**, campanha 26661911, **5.000 páginas, móvel, JavaScript desativado**. Resultado: **Site Health 73%, IA 84%, 64 erros, 8.388 advertências e 1.643 observações**. O comparativo real é contra 24/10 às 23:40: saúde 79% → 73%, erros 20 → 64. O painel ainda mostrava a coleta de 22/10; foi atualizado preservando a coleta orgânica de 04/10 (51 pares palavra-chave/URL e seis oportunidades). Não atribuir aos dados orgânicos a data nova da auditoria.

Prioridade alterada a partir dessa evidência: corrigir as novas duplicidades antes de ampliar a interface de colaboração. Foram lidas as quatro páginas do relatório de descrições, totalizando **34 URLs: 30 regionais e quatro fichas de eventos**.

- **Regionais:** primeira página e continuação tinham a mesma descrição. Agora calendários com mais de uma página identificam a página atual e o total, coerentes com a lista. As 30 descrições apontadas ficaram distintas. Calendários de uma única página, filtros, canonicals, noindex e paginação mantidos.
- **ADC ZF Clube:** os cadastros 48501 e 49606 apontam para a mesma prova Ticket Sports 88536, com data atual de **24/01/2027**, Sorocaba, 4/8 km e caminhada. A URL com prefixo 2026 passou a redirecionar para a de 2027. Não é uma edição histórica de 2026 sendo removida. Resumo factual PT/EN/ES no cadastro válido; retirada de kits continua a informar, conforme fonte.
- **Outubro Rosa de Chupinguaia:** cadastros 48554 e 48918 apontam para a mesma prova Sympla 3594186. Cabeçalho e descrição atuais confirmam **31/10/2026, 6h, Sicredi, 5 km**. A duplicada com sufixo RO passou a redirecionar para a ficha com cidade. Resumo PT/EN/ES atualizado, retirando a informação antiga de 25/10.
- **Preservação:** nenhum registro foi apagado. Fontes duplicadas não tinham resultados, agenda, inscrições/contas, anúncios ou CRM a migrar; seis percursos e 46 grupos de dependências mantiveram IDs, contagens e hashes. Datas de início/término dos eventos e datas/flags dos percursos não foram alteradas.

Dados ensaiados em transação com rollback e inversão comprovada antes da aplicação. Runtime regional: um template compilado, seis cenários Adobe. **44 verificações públicas** cobriram as 34 URLs do relatório, seis redirecionamentos localizados e quatro destinos traduzidos; mais quatro conferências do conteúdo das traduções. Painel: seis testes Python, dois templates compilados, 19 cenários Adobe antes/depois e oito controles de acesso. Um hash de runtime/cinco dependências e dois hashes do painel/11 dependências preservados.

Publicações: página estadual às **15:29:01** e painel às **15:33:52** de Brasília. Backups: `/var/backups/seo-duplicidades-20261030-data/`, `/var/backups/seo-duplicidades-20261030-runtime/baseline` e `/var/backups/seo-reaudit-20261030-panel/baseline`. Evidências em `../staging/seo-duplicidades-20261030/` e `../staging/seo-reaudit-20261030/`. Código local sincronizado com guarda de hashes. Correções no banco efetivamente aplicadas; nada para executar no DataGrip. Sem commit/push.

**Medição em curso:** iniciada uma nova execução da mesma campanha após as correções, mantendo 5.000 páginas/móvel/JS desativado. A interface confirmou “Preparando-se para rastrear” e o controle de interromper. Não reiniciar por timeout; conferir o mesmo processo até conclusão real. O painel mantém 73% da última coleta concluída até haver outra fonte completa. Os 18 links internos quebrados, dois 4xx, um hreflang e uma página lenta da coleta de 29/10 continuam para análise individual; não alterar proteção de e-mail, login ou configurações da campanha para elevar a nota.

A leitura GA4 continua negada em 30/10; nenhuma permissão/credencial foi alterada, e ausência de leitura não virou audiência zero. Confirmação de Imperatriz, kits não anunciados, colaboração com organizadores e comprovação de impacto em GSC/GA4 permanecem abertas. **A meta de Site Health acima de 80% não foi atingida.**

### Rodada de 30/10 concluída: retorno pós-prova

Publicado o primeiro recorte do lote 5, reutilizando dados e vínculos existentes, sem criar páginas de resultados pessoais nem mudar sua política de indexação:

- **Fichas realizadas:** bloco de pós-prova em HTML, logo após o resumo da prova, com resultados no OpenResults quando há registros oficiais publicáveis. Consulta somente a existência desses registros, sem trazer nomes ou URLs individuais para o novo bloco.
- **Fonte de resultados:** link público de `url_resultado`, identificado como fonte cadastrada. Não é anunciado como verificado nesta rodada nem se usa `url_wiclax`, que pode ser um arquivo de importação. Estado vazio explícito quando não há importação nem fonte cadastrada.
- **Fotos independentes dos resultados:** galerias Foco vinculadas passam a ter acesso mesmo sem resultados importados. Mantido o modal existente, com cupom e seleção de galerias; links HTML das galerias também ficam disponíveis em uma seção recolhida. Ignorados destinos genéricos/inválidos e galerias duplicadas no novo bloco.
- **Continuidade:** próxima edição cadastrada do mesmo histórico de maratona, com intervalo de datas e link localizado PT/EN/ES. Não confunde a próxima parada de um circuito com a próxima edição da prova. Quando não existe próxima edição, não se inventa uma; há acesso ao calendário da cidade para provas brasileiras elegíveis.
- **Páginas permanentes:** seção recolhida com atalhos diretos para o pós-prova das três edições/etapas realizadas mais recentes, sem prometer que todas tenham resultados ou fotos. Aplica-se ao template de maratonas e aos dois circuitos piloto.
- **Datas e metadados:** o bloco só aparece após o último dia inteiro da prova, com fallback para início quando término não existe; não aparece em canceladas/adiadas. Descrição SEO das fichas realizadas passa a refletir a data passada e a consulta dos materiais. Canonicals, títulos, schema e fluxos de inscrição preservados.

Validação: **7 templates compilados, 15 cenários Adobe ColdFusion e 19 asserções** de datas, cancelamento/adiamento, próxima edição, URLs, galerias e idiomas. Conferência pública de **14 páginas, dois includes protegidos (403) e CSS por hash — 17 verificações**. Chrome desktop/celular de 390 px: modal de Floripa com duas galerias e cupom, galeria de São Luís sem resultados importados, navegação pelo histórico e teclado, sem overflow. Destino OpenResults de Floripa abriu com a prova e 12.936 concluintes.

Publicado em 30/10 às **15:12:29 (Brasília)**. Oito arquivos verificados por hash, cinco dependências compartilhadas preservadas e backup recuperável em `/var/backups/seo-pos-prova-20261030/baseline`. Evidências em `../staging/seo-pos-prova-20261030/`; detalhes em `../../../RoadRunners/_codex/docs/2026-10-30_pos_prova.md`. Código local sincronizado com guarda de hashes. **Nenhuma escrita no banco; nada para executar no DataGrip; sem commit/push.**

**Próxima prioridade:** acompanhar uso/descoberta das entradas de pós-prova e avançar na confirmação de informações pelos organizadores, sem criar um CMS novo como pré-requisito. Permanecem abertas a confirmação oficial de Imperatriz, kits ainda não anunciados, cobertura histórica/outros circuitos e comprovação de coleta GA4/impacto em GSC. A entrega técnica não comprova crescimento de tráfego, ranking ou Site Health.

### Revisão de 30/10 concluída: demais etapas dos circuitos

Revisadas **45 fichas futuras candidatas** do catálogo, com datas entre 01/11 e 20/12/2026, comparando nome, cidade e data com as páginas oficiais. O lote não representa revisão de todo o histórico nem de todas as provas de 2027.

- **Circuito das Estações:** 21 vínculos confirmados nas páginas oficiais Running Land e adicionados; a lista passou de três para **24 próximas etapas**. Os três vínculos anteriores foram preservados. Não houve associação apenas por semelhança de nome.
- **LIVE!:** calendário oficial e 12 etapas futuras conferidos. Adicionado o vínculo de **Ribeirão Preto II, 22/11**, passando de 11 para **12 próximas etapas**. Corrigidos o hotsite e a inscrição, que apontavam para o Rio; incluídos os 15 km e um resumo factual em PT/EN/ES. Os dois percursos anteriores mantiveram seus IDs e receberam proteção de revisão manual; somente o percurso de 15 km foi criado.
- **Fortaleza:** confirmada a duplicidade das fichas 45366 e 37570 para a mesma etapa oficial de 20/11. A duplicada foi inativada com **301** para a válida nos três idiomas. Registros e dependências foram preservados, sem excluir percursos, associações de fotos ou dados de usuários.
- **Navegação das fichas:** o acesso de volta ao circuito passou a funcionar também quando a etapa não tem tema visual específico. O ajuste preserva o agrupamento de edições e evita repetir o link quando o cabeçalho temático já o oferece.
- **Imperatriz (37765): pendente.** A página O2 cadastrada não apresentou detalhes da etapa, e a cidade não aparece no seletor atual do circuito. Não há confirmação suficiente para vincular, mudar data ou declarar cancelamento; a ficha ficou intacta. Sete candidatas de outros organizadores foram excluídas do lote por não pertencerem aos dois circuitos.

Validação: ensaio transacional e restauração inversa comprovados; 24 eventos sob guarda, 50 percursos anteriores preservados, 46 conjuntos de dependências com contagens/hashes intactos. Dois templates compilados e cinco cenários Adobe ColdFusion passaram. Conferência pública: duas listas, 22 fichas, três redirecionamentos e duas traduções (**29 verificações**), além do bloqueio de acesso direto ao include (**403**). Chrome desktop e celular de 390 px conferidos, sem overflow horizontal. **Não foram alteradas as datas de início/término dos eventos.** As correções foram aplicadas no banco; nada precisa ser executado no DataGrip.

Runtime publicado em 30/10 às **14:54:20 (Brasília)**, com dois arquivos e cinco dependências compartilhadas preservadas. Backups recuperáveis: `/var/backups/seo-circuitos-vinculos-20261030/` (dados e inversão) e `/var/backups/seo-circuitos-vinculos-20261030-runtime/baseline` (runtime). Evidências, fontes oficiais por etapa e screenshots em `../staging/seo-circuitos-vinculos-20261030/` e `../staging/seo-circuitos-vinculos-20261030-runtime/`. Detalhes: `../../../RoadRunners/_codex/docs/2026-10-30_revisao_vinculos_circuitos.md`. Código local sincronizado com guarda de hashes; sem commit/push.

**Prioridade registrada ao fim desta rodada:** acompanhar a confirmação oficial de Imperatriz e avançar na utilidade pós-prova, entregue no primeiro recorte acima; detalhes de kits dependem de anúncio. A revisão dos vínculos futuros encontrados neste lote foi concluída, exceto Imperatriz. Revisão histórica e de outros circuitos, medição GSC/GA4 e impacto em tráfego/ranking continuam abertos; a publicação não comprova ganho de posição ou Site Health.

### Rodada editorial de 30/10 concluída: vínculos, fatos e circuitos

Correções feitas a partir das páginas oficiais e dos regulamentos atuais, com baseline, ensaio transacional, inversão comprovada e conferência pública:

- **Curitiba 2026:** ficha 43657 vinculada ao histórico da Maratona de Curitiba; 42 km incluídos no cadastro/percursos; regulamento atualizado e resumo em PT/EN/ES. A página permanente passou a mostrar a próxima edição de 15/11/2026, além das quatro edições anteriores. Os três percursos existentes mantiveram seus IDs.
- **Monumental de Brasília 2026:** categorias e percursos adultos completados; 5/10 km em 21/11 às 17h e 21/42 km em 22/11 às 6h/5h, conforme regulamento v6. Descrição e traduções corrigidas, incluindo a referência incorreta a 2025 e o horário antigo de 18h. Mantidas as datas do evento, 21–22/11.
- **Night Run:** as fichas 37774 e 38982 apontam para a mesma prova oficial. A ficha válida mantém 31/10; cidade física corrigida para Pinhais, Parque das Águas. A duplicada de 07/11 foi inativada com 301 para a válida nos três idiomas, preservando os registros. Não havia resultados, agenda, inscrições/conta ou percursos na duplicada que precisassem ser migrados.
- **LIVE! Brasília:** data 13/12 e 5/10/15 km conferidos na origem; vínculo moderno do circuito já correto. Retirada de kits continua a confirmar. A aceitação do cupom no checkout externo não foi testada nesta revisão.
- **Floripa 2027:** programação conferida: meia em 28/08, maratona e 5 km em 29/08, com base na Praça Sesquicentenário. A ficha já estava correta. A página permanente ganhou informações práticas com fonte e data da conferência.
- **LIVE! e Estações:** guias de próximas etapas, última realizada e calendários das próximas cidades, com menu recolhido no celular e desktop. Mantidos destaque LIVE, abas, cupons e inscrição. No Estações, vínculos de Curitiba 29/11 (46521) e Brasília 06/12 (46508) adicionados após conferência individual nas páginas Running Land; fichas intactas. Outras provas com nomes semelhantes foram excluídas da associação automática.

Os blocos editoriais das três maratonas só aparecem quando **tag e intervalo da próxima edição** correspondem à evidência. Mudança de edição/data oculta o texto, evitando transportar informações de um ano para outro. Circuitos usam suas próprias canonicals e `CollectionPage`/`ItemList` com links às fichas.

Validação: 5 templates compilados, 7 cenários Adobe, 16 asserções de modelo, 13 páginas HTTP anônimas, três redirecionamentos localizados e proteção do include. Desktop/mobile 390 px, teclado, abas e ausência de overflow conferidos. Dados: 47 conjuntos de dependências preservados, cinco percursos faltantes criados, IDs dos percursos anteriores mantidos, histórico factual automático conferido. As correções de categorias/localidade e os dois vínculos foram efetivamente aplicados no banco; **não foram alteradas as datas de início/término dos eventos**. Nada precisa ser executado no DataGrip.

Runtime publicado às 13:17:39 (Brasília), com ajuste de apresentação dos circuitos às 13:19. Cinco arquivos no pacote, sendo quatro com mudanças; cinco dependências compartilhadas preservadas. Backups: `/var/backups/seo-curadoria-circuitos-20261030-data/`, `/var/backups/seo-curadoria-estacoes-20261030/` e `/var/backups/seo-curadoria-circuitos-20261030-runtime/`. Fontes, hashes, recibos e screenshots em `../staging/seo-curadoria-circuitos-20261030/`. Detalhes: `../../../RoadRunners/_codex/docs/2026-10-30_curadoria_provas_circuitos.md`. Sem commit/push.

**Prioridade registrada ao fim desta rodada:** ampliar a revisão das etapas ainda sem vínculo nos dois circuitos, executada na revisão acima, com Imperatriz pendente. Confirmar detalhes de kits quando a origem atualizar e evoluir pós-prova continuam abertos. O piloto factual PR/DF e o primeiro aprofundamento de Floripa/circuitos estão entregues; a cobertura de todo o acervo e o lote pós-prova não estão concluídos. Avaliar os resultados com GSC e ações comerciais em janelas equivalentes; a publicação não comprova melhora de ranking ou Site Health.

### Rodada de 30/10 concluída: regionais e páginas permanentes

Seguindo a [comparação dos concorrentes de 30/10](2026-10-30_seo_concorrentes_comparacao.md), foi publicada a ligação entre calendários regionais e históricos permanentes, seguida da melhoria do template de maratonas. O escopo desta rodada foi de seis arquivos no RoadRunners; o Business mantém este plano e as evidências.

- Regionais: bloco recolhido **Histórico de maratonas** antes dos filtros, também no celular; até seis famílias com pelo menos duas edições ativas na localidade. Seleção independente dos filtros do calendário, somente na primeira página. Priorizadas PR/Curitiba e DF/Brasília, com conferência adicional de SC/RS e do estado sem acervo AC. A regra compartilhada também atende outras regiões com acervo elegível.
- Permanentes: próxima edição cadastrada ou em andamento, intervalo de datas, última edição realizada, links para calendários de cidade/UF e acesso à calculadora. Floripa, Curitiba, Monumental de Brasília e Porto Alegre conferidas. Mantidas as abas de próximas/realizadas; eventos de vários dias permanecem em próximas até o término, com fallback para início quando término não existe.
- SEO: títulos e descrições específicos, canonical permanente e `CollectionPage`/`ItemList` coerentes com as edições exibidas. Não foi criado um `Event` artificial para o conjunto de edições nem novas rotas combinatórias.
- **Pendência identificada nesta primeira rodada, resolvida na rodada editorial acima:** a ficha futura de Curitiba estava sem vínculo com o histórico permanente. A associação foi feita após conferência na fonte oficial.

Validação: 5 templates compilados, 14 cenários ColdFusion, 13 asserções de borda, 12 páginas HTTP públicas, CSS por hash e bloqueio do acesso direto aos três includes. Chrome desktop/mobile de 390 px, abas e abertura pelo teclado conferidos, sem overflow horizontal. Publicação inicial em 30/10 às 12:55:51 (Brasília), com ajustes de contagem de registros ativos e texto durante a conferência final. Seis hashes e cinco dependências preservadas verificados; backup em `/var/backups/seo-regionais-provas-20261030/baseline` e complementos documentados.

Evidências: `../staging/seo-regionais-provas-20261030/`. Detalhes de runtime: `../../../RoadRunners/_codex/docs/2026-10-30_regionais_provas.md`. Código local sincronizado com guarda de hashes. **Sem alteração de datas, vínculos, percursos ou outros dados no banco; nada para executar no DataGrip; sem commit/push.**

**Prioridade registrada ao fim da primeira rodada:** revisão factual PR/DF e aprofundamento de Floripa/circuitos, executados na rodada editorial acima. A expansão completa dos lotes 1/4 e a medição de impacto continuam abertas.

### Registro das entregas de 25/10

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
