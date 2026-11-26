## P13 — Maratonas rápidas e pódio

**Editor:** [Provas Rápidas](https://business.roadrunners.run/estudo/?caderno=1&secao=11); [Headline performance](https://business.roadrunners.run/estudo/?caderno=1&secao=13) traz resumos por sexo e destaques gerais; não reconstitui sozinho o quadro de medalhas.

**DataGrip:** os blocos longos de maratonas usam seleção fixa, exclusões por texto, limites por evento e percentis; não equivalem ao primeiro ranking. Há diferenças entre menor tempo, média, mediana e grupos percentuais. “Sub” no quadro desta página é estritamente menor, enquanto outros blocos usam <=.

**Decisão:** preservar os dez IDs como referência identificada e recalcular os limites <4h/<3h/<2h30 na população do primeiro bloco, deixando essa derivação explícita. A classificação de pódio e a tabela top10/top100/5%/10%/50% ainda exigem conciliar o SQL extenso, não foram reconstruídas por aproximação.