-- Proposta revisada, NÃO EXECUTADA. Somente SELECT: não é script de carga.
-- Contrato do estudo: BR, data_final Jan–Set2026, status0/homologado/concluinte.
-- Mantém id_data pela data_inicial conforme contrato DBA atual; não usa dd.mes
-- para definir o mês do estudo, que continua vindo de data_evento/data_final.
-- Pré-condições: uma linha de dim_data por data_inicial; sexo/percurso não nulos;
-- validar IDs únicos e demais dimensões antes de qualquer publicação da carga.
WITH eventos AS MATERIALIZED (
 SELECT evt.id_evento,evt.data_final,evt.homologado,dtt.id_data,
  coalesce((SELECT min(loc.id_localidade) FROM public.tbbi_dim_localidade loc
    WHERE upper(loc.estado)=upper(evt.estado) AND upper(loc.nome_cidade)=upper(evt.cidade)),0) AS id_localidade,
  coalesce((SELECT min(frn.id_organizacao) FROM public.tbbi_dim_organizacao_2026 frn
    WHERE frn.nome_original=evt.organizador),0) AS id_organizador,
  coalesce((SELECT min(frn.id_fornecedor) FROM public.tb_evento_corridas_fornecedores frn
    WHERE frn.id_evento=evt.id_evento AND frn.id_fornecedor_tipo=2),0) AS id_cronometrador
 FROM public.tb_evento_corridas evt
 JOIN public.tbbi_dim_data dtt ON dtt.data_referencia=evt.data_inicial
 WHERE evt.pais='BR' AND evt.data_final>=DATE '2026-01-01'
   AND evt.data_final<DATE '2026-10-01'
)
SELECT evt.id_data,evt.id_localidade,evt.id_evento,evt.id_organizador,evt.id_cronometrador,
 res.id_resultado,
 public.get_id_geracao(res.idade_range,extract(year FROM evt.data_final)::integer,
   res.data_nascimento,evt.data_final) AS id_geracao,
 public.get_id_categoria_cbat(res.idade_range) AS id_cbat_categoria,
 public.get_id_dim_faixa(res.percurso,res.tempo_total) AS id_faixa,
 evt.data_final AS data_evento,res.percurso,res.sexo,res.tempo_total,res.idade_range,
 res.id_usuario,usu.strava_id AS id_atleta_strava,res.pcd,
 evt.homologado AS evento_homologado,res.homologado AS resultado_homologado
FROM public.tb_resultados res JOIN eventos evt ON evt.id_evento=res.id_evento
-- tb_usuarios.id é chave única referenciada pela FK de id_usuario: o LEFT JOIN
-- equivale ao min(strava_id) original, inclusive para id_usuario0 ou ausente.
LEFT JOIN public.tb_usuarios usu ON usu.id=res.id_usuario AND res.id_usuario<>0
WHERE res.status_final=0 AND res.homologado IS TRUE AND res.concluinte IS TRUE;
