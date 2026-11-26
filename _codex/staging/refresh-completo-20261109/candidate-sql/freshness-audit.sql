-- Renovação completa solicitada em09/11/2026. Somente auditoria, sem carga de BI.
-- Mesma elegibilidade do panorama: BR, 01/01 a30/09/2026, status0,
-- homologado=true e concluinte=true. Todas as idades e modalidades no total.
-- O notebook executa em transação somente leitura/repeatable read.
WITH elegiveis AS MATERIALIZED (
 SELECT r.id_resultado,r.id_evento,e.data_final
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2026-01-01'
 AND e.data_final<DATE '2026-10-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
), comparados AS MATERIALIZED (
 SELECT r.id_resultado AS raw_id,f.id_resultado AS bi_id,
 r.id_evento AS raw_evento,f.id_evento AS bi_evento,
 r.data_final AS raw_data,f.data_evento AS bi_data
 FROM elegiveis r FULL JOIN public.tbbi_fat_perfil_br_2026 f
 ON f.id_resultado=r.id_resultado
)
SELECT current_timestamp AS coletado_em,
 DATE '2026-01-01' AS inicio,DATE '2026-10-01' AS fim_exclusivo,
 count(raw_id) AS operacional_linhas,count(DISTINCT raw_id) AS operacional_ids,
 count(bi_id) AS bi_linhas,count(DISTINCT bi_id) AS bi_ids,
 count(DISTINCT raw_evento) AS operacional_eventos,
 count(DISTINCT bi_evento) AS bi_eventos,
 count(*) FILTER(WHERE raw_id IS NOT NULL AND bi_id IS NOT NULL) AS ids_comuns,
 count(*) FILTER(WHERE raw_id IS NOT NULL AND bi_id IS NULL) AS novos_no_operacional,
 count(*) FILTER(WHERE raw_id IS NULL AND bi_id IS NOT NULL) AS bi_fora_elegibilidade_atual,
 count(*) FILTER(WHERE raw_id IS NOT NULL AND bi_id IS NOT NULL
 AND raw_evento IS DISTINCT FROM bi_evento) AS evento_divergente,
 count(*) FILTER(WHERE raw_id IS NOT NULL AND bi_id IS NOT NULL
 AND raw_data IS DISTINCT FROM bi_data) AS data_divergente
FROM comparados
