BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
SELECT pg_advisory_xact_lock(9282026,5);
DO $verify$
BEGIN
 IF md5(pg_get_functiondef('estudo.web_payload_conferido(integer,bigint)'::regprocedure))<>'0a345253e5ee950a88295e8cc2d38e66' THEN RAISE EXCEPTION 'Validador alterado; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2025 AND versao=4 AND md5(payload::text)='b9dacff16c223e23d9daab945f1202dd' AND md5(contrato::text)='db0683b67e68b1a55e8806401b1a4538') THEN RAISE EXCEPTION 'Contrato anterior 2025 mudou'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2025 AND versao=5) THEN RAISE EXCEPTION 'Contrato novo 2025 existe; conferir recibo'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND publicacao_id=15) THEN RAISE EXCEPTION 'Publicacao 2025 mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE id=249 AND version=18) THEN RAISE EXCEPTION 'Saida 2025 mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=95 AND cell_id=249 AND cell_version=18 AND status='ok' AND frozen AND NOT truncated AND row_count=1) THEN RAISE EXCEPTION 'Pacote 2025 incompleto'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2026 AND versao=2 AND md5(payload::text)='a34f99351921c1e8a6bc66273ee37312' AND md5(contrato::text)='441ef735ec62bbfb326ecc5b83301da3') THEN RAISE EXCEPTION 'Contrato anterior 2026 mudou'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2026 AND versao=3) THEN RAISE EXCEPTION 'Contrato novo 2026 existe; conferir recibo'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND publicacao_id=13) THEN RAISE EXCEPTION 'Publicacao 2026 mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE id=251 AND version=12) THEN RAISE EXCEPTION 'Saida 2026 mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=96 AND cell_id=251 AND cell_version=12 AND status='ok' AND frozen AND NOT truncated AND row_count=1) THEN RAISE EXCEPTION 'Pacote 2026 incompleto'; END IF;
END;
$verify$;
-- Contratos novos; anteriores intactos. Em 2026, o resumo agora conta também o status existente coletado_notebook.
INSERT INTO estudo.web_base_versoes(ano,versao,payload,contrato) SELECT 2025,5,r.result->'rows'->0->'payload',b.contrato FROM estudo.notebook_runs r CROSS JOIN estudo.web_base_versoes b WHERE r.id=95 AND b.ano=2025 AND b.versao=4;
INSERT INTO estudo.web_base_versoes(ano,versao,payload,contrato) SELECT 2026,3,r.result->'rows'->0->'payload',jsonb_set(b.contrato,'{keys,conciliacao,keys,coletado_notebook}','{"types":["number"]}'::jsonb,true) FROM estudo.notebook_runs r CROSS JOIN estudo.web_base_versoes b WHERE r.id=96 AND b.ano=2026 AND b.versao=2;
DO $validate$
BEGIN
 PERFORM estudo.web_payload_conferido(2025,95);
 PERFORM estudo.web_payload_conferido(2026,96);
 PERFORM estudo.web_payload_conferido(2025,86);
 PERFORM estudo.web_payload_conferido(2026,81);
 PERFORM estudo.web_payload_conferido(2025,80);
 PERFORM estudo.web_payload_conferido(2025,45);
END;
$validate$;
COMMIT;
