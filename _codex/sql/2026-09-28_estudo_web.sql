-- Public packages are copied from explicitly selected frozen notebook runs.
-- Existing snapshots and operational tables are never modified.
CREATE TABLE estudo.web_bases (
 ano integer PRIMARY KEY CHECK(ano IN(2025,2026)), payload jsonb NOT NULL, contrato jsonb NOT NULL
);
CREATE TABLE estudo.web_destinos (
 ano integer PRIMARY KEY REFERENCES estudo.web_bases(ano),
 cell_id bigint NOT NULL UNIQUE REFERENCES estudo.notebook_cells(id),
 publicacao_id bigint, versao integer NOT NULL DEFAULT 0
);
CREATE TABLE estudo.web_publicacoes (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 ano integer NOT NULL REFERENCES estudo.web_destinos(ano),
 run_id bigint NOT NULL REFERENCES estudo.notebook_runs(id),
 payload jsonb NOT NULL, nota text NOT NULL,
 publicado_por bigint NOT NULL, publicado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(ano,id)
);
ALTER TABLE estudo.web_destinos ADD CONSTRAINT web_destino_publicacao_fk FOREIGN KEY(ano,publicacao_id) REFERENCES estudo.web_publicacoes(ano,id);
CREATE TRIGGER web_publicacao_imutavel BEFORE UPDATE OR DELETE ON estudo.web_publicacoes FOR EACH ROW EXECUTE FUNCTION estudo.notebook_immutable();
CREATE TRIGGER web_publicacao_no_truncate BEFORE TRUNCATE ON estudo.web_publicacoes FOR EACH STATEMENT EXECUTE FUNCTION estudo.notebook_immutable();
CREATE TRIGGER web_base_imutavel BEFORE UPDATE OR DELETE ON estudo.web_bases FOR EACH ROW EXECUTE FUNCTION estudo.notebook_immutable();
CREATE TRIGGER web_base_no_truncate BEFORE TRUNCATE ON estudo.web_bases FOR EACH STATEMENT EXECUTE FUNCTION estudo.notebook_immutable();

CREATE FUNCTION estudo.web_json_valido(v jsonb,s jsonb) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path=pg_catalog AS $$
DECLARE t text:=jsonb_typeof(v); k text; x jsonb;
BEGIN
 IF v IS NULL OR NOT (s->'types' ? t) THEN RETURN false; END IF;
 IF t='object' THEN
   FOR k,x IN SELECT * FROM jsonb_each(v) LOOP
     IF NOT (s->'keys' ? k) OR NOT estudo.web_json_valido(x,s->'keys'->k) THEN RETURN false; END IF;
   END LOOP;
   FOR k IN SELECT jsonb_array_elements_text(coalesce(s->'required','[]')) LOOP
     IF NOT (v ? k) THEN RETURN false; END IF;
   END LOOP;
 ELSIF t='array' THEN
   IF jsonb_array_length(v)>2000 THEN RETURN false; END IF;
   FOR x IN SELECT jsonb_array_elements(v) LOOP
     IF NOT estudo.web_json_valido(x,s->'items') THEN RETURN false; END IF;
   END LOOP;
 ELSIF t='string' AND length(v#>>'{}')>10000 THEN RETURN false;
 END IF;
 RETURN true;
END;$$;
CREATE FUNCTION estudo.web_payload_conferido(p_ano integer,p_run bigint) RETURNS jsonb
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
DECLARE d estudo.web_destinos; r estudo.notebook_runs; b estudo.web_bases; p jsonb; a jsonb; z jsonb;
BEGIN
 SELECT * INTO d FROM estudo.web_destinos WHERE ano=p_ano;
 SELECT * INTO r FROM estudo.notebook_runs WHERE id=p_run;
 IF d.ano IS NULL OR r.id IS NULL OR r.cell_id<>d.cell_id OR r.status<>'ok' OR NOT r.frozen OR r.truncated OR r.row_count<>1
   OR r.result->'columns'<>'["payload"]'::jsonb OR jsonb_array_length(r.result->'rows')<>1 THEN
  RAISE EXCEPTION 'Escolha um congelamento completo da celula de saida desta edicao';
 END IF;
 p:=r.result->'rows'->0->'payload';
 SELECT * INTO b FROM estudo.web_bases WHERE ano=p_ano;
 IF octet_length(p::text)>5000000 OR NOT estudo.web_json_valido(p,b.contrato) OR p->'meta'->>'ano'<>p_ano::text THEN
  RAISE EXCEPTION 'Pacote fora do contrato publico';
 END IF;
 -- Definitions/categories stay fixed in this contract; editorial notes may evolve.
 SELECT jsonb_agg(x-'ressalva' ORDER BY x->>'id') INTO a FROM jsonb_array_elements(p->'series') x;
 SELECT jsonb_agg(x-'ressalva' ORDER BY x->>'id') INTO z FROM jsonb_array_elements(b.payload->'series') x;
 IF a IS DISTINCT FROM z THEN RAISE EXCEPTION 'A referencia e as categorias da edicao devem ser preservadas'; END IF;
 SELECT jsonb_agg(jsonb_build_array(x->'serie',x->'categoria') ORDER BY x->>'serie',x->>'categoria') INTO a FROM jsonb_array_elements(p->'comparacoes') x;
 SELECT jsonb_agg(jsonb_build_array(x->'serie',x->'categoria') ORDER BY x->>'serie',x->>'categoria') INTO z FROM jsonb_array_elements(b.payload->'comparacoes') x;
 IF a IS DISTINCT FROM z THEN RAISE EXCEPTION 'Categorias ausentes ou duplicadas no pacote'; END IF;
 RETURN p;
END;$$;
CREATE FUNCTION estudo.publicar_web(p_ano integer,p_run bigint,p_esperada bigint,p_admin bigint,p_nota text) RETURNS bigint
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
DECLARE d estudo.web_destinos; p jsonb; pid bigint;
BEGIN
 IF p_admin IS NULL OR p_admin<=0 OR length(btrim(p_nota)) NOT BETWEEN 1 AND 2000 THEN RAISE EXCEPTION 'Administrador e nota obrigatorios'; END IF;
 SELECT * INTO d FROM estudo.web_destinos WHERE ano=p_ano FOR UPDATE;
 IF d.ano IS NULL THEN RAISE EXCEPTION 'Edicao inexistente'; END IF;
 IF EXISTS(SELECT 1 FROM estudo.web_publicacoes WHERE id=d.publicacao_id AND run_id=p_run) THEN RETURN d.publicacao_id; END IF;
 IF coalesce(d.publicacao_id,0)<>p_esperada THEN RAISE EXCEPTION 'A publicacao mudou. Recarregue antes de publicar'; END IF;
 p:=estudo.web_payload_conferido(p_ano,p_run);
  INSERT INTO estudo.web_publicacoes(ano,run_id,payload,nota,publicado_por) VALUES(p_ano,p_run,p,p_nota,p_admin) RETURNING id INTO pid;
 UPDATE estudo.web_destinos SET publicacao_id=pid,versao=versao+1 WHERE ano=p_ano;
 RETURN pid;
END;$$;
CREATE VIEW estudo.web_payloads AS
 SELECT d.ano,p.payload || jsonb_build_object('publicacao',jsonb_build_object('versao',d.versao,'publicado_em',p.publicado_em,'execucao',p.run_id,'nota',p.nota)) AS payload
 FROM estudo.web_destinos d JOIN estudo.web_publicacoes p ON p.id=d.publicacao_id AND p.ano=d.ano;
REVOKE ALL ON estudo.web_bases,estudo.web_destinos,estudo.web_publicacoes,estudo.web_payloads FROM PUBLIC;
REVOKE ALL ON FUNCTION estudo.web_json_valido(jsonb,jsonb),estudo.web_payload_conferido(integer,bigint),estudo.publicar_web(integer,bigint,bigint,bigint,text) FROM PUBLIC;
GRANT USAGE ON SCHEMA estudo TO runner;
GRANT SELECT ON estudo.web_payloads TO runner;
GRANT SELECT ON estudo.web_bases TO estudo_reader;
