-- Organizer identity and legal holder are reviewed independently.
-- No artificial document is generated; the unique index continues to protect known documents.
ALTER TABLE public.tb_contas ADD COLUMN documento_pendente boolean NOT NULL DEFAULT false;
ALTER TABLE public.tb_contas ALTER COLUMN documento DROP NOT NULL;
ALTER TABLE public.tb_contas ADD CONSTRAINT tb_contas_documento_pendente_check CHECK (
    (documento_pendente AND documento IS NULL AND tipo_titular = 'PJ' AND status = 'PENDENTE')
    OR (NOT documento_pendente AND documento IS NOT NULL AND length(trim(documento)) > 0)
);
