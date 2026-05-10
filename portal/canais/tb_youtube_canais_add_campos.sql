ALTER TABLE public.tb_youtube_canais
ADD COLUMN IF NOT EXISTS descricao text,
ADD COLUMN IF NOT EXISTS instagram_url text;
