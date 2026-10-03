-- Casos de fronteira da regra v1. Só dados sintéticos; mesma classificação das consultas anuais.
WITH casos AS(SELECT column1 AS caso,column2::int4range AS idade_range,column3::date AS nascimento,column4 AS esperado_idade,column5 AS esperado_geracao FROM(VALUES ('idade13','[13,14)',NULL,'Menos de 14','Menos de 14'),
('idade14','[14,15)',NULL,'14–19','Alfa'),
('idade15','[15,16)',NULL,'14–19','Alfa'),
('idade16','[16,17)',NULL,'14–19','Geração Z'),
('idade19','[19,20)',NULL,'14–19','Geração Z'),
('idade20','[20,21)',NULL,'20–24','Geração Z'),
('idade28','[28,29)',NULL,'25–29','Geração Z'),
('idade29','[29,30)',NULL,'25–29','Millennials'),
('idade44','[44,45)',NULL,'40–44','Millennials'),
('idade45','[45,46)',NULL,'45–49','Geração X'),
('idade60','[60,61)',NULL,'60–64','Geração X'),
('idade61','[61,62)',NULL,'60–64','Boomers'),
('idade79','[79,80)',NULL,'70+','Boomers'),
('idade80','[80,81)',NULL,'70+','Anteriores a 1946'),
('geracao25a30','[25,30)',NULL,'25–29','Geração indeterminada'),
('sobreposicao25a31','[25,31)',NULL,'Idade indeterminada','Geração indeterminada'),
('fronteira14','[13,15)',NULL,'Idade indeterminada','Geração indeterminada'),
('ampla','[0,100)',NULL,'Idade indeterminada','Geração indeterminada'),
('semidade',NULL,NULL,'Sem idade informada','Sem idade informada'),
('vazio','empty',NULL,'Idade indeterminada','Geração indeterminada'),
('negativo','[-1,20)',NULL,'Idade indeterminada','Geração indeterminada'),
('aberto70','[70,)',NULL,'70+','Geração indeterminada'),
('aberto80','[80,)',NULL,'70+','Anteriores a 1946'),
('abertoinferior','(,20)',NULL,'Idade indeterminada','Geração indeterminada'),
('idadeimpossivel','[121,122)',NULL,'Idade indeterminada','Geração indeterminada'),
('nascimentoprioritario','[25,29)','1996-12-31','25–29','Millennials'),
('nascimentosemfaixa',NULL,'1980-12-31','45–49','Geração X'),
('nascimento120',NULL,'1905-01-01','70+','Anteriores a 1946'),
('nascimentofuturo','[30,35)','2026-01-01','30–34','Millennials'),
('nascimento121','[30,35)','1904-01-01','30–34','Millennials'),
('nascimentomenor14',NULL,'2012-12-31','Menos de 14','Menos de 14'))t),
agrupados AS(SELECT *,1 AS n,'geral'::text AS sexo,NULL::text AS distancia,
 2025-extract(year FROM nascimento)::integer AS idade_31dez,
 coalesce(nascimento<=DATE '2025-06-01' AND 2025-extract(year FROM nascimento)::integer BETWEEN 0 AND 120,false) AS nascimento_plausivel FROM casos),
normalizados AS (
 SELECT *,CASE WHEN nascimento_plausivel THEN int4range(idade_31dez,idade_31dez+1,'[)')
 WHEN idade_range IS NOT NULL AND idade_range<>'empty'::int4range
 AND lower(idade_range)>=0 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN idade_range END AS faixa,
 CASE WHEN nascimento_plausivel THEN 'Nascimento plausível'
 WHEN idade_range IS NULL THEN 'Sem idade informada'
 WHEN idade_range<>'empty'::int4range AND lower(idade_range)>=0
 AND (upper(idade_range) IS NULL OR upper(idade_range)<=121) THEN 'Faixa da categoria'
 ELSE 'Dado inválido' END AS origem
 FROM agrupados
), faixas_idade AS (
 SELECT column1 AS ordem,column2 AS categoria,column3 AS faixa FROM (VALUES
 (0,'Menos de 14',int4range(0,14,'[)')),
 (1,'14–19',int4range(14,20,'[)')),(2,'20–24',int4range(20,25,'[)')),
 (3,'25–29',int4range(25,30,'[)')),(4,'30–34',int4range(30,35,'[)')),
 (5,'35–39',int4range(35,40,'[)')),(6,'40–44',int4range(40,45,'[)')),
 (7,'45–49',int4range(45,50,'[)')),(8,'50–54',int4range(50,55,'[)')),
 (9,'55–59',int4range(55,60,'[)')),(10,'60–64',int4range(60,65,'[)')),
 (11,'65–69',int4range(65,70,'[)')),(12,'70+',int4range(70,NULL,'[)'))) t
), faixas_geracao AS (
 SELECT column1 AS ordem,column2 AS categoria,column3 AS faixa FROM (VALUES
 (0,'Menos de 14',int4range(0,14,'[)')),
 (1,'Alfa',int4range(14,2025-2010+1,'[)')),
 (2,'Geração Z',int4range(2025-2010+1,2025-1997+1,'[)')),
 (3,'Millennials',int4range(2025-1997+1,2025-1981+1,'[)')),
 (4,'Geração X',int4range(2025-1981+1,2025-1965+1,'[)')),
 (5,'Boomers',int4range(2025-1965+1,2025-1946+1,'[)')),
 (6,'Anteriores a 1946',int4range(2025-1946+1,NULL,'[)'))) t
), classificados AS (
 SELECT n.*,
 coalesce((SELECT f.categoria FROM faixas_idade f WHERE n.faixa<@f.faixa),
 CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Idade indeterminada' END) AS idade,
 coalesce((SELECT f.categoria FROM faixas_geracao f WHERE n.faixa<@f.faixa),
 CASE WHEN origem='Sem idade informada' THEN 'Sem idade informada' ELSE 'Geração indeterminada' END) AS geracao
 FROM normalizados n
)
SELECT caso,idade,geracao,esperado_idade,esperado_geracao,origem,idade_31dez,
 idade=esperado_idade AND geracao=esperado_geracao AS confere FROM classificados ORDER BY caso;
