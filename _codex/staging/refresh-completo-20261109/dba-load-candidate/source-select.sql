-- CANDIDATO SELECT: universo Q3 vigente, todas as idades/modalidades.
-- Sem DDL/DML. Dados individuais apenas na projeção interna; para evidência use agregados/EXPLAIN.
WITH fonte AS MATERIALIZED (
SELECT r.id_resultado,r.id_evento,r.percurso,r.sexo,r.tempo_total,
 r.idade_range,r.data_nascimento,r.id_usuario,r.pcd,
 r.homologado AS resultado_homologado,r.concluinte,r.status_final,r.modalidade,
 e.data_final,e.data_inicial,e.estado,e.cidade,e.organizador,
 e.homologado AS evento_homologado,e.tipo_corrida
FROM public.tb_resultados r
JOIN public.tb_evento_corridas e ON e.id_evento=r.id_evento
WHERE e.pais='BR'
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01'
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
), lookup_data AS (
 SELECT data_referencia,min(id_data) AS id_data FROM public.tbbi_dim_data GROUP BY data_referencia
), lookup_local AS (
 SELECT upper(estado) AS estado,upper(nome_cidade) AS cidade,min(id_localidade) AS id_localidade
 FROM public.tbbi_dim_localidade GROUP BY upper(estado),upper(nome_cidade)
), lookup_org AS (
 SELECT nome_original,min(id_organizacao) AS id_organizacao
 FROM public.tbbi_dim_organizacao_2026 GROUP BY nome_original
), lookup_crono AS (
 SELECT id_evento,min(id_fornecedor) AS id_cronometrador
 FROM public.tb_evento_corridas_fornecedores WHERE id_fornecedor_tipo=2 GROUP BY id_evento
), lookup_strava AS (
 SELECT id,min(strava_id) AS id_atleta_strava FROM public.tb_usuarios WHERE id<>0 GROUP BY id
)
SELECT row_number() OVER(ORDER BY r.id_resultado)::integer AS id_fat_perfil_br_2026,
 dd.id_data,
 coalesce(dl.id_localidade,0) AS id_localidade,
 r.id_evento,
 coalesce(org.id_organizacao,0) AS id_organizador,
 coalesce(cr.id_cronometrador,0) AS id_cronometrador,
 r.id_resultado,
 public.get_id_geracao(r.idade_range,extract(year FROM r.data_final)::integer,
                      r.data_nascimento,r.data_final) AS id_geracao,
 public.get_id_categoria_cbat(r.idade_range) AS id_cbat_categoria,
 public.get_id_dim_faixa(r.percurso,r.tempo_total) AS id_faixa,
 r.data_final AS data_evento,r.percurso,r.sexo,r.tempo_total,r.idade_range,r.id_usuario,
 st.id_atleta_strava,r.pcd,r.evento_homologado,r.resultado_homologado
FROM fonte r
LEFT JOIN lookup_data dd ON dd.data_referencia=r.data_inicial
LEFT JOIN lookup_local dl ON dl.estado=upper(r.estado) AND dl.cidade=upper(r.cidade)
LEFT JOIN lookup_org org ON org.nome_original=r.organizador
LEFT JOIN lookup_crono cr ON cr.id_evento=r.id_evento
LEFT JOIN lookup_strava st ON st.id=r.id_usuario AND r.id_usuario<>0;
