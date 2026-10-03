BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
SELECT pg_advisory_xact_lock(9282026,4);
DO $verify$
BEGIN
 IF md5(pg_get_functiondef('estudo.web_payload_conferido(integer,bigint)'::regprocedure))<>'0a345253e5ee950a88295e8cc2d38e66' THEN RAISE EXCEPTION 'Validador alterado; reler antes de aplicar'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2025 AND versao=3 AND md5(payload::text)='22a0ca78324f5fe88f5dddaeb8be9e19' AND md5(contrato::text)='db0683b67e68b1a55e8806401b1a4538') THEN RAISE EXCEPTION 'Contrato anterior alterado; reler'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2025 AND versao=4) THEN RAISE EXCEPTION 'Contrato 4 ja existe; conferir recibo antes de repetir'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND publicacao_id=12) THEN RAISE EXCEPTION 'Publicacao anterior mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE id=249 AND version=15) THEN RAISE EXCEPTION 'Saida atual mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=85 AND cell_id=249 AND cell_version=15 AND status='ok' AND frozen AND NOT truncated AND row_count=1 AND sql_sha256='8aaef3a5c6a7b9bdee4e832dd0ba7da634b06e6b64df3a8ca770de87f335c47b') THEN RAISE EXCEPTION 'Congelamento completo esperado ausente'; END IF;
END;
$verify$;
-- Contrato aditivo: mesmas regras de tipos, mais cinco series atuais sem valores historicos.
INSERT INTO estudo.web_base_versoes(ano,versao,payload,contrato)
SELECT 2025,4,r.result->'rows'->0->'payload',b.contrato
FROM estudo.notebook_runs r CROSS JOIN estudo.web_base_versoes b
WHERE r.id=85 AND b.ano=2025 AND b.versao=3;
DO $validate$
BEGIN
 PERFORM estudo.web_payload_conferido(2025,85);
 PERFORM estudo.web_payload_conferido(2025,80);
 PERFORM estudo.web_payload_conferido(2026,81);
END;
$validate$;
COMMIT;
