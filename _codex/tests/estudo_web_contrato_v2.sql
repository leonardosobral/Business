-- Integration test: always roll back its temporary test executions.
BEGIN;
DO $test$
DECLARE base jsonb; changed jsonb; result_doc jsonb; rid bigint; rejected boolean; i integer;
BEGIN
 SELECT result->'rows'->0->'payload' INTO base FROM estudo.notebook_runs WHERE id=35;
 IF base IS NULL THEN RAISE EXCEPTION 'Fixture ausente'; END IF;
 PERFORM estudo.web_payload_conferido(2025,32);
 PERFORM estudo.web_payload_conferido(2026,33);
 PERFORM estudo.web_payload_conferido(2025,35);
 FOR i IN 1..4 LOOP
  changed:=CASE i
   WHEN 1 THEN jsonb_set(base,'{meta,contrato_versao}','3')
   WHEN 2 THEN jsonb_set(base,'{series,0,valores,0,valor}','"Referencia alterada"')
   WHEN 3 THEN jsonb_set(base,'{comparacoes}',(base->'comparacoes')||jsonb_build_array(base->'comparacoes'->0))
   WHEN 4 THEN base||jsonb_build_object('campo_nao_permitido','teste') END;
  result_doc:=jsonb_build_object('columns',jsonb_build_array('payload'),'rows',jsonb_build_array(jsonb_build_object('payload',changed)));
  INSERT INTO estudo.notebook_runs(cell_id,cell_version,sql_text,sql_sha256,executed_by,status,result,row_count)
   SELECT cell_id,cell_version,sql_text,sql_sha256,executed_by,'ok',result_doc,1 FROM estudo.notebook_runs WHERE id=35 RETURNING id INTO rid;
  UPDATE estudo.notebook_runs SET frozen=true,frozen_by=139,title='Teste revertido do contrato' WHERE id=rid;
  rejected:=false;
  BEGIN PERFORM estudo.web_payload_conferido(2025,rid); EXCEPTION WHEN OTHERS THEN rejected:=true; END;
  IF NOT rejected THEN RAISE EXCEPTION 'Contrato aceitou alteracao invalida %',i; END IF;
 END LOOP;
 rejected:=false;
 BEGIN UPDATE estudo.web_base_versoes SET payload=payload WHERE ano=2025 AND versao=2; EXCEPTION WHEN OTHERS THEN rejected:=true; END;
 IF NOT rejected THEN RAISE EXCEPTION 'Nova referencia nao e imutavel'; END IF;
END;$test$;

ROLLBACK;
