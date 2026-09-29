-- Explicit additive migration. No change to tb_log or database grants.
CREATE TABLE IF NOT EXISTS public.tb_error_problem (
 id bigserial PRIMARY KEY,
 signature varchar(64) NOT NULL UNIQUE,
 signature_version integer NOT NULL DEFAULT 1,
 site varchar(32) NOT NULL,
 title varchar(180) NOT NULL,
 suggested_category varchar(24) NOT NULL,
 category varchar(24) NOT NULL CHECK(category IN ('unclassified','code','database','external','input','not_found')),
 status varchar(24) NOT NULL DEFAULT 'new' CHECK(status IN ('new','investigating','ready','published','verified','ignored','reopened')),
 occurrences integer NOT NULL DEFAULT 0 CHECK(occurrences>=0),
 first_seen timestamp, last_seen timestamp,
 analysis text NOT NULL DEFAULT '', proposal text NOT NULL DEFAULT '', evidence text NOT NULL DEFAULT '',
 published_at timestamp, owner_id integer,
 version integer NOT NULL DEFAULT 1 CHECK(version>0),
 created_at timestamp NOT NULL DEFAULT now(), updated_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tb_error_problem_queue_idx ON public.tb_error_problem(status,site,last_seen DESC,id);
CREATE TABLE IF NOT EXISTS public.tb_error_occurrence (
 id_log integer PRIMARY KEY,
 problem_id bigint NOT NULL REFERENCES public.tb_error_problem(id),
 occurred_at timestamp NOT NULL,
 path varchar(320) NOT NULL DEFAULT '', technical_message varchar(500) NOT NULL DEFAULT '',
 confidence varchar(16) NOT NULL,
 collected_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tb_error_occurrence_problem_idx ON public.tb_error_occurrence(problem_id,occurred_at DESC,id_log);
CREATE TABLE IF NOT EXISTS public.tb_error_history (
 id bigserial PRIMARY KEY,
 problem_id bigint NOT NULL REFERENCES public.tb_error_problem(id),
 action varchar(32) NOT NULL, from_status varchar(24) NOT NULL DEFAULT '', to_status varchar(24) NOT NULL DEFAULT '',
 actor_id integer NOT NULL, note text NOT NULL DEFAULT '', created_at timestamp NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tb_error_history_problem_idx ON public.tb_error_history(problem_id,id DESC);
CREATE TABLE IF NOT EXISTS public.tb_error_collector (
 id integer PRIMARY KEY CHECK(id=1),
 started_at timestamp NOT NULL DEFAULT now()-interval '7 days',
 upper_id integer NOT NULL DEFAULT 0, last_id integer NOT NULL DEFAULT 0,
 updated_at timestamp NOT NULL DEFAULT now()
);
