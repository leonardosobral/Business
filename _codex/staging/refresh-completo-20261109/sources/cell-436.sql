-- Ampliação do vertical: seleção congelada 244. Mesmos filtros convencionais.
-- Perfil usa a base atual; Floripa 2026 permanece com 3594 nesta leitura, sem imputar nascimento à captura oficial3592.
-- Não somar a população de perfil com a seleção oficial; denominadores próprios explícitos.
WITH base AS MATERIALIZED (
 SELECT r.id_evento,r.id_resultado,r.sexo,extract(epoch FROM r.tempo_total) AS segundos,e.nome_evento,e.estado,e.cidade,e.data_final
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento)
 WHERE r.status_final=0 AND r.homologado IS TRUE  AND r.id_evento IN(22582,22586,22590,22591,22592,22792,23713,24012,24015,24016,24998,24999,25481,25680,25698,25720,25726,25727,25733,26506,26768,26867,26983,27088,27099,27104,27532,27635,27637,27747,27771,28253,28327,28572,28609,28610,28611,28617,29387,30471,31973) AND r.percurso BETWEEN 42 AND 42.2 AND r.concluinte IS TRUE AND r.tempo_total>TIME '00:00:00' AND r.pcd IS FALSE AND NOT(coalesce(r.modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|REVEZ|DUPLA|QUARTETO|OCTETO|TRAIL|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))')
), ordenados AS (
 SELECT *,row_number() OVER(PARTITION BY id_evento ORDER BY segundos,id_resultado) AS posicao,count(*) OVER(PARTITION BY id_evento) AS n FROM base
), agregado AS (
 SELECT id_evento,max(nome_evento) AS nome,max(estado) AS uf,max(cidade) AS cidade,max(data_final)::text AS data,
 count(*) AS total,count(*) FILTER(WHERE sexo='F') AS feminino,count(*) FILTER(WHERE sexo='M') AS masculino,
 min(segundos) AS minimo,avg(segundos) AS media,percentile_cont(.5) WITHIN GROUP(ORDER BY segundos) AS mediana,
 count(*) FILTER(WHERE segundos<9000) AS sub2h30,count(*) FILTER(WHERE segundos<10800) AS sub3,count(*) FILTER(WHERE segundos<14400) AS sub4,
 avg(segundos) FILTER(WHERE posicao<=10) AS top10,avg(segundos) FILTER(WHERE posicao<=100) AS top100,
 avg(segundos) FILTER(WHERE posicao<=ceil(n*.05)) AS top5pct,avg(segundos) FILTER(WHERE posicao<=ceil(n*.10)) AS top10pct,avg(segundos) FILTER(WHERE posicao<=ceil(n*.50)) AS top50pct
 FROM ordenados GROUP BY id_evento
), bins AS (
 SELECT id_evento,coalesce(nullif(sexo,''),'N/A') AS sexo,CASE WHEN segundos<9000 THEN '01 · <2h30' WHEN segundos<10800 THEN '02 · 2h30–3h' WHEN segundos<12600 THEN '03 · 3h–3h30' WHEN segundos<14400 THEN '04 · 3h30–4h' WHEN segundos<16200 THEN '05 · 4h–4h30' WHEN segundos<18000 THEN '06 · 4h30–5h' WHEN segundos<21600 THEN '07 · 5h–6h' ELSE '08 · 6h+' END AS faixa,count(*) AS total FROM base GROUP BY 1,2,3
)
SELECT 2025 AS ano,jsonb_build_object('provas',(SELECT jsonb_agg(to_jsonb(a) ORDER BY a.total DESC) FROM agregado a),'tempos',(SELECT jsonb_agg(to_jsonb(b) ORDER BY id_evento,sexo,faixa) FROM bins b)) AS payload
