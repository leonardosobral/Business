-- Mapeamento real por ID: categorias mutuamente exclusivas, incluindo resumos zerados.
-- Mesma população ativa BR/UF do Stats; 2025 completo e corte web 2026 em30/09.
-- Qualquer resultado bruto demonstra coleta, não completude/conclusão elegível.
-- Links: ambos os campos, após trim. Observações livres não demonstram mapeamento.
WITH calendario AS MATERIALIZED(
 SELECT e.id_evento,extract(year FROM e.data_final)::integer AS ano,
 coalesce(nullif(btrim(e.url_resultado),''),nullif(btrim(e.url_wiclax),'')) IS NOT NULL AS link,
 lower(btrim(coalesce(e.obs_resultado,''))) IN('sem resultado','kids','treino','cancelado','adiado','repetido','adiado/cancelado') AS conhecida,
 coalesce(e.obs_resultado,'') AS observacao
 FROM public.tb_evento_corridas e
 WHERE e.ativo IS TRUE AND e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-10-01'
 AND EXISTS(SELECT 1 FROM public.tb_uf uf WHERE uf.uf=e.estado)
), classes AS(
 SELECT c.*,CASE WHEN EXISTS(SELECT 1 FROM public.tb_resultados r WHERE r.id_evento=c.id_evento) THEN 'Com resultado coletado'
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
SELECT jsonb_build_object('coletado_em',current_timestamp,'corte_2026','2026-09-30','regra','Cada ID uma vez. Resultado bruto; url_resultado/url_wiclax com trim; situação conhecida normalizada: Sem Resultado, Kids, Treino, Cancelado, Adiado, Repetido, Adiado/Cancelado. Não encontrado e códigos não interpretados continuam pendentes.',
'linhas',(SELECT jsonb_agg(to_jsonb(l) ORDER BY ano,categoria) FROM linhas l),
'pendencias',(SELECT jsonb_agg(to_jsonb(p) ORDER BY ano,provas DESC,observacao) FROM pendencias p)) AS payload;
