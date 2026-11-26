## P12 — Top maratonas e tempos

**Editor:** [Provas Rápidas](https://business.roadrunners.run/estudo/?caderno=1&secao=11) usa tb_resultados_resumo_2025, evento homologado, ranking='true', data inicial e exclusões por texto de modalidade. HTML 77 está vazio.

**DataGrip:** INFOGRAFICO_MARATONAS: primeiro bloco usa vw_resultados, PCD=false, rua, data final e 42–42,2 km; outros blocos usam dez IDs fixos, limites e filtros distintos. Há também UPDATE de pace, mantido apenas como fonte, sem execução.

**DBA:** estudo_treinos tem explorações de maratonas femininas, não a regra completa deste ranking.

**Decisão:** o candidato abaixo usa o primeiro bloco DataGrip e mostra tanto o top 10 recalculado quanto a seleção de IDs legada. Resultados com tempo zero/nulo são contados explicitamente. Isso não resolve sozinho a regra de média/mediana/pódio do PDF.