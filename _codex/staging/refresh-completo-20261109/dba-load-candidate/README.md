# Carga Q3 2026 — candidato para revisão no DataGrip

Nenhum destes arquivos foi executado no banco. A assinatura, definições e contratos usados foram lidos pelo controlador em09/11 e preservados em `../dba-load-review/current-metadata.json`. O script original recebido tem SHA256 `d9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08`.

Executar o **arquivo inteiro em uma conexão/console DataGrip novo e sem transação pendente**. Uma aba nova pode compartilhar a conexão anterior; é necessário confirmar uma conexão nova e limpa. O guard recusa isolamento diferente de `REPEATABLE READ`, mas não detecta uma transação anterior nesse mesmo isolamento: o `COMMIT` poderia confirmar DML alheio. O candidato não tenta detectar, confirmar nem reverter transações de outras tarefas.

A entrada operacional proposta é **15-load-and-cutover.sql**. Ela cria uma versão aditiva da fato no schema `estudo`, carrega janeiro–setembro, valida a conservação e troca exclusivamente os dois adaptadores do estudo, com um único `BEGIN ... COMMIT`. A fato e view públicas originais, produto41 e JSONs publicados233/239 permanecem preservados. Qualquer erro aborta a transação; executar `ROLLBACK` e revisar a causa antes de tentar novamente. Não executar o arquivo15 depois de já executar10: o guard de versão existente recusará a duplicação.

Os arquivos10 e30 mantêm carga e troca separadas para revisão. Se for necessário executar por etapas,10 cria a versão validada sem trocar os adaptadores;30 faz somente a troca após conferir hashes e contratos. O arquivo40 restaura as definições capturadas dos adaptadores, verifica alterações concorrentes e conserva a nova fato e histórico.

| Arquivo | Finalidade |
|---|---|
| `source-select.sql` | CTE/SELECT independente das20 colunas. Serve para `EXPLAIN` ou amostra interna controlada; contém IDs e não deve ser exibido cru como evidência pública. |
| `00-preflight.sql` | Um SELECT JSON agregado sem dados individuais: período, NULLs, modalidade/tipo, datas ausentes/ambíguas, dimensões duplicadas, gerações, assinaturas/hash e permissões de criação. |
| `10-load-version.sql` | Carga aditiva e views versionadas, sem troca das views vigentes. |
| `15-load-and-cutover.sql` | Entrada operacional única:10 e30 na mesma transação/snapshot, sem commit intermediário. |
| `20-verify-version.sql` | Leitura agregada da versão/recibo após execução. |
| `30-cutover-study.sql` | Troca dos dois adaptadores após carga validada; não altera produtos/publicações/view pública de lançamento. |
| `40-rollback-study.sql` | Recuperação dos adaptadores, condicionada a não haver alteração concorrente desde a ativação. |

## O que muda em relação ao script DBA recebido

| Regra | DBA recebido | Candidato do estudo |
|---|---|---|
| Destino | Apaga/recria a fato e view públicas | Cria `estudo.fat_perfil_br_2026_20261109`; nenhum objeto público é escrito |
| Consistência | Nove inserts com commits mensais | Materializa a fonte uma vez e insere nove meses sob um único `REPEATABLE READ` |
| Universo | Exclui `KIDS`, NULL de modalidade, tipos fora de rua/trail e tempoNULL | BR, data_final `[01/01,01/10)`, status0, resultado homologadoTRUE, concluinteTRUE; todas as modalidades/idades, tempoNULL/zero conservado |
| Homologação | Filtro de resultado comentado | `r.homologado IS TRUE`; homologação do evento é atributo preservado, inclusive FALSE/NULL |
| Geração | Função de dois argumentos | Função atual de quatro argumentos `(idade_range,ano,data_nascimento,data_final)`, com guard do hash e da sobrecarga de dois argumentos usada internamente |
| Dimensão de data | INNER JOIN por data_inicial; ausência exclui e duplicação multiplica | LEFT JOIN; ausência mantém `id_data=NULL`; chave ambígua bloqueia para revisão |
| Localidade/organizador/cronometrador | Menor ID, fallback0 | Mesma normalização DBA, agrupada antes da junção para evitar subconsulta por resultado |
| Outros NULLs | NOTNULL em sexo/percurso poderia rejeitar elegíveis |20 colunas/tipos mantidos, campos permitemNULL; não substitui sexo/percurso/flags por X/0/false |
| Sexo fora de varchar(1) | Restrição na escrita | Preflight quantifica; carga aborta sem truncar nem inventar categoria |
| Dimensões | View pública faz INNER JOIN | Views do estudo usam os sete LEFT JOINs; IDs desconhecidos conservam as linhas |
| Guarda e recuperação | Recriação destrutiva | Novo nome, unicidade de resultado, PK própria, índice ID/evento/data, contratos52/36colunas, hashes e rollback dos adaptadores |

`id_fat_perfil_br_2026` é um identificador próprio da versão, determinístico por `id_resultado`. Não é chave para alinhar a versão à fato pública antiga: a conciliação deve usar `id_resultado`. Localidade/organizador/cronometrador usam0 porque esse fallback existe no script DBA; `id_data` ausente e retornoNULL de função permanecemNULL. Nenhum dos20 campos recebe defaults de flags.

O recibo lateral registra snapshot, horário real da carga, SHA do script, hashes das funções, definições anteriores, nove contagens mensais e qualidade. `loaded_at` é horário de carga, não uma afirmação de recoleta externa. O script não atualiza datas/fontes de células ou materiais.

## Limites e controles

A fato fica congelada no snapshot da carga. Os rótulos das dimensões e o complemento de resultados por `id_resultado` continuam vivos nas views, conforme o contrato existente; não se alega um snapshot permanente de todos os36/52 campos. Dentro da transação, contagens, IDs, valores e flagsNULL são comparados com a fonte materializada, e fanout/perda nas views abortam a operação. Alterações operacionais posteriores exigem nova revisão e fontes congeladas próprias.

Os guards não exigem localidade/organizador/cronometrador conhecidos. Duplicação de chave de dimensão que pudesse multiplicar linhas bloqueia. Ausências permanecem identificáveis. Não há alterações de funções, tabelas públicas, credenciais, permissões de origem, objetos comerciais ou namespace público. O único grant novo é SELECT dos objetos novos para o papel já existente `estudo_reader`.

Verificação offline: `python3 test_candidate.py`. A compilação/EXPLAIN PostgreSQL, preflight real e execução DataGrip pertencem ao controlador/DBA. Testes estáticos não equivalem à execução da carga.
