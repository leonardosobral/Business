-- Public projection only. Private receipts and their permissions remain unchanged.
ALTER TABLE public.tb_evento_corridas ADD COLUMN conferencia_datas_publica jsonb;
COMMENT ON COLUMN public.tb_evento_corridas.conferencia_datas_publica IS 'Recibo publico de datas, publicado explicitamente pelo Business. NULL usa legado; withdrawn impede retorno ao legado; published exige coincidencia com datas atuais. Sem dados pessoais ou acesso a revisoes privadas.';
