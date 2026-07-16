BEGIN;

ALTER TABLE tb_agendas
    ADD COLUMN IF NOT EXISTS fonte_cards varchar(16) NOT NULL DEFAULT 'trebuchet';

ALTER TABLE tb_agendas
    ADD COLUMN IF NOT EXISTS raio_cards varchar(12) NOT NULL DEFAULT 'atual';

DO $agenda_visual_options_constraints$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_agendas_fonte_cards_ck'
          AND conrelid = 'tb_agendas'::regclass
    ) THEN
        ALTER TABLE tb_agendas
            ADD CONSTRAINT tb_agendas_fonte_cards_ck
            CHECK (fonte_cards IN ('trebuchet', 'verdana', 'georgia', 'tahoma', 'monospace'));
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_agendas_raio_cards_ck'
          AND conrelid = 'tb_agendas'::regclass
    ) THEN
        ALTER TABLE tb_agendas
            ADD CONSTRAINT tb_agendas_raio_cards_ck
            CHECK (raio_cards IN ('atual', 'medio', 'suave', 'reto'));
    END IF;
END
$agenda_visual_options_constraints$;

COMMIT;
