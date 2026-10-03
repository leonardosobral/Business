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
