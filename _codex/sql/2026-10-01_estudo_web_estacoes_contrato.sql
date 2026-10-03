BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
SELECT pg_advisory_xact_lock(9282026,6);
DO $verify$
BEGIN
 IF md5(pg_get_functiondef('estudo.web_payload_conferido(integer,bigint)'::regprocedure))<>'0a345253e5ee950a88295e8cc2d38e66' THEN RAISE EXCEPTION 'Validador alterado; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2026 AND versao=3 AND md5(payload::text)='9718e2ff06aa901d2200fcd3a95ccace' AND md5(contrato::text)='c75dfb05f6f965754ab6b7e44e522b42') THEN RAISE EXCEPTION 'Baseline 2026 mudou; reler'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_base_versoes WHERE ano=2026 AND versao=4) THEN RAISE EXCEPTION 'Contrato 4 existe; conferir antes de repetir'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2026 AND publicacao_id=17) OR NOT EXISTS(SELECT 1 FROM estudo.web_destinos WHERE ano=2025 AND publicacao_id=16) THEN RAISE EXCEPTION 'Publicacao mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE id=251 AND version=13) OR NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE id=249 AND version=19) THEN RAISE EXCEPTION 'Saida mudou; reler'; END IF;
 IF NOT EXISTS(SELECT 1 FROM estudo.notebook_runs WHERE id=101 AND cell_id=251 AND cell_version=13 AND status='ok' AND frozen AND NOT truncated AND row_count=1) THEN RAISE EXCEPTION 'Pacote 2026 incompleto'; END IF;
END;
$verify$;
-- Acrescenta estacoes à baseline 2026 sem mudar o contrato estrutural nem o histórico.
INSERT INTO estudo.web_base_versoes(ano,versao,payload,contrato)
 SELECT 2026,4,r.result->'rows'->0->'payload',b.contrato FROM estudo.notebook_runs r CROSS JOIN estudo.web_base_versoes b WHERE r.id=101 AND b.ano=2026 AND b.versao=3;
DO $validate$
BEGIN
 PERFORM estudo.web_payload_conferido(2025,100);
 PERFORM estudo.web_payload_conferido(2026,101);
 PERFORM estudo.web_payload_conferido(2025,95);
 PERFORM estudo.web_payload_conferido(2026,96);
 PERFORM estudo.web_payload_conferido(2025,86);
 PERFORM estudo.web_payload_conferido(2026,81);
END;
$validate$;
COMMIT;
