WITH events AS (
 SELECT e.id_evento,e.nome_evento,e.tag,e.cidade,e.estado,e.data_inicial,e.data_final,e.url_resultado,e.url_inscricao,e.id_agrega_evento,a.tag AS family_tag,e.status_evento,e.obs_resultado,
 (SELECT count(*) FROM tb_resultados r WHERE r.id_evento=e.id_evento AND r.origem_resultado <> 'validacao_documental' AND r.status_final < 3) AS public_results,
 (SELECT count(*) FROM tb_evento_foco_vinculos f WHERE f.id_evento=e.id_evento AND f.status='active') AS galleries
 FROM tb_evento_corridas e LEFT JOIN tb_agrega_eventos a ON a.id_agrega_evento=e.id_agrega_evento
 WHERE e.ativo=true AND a.tag='maratona-de-aracaju'
 ORDER BY e.data_inicial DESC LIMIT 6
) SELECT jsonb_build_object('events',(SELECT jsonb_agg(to_jsonb(events)) FROM events))::text AS payload
