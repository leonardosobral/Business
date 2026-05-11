ALTER TABLE news.tb_content_types
ADD COLUMN IF NOT EXISTS rr_portal_enabled boolean NOT NULL DEFAULT true,
ADD COLUMN IF NOT EXISTS rr_home_featured_enabled boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS rr_news_featured_enabled boolean NOT NULL DEFAULT false;
