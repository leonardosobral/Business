-- O monitor passa a aceitar apenas mensagens recebidas depois do corte operacional.
ALTER TABLE public.tb_ai_mail_config
  ADD COLUMN IF NOT EXISTS monitor_since_ms bigint NOT NULL DEFAULT 0;
