### Equivalência web com o PDF — revisão de 01/10/2026

Este é o mapa vigente das páginas, atualizado no mesmo caderno 6. O acompanhamento anterior de 30/09 permanece na revisão anterior desta célula. SQLs, resultados congelados e saídas web não são alterados por esta revisão editorial.

**Pacotes de referência:** 2025 web v13, saída 249/rev24, execução 120; 2026 web v11, saída 251/rev20, execução 122. As datas de coleta pertencem a cada tema: uma execução posterior não atualiza automaticamente os outros blocos. A referência é o PDF 2025 v3.10.3, atualizado em 09/03/2026.

**Estados:** adaptado = conteúdo em páginas responsivas e filtros; parcial = referência ainda incompleta; omitido = decisão editorial. Implementado visualmente não significa método histórico recuperado nem igualdade entre base atual e antiga.

| PDF | Estado da reprodução histórica | Conteúdo web e fontes para recálculo | Pendência ou diferença documentada |
| --- | --- | --- | --- |
| 1 | Adaptado | Capa, título, ano, seleção PDF/atual e PDF original. | 2026 tem identidade de edição parcial e não tem PDF próprio. |
| 2 | Adaptado | Objetivos, população e fontes distintas; auditorias próprias de coleta e 14+, células 312/rev3 (#117), 314/rev1 (#118), 315/rev1 (#119). | 84,1% sem denominador histórico recuperado; cadastro/coleta mede o portal. Tratamento dos casos sem idade para o corte nacional 14+ permanece pendente. |
| 3 | Parcial | Totais, gênero 2024/2025, gerações e distâncias. Totais 2025 #7/#8; volume atual 2023–2025 célula 292/rev1 (#83). Comparativos de 2026 preservados. | Três contagens históricas exatas das barras não foram recuperadas. Não usar altura ou contagem atual como valor do PDF. |
| 4 | Adaptado | Idades geral/F/M e destaques históricos; regra 31/12 em 294–297/rev1 (#87–90), testes 298/rev2 (#92). | População e classificação revisadas mantêm menores, ausências e intervalos ambíguos visíveis; não reproduzem automaticamente os percentuais do PDF. |
| 5 | Adaptado | Gerações por ano/gênero, legenda e destaques históricos. Mesmas fontes #87–90. | Coortes de nascimento fixas. As quatro variações rotuladas com % no PDF permanecem históricas; o algoritmo original não foi recuperado. |
| 6 | Adaptado | Distâncias, gênero dentro da distância, distância dentro do gênero e presença de 5 km; fontes #13–17 e derivação #42/2026. | Os dois cruzamentos têm denominadores diferentes. Universo, normalização e coletas estão nas fontes; não impor 14+ aos totais anteriores. |
| 7 | Adaptado | Geração dentro da distância e distância dentro da geração; fontes revisadas #87–90. | Denominador próprio por faixa/geração; intervalos de distância contínuos. Não extrapolar coortes sem classificação. |
| 8 | Adaptado | Ritmo geral/F/M nas quatro distâncias; fonte revisada 274/rev2 (#60), fronteiras #62. | Limites e exclusão de tempos nulos/zero explícitos. Rótulo histórico <4h designa uma faixa não cumulativa neste bloco. |
| 9 | Parcial | Regiões 2024/2025 e ambos os sentidos de gênero/região; 287/rev1 (#75), derivado de fontes congeladas. | Dois rótulos do Norte do PDF não recuperados; sem completar por diferença. Nordeste/Sul 2024 aparentam troca entre PDF e fonte: conciliação #82, sem corrigir a referência. |
| 10 | Adaptado | Nove UFs + Outros, 27 UFs, cidades, capital/interior e filtro de região; #75, cidades 288/rev2 (#77), capital/interior 267/rev2 (#52). | Localidade validada por cidade/UF e código; sem join só pelo nome. Casos não classificados permanecem na base; não certificar cadastro histórico. |
| 11 | Adaptado | Meses, trimestres e estações; fontes #25, derivação 2026 #61 e estações 300/rev1 (#97). | Meses inteiros confirmados: dez–fev, mar–mai, jun–ago, set–nov. A regra não reproduz as estações do PDF; 2026 tem estações e trimestre incompletos. |
| 12 | Adaptado | Dez maratonas, F/M, volumes, tempos e destaques históricos; 2025 #41; 2026 309/rev1 (#111). | Cinco destaques contextuais de 2025 ainda sem recálculo na série maratonas_destaques. Seleção 2025 fixa e 2026 dinâmica/parcial. Floripa 2026 mantém volume, com tempos suspensos. |
| 13 | Adaptado | Cortes acumulados, quantidades, melhores grupos e medalhas; referência 255/rev1 (#34), cálculo 2025 #41/#67, pódio 301/rev1 (#98), 2026 #111. | Seleção global revisada difere do SQL legado. Bronze destacado do PDF diverge dos próprios tempos publicados; referência preservada. Pódio 2026 usa nove provas; 17 valores de Floripa pendentes. |
| 14 | Adaptado | Faixas CNA, limites, crédito a Sérgio Rocha/Corrida no Ar; 2025 #60 e testes #62. | CNA e performance têm populações e fronteiras distintas. Flags PCD e resultados permanecem sujeitos à revisão cadastral; fontes iniciais 2026 nem sempre identificam origem por indicador. |
| 15 | Adaptado | Dez métricas e explicações; 305/rev4 (#104), testes #105. Outros esportes #69/#71 e 2026 #65/#71. | Todos os cadastrados até o corte, com bases próprias; atributos atuais não reconstroem o perfil passado. + significa mais de esse percentual, não crescimento. Peso 20–300 kg provisório. Esportes em barras em vez de retângulos, mantendo valores e base. |
| 16 | Omitido por decisão editorial | Anúncio RunPro “em breve” fica disponível no PDF original. | Não transportado para a reprodução analítica; não bloqueia reutilização em 2026. |

### Fontes, tabelas e exportações

O menu web oferece **Fontes e critérios**. Valores do PDF identificam sua página e não herdam execução, denominador ou regras do recálculo. Ressalvas históricas próprias de cobertura, Norte, variações e sinal + permanecem explícitas. CSVs geral e por gráfico incluem leitura, fonte, nota, ressalva, contagem, denominador, base e população quando informados; valor numérico conserva sua precisão. Ausência fica vazia, nunca zero nem valor histórico como fallback. Fontes iniciais sem identificação por indicador são declaradas como não informadas; não são inferidas pela origem global do pacote.

### Aceite parcial e próximos passos

Revisão das 16 páginas do PDF e da implementação existente: conteúdo adaptado com duas referências quantitativas incompletas (P03/P09) e decisão editorial P16. Permanecem as decisões de cobertura nacional/14+, qualidade e rastreabilidade das fontes iniciais 2026, fonte dos tempos de Floripa, quatro variações históricas, cinco destaques contextuais de maratonas e qualidade do perfil. Isso não fecha integralmente as etapas 5/6 do plano.

As regras de idade, estações, tempos, grupos, medalhas e perfil já implementadas não voltam a ser tratadas como consultas ausentes. Próximas correções devem ler a revisão corrente, executar, congelar, conferir o pacote e publicar pela saída do mesmo caderno, preservando as versões anteriores.
