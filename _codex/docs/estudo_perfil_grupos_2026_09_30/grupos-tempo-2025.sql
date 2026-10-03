-- P13: média dos menores tempos, em uma única população de concluintes.
-- Nova regra explícita; não reproduz a classificação cadastrada legada.
-- Top10/100 seleciona no máximo 10/100 resultados; grupos % usam ceil(n*p) de concluintes.
-- Empates no tempo são desempatados por id_resultado para um tamanho determinístico.
-- Janela anual; seleção histórica fixa das dez provas para permitir conciliação.
-- PCD=false também exige ausência das palavras de modalidade excluídas nos SQLs recebidos.
-- Não altera cadastros. A consulta é uma candidata metodológica, não o snapshot do PDF.
WITH parametros AS (
 SELECT DATE '2025-01-01' AS inicio,DATE '2026-01-01' AS fim_exclusivo
), base AS (
 SELECT e.id_evento,e.nome_evento,r.id_resultado,r.sexo,r.tempo_total
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 CROSS JOIN parametros p
 WHERE e.id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
 AND e.data_final>=p.inicio AND e.data_final<p.fim_exclusivo
 AND e.pais='BR' AND e.tipo_corrida='rua' AND (e.ranking IS NULL OR e.ranking<>'false')
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 AND r.percurso BETWEEN 42 AND 42.2 AND r.pcd IS FALSE AND r.tempo_total>TIME '00:00:00'
 AND r.modalidade NOT ILIKE '%CADEIRANTE%' AND r.modalidade NOT ILIKE '%PCD%'
 AND r.modalidade NOT ILIKE '%DI%' AND r.modalidade NOT ILIKE '%DMAI%'
 AND r.modalidade NOT ILIKE '%DMS%' AND r.modalidade NOT ILIKE '%HAND%'
 AND r.modalidade NOT ILIKE '%BIKE%' AND r.modalidade NOT ILIKE '%ACD%'
), ordenados AS (
 SELECT *,row_number() OVER(PARTITION BY id_evento ORDER BY tempo_total,id_resultado) AS ordem,
 count(*) OVER(PARTITION BY id_evento) AS denominador FROM base
), cortes AS (SELECT column1 AS grupo,column2 AS absoluto,column3 AS proporcao FROM (VALUES('top10',10,0::numeric),('top100',100,0::numeric),('top5pct',0,.05),('top10pct',0,.10),('top50pct',0,.50)) t),
g AS (SELECT o.*,c.grupo,least(denominador,CASE WHEN c.proporcao>0 THEN ceil(denominador*c.proporcao) ELSE c.absoluto END) AS limite FROM ordenados o CROSS JOIN cortes c)
 , selecoes AS (SELECT id_evento,nome_evento,grupo,max(denominador) AS denominador,max(limite) AS selecionados,
 count(*) FILTER(WHERE ordem<=limite) AS incluidos,
 to_char(round(avg(extract(epoch FROM tempo_total)) FILTER(WHERE ordem<=limite))::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_medio,
 min(tempo_total)::text AS tempo_minimo,
 max(tempo_total) FILTER(WHERE ordem<=limite)::text AS tempo_limite
FROM g GROUP BY id_evento,nome_evento,grupo),
empates AS (SELECT id_evento,tempo_total,count(*) AS empatados_no_limite FROM base GROUP BY id_evento,tempo_total)
SELECT s.*,e.empatados_no_limite FROM selecoes s JOIN empates e ON e.id_evento=s.id_evento AND e.tempo_total::text=s.tempo_limite
ORDER BY s.id_evento,s.grupo
