-- Additive: existing events remain unconfirmed; no ticket status is inferred.
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '15s';
ALTER TABLE public.tb_evento_corridas
    ADD COLUMN IF NOT EXISTS inscricao_disponibilidade jsonb;
