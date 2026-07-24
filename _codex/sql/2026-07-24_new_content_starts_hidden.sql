BEGIN;

ALTER TABLE news.tb_content
    ALTER COLUMN published SET DEFAULT false,
    ALTER COLUMN editorial_status SET DEFAULT 'draft',
    ALTER COLUMN is_featured SET DEFAULT false;

CREATE OR REPLACE FUNCTION news.fn_content_force_hidden_on_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- Toda notícia nova precisa passar pela curadoria manual do Business.
    NEW.published := false;
    NEW.editorial_status := 'draft';
    NEW.is_featured := false;
    NEW.published_at := NULL;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_content_force_hidden_on_insert ON news.tb_content;

CREATE TRIGGER trg_content_force_hidden_on_insert
BEFORE INSERT ON news.tb_content
FOR EACH ROW
EXECUTE FUNCTION news.fn_content_force_hidden_on_insert();

COMMIT;
