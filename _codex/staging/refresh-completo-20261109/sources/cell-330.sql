WITH entrada(id_evento,ano,url_resultado,url_wiclax,obs_resultado,esperado) AS(VALUES
(1,2025,'link','link','Cancelado','Com resultado coletado'),
(2,2025,'link','link','Kids','Sem coleta, com link'),
(3,2025,'  ','wiclax',NULL,'Sem coleta, com link'),
(4,2025,'  ','  ',NULL,'Sem resultado, link ou situação conhecida'),
(5,2025,NULL,NULL,NULL,'Sem resultado, link ou situação conhecida'),
(6,2025,NULL,NULL,' KIDS ','Sem coleta/link, situação conhecida'),
(7,2025,NULL,NULL,'Não encontrado','Sem resultado, link ou situação conhecida'),
(8,2025,NULL,NULL,'TF','Sem resultado, link ou situação conhecida'),
(9,2025,NULL,NULL,' Cancelado ','Sem coleta/link, situação conhecida'),
(10,2025,NULL,NULL,NULL,'Com resultado coletado')),
resultados(id_evento) AS(VALUES(1),(1),(10)),
calendario AS(
SELECT id_evento,ano,esperado,
coalesce(nullif(btrim(url_resultado),''),nullif(btrim(url_wiclax),'')) IS NOT NULL AS link,
lower(btrim(coalesce(obs_resultado,''))) IN('sem resultado','kids','treino','cancelado','adiado','repetido','adiado/cancelado') AS conhecida,
coalesce(obs_resultado,'') AS observacao FROM entrada),
classes AS(
 SELECT c.*,CASE WHEN EXISTS(SELECT 1 FROM resultados r WHERE r.id_evento=c.id_evento) THEN 'Com resultado coletado'
 WHEN c.link THEN 'Sem coleta, com link'
 WHEN c.conhecida THEN 'Sem coleta/link, situação conhecida'
 ELSE 'Sem resultado, link ou situação conhecida' END AS categoria
 FROM calendario c
), contagens AS(
 SELECT ano,categoria,count(*)::bigint AS n FROM classes GROUP BY ano,categoria
), totais AS(SELECT ano,count(*)::bigint AS base,count(*)FILTER(WHERE categoria<>'Sem resultado, link ou situação conhecida')::bigint AS mapeados FROM classes GROUP BY ano),
 categorias AS(SELECT column1 AS categoria FROM(VALUES('Com resultado coletado'),('Sem coleta, com link'),('Sem coleta/link, situação conhecida'),('Sem resultado, link ou situação conhecida'))t),
 linhas AS(
 SELECT t.ano,k.categoria,coalesce(c.n,0) AS contagem,t.base AS denominador,(coalesce(c.n,0)*100.0/t.base)::text AS valor
 FROM totais t CROSS JOIN categorias k LEFT JOIN contagens c ON c.ano=t.ano AND c.categoria=k.categoria
 UNION ALL SELECT ano,'Provas mapeadas',mapeados,base,(mapeados*100.0/base)::text FROM totais
), pendencias AS(SELECT ano,observacao,count(*)::bigint AS provas FROM classes WHERE categoria='Sem resultado, link ou situação conhecida' GROUP BY ano,observacao)
SELECT jsonb_build_object('testes_falhos',(SELECT count(*) FROM classes WHERE categoria<>esperado),'coletado_em',current_timestamp,'corte_2026','2026-09-26','regra','Cada ID uma vez. Resultado bruto; url_resultado/url_wiclax com trim; situação conhecida normalizada: Sem Resultado, Kids, Treino, Cancelado, Adiado, Repetido, Adiado/Cancelado. Não encontrado e códigos não interpretados continuam pendentes.',
'linhas',(SELECT jsonb_agg(to_jsonb(l) ORDER BY ano,categoria) FROM linhas l),
'pendencias',(SELECT jsonb_agg(to_jsonb(p) ORDER BY ano,provas DESC,observacao) FROM pendencias p)) AS payload;
