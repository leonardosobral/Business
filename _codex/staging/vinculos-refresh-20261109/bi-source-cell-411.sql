-- Auditoria agregada: não retorna nomes, documentos ou nascimentos individuais.
WITH linhas AS (
 SELECT f.id_resultado,f.id_evento,f.idade_range AS faixa_bi,f.data_evento,
 r.id_resultado AS resultado_operacional,r.id_evento AS evento_operacional,
 r.idade_range AS faixa_operacional,r.status_final,r.homologado,r.concluinte,
 e.pais,e.data_final,
 coalesce(r.data_nascimento<=e.data_final
  AND 2026-extract(year FROM r.data_nascimento)::integer BETWEEN 0 AND 120,false) AS nascimento_plausivel
 FROM public.tbbi_fat_perfil_br_2026 f
 LEFT JOIN public.tb_resultados r ON r.id_resultado=f.id_resultado
 LEFT JOIN public.tb_evento_corridas e ON e.id_evento=f.id_evento
), contagens AS (
 SELECT count(*) AS linhas,
 count(*) FILTER(WHERE resultado_operacional IS NULL) AS sem_resultado_operacional,
 count(*) FILTER(WHERE evento_operacional IS DISTINCT FROM id_evento) AS evento_divergente,
 count(*) FILTER(WHERE faixa_bi IS DISTINCT FROM faixa_operacional) AS ranges_divergentes,
 count(*) FILTER(WHERE data_evento IS DISTINCT FROM data_final) AS data_evento_divergente,
 count(*) FILTER(WHERE faixa_bi IS NULL AND nascimento_plausivel) AS ranges_nulos_com_nascimento_plausivel,
 count(*) FILTER(WHERE pais='BR' AND data_final>=DATE '2026-01-01'
 AND data_final<DATE '2026-10-01' AND status_final=0 AND homologado IS TRUE AND concluinte IS TRUE) AS elegiveis_regra_estudo,
 count(*) FILTER(WHERE concluinte IS DISTINCT FROM TRUE) AS concluinte_nao_true,
 count(*) FILTER(WHERE homologado IS DISTINCT FROM TRUE) AS homologado_nao_true,
 count(*) FILTER(WHERE status_final IS DISTINCT FROM 0) AS status_nao_zero,
 count(*) FILTER(WHERE pais IS DISTINCT FROM 'BR') AS pais_nao_br
 FROM linhas
)
SELECT jsonb_build_object('coletado_em',transaction_timestamp(),
 'read_only',current_setting('transaction_read_only'),
 'conciliacao',(SELECT to_jsonb(c) FROM contagens c))::text AS payload;
