# Estudo 2025 — conciliação por página

Publicado em 28/09/2026 no Business, somente para admins:
https://business.roadrunners.run/estudo/?caderno=4&secao=37

## Entrega

Caderno **2025 — Reprodução por página do PDF**, com 15 seções, 93 células (24 SQL e 69 Markdown), 23 pares de fontes comparados e referências às 83 séries transcritas do PDF v3.10.3. Páginas analíticas 3–15, mais guia e apoio. Os dois cadernos anteriores, suas 30 seções e 73 células estão integralmente preservados.

Todas as 24 consultas foram executadas pelo notebook na sessão admin autenticada, sem consultar dados pessoais individuais. Os resultados estão congelados, completos e vinculados ao SQL/revisão/data. O novo caderno não contém HTML; a tabela de execução substitui a colagem manual. O acervo HTML antigo continua como evidência histórica.

Não houve alteração de runtime nesta etapa, nem do contrato/API do notebook. Foram acrescentados registros em `estudo.cadernos`, `estudo.notebooks` e `estudo.notebook_cells`; o mecanismo existente gerou revisões e execuções. Não foram alteradas tabelas operacionais de corridas/resultados, funções, permissões ou dados do estudo público. Os quatro snapshots do estudo web conservaram seus hashes.

## Proveniência e limites

O responsável informou que `vw_resultados` foi criada depois, tratada e provavelmente usada na publicação. Ela é a candidata prioritária. A definição atual inspecionada é uma view comum sobre `tb_resultados`, filtrando `status_final=0 AND homologado=true`; não fornece por si só uma cópia temporal da base. Os congelamentos desta etapa registram o recálculo atual de 2025, não recuperam o estado histórico usado no PDF atualizado em 09/03/2026.

Fontes: 8 SQLs originais do DataGrip conferidos por SHA-256 contra o acervo; pacote do DBA; 14 seções/43 células do editor recuperado; PDF e transcrição de referência no RoadRunners. Seis blocos de distância do DBA são iguais aos DataGrip após retirar comentários/espaços; quatro blocos de performance diferem pelo filtro de sexo. A comparação preserva literais e usa pares explícitos. O gerador armazena as diferenças textuais em `comparison`.

## Primeiras evidências e pendências

- P03: view = 5.279.415, bruto = 5.599.435. Mulheres no DataGrip com tempo positivo = 52,85%, compatível com 52,9% publicado. Cadastros 2024/2025 = 6.167/9.360; eventos com ao menos um resultado tratado = 3.214/5.121. A cobertura de 84,1% ainda precisa de denominador.
- P04: rótulo SQL 13–19 vs PDF 14–19. Sobreposição de `idade_range` produz 6.620.729 atribuições a faixas para a população tratada, não uma partição exclusiva das 5.279.415 participações. A regra foi preservada e sinalizada.
- P05: SQLs históricos são 2023 geral, 2024 M, 2025 F. Os cinco percentuais de 2024 M coincidem com o quadro masculino publicado. Não comparar os três blocos como uma série geral. BI usa outra classificação.
- P06: quatro faixas gerais coincidem (59,1/28,4/11,1/1,4). Presença de 5 km = 74,53% vs 74,6%. No candidato por sexo foi corrigido explicitamente o denominador para ser dentro de cada sexo; não apresentar como SQL original.
- P07: classificação atual expandida da função `get_id_geracao`, sem conceder execução de função adicional. Geração zero excluída conforme fonte. Há diferenças em 30+ km.
- P08: faixas gerais do DBA coincidem para 10/21/42 km. Preservados limites e filtros das fontes. DataGrip fornece 5k F e 10/21/42k M; recortes complementares ainda precisam de derivação identificada.
- P09/P10: manter direção do denominador (regiões dentro do sexo vs sexos dentro da região). Cidades usam UF, mas BRASÍLIA/DF e BRASILIA/DF permanecem separadas por acento. Alternativa BI usa `id_localidade` e preserva 125.710 não classificados, sem descartá-los.
- P11: 12 meses e 4 trimestres recalculados com denominador anual. Novembro = 13,21% vs 13,4% publicado. Regra de estações não localizada.
- P12/P13: sete contagens de maratonas coincidem; SP City +6, São Paulo +18, Curitiba +28; total 43.414 vs 43.362. Menor tempo de Curitiba 01:56:00 vs 02:15:13 sinalizado para revisão, sem alteração da base. Pódio e médias Top10/Top100/5%/10%/50% ainda não reconciliados.
- P14: CNA separado da performance, pois filtros e fronteiras são diferentes.
- P15: a consulta mede atividades, não usuários. Mapeamento de rótulos e dez cartões de perfil pendentes. Personas individuais não promovidas a amostra nacional.

Cada página tem uma nota com os achados e IDs dos resultados congelados. Não foi calculado um percentual global de “reprodução do PDF”: coincidência numérica isolada não prova identidade de população, critérios ou momento da base.

## Execuções

| Página | Células SQL | Execuções congeladas |
|---|---|---|
| 3 | 155, 157, 159 | 6, 7, 8 |
| 4 | 163 revisão 2 | 10 |
| 5 | 167 revisão 2; 169 | 11, 12 |
| 6 | 173, 175, 177, 179, 181 | 13–17 |
| 7 | 185 | 18 |
| 8 | 189, 191 | 19, 20 |
| 9 | 195 | 21 |
| 10 | 199, 201, 203 | 22–24 |
| 11 | 207 | 25 |
| 12 | 211 | 26 |
| 13 | 215 | 27 |
| 14 | 219 | 28 |
| 15 | 223 | 29 |
| Apoio | 227 | 30 |

Execução #9: timeout de 45s na revisão 1 de idades, mantido no histórico. As duas consultas de ranges foram otimizadas por pré-agregação, preservando faixas e populações; a nota de idades também recebeu revisão 2. A nova consulta de idade terminou em 10,087s. Nenhuma saída foi truncada.

## Validação e publicação

- PostgreSQL local descartável: importação aditiva, repetição sem duplicação, detecção de conteúdo concorrente do DBA e preservação de células existentes.
- Teste de equivalência entre SQL original/otimizado para idades e gerações: intervalos sobrepostos, vazios, ausentes, múltiplos sexos, anos, país e homologação/status.
- Sequência importação → otimização → notas validada: 93 células; notas idempotentes; acervo anterior intacto.
- 24 SQLs passaram `SqlReadGuard` e compilação `LIMIT 0` em produção sob `estudo_reader`, transação somente leitura.
- 24 execuções completas/congeladas verificadas por hash e revisão. 93 hashes de conteúdo em produção iguais ao manifesto final.
- Comparação integral com backup: 2 livros, 30 seções e 73 células anteriores idênticos. Quatro snapshots públicos idênticos.
- Validação da interface autenticada no Chrome, incluindo carregamento das notas e leitura dos congelamentos.

Backup privado: `/var/backups/business-estudo-paginas-20260928/before.json`. A primeira tentativa de importação encontrou divergência CRLF no corpo da função e reverteu a transação inteira; normalizado LF, a importação seguinte concluiu. Gaps de IDs são esperados.

SQLs aplicados, em ordem:
1. `_codex/sql/2026-09-28_estudo_paginas.sql` — criação aditiva original.
2. `_codex/sql/2026-09-28_estudo_paginas_otimizacao.sql` — três revisões com verificação de versão/hash.
3. `_codex/sql/2026-09-28_estudo_paginas_notas.sql` — quinze notas da coleta.

Não reaplicar a migração inicial depois que o DBA editar uma célula: ela detecta diferenças e aborta. A otimização é uma migração única, exige revisão 1 e hash original. Importações futuras devem gerar novas revisões com controle de concorrência, sem substituir congelamentos.

Os scripts `estudo_pages_*` apenas geram/revisam artefatos quando chamados; `estudo_pages_operator.py` realiza a operação explícita selecionada (`inspect`, `check`, `catalogue`, `preservation`, `import arquivo.sql`). Usa o mecanismo privado de deploy já existente, POST loopback com token temporário e remoção do bridge em `finally`. Não expõe endpoint público adicional. O modo `import` guarda cada SQL aplicado por nome no backup privado.

Artefatos em `_codex/staging/estudo-paginas/`: baseline v1, candidato otimizado, manifesto final, catálogo das execuções, comparação de preservação, verificações e imagem da interface. Geradores e testes ficam em `_codex/scripts/` e `_codex/tests/`. Uma reversão deve preservar os congelamentos e considerar as edições posteriores do DBA; não restaurar o backup por cima delas nem excluir o histórico.

Próxima integração, fora desta etapa: definir quais resultados aprovados serão consumidos pelo estudo web, com ID de congelamento explícito e contrato de série/denominador.
