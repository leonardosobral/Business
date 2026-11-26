# Estado vigente — BI 2026 integrada, 06/10/2026

- Publicação web 2026: **v22 / publicação41 / saída251 rev39 / congelamento233**. Corte de eventos: 01/01–30/09/2026. Panorama: 4.502.542 participações, 7.891 provas cadastradas, 53,8516% femininas; Jan–Set vs2025: +27,3347% na base conhecida.
- 2025 preservado: v19 / publicação37 / congelamento205. Consultas originais/legadas do DBA e congelamentos anteriores preservados. As consultas autorais da publicação foram relidas antes de editar, com revisão esperada e histórico automático.
- BI: public.tbbi_fat_perfil_br_2026; estrutura de public.vwbi_fat_perfil_br_2026 reproduzida em **estudo.vwbi_perfil_br_2026**, com LEFT JOIN nas dimensões. A view pública não foi alterada. Campos de resultado disponíveis na BI têm prioridade; nascimento, modalidade e outros campos ausentes são complementados por id_resultado, nunca por nome.
- Adaptadores: estudo.vw_resultados_2026 e estudo.vw_resultados_comparativo_2025_2026. Auditoria413/#215: 4.502.542 resultados únicos, 4.789 eventos elegíveis, zero divergências de elegibilidade; 150.159 participações com id_localidade=0 conservadas. A falta do ID da dimensão não significa automaticamente que cidade/UF do evento sejam desconhecidas: a geografia valida código+UF e normalização do cadastro.
- Gerações: nascimento plausível prioritário, idade em31/12; sem nascimento, faixa finita14+ cruzando atéduas gerações pela idade central inteira, menor central no empate. Função de quatro argumentos aplicada à fato: 860.031 IDs atualizados. Valores anteriores em estudo.bi_geracoes_2026_revisao_20261006; nenhuma outra coluna alterada. Consulta357 rev2/#219 confere com os IDs de geração da fato; categorias sem idade não são imputadas.
- Coorte: consulta387 rev2/#231, fontes383/#229 e384 rev3/#226. 608 pares, 597 por vínculo e11 por nome; 1.185.401→1.210.676, +2,1322%. Não mede crescimento causal nem atletas únicos.
- Floripa: fonte oficial402/#210 preservada, 3.592 classificados geral/elite. Demais maratonas: nova coleta353 rev2/#218. Reimportação operacional continua pendente. Revisão dos16 IDs:404/#212 e405/#213 preservadas como evidência datada.
- Preços, perfil, atividades, mapeamento e auditoria ampla de coleta mantêm congelamentos próprios. A auditoria do corte14 (358/#227) inclui também não concluintes, por isso conserva a fonte operacional mais ampla. Nenhuma visita à web executa SQL pesado; saída233 deriva de resultados congelados.
- Validação: contrato17 preservado;154 testes Node passaram; conservação de IDs e denominadores conferida; HTTP de ambos os anos igual ao congelamento, private/no-store/noindex; desktop1280 e celular390 sem transbordamento.

Veja a seção **Fontes BI2026** deste mesmo caderno para a auditoria413, a projeção414/#230 e o registro de integração. A fonte corrente está nas células; arquivos locais são recibos e documentação, não substitutos de edições do DBA.

---

## Registro anterior, preservado para consulta

# Registro anterior — 06/10/2026

Caderno único: Brasil que Corre Provas — Publicação web (6). Fontes e consultas existentes são lidas antes de cada alteração; as revisões anteriores e congelamentos continuam preservados.

**Pacotes:** 2025 v19 / congelamento205 / publicação37, ano inteiro; 2026 v21 / congelamento214 / publicação40 (saída251/rev36, contrato17), janeiro a setembro. A publicação efetiva deve ser conferida no catálogo do Estudo; o pacote214 acrescenta a revisão cadastral sem modificar os valores do pacote211.

- **Idades e gerações:** tratamento dos ranges do DBA incorporado nos congelamentos de05/10. Idade em31/12; nascimento plausível prioritário. Sem nascimento, faixa inteira à geração da idade central; categorias como GERAL F SOCIO continuam desconhecidas. Alfa/Z revisado em pontos percentuais já calculado. Fórmula histórica do PDF não recuperada.
- **Floripa:** desempenho recuperado no estudo: célula402/rev1, congelamento210, fonte RaceTag14221WX. 3.592 classificados geral/elite; 17 métricas restauradas e pódio entre dez provas. Correção/reimportação operacional do portal permanece pendente; não substituir outras fontes nacionais sem nova coleta.
- **Maratonas sem percurso:** revisão individual dos16 IDs do congelamento174. Auditoria404/rev1 congelada212; decisões405/rev1 congeladas213. Seis com42km confirmados na fonte, seis com tipo divergente, três com vínculo/modalidade a revisar, Foz com divergência de importação. Distância confirmada não certifica terreno, homologação ou conclusão individual. A regra antiga admitiu revezamentos e MTB; 1.456 linhas pela regra anterior não são novos concluintes de maratona. Próximos passos em cada caso; nenhum cadastro/resultados operacionais alterado.
- **Referências de2025:** cinco?? só na leitura Publicado no PDF: volumes exatos2023/2024/2025(P03); Norte feminino/masculino(P09). Solicitar valores originais e fontes ao DBA; não deduzir de barras, base atual ou100%.
- **Escopo2026:** Jan–Set, até30/09 nos dois anos comparados. Importações tardias e correções devem produzir novos congelamentos; não alterar a janela silenciosamente.
- **Regras confirmadas:** cobertura real =100% menos provas sem resultado/link/situação conhecida, IDs distintos; peso20–300kg inclusivo; estações por meses inteiros; preços=menor capturado de categoria geral identificada, separado de descontos/kids, com kits/lotes próprios. Atributos atuais das contas não reconstroem o perfil histórico.

**Fila de correção operacional:** primeiro conferir Foz(#48640): linkSuperCrono5K, linhas marcadas42km,105REVEZAMENTO e tempos mínimos de30segundos; causa não diagnosticada. Conferir UCCRIDE(#42782): organizador identifica MountainBikeXCM42km, portal classificado rua. Depois revisar tipo das demais cinco divergentes, associação das três inconclusivas e cadastro/terreno/data/solo dos seis confirmados. Corrigir na origem apropriada, reexecutar auditorias e publicar nova versão; não excluir só por um tempo rápido.

[Revisão web2026](https://roadrunners.run/brasilquecorreprovas/web/?ano=2026#maratonas-revisao).

---
## Histórico de acompanhamento — regras e pendências anteriores

O texto abaixo preserva decisões e evidências anteriores. Status/cortes/fontes antigos devem ser interpretados pela data; o estado vigente está acima. Revisões históricas também podem ser consultadas no editor.

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
| 14 | Adaptado | Faixas CNA, limites, crédito a Sérgio Rocha/Corrida no Ar; 2025 #60 e testes #62. | CNA e performance têm populações e fronteiras distintas. Flags PCD e resultados permanecem sujeitos à revisão cadastral; fontes iniciais2026 identificadas por indicador, sem recoleta (auditoria125). |
| 15 | Adaptado | Dez métricas e explicações; 305/rev4 (#104), testes #105. Outros esportes #69/#71 e 2026 #65/#71. | Todos os cadastrados até o corte, com bases próprias; atributos atuais não reconstroem o perfil passado. + significa mais de esse percentual, não crescimento. Peso20–300 kg inclusivo confirmado em03/10/2026. Esportes em barras em vez de retângulos, mantendo valores e base. |
| 16 | Omitido por decisão editorial | Anúncio RunPro “em breve” fica disponível no PDF original. | Não transportado para a reprodução analítica; não bloqueia reutilização em 2026. |

### Fontes, tabelas e exportações

O menu web oferece **Fontes e critérios**. Valores do PDF identificam sua página e não herdam execução, denominador ou regras do recálculo. Ressalvas históricas próprias de cobertura, Norte, variações e sinal + permanecem explícitas. CSVs geral e por gráfico incluem leitura, fonte, nota, ressalva, contagem, denominador, base e população quando informados; valor numérico conserva sua precisão. Ausência fica vazia, nunca zero nem valor histórico como fallback. Em2026,448 valores e dois totais tiveram suas fontes recuperadas dos recibos e das execuções próprias. Auditoria323/rev3 (#125); pacote251/rev21 (#126), publicação25/v12. Comparação JSON nativa confirma todos os valores/contagens/denominadores, cortes e coortes intactos. Consultas iniciais317–322/rev1 estão na seção Recortes e conciliação2026; sem nova coleta. As origens não foram inferidas pelo texto global do pacote.

### Aceite parcial e próximos passos

Revisão das 16 páginas do PDF e da implementação existente: conteúdo adaptado com duas referências quantitativas incompletas (P03/P09) e decisão editorial P16. Permanecem as decisões de cobertura nacional/14+, qualidade dos resultados, fonte dos tempos de Floripa, quatro variações históricas, cinco destaques contextuais de maratonas e qualidade do perfil. Isso não fecha integralmente as etapas 5/6 do plano.

As regras de idade, estações, tempos, grupos, medalhas e perfil já implementadas não voltam a ser tratadas como consultas ausentes. Próximas correções devem ler a revisão corrente, executar, congelar, conferir o pacote e publicar pela saída do mesmo caderno, preservando as versões anteriores.


### Rastreabilidade2026 — 01/10/2026

Esta revisão fecha a identificação por indicador dos448 valores e dois totais que não tinham fonte individual. Foram preservadas222 fontes já identificadas. Pub2026:25/v12/run126;2025 segue23/v13/run120. Os CSVs refletem as fontes adicionadas. Congelamentos anteriores continuam válidos; não houve nova coleta, mudança de critério ou certificação de equivalência com o PDF.


### Atualização03/10/2026 — responsabilidades e cobertura real

Registro central de pendências:327/rev2. DBA trata ranges/14+; cinco referências históricas P03/P09 exibem ?? e pedidos ao DBA na326/rev1. Floripa2026 aguarda recoleta da cronometragem pelo responsável; manter17 tempos pendentes. Peso20–300 kg inclusivo confirmado, sem recoleta da104. Definições editoriais das quatro variações Alfa/Z e dos cinco destaques contextuais de maratonas estão discriminadas na327.

Cobertura real:329/rev1, congelamento129. Cada prova uma vez; cinza = sem resultado bruto, link nos dois campos ou situação conhecida normalizada. 2025:7511/9414 =79,7854%, cinza1903/9414. 2026 até26/09:6099/7551 =80,7708%, cinza1452/7551. Não encontrado e códigos sem interpretação continuam pendentes. Fórmula antiga325/#127 e auditoria de links328/#128 preservadas. Somar barras antigas duplicava508/493 IDs. Os84,1% do PDF permanecem históricos.

Saídas novas249/rev27 e251/rev24 derivam dos JSONBs nativos120/126, preservando valores, contagens, bases, coortes e demais fontes. Só acrescentam a cobertura acima, cinco referências nulas e confirmação do peso. Contratos aditivos2025/8 e2026/9, sem alterar versões/validador anteriores. Publicar apenas depois de conferir os pacotes e validar o runtime.


### Publicação conferida — 03/10/2026

2025: publicação26/v14, execução congelada130, saída249/rev27. 2026: publicação27/v13, execução131, saída251/rev24. Comparação do JSON nativo público com os candidatos aprovada; desktop e celular conferidos em produção. P03/P09 exibem as cinco referências ??; demais fontes/valores/coortes preservados. Somente os três JS da versão web foram publicados. A tela Stats do RunnerHub não foi alterada e continua com a fórmula antiga. Auditoria e testes da classificação ficam no mesmo notebook (330/rev1, congelamento132, dez casos sem falhas).


### Stats do RunnerHub corrigido — 03/10/2026

A barra de /admin/stats_obs.cfm agora usa categorias exclusivas por ID, com a mesma regra da fonte329/#129: resultado bruto, link em qualquer um dos dois campos, situação conhecida normalizada, pendente. Inclui resumos zerados. Barra e observações compartilham período/localização/edições/circuitos; links e cores não se sobrepõem. Cada outra tela mantém sua projeção de resumo. Cards anuais do Stats continuam calculados pelos resumos de concluintes, diferença informada na tela.

2025 conferido em produção no Chrome:7511/9414 =79,8%; cinza1903 =20,2%, reproduz129. 2026 no Stats lê até o instante atual (03/10):6338/7901 =80,2%; cinza1563 =19,8%. Não comparar como crescimento com o corte do estudo:2026 web permanece publicação27/v13/#131, corte26/09 e80,8%. 2025 web26/v14/#130 também permanece. Nenhuma fonte analítica do DBA, range ou congelamento anterior alterado.

Validação: três casos CFML de regressão (dez eventos sintéticos); nove recortes reais contra SQL canônico em transação somente leitura; consumidor compartilhado de homologação; nove testes Python do projeto; compilação dos três CFMs e hashes publicados. Backup: /var/backups/runnerhub-stats-mapeamento-20261003/baseline. A auditoria325/#127 continua documentando a fórmula antiga.


### Maratonas — destaques do quadro publicados em03/10/2026

Célula331/rev2, execução congelada134: deriva fontes41 (2025,259rev2) e111 (2026,309rev1). Sem consultas novas aos resultados operacionais. Soma das dez provas:43.395/49.783 participações; composição feminina:10.420/43.395 e12.462/49.783. Quantidades e percentuais ponderados preservam a precisão; outros gêneros permanecem no denominador.2025 mantém a seleção histórica;2026 usa dez maiores até26/09. Esses valores não medem crescimento.

Fontes, critérios e unidades ficam no mesmo caderno6. A fonte331 aponta para congelamentos imutáveis; executá-la novamente apenas deriva esses resultados, não recolhe dados atualizados. Para atualizar: revisar e executar a consulta fonte vigente, congelar sua nova execução, ajustar as referências da derivação em nova revisão e publicar a saída candidata validada. Nunca substituir ou alterar os congelamentos anteriores.

Web publicada:2025 v15, publicação28, execução135, saída249/rev29, contrato9;2026 v14, publicação29, execução136, saída251/rev26, contrato10. Referências do PDF e demais indicadores byte a byte em JSONB preservados;173 células anteriores, exceto as duas saídas, ficaram iguais antes desta atualização de notas. Contratos aditivos, validador genérico intacto.

107 testes Node e46 Python passaram, incluindo conservação, unidades mistas, CSV, histórico e recuperação. Conferência oficial dos pacotes novos e anteriores, hashes dos três assets, HTTP e igualdade decimal dos pacotes públicos. Produção conferida no navegador integrado em1280px e390px; troca de fonte2025 mantém43.362 no PDF e43.395 no recálculo. Nenhum erro de console na conferência. Download de CSV pela interface não foi revalidado; seu conteúdo é coberto pelos testes.

Pendências centrais:327, agora distingue dois destaques implementados dos três restantes (número de maratonas, fração nacional e New York). Alfa/Z aguarda fórmula; DBA cuida dos ranges; cinco referências ?? e Floripa continuam pendentes. Apenas agregados, sem dados pessoais nem mutações nas provas.


### Cadastro/coleta de maratonas e NYRR — publicação03/10/2026

Fontes333rev1/#137 (cadastro, coleta, elegibilidade e auditoria por evento) e334rev1/#138 (referência externa verificadaNYRR). Universo BR/rua ativo elegível ao ranking, data_final por período; registro de distância rua/km42–42,2. Contagem por id_evento. Fração87/8801=0,98852403136007271901% em2025;73/7401=0,98635319551411971355% até26/09/2026. Cadastro de distâncias incompleto, bloqueados incluídos, cadastro não certifica realização. Cadastradas/coletadas/elegíveis63/63 em2025 e53/53 em2026; resultados fora do cadastro11/15 auditados sem correção operacional. Ver fonte137 para IDs e casos.

New York2025=59.226, confirmado em fonte oficialNYRR;2026prevista01/11,sem concluintes no corte. Célula334 conserva URLs, edição, data de verificação e estado. Referência externa não usa a população brasileira; não copiar para2026. Fonte é manualmente verificada; rodar334 não faz scrape nem atualiza o site externo.

Saídas2025:249rev30/#139, publicação30, webv16, contrato10.2026:251rev28/#141, publicação31, webv15, contrato11. Correção da página do PDF2026 em nova revisão; candidata140 preservada, não publicada. Demais séries, números, coortes, PDF,17NULLFloripa e nove provas do pódio mantidos. Sem alterações nas fontes doDBA ou nos cadastros/resultados. Validação JSONB nativa e decimal/HTTP confirmou conservação integral; contratos aditivos e função genérica intacta. Guardas de revisão e de publicação relidas.

111 testesNode e46Python passaram. SQL executado com relações sintéticas cobre grain, unidades/tipo, duplicação de percurso, limites de data, status/PCD e modalidadeINDIVIDUAL. Novo indicador exporta valores e bases, sem arredondamento do percentual. Histórico e recuperação mantidos. Revisão final independente sem achados acionáveis. Página sem divulgação na landing, noindex/no-store; um únicoassetestudo.js alterado. Prévia conferida1280/390 e troca de fonte2025.

Pendências atualizadas na327: fórmula históricaAlfa/Z, ranges/14+ comDBA, três volumes históricos e dois valoresNorte??, Floripa/recoleta. Acrescentada revisão cadastral42km paraDBA/admin com auditoria137. Destaques de maratonas implementados; conciliação da população histórica continua aberta.


### Estado final da publicação e conferência em produção

2025: publicação32/webv17, saída249rev30/#142, contrato10.2026: publicação33/webv16, saída251rev28/#143, contrato11. As saídas142/143 são JSONB idênticas às139/141: nenhuma recoleta, alteração numérica ou de critérios. Foram executadas novamente, preservando as mesmas fontes137/138, para corrigir apenas as descrições das publicações (a seleção do mesmo run é idempotente e não muda a descrição).

A nota inicial de2026 continha um trecho longo sem espaços e causava transbordamento na faixa de descrição. Nova publicação com texto legível resolveu: viewport390/scrollWidth390, confirmado após carregar o conteúdo. Produção2025 e2026 conferida1280/390;2025 troca de fonte preserva43.362/59.226/0,9% históricos e não inclui o quadro novo no PDF. Sem erros de console observados. HTTP final corresponde decimal e integralmente aos candidatos, exceto metadado de publicação; noindex/no-store preservados. Quatro capturas em cadastro_maratonas_2026_10_03; o conteúdo do CSV foi testado, o download pela interface não foi revalidado.

Conciliações e pendências acima permanecem iguais. Fontes doDBA, histórico,17NULLFloripa e comparativos anteriores conservados. A web consulta somente os pacotes congelados.
