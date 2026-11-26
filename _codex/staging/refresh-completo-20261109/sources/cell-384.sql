-- BI 2026: fato e estrutura da view do DBA; adapter estudo conserva IDs sem localidade.
-- Nascimento/modalidade/ranking complementados por id_resultado; nenhuma junção por nome.
WITH eventos AS MATERIALIZED (
 SELECT e.id_evento,e.nome_evento,e.data_final,extract(year FROM e.data_final)::int AS ano,e.cidade,e.estado,e.tipo_corrida,e.id_agrega_evento,a.tipo_agregacao,e.resultado_completo,(extract(month FROM e.data_final)<=9) AS na_janela
 FROM public.tb_evento_corridas e LEFT JOIN public.tb_agrega_eventos a USING(id_agrega_evento)
 WHERE e.pais='BR' AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2027-01-01'
), contagens AS MATERIALIZED (
 SELECT r.id_evento,r.percurso,count(*) AS concluintes,
  count(*) FILTER(WHERE r.sexo='F') AS feminino,
  count(*) FILTER(WHERE r.origem_resultado='oficial') AS origem_oficial,
  count(*) FILTER(WHERE r.tempo_total>TIME '00:00:00') AS tempo_positivo
 FROM estudo.vw_resultados_2026 r JOIN eventos e USING(id_evento)
 WHERE e.na_janela AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 GROUP BY r.id_evento,r.percurso
), totais AS (
 SELECT id_evento,sum(concluintes)::bigint AS concluintes,
  sum(feminino)::bigint AS feminino,sum(origem_oficial)::bigint AS origem_oficial,
  sum(tempo_positivo)::bigint AS tempo_positivo,
  jsonb_agg(jsonb_build_object('percurso',percurso,
   'concluintes',concluintes) ORDER BY percurso) AS percursos
 FROM contagens GROUP BY id_evento
), processamento AS (
 SELECT p.id_evento,count(*) AS processamentos,
  min(p.data_processamento_inicial) AS primeiro_processamento,
  max(p.data_processamento_final) AS ultimo_processamento,
  count(*) FILTER(WHERE p.erro_execucao IS TRUE) AS processamentos_com_erro
 FROM public.tb_resultados_processa p JOIN eventos e USING(id_evento)
 GROUP BY p.id_evento
), linhas AS (
 SELECT e.*,t.concluintes,t.feminino,t.origem_oficial,t.percursos,p.processamentos_com_erro
 FROM eventos e LEFT JOIN totais t USING(id_evento) LEFT JOIN processamento p USING(id_evento)
)
SELECT jsonb_build_object(
 'coletado_em',transaction_timestamp(),'read_only',current_setting('transaction_read_only'),
 'populacao','BR, data_final Jan–Set de 2025 e 2026; status_final=0, homologado=true, concluinte=true; todas modalidades e idades; participações.',
 'aviso','Concluintes nulos dentro da janela significam nenhum registro elegível; fora da janela não foram consultados. Resultado completo não certifica cobertura. Calendário atual não é histórico de captura.',
 'eventos',(SELECT jsonb_agg(to_jsonb(l) ORDER BY ano,id_evento) FROM linhas l),
 'totais',(SELECT jsonb_agg(to_jsonb(t) ORDER BY ano) FROM (
  SELECT ano,sum(coalesce(concluintes,0)) AS concluintes,
   count(*) FILTER(WHERE concluintes>0) AS eventos_com_resultados
  FROM linhas WHERE na_janela GROUP BY ano
 ) t)
) AS payload;