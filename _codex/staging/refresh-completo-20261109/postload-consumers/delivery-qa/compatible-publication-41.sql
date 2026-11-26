-- Read-only QA virtual authorized relation; no REQUEST identity, product or destination mutation.
SELECT payload_json::text AS payload FROM (WITH authorized AS (SELECT p.id,p.codigo,p.titulo,p.tipo,p.ano,w.id AS publicacao_id,w.payload
        FROM estudo.produtos p JOIN estudo.web_publicacoes w ON w.id=41 AND w.ano=p.ano
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
        ), paired_source AS (
            SELECT r.id,r.cell_id,r.cell_version,jsonb_extract_path(r.result,'rows','0','payload') AS summary,
                a.publicacao_id,a.payload AS publication
            FROM authorized a
            CROSS JOIN LATERAL jsonb_array_elements(CASE
                WHEN jsonb_typeof(jsonb_extract_path(a.payload,'meta','notebook_fontes'))='array'
                THEN jsonb_extract_path(a.payload,'meta','notebook_fontes') ELSE '[]'::jsonb END) f
            JOIN estudo.notebook_runs r ON r.id=CASE WHEN f->>'execucao' ~ '^[1-9][0-9]{0,17}$'
                    THEN (f->>'execucao')::bigint ELSE NULL END
                AND r.cell_id=387 AND r.cell_version=CASE WHEN f->>'revisao' ~ '^[1-9][0-9]{0,8}$'
                    THEN (f->>'revisao')::integer ELSE NULL END
            WHERE f->>'celula'='387' AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1
                AND a.publicacao_id IN (41,42) AND jsonb_extract_path_text(a.payload,'meta','corte')='2026-09-30'
                AND jsonb_extract_path_text(a.payload,'meta','periodo_inicio')='2026-01-01'
            LIMIT 1
        ), paired_public AS (
            SELECT approved_pairs.publication_id,r.id AS narrative_run,r.cell_version AS narrative_revision,
                jsonb_extract_path(r.result,'rows','0','payload','release') AS narrative
            FROM (VALUES (41::bigint,239::bigint,5::integer),
                         (42::bigint,352::bigint,7::integer)) approved_pairs(publication_id,run_id,revision)
            JOIN estudo.notebook_runs r ON r.id=approved_pairs.run_id AND r.cell_id=420 AND r.cell_version=approved_pairs.revision
            WHERE r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1
        ), paired_checked AS (
            SELECT p.*,n.narrative_run,n.narrative_revision
            FROM paired_source p JOIN paired_public n ON n.publication_id=p.publicacao_id
            WHERE p.summary->>'periodo'='Jan–Set de2025 e2026'
              AND (jsonb_extract_path_text(p.summary,'coorte_pareada','pares')) ~ '^[1-9][0-9]*$'
              AND (jsonb_extract_path_text(p.summary,'coorte_pareada','concluintes_2025')) ~ '^[1-9][0-9]*$'
              AND (jsonb_extract_path_text(p.summary,'coorte_pareada','concluintes_2026')) ~ '^[0-9]+$'
              AND n.narrative->>'periodo_inicio'='2026-01-01' AND n.narrative->>'periodo_fim'='2026-09-30'
              AND CASE WHEN jsonb_extract_path_text(p.summary,'coorte_pareada','variacao_pct') ~ '^-?[0-9]+([.][0-9]+)?$'
                    THEN round((jsonb_extract_path_text(p.summary,'coorte_pareada','variacao_pct'))::numeric,1)::text
                    ELSE NULL END = jsonb_extract_path_text(n.narrative,'historias','pareadas','variacao_percentual')
              AND CASE WHEN jsonb_extract_path_text(p.publication,'comparativo','provas','meses_completos','variacao_cadastradas') ~ '^-?[0-9]+([.][0-9]+)?$'
                    THEN round((jsonb_extract_path_text(p.publication,'comparativo','provas','meses_completos','variacao_cadastradas'))::numeric,1)::text
                    ELSE NULL END = jsonb_extract_path_text(n.narrative,'historias','provas','variacao_percentual')
        ), paired_context AS (
            SELECT (SELECT jsonb_build_object('status','disponivel','celula',cell_id,'execucao',id,'revisao',cell_version,
                'coletado_em',summary->'coletado_em','periodo',summary->'periodo','metodologia',summary->'metodologia',
                'fontes',summary->'fontes','coorte',summary->'coorte_pareada',
                'narrativa',jsonb_build_object('celula',420,'execucao',narrative_run,'revisao',narrative_revision),
                'ressalva','Variação da soma de participações nas edições pareadas; não é a média das variações por prova. O pareamento não certifica captura completa nem isola crescimento real. Não conta pessoas únicas.')
                FROM paired_checked) AS metadata,
                (SELECT 'Notebook · célula ' || cell_id || ', revisão ' || cell_version || ', execução congelada ' || id
                    || '; coleta ' || left(summary->>'coletado_em',10) || '; fontes ' || (summary->'fontes')::text
                    FROM paired_checked) AS provenance,
                (SELECT summary FROM paired_checked) AS summary
        ), paired_metrics AS (
            SELECT v.*,c.provenance,c.metadata,
                'Participações das mesmas edições em 01/01–30/09 de 2025 e 2026; não são pessoas únicas. ' || coalesce(c.metadata->>'ressalva','Fonte congelada em revisão; ausência preservada, sem zero.') AS population
            FROM paired_context c CROSS JOIN LATERAL (VALUES
                ('comparativo_pareadas_concluintes','participacoes',0,'2025',jsonb_extract_path(c.summary,'coorte_pareada','concluintes_2025'),jsonb_extract_path(c.summary,'coorte_pareada','concluintes_2025'),jsonb_extract_path(c.summary,'totais','2025'),'Participações elegíveis no ano · Jan–Set'),
                ('comparativo_pareadas_concluintes','participacoes',0,'2026',jsonb_extract_path(c.summary,'coorte_pareada','concluintes_2026'),jsonb_extract_path(c.summary,'coorte_pareada','concluintes_2026'),jsonb_extract_path(c.summary,'totais','2026'),'Participações elegíveis no ano · Jan–Set'),
                ('comparativo_pareadas_variacao','percentual',1,'2026 / 2025',jsonb_extract_path(c.summary,'coorte_pareada','variacao_pct'),jsonb_extract_path(c.summary,'coorte_pareada','delta'),jsonb_extract_path(c.summary,'coorte_pareada','concluintes_2025'),'Concluintes de 2025 nas edições pareadas'),
                ('comparativo_pareadas_amostra','provas',0,'Pares de edições',jsonb_extract_path(c.summary,'coorte_pareada','pares'),jsonb_extract_path(c.summary,'coorte_pareada','pares'),NULL::jsonb,'Um par liga uma edição de cada ano')
            ) v(id,unit,decimals,label,value,count,denominator,base_label)
        ), paired_additions AS (
            SELECT coalesce((SELECT metadata FROM paired_context),jsonb_build_object('status','em_revisao',
                'ressalva','Comparativo das mesmas provas indisponível: confira a fonte congelada e sua conciliação com a narrativa pública. Ausência não significa zero.')) AS metadata,
                (SELECT jsonb_agg(s ORDER BY s->>'id') FROM (
                    SELECT jsonb_build_object('id',id,'unidade',unit,'casas_decimais',decimals,'pagina_pdf',NULL,
                        'ressalva','Edições pareadas por vínculo ou nome normalizado, cidade, UF, tipo, sazonalidade e unicidade. Mesma janela Jan–Set; a captura dos resultados pode variar. Soma de participações, não pessoas únicas.',
                        'valores',jsonb_agg(jsonb_build_object('rotulo',label,'valor',NULL) ORDER BY label)) s
                    FROM paired_metrics GROUP BY id,unit,decimals) defs) AS series,
                (SELECT jsonb_agg(jsonb_build_object('serie',id,'categoria',label,
                    'status',CASE WHEN metadata IS NULL THEN 'fonte_em_revisao' ELSE 'notebook_em_conciliacao' END,
                    'atual',jsonb_build_object('valor',value,'contagem',count,'denominador',denominator,
                        'fonte',provenance,'base_rotulo',base_label,'populacao',population,
                        'nota',coalesce(metadata->>'ressalva','Fonte congelada em revisão; ausência preservada, sem zero.')))
                    ORDER BY id,label) FROM paired_metrics) AS comparisons

        ) SELECT id,codigo,titulo,tipo,ano,publicacao_id,CAST(payload || jsonb_build_object(
            'series',selected_series || (SELECT series FROM paired_additions),
            'comparacoes',selected_comparisons || (SELECT comparisons FROM paired_additions),
            'conciliacao',(SELECT coalesce(jsonb_object_agg(status,n),'{}'::jsonb) FROM (
                SELECT c->>'status' AS status,count(*) AS n FROM jsonb_array_elements(selected_comparisons) c
                WHERE c->>'status' IS NOT NULL GROUP BY c->>'status') counts),
            'meta',(payload->'meta') - ARRAY['inscricoes','inscricoes_geral','maratonas_revisao','maratonas_cadastro','maratonas_referencia_externa','notebook_fontes']
                || jsonb_build_object('comparativo_pareado',(SELECT metadata FROM paired_additions),'escopo_editorial',jsonb_build_object(
                    'versao','q3-20261010-v1','produto',codigo,'publicacao_fonte',publicacao_id,
                    'criterio','Prévia profissional Jan–Set com recortes revisados. Consultas e congelamentos originais preservados no notebook.',
                    'temas_anuais_previstos',jsonb_build_array('Preços de inscrição, categorias, kits e lotes','Ritmo nacional dos 42 km e faixas de desempenho','Calendário completo de janeiro a dezembro'),
                    'ressalva','Temas previstos para a edição anual, sujeitos à revisão das fontes. Não integram os números nem as exportações desta prévia.'))
            ) AS text) AS payload_json FROM delivery) checked_delivery