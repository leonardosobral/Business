-- Habilita o gerenciamento de destaque da home em /portal/videos/.
ALTER TABLE public.tb_media
ADD COLUMN IF NOT EXISTS is_featured boolean NOT NULL DEFAULT false;

-- O evento e opcional e contextualiza o video escolhido para o destaque.
ALTER TABLE public.tb_media
ADD COLUMN IF NOT EXISTS id_evento integer;

CREATE INDEX IF NOT EXISTS tb_media_id_evento_index
ON public.tb_media (id_evento)
WHERE id_evento IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tb_media_id_evento_fkey'
          AND conrelid = 'public.tb_media'::regclass
    ) THEN
        ALTER TABLE public.tb_media
        ADD CONSTRAINT tb_media_id_evento_fkey
        FOREIGN KEY (id_evento)
        REFERENCES public.tb_evento_corridas (id_evento)
        ON DELETE SET NULL;
    END IF;
END
$$;
