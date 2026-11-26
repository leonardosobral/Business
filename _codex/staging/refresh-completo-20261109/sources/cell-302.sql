-- Testes sintéticos; não lê dados individuais nem altera tabelas.
WITH datas AS(SELECT column1 AS caso,column2 AS data,column3 AS esperado FROM(VALUES
 ('jan',DATE '2026-01-01','Verão'),('fev',DATE '2026-02-28','Verão'),('mar',DATE '2026-03-01','Outono'),('abr',DATE '2026-04-30','Outono'),('mai',DATE '2026-05-31','Outono'),
 ('jun',DATE '2026-06-01','Inverno'),('jul',DATE '2026-07-31','Inverno'),('ago',DATE '2026-08-31','Inverno'),('set',DATE '2026-09-01','Primavera'),('out',DATE '2026-10-31','Primavera'),('nov',DATE '2026-11-30','Primavera'),('dez',DATE '2026-12-01','Verão'),('virada-anterior',DATE '2025-12-31','Verão'),('bissexto',DATE '2024-02-29','Verão'))t),
meses AS(SELECT caso,esperado,CASE WHEN extract(month FROM data) IN(12,1,2) THEN 'Verão' WHEN extract(month FROM data) BETWEEN 3 AND 5 THEN 'Outono' WHEN extract(month FROM data) BETWEEN 6 AND 8 THEN 'Inverno' ELSE 'Primavera' END AS observado FROM datas),
competidores AS(SELECT column1 AS grupo,column2 AS prova,column3 AS valor,column4 AS esperado FROM(VALUES
 ('sem-empate','A',1,1),('sem-empate','B',2,2),('sem-empate','C',3,3),('sem-empate','D',4,4),
 ('ouro-empatado','A',1,1),('ouro-empatado','B',1,1),('ouro-empatado','C',2,3),
 ('prata-empatada','A',1,1),('prata-empatada','B',2,2),('prata-empatada','C',2,2),('prata-empatada','D',3,4),
 ('bronze-empatado','A',1,1),('bronze-empatado','B',2,2),('bronze-empatado','C',3,3),('bronze-empatado','D',3,3),
 ('maior-contagem','A',-500,1),('maior-contagem','B',-100,2),('maior-contagem','C',-50,3),
 ('tempo-exibido-empatado','A',10800,1),('tempo-exibido-empatado','B',10800,1),('tempo-exibido-empatado','C',10801,3))t),
ranks AS(SELECT *,rank() OVER(PARTITION BY grupo ORDER BY valor) AS observado FROM competidores),
checks AS(SELECT 'estacao-'||caso AS caso,esperado,observado,esperado=observado AS passou FROM meses
 UNION ALL SELECT grupo||'-'||prova,esperado::text,observado::text,esperado=observado FROM ranks)
SELECT * FROM checks ORDER BY caso;
