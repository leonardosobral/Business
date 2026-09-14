-- Reconcile sitemap tags with public event eligibility. No data changes.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '60s';
SET LOCAL lock_timeout = '2s';
SET LOCAL TIME ZONE 'America/Sao_Paulo';
WITH base AS MATERIALIZED (
 SELECT tag, data_final, ativo,
        CASE WHEN data_final >= CURRENT_DATE - 1 THEN 'upcoming'
             WHEN data_final < CURRENT_DATE - 1 THEN 'history' ELSE 'no_date' END AS bucket
 FROM tb_evento_corridas
), eligible AS (
 SELECT * FROM base WHERE ativo = true AND tag IS NOT NULL AND trim(tag) <> ''
), grouped AS (
 SELECT bucket, count(*) AS events, count(DISTINCT tag) AS distinct_tags,
        md5(string_agg(tag, chr(31) ORDER BY tag COLLATE "C")) AS tags_md5,
        count(*) FILTER (WHERE tag ~ '[[:cntrl:]]') AS tags_with_controls,
        count(*) FILTER (WHERE tag ~ '[?#]') AS tags_with_delimiters,
        min(data_final) AS first_date, max(data_final) AS last_date
 FROM eligible GROUP BY bucket
)
SELECT json_build_object(
 'read_only', current_setting('transaction_read_only'),
 'database_now', now(), 'database_timezone', current_setting('TimeZone'), 'database_date', CURRENT_DATE,
 'total_records', (SELECT count(*) FROM base),
 'active_records', (SELECT count(*) FROM base WHERE ativo = true),
 'active_without_tag', (SELECT count(*) FROM base WHERE ativo = true AND (tag IS NULL OR tag = '')),
 'eligible_events', (SELECT count(*) FROM eligible WHERE bucket <> 'no_date'),
 'eligible_distinct_tags', (SELECT count(DISTINCT tag) FROM eligible WHERE bucket <> 'no_date'),
 'eligible_tags_md5', (SELECT md5(string_agg(tag, chr(31) ORDER BY tag COLLATE "C")) FROM eligible WHERE bucket <> 'no_date'),
 'groups', (SELECT json_agg(row_to_json(g)) FROM grouped g)
);

ROLLBACK;
