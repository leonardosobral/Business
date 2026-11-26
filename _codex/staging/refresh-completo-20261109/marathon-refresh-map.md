# Atualização coordenada do vertical Maratonas 2025/2026

Mapa preparado em 09/11/2026 por leitura de código e snapshots locais. Não executa
consultas, não renova dados, não muda runtime e não autoriza publicação. O inventário
de células/revisões abaixo usa `notebook-before.json`, `source-inventory.json` e
`sources/cell-*.sql` desta pasta, capturados pelo controlador. Conferir novamente
revisões, hashes, carga e permissões no banco antes da execução futura.

## Estado que deve ser preservado

A origem canônica atual é `Business/estudos/lancamento/maratonas.cfm`, com o objeto
JSON inline `study-data`, e `Business/estudos/lancamento/maratonas-detalhado.js`.
O CFML não consulta o banco para montar o vertical: mudar uma célula/congelamento
não altera os números da página automaticamente.

Comparação local efetuada: ambos os arquivos canônicos são idênticos, byte a
byte, aos candidatos finais de
`RoadRunners/_codex/staging/brasil-gigante-maratonas-20261023/runtime/business/estudos/lancamento/`.

| Arquivo canônico | SHA-256 observado |
|---|---|
| `maratonas.cfm` | `3c76cbf15d102f88fadbb97e90f229deaaf564a8cefd8c43f63ddb6a523fa656` |
| `maratonas-detalhado.js` | `618fd3dbb06d3a9207696c6d5653954a8b59a0755f385eec5471b1accf70a601` |

Chaves atuais do JSON: `years`, `pairs`, `runs`, `boston`, `notes`, `age_audit`,
`pairs2025`, `context`, `brasil_gigante`. Não reconstruir apenas o objeto original
de `maratonas-completo`: isso elimina revisões posteriores.

| Objeto atual | 2025 | 2026 |
|---|---|---|
| Janela editorial | Janeiro a dezembro | Janeiro a setembro, corte 30/09 |
| Seleção e relação completa | 41 provas / 54.234 conclusões | 39 provas / 61.452 conclusões |
| Inventário de candidatas | 100 registros | 94 registros |
| Linhas da seleção curada | 50, incluindo decisões de exclusão/pendência | 39 selecionadas |
| Séries herdadas do principal | 26 | 28 |
| Perfil/histogramas | Base 54.234 | Base BI 61.454; distinta das 61.452 conclusões editoriais |

Esses números são o baseline, não metas para o refresh. Não fixar os mesmos totais
depois da carga nova. Floripa é a razão conhecida de diferença entre base de perfil
e ficha editorial: BI 3.594 versus captura oficial 3.592 de geral/elite.

## Fontes por tema e ordem de dependência

`BI2026` abaixo significa dependência de `estudo.vw_resultados_2026`, cujo produtor
é a carga da fato BI de 2026. Uma view comum não renova a tabela fato. Ler novamente
essa view antes da carga pode capturar novos metadados operacionais junto dos
mesmos resultados antigos; isso não constitui refresh completo dos resultados.

| Tema / destino | Célula, revisão e run atualmente usados | Entradas e cuidados | Dependência |
|---|---|---|---|
| Totais amplos por distância, contexto 2025 | 423 rev1 / 240 | `public.tb_resultados` + `tb_evento_corridas`; BR, data final anual, status 0, homologado e concluinte. Base distinta da seleção convencional de maratonas. | Operacional, pode recapturar antes do BI |
| Totais amplos por distância, contexto 2026 | 424 rev1 / 241 | `vw_resultados_2026` + cadastro; mesma lógica, janela Jan–Set. | BI2026 |
| Inventário 2025 | 425 rev1 / 242 | `public.tb_resultados`, cadastro e percursos; candidata tem percurso cadastrado ou resultados entre 42 e 42,2 km. Preserva flags de modalidade, PCD desconhecido, tempo ausente, sub2h e links. | Operacional, pode recapturar |
| Inventário 2026 | 426 rev1 / 243 | Equivalente sobre `vw_resultados_2026`; inclui João Pessoa Internacional de agosto, fora da seleção geral mas usado no Brasil Gigante. | BI2026 |
| Seleção 2025 | 427 rev1 / 244 | Deriva do inventário 242 e mapa editorial literal de 50 candidatas, com decisões. Não cria automaticamente uma lista nova de todas as importações. | Transformação; atualizar referência após novo 425 |
| Seleção 2026 | 428 rev1 / 245 | Deriva de 243 + oficial Floripa 210; whitelist literal de 39 IDs. Uma importação nova não entra automaticamente. | Transformação; aguardar novo 426 e revisão da seleção |
| Comparativo 2025 × 2026, totais e cenários Q4 | 429 rev1 / 246 | Lê 244/245. Pareia agregador com exatamente uma edição por seleção, mesma janela Jan–Set. Hoje 17 pares. Cenários usam sete provas Q4 de 2025; não são previsão nacional. | Transformação; após ambas seleções |
| Especial/oficiais/auditoria | 432 rev1 / 248 | Empacota runs 207,208,209,210,212,213,242,243. Só reexecutar com os mesmos IDs repete capturas antigas. | Transformação; cada origem tem ciclo próprio |
| Capítulo das maratonas do principal | 433 rev1 / 249 | Lê saídas 205/233, equivalentes às publicações 37/41. Seleciona `comparacoes.atual`, nunca a transcrição histórica do PDF. 26/28 séries. Não consulta `web_publicacoes` durante o notebook. | Após novas saídas gerais 2025/2026 |
| Perfil original 2025 / 2026 | 434 rev1 / 250; 435 rev1 / 251 | SQL com IDs da seleção embutidos. Gênero, geração, origem da idade e demais dimensões. As faixas de idade web posteriores vêm de 441/442. | 2025 operacional; 2026 BI |
| Tempos, cortes, grupos e histogramas por prova | 436 rev1 / 252; 437 rev1 / 253 | IDs selecionados embutidos. 2025 usa `public.tb_resultados`; 2026 usa BI. Mesmos filtros convencionais da seleção. Histogramas disjuntos por sexo; cortes sub4/sub3/sub2h30 cumulativos e estritos. | 2025 operacional; 2026 BI |
| Auditoria quinquenal histórica | 439 rev1 / 254; 440 rev1 / 255 | Versões anteriores preservadas. Não substituir a web atual pelas saídas quinquenais. | Histórica; não necessária para a web atual |
| Perfil por décadas + auditoria por prova atual | 441 rev1 / 256; 442 rev1 / 257 | Hoje alimentam `years[*].profile` e `age_audit`. Idade em 31/12; nascimento plausível prioritário; categorias inteiras, sem imputar idades. 442 combina BI e comparação com `public.tb_resultados` por `id_resultado`. IDs da seleção embutidos. | 2025 operacional; 2026 depende BI e operacional |
| Inventário 2024 | 444 rev1 / 258 | `public.tb_resultados` + cadastro/percursos; versão derivada da regra de 2025. Não é censo nacional validado. | Operacional, pode recapturar |
| Pareamento 2024 × 2025 diagnóstico | 445 rev3 / 260 | Lê 258/244/242 e vínculos atuais em `tb_evento_corridas`; há revisão 259 intermediária que não alimenta a web. | Operacional + transformações novas |
| Comparativo anual 2024 × 2025 validado pela lista CR | 446 rev2 / 261 | 258/260 + cadastro e diagnóstico direto `tb_resultados` de Pelotas. Restrição à lista externa literal, identificação confirmada; 19 pares na web. Volumes RR em ambos os anos, sem misturar volumes CR. | Sem BI2026; após novos 444/445 e seleção 2025 |
| Contexto principal/distâncias/Nova York | 449 rev2 / 263 | Deriva 240/241 e 205/233; anota publicações 37/41. Soma Brasil top10 vem do principal 2025. Nova York é literal 59.219, captura externa de 19/10; anterior 59.226 preservado. | Transformação com entradas BI2026 e externas |
| Adesão Brasil Gigante | 452 rev2 / 265 | `public.desafios` + cadastro + `vw_resultados_2026`. Corte cadastro/resultados 30/09; links de conta são atuais/possivelmente retrospectivos. Deduplica conta e evento. Data oficial do Paraná 03/05 substitui data cadastrada 28/04 somente nesta leitura temporal. | BI2026 para métricas de resultado; inscrições isoladas independem BI |
| Encarte Brasil Gigante | 453 rev2 / 266 | 210,242,243,244,245,246,252,253,265. Metadados com células/revisões/hashes e datas por fonte. `publication_run=266`, seção 67. | Transformação; após todos os novos inputs pertinentes |

Os SQLs atuais listados estão preservados em `sources/cell-<id>.sql`. Usar esses
arquivos e comparar com a revisão corrente no banco; scripts de outubro não são
autorização para sobrescrever células alteradas por outra frente.

### Séries do principal que o vertical também precisa renovar

A saída 433/249 não recaptura os temas originais. Reapontar para a saída geral
nova é necessário, mas a saída geral deve ter fontes atualizadas:

| Tema | 2025 | 2026 |
|---|---|---|
| Dez maratonas, volumes, gênero, tempos e cortes | 259 rev2 / 41, operacional | 353 rev2 / 218, BI, com substituição oficial Floripa 402/210 |
| CNA42 e performance42 por sexo | 274 rev2 / 60, operacional | 351 rev2 / 217, BI |
| Grupos mais rápidos | 281 rev2 / 67, operacional → 283 rev1 / 70 derivado | Integrados em 353/218 e oficial 210 |
| Pódios: 11 critérios nas dez provas do principal | 301 rev1 / 98, derivado de congelamentos | Integrados na saída revisada de 353/218 + 210 |
| Destaques | 331 rev2 / 134, derivado | Saída geral revisada; não copiar números antigos por texto |
| Cadastro de maratonas e com resultados | 333 rev1 / 137 | 364 rev1 / 174 |
| Auditoria/revisão de candidatas 2026 | Não aplicável | 404 rev1 / 212 operacional → 405 rev1 / 213 derivado |
| Referência internacional histórica | 334 rev1 / 138, literal externo | 334/138 preservado nas séries antigas; contexto 449/263 usa captura posterior de NYC2025 |

As células 333, 364 e 404 leem `public.tb_resultados`, cadastro e percursos,
**não a fato BI2026**, e podem ser recapturadas separadamente agora. A revisão 405
é uma transformação sobre seus congelamentos e decisões editoriais. Não confundir
essa possibilidade com atualização das participações/performance que vêm do BI.

O contexto 449 tem filtros próprios: agrega 240/241 somente para rua e exclui o
grupo `Sem distância válida` antes de calcular a distribuição e o denominador dos
42 km. Não aplicar a ele automaticamente o denominador da seleção convencional
ou o total de todos os resultados. Os recortes CNA também têm filtros próprios;
não os restringir inadvertidamente às 41/39 provas ou exclusivamente à rua.

## Regra efetiva da seleção 2025: 50 candidatas, 41 aprovadas

A seleção 244 não é `WHERE participacoes>0` sobre todas as 100 candidatas de 425.
Foi produzida por `maratonas-vertical-20261019/curate.py`, com conciliação registrada
em `cr-conciliacao-2025.json`, materializada no SQL atual da célula 427. A origem
editorial são as 50 candidatas do artigo parcial CR de 02/05/2025, ligadas
manualmente por nome, cidade e ano a IDs do portal; mudanças de datas de Niterói
e São Luís ficaram registradas, sem corrigir o cadastro.

Prioridades efetivamente implementadas no `curate.py` original, nesta ordem:

1. Fora dos 50 IDs do mapa: não entra nessa seleção, mesmo que apareça no inventário
   ou tenha novos resultados elegíveis. O inventário de 100 tem finalidade maior.
2. Conjunto literal `short={25395,26514,28612}`: excluir do desempenho por ressalva
   de percurso curto na referência CR. São Blumenau, FILA e Niterói/2025.
3. Conjunto literal `blocked={28391,23728}`: status “ranking=false na base; revisar
   antes de incluir”. São Piauí e Olinda Internacional. A decisão é uma lista
   editorial fixa: a query 425 **retorna** `ranking`, mas não filtra automaticamente
   todos os eventos por `ranking`; o `curate.py` também não reavalia esse flag para
   cada candidata. Não converter isso numa nova política automática por bool/null.
4. Demais IDs do mapa sem participações elegíveis: status “sem concluintes elegíveis
   nesta captura”. No baseline: Gramado 30485, Foz 28613, Pelotas 28615, Pedra Azul
   28616. Essa condição foi calculada no gerador a partir do run242 e depois ficou
   literal dentro do SQL427; trocar só 242 por novo run não recalcula a decisão.
5. Demais IDs do mapa: `selecionada`. Resultado original: 50 = 3 curtas + 2 bloqueadas
   + 4 sem elegíveis + 41 selecionadas. O status não certifica aferição da prova
   nem completude da coleta. `validate_freeze.py` e as notas históricas explicitam
   que é uma seleção inicial, e não lista nacional final.

Fonte exata dos 41 IDs aprovados: `cell-427.sql`, linhas `VALUES` com
`decisao='selecionada'`, ou as 41 linhas correspondentes de `selecao-2025-run.json`.
Esses mesmos IDs estão materializados em `IN(...)` nos SQLs atuais 434,436,441.
Eles **não leem** o run244 durante a execução: 244 nos comentários é proveniência
da geração da lista. Reexecutar esses SQLs reconta somente a seleção já embutida;
não descobre outras provas e não renova automaticamente a decisão da célula427.

### Atualização permitida sem inventar política editorial

Para preparar a revisão offline, alinhar por `id_evento` as 50 linhas do mapa atual
com o novo inventário425. Preservar decisões explícitas e produzir uma tabela de
diferenças: ID/nome/cidade/data, decisão anterior, nova elegibilidade, ranking e
modalidades, motivo de inclusão/exclusão proposta e fonte que sustenta a mudança.
Mostrar separadamente novos positivos entre os quatro sem elegíveis, IDs do mapa
que sumiram, mudanças nos 41 existentes e candidatas que estão fora dos 50.
Não transformar uma linha ausente no join em zero nem deixá-la desaparecer sem
diagnóstico. O SQL atual usa inner join; a revisão precisa conferir presença
das 50 antes de aceitar sua saída.

O algoritmo original permite propor `selecionada` para uma antiga linha sem
elegíveis que agora tenha resultados, mas **essa proposta não está aprovada só
porque o código a produziu**. Novos IDs ou mudança das exclusões acima exigem
conferência CR/identidade/modalidade/distância/duplicidade e decisão editorial do
responsável antes de alterar a seleção aprovada. Esse é o limite pedido pelo
controlador; não se propõe critério de seleção novo nesta análise. Fontes externas
não foram relidas nesta subtarefa, logo não se afirma que uma ressalva CR acabou.

Até essa decisão, a opção independente segura é analisar/recapturar a mesma
amostra aprovada de 41 IDs e reportar diferenças como sondagem dessa amostra,
além de inventários amplos e contexto operacional. Isso não representa seleção
ampliada nem refresh completo do estudo. Se um dos 41 tiver nova inconsistência,
mostrar a pendência e segurar montagem final em vez de incluí-lo/excluí-lo
silenciosamente.

Depois da decisão, congelar a seleção revisada a partir do novo425, conservar o
histórico das exclusões e usar **o conjunto selecionado desse novo run** como
entrada única para regenerar os `IN(...)` de 434/436 e 441. `make_queries.py` mostra
como 434/436 foram derivados da seleção; `make_decades.py` mostra como preservar
as décadas e auditoria da 441. Adaptar os geradores em staging novo: os existentes
leem arquivos fixos de outubro e não devem ser executados sobre a documentação
histórica para substituí-la. Guardar hash da lista ordenada de IDs e run/revisão
de seleção como metadados, e conferir igualdade de IDs nas três consultas.

Recalcular então síntese429, comparativo445/446, CSVs e dados por prova. Na montagem
web, substituir as chaves pertinentes sobre o HTML canônico de 23/10, preservando
`age_audit`, `pairs2025`, `context`, `boston`, `brasil_gigante`, navegação e guardas;
não voltar ao `build_data` original que só conhecia as primeiras cinco chaves.
Mesmo uma parte 2025 coerente fica em candidato offline até o corte coordenado
após a renovação BI2026, conforme orientação do controlador.

### Coletas iniciadas pelo controlador nesta sessão

O controlador informou novas execuções candidatas: 425→292 (100 eventos),
434→293, 436→294, 441→295, 444→296 (88 eventos). Os runs293/294/295 continuam
limitados aos 41 IDs literais antigos e foram corretamente classificados como
**sondagem**, sem uso na montagem final antes da revisão da seleção. A igualdade
100/88 de tamanho de inventário não comprova igualdade dos resultados, vínculos
ou decisões. Estes IDs/contagens são informação fornecida pelo controlador; não
foram consultados remotamente nem validados por esta subtarefa. Não presumir que
sejam congelamentos finais nem substituir os recibos históricos.

## O que pode ser preparado antes da carga DBA

1. Recapturas operacionais independentes: células 423,425,436,441,444; fontes gerais
   de 2025 pertinentes; cadastro 333/364 e auditoria operacional 404. A seleção
   427, comparativo 445/446 e fontes derivadas de 2025 podem seguir os novos runs.
   Se a seleção mudar, regenerar as listas de IDs nos SQLs de perfil/provas/idades.
2. Diagnóstico só de inscrições do Brasil Gigante pode consultar `public.desafios`
   sem o BI. A célula 452 completa não é independente: suas taxas de resultado e
   recorrência dependem de `vw_resultados_2026`. Não rotular o run completo como
   atualizado antes da recarga da fato. Não trocar o corte de 30/09 pelo dia atual.
3. Reexecutar 427/428/429/432/433/449/453 sem atualizar seus IDs apenas reprocessa
   resultados antigos. Pode testar transformação, mas não recaptura a base.
4. Boston, Floripa oficial e Nova York independem da fato BI. Entretanto os SQLs
   de Boston/Floripa contêm os dados externos capturados como **JSON literal**;
   reexecutá-los não consulta RaceTag/Runking nem obtém informação nova. Se não houver
   nova captura oficial autorizada, manter a data e o hash antigos explicitamente.

Não foram executadas essas etapas nesta subtarefa. A oportunidade de execução
independente não certifica permissões/tempo de execução: respeitar os limites do
executor, comparar estado e tratar falhas sem ampliar acessos.

## Boston: universo independente, narrativa também embutida

| Caso | Célula / run | Fonte e escopo preservados |
|---|---|---|
| Floripa índices gerais | 396 rev1 / 207 | RaceTag/MyCrono `14221WX`, captura 05/10; corrida a pé, 3.603 concluintes incluindo PCD/DV separados; 264 atingem tabela geral. Idade em 19/04/2027. |
| Floripa curiosidades/gerações | 398 rev1 / 208 | Mesma captura de 207; gerações por nascimento individual. |
| NB Porto Alegre auditoria | 400 rev1 / 209 | Runking/API, captura 05/10; mínimo verificável 887 em geral/elite; 908 divulgados permanecem não confirmados e teto teórico não é estimativa. |
| Floripa desempenho convencional | 402 rev1 / 210 | Mesma captura oficial; 3.592 geral/elite; substitui integralmente o BI editorial para essa prova, sem soma. |

O hash da captura RaceTag nos SQLs é
`d2202b8d9d0f9c1727980838d81ee33c08a65e858bd480fee6c01236aeaf5dbd`.
Nota editorial do encarte: célula 448 rev2. Boston é exibido somente na edição 2026.
Não é ranking abrangente nem comparação causal entre as duas provas. Índice geral
não confirma vaga/inscrição e não substitui regras específicas de paratletismo.

`bostonInsert()` do JS atual contém números narrativos literais: 264/186/78/3.603,
262/2/189, estatísticas de idade, 887/670/217/1.259 e data 05/10. As tabelas usam
`D.boston`, mas os destaques e parágrafos não. Nova captura exige atualizar ambos,
de preferência derivando a narrativa do novo objeto, sem só trocar o JSON.

## Brasil Gigante: preservar decisões que não vêm da carga BI

Oito etapas; sete dentro do corte e seis pares comparáveis. A referência 2025
antecede o lançamento do circuito. As comparações somam conclusões e depois
calculam a variação, nunca fazem média de percentuais individuais.

- João Pessoa é a Internacional de agosto, agregador 14 / evento 32450; não é
  a prova de abril, agregador 12. Entra pelo inventário 426/243 mesmo sem estar na
  seleção geral 428/245. Baseline 335 versus 332 oficial é pendência, não ajuste
  automático; atualizar a diferença narrativa se a nova fonte mudar.
- Paraná é estreia, sem base 2025. Data oficial 03/05/2026 e data cadastrada 28/04
  permanecem documentadas; não apagar a divergência ao renovar os resultados.
- Aracaju 2025 em outubro e 2026 prevista em novembro ficam fora de Jan–Set;
  resultado ausente não vira zero e não entra na soma Q3 só porque já houve corrida.
- Floripa editorial usa 210, operacional de adesão usa BI: populações distintas.
- Benchmark exclui etapas do circuito por agregador e deriva dos pares de 429.
  Há sensibilidade sem Floripa e sem NB no benchmark; não tratar como grupo causal.
- A adesão usa contas cadastradas até o corte, resultados associados e deduplicação
  por conta/evento. Associações podem ser retroativas e cadastro não prova que a
  pessoa concluiu uma etapa. Não gerar lista nominal ou dados pessoais no pacote.

Além de atualizar referências SQL, revisar `seed`, notas e metadados da 453,
`quality_notes` e texto JS: a página ainda traz literal “diferença de três”, a data
fallback 23/10, número de etapas/pares e referências temporais. O campo
`publication_run` só deve receber o novo congelamento final validado, não o run de
adesão. Não renomear 265/266 antigos nem editar seus resultados congelados.

## Geradores e preservação das revisões recentes

Todos os caminhos nesta seção são relativos a `RoadRunners/_codex/staging/`.

| Camada | Fontes/gerador existente | Limite para reutilização |
|---|---|---|
| Base do vertical | `maratonas-vertical-20261019/`: inventários, seleções, síntese e `build_report.py` | Piloto; não produz as revisões web posteriores. SQL tem IDs de run e listas editoriais fixas. |
| Detalhado principal | `maratonas-completo-20261019/{make_queries,build_data,build_html}.py` | Produz base `years/pairs/runs/boston/notes` e CSV de indicadores. `build_data` fixa runs e overlay Floripa; sozinho perde chaves posteriores. Não executar `build_pdf.py` neste refresh web. |
| Idades por décadas | `maratonas-web-revisao-20261019/{make_audit,make_decades,build_audit}.py` | `build_audit` substitui perfil e inclui `age_audit`; compara dimensões não etárias com base anterior. Adaptar entradas/IDs em candidato, preservando a regra. |
| Anual 2024 × 2025 | `maratonas-coorte2024-20261019/`: SQL 444/445/446 e `build_html.py` | Manter `pairs2025`, lista CR, exclusões e intervalos de calendário. Não usar o diagnóstico 259. |
| Encarte Boston | `maratonas-boston-encarte-20261019/build_html.py` e renderer da pasta | Inclui linguagem de dois estudos de caso e nota 448. Não voltar à seção genérica anterior nem ao termo “corrida a pé” como título de subtotal. |
| Contexto do principal | `maratonas-contexto-revisao-20261019/contexto.sql`, `build_html.py` e renderer | Inclui `context`, cruzamentos entre distâncias, escala dos 42 km e NYC. Reapontar fontes 240/241/205/233 e metadados, sem misturar universos. |
| Todas as provas | `maratonas-todas-provas-20261019/build_html.py` e renderer | Acrescenta seção `todas-maratonas` com tabela completa. Não tem consulta nova própria: usa `years[ano].races`, ordenadas por total/id. Top10 continua nos gráficos/fichas, todas 41/39 nos consolidados. |
| Brasil Gigante (último pacote canônico) | `brasil-gigante-maratonas-20261023/analysis/{build_payload,build_sql,validate_payload}.py` e `build.py` | `build.py` lê baseline anterior ao encarte, injeta objeto/JS/CSS/nav e gera leitores de imprensa; preserva todas as chaves anteriores. Não é um reconstrutor genérico de toda a DAG; também contém IDs fixos e asserts dos números antigos. |
| Leitor imprensa | `imprensa-estudos-20261019/reader-builder.py`: `marathon_reader()` | Consumidor canônico do HTML/JS Business atuais. Regerar a partir do candidato Business; não editar imprensa manualmente. |

Não há no código inspecionado um único gerador parametrizado que recapture toda
a DAG e preserve todas as revisões automaticamente. `build.py` de 23/10 é a base
mais recente confirmada por igualdade dos bytes, mas ainda é um patch do encarte
sobre um baseline fixo. Para novo refresh, materializar explicitamente cada chave
do JSON sobre uma cópia do HTML canônico atual e manter o renderer atual, adaptando
seus números literais. Comparar diffs de layout/nav/guards e ausência de chaves
perdidas antes de publicar. Os `notebook.py` históricos retornam runs de arquivos
`*-run.json` já existentes; rodá-los sem staging novo pode apenas reutilizar cache
antigo. Não apagar recibos históricos para forçar nova execução.

### Outros literais atuais que exigem revisão

- `render()`: rótulo “17 pares” e narrativa de crescimento, mesmo com novo tamanho
  ou sinal da coorte; usar contagem/taxa do novo objeto e linguagem consistente.
- Cenários Q4: `61.452`, `70.219`, `71.396` estão literais no JS, apesar de a síntese
  possuir campos `cenarios`. Derivar da nova síntese ou manter explicitamente como
  cenário histórico; nunca apresentar como resultado atual.
- `fontes`: ranges de congelamentos 248–253 e referências antigas não mudam ao
  trocar `D.runs`. Atualizar referências e datas próprias por tema.
- Títulos/narrativas do Brasil Gigante e Boston podem exigir mudança quando o
  sinal, volume, diferença de conciliação ou fonte mudar; o atual renderer mistura
  texto fixo e valores dinâmicos.
- Lista completa deriva do payload; não exige manter números 41/39. Já pódios e
  gráficos de determinadas séries herdam as dez provas do principal. Se o novo
  top10 selecionado divergir, conferir títulos/categorias e preservar proveniência
  em vez de recaracterizar o pódio como recalculado sobre toda a seleção.

## Saídas e limites de acesso

Business entrega HTML/JSON embutido em `estudos/lancamento/maratonas.cfm`, JS
`maratonas-detalhado.js` e os CSVs protegidos de indicadores/seleção/pares/idades
em `estudos/lancamento/arquivos/`, por `arquivo.cfm` com guard administrativo.
Todos são arquivos estáticos; nenhum se renova somente por publicar nova saída Q3.

Imprensa entrega `brasilquecorreprovas/imprensa/maratonas/{index.cfm,maratonas-detalhado.js}`.
O gerador canônico particiona o JSON por edição e aplica o guard de cada ano:
2025 não recebe Boston, Brasil Gigante nem cenários2026. Mantém a lista completa
da edição e remove downloads/links internos administrativos. Preservar o contrato
de acesso de imprensa vigente; atualização de dados não autoriza fechá-lo ou
alterar convites/entitlements.

PDF executivo e PDF detalhado de Maratonas são versões anteriores preservadas;
há instrução documentada de continuar somente na web até aprovação visual/editorial.
**Não regenerar nem substituir esses PDFs nesta etapa.** Ao trocar CSVs web,
identificar claramente que PDFs antigos não foram atualizados. Não alterar RR Teams:
checkout e candidato têm de passar o hold antes de qualquer deploy RR futuro.

## Sequência futura recomendada após liberação da carga

1. Guardar baseline real de banco e arquivos, inclusive hashes dos PDFs que devem
   permanecer iguais; comparar snapshot desta análise com estado corrente.
2. Validar carga DBA: contagens, datas, dimensões, ranges/idades e relações por
   `id_resultado`, sem mudar permissões ou redefinir views para contornar bloqueios.
3. Congelar fontes independentes 2025/2024 e os novos 2026 BI. Revisar inventários,
   candidatos duplicados, modalidades e seleção explícita; não promover pendências
   automaticamente por haver resultados novos.
4. Regenerar seleções, listas de IDs de perfil/provas/décadas e sínteses/coortes.
   Atualizar fontes gerais e saídas principais, então capítulo433 e contexto449.
5. Renovar adesão452 somente com BI validado; derivar encarte453 dos novos runs.
   Boston/Floripa/NYC preservam capturas antigas se não houver recaptura separada.
6. Montar payload com TODAS as chaves e atualizar narrativa literal do renderer.
   Regenerar CSVs pertinentes, sem PDFs; gerar imprensa pelo reader-builder usando
   a cópia candidata Business. Preparar mapa explícito célula→revisão→run novo e
   hash da carga/origens para cada tema.
7. Validar somas por sexo/idade/histograma, Floripa oficial versus BI, ranking/cortes,
   unicidade dos pares, soma de coortes antes de taxa, ambas janelas, 8 etapas BG,
   desconhecidos e ausências. Confirmar todas as provas e top10/fichas, deep links,
   ambos anos, tabelas completas/rolagem própria e fontes/CSV. Comparar objetos não
   renovados e garantir ausência de números antigos apresentados como novos.
8. Fazer corte coordenado dos consumidores e verificar resultados reais conforme
   fluxo de publicação do controlador, com backup/rollback e guards/Teams intactos.
   O vertical estático em si não depende de DDL novo. A view pública do estudo
   geral continua tendo seu bloqueio separado de DDL/ponteiros; não alterar essa
   proteção para publicar apenas parte de um pacote alegadamente atualizado.

## Evidências locais consultadas

- `Business/_codex/staging/refresh-completo-20261109/{notebook-before.json,source-inventory.json,sources/}`.
- JSON `study-data`, renderer atual e comparação SHA dos dois arquivos canônicos.
- `RoadRunners/_codex/docs/brasil_que_corre_provas/maratonas_detalhado_2026_10_19/README.md`
  (registra revisões de idades, comparativo 2024, Boston, contexto e todas as provas).
- `RoadRunners/_codex/docs/brasil_que_corre_provas/2026-10-23_brasil_gigante.md`.
- SQLs e geradores das pastas de staging enumeradas acima; especial atenção aos
  SQLs atuais 423–453, não só às versões históricas de outubro.

Esta entrega altera somente este documento. Nenhum SQL remoto, navegador,
servidor de teste ou processo persistente foi iniciado por esta subtarefa.
