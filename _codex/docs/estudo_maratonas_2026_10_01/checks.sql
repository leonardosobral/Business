WITH fixture_eventos AS(
 SELECT n AS id_evento,'Prova '||n::text AS nome_evento,DATE '2026-09-26' AS data_final,'BR' AS pais,'rua' AS tipo_corrida,NULL::text AS ranking FROM generate_series(1,10)n
 UNION ALL SELECT 11,'Depois do corte',DATE '2026-09-27','BR','rua',NULL
 UNION ALL SELECT 12,'Outro país',DATE '2026-09-26','AR','rua',NULL
), tamanhos AS(SELECT column1 AS id_evento,column2 AS tamanho FROM(VALUES(1,1),(2,9),(3,10),(4,101),(5,200),(6,2),(7,2),(8,2),(9,2),(10,2))t),
fixture_resultados AS(
 SELECT t.id_evento,t.id_evento*1000+n AS id_resultado,CASE WHEN n%2=0 THEN 'F' ELSE 'M' END AS sexo,
 (TIME '02:10:00'+n*INTERVAL '1 minute')::time AS tempo_total,false AS pcd,
 CASE WHEN t.id_evento=3 THEN NULL WHEN t.id_evento=4 THEN '42K INDIVIDUAL' ELSE '42K GERAL' END::text AS modalidade,
 0 AS status_final,true AS homologado,true AS concluinte,42::numeric AS percurso
 FROM tamanhos t JOIN LATERAL generate_series(1,t.tamanho)n ON TRUE
 UNION ALL
 SELECT 2,200100,'M',TIME '01:20:00',false,'42K ACD',0,true,true,42
 UNION ALL SELECT 5,500100,'M',TIME '01:10:00',true,'42K',0,true,true,42
 UNION ALL SELECT 6,600100,'M',TIME '00:00:00',false,'42K',0,true,true,42
 UNION ALL SELECT 7,700100,'M',TIME '01:00:00',false,'42K',0,false,true,42
 UNION ALL SELECT 11,1100100,'M',TIME '01:00:00',false,'42K',0,true,true,42
 UNION ALL SELECT 12,1200100,'M',TIME '01:00:00',false,'42K',0,true,true,42
), candidatos AS (
 SELECT e.id_evento,e.nome_evento,e.data_final,r.id_resultado,r.sexo,r.tempo_total,r.pcd,r.modalidade
 FROM fixture_resultados r JOIN fixture_eventos e USING(id_evento)
 WHERE e.pais='BR' AND e.tipo_corrida='rua' AND (e.ranking IS NULL OR e.ranking<>'false')
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-09-27'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 AND r.percurso BETWEEN 42 AND 42.2 AND r.tempo_total>TIME '00:00:00'
), classificados AS (
 SELECT *,coalesce(modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))' AS modalidade_especial
 FROM candidatos
), base AS (
 SELECT * FROM classificados WHERE pcd IS FALSE AND NOT modalidade_especial
), totais AS (
 SELECT id_evento,nome_evento,data_final,count(*) AS concluintes,
 count(*) FILTER(WHERE sexo='F') AS feminino,count(*) FILTER(WHERE sexo='M') AS masculino,
 count(*) FILTER(WHERE sexo IS NULL OR sexo NOT IN('F','M')) AS outros_sexos,
 min(tempo_total)::text AS tempo_menor,
 to_char(round(avg(extract(epoch FROM tempo_total)))::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_medio,
 to_char(round((percentile_cont(.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)))::numeric)::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_mediano,
 count(*) FILTER(WHERE tempo_total<TIME '04:00:00') AS sub4,
 count(*) FILTER(WHERE tempo_total<TIME '03:00:00') AS sub3,
 count(*) FILTER(WHERE tempo_total<TIME '02:30:00') AS sub2h30,
 count(*) FILTER(WHERE tempo_total<TIME '02:00:00') AS suspeitos_sub2
 FROM base GROUP BY id_evento,nome_evento,data_final
), ranking AS (
 SELECT *,row_number() OVER(ORDER BY concluintes DESC,id_evento) AS posicao FROM totais
), top AS (SELECT * FROM ranking WHERE posicao<=10),
ordenados AS (
 SELECT b.*,row_number() OVER(PARTITION BY b.id_evento ORDER BY b.tempo_total,b.id_resultado) AS ordem,
 count(*) OVER(PARTITION BY b.id_evento) AS denominador FROM base b JOIN top t ON t.id_evento=b.id_evento
), cortes AS(SELECT column1 AS grupo,column2 AS absoluto,column3 AS proporcao FROM(VALUES
 ('top10',10,0::numeric),('top100',100,0::numeric),('top5pct',0,.05),('top10pct',0,.10),('top50pct',0,.50))t),
g AS(SELECT o.*,c.grupo,least(denominador,CASE WHEN c.proporcao>0 THEN ceil(denominador*c.proporcao) ELSE c.absoluto END) AS limite FROM ordenados o CROSS JOIN cortes c),
selecoes AS (
 SELECT id_evento,nome_evento,data_final,grupo,max(denominador) AS denominador,max(limite) AS selecionados,
 count(*) FILTER(WHERE ordem<=limite) AS incluidos,
 to_char(round(avg(extract(epoch FROM tempo_total)) FILTER(WHERE ordem<=limite))::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_medio,
 max(tempo_total) FILTER(WHERE ordem<=limite)::text AS tempo_limite
 FROM g GROUP BY id_evento,nome_evento,data_final,grupo
), empates AS (SELECT id_evento,tempo_total,count(*) AS empatados_no_limite FROM base GROUP BY id_evento,tempo_total),
auditoria AS (
 SELECT id_evento,nome_evento,count(*) AS candidatos,
 count(*) FILTER(WHERE pcd IS TRUE) AS flag_pcd,
 count(*) FILTER(WHERE pcd IS FALSE AND modalidade_especial) AS texto_com_flag_falsa,
 count(*) FILTER(WHERE pcd IS NULL) AS flag_ausente,
 count(*) FILTER(WHERE pcd IS FALSE AND NOT modalidade_especial) AS elegiveis
 FROM classificados GROUP BY id_evento,nome_evento
)
SELECT jsonb_build_object('ano',2026,'corte','2026-09-26','coletado_em',current_timestamp,
 'eventos', (SELECT count(*) FROM totais),'concluintes',(SELECT count(*) FROM base),
 'top10_soma',(SELECT sum(concluintes) FROM top),
 'top10',(SELECT jsonb_agg(to_jsonb(t) ORDER BY posicao) FROM top t),
 'grupos',(SELECT jsonb_agg(to_jsonb(s)||jsonb_build_object('empatados_no_limite',e.empatados_no_limite) ORDER BY s.id_evento,s.grupo) FROM selecoes s JOIN empates e ON e.id_evento=s.id_evento AND e.tempo_total::text=s.tempo_limite),
 'auditoria',(SELECT jsonb_agg(to_jsonb(a) ORDER BY id_evento) FROM auditoria a)) AS payload
