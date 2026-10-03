-- Maratonas 2026: população revisada e seleção dinâmica das dez maiores.
-- Corte de eventos até 26/09 preservado; coleta própria identificada.
-- Modalidade PCD no texto não é corrida convencional mesmo com flag falsa.
-- Não altera o cadastro nem elimina tempos suspeitos: quantidade sub2h sinaliza revisão.
WITH candidatos AS (
 SELECT e.id_evento,e.nome_evento,e.data_final,r.id_resultado,r.sexo,r.tempo_total,r.pcd,r.modalidade
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
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
