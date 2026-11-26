SELECT jsonb_build_object(
 'rates_and_public_contract',EXISTS(SELECT 1 FROM estudo.web_publicacoes p
   JOIN estudo.notebook_runs paired ON paired.id=329
   JOIN estudo.notebook_runs public_run ON public_run.id=352
   CROSS JOIN LATERAL (SELECT paired.result->'rows'->0->'payload' AS summary, public_run.result->'rows'->0->'payload' AS document) raw
   CROSS JOIN LATERAL (SELECT raw.document->'release' AS release) n
   WHERE p.id=42 AND raw.document->'ok'='true'::jsonb
     AND raw.document - ARRAY['ok','release']='{}'::jsonb
     AND n.release - ARRAY['title','periodo_inicio','periodo_fim','coleta','indicadores','historias']='{}'::jsonb
     AND n.release->>'periodo_inicio'='2026-01-01' AND n.release->>'periodo_fim'='2026-09-30'
     AND n.release->>'coleta' ~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}$'
     AND jsonb_array_length(n.release->'indicadores')=6
     AND (SELECT count(DISTINCT i->>'id') FROM jsonb_array_elements(n.release->'indicadores') i)=6
     AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(n.release->'indicadores') i
       WHERE i->>'id' NOT IN('femininas','millennials','distancias_curtas','interior','terceiro_trimestre','concentracao_porte')
         OR i - ARRAY['id','valor','label','descricao','universo','comparativo']<>'{}'::jsonb
         OR (i->'comparativo') - ARRAY['anterior','nota']<>'{}'::jsonb)
     AND (n.release->'historias') - ARRAY['pareadas','provas','resultados','mulheres']='{}'::jsonb
     AND (n.release->'historias'->'mulheres') - ARRAY['anterior','atual','diferenca_pp']='{}'::jsonb
     AND NOT EXISTS(SELECT 1 FROM jsonb_each(n.release->'historias') h WHERE h.key<>'mulheres' AND h.value - 'variacao_percentual'<>'{}'::jsonb)
     AND raw.summary->>'periodo'='Jan–Set de2025 e2026'
     AND (raw.summary#>>'{coorte_pareada,pares}')::bigint>0
     AND (raw.summary#>>'{coorte_pareada,concluintes_2025}')::bigint>0
     AND (raw.summary#>>'{coorte_pareada,concluintes_2026}')::bigint>=0
     AND round((raw.summary#>>'{coorte_pareada,variacao_pct}')::numeric,1)=(n.release#>>'{historias,pareadas,variacao_percentual}')::numeric
     AND round((p.payload#>>'{comparativo,provas,meses_completos,variacao_cadastradas}')::numeric,1)=(n.release#>>'{historias,provas,variacao_percentual}')::numeric),
 'destination2026',EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND cell_id=251 AND publicacao_id=41 AND versao=22),
 'destination2025',EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND cell_id=249 AND publicacao_id=37 AND versao=19),
 'candidate_contract18',EXISTS(SELECT 1 FROM estudo.web_publicacoes WHERE id=42 AND run_id=351 AND payload->'meta'->>'contrato_versao'='18'),
 'candidate_active_references',(SELECT count(*) FROM estudo.web_destinos WHERE publicacao_id=42)+(SELECT count(*) FROM estudo.produtos WHERE publicacao_id=42),
 'old_public_view',encode(sha256(convert_to(pg_get_viewdef('estudo.lancamento_publico'::regclass,true),'UTF8')),'hex')='ee05be7bd4b56685eb01cd0e9c7fcc3a4a0f54fc8a80604e59b52717157252e4'
)::text AS payload