CREATE OR REPLACE FUNCTION estudo.web_payload_conferido(p_ano integer, p_run bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog'
AS $function$
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
END;$function$
