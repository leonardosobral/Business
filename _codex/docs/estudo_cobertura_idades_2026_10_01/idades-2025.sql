-- P02/P03 — elegibilidade 14+ na população com status0/homologação; não altera totais.
-- Pré-agregação antes de interpretar faixas; nascimento em31/12 tem prioridade.
WITH entradas AS(
 SELECT r.sexo,r.idade_range,r.concluinte,e.tipo_corrida,e.data_final<DATE '2025-09-27' AS ate26set,
 2025-extract(year FROM r.data_nascimento)::integer AS idade_31dez,
 coalesce(r.data_nascimento<=e.data_final AND 2025-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120,false) AS nascimento_plausivel
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-01-01'
 AND r.status_final=0 AND r.homologado IS TRUE
), base AS(
 SELECT coalesce(sexo,'N/A') AS sexo,idade_range,concluinte,tipo_corrida,ate26set,idade_31dez,nascimento_plausivel,count(*) AS n
 FROM entradas GROUP BY sexo,idade_range,concluinte,tipo_corrida,ate26set,idade_31dez,nascimento_plausivel
),
normalizados AS (
 SELECT *,CASE WHEN nascimento_plausivel THEN int4range(idade_31dez,idade_31dez+1,'[)')
 WHEN idade_range IS NOT NULL AND idade_range<>'empty'::int4range AND lower(idade_range)>=0 AND lower(idade_range)<=120 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN idade_range END AS faixa,
 CASE WHEN nascimento_plausivel THEN 'Nascimento plausível'
 WHEN idade_range IS NULL THEN 'Sem idade informada'
 WHEN idade_range<>'empty'::int4range AND lower(idade_range)>=0 AND lower(idade_range)<=120 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN 'Faixa da categoria'
 ELSE 'Dado inválido' END AS origem
 FROM base
), classificados AS (
 SELECT *,CASE WHEN faixa IS NULL THEN CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Dado inválido' END
 WHEN faixa<@int4range(0,14,'[)') THEN 'Menos de 14'
 WHEN lower(faixa)>=14 THEN '14+ identificados'
 ELSE 'Faixa cruza 14' END AS corte14
 FROM normalizados
),periodos AS(SELECT '2025 · ano completo' AS escopo,true AS completo UNION ALL SELECT '2025 · até 26/09',false), universos AS(SELECT 'Todas as modalidades' AS universo UNION ALL SELECT 'Rua/trail'),
idades AS(
 SELECT p.escopo,2025 AS ano,u.universo,
 CASE WHEN c.concluinte IS TRUE THEN 'Conclusão registrada' WHEN c.concluinte IS FALSE THEN 'Conclusão falsa' ELSE 'Conclusão desconhecida' END AS conclusao,
 c.corte14,c.origem,c.sexo,sum(c.n)::bigint AS n
 FROM classificados c CROSS JOIN periodos p CROSS JOIN universos u
 WHERE (p.completo OR c.ate26set) AND (u.universo='Todas as modalidades' OR c.tipo_corrida IN('rua','trail'))
 GROUP BY p.escopo,u.universo,c.concluinte,c.corte14,c.origem,c.sexo
)
SELECT jsonb_build_object('ano',2025,'coletado_em',current_timestamp,'idades',(SELECT jsonb_agg(to_jsonb(i) ORDER BY escopo,universo,conclusao,corte14,origem,sexo) FROM idades i)) AS payload;
