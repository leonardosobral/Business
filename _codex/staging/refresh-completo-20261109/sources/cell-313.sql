-- Mesma classificação da auditoria, aplicada somente a dados sintéticos.
WITH casos AS(SELECT column1 AS caso,column2 AS ano,column3 AS nascimento,column4 AS idade_range,column5 AS esperado,column6 AS origem_esperada FROM(VALUES
('idade13',2025,'2012-01-01'::date,NULL::int4range,'Menos de 14','Nascimento plausível'),
('idade14',2025,'2011-12-31'::date,NULL::int4range,'14+ identificados','Nascimento plausível'),
('nasc_prioritario',2025,'2011-01-01'::date,'[0,14)'::int4range,'14+ identificados','Nascimento plausível'),
('futuro_fallback',2025,'2026-01-01'::date,'[14,20)'::int4range,'14+ identificados','Faixa da categoria'),
('nasc_futuro_no_ano',2025,'2025-12-31'::date,NULL::int4range,'Sem idade informada','Sem idade informada'),
('idade121',2025,'1904-01-01'::date,NULL::int4range,'Sem idade informada','Sem idade informada'),
('idade120',2025,'1905-01-01'::date,NULL::int4range,'14+ identificados','Nascimento plausível'),
('cat13',2025,NULL::date,'[13,14)'::int4range,'Menos de 14','Faixa da categoria'),
('cat14',2025,NULL::date,'[14,15)'::int4range,'14+ identificados','Faixa da categoria'),
('ampla14',2025,NULL::date,'[14,100)'::int4range,'14+ identificados','Faixa da categoria'),
('catcruza',2025,NULL::date,'[10,18)'::int4range,'Faixa cruza 14','Faixa da categoria'),
('catfecha14',2025,NULL::date,'[10,14]'::int4range,'Faixa cruza 14','Faixa da categoria'),
('cataberta14',2025,NULL::date,'(13,20]'::int4range,'14+ identificados','Faixa da categoria'),
('cat70mais',2025,NULL::date,'[70,)'::int4range,'14+ identificados','Faixa da categoria'),
('cat120mais',2025,NULL::date,'[120,)'::int4range,'14+ identificados','Faixa da categoria'),
('cat121mais',2025,NULL::date,'[121,)'::int4range,'Dado inválido','Dado inválido'),
('sem_inferior',2025,NULL::date,'(,20)'::int4range,'Dado inválido','Dado inválido'),
('negativa',2025,NULL::date,'[-1,20)'::int4range,'Dado inválido','Dado inválido'),
('vazia',2025,NULL::date,'empty'::int4range,'Dado inválido','Dado inválido'),
('ausente',2025,NULL::date,NULL::int4range,'Sem idade informada','Sem idade informada'),
('categoria_impossivel',2025,NULL::date,'[14,122)'::int4range,'Dado inválido','Dado inválido'),
('2026_14',2026,'2012-12-31'::date,NULL::int4range,'14+ identificados','Nascimento plausível'),
('2026_13',2026,'2013-01-01'::date,NULL::int4range,'Menos de 14','Nascimento plausível'))t),base AS(SELECT *,ano-extract(year FROM nascimento)::integer AS idade_31dez,coalesce(nascimento<=make_date(ano,9,26) AND ano-extract(year FROM nascimento)::integer BETWEEN 0 AND 120,false) AS nascimento_plausivel FROM casos),
normalizados AS (
 SELECT *,CASE WHEN nascimento_plausivel THEN int4range(idade_31dez,idade_31dez+1,'[)')
 WHEN idade_range IS NOT NULL AND idade_range<>'empty'::int4range AND lower(idade_range)>=0 AND lower(idade_range)<=120 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN idade_range END AS faixa,
 CASE WHEN nascimento_plausivel THEN 'Nascimento plausível'
 WHEN idade_range IS NULL THEN 'Sem idade informada'
 WHEN idade_range<>'empty'::int4range AND lower(idade_range)>=0 AND lower(idade_range)<=120 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN 'Faixa da categoria'
 ELSE 'Dado inválido' END AS origem
 FROM base
), classificados AS (
 SELECT *,CASE WHEN faixa IS NULL THEN CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Dado inválido' END
 WHEN faixa<@int4range(0,14,'[)') THEN 'Menos de 14'
 WHEN lower(faixa)>=14 THEN '14+ identificados'
 ELSE 'Faixa cruza 14' END AS corte14
 FROM normalizados
)
SELECT caso,corte14,origem,esperado,origem_esperada,corte14=esperado AND origem=origem_esperada AS ok FROM classificados ORDER BY caso;
