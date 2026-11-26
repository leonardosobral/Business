-- LEFT JOIN conserva a população da fato e mede ausências nas sete dimensões.
WITH cruzamentos AS MATERIALIZED (
 SELECT count(*) AS linhas,
 d.id_data IS NULL AS sem_data,l.id_localidade IS NULL AS sem_localidade,
 g.id_geracao IS NULL AS sem_geracao,t.id_faixa IS NULL AS sem_faixa,
 c.id_cbat_categoria IS NULL AS sem_cbat,o.id_organizacao IS NULL AS sem_organizacao,
 n.id_cronometragem IS NULL AS sem_cronometragem
 FROM public.tbbi_fat_perfil_br_2026 f
 LEFT JOIN public.tbbi_dim_data d ON d.id_data=f.id_data
 LEFT JOIN public.tbbi_dim_localidade l ON l.id_localidade=f.id_localidade
 LEFT JOIN public.tbbi_dim_geracoes g ON g.id_geracao=f.id_geracao
 LEFT JOIN public.tbbi_dim_faixas t ON t.id_faixa=f.id_faixa
 LEFT JOIN public.tbbi_dim_cbat_categorias c ON c.id_cbat_categoria=f.id_cbat_categoria
 LEFT JOIN public.tbbi_dim_organizacao_2026 o ON o.id_organizacao=f.id_organizador
 LEFT JOIN public.tbbi_dim_cronometragem n ON n.id_cronometragem=f.id_cronometrador
 GROUP BY 2,3,4,5,6,7,8
), totais AS (
 SELECT sum(linhas) AS linhas_apos_left_join,
 coalesce(sum(linhas) FILTER(WHERE sem_data),0) AS sem_data,
 coalesce(sum(linhas) FILTER(WHERE sem_localidade),0) AS sem_localidade,
 coalesce(sum(linhas) FILTER(WHERE sem_geracao),0) AS sem_geracao,
 coalesce(sum(linhas) FILTER(WHERE sem_faixa),0) AS sem_faixa,
 coalesce(sum(linhas) FILTER(WHERE sem_cbat),0) AS sem_cbat,
 coalesce(sum(linhas) FILTER(WHERE sem_organizacao),0) AS sem_organizacao,
 coalesce(sum(linhas) FILTER(WHERE sem_cronometragem),0) AS sem_cronometragem,
 coalesce(sum(linhas) FILTER(WHERE sem_data OR sem_localidade OR sem_geracao OR sem_faixa
 OR sem_cbat OR sem_organizacao OR sem_cronometragem),0) AS descartadas_pela_view
 FROM cruzamentos
)
SELECT *,round(descartadas_pela_view*100.0/nullif(linhas_apos_left_join,0),4) AS percentual_descartado,
 current_timestamp AS coletado_em FROM totais;
