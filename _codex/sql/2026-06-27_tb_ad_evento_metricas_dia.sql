-- Agregacao diaria de metricas de turbinados.
-- Objetivo: alimentar graficos de /ads/ sem varrer tb_ad_log em tempo real.

CREATE TABLE IF NOT EXISTS ads.tb_ad_evento_metricas_dia (
    id_metrica_dia bigserial PRIMARY KEY,
    data_metrica date NOT NULL,
    id_ad_evento bigint NOT NULL,
    id_evento integer NOT NULL,
    id_conta bigint NOT NULL,
    views integer NOT NULL DEFAULT 0,
    clicks integer NOT NULL DEFAULT 0,
    custo numeric(14, 2) NOT NULL DEFAULT 0,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    updated_at timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT uq_tb_ad_evento_metricas_dia UNIQUE (data_metrica, id_ad_evento, id_conta)
);

CREATE INDEX IF NOT EXISTS idx_tb_ad_evento_metricas_dia_conta_data
    ON ads.tb_ad_evento_metricas_dia (id_conta, data_metrica DESC);

CREATE INDEX IF NOT EXISTS idx_tb_ad_evento_metricas_dia_ad_data
    ON ads.tb_ad_evento_metricas_dia (id_ad_evento, data_metrica DESC);

CREATE INDEX IF NOT EXISTS idx_tb_ad_evento_metricas_dia_evento_data
    ON ads.tb_ad_evento_metricas_dia (id_evento, data_metrica DESC);

GRANT SELECT, INSERT, UPDATE ON ads.tb_ad_evento_metricas_dia TO runner;
GRANT SELECT, USAGE ON SEQUENCE ads.tb_ad_evento_metricas_dia_id_metrica_dia_seq TO runner;

-- Carga inicial/fallback para consolidar dados ja existentes.
-- Pode ser reexecutada; em conflito, atualiza a linha do dia/campanha/conta.
INSERT INTO ads.tb_ad_evento_metricas_dia (
    data_metrica,
    id_ad_evento,
    id_evento,
    id_conta,
    views,
    clicks,
    custo,
    updated_at
)
SELECT log.data_insercao::date AS data_metrica,
       ad.id_ad_evento,
       ad.id_evento,
       ce.id_conta,
       count(*) FILTER (WHERE log.status <= 2)::integer AS views,
       count(*) FILTER (WHERE log.status = 2)::integer AS clicks,
       coalesce(sum(CASE WHEN log.status = 2 THEN log.valor_ad ELSE 0 END), 0) AS custo,
       now() AS updated_at
FROM ads.tb_ad_log log
INNER JOIN ads.tb_ad_eventos ad ON ad.id_ad_evento = log.id_ad
INNER JOIN public.tb_conta_eventos ce ON ce.id_evento = ad.id_evento
WHERE ce.status::text = 'ATIVO'
GROUP BY log.data_insercao::date,
         ad.id_ad_evento,
         ad.id_evento,
         ce.id_conta
ON CONFLICT (data_metrica, id_ad_evento, id_conta)
DO UPDATE SET
    id_evento = EXCLUDED.id_evento,
    views = EXCLUDED.views,
    clicks = EXCLUDED.clicks,
    custo = EXCLUDED.custo,
    updated_at = now();

CREATE OR REPLACE FUNCTION ads.refresh_tb_ad_evento_metricas_dia(
    p_data_inicio date DEFAULT current_date - 30,
    p_data_fim date DEFAULT current_date
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM ads.tb_ad_evento_metricas_dia
    WHERE data_metrica BETWEEN p_data_inicio AND p_data_fim;

    INSERT INTO ads.tb_ad_evento_metricas_dia (
        data_metrica,
        id_ad_evento,
        id_evento,
        id_conta,
        views,
        clicks,
        custo,
        updated_at
    )
    SELECT log.data_insercao::date AS data_metrica,
           ad.id_ad_evento,
           ad.id_evento,
           ce.id_conta,
           count(*) FILTER (WHERE log.status <= 2)::integer AS views,
           count(*) FILTER (WHERE log.status = 2)::integer AS clicks,
           coalesce(sum(CASE WHEN log.status = 2 THEN log.valor_ad ELSE 0 END), 0) AS custo,
           now() AS updated_at
    FROM ads.tb_ad_log log
    INNER JOIN ads.tb_ad_eventos ad ON ad.id_ad_evento = log.id_ad
    INNER JOIN public.tb_conta_eventos ce ON ce.id_evento = ad.id_evento
    WHERE ce.status::text = 'ATIVO'
      AND log.data_insercao::date BETWEEN p_data_inicio AND p_data_fim
    GROUP BY log.data_insercao::date,
             ad.id_ad_evento,
             ad.id_evento,
             ce.id_conta;
END;
$$;

GRANT EXECUTE ON FUNCTION ads.refresh_tb_ad_evento_metricas_dia(date, date) TO runner;

-- Sugestao de uso diario:
-- SELECT ads.refresh_tb_ad_evento_metricas_dia(current_date - 2, current_date);
