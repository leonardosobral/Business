CREATE TEMP TABLE tb_evento_corridas (
 id_evento integer PRIMARY KEY, nome_evento text,tag text,data_inicial date,data_final date,
 cidade text,estado text,pais text,endereco text,coordenadas text,categorias text,tipo_corrida text,
 status_evento text,url_hotsite text,url_regulamento text,url_inscricao text,ativo boolean,
 descricao text,obs text,data_processamento timestamp
);
CREATE TEMP TABLE tb_evento_corridas_percursos (
 id_evento_percurso integer PRIMARY KEY,id_evento integer,percurso_evento numeric,
 unidade_de_medida text,data_percurso date,hora_largada time,hora_corte time,tipo_corrida text,
 percurso_bloqueado boolean,mapa text
);
CREATE TEMP TABLE checks (name text,passed boolean);
CREATE FUNCTION pg_temp.assert_check(n text,ok boolean) RETURNS void LANGUAGE plpgsql AS $check$
BEGIN INSERT INTO pg_temp.checks VALUES(n,COALESCE(ok,false));END;$check$;
-- Migration and temporary trigger copy inserted here by the executor.
-- MIGRATION
INSERT INTO pg_temp.tb_evento_corridas VALUES(1,'Fixture','fixture',DATE '2027-01-10',DATE '2027-01-11','Cidade','SP','BR','Local',NULL,'5km','rua','confirmado','https://example.com/evento',NULL,NULL,true,'PRIVATE DESCRIPTION','PRIVATE NOTE',now());
SELECT pg_temp.assert_check('event insert captured', (SELECT count(*)=1 FROM pg_temp.tb_evento_fatos_historico WHERE entidade='evento' AND id_entidade=1 AND operacao='INSERT'));
SELECT pg_temp.assert_check('insert before null', (SELECT alteracoes->'data_inicial'->'antes'='null'::jsonb AND alteracoes->'data_inicial'->>'depois'='2027-01-10' FROM pg_temp.tb_evento_fatos_historico WHERE id_historico=1));
SELECT pg_temp.assert_check('private fields absent', NOT EXISTS(SELECT 1 FROM pg_temp.tb_evento_fatos_historico WHERE alteracoes::text LIKE '%PRIVATE%' OR alteracoes ?| ARRAY['obs','descricao','data_processamento']));
UPDATE pg_temp.tb_evento_corridas SET data_inicial=data_inicial,descricao='PRIVATE DESCRIPTION 2',data_processamento=now();
SELECT pg_temp.assert_check('irrelevant update ignored',(SELECT count(*)=1 FROM pg_temp.tb_evento_fatos_historico));
UPDATE pg_temp.tb_evento_corridas SET data_inicial='2027-01-12',data_final='2027-01-12',endereco='Novo local',status_evento='adiado' WHERE id_evento=1;
SELECT pg_temp.assert_check('single update row and exact fields',(SELECT operacao='UPDATE' AND (SELECT count(*) FROM jsonb_object_keys(alteracoes))=4 FROM pg_temp.tb_evento_fatos_historico WHERE id_historico=2));
SELECT pg_temp.assert_check('date before and after',(SELECT alteracoes->'data_inicial'=jsonb_build_object('antes','2027-01-10','depois','2027-01-12') FROM pg_temp.tb_evento_fatos_historico WHERE id_historico=2));
SELECT pg_temp.assert_check('location and status',(SELECT alteracoes->'endereco'->>'antes'='Local' AND alteracoes->'endereco'->>'depois'='Novo local' AND alteracoes->'status_evento'->>'depois'='adiado' FROM pg_temp.tb_evento_fatos_historico WHERE id_historico=2));
UPDATE pg_temp.tb_evento_corridas SET url_regulamento='https://example.com/regulamento';
UPDATE pg_temp.tb_evento_corridas SET url_regulamento=NULL;
SELECT pg_temp.assert_check('null transitions captured',(SELECT count(*)=2 FROM pg_temp.tb_evento_fatos_historico WHERE alteracoes ? 'url_regulamento' AND operacao='UPDATE'));
SELECT pg_temp.assert_check('nullable after is json null',(SELECT alteracoes->'url_regulamento'->'depois'='null'::jsonb FROM pg_temp.tb_evento_fatos_historico ORDER BY id_historico DESC LIMIT 1));
INSERT INTO pg_temp.tb_evento_corridas_percursos VALUES(20,1,5,'km','2027-01-10','07:00','10:00','rua',false,'PRIVATE MAP');
SELECT pg_temp.assert_check('route insert captured',(SELECT count(*)=1 FROM pg_temp.tb_evento_fatos_historico WHERE entidade='percurso' AND id_entidade=20 AND id_evento=1 AND operacao='INSERT'));
UPDATE pg_temp.tb_evento_corridas_percursos SET percurso_bloqueado=true,mapa='CHANGED PRIVATE MAP';
SELECT pg_temp.assert_check('technical route change ignored',(SELECT count(*)=1 FROM pg_temp.tb_evento_fatos_historico WHERE entidade='percurso'));
UPDATE pg_temp.tb_evento_corridas_percursos SET data_percurso='2027-01-12',hora_largada='08:00';
SELECT pg_temp.assert_check('route date and time',(SELECT alteracoes->'data_percurso'->>'antes'='2027-01-10' AND alteracoes->'data_percurso'->>'depois'='2027-01-12' AND alteracoes->'hora_largada'->>'depois'='08:00:00' AND (SELECT count(*) FROM jsonb_object_keys(alteracoes))=2 FROM pg_temp.tb_evento_fatos_historico WHERE entidade='percurso' AND operacao='UPDATE'));
UPDATE pg_temp.tb_evento_corridas_percursos SET id_evento=2;
SELECT pg_temp.assert_check('route reassignment preserves both events',(SELECT id_evento=2 AND id_evento_anterior=1 AND alteracoes->'id_evento'=jsonb_build_object('antes',1,'depois',2) FROM pg_temp.tb_evento_fatos_historico ORDER BY id_historico DESC LIMIT 1));
DELETE FROM pg_temp.tb_evento_corridas_percursos WHERE id_evento_percurso=20;
INSERT INTO pg_temp.tb_evento_corridas_percursos VALUES(21,2,5,'km','2027-01-12','08:00','10:00','rua',false,NULL);
SELECT pg_temp.assert_check('route replacement distinct IDs',(SELECT count(*)=1 FROM pg_temp.tb_evento_fatos_historico WHERE id_entidade=20 AND operacao='DELETE') AND (SELECT count(*)=1 FROM pg_temp.tb_evento_fatos_historico WHERE id_entidade=21 AND operacao='INSERT'));
DO $rollback$
DECLARE n bigint;
BEGIN
 SELECT count(*) INTO n FROM pg_temp.tb_evento_fatos_historico;
 BEGIN
  UPDATE pg_temp.tb_evento_corridas SET status_evento='cancelado';
  IF (SELECT count(*) FROM pg_temp.tb_evento_fatos_historico)<>n+1 THEN RAISE EXCEPTION 'missing capture';END IF;
  RAISE EXCEPTION 'intentional test rollback' USING ERRCODE='P0002';
 EXCEPTION WHEN SQLSTATE 'P0002' THEN NULL;END;
 PERFORM pg_temp.assert_check('rollback removes audit row',(SELECT count(*) FROM pg_temp.tb_evento_fatos_historico)=n);
 PERFORM pg_temp.assert_check('rollback restores source',(SELECT status_evento='adiado' FROM pg_temp.tb_evento_corridas WHERE id_evento=1));
END;$rollback$;
DELETE FROM pg_temp.tb_evento_corridas WHERE id_evento=1;
SELECT pg_temp.assert_check('event delete records old public values',(SELECT alteracoes->'data_inicial'->>'antes'='2027-01-12' AND alteracoes->'data_inicial'->'depois'='null'::jsonb FROM pg_temp.tb_evento_fatos_historico WHERE entidade='evento' AND operacao='DELETE'));
SELECT pg_temp.assert_check('history survives deletion',(SELECT count(*)>1 FROM pg_temp.tb_evento_fatos_historico WHERE id_evento=1));
SELECT pg_temp.assert_check('timestamps populated',NOT EXISTS(SELECT 1 FROM pg_temp.tb_evento_fatos_historico WHERE registrado_em IS NULL OR registrado_em > clock_timestamp()));
SELECT pg_temp.assert_check('no source verified claim',NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=pg_my_temp_schema()::regnamespace::text AND table_name='tb_evento_fatos_historico' AND column_name IN ('verified','checked_at','operator','ip')));
SELECT pg_temp.assert_check('runner has no direct history access',NOT has_table_privilege('runner','pg_temp.tb_evento_fatos_historico','SELECT') AND NOT has_table_privilege('runner','pg_temp.tb_evento_fatos_historico','INSERT'));
SELECT pg_temp.assert_check('public execute revoked',NOT EXISTS(SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(p.proacl) a WHERE p.oid='pg_temp.registra_evento_fatos_historico()'::regprocedure AND a.grantee=0));
-- Exercise bulk capture without writing production rows.
INSERT INTO pg_temp.tb_evento_corridas(id_evento,nome_evento,data_inicial,data_final,ativo)
SELECT i,'Fixture batch','2027-02-01','2027-02-01',true FROM generate_series(100,1099) i;
UPDATE pg_temp.tb_evento_corridas SET data_final='2027-02-02' WHERE id_evento>=100;
SELECT pg_temp.assert_check('bulk updates captured',(SELECT count(*)=1000 FROM pg_temp.tb_evento_fatos_historico WHERE id_evento>=100 AND operacao='UPDATE'));
SELECT pg_temp.assert_check('bulk source unchanged beyond date',(SELECT count(*)=1000 FROM pg_temp.tb_evento_corridas WHERE id_evento>=100 AND data_inicial='2027-02-01' AND data_final='2027-02-02' AND nome_evento='Fixture batch'));

UPDATE pg_temp.tb_evento_corridas SET id_evento=2100 WHERE id_evento=1099;
SELECT pg_temp.assert_check('event id changes retain old id',(SELECT id_evento=2100 AND id_evento_anterior=1099 AND alteracoes->'id_evento'=jsonb_build_object('antes',1099,'depois',2100) FROM pg_temp.tb_evento_fatos_historico ORDER BY id_historico DESC LIMIT 1));
UPDATE pg_temp.tb_evento_corridas_percursos SET id_evento_percurso=22 WHERE id_evento_percurso=21;
SELECT pg_temp.assert_check('route id changes captured',(SELECT id_entidade=22 AND alteracoes->'id_evento_percurso'=jsonb_build_object('antes',21,'depois',22) FROM pg_temp.tb_evento_fatos_historico ORDER BY id_historico DESC LIMIT 1));
CREATE TEMP TABLE forbidden_history_source(id_evento integer);
CREATE TRIGGER reject_wrong_table AFTER INSERT ON pg_temp.forbidden_history_source FOR EACH ROW EXECUTE FUNCTION pg_temp.registra_evento_fatos_historico();
DO $invalid$ DECLARE rejected boolean:=false;BEGIN
 BEGIN INSERT INTO pg_temp.forbidden_history_source VALUES(1);
 EXCEPTION WHEN OTHERS THEN
  IF SQLERRM <> 'Unsupported factual history table' THEN RAISE;END IF;
  rejected:=true;
 END;
 PERFORM pg_temp.assert_check('reject unexpected source table',rejected AND NOT EXISTS(SELECT 1 FROM pg_temp.forbidden_history_source));
END;$invalid$;
