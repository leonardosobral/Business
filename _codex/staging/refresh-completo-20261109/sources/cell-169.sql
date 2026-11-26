-- Gerações — população da view BI 2025
SELECT nome_geracao,coalesce(sexo,'N/A') AS sexo,count(*) AS total,
round(count(*)*100.0/nullif(sum(count(*)) OVER(PARTITION BY sexo),0),2) AS percentual_dentro_sexo
FROM public.vwbi_fat_perfil_br_2025 GROUP BY nome_geracao,sexo ORDER BY sexo,total DESC;