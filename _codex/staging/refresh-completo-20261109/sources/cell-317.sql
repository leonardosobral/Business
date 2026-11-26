WITH parametros AS (
  SELECT DATE '2026-01-01' AS inicio, DATE '2026-09-27' AS fim_exclusivo
), eventos AS MATERIALIZED (
  SELECT e.id_evento, e.tipo_corrida, e.homologado AS evento_homologado,
         e.ativo, e.status_evento, e.resultado_completo, e.data_final,
         e.estado, e.cidade
  FROM public.tb_evento_corridas e CROSS JOIN parametros p
  WHERE e.pais='BR' AND e.data_final>=p.inicio AND e.data_final<p.fim_exclusivo
), base AS MATERIALIZED (
  SELECT r.id_resultado, r.id_evento, r.sexo, r.concluinte,
         r.homologado, r.status_final, r.origem_resultado,
         r.tempo_total, r.percurso, r.idade_range, r.pcd,
         e.tipo_corrida, e.evento_homologado, e.data_final, e.estado
  FROM public.tb_resultados r JOIN eventos e ON e.id_evento=r.id_evento
), cenarios AS (
  SELECT 'tb_resultados_sem_filtro' AS criterio, count(*) AS resultados, count(DISTINCT id_evento) AS eventos FROM base
  UNION ALL
  SELECT 'status_0_homologado', count(*), count(DISTINCT id_evento)
    FROM base WHERE status_final=0 AND homologado IS TRUE
  UNION ALL
  SELECT 'status_0_homologado_concluinte', count(*), count(DISTINCT id_evento)
    FROM base WHERE status_final=0 AND homologado IS TRUE AND concluinte IS TRUE
  UNION ALL
  SELECT 'status_0_homologado_tempo_positivo', count(*), count(DISTINCT id_evento)
    FROM base WHERE status_final=0 AND homologado IS TRUE AND tempo_total>TIME '00:00:00'
  UNION ALL
  SELECT 'status_0_homologado_rua', count(*), count(DISTINCT id_evento)
    FROM base WHERE status_final=0 AND homologado IS TRUE AND tipo_corrida='rua'
  UNION ALL
  SELECT 'candidato_oficial_rua_concluinte_tempo_positivo', count(*), count(DISTINCT id_evento)
    FROM base WHERE status_final=0 AND homologado IS TRUE AND concluinte IS TRUE
      AND tipo_corrida='rua' AND origem_resultado='oficial' AND tempo_total>TIME '00:00:00'
), qualidade AS (
  SELECT count(*) AS linhas,
    count(*) FILTER(WHERE sexo IS NULL OR btrim(sexo)='') AS sexo_ausente,
    count(*) FILTER(WHERE sexo IS NOT NULL AND sexo NOT IN ('M','F')) AS sexo_fora_m_f,
    count(*) FILTER(WHERE tempo_total IS NULL) AS tempo_nulo,
    count(*) FILTER(WHERE tempo_total=TIME '00:00:00') AS tempo_zero,
    count(*) FILTER(WHERE percurso IS NULL OR percurso<=0) AS distancia_ausente_ou_invalida,
    count(*) FILTER(WHERE idade_range IS NULL) AS idade_ausente,
    count(*) FILTER(WHERE isempty(idade_range)) AS idade_range_vazio,
    count(*) FILTER(WHERE lower_inf(idade_range) OR upper_inf(idade_range)) AS idade_range_aberto,
    count(*) FILTER(WHERE upper(idade_range)-lower(idade_range)>1) AS idade_intervalo_amplo,
    count(*) FILTER(WHERE idade_range && int4range(NULL,14,'[)')) AS idade_intersecta_menor_14,
    count(*) FILTER(WHERE idade_range && int4range(NULL,14,'[)') AND idade_range && int4range(14,NULL,'[)')) AS idade_cruza_limite_14,
    count(*) FILTER(WHERE concluinte IS DISTINCT FROM TRUE) AS nao_confirmado_concluinte,
    count(*) FILTER(WHERE origem_resultado IS DISTINCT FROM 'oficial') AS origem_nao_oficial,
    count(*) FILTER(WHERE evento_homologado IS DISTINCT FROM TRUE) AS evento_sem_homologacao_positiva
  FROM base WHERE status_final=0 AND homologado IS TRUE
), genero AS (
  SELECT sexo, count(*) AS status_0_homologado,
    count(*) FILTER(WHERE tempo_total>TIME '00:00:00') AS com_tempo_positivo,
    count(*) FILTER(WHERE tipo_corrida='rua') AS corrida_rua
  FROM base WHERE status_final=0 AND homologado IS TRUE GROUP BY sexo
), tipos AS (
  SELECT tipo_corrida,count(*) AS eventos,
    count(*) FILTER(WHERE ativo IS TRUE) AS ativos,
    count(*) FILTER(WHERE evento_homologado IS TRUE) AS homologados,
    count(*) FILTER(WHERE resultado_completo IS TRUE) AS sinalizados_completos
  FROM eventos GROUP BY tipo_corrida
), estados_evento AS (
  SELECT status_evento,count(*) AS eventos FROM eventos GROUP BY status_evento
)
SELECT jsonb_build_object(
  'coletado_em',transaction_timestamp(),'banco',current_database(),
  'read_only',current_setting('transaction_read_only'),
  'parametros',(SELECT to_jsonb(p) FROM parametros p),
  'status','diagnostico_da_base_atual_nao_reconciliado',
  'aviso','Cenários não aplicam idade 14+. Status/homologação são filtros explícitos, não prova da definição ativa de vw_resultados.',
  'eventos_cadastrados',(SELECT count(*) FROM eventos),
  'eventos_por_tipo',(SELECT jsonb_agg(to_jsonb(t) ORDER BY tipo_corrida) FROM tipos t),
  'estados_evento',(SELECT jsonb_agg(to_jsonb(s) ORDER BY status_evento) FROM estados_evento s),
  'cenarios',(SELECT jsonb_agg(to_jsonb(c) ORDER BY criterio) FROM cenarios c),
  'qualidade_status_0_homologado',(SELECT to_jsonb(q) FROM qualidade q),
  'genero_status_0_homologado',(SELECT jsonb_agg(to_jsonb(g) ORDER BY sexo) FROM genero g)
) AS payload