CREATE TABLE IF NOT EXISTS tb_youtube_canais (
    id_youtube_canal serial PRIMARY KEY,
    code varchar(120) NOT NULL UNIQUE,
    name varchar(255) NOT NULL,
    source_type varchar(20) NOT NULL DEFAULT 'channel',
    channel_id varchar(80),
    channel_handle varchar(255),
    playlist_id varchar(80),
    id_pagina integer,
    id_usuario integer,
    max_results integer NOT NULL DEFAULT 3,
    enabled boolean NOT NULL DEFAULT true,
    sort_order integer NOT NULL DEFAULT 0,
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_youtube_canais_source_type_ck
        CHECK (source_type IN ('channel', 'playlist')),
    CONSTRAINT tb_youtube_canais_source_data_ck
        CHECK (
            (source_type = 'channel' AND (channel_id IS NOT NULL OR channel_handle IS NOT NULL))
            OR
            (source_type = 'playlist' AND playlist_id IS NOT NULL)
        ),
    CONSTRAINT tb_youtube_canais_max_results_ck
        CHECK (max_results BETWEEN 1 AND 50)
);

CREATE INDEX IF NOT EXISTS tb_youtube_canais_enabled_idx
    ON tb_youtube_canais (enabled, sort_order, id_youtube_canal);

ALTER TABLE tb_youtube_canais
    ADD COLUMN IF NOT EXISTS min_duration_seconds integer,
    ADD COLUMN IF NOT EXISTS max_duration_seconds integer;

ALTER TABLE tb_youtube_canais
    DROP CONSTRAINT IF EXISTS tb_youtube_canais_duration_range_ck;

ALTER TABLE tb_youtube_canais
    ADD CONSTRAINT tb_youtube_canais_duration_range_ck
        CHECK (
            (min_duration_seconds IS NULL OR min_duration_seconds >= 0)
            AND
            (max_duration_seconds IS NULL OR max_duration_seconds >= 0)
            AND
            (
                min_duration_seconds IS NULL
                OR max_duration_seconds IS NULL
                OR min_duration_seconds <= max_duration_seconds
            )
        );

ALTER TABLE tb_media
    ADD COLUMN IF NOT EXISTS youtube_duration_iso varchar(32),
    ADD COLUMN IF NOT EXISTS youtube_duration_seconds integer;

INSERT INTO tb_youtube_canais
    (code, name, source_type, channel_id, channel_handle, playlist_id, id_pagina, id_usuario, max_results, enabled, sort_order, min_duration_seconds, max_duration_seconds)
VALUES
    ('corrida-no-ar', 'Corrida no Ar', 'channel', 'UCxmZoyAOr6HkyAkW2c2YSog', NULL, NULL, 11796, 133, 3, true, 10, NULL, NULL),
    ('mania-de-corrida', 'Mania de Corrida', 'channel', 'UCn6oqdGLFgHcqjuHR1sGc8w', NULL, NULL, 10498, 6922, 3, true, 20, NULL, NULL),
    ('bora-correr', 'Bora Correr', 'channel', 'UCI5oJ5mN1GgXRDgUzePf-TA', NULL, NULL, 39725, 6922, 3, true, 30, NULL, NULL),
    ('canal-corredores', 'Canal Corredores', 'channel', 'UCHy3t28JXuoYJcbQKK09x7g', NULL, NULL, 10498, 6922, 3, true, 40, NULL, NULL),
    ('correria-campinas', 'Correria Campinas', 'channel', 'UCHKtz27XDxJ1XO9Ig-VSmMw', NULL, NULL, 2602, 5573, 3, true, 50, NULL, NULL),
    ('corre-pezao', 'Corre Pezao', 'channel', 'UCu387Xz__NO6msvWPyM7_UQ', NULL, NULL, 2892, 5573, 3, true, 60, NULL, NULL),
    ('road-runners', 'Road Runners', 'channel', NULL, '@weareroadrunners', NULL, NULL, 1, 3, true, 70, NULL, NULL)
ON CONFLICT (code) DO UPDATE
SET
    name = EXCLUDED.name,
    source_type = EXCLUDED.source_type,
    channel_id = EXCLUDED.channel_id,
    channel_handle = EXCLUDED.channel_handle,
    playlist_id = EXCLUDED.playlist_id,
    id_pagina = EXCLUDED.id_pagina,
    id_usuario = EXCLUDED.id_usuario,
    max_results = EXCLUDED.max_results,
    enabled = EXCLUDED.enabled,
    sort_order = EXCLUDED.sort_order,
    min_duration_seconds = EXCLUDED.min_duration_seconds,
    max_duration_seconds = EXCLUDED.max_duration_seconds,
    updated_at = now();
