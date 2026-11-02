WITH ev AS (
 SELECT e.id_evento,e.nome_evento,e.tag,e.cidade,e.estado,e.data_inicial,e.data_final,e.url_resultado,e.url_wiclax,e.id_agrega_evento,a.tag AS family_tag,a.tipo_agregacao,
 (SELECT coalesce(sum(r.concluintes),0) FROM tb_resultados_resumo r WHERE r.id_evento=e.id_evento) AS concluintes,
 (SELECT count(*) FROM tb_evento_foco_vinculos f WHERE f.id_evento=e.id_evento AND f.status='active') AS galleries,
 EXISTS(SELECT 1 FROM tb_badges b WHERE b.id_evento=e.id_evento AND b.badge='foco' AND b.percurso=0) AS foco_badge
 FROM tb_evento_corridas e LEFT JOIN tb_agrega_eventos a ON a.id_agrega_evento=e.id_agrega_evento
 WHERE e.ativo=true AND coalesce(e.data_final,e.data_inicial) < current_date
 AND (a.tag IN ('maratona-internacional-de-floripa','maratona-de-curitiba','maratona-monumental-de-brasilia','maratona-internacional-de-porto-alegre') OR e.id_evento IN (SELECT id_evento FROM tb_agregadores_eventos WHERE agregador_tag IN ('estacoes','live-run-xp')))
 ORDER BY coalesce(e.data_final,e.data_inicial) DESC LIMIT 80
) SELECT jsonb_build_object('events',(SELECT jsonb_agg(to_jsonb(ev)) FROM ev))::text AS payload