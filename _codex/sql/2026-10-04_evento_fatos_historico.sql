-- Apply with the guarded release: seo-fact-change-log-20261004/release.py.
-- No backfill: a stored change is not proof that a fact was verified.
CREATE TABLE public.tb_evento_fatos_historico (
    id_historico bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    registrado_em timestamptz NOT NULL DEFAULT clock_timestamp(),
    entidade text NOT NULL CHECK (entidade IN ('evento','percurso')),
    id_entidade integer NOT NULL,
    id_evento integer NOT NULL,
    id_evento_anterior integer,
    operacao text NOT NULL CHECK (operacao IN ('INSERT','UPDATE','DELETE')),
    alteracoes jsonb NOT NULL CHECK (jsonb_typeof(alteracoes) = 'object' AND alteracoes <> '{}'::jsonb)
);
CREATE INDEX tb_evento_fatos_historico_evento_idx
    ON public.tb_evento_fatos_historico (id_evento, registrado_em DESC, id_historico DESC);
CREATE INDEX tb_evento_fatos_historico_evento_anterior_idx
    ON public.tb_evento_fatos_historico (id_evento_anterior, registrado_em DESC, id_historico DESC)
    WHERE id_evento_anterior IS NOT NULL AND id_evento_anterior <> id_evento;
COMMENT ON TABLE public.tb_evento_fatos_historico IS
    'Alteracoes publicas do cadastro desde a implantacao; nao implica revisao factual, fonte conferida ou identificacao do operador. Sem backfill.';
REVOKE ALL ON TABLE public.tb_evento_fatos_historico FROM PUBLIC;
REVOKE ALL ON SEQUENCE public.tb_evento_fatos_historico_id_historico_seq FROM PUBLIC;

CREATE FUNCTION public.registra_evento_fatos_historico()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog
AS $history$
DECLARE
    antes jsonb := '{}'::jsonb;
    depois jsonb := '{}'::jsonb;
    diferencas jsonb := '{}'::jsonb;
    campos text[];
    campo text;
    tipo text;
    entidade_id integer;
    evento_id integer;
    evento_anterior integer;
BEGIN
    IF TG_TABLE_SCHEMA <> 'public' OR TG_NARGS <> 0 OR TG_WHEN <> 'AFTER' OR TG_LEVEL <> 'ROW' THEN
        RAISE EXCEPTION 'Unsupported factual history trigger';
    END IF;
    IF TG_TABLE_NAME = 'tb_evento_corridas' THEN
        tipo := 'evento';
        campos := ARRAY['id_evento','nome_evento','tag','data_inicial','data_final','cidade','estado','pais','endereco','coordenadas','categorias','tipo_corrida','status_evento','url_hotsite','url_regulamento','url_inscricao','ativo'];
    ELSIF TG_TABLE_NAME = 'tb_evento_corridas_percursos' THEN
        tipo := 'percurso';
        campos := ARRAY['id_evento_percurso','id_evento','percurso_evento','unidade_de_medida','data_percurso','hora_largada','hora_corte','tipo_corrida'];
    ELSE
        RAISE EXCEPTION 'Unsupported factual history table';
    END IF;
    IF TG_OP <> 'INSERT' THEN antes := to_jsonb(OLD); END IF;
    IF TG_OP <> 'DELETE' THEN depois := to_jsonb(NEW); END IF;
    FOREACH campo IN ARRAY campos LOOP
        IF TG_OP <> 'UPDATE' OR antes->campo IS DISTINCT FROM depois->campo THEN
            diferencas := diferencas || jsonb_build_object(campo,
                jsonb_build_object('antes', antes->campo, 'depois', depois->campo));
        END IF;
    END LOOP;
    IF diferencas = '{}'::jsonb THEN RETURN NULL; END IF;
    evento_id := COALESCE((depois->>'id_evento')::integer, (antes->>'id_evento')::integer);
    evento_anterior := (antes->>'id_evento')::integer;
    entidade_id := CASE WHEN tipo = 'evento' THEN evento_id
        ELSE COALESCE((depois->>'id_evento_percurso')::integer,(antes->>'id_evento_percurso')::integer) END;
    INSERT INTO public.tb_evento_fatos_historico
        (entidade,id_entidade,id_evento,id_evento_anterior,operacao,alteracoes)
    VALUES (tipo,entidade_id,evento_id,evento_anterior,TG_OP,diferencas);
    RETURN NULL; -- AFTER trigger: never rewrites the originating row.
END;
$history$;

CREATE TRIGGER trg_evento_fatos_historico
AFTER INSERT OR UPDATE OR DELETE ON public.tb_evento_corridas
FOR EACH ROW EXECUTE FUNCTION public.registra_evento_fatos_historico();
CREATE TRIGGER trg_percurso_fatos_historico
AFTER INSERT OR UPDATE OR DELETE ON public.tb_evento_corridas_percursos
FOR EACH ROW EXECUTE FUNCTION public.registra_evento_fatos_historico();
REVOKE ALL ON FUNCTION public.registra_evento_fatos_historico() FROM PUBLIC;
