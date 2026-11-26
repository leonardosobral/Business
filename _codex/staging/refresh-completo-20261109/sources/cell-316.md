# Cobertura cadastral e corte 14+ — 01/10/2026

Consultas próprias no caderno único. Não substituem consultas do DBA, valores históricos, panorama ou comparativos já congelados.

## Fontes congeladas

| Fonte | Célula/revisão | Execução | Duração |
| --- | --- | --- | --- |
| Cobertura cadastral | 312/3 | 117 | 8,1 s |
| Idades de 2025 | 314/1 | 118 | 11,8 s |
| Idades de 2026 parcial | 315/1 | 119 | 11,2 s |
| Fixture de classificação | 313/1 | 116 | 23 casos aprovados |
| Saída web 2025 | 249/24 | 120 | apenas congelamentos |
| Saída web 2026 | 251/20 | 122 | apenas congelamentos |

## População e cobertura

Eventos BR pela data final, inclusive inativos: calendário de 2025 completo e até 26/09/2025; 2026 até 26/09. Todas as modalidades e rua/trail são recortes sobrepostos. Não somar recortes ou comparar 2025 completo com 2026 parcial como períodos iguais.

Coleta significa ao menos uma linha bruta, sem certificar captura completa. Com conclusão registrada exige status 0, homologado e concluinte=true. Razão coletadas/cadastradas mede somente o calendário conhecido do portal: não estima cobertura nacional e não substitui os 84,1% do PDF, cujo denominador histórico continua desconhecido. Cadastro não certifica realização.

Todas as modalidades, até 26/09: 2025 tem 5.575 cadastradas, 3.067 coletadas, 3.065 com conclusão, cobertura cadastral 55,0%; 2026 tem 7.588 cadastradas, 4.602 coletadas, 4.595 com conclusão, cobertura cadastral 60,6%. A coleta é nova; importações tardias e revisões podem alterar números em relação às outras páginas. Essa razão não mede crescimento real de participações.

## Conclusão e idade

A definição vigente de vw_resultados filtra status 0 e homologado, sem filtro de idade ou conclusão. Flags true/false/NULL são auditadas separadamente, sem converter ausência em true. Em 2025 completo: 5.279.220 = 5.279.212 + 8 + 0. Em 2026 parcial: 4.301.636 = 4.301.399 + 237 + 0.

Idade em 31/12 do ano da prova, regra confirmada. Nascimento não posterior à prova e idade 0–120 têm prioridade. Sem nascimento plausível, usa-se a faixa inteira da categoria. Uma faixa com limite inferior >=14 identifica o corte mínimo, mesmo ampla sem caber em um grupo de cinco anos. Faixa inteiramente abaixo de 14 é menor. Cruzando 14, faltante ou inválida conserva pendência. Faixas vazias, negativas, sem limite inferior, limite inferior >120 e superior finito >121 são inválidas. Plausibilidade não certifica o cadastro. Faixa aberta superior pode indicar mínimo 14+ sem afirmar idade exata.

Denominador etário: todas as participações com conclusão registrada do recorte, todas as modalidades. As cinco classes somam o total e 100%.

| Situação | 2025 completo | 2026 até 26/09 |
| --- | ---: | ---: |
| 14+ identificados | 4.330.048 | 3.846.948 |
| Menos de 14 | 9.676 | 9.419 |
| Faixa cruza 14 | 98.282 | 75.566 |
| Sem idade informada | 841.202 | 369.386 |
| Dado inválido | 4 | 80 |

Desconhecidos não entram automaticamente nos 14+ e não são estimados. Os 14+ identificados são subconjuntos conhecidos, não novos totais completos ou nacionais. Cada linha é uma participação, não uma pessoa. Ainda falta definição ou fonte para fechar a população 14+ dos registros pendentes. Esta auditoria não altera as distribuições etárias anteriores.

## Conferência e desempenho

Seis recortes reconciliam contagens de idade com cobertura: soma de flags = view; soma da idade com conclusão=true = concluintes; com conclusão <= com view <= coletadas <= cadastradas. Os 23 casos sintéticos incluem limites 13/14/120/121, prioridade nascimento/faixa, negativos, vazios, abertos e ambiguidades.

Consulta conjunta 312 rev1/2 excedeu 45 s, sem congelamento ou publicação. Separação por ano e pré-agregação antes da classificação resolveu em 8/12/11 s. Nenhuma proteção, timeout, role ou autenticação foi ampliada. As revisões rejeitadas das saídas permanecem no histórico. Migrações rejeitadas pelo contrato fizeram ROLLBACK. Contratos novos acrescentam tipos e campos necessários sem alterar validador genérico, baselines ou publicações anteriores.

Todos os indicadores preexistentes, totais, coortes e valores publicados no PDF de 2025 foram preservados. Novas definições têm valores históricos NULL; a opção PDF não mostra esta auditoria. A interface aceita pacotes anteriores para recuperação. Visitas leem congelamentos e não executam consultas de coleta.
