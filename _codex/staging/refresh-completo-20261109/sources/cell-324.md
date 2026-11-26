## Fontes iniciais e rastreabilidade2026 — 01/10/2026

A web usa o pacote congelado da célula251/rev21, execução126, publicação25/v12. 2025 permanece na publicação23/v13 (#120). A auditoria323/rev3 (#125) recuperou fontes para448 valores e dois totais;222 fontes existentes foram preservadas. Todos os valores, contagens, denominadores, cortes e coortes anteriores permanecem idênticos no PostgreSQL.

### Consultas iniciais preservadas neste caderno

| Consulta | Célula/revisão | Recibo histórico | Uso vigente |
|---|---|---|---|
| 12 | 317/rev1 | 2026-09-26T23:35:44.446141-03:00 | Total de eventos cadastrados no panorama |
| 13 | 318/rev1 | 2026-09-26T23:37:25.233531-03:00 | Gêneros, distâncias, regiões/UFs e calendário; base das derivações42/61/75/97 |
| 14 | 319/rev1 | 2026-09-26T23:38:42.685667-03:00 | 2025 no mesmo corte para o comparativo inicial |
| 15 | 320/rev1 | 2026-09-26T23:39:42.649205-03:00 | Performance e CNA iniciais2026 |
| 16 | 321/rev1 | 2026-09-26T23:39:53.407883-03:00 | Evidência da regra inicial de maratonas; substituída por309/rev1 (#111) |
| 20 | 322/rev1 | 2026-09-27T09:21:10.707659-03:00 | Provas cadastradas e com resultados coletados, por mês e no Jan–Ago |

Os textos entre QUERY_START/QUERY_END foram importados sem alteração: SHA-256 iguais aos recibos e ao snapshot históricov3. Foram registrados agora, sem simular uma execução de2026-09-26 e sem rodar as consultas pesadas novamente. Executá-las futuramente lê a base então vigente e pode produzir outros números. Antes de editar, ler a revisão existente e comparar; nunca substituir automaticamente os ajustes do DBA.

### Fontes posteriores têm sua própria população

Capital/interior:267/rev2 (#52); cidades:288/rev2 (#77); atividades:280/rev1 (#65), derivação284/rev1 (#71); idades, gerações e cruzamentos:297/rev1 (#90); regiões por gênero:287/rev1 (#75); estações:300/rev1 (#97). As derivações mantêm a data de coleta dos resultados de origem; não renovam automaticamente o panorama.

### Conferência e publicação

Os JSONs congelados foram lidos como texto nativo. Percentuais numéricos e strings conservaram cada casa decimal e o tipoJSON; o manifesto usa esperado_texto, validado comoJSONB antes da saída. Hashes dos recibos são ancorados no snapshot preservado, não recalculados como referência. Auditorias123/124 são preparatórias; apenas125 alimenta126. O contrato8 permite as duas fontes de totais e conserva definições/categorias e contratos anteriores.

As funções puras e sintaxes de CTE/agrupamento usadas nos SQLs iniciais agora passam pelo validador.16 casosCF incluíram escrita e funções arbitrárias rejeitadas; o executor mantém transação de leitura e limites de execução.

Pendências analíticas permanecem: denominador nacional84,1% do PDF, tratamento final de idades incertas/14+, tempos de Floripa, referências históricasP03/P09 e diferenças metodológicas/editoriais. Fontes identificadas não tornam a população atual uma reprodução certificada doPDF.
