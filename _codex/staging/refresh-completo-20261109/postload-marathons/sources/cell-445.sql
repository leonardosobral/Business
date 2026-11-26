-- Diagnóstico anual2024 x2025; não altera a publicação2026 nem o estudo principal.
-- 2024: inventário258 com mesmos filtros elegíveis2025; ainda não é seleção CR validada.
-- 2025: seleção congelada244; volumes preservados; vínculos atuais congelados nesta execução.
-- Pares exigem agregador positivo, uma candidata2024 e uma prova2025 selecionada por agregador,
-- além de exatamente uma candidata2025 do inventário242 naquele agregador e resultados elegíveis2024.
-- Treinos sem percurso/resultado42km não são candidatas a edição de maratona (Floripa).
-- Ano inteiro em ambos; não comparar com Jan-Set2026; crescimento de registros não mede causalmente o mercado.
WITH a AS MATERIALIZED (
 SELECT (j.value->>'id_evento')::int AS id_evento,j.value->>'nome_evento' AS nome_evento,
 (j.value->>'data_final')::date AS data_final,(j.value->>'participacoes')::int AS participacoes,
 (j.value->>'id_agrega_evento')::int AS agregador,
 (j.value->>'sub2_auditar')::int AS sub2_auditar,(j.value->>'resultado_completo')::boolean AS resultado_completo,
 (j.value->>'ranking')::boolean AS ranking,j.value->>'url_resultado' AS url_resultado,j.value->>'modalidades' AS modalidades
 FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j WHERE r.id=258
), b AS MATERIALIZED (
 SELECT e.id_evento,e.nome_evento,e.data_final,e.cidade,e.estado,e.id_agrega_evento AS agregador,
 (j.value->>'participacoes')::int AS participacoes,(j.value->>'id_agrega_evento')::int AS vinculo_no_congelamento
 FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j
 JOIN public.tb_evento_corridas e ON e.id_evento=(j.value->>'id_evento')::int
 WHERE r.id=244 AND j.value->>'decisao'='selecionada'
), agrupados AS (
 SELECT b.*,
 (SELECT count(*) FROM a WHERE a.agregador=b.agregador) AS candidatas2024,
 (SELECT count(*) FROM a WHERE a.agregador=b.agregador AND a.participacoes>0) AS com_resultado2024,
 (SELECT count(*) FROM b x WHERE x.agregador=b.agregador) AS selecionadas2025,
 (SELECT count(*) FROM public.tb_evento_corridas e WHERE e.id_agrega_evento=b.agregador AND e.data_final>=DATE '2025-01-01' AND e.data_final<DATE '2026-01-01' AND EXISTS(SELECT 1 FROM estudo.notebook_runs r CROSS JOIN LATERAL jsonb_array_elements(r.result->'rows') j WHERE r.id=242 AND (j.value->>'id_evento')::int=e.id_evento)) AS candidatas2025,
 (SELECT jsonb_agg(to_jsonb(a) ORDER BY participacoes DESC) FROM a WHERE a.agregador=b.agregador) AS edicoes2024
 FROM b
), classificados AS (
 SELECT *,CASE WHEN agregador IS NULL OR agregador<=0 THEN 'Sem agregador em2025'
 WHEN candidatas2024=0 THEN 'Sem candidata2024 vinculada no inventário'
 WHEN candidatas2024>1 OR selecionadas2025>1 OR candidatas2025>1 THEN 'Vínculo ambíguo; revisão manual'
 WHEN com_resultado2024=0 THEN 'Edição2024 sem resultados elegíveis'
 ELSE 'Par disponível; cobertura2024 ainda a validar' END AS situacao
 FROM agrupados
), pares AS (
 SELECT agregador,id_evento AS id2025,nome_evento,data_final AS data2025,participacoes AS n2025,
 (edicoes2024->0->>'id_evento')::int AS id2024,
 (edicoes2024->0->>'data_final')::date AS data2024,
 (edicoes2024->0->>'participacoes')::int AS n2024,
 (edicoes2024->0->>'sub2_auditar')::int AS sub2_2024,
 (edicoes2024->0->>'resultado_completo')::boolean AS resultado_completo2024,
 (edicoes2024->0->>'ranking')::boolean AS ranking2024
 FROM classificados WHERE situacao='Par disponível; cobertura2024 ainda a validar'
)
SELECT current_timestamp AS coletado_em,jsonb_build_object(
 'inventario2024',(SELECT jsonb_build_object('candidatas',count(*),'com_resultados',count(*) FILTER(WHERE participacoes>0),'participacoes',sum(participacoes)) FROM a),
 'selecao2025',(SELECT jsonb_build_object('provas',count(*),'participacoes',sum(participacoes),'vinculos_alterados',count(*) FILTER(WHERE agregador IS DISTINCT FROM vinculo_no_congelamento)) FROM b),
 'resumo',(SELECT jsonb_build_object('pares',count(*),'n2024',sum(n2024),'n2025',sum(n2025),'variacao_registros',100.0*(sum(n2025)::numeric/nullif(sum(n2024),0)-1),'cobertura_volume2025',100.0*sum(n2025)/(SELECT sum(participacoes) FROM b),'provas_sub2_2024',count(*) FILTER(WHERE sub2_2024>0),'provas_marcadas_completas2024',count(*) FILTER(WHERE resultado_completo2024),'provas_rankingfalse2024',count(*) FILTER(WHERE ranking2024 IS FALSE)) FROM pares),
 'pares',(SELECT jsonb_agg(to_jsonb(p) ORDER BY n2025 DESC) FROM pares p),
 'situacoes',(SELECT jsonb_agg(to_jsonb(s)) FROM (SELECT situacao,count(*) AS provas,sum(participacoes) AS participacoes2025 FROM classificados GROUP BY situacao) s),
 'por_prova',(SELECT jsonb_agg(to_jsonb(c) ORDER BY participacoes DESC) FROM classificados c)
) AS payload
