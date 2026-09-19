-- Executar em transação, após backup do trigger/default e dos registros elegíveis.
-- Mantém a proteção contra publicação automática; corrige somente o estado editorial.
ALTER TABLE news.tb_content ALTER COLUMN editorial_status SET DEFAULT 'review';

CREATE OR REPLACE FUNCTION news.fn_content_force_hidden_on_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Novo conteúdo fica fora do site até uma decisão explícita da curadoria.
    NEW.published := false;
    NEW.editorial_status := 'review';
    NEW.is_featured := false;
    NEW.published_at := NULL;
    RETURN NEW;
END;
$$;

-- Recupera apenas importações sem edição nem publicação anterior.
-- Rascunhos editados, ocultações manuais, rejeições e publicações são preservados.
UPDATE news.tb_content c
SET editorial_status = 'review'
WHERE c.published = false
  AND c.editorial_status = 'draft'
  AND c.published_at IS NULL
  AND c.created_at = c.updated_at
  AND EXISTS (SELECT 1 FROM news.tb_content_imports i WHERE i.content_id = c.id);
