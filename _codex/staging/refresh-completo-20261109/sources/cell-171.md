## P06 — Distâncias e participação por sexo

**Editor:** [Modalidade](https://business.roadrunners.run/estudo/?caderno=1&secao=4); [Distâncias](https://business.roadrunners.run/estudo/?caderno=1&secao=5); [Headline distâncias](https://business.roadrunners.run/estudo/?caderno=1&secao=6). Uma consulta está intitulada RUA, mas filtra trail; o agrupamento padrão de rua usa valores exatos de percurso e tb_resultados.

**DataGrip/DBA:** seis blocos de distâncias são iguais após retirar comentários/espaços; usam vw_resultados. DataGrip também traz recortes adicionais por sexo/UF/geração. Não confundir count(distinct evento) somado por faixa com total de eventos únicos: uma prova pode oferecer várias distâncias.

**Decisão:** conservar a diferença entre detalhe (floor), faixas e distâncias padrão. O diagnóstico de presença de 5 km usa um denominador de eventos únicos explícito.