-- Inventário auditável. Não certifica realização, medição ou completude.
WITH eventos AS MATERIALIZED (
 SELECT e.id_evento,e.nome_evento,e.data_final,e.cidade,e.estado,e.id_agrega_evento,e.tipo_corrida,e.ativo,e.ranking,
 e.url_resultado,e.url_hotsite,e.resultado_completo,
 EXISTS(SELECT 1 FROM public.tb_evento_corridas_percursos p WHERE p.id_evento=e.id_evento AND lower(trim(p.unidade_de_medida))='km' AND p.tipo_corrida='rua' AND p.percurso_evento BETWEEN 42 AND 42.2) AS percurso_cadastrado
 FROM public.tb_evento_corridas e WHERE e.pais='BR'
 AND e.data_final>=DATE '2026-01-01' AND e.data_final<DATE '2026-10-01' AND e.tipo_corrida='rua'
), linhas AS MATERIALIZED (
 SELECT r.id_evento,r.id_resultado,r.sexo,r.tempo_total,r.modalidade,r.pcd,
 (r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE) AS concluinte,
 coalesce(r.modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|REVEZ|DUPLA|QUARTETO|OCTETO|TRAIL|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))' AS especial
 FROM estudo.vw_resultados_2026 r JOIN eventos e USING(id_evento) WHERE r.percurso BETWEEN 42 AND 42.2
), elegiveis AS MATERIALIZED (
 SELECT * FROM linhas WHERE concluinte AND tempo_total>TIME '00:00:00' AND pcd IS FALSE AND NOT especial
), totais AS (
 SELECT id_evento,count(*) AS participacoes,count(*) FILTER(WHERE sexo='F') AS feminino,
 count(*) FILTER(WHERE sexo='M') AS masculino,
 count(*) FILTER(WHERE tempo_total<TIME '02:00:00') AS sub2_auditar,
 count(*) FILTER(WHERE tempo_total<TIME '03:00:00') AS sub3,
 count(*) FILTER(WHERE tempo_total<TIME '04:00:00') AS sub4,
 percentile_cont(.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)) AS mediana_segundos,
 min(tempo_total)::text AS menor_tempo
 FROM elegiveis GROUP BY id_evento
), bruto AS (
 SELECT id_evento,count(*) AS linhas42,count(*) FILTER(WHERE concluinte) AS conclusoes42,
 count(*) FILTER(WHERE concluinte AND especial) AS modalidade_excluida,
 count(*) FILTER(WHERE concluinte AND pcd IS NULL) AS pcd_desconhecido,
 count(*) FILTER(WHERE concluinte AND (tempo_total IS NULL OR tempo_total=TIME '00:00:00')) AS sem_tempo,
 string_agg(DISTINCT modalidade,' | ' ORDER BY modalidade) AS modalidades FROM linhas GROUP BY id_evento
)
SELECT 2026 AS ano,current_timestamp AS coletado_em,e.*,b.linhas42,b.conclusoes42,b.modalidade_excluida,b.pcd_desconhecido,b.sem_tempo,b.modalidades,
 coalesce(t.participacoes,0) AS participacoes,t.feminino,t.masculino,t.sub2_auditar,t.sub3,t.sub4,t.mediana_segundos,t.menor_tempo
FROM eventos e LEFT JOIN bruto b USING(id_evento) LEFT JOIN totais t USING(id_evento)
WHERE e.percurso_cadastrado OR b.linhas42>0 ORDER BY e.data_final,e.id_evento