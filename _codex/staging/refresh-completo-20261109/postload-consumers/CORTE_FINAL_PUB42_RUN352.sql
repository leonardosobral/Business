-- DBA review artifact only. This helper never executes this transaction.
-- Private unreferenced publication exists; all active pointers remain old until this transaction.
-- Deploy and verify the compatible runtime before executing in DataGrip.
BEGIN;
SET LOCAL lock_timeout='5s';
DO $consumer_cutover$
DECLARE touched integer;
BEGIN
 PERFORM ano FROM estudo.web_destinos WHERE ano IN(2025,2026) ORDER BY ano FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND cell_id=249 AND publicacao_id=37 AND versao=19) THEN RAISE EXCEPTION '2025 destination changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND cell_id=251 AND publicacao_id=41 AND versao=22) THEN RAISE EXCEPTION '2026 technical destination changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_publicacoes WHERE id=41 AND run_id=233 AND payload->'meta'->>'contrato_versao'='17') THEN RAISE EXCEPTION 'Previous contract/publication changed'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_destinos WHERE publicacao_id=42) OR EXISTS(SELECT 1 FROM estudo.produtos WHERE publicacao_id=42) THEN RAISE EXCEPTION 'Candidate publication already referenced'; END IF;
 IF encode(sha256(convert_to(pg_get_viewdef('estudo.lancamento_publico'::regclass,true),'UTF8')),'hex')<>'ee05be7bd4b56685eb01cd0e9c7fcc3a4a0f54fc8a80604e59b52717157252e4' THEN RAISE EXCEPTION 'Public view changed; recapture baseline'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_class WHERE oid='estudo.lancamento_publico'::regclass AND coalesce(reloptions,'{}') @> ARRAY['security_barrier=true']) THEN RAISE EXCEPTION 'Public view barrier changed'; END IF;
 PERFORM id FROM estudo.produtos WHERE id=1 AND codigo='previa-2026-q3' AND status='ACTIVE' AND publicacao_id=41 FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Product pointer changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=352 AND cell_id=420 AND cell_version=7 AND frozen AND status='ok' AND NOT truncated AND row_count=1 AND encode(sha256(convert_to((result->'rows'->0->'payload')::text,'UTF8')),'hex')='584fee688f5826365ed33534eb7da4b6256c9037ef937bdd4b6ed8fab2180dd8') THEN RAISE EXCEPTION 'Target run 352 changed'; END IF; IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=329 AND cell_id=387 AND cell_version=3 AND frozen AND status='ok' AND NOT truncated AND row_count=1) THEN RAISE EXCEPTION 'Target run 329 changed'; END IF; IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=353 AND cell_id=418 AND cell_version=3 AND frozen AND status='ok' AND NOT truncated AND row_count=1) THEN RAISE EXCEPTION 'Target run 353 changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_publicacoes p JOIN estudo.notebook_runs r ON r.id=p.run_id WHERE p.id=42 AND p.ano=2026 AND p.run_id=351 AND r.cell_id=251 AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1 AND encode(sha256(convert_to(p.payload::text,'UTF8')),'hex')='a04b8ac9649bb5a230c0c3e36b07fcd5be75add96a474d0aa842632f19d45a85' AND p.payload=r.result->'rows'->0->'payload' AND p.payload=estudo.web_payload_conferido(2026,351) AND p.payload->'meta'->>'contrato_versao'='18' AND p.payload->'meta'->>'corte'='2026-09-30' AND p.payload->'meta'->>'periodo_inicio'='2026-01-01' AND EXISTS(SELECT 1 FROM jsonb_array_elements(p.payload->'meta'->'notebook_fontes') f WHERE f->>'celula'='387' AND f->>'execucao'='329' AND f->>'revisao'='3')) THEN RAISE EXCEPTION 'Professional publication/source link changed'; END IF;
 IF NOT EXISTS(
   SELECT 1 FROM estudo.web_publicacoes p
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
     AND round((p.payload#>>'{comparativo,provas,meses_completos,variacao_cadastradas}')::numeric,1)=(n.release#>>'{historias,provas,variacao_percentual}')::numeric
 ) THEN RAISE EXCEPTION 'Comparative rates or public release contract changed'; END IF;
 IF (SELECT r.id FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id WHERE c.source_key='bqc-2026-anual-output' AND NOT c.archived AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1 AND r.result->'columns'='["payload"]'::jsonb AND jsonb_array_length(r.result->'rows')=1 ORDER BY r.frozen_at DESC,r.id DESC LIMIT 1) IS DISTINCT FROM 353 THEN RAISE EXCEPTION 'Annual latest-frozen changed'; END IF;
 UPDATE estudo.web_destinos SET publicacao_id=42,versao=versao+1 WHERE ano=2026 AND cell_id=251 AND publicacao_id=41 AND versao=22;
 GET DIAGNOSTICS touched=ROW_COUNT;
 IF touched<>1 THEN RAISE EXCEPTION 'Technical destination cutover did not update exactly one row'; END IF;
 UPDATE estudo.produtos SET publicacao_id=42 WHERE id=1 AND codigo='previa-2026-q3' AND status='ACTIVE' AND publicacao_id=41;
 GET DIAGNOSTICS touched=ROW_COUNT;
 IF touched<>1 THEN RAISE EXCEPTION 'Product cutover did not update exactly one row'; END IF;
END;$consumer_cutover$;
CREATE OR REPLACE VIEW estudo.lancamento_publico WITH (security_barrier=true) AS
SELECT r.result->'rows'->0->'payload' AS payload FROM estudo.notebook_runs r
JOIN estudo.produtos p ON p.codigo='previa-2026-q3' AND p.status='ACTIVE' AND p.publicacao_id=42
WHERE r.id=352 AND r.cell_id=420 AND r.cell_version=7 AND r.frozen AND r.status='ok' AND NOT r.truncated AND r.row_count=1;
DO $consumer_postcheck$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND cell_id=249 AND publicacao_id=37 AND versao=19) THEN RAISE EXCEPTION '2025 destination changed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND cell_id=251 AND publicacao_id=42 AND versao=23) THEN RAISE EXCEPTION 'Technical destination final mismatch'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.produtos WHERE id=1 AND publicacao_id=42 AND status='ACTIVE') THEN RAISE EXCEPTION 'Product final mismatch'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.lancamento_publico WHERE encode(sha256(convert_to(payload::text,'UTF8')),'hex')='584fee688f5826365ed33534eb7da4b6256c9037ef937bdd4b6ed8fab2180dd8') THEN RAISE EXCEPTION 'Public view final mismatch'; END IF;
END;$consumer_postcheck$;
SELECT payload FROM estudo.lancamento_publico;
COMMIT;
