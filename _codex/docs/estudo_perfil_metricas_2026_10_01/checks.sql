-- Testa a consulta real sobre dados sintéticos, sem dados pessoais.
WITH usuarios_teste AS(SELECT column1 AS id,column2 AS data_criacao,column3 AS strava_id,column4 AS strava_premium,column5 AS strava_full_follower_count,column6 AS strava_weight,column7 AS assessoria,column8 AS strava_full_shoes FROM(VALUES
 (1,TIMESTAMP '2025-12-31 23:59:59',101,true,0,0::float8,' A ','[{"retired":false,"distance":1000},{"retired":true,"distance":999999},{"distance":99}]'::jsonb),
 (2,TIMESTAMP '2026-01-01 00:00:00',102,false,10,20::float8,'','[]'::jsonb),
 (3,TIMESTAMP '2026-09-26 23:59:59',103,NULL,NULL,300::float8,'  ',NULL::jsonb),
 (4,TIMESTAMP '2026-09-27 00:00:00',104,true,900,100::float8,'B','[]'::jsonb),
 (5,TIMESTAMP '2025-06-01 00:00:00',0,true,999,740::float8,NULL,'{}'::jsonb))t),
eventos_teste AS(SELECT column1 AS id_evento,column2 AS data_final FROM(VALUES(1,DATE '2025-12-31'),(2,DATE '2026-06-01'),(3,DATE '2026-09-27'))t),
resultados_teste AS(SELECT column1 AS id_usuario,column2 AS id_evento FROM(VALUES(1,1),(1,1),(5,2),(2,3))t),
calendario_teste AS(SELECT column1 AS id_usuario,column2 AS data_checkin,column3 AS id_fornecedor FROM(VALUES
 (1,TIMESTAMP '2025-12-31 23:59:59',NULL::integer),(1,TIMESTAMP '2025-10-01',NULL::integer),
 (5,TIMESTAMP '2026-01-01',NULL::integer),(3,TIMESTAMP '2026-09-26',99))t),
desafios_teste AS(SELECT column1 AS id_usuario,column2 AS status,column3 AS data_inscricao FROM(VALUES
 (1,'C',TIMESTAMP '2025-06-01'),(1,'C',TIMESTAMP '2025-12-01'),(2,'C',TIMESTAMP '2026-09-26 23:59:59'),
 (3,'I',TIMESTAMP '2026-01-01'),(5,'I',TIMESTAMP '2025-06-01'))t),
cortes AS(SELECT column1 AS ano,column2 AS corte FROM(VALUES(2025,DATE '2025-12-31'),(2026,DATE '2026-09-26'))t),
resultados AS(
 SELECT r.id_usuario,min(e.data_final) AS primeira_prova FROM resultados_teste r
 JOIN eventos_teste e ON e.id_evento=r.id_evento WHERE r.id_usuario>0 GROUP BY r.id_usuario
),calendario AS(
 SELECT id_usuario,min(data_checkin) AS primeiro_registro,bool_or(data_checkin IS NULL) AS sem_data
 FROM calendario_teste WHERE id_fornecedor IS NULL GROUP BY id_usuario
),desafios AS(
 SELECT id_usuario,min(data_inscricao) AS primeira_inscricao FROM desafios_teste WHERE upper(status)='C' GROUP BY id_usuario
),sapatos AS(
 SELECT u.id,jsonb_typeof(u.strava_full_shoes)='array' AS lista_informada,
 count(a) FILTER(WHERE a->>'retired'='false') AS pares_ativos,
 count(a) FILTER(WHERE a->>'retired'='false' AND a->>'distance'~'^[0-9]+([.][0-9]+)?$') AS pares_com_distancia,
 sum((CASE WHEN a->>'distance'~'^[0-9]+([.][0-9]+)?$' THEN (a->>'distance')::numeric END)/1000) FILTER(WHERE a->>'retired'='false') AS distancia_km,
 count(a) FILTER(WHERE a->>'retired' IS NULL OR a->>'retired' NOT IN('true','false')) AS ativo_desconhecido
 FROM usuarios_teste u LEFT JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(u.strava_full_shoes)='array' THEN u.strava_full_shoes ELSE '[]'::jsonb END)a ON true GROUP BY u.id,u.strava_full_shoes
),base AS(
 SELECT c.ano,c.corte,u.strava_id,u.strava_premium,u.strava_full_follower_count AS seguidores,u.strava_weight AS peso,
 nullif(trim(u.assessoria),'') IS NOT NULL AS equipe,
 r.primeira_prova<=c.corte AS tem_resultado,k.primeiro_registro<c.corte+1 AS tem_calendario,k.sem_data,
 d.primeira_inscricao<c.corte+1 AS tem_desafio,s.* FROM cortes c JOIN usuarios_teste u ON u.data_criacao<c.corte+1
 LEFT JOIN resultados r ON r.id_usuario=u.id LEFT JOIN calendario k ON k.id_usuario=u.id LEFT JOIN desafios d ON d.id_usuario=u.id
 LEFT JOIN sapatos s ON s.id=u.id
),stats AS(
 SELECT ano,corte,count(*) AS contas,
 count(*) FILTER(WHERE tem_resultado) AS resultados,
 count(*) FILTER(WHERE tem_calendario) AS calendario,
 count(*) FILTER(WHERE coalesce(sem_data,false) AND NOT coalesce(tem_calendario,false)) AS calendario_sem_data,
 count(*) FILTER(WHERE equipe) AS equipe,count(*) FILTER(WHERE tem_desafio) AS desafios,
 count(*) FILTER(WHERE strava_id>0) AS strava,
 count(*) FILTER(WHERE strava_id>0 AND strava_premium IS NOT NULL) AS premium_informado,
 count(*) FILTER(WHERE strava_id>0 AND strava_premium IS TRUE) AS premium,
 count(*) FILTER(WHERE strava_id>0 AND seguidores>=0) AS seguidores_informados,
 sum(seguidores) FILTER(WHERE strava_id>0 AND seguidores>=0) AS soma_seguidores,
 count(*) FILTER(WHERE strava_id>0 AND peso>0 AND peso<'Infinity'::float8) AS pesos_positivos,
 sum(peso) FILTER(WHERE strava_id>0 AND peso>0 AND peso<'Infinity'::float8) AS soma_pesos_positivos,
 count(*) FILTER(WHERE strava_id>0 AND peso BETWEEN 20 AND 300) AS pesos_20_300,
 sum(peso) FILTER(WHERE strava_id>0 AND peso BETWEEN 20 AND 300) AS soma_pesos_20_300,
 count(*) FILTER(WHERE strava_id>0 AND lista_informada) AS listas_tenis,
 sum(pares_ativos) FILTER(WHERE strava_id>0 AND lista_informada) AS pares_ativos,
 sum(pares_com_distancia) FILTER(WHERE strava_id>0 AND lista_informada) AS pares_com_distancia,
 sum(distancia_km) FILTER(WHERE strava_id>0 AND lista_informada) AS distancia_km,
 sum(ativo_desconhecido) FILTER(WHERE strava_id>0 AND lista_informada) AS tenis_ativo_desconhecido
 FROM base GROUP BY ano,corte
),mapa AS(SELECT column1 AS ordem,column2 AS categoria,column3 AS unidade,column4 AS casas_decimais,column5 AS regra FROM(VALUES
 (1,'Associaram resultados','percentual',1,'resultado_atual'),
 (2,'Incluíram provas ao calendário','percentual',1,'calendario_registrado'),
 (3,'Com equipe/assessoria','percentual',1,'equipe_atual'),
 (4,'Desafios virtuais','percentual',1,'inscricao_confirmada_atual'),
 (5,'Vincularam ao Strava','percentual',1,'strava_atual'),
 (6,'Strava Premium','percentual',1,'premium_informado'),
 (7,'Média seguidores','numero',0,'seguidores_strava'),
 (8,'Peso médio — positivos','kg',1,'peso_positivo'),
 (8,'Peso médio — 20 a 300 kg','kg',1,'peso_20_300'),
 (9,'Pares tênis ativos','pares',1,'pares_por_lista_informada'),
 (10,'Rodagem por par','km',0,'km_por_par_ativo'))v),metricas AS(
 SELECT s.*,m.*,
 (CASE m.regra WHEN 'resultado_atual' THEN resultados WHEN 'calendario_registrado' THEN calendario
 WHEN 'equipe_atual' THEN equipe WHEN 'inscricao_confirmada_atual' THEN desafios WHEN 'strava_atual' THEN strava
 WHEN 'premium_informado' THEN premium WHEN 'seguidores_strava' THEN soma_seguidores
 WHEN 'peso_positivo' THEN soma_pesos_positivos WHEN 'peso_20_300' THEN soma_pesos_20_300
 WHEN 'pares_por_lista_informada' THEN pares_ativos WHEN 'km_por_par_ativo' THEN distancia_km END)::numeric AS numerador,
 CASE m.regra WHEN 'premium_informado' THEN premium_informado WHEN 'seguidores_strava' THEN seguidores_informados
 WHEN 'peso_positivo' THEN pesos_positivos WHEN 'peso_20_300' THEN pesos_20_300
 WHEN 'pares_por_lista_informada' THEN listas_tenis WHEN 'km_por_par_ativo' THEN pares_com_distancia ELSE contas END AS denominador
 FROM stats s CROSS JOIN mapa m
)
SELECT ano,corte,ordem,categoria,unidade,casas_decimais,numerador,denominador,
 numerador*CASE WHEN unidade='percentual' THEN 100 ELSE 1 END/nullif(denominador,0) AS valor,
 contas,calendario_sem_data,premium_informado,seguidores_informados,pesos_positivos,pesos_20_300,
 listas_tenis,pares_ativos,pares_com_distancia,tenis_ativo_desconhecido,regra,current_timestamp AS coletado_em
FROM metricas ORDER BY ano,ordem,categoria;
