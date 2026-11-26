WITH authorized AS (SELECT p.id,p.codigo,p.titulo,p.tipo,p.ano,p.publicacao_id,w.payload
        FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=p.publicacao_id AND w.ano=p.ano
        WHERE p.codigo='previa-2026-q3' AND p.status='ACTIVE' AND p.ano=2026), selected AS (
            SELECT a.*,
                (SELECT coalesce(jsonb_agg(
                    CASE WHEN s->>'id'='maratonas_destaques' THEN s || jsonb_build_object('valores',
                        (SELECT jsonb_agg(v ORDER BY vo) FROM jsonb_array_elements(s->'valores') WITH ORDINALITY AS vals(v,vo)
                         WHERE v->>'rotulo' IN ('Top 10 soma','Mulheres')))
                    ELSE s END ORDER BY so),'[]'::jsonb)
                 FROM jsonb_array_elements(a.payload->'series') WITH ORDINALITY AS all_series(s,so)
                 WHERE s->>'id' !~ '^(inscricoes_|cna_|maratonas_revisao_|performance_42k_)'
                   AND s->>'id' NOT IN ('maratonas_cadastro','variacoes_a_z')) AS selected_series
            FROM authorized a
        ), delivery AS (
            SELECT s.*,
                (SELECT coalesce(jsonb_agg(c ORDER BY co),'[]'::jsonb)
                 FROM jsonb_array_elements(s.payload->'comparacoes') WITH ORDINALITY AS comparisons(c,co)
                 WHERE s.selected_series @> jsonb_build_array(jsonb_build_object('id',c->>'serie'))
                   AND (c->>'serie'<>'maratonas_destaques' OR c->>'categoria' IN ('Top 10 soma','Mulheres'))) AS selected_comparisons
            FROM selected s
        ) SELECT id,codigo,titulo,tipo,ano,publicacao_id,CAST(payload || jsonb_build_object(
            'series',selected_series,
            'comparacoes',selected_comparisons,
            'conciliacao',(SELECT coalesce(jsonb_object_agg(status,n),'{}'::jsonb) FROM (
                SELECT c->>'status' AS status,count(*) AS n FROM jsonb_array_elements(selected_comparisons) c
                WHERE c->>'status' IS NOT NULL GROUP BY c->>'status') counts),
            'meta',(payload->'meta') - ARRAY['inscricoes','inscricoes_geral','maratonas_revisao','maratonas_cadastro','maratonas_referencia_externa','notebook_fontes']
                || jsonb_build_object('escopo_editorial',jsonb_build_object(
                    'versao','q3-20261010-v1','produto',codigo,'publicacao_fonte',publicacao_id,
                    'criterio','Prévia profissional Jan–Set com recortes revisados. Consultas e congelamentos originais preservados no notebook.',
                    'temas_anuais_previstos',jsonb_build_array('Preços de inscrição, categorias, kits e lotes','Ritmo nacional dos 42 km e faixas de desempenho','Calendário completo de janeiro a dezembro'),
                    'ressalva','Temas previstos para a edição anual, sujeitos à revisão das fontes. Não integram os números nem as exportações desta prévia.'))
            ) AS text) AS payload_json FROM delivery