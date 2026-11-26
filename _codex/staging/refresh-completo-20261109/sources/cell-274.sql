-- P08/P14: uma consulta e matriz explícita de limites, derivados das células 189/191/219 rev1.
-- Candidata revista de 2025: status 0, homologado, concluinte e tempo positivo.
-- Performance: rua; CNA: PCD=false e ranking elegível, sem filtro de tipo (como SQL original).
-- Limites performance (inferior,superior]; CNA [inferior,superior). Não aplica marca de plausibilidade.
-- Rótulos históricos preservados como chave; intervalo exato retornado para evitar ambiguidades.
WITH parametros AS (SELECT DATE '2025-01-01' AS inicio,DATE '2026-01-01' AS fim_exclusivo),
limites AS (
 SELECT column1 AS indicador,column2 AS distancia,column3 AS faixa,column4::numeric AS minimo,
 column5::numeric AS maximo,column6 AS ordem,column7 AS fronteiras
 FROM (VALUES ('performance','5k','<20min',0,1200,1,'(]'),
 ('performance','5k','20–25min',1200,1500,2,'(]'),
 ('performance','5k','25–30min',1500,1800,3,'(]'),
 ('performance','5k','30+min',1800,NULL,4,'(]'),
 ('performance','10k','<40min',0,2400,1,'(]'),
 ('performance','10k','40–50min',2400,3000,2,'(]'),
 ('performance','10k','50–60min',3000,3600,3,'(]'),
 ('performance','10k','60+min',3600,NULL,4,'(]'),
 ('performance','21k','<1:30',0,5400,1,'(]'),
 ('performance','21k','1:30–2:00',5400,7200,2,'(]'),
 ('performance','21k','2:00–2:30',7200,9000,3,'(]'),
 ('performance','21k','2:30+',9000,NULL,4,'(]'),
 ('performance','42k','<3:00',0,10800,1,'(]'),
 ('performance','42k','3:00–3:30',10800,12600,2,'(]'),
 ('performance','42k','<4:00',12600,14400,3,'(]'),
 ('performance','42k','4:00–4:30',14400,16200,4,'(]'),
 ('performance','42k','4:30+',16200,NULL,5,'(]'),
 ('cna','5k','Branca',1800,NULL,1,'[)'),
 ('cna','5k','Laranja',1620,1800,2,'[)'),
 ('cna','5k','Amarela',1500,1620,3,'[)'),
 ('cna','5k','Azul',1320,1500,4,'[)'),
 ('cna','5k','Vermelha',1200,1320,5,'[)'),
 ('cna','5k','Marrom',1020,1200,6,'[)'),
 ('cna','5k','Preta',900,1020,7,'[)'),
 ('cna','5k','Mestre',0,900,8,'[)'),
 ('cna','10k','Branca',3600,NULL,1,'[)'),
 ('cna','10k','Laranja',3300,3600,2,'[)'),
 ('cna','10k','Amarela',3000,3300,3,'[)'),
 ('cna','10k','Azul',2700,3000,4,'[)'),
 ('cna','10k','Vermelha',2520,2700,5,'[)'),
 ('cna','10k','Marrom',2400,2520,6,'[)'),
 ('cna','10k','Preta',2100,2400,7,'[)'),
 ('cna','10k','Mestre',0,2100,8,'[)'),
 ('cna','21k','Branca',7200,NULL,1,'[)'),
 ('cna','21k','Laranja',6600,7200,2,'[)'),
 ('cna','21k','Amarela',6300,6600,3,'[)'),
 ('cna','21k','Azul',6000,6300,4,'[)'),
 ('cna','21k','Vermelha',5400,6000,5,'[)'),
 ('cna','21k','Marrom',5100,5400,6,'[)'),
 ('cna','21k','Preta',4800,5100,7,'[)'),
 ('cna','21k','Mestre',0,4800,8,'[)'),
 ('cna','42k','Branca',14400,NULL,1,'[)'),
 ('cna','42k','Laranja',13500,14400,2,'[)'),
 ('cna','42k','Amarela',12600,13500,3,'[)'),
 ('cna','42k','Azul',11700,12600,4,'[)'),
 ('cna','42k','Vermelha',10800,11700,5,'[)'),
 ('cna','42k','Marrom',9900,10800,6,'[)'),
 ('cna','42k','Preta',9000,9900,7,'[)'),
 ('cna','42k','Mestre',0,9000,8,'[)')) t
), base AS (
 SELECT r.sexo,r.percurso,extract(epoch FROM r.tempo_total) AS segundos,r.pcd,e.tipo_corrida,e.ranking,
 CASE WHEN r.percurso=5 THEN '5k' WHEN r.percurso=10 THEN '10k' WHEN r.percurso<22 THEN '21k' ELSE '42k' END AS distancia
 FROM public.tb_resultados r JOIN public.tb_evento_corridas e USING(id_evento) CROSS JOIN parametros p
 WHERE e.pais='BR' AND e.data_final>=p.inicio AND e.data_final<p.fim_exclusivo
 AND r.status_final=0 AND r.homologado IS TRUE AND r.concluinte IS TRUE AND r.tempo_total>TIME '00:00:00'
 AND (r.percurso IN(5,10) OR r.percurso>=21 AND r.percurso<22 OR r.percurso>=42 AND r.percurso<43)
), classificados AS (
 SELECT l.indicador,l.distancia,l.faixa,l.ordem,b.sexo
 FROM base b JOIN limites l ON l.distancia=b.distancia AND b.segundos<@numrange(l.minimo,l.maximo,l.fronteiras)
 AND (l.indicador='performance' AND b.tipo_corrida='rua'
 OR l.indicador='cna' AND b.pcd IS FALSE AND (b.ranking IS NULL OR b.ranking<>'false')
 AND (b.percurso IN(5,10) OR b.percurso BETWEEN 21 AND 21.1 OR b.percurso BETWEEN 42 AND 42.2))
), contagens AS (
 SELECT indicador,distancia,faixa,ordem,'geral' AS segmento,count(*) AS total FROM classificados GROUP BY indicador,distancia,faixa,ordem
 UNION ALL SELECT indicador,distancia,faixa,ordem,sexo,count(*) FROM classificados WHERE sexo IN('F','M') GROUP BY indicador,distancia,faixa,ordem,sexo
), segmentos AS (SELECT column1 AS segmento FROM (VALUES ('geral'),('F'),('M')) t),
completos AS (
 SELECT l.*,s.segmento,coalesce(c.total,0) AS total FROM limites l CROSS JOIN segmentos s
 LEFT JOIN contagens c ON c.indicador=l.indicador AND c.distancia=l.distancia AND c.faixa=l.faixa AND c.segmento=s.segmento
 WHERE l.indicador='performance' OR s.segmento='geral'
), finais AS (
 SELECT *,sum(total) OVER(PARTITION BY indicador,distancia,segmento) AS denominador FROM completos
)
SELECT indicador,distancia,faixa,ordem,segmento,total,denominador,
 total*100.0/nullif(denominador,0) AS percentual,minimo,maximo,fronteiras,
 CASE WHEN fronteiras='[)' THEN
 CASE WHEN maximo IS NULL THEN '≥ '||to_char(minimo::double precision*INTERVAL '1 second','HH24:MI:SS')
 WHEN minimo=0 THEN '> 00:00:00 e < '||to_char(maximo::double precision*INTERVAL '1 second','HH24:MI:SS')
 ELSE '≥ '||to_char(minimo::double precision*INTERVAL '1 second','HH24:MI:SS')||' e < '||to_char(maximo::double precision*INTERVAL '1 second','HH24:MI:SS') END
 ELSE CASE WHEN maximo IS NULL THEN '> '||to_char(minimo::double precision*INTERVAL '1 second','HH24:MI:SS')
 ELSE '> '||to_char(minimo::double precision*INTERVAL '1 second','HH24:MI:SS')||' e ≤ '||to_char(maximo::double precision*INTERVAL '1 second','HH24:MI:SS') END END AS intervalo
FROM finais ORDER BY indicador,distancia,segmento,ordem
