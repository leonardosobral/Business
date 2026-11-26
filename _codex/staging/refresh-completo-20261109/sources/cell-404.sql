-- Revisão dos 16 casos do congelamento 174: não acrescentar 42 km ao cadastro automaticamente.
-- Captura atual por esses IDs, preservando a referência original Jan–Set; apenas agregados.
-- A distância marcada em tb_resultados não confirma que seja corrida de rua individual.
WITH ids AS(SELECT column1 AS id_evento FROM(VALUES (34834),(34839),(37868),(38070),(39970),(40447),(40980),(41082),(42782),(44199),(44586),(45804),(46817),(47613),(48354),(48640)) t),
base AS MATERIALIZED(
 SELECT r.id_evento,r.modalidade,r.percurso,r.tempo_total,
 r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE AND r.tempo_total>TIME '00:00:00' AND r.pcd IS FALSE
 AND NOT(coalesce(r.modalidade,'') ~* '(CADEIR|DEFICI|ANDANTE|HAND|BIKE|GUIA|(^|[^A-Z0-9])(PCD|ACD|DI|DV|DA|DMAI|DMS|CAD)([^A-Z0-9]|$))') AS elegivel
 FROM public.tb_resultados r JOIN ids i USING(id_evento) WHERE r.percurso BETWEEN 42 AND 42.2
), grupos AS(
 SELECT id_evento,coalesce(modalidade,'[não informada]') AS modalidade,count(*) AS linhas,
 count(*) FILTER(WHERE elegivel) AS elegiveis,
 min(extract(epoch FROM tempo_total)) FILTER(WHERE elegivel) AS menor_segundos,
 percentile_cont(0.5) WITHIN GROUP(ORDER BY extract(epoch FROM tempo_total)) FILTER(WHERE elegivel) AS mediana_segundos
 FROM base GROUP BY id_evento,modalidade
)
SELECT e.id_evento,e.nome_evento,e.data_final,e.cidade,e.estado,e.tag,e.tipo_corrida,e.ranking,e.ativo,
 e.url_resultado,e.url_wiclax,e.url_hotsite,e.url_inscricao,e.url_regulamento,
 (SELECT count(*) FROM base b WHERE b.id_evento=e.id_evento) AS linhas_brutas,
 (SELECT count(*) FROM base b WHERE b.id_evento=e.id_evento AND b.elegivel) AS elegiveis,
 (SELECT jsonb_agg(to_jsonb(g) ORDER BY modalidade) FROM grupos g WHERE g.id_evento=e.id_evento) AS modalidades,
 coalesce((SELECT jsonb_agg(jsonb_build_object('km',d.percurso_evento,'unidade',d.unidade_de_medida,'tipo',d.tipo_corrida,'bloqueado',d.percurso_bloqueado) ORDER BY d.percurso_evento) FROM public.tb_evento_corridas_percursos d WHERE d.id_evento=e.id_evento),'[]'::jsonb) AS percursos,
 current_timestamp AS coletado_em,174 AS congelamento_referencia
 FROM public.tb_evento_corridas e JOIN ids i USING(id_evento) ORDER BY e.data_final,e.id_evento