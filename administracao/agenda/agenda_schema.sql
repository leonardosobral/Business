BEGIN;
CREATE TABLE IF NOT EXISTS public.tb_google_agenda_conexao (
    id integer PRIMARY KEY CHECK (id = 1),
    email varchar(254) NOT NULL CHECK (email = 'contato@runnerhub.run'),
    google_sub varchar(255) NOT NULL,
    refresh_token text NOT NULL,
    scopes text NOT NULL,
    atualizado_em timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.tb_google_agenda_calendarios (
    calendar_id varchar(1024) PRIMARY KEY,
    nome varchar(1024) NOT NULL,
    ativo boolean NOT NULL DEFAULT false
);
CREATE TABLE IF NOT EXISTS public.tb_google_agenda_cartoes (
    card_id varchar(24) PRIMARY KEY CHECK (card_id ~ '^[0-9a-f]{24}$'),
    calendar_id varchar(1024) NOT NULL,
    event_id varchar(1024) NOT NULL,
    criado_em timestamptz NOT NULL DEFAULT now(),
    UNIQUE (calendar_id, event_id)
);
CREATE TABLE IF NOT EXISTS public.tb_google_agenda_auditoria (
    id bigserial PRIMARY KEY,
    id_usuario integer REFERENCES public.tb_usuarios(id) ON DELETE SET NULL,
    acao varchar(64) NOT NULL,
    calendar_id varchar(1024),
    event_id varchar(1024),
    estado varchar(20) NOT NULL DEFAULT 'pending',
    criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tb_google_agenda_auditoria_data_idx ON public.tb_google_agenda_auditoria(criado_em DESC);
COMMIT;
