        ), paired_source AS (
            SELECT r.id,r.cell_id,r.cell_version,jsonb_extract_path(r.result,'rows','0','payload') AS summary,
                a.payload AS publication
            FROM authorized a
            CROSS JOIN LATERAL jsonb_array_elements(coalesce(jsonb_extract_path(a.payload,'meta','notebook_fontes'),'[]'::jsonb)) f
            JOIN estudo.notebook_runs r ON r.id=(f->>'execucao')::bigint
                AND r.cell_id=387 AND r.cell_version=(f->>'revisao')::integer
            WHERE f->>'celula'='387' AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1
                AND a.publicacao_id=41 AND jsonb_extract_path_text(a.payload,'meta','corte')='2026-09-30'
                AND jsonb_extract_path_text(a.payload,'meta','periodo_inicio')='2026-01-01'
            LIMIT 1
        ), paired_public AS (
            SELECT jsonb_extract_path(result,'rows','0','payload','release') AS narrative
            FROM estudo.notebook_runs
            WHERE id=239 AND cell_id=420 AND cell_version=5 AND frozen AND status='ok' AND NOT truncated AND row_count=1
        ), paired_checked AS (
            SELECT p.*
            FROM paired_source p CROSS JOIN paired_public n
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
                'narrativa',jsonb_build_object('celula',420,'execucao',239,'revisao',5),
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
