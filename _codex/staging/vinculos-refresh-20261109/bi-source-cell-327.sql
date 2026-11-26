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

# Pendências e decisões do estudo — 03/10/2026

Este é o registro central no caderno 6. Não envia mensagens ao DBA nem altera suas consultas. Os pacotes publicados conservam os demais congelamentos e critérios.

## 1 — Idade mínima e ranges: responsável DBA

O DBA vai tratar a coluna de ranges. A referência de idade segue 31/12 do ano da prova. Não alterar a carga agora. Após o tratamento, conferir os intervalos, executar as consultas revisadas e congelar novos resultados antes de atualizar totais/recortes. Ajuda ao DBA somente quando solicitada pelo responsável.

## 2 — Mapeamento real confirmado pelo responsável

Decisão de03/10: 100% menos provas sem resultado coletado, link de resultado ou situação conhecida. Cada ID uma vez. População ativa BR com UF reconhecida, mesma do Stats; 2025 inteiro e2026 até26/09. Inclui resumos zerados. Resultado coletado = qualquer linha bruta; não certifica completude nem conclusão elegível. Links: url_resultado ou url_wiclax após trim. Situação conhecida: Sem Resultado, Kids, Treino, Cancelado, Adiado, Repetido e Adiado/Cancelado, normalizada por maiúsculas/espaços. Prioridade: coleta, link, situação, cinza.

Fonte real: célula329/rev1, congelamento129, coleta03/10/2026 às08h09. Em2025: 7.511/9.414 =79,7854259613341831%; cinza1.903 =20,2145740386658169%. Em2026 até26/09: 6.099/7.551 =80,7707588398887565%; cinza1.452 =19,2292411601112435%. Os demais totais/coortes mantêm suas coletas; o aumento entre essas coberturas não mede crescimento do mercado.

Não encontrado continua cinza. Códigos Modalidade, TF, PNC, Formato e duplicado permanecem pendentes de interpretação nesta versão: não transformar toda observação livre em mapeamento. Pedido de esclarecimento ao responsável, sem enviar mensagem externa. Corrigir a lista reconhecida apenas em nova revisão/congelamento após definição.

Auditoria preservada:325/rev1, congelamento127, reproduz fórmula antiga (83,6060% em2025; 86,0817% em2026). Ela conta508/493 provas em azul e vermelho e exclui2/7 resumos zerados. Deduplicar só a barra antiga daria78,2087%/79,5467%; não é a mesma regra real acima, que consulta resultados brutos, ambos os links e Kids normalizado. Auditoria328/rev1, congelamento128, documenta links/observações ignorados na barra antiga. Os84,1% do PDF continuam históricos; não substituir pelo recálculo de hoje.

## 3 — Pedidos ao DBA: cinco referências históricas com ??

- PDF P03: total exato da barra de 2023 — ??
- PDF P03: total exato da barra de 2024 — ??
- PDF P03: total exato da barra de 2025 — ??
- PDF P09: Norte, distribuição regional feminina — ??
- PDF P09: Norte, distribuição regional masculina — ??

Pedir os valores originais e, se existir, a query/recibo correspondente. Preencher no mesmo notebook e congelar a versão revisada. Não usar a base de hoje, altura da barra, zero ou complemento de 100% como substituto. Na web, ?? é apenas apresentação: os dados e CSVs permanecem NULL.

## 4 — Floripa 2026: aguarda recoleta da cronometragem

Responsável confirmou a recoleta futura. Não investigar nem recalcular tempos nesta etapa. Manter volume/composição; os 17 valores de desempenho continuam sem cálculo e o pódio parcial usa nove provas. Depois da recoleta, conferir modalidade/tempos e congelar outra versão antes de reinserir a prova no desempenho e pódio. Pendência permanece aberta até validação, sem prazo inventado.

## 5 — Decisões a confirmar

### Variações de Alfa/Z

O PDF traz +4,81% versus 2023, +1,22% versus 2024, +0,64% feminino versus 2024 e +1,91% masculino versus 2024. O algoritmo original não foi recuperado. Decidir: preservar como destaques históricos, solicitar o algoritmo ao DBA, ou substituí-los no recálculo por uma definição explícita. Diferença de participação = pontos percentuais; crescimento da quantidade de participações = percentual relativo. Não converter os quatro números históricos sem a fórmula original. Não reabrir regras de idade/coortes já confirmadas.

### Destaques contextuais das maratonas

**Soma e composição das dez provas implementadas em03/10.** Célula331/rev2, congelamento134, derivação exclusivamente das fontes já congeladas:41/259rev2 para2025 e111/309rev1 para2026. Nenhuma recoleta dos resultados. 2025 mantém as dez provas da seleção histórica para conciliar o quadro;2026 usa as dez maiores por concluintes elegíveis no corte26/09. Os universos e períodos diferem; não calcular crescimento entre essas somas.

- 2025:43.395 participações;10.420 femininas/43.395 =24,0119829473441641%.
- 2026 até26/09:49.783 participações;12.462 femininas/49.783 =25,0326416648253420%.

Escopo editorial desta versão: **Mulheres nas dez provas**, explicitamente rotulado. Soma das quantidades F / soma de todas as participações, incluindo gênero desconhecido; não média simples dos percentuais de cada prova. Neste congelamento há zero desconhecidos nas duas seleções. Isso não confirma que o destaque histórico de24% usava o mesmo universo. Floripa2026 continua no volume e na composição;17 valores de desempenho seguem pendentes da recoleta.

Publicações:2025 v15/#28, saída249/rev29, congelamento135, contrato9;2026 v14/#29, saída251/rev26, congelamento136, contrato10. As cinco referências do PDF, demais indicadores e comparativos anteriores foram preservados. CSV e fonte identificam as unidades por indicador. Contratos e resultados anteriores permanecem recuperáveis.

**Cadastro, coleta e referência externa implementados em03/10.** Fonte333/rev1/#137, consulta executada/congelada no notebook; fonte334/rev1/#138 registra a referência externa verificada naNYRR. Saídas249/rev30/#139 (2025) e251/rev28/#141 (2026). Publicações30/webv16/contrato10 e31/webv15/contrato11. Contratos anteriores e validador genérico preservados. A candidata2026/#140 permanece para auditoria: metadado de página do PDF incorreto foi corrigido em nova revisão, sem mudar números; só#141 publicada.

Regra revisada: eventos ativos BR/rua, ranking nulo ou diferente defalse, data_final no ano2025 inteiro ou2026 até26/09. Uma unidade=id_evento distinto. Cadastro=ao menos um percurso rua/km de42 a42,2km, sem inferir pelo nome; bloqueados permanecem cadastrados. Numerador e denominador da fração pertencem à mesma base. Cadastradas não certifica realização; pode incluir canceladas. Cadastro de distâncias incompleto pode subestimar: só5.256/8.801 eventos2025 e3.280/7.401 eventos2026 têm algum percurso positivo emkm.

| Recorte |2025 inteiro|2026 até26/09|
|---|---:|---:|
|Calendário BR/rua ativo elegível ao ranking|8.801|7.401|
|Maratonas cadastradas|87|73|
|Cadastradas com linha bruta42km|63|53|
|Cadastradas com concluinte elegível42km|63|53|
|Linha bruta42km sem percurso cadastrado|11|15|
|Concluinte elegível42km sem percurso cadastrado|9|15|
|Resultados42km em toda a base|74|68|
|Com concluinte elegível em toda a base|72|68|
|Participações elegíveis em toda a base|58.922|64.285|
|Cadastradas/calendário|0,98852403136007271901%|0,98635319551411971355%|

Coleta=ao menos uma linha bruta da distância, não comprova completude. Elegível=status0/homologado/concluinte/tempo positivo, pcd=false e modalidade convencional por termos delimitados, igual regra revisada2026. Este recorte difere do legado2025; não substitui as dez provas ou seus tempos. Resultados sem percurso cadastrado são auditados fora do numerador do cadastro; não os somar para chamar87+11 de cadastradas.

**Pendência de qualidade do cadastro para DBA/admin:** revisar os11/15 eventos com resultados42km e percurso ausente/divergente (IDs, nomes e datas na auditoria congelada137). A auditoria não certifica que todos são maratonas reais. Nenhum evento, percurso ou resultado foi alterado. Não confirma universo62/0,9% do PDF; referências históricas permanecem íntegros. O parcial não mede crescimento frente ao ano inteiro.

**New York:**59.226 concluintes2025 confirmados pela organizadora emhttps://www.nyrr.org/tcsnycmarathon; consulta da página oficial emhttps://testcache.nyrr.org/tcsnycmarathon e confirmação no release04/03/2026 https://www.nyrr.org/media-center/press-release/2026_0304_tcsnycmdrawingday. Verificação03/10/2026 registrada na fonte334/#138.2026 prevista01/11 e ainda não realizada no corte ou na verificação; valorNULL, nunca0 ou cópia2025. Referência externa com outros filtros; não equivalente à população brasileira do quadro. Rodar334 registra o valor verificado, não busca automaticamente atualizações daNYRR.

Os quatro destaques históricos de Alfa/Z continuam aguardando a fórmula original indicada acima. DBA trata ranges/14+; referências históricas ?? e recoleta de Floripa continuam com os responsáveis definidos. Peso20–300 kg permanece confirmado.

### Peso médio

Confirmado pelo responsável em03/10/2026: intervalo20–300 kg, inclusivo. Um registro de 740 kg fica fora; zero/NULL também ficam fora. As médias com o intervalo e com todos os pesos positivos já estão no congelamento 104. Regra fechada; não ajustar para coincidir com os 67,8 kg históricos do PDF.


### Estado final da publicação e conferência em produção

2025: publicação32/webv17, saída249rev30/#142, contrato10.2026: publicação33/webv16, saída251rev28/#143, contrato11. As saídas142/143 são JSONB idênticas às139/141: nenhuma recoleta, alteração numérica ou de critérios. Foram executadas novamente, preservando as mesmas fontes137/138, para corrigir apenas as descrições das publicações (a seleção do mesmo run é idempotente e não muda a descrição).

A nota inicial de2026 continha um trecho longo sem espaços e causava transbordamento na faixa de descrição. Nova publicação com texto legível resolveu: viewport390/scrollWidth390, confirmado após carregar o conteúdo. Produção2025 e2026 conferida1280/390;2025 troca de fonte preserva43.362/59.226/0,9% históricos e não inclui o quadro novo no PDF. Sem erros de console observados. HTTP final corresponde decimal e integralmente aos candidatos, exceto metadado de publicação; noindex/no-store preservados. Quatro capturas em cadastro_maratonas_2026_10_03; o conteúdo do CSV foi testado, o download pela interface não foi revalidado.

Conciliações e pendências acima permanecem iguais. Fontes doDBA, histórico,17NULLFloripa e comparativos anteriores conservados. A web consulta somente os pacotes congelados.
