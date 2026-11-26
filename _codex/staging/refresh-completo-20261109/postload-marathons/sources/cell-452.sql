-- Diagnóstico operacional separado dos volumes editoriais congelados.
-- Nenhuma identificação pessoal é retornada. O vínculo id_usuario é o atual da
-- view BI e pode ter sido associado retrospectivamente; não prova causalidade.
WITH inscritos AS MATERIALIZED (
 SELECT id_usuario,min(data_inscricao) AS inscrito_em
 FROM public.desafios WHERE desafio='circuitobrasilgigante'
 AND data_inscricao<TIMESTAMP '2026-10-01' AND id_usuario>0
 GROUP BY id_usuario
), eventos AS MATERIALIZED (
 SELECT id_evento,id_agrega_evento,CASE WHEN id_evento=37310 THEN DATE '2026-05-03' ELSE data_final END AS data_final FROM public.tb_evento_corridas
 WHERE id_evento IN(29291,34236,32450,36245,34529,37310,39393)
 AND pais='BR' AND data_final>=DATE '2026-01-01' AND data_final<DATE '2026-10-01'
), elegiveis AS MATERIALIZED (
 SELECT r.id_resultado,r.id_evento,r.id_usuario,e.data_final,e.id_agrega_evento
 FROM estudo.vw_resultados_2026 r JOIN eventos e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE
 AND r.percurso BETWEEN 42 AND 42.2 AND r.tempo_total>TIME '00:00:00'
 AND r.pcd IS FALSE AND NOT(coalesce(r.modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|REVEZ|DUPLA|QUARTETO|OCTETO|TRAIL|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))')
), por_inscrito AS (
 SELECT i.id_usuario,count(DISTINCT e.id_evento) AS etapas,
 count(DISTINCT e.id_evento) FILTER(WHERE i.inscrito_em::date<=e.data_final) AS etapas_inscrito_antes_ou_dia
 FROM inscritos i LEFT JOIN elegiveis e USING(id_usuario) GROUP BY i.id_usuario
), por_etapa AS (
 SELECT e.id_evento,e.id_agrega_evento,count(*) AS conclusoes_bi,
 count(*) FILTER(WHERE e.id_usuario>0) AS conclusoes_com_conta,
 count(*) FILTER(WHERE i.id_usuario IS NOT NULL) AS conclusoes_de_inscritos,
 count(DISTINCT i.id_usuario) AS inscritos_com_resultado
 FROM elegiveis e LEFT JOIN inscritos i USING(id_usuario)
 GROUP BY e.id_evento,e.id_agrega_evento
)
SELECT jsonb_build_object('consultado_em',current_timestamp,
 'corte','2026-09-30','natureza','Adesão operacional; vínculo de resultado atual e possivelmente retrospectivo; sem inferência causal',
 'inscritos',(SELECT count(*) FROM inscritos),
 'com_resultado',(SELECT count(*) FROM por_inscrito WHERE etapas>=1),
 'com_duas_ou_mais',(SELECT count(*) FROM por_inscrito WHERE etapas>=2),
 'inscritos_antes_ou_dia_de_uma_etapa',(SELECT count(*) FROM por_inscrito WHERE etapas_inscrito_antes_ou_dia>=1),
 'inscritos_antes_ou_dia_de_duas_etapas',(SELECT count(*) FROM por_inscrito WHERE etapas_inscrito_antes_ou_dia>=2),
 'distribuicao',(SELECT jsonb_agg(to_jsonb(t) ORDER BY t.etapas) FROM (SELECT etapas,count(*) AS contas FROM por_inscrito GROUP BY etapas) t),
 'etapas',(SELECT jsonb_agg(to_jsonb(t) ORDER BY t.id_evento) FROM por_etapa t))::text AS payload
