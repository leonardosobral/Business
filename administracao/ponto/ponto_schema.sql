BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_ponto_jornadas (
    id bigserial PRIMARY KEY,
    id_usuario integer NOT NULL REFERENCES public.tb_usuarios(id),
    tipo varchar(10) NOT NULL CHECK (tipo IN ('trabalho', 'viagem')),
    estado varchar(12) NOT NULL CHECK (estado IN ('ativo', 'pausado', 'finalizado', 'cancelado')),
    dia_viagem date,
    minutos_viagem integer,
    versao integer NOT NULL DEFAULT 1,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now(),
    CHECK ((tipo = 'trabalho' AND dia_viagem IS NULL AND minutos_viagem IS NULL)
        OR (tipo = 'viagem' AND dia_viagem IS NOT NULL AND minutos_viagem BETWEEN 1 AND 1440
            AND estado IN ('finalizado', 'cancelado')))
);
CREATE UNIQUE INDEX IF NOT EXISTS ponto_uma_jornada_aberta
    ON public.tb_ponto_jornadas(id_usuario) WHERE estado IN ('ativo', 'pausado');
CREATE UNIQUE INDEX IF NOT EXISTS ponto_uma_viagem_por_dia
    ON public.tb_ponto_jornadas(id_usuario, dia_viagem) WHERE tipo = 'viagem' AND estado <> 'cancelado';
CREATE INDEX IF NOT EXISTS ponto_usuario_historico ON public.tb_ponto_jornadas(id_usuario, criado_em);

CREATE TABLE IF NOT EXISTS public.tb_ponto_periodos (
    id bigserial PRIMARY KEY,
    id_jornada bigint NOT NULL REFERENCES public.tb_ponto_jornadas(id),
    inicio timestamptz NOT NULL,
    fim timestamptz,
    CHECK (fim IS NULL OR fim > inicio)
);
CREATE INDEX IF NOT EXISTS ponto_periodos_jornada ON public.tb_ponto_periodos(id_jornada);
CREATE UNIQUE INDEX IF NOT EXISTS ponto_um_periodo_aberto
    ON public.tb_ponto_periodos(id_jornada) WHERE fim IS NULL;

CREATE TABLE IF NOT EXISTS public.tb_ponto_auditoria (
    id bigserial PRIMARY KEY,
    id_jornada bigint NOT NULL REFERENCES public.tb_ponto_jornadas(id),
    id_usuario integer NOT NULL REFERENCES public.tb_usuarios(id),
    acao varchar(20) NOT NULL,
    antes jsonb,
    depois jsonb NOT NULL,
    criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ponto_auditoria_jornada ON public.tb_ponto_auditoria(id_jornada, id);

CREATE OR REPLACE FUNCTION public.ponto_snapshot(p_id bigint) RETURNS jsonb
LANGUAGE sql STABLE AS $$
    SELECT to_jsonb(j) || jsonb_build_object('periodos', COALESCE((
        SELECT jsonb_agg(to_jsonb(p) ORDER BY p.inicio) FROM public.tb_ponto_periodos p WHERE p.id_jornada = j.id
    ), '[]'::jsonb)) FROM public.tb_ponto_jornadas j WHERE j.id = p_id;
$$;

-- All writes use this function: per-person serialization, ownership, optimistic
-- version checks and audit are in the same transaction. No SECURITY DEFINER.
CREATE OR REPLACE FUNCTION public.ponto_registrar(
    p_usuario integer, p_acao text, p_id bigint, p_versao integer, p_dados jsonb DEFAULT '{}'::jsonb
) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE
    v_j public.tb_ponto_jornadas%ROWTYPE;
    v_antes jsonb;
    v_id bigint;
    v_agora timestamptz;
    v_inicio timestamptz;
    v_fim timestamptz;
    v_dia date;
    v_de date;
    v_ate date;
    v_minutos integer;
    v_item jsonb;
    v_ids bigint[] := '{}';
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.tb_usuarios WHERE id = p_usuario AND is_admin = true) THEN
        RAISE EXCEPTION 'Acesso exclusivo para ADMIN.';
    END IF;
    PERFORM pg_advisory_xact_lock(70680, p_usuario);
    v_agora := clock_timestamp();

    IF p_acao NOT IN ('iniciar', 'pausar', 'retomar', 'finalizar', 'salvar', 'viagem', 'cancelar') THEN
        RAISE EXCEPTION 'Ação inválida.';
    END IF;
    IF p_id > 0 THEN
        SELECT * INTO v_j FROM public.tb_ponto_jornadas WHERE id = p_id AND id_usuario = p_usuario FOR UPDATE;
        IF NOT FOUND THEN RAISE EXCEPTION 'Registro não encontrado.'; END IF;
        IF v_j.versao <> p_versao OR v_j.estado = 'cancelado' THEN
            RAISE EXCEPTION 'Este registro mudou. Recarregue a página antes de continuar.';
        END IF;
        v_antes := public.ponto_snapshot(p_id);
    ELSIF p_acao IN ('pausar', 'retomar', 'finalizar', 'cancelar') THEN
        RAISE EXCEPTION 'Selecione um registro.';
    END IF;

    IF p_acao = 'iniciar' THEN
        IF p_id <> 0 OR EXISTS (SELECT 1 FROM public.tb_ponto_jornadas WHERE id_usuario = p_usuario AND estado IN ('ativo','pausado')) THEN
            RAISE EXCEPTION 'Você já tem uma jornada aberta. Retome ou finalize esse registro.';
        END IF;
        INSERT INTO public.tb_ponto_jornadas(id_usuario, tipo, estado) VALUES (p_usuario, 'trabalho', 'ativo') RETURNING id INTO v_id;
        INSERT INTO public.tb_ponto_periodos(id_jornada, inicio) VALUES (v_id, v_agora);
        v_ids := ARRAY[v_id];
    ELSIF p_acao IN ('pausar', 'retomar', 'finalizar') THEN
        IF v_j.tipo <> 'trabalho' OR v_j.estado NOT IN ('ativo', 'pausado')
            OR (p_acao = 'pausar' AND v_j.estado <> 'ativo')
            OR (p_acao = 'retomar' AND v_j.estado <> 'pausado') THEN
            RAISE EXCEPTION 'Ação incompatível com o estado atual. Recarregue a página.';
        END IF;
        IF p_acao = 'retomar' THEN
            INSERT INTO public.tb_ponto_periodos(id_jornada, inicio) VALUES (p_id, v_agora);
        ELSE
            UPDATE public.tb_ponto_periodos SET fim = v_agora WHERE id_jornada = p_id AND fim IS NULL;
        END IF;
        UPDATE public.tb_ponto_jornadas SET estado = CASE p_acao WHEN 'pausar' THEN 'pausado' WHEN 'retomar' THEN 'ativo' ELSE 'finalizado' END,
            versao = versao + 1, atualizado_em = v_agora WHERE id = p_id;
        v_ids := ARRAY[p_id];
    ELSIF p_acao = 'salvar' THEN
        IF p_id > 0 AND v_j.tipo <> 'trabalho' THEN RAISE EXCEPTION 'Para alterar a viagem, cancele o dia e registre novamente.'; END IF;
        IF jsonb_typeof(p_dados->'periodos') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Informe os períodos trabalhados.'; END IF;
        IF jsonb_array_length(p_dados->'periodos') NOT BETWEEN 1 AND 50 THEN RAISE EXCEPTION 'Informe de 1 a 50 períodos.'; END IF;
        IF p_id > 0 THEN
            v_id := p_id;
            DELETE FROM public.tb_ponto_periodos WHERE id_jornada = v_id;
            UPDATE public.tb_ponto_jornadas SET estado = 'finalizado', versao = versao + 1, atualizado_em = v_agora WHERE id = v_id;
        ELSE
            INSERT INTO public.tb_ponto_jornadas(id_usuario, tipo, estado) VALUES (p_usuario, 'trabalho', 'finalizado') RETURNING id INTO v_id;
        END IF;
        FOR v_item IN SELECT value FROM jsonb_array_elements(p_dados->'periodos') LOOP
            IF COALESCE(v_item->>'inicio', '') !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?$'
                OR COALESCE(v_item->>'fim', '') !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?$' THEN
                RAISE EXCEPTION 'Preencha a data e a hora de início e fim de cada período.';
            END IF;
            v_inicio := (v_item->>'inicio')::timestamp AT TIME ZONE 'America/Sao_Paulo';
            v_fim := (v_item->>'fim')::timestamp AT TIME ZONE 'America/Sao_Paulo';
            IF v_fim <= v_inicio OR v_fim > v_agora THEN RAISE EXCEPTION 'O fim deve ser posterior ao início e não pode estar no futuro.'; END IF;
            INSERT INTO public.tb_ponto_periodos(id_jornada, inicio, fim) VALUES (v_id, v_inicio, v_fim);
        END LOOP;
        v_ids := ARRAY[v_id];
    ELSIF p_acao = 'viagem' THEN
        IF p_id <> 0 THEN RAISE EXCEPTION 'Registre a viagem pelo formulário de datas.'; END IF;
        IF COALESCE(p_dados->>'de', '') !~ '^\d{4}-\d{2}-\d{2}$' OR COALESCE(p_dados->>'ate', '') !~ '^\d{4}-\d{2}-\d{2}$' THEN
            RAISE EXCEPTION 'Informe as datas da viagem.';
        END IF;
        v_de := (p_dados->>'de')::date;
        v_ate := (p_dados->>'ate')::date;
        v_minutos := (p_dados->>'minutos')::integer;
        IF v_ate < v_de OR v_ate - v_de > 365 OR v_minutos IS NULL OR v_minutos NOT BETWEEN 1 AND 1440 THEN
            RAISE EXCEPTION 'Revise o intervalo (máximo de 366 dias) e as horas por dia.';
        END IF;
        FOR v_dia IN SELECT v_de + i FROM generate_series(0, v_ate - v_de) i LOOP
            IF extract(isodow FROM v_dia) <= 5 OR COALESCE((p_dados->>'fins_semana')::boolean, false) THEN
                IF EXISTS (SELECT 1 FROM public.tb_ponto_jornadas WHERE id_usuario = p_usuario AND dia_viagem = v_dia AND estado <> 'cancelado') THEN
                    RAISE EXCEPTION 'Já existe viagem em %. Nenhum dia foi adicionado.', to_char(v_dia, 'DD/MM/YYYY');
                END IF;
                INSERT INTO public.tb_ponto_jornadas(id_usuario, tipo, estado, dia_viagem, minutos_viagem)
                    VALUES (p_usuario, 'viagem', 'finalizado', v_dia, v_minutos) RETURNING id INTO v_id;
                v_ids := array_append(v_ids, v_id);
            END IF;
        END LOOP;
        IF cardinality(v_ids) = 0 THEN RAISE EXCEPTION 'O intervalo contém apenas fim de semana. Marque a opção para incluí-lo.'; END IF;
    ELSE
        UPDATE public.tb_ponto_periodos SET fim = v_agora WHERE id_jornada = p_id AND fim IS NULL;
        UPDATE public.tb_ponto_jornadas SET estado = 'cancelado', versao = versao + 1, atualizado_em = v_agora WHERE id = p_id;
        v_ids := ARRAY[p_id];
    END IF;

    -- Open intervals have no upper bound when checking other work periods.
    -- Trip conflicts below use days reached by the timer, allowing future trips.
    IF EXISTS (
        SELECT 1 FROM public.tb_ponto_periodos a JOIN public.tb_ponto_jornadas ja ON ja.id = a.id_jornada
        JOIN public.tb_ponto_periodos b ON b.id > a.id
        JOIN public.tb_ponto_jornadas jb ON jb.id = b.id_jornada
        WHERE ja.id_usuario = p_usuario AND jb.id_usuario = p_usuario
          AND ja.estado <> 'cancelado' AND jb.estado <> 'cancelado'
          AND (ja.id = ANY(v_ids) OR jb.id = ANY(v_ids))
          AND tstzrange(a.inicio, a.fim, '[)') && tstzrange(b.inicio, b.fim, '[)')
    ) THEN RAISE EXCEPTION 'Há horários sobrepostos. Corrija os períodos antes de salvar.'; END IF;
    IF EXISTS (
        SELECT 1 FROM public.tb_ponto_jornadas t
        JOIN public.tb_ponto_jornadas j ON j.id_usuario = t.id_usuario AND j.tipo = 'trabalho' AND j.estado <> 'cancelado'
        JOIN public.tb_ponto_periodos p ON p.id_jornada = j.id
        WHERE t.id_usuario = p_usuario AND t.tipo = 'viagem' AND t.estado <> 'cancelado'
          AND (t.id = ANY(v_ids) OR j.id = ANY(v_ids))
          AND tstzrange(p.inicio, COALESCE(p.fim, v_agora), '[)') && tstzrange(
              t.dia_viagem::timestamp AT TIME ZONE 'America/Sao_Paulo',
              (t.dia_viagem + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo', '[)')
    ) OR EXISTS (
        SELECT 1 FROM public.tb_ponto_jornadas t JOIN public.tb_ponto_jornadas j ON j.id_usuario = t.id_usuario
        JOIN public.tb_ponto_periodos p ON p.id_jornada = j.id
        WHERE t.id_usuario = p_usuario AND t.tipo = 'viagem' AND t.estado <> 'cancelado'
          AND j.estado = 'ativo' AND p.fim IS NULL
          AND (t.id = ANY(v_ids) OR j.id = ANY(v_ids))
          AND t.dia_viagem = (v_agora AT TIME ZONE 'America/Sao_Paulo')::date
    ) THEN RAISE EXCEPTION 'Já existe ponto ou viagem nessa data. Ajuste o registro existente para não contar horas duas vezes.'; END IF;

    FOREACH v_id IN ARRAY v_ids LOOP
        INSERT INTO public.tb_ponto_auditoria(id_jornada, id_usuario, acao, antes, depois)
            VALUES (v_id, p_usuario, p_acao, v_antes, public.ponto_snapshot(v_id));
    END LOOP;
    RETURN v_ids[1];
END;
$$;

-- Only finalized work is consolidated. Split at local midnight, preserving
-- pauses and week/month boundaries without rounding each individual interval.
CREATE OR REPLACE VIEW public.vw_ponto_diario AS
SELECT j.id AS id_jornada, j.id_usuario, 'trabalho'::text AS tipo, d.dia::date AS dia,
    sum(extract(epoch FROM (
        least(p.fim, (d.dia::date + 1)::timestamp AT TIME ZONE 'America/Sao_Paulo')
        - greatest(p.inicio, d.dia::date::timestamp AT TIME ZONE 'America/Sao_Paulo')
    ))) AS segundos
FROM public.tb_ponto_jornadas j JOIN public.tb_ponto_periodos p ON p.id_jornada = j.id
CROSS JOIN LATERAL generate_series((p.inicio AT TIME ZONE 'America/Sao_Paulo')::date::timestamp,
    ((p.fim - interval '1 microsecond') AT TIME ZONE 'America/Sao_Paulo')::date::timestamp, interval '1 day') d(dia)
WHERE j.tipo = 'trabalho' AND j.estado = 'finalizado'
GROUP BY j.id, j.id_usuario, d.dia
UNION ALL
SELECT id, id_usuario, 'viagem', dia_viagem, minutos_viagem * 60::numeric
FROM public.tb_ponto_jornadas WHERE tipo = 'viagem' AND estado = 'finalizado';

COMMIT;
