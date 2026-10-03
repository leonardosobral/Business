-- P13: reprodução da regra encontrada em INFOGRAFICO_MARATONAS.sql, segundo bloco geral.
-- Classificações cadastradas, não uma ordenação nova por tempo.
-- Denominador dos grupos percentuais: todos os inscritos após filtro textual, por evento/percurso.
-- Preserva a ausência de filtro pcd booleano e o intervalo 42–42,99 do original.
-- Médias convertidas para segundos e arredondadas ao segundo mais próximo.
WITH base AS (
 SELECT r.id_evento,e.nome_evento,r.percurso,r.tempo_total,r.classificacao_total,
 r.homologado,r.concluinte,r.status_final
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.id_evento IN(24999,24998,26867,22792,22582,27104,28253,22590,25481,24016)
 AND r.percurso BETWEEN 42 AND 42.99
 AND r.modalidade NOT ILIKE '%CADEIRANTE%' AND r.modalidade NOT ILIKE '%PCD%'
 AND r.modalidade NOT ILIKE '%DI%' AND r.modalidade NOT ILIKE '%DMAI%'
 AND r.modalidade NOT ILIKE '%DMS%' AND r.modalidade NOT ILIKE '%HAND%'
 AND r.modalidade NOT ILIKE '%BIKE%' AND r.modalidade NOT ILIKE '%ACD%'
), universo AS (
 SELECT *,count(*) OVER(PARTITION BY id_evento,percurso) AS inscritos FROM base
), elegiveis AS (
 SELECT * FROM universo WHERE homologado IS TRUE AND concluinte IS TRUE AND status_final=0 AND tempo_total IS NOT NULL
), cortes AS (
 SELECT column1 AS grupo,column2 AS absoluto,column3 AS proporcao FROM (VALUES('top10',10,0::numeric),('top100',100,0::numeric),('top5pct',0,.05),('top10pct',0,.10),('top50pct',0,.50)) t
), grupos AS (
 SELECT e.*,g.grupo,CASE WHEN g.proporcao>0 THEN inscritos*g.proporcao ELSE g.absoluto END AS limite FROM elegiveis e CROSS JOIN cortes g
)
SELECT id_evento,nome_evento,percurso,grupo,max(inscritos) AS inscritos,max(limite) AS limite_classificacao,
 count(*) AS concluintes_com_tempo,
 count(*) FILTER(WHERE classificacao_total<=limite) AS incluidos,
 count(DISTINCT classificacao_total) FILTER(WHERE classificacao_total<=limite) AS posicoes_distintas,
 count(*) FILTER(WHERE classificacao_total IS NULL OR classificacao_total<=0) AS classificacao_ausente_ou_invalida,
 count(*) FILTER(WHERE tempo_total=TIME '00:00:00') AS tempos_zero,
 to_char(round(avg(extract(epoch FROM tempo_total)) FILTER(WHERE classificacao_total<=limite))::double precision*INTERVAL '1 second','HH24:MI:SS') AS tempo_medio
FROM grupos GROUP BY id_evento,nome_evento,percurso,grupo ORDER BY id_evento,percurso,grupo
