-- Run on the Business PostgreSQL database before enabling the pilot.
BEGIN;
CREATE TABLE IF NOT EXISTS public.business_gorunners_zone_sales (
    reference varchar(37) PRIMARY KEY CHECK (reference ~ '^RHGR-[0-9a-f]{32}$'),
    account_id bigint NOT NULL REFERENCES public.tb_contas(id_conta),
    actor_id bigint NOT NULL,
    quote_id uuid NOT NULL UNIQUE,
    amount_cents bigint NOT NULL CHECK (amount_cents BETWEEN 1 AND 2147483647),
    hex_count integer NOT NULL CHECK (hex_count BETWEEN 1 AND 2500),
    starts_on date NOT NULL,
    ends_on date NOT NULL CHECK (ends_on > starts_on),
    expires_at timestamptz NOT NULL,
    order_id bigint UNIQUE,
    sponsor_name varchar(80),
    game_status text,
    checkout_state text NOT NULL DEFAULT 'new' CHECK (checkout_state IN ('new','creating','ready','review')),
    checkout_url text,
    provider_order text UNIQUE,
    received_at timestamptz,
    last_game_event timestamptz,
    activated_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS business_gr_zones_account_created ON public.business_gorunners_zone_sales(account_id,created_at DESC);
GRANT SELECT,INSERT,UPDATE ON public.business_gorunners_zone_sales TO runner;
COMMIT;
