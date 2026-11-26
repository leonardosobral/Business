-- Eventos públicos com id_localidade ausente na dimensão.
-- O cruzamento é por ID; cidade/UF aparecem somente para revisão humana.
SELECT f.id_evento,e.nome_evento,e.cidade,e.estado,f.id_localidade,count(*) AS participacoes_sem_dimensao,
 current_timestamp AS coletado_em
FROM public.tbbi_fat_perfil_br_2026 f
LEFT JOIN public.tbbi_dim_localidade l ON l.id_localidade=f.id_localidade
LEFT JOIN public.tb_evento_corridas e ON e.id_evento=f.id_evento
WHERE l.id_localidade IS NULL
GROUP BY f.id_evento,e.nome_evento,e.cidade,e.estado,f.id_localidade
ORDER BY participacoes_sem_dimensao DESC,f.id_evento LIMIT 20;
