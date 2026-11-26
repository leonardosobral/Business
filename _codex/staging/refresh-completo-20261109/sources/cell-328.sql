-- Auditoria dos campos de link ignorados pela barra original. Não altera sua fórmula.
-- Mesma base/fórmula de RunnerHub admin/stats_obs.cfm, sem filtros opcionais.
-- 2025 completo e 2026 até o corte vigente da web (26/09); coleta própria.
WITH periodos(ano,inicio,fim_exclusivo) AS (
 VALUES (2025,DATE '2025-01-01',DATE '2026-01-01'),
        (2026,DATE '2026-01-01',DATE '2026-09-27')
), eventos AS MATERIALIZED (
 SELECT p.ano,e.id_evento,e.url_resultado,e.url_wiclax,e.obs_resultado
 FROM public.tb_evento_corridas e JOIN periodos p
   ON e.data_final>=p.inicio AND e.data_final<p.fim_exclusivo
 JOIN public.tb_uf uf ON uf.uf=e.estado
 WHERE e.ativo IS TRUE AND e.pais='BR'
), resumo AS MATERIALIZED (
 SELECT r.id_evento,sum(r.concluintes) AS concluintes
 FROM public.tb_resultados_resumo_2025 r
 WHERE r.sexo IS NULL AND EXISTS(SELECT 1 FROM eventos e WHERE e.id_evento=r.id_evento)
 GROUP BY r.id_evento
), base AS (
 SELECT e.*,r.concluintes FROM eventos e LEFT JOIN resumo r USING(id_evento)
), contagens AS (
 SELECT ano,count(*) AS ativos_com_uf,
 count(*) FILTER(WHERE concluintes>0) AS verde,
 count(*) FILTER(WHERE concluintes IS NULL) AS sem_concluintes,
 count(*) FILTER(WHERE concluintes IS NULL AND url_resultado IS NOT NULL AND url_resultado<>'') AS azul,
 count(*) FILTER(WHERE concluintes IS NULL AND obs_resultado IN ('Sem Resultado','Kids','Treino','Cancelado','Adiado','Repetido')) AS vermelho,
 count(*) FILTER(WHERE concluintes IS NULL AND url_resultado IS NOT NULL AND url_resultado<>'' AND obs_resultado IN ('Sem Resultado','Kids','Treino','Cancelado','Adiado','Repetido')) AS sobreposicao_azul_vermelho,
 count(*) FILTER(WHERE concluintes IS NOT NULL AND concluintes<=0) AS fora_barra_zero_ou_negativo
 FROM base GROUP BY ano
), calculo AS (
 SELECT *,verde+sem_concluintes AS denominador,
 verde+azul+vermelho AS mapeados_formula,
 verde+azul+vermelho-sobreposicao_azul_vermelho AS mapeados_distintos
 FROM contagens
)
SELECT b.ano,
count(*) FILTER(WHERE b.concluintes IS NULL AND (b.url_resultado IS NULL OR b.url_resultado='') AND coalesce(b.obs_resultado,'') NOT IN ('Sem Resultado','Kids','Treino','Cancelado','Adiado','Repetido')) AS cinza_distinto,
count(*) FILTER(WHERE b.concluintes IS NULL AND (b.url_resultado IS NULL OR b.url_resultado='') AND coalesce(b.obs_resultado,'') NOT IN ('Sem Resultado','Kids','Treino','Cancelado','Adiado','Repetido') AND coalesce(trim(b.url_wiclax),'')<>'') AS cinza_com_link_wiclax,
count(*) FILTER(WHERE b.concluintes IS NULL AND b.url_resultado<>'' AND trim(b.url_resultado)='') AS link_resultado_so_espacos,
count(*) FILTER(WHERE b.concluintes IS NULL AND (b.url_resultado IS NULL OR b.url_resultado='') AND coalesce(b.obs_resultado,'') NOT IN ('Sem Resultado','Kids','Treino','Cancelado','Adiado','Repetido') AND coalesce(trim(b.obs_resultado),'')<>'') AS cinza_com_outra_observacao
FROM base b GROUP BY b.ano ORDER BY b.ano