BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_google_drive_config (
    id integer PRIMARY KEY CHECK (id = 1),
    root_folder_id varchar(255) NOT NULL CHECK (root_folder_id ~ '^[A-Za-z0-9_-]+$'),
    root_folder_name varchar(255) NOT NULL CHECK (length(trim(root_folder_name)) > 0),
    criado_por integer REFERENCES public.tb_usuarios(id) ON DELETE SET NULL,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tb_google_drive_auditoria (
    id bigserial PRIMARY KEY,
    id_usuario integer REFERENCES public.tb_usuarios(id) ON DELETE SET NULL,
    acao varchar(64) NOT NULL CHECK (length(trim(acao)) > 0),
    file_id varchar(255),
    nome varchar(255),
    estado varchar(20) NOT NULL DEFAULT 'pending' CHECK (estado IN ('pending', 'success', 'failed')),
    criado_em timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tb_google_drive_auditoria_data_idx
    ON public.tb_google_drive_auditoria(criado_em DESC);

COMMIT;
