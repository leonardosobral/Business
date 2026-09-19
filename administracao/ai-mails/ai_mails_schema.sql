-- Migração aditiva. Não modifica mensagens no Gmail nem tabelas de outros módulos.
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_config (
 id integer PRIMARY KEY CHECK (id=1), email text NOT NULL DEFAULT 'contato@runnerhub.run',
 enabled boolean NOT NULL DEFAULT false, model text NOT NULL DEFAULT 'gpt-4.1-mini',
 initial_days integer NOT NULL DEFAULT 30 CHECK (initial_days BETWEEN 1 AND 365),
 daily_limit integer NOT NULL DEFAULT 100 CHECK (daily_limit BETWEEN 1 AND 2000),
 retention_days integer NOT NULL DEFAULT 90 CHECK (retention_days BETWEEN 7 AND 365),
 history_id text NOT NULL DEFAULT '', initial_history text NOT NULL DEFAULT '', page_token text NOT NULL DEFAULT '',
 initial_query text NOT NULL DEFAULT '', initial_complete boolean NOT NULL DEFAULT false,
 monitor_since_ms bigint NOT NULL DEFAULT 0,
 collected integer NOT NULL DEFAULT 0, last_sync_at timestamptz, last_error text NOT NULL DEFAULT '',
 next_attempt_at timestamptz NOT NULL DEFAULT now(), failures integer NOT NULL DEFAULT 0,
 collector_lease timestamptz, collector_token text NOT NULL DEFAULT '', consent_at timestamptz, consent_by bigint,
 updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.tb_ai_mail_config(id) VALUES(1) ON CONFLICT DO NOTHING;
ALTER TABLE public.tb_ai_mail_config ADD COLUMN IF NOT EXISTS monitor_since_ms bigint NOT NULL DEFAULT 0;
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_threads (
 id bigserial PRIMARY KEY, mailbox text NOT NULL DEFAULT 'contato@runnerhub.run', thread_id text NOT NULL,
 subject text NOT NULL DEFAULT '', sender text NOT NULL DEFAULT '', last_message_at timestamptz,
 last_inbound_ms bigint NOT NULL DEFAULT 0, source_message_id text NOT NULL DEFAULT '', rfc_message_id text NOT NULL DEFAULT '',
 in_inbox boolean NOT NULL DEFAULT true, source_available boolean NOT NULL DEFAULT true, content_expired boolean NOT NULL DEFAULT false,
 content_hash text NOT NULL DEFAULT '', summary text NOT NULL DEFAULT '', reason text NOT NULL DEFAULT '',
 actions jsonb NOT NULL DEFAULT '[]', priority text NOT NULL DEFAULT 'normal' CHECK(priority IN ('critical','high','normal','informational','low')),
 category text NOT NULL DEFAULT 'outros', relevant boolean NOT NULL DEFAULT true, needs_response boolean NOT NULL DEFAULT false,
 needs_review boolean NOT NULL DEFAULT true, deadline_at timestamptz, deadline_text text NOT NULL DEFAULT '',
 warnings jsonb NOT NULL DEFAULT '[]', sources jsonb NOT NULL DEFAULT '[]',
 state text NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','in_progress','resolved')),
 assignee_id bigint, assignee_name text NOT NULL DEFAULT '', note text NOT NULL DEFAULT '',
 manual_priority boolean NOT NULL DEFAULT false, version integer NOT NULL DEFAULT 1,
 resolved_at timestamptz, resolved_by bigint, resolved_inbound_ms bigint NOT NULL DEFAULT 0,
 analyzed_at timestamptz, analysis_model text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(mailbox,thread_id)
);
CREATE INDEX IF NOT EXISTS ai_mail_threads_attention ON public.tb_ai_mail_threads(state,priority,last_message_at);
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_queue (
 thread_id text PRIMARY KEY, revision integer NOT NULL DEFAULT 1, attempts integer NOT NULL DEFAULT 0,
 available_at timestamptz NOT NULL DEFAULT now(), lease_until timestamptz, lease_token text NOT NULL DEFAULT '',
 last_error text NOT NULL DEFAULT '', force_analysis boolean NOT NULL DEFAULT false, queued_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_messages (
 message_id text PRIMARY KEY, thread_id text NOT NULL, content_hash text NOT NULL, received_ms bigint NOT NULL,
 seen_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ai_mail_messages_thread ON public.tb_ai_mail_messages(thread_id);
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_audit (
 id bigserial PRIMARY KEY, thread_id text NOT NULL DEFAULT '', actor_id bigint, actor_name text NOT NULL DEFAULT '',
 action text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_usage (
 id bigserial PRIMARY KEY, model text NOT NULL, input_tokens integer NOT NULL DEFAULT 0, output_tokens integer NOT NULL DEFAULT 0,
 operation varchar(20) NOT NULL DEFAULT 'thread', status text NOT NULL DEFAULT 'reserved', created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.tb_ai_mail_usage ADD COLUMN IF NOT EXISTS operation varchar(20) NOT NULL DEFAULT 'thread';
CREATE INDEX IF NOT EXISTS ai_mail_usage_date ON public.tb_ai_mail_usage(created_at);
CREATE INDEX IF NOT EXISTS ai_mail_usage_operation_date ON public.tb_ai_mail_usage(operation,created_at);

-- Grupos persistentes para análise e tratamento de sequências relacionadas.
CREATE TABLE IF NOT EXISTS public.tb_ai_mail_batches (
  id bigserial PRIMARY KEY,
  title varchar(200) NOT NULL,
  instruction text NOT NULL DEFAULT '',
  summary text NOT NULL DEFAULT '',
  pattern text NOT NULL DEFAULT '',
  impact text NOT NULL DEFAULT '',
  actions jsonb NOT NULL DEFAULT '[]'::jsonb,
  priority varchar(20) NOT NULL DEFAULT 'normal',
  category varchar(30) NOT NULL DEFAULT 'outros',
  needs_review boolean NOT NULL DEFAULT false,
  state varchar(20) NOT NULL DEFAULT 'open',
  assignee_id bigint,
  assignee_name varchar(200),
  note text NOT NULL DEFAULT '',
  analysis_model varchar(120),
  analyzed_at timestamp,
  resolved_at timestamp,
  resolved_by bigint,
  created_by bigint,
  created_by_name varchar(200),
  version integer NOT NULL DEFAULT 1,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT tb_ai_mail_batches_priority_ck CHECK (priority IN ('critical', 'high', 'normal', 'informational', 'low')),
  CONSTRAINT tb_ai_mail_batches_category_ck CHECK (category IN ('operacao', 'financeiro', 'comercial', 'suporte', 'seguranca', 'juridico', 'outros')),
  CONSTRAINT tb_ai_mail_batches_state_ck CHECK (state IN ('open', 'in_progress', 'resolved'))
);

CREATE TABLE IF NOT EXISTS public.tb_ai_mail_batch_items (
  batch_id bigint NOT NULL REFERENCES public.tb_ai_mail_batches(id) ON DELETE CASCADE,
  thread_id bigint NOT NULL REFERENCES public.tb_ai_mail_threads(id) ON DELETE RESTRICT,
  relationship varchar(20) NOT NULL DEFAULT 'context',
  finding text NOT NULL DEFAULT '',
  added_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (batch_id, thread_id),
  CONSTRAINT tb_ai_mail_batch_items_relationship_ck CHECK (relationship IN ('primary', 'duplicate', 'consequence', 'context', 'unrelated'))
);

CREATE TABLE IF NOT EXISTS public.tb_ai_mail_batch_audit (
  id bigserial PRIMARY KEY,
  batch_id bigint NOT NULL REFERENCES public.tb_ai_mail_batches(id) ON DELETE CASCADE,
  actor_id bigint,
  actor_name varchar(200),
  action varchar(80) NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_ai_mail_batches_state_updated
  ON public.tb_ai_mail_batches (state, updated_at DESC);
CREATE INDEX IF NOT EXISTS ix_ai_mail_batches_priority_updated
  ON public.tb_ai_mail_batches (priority, updated_at DESC);
CREATE INDEX IF NOT EXISTS ix_ai_mail_batch_items_thread
  ON public.tb_ai_mail_batch_items (thread_id, batch_id);
CREATE INDEX IF NOT EXISTS ix_ai_mail_batch_audit_batch
  ON public.tb_ai_mail_batch_audit (batch_id, created_at DESC);
-- Secret resolved at runtime through the existing scheduler credential; never stored in SQL.
INSERT INTO public.tb_cron_jobs (nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,next_run_at)
SELECT 'AI-mails · '||v.label,'Leitura e triagem da caixa contato@runnerhub.run, somente leitura.','business','prod',
 'https://business.roadrunners.run/administracao/ai-mails/jobs/'||v.path||'.cfm','POST','application/json','{}','{}'::jsonb,'bearer','business_ai_mails',5,120,0,false,true,180,now()
FROM (VALUES ('Coletar Gmail','collect'),('Analisar conversas','process')) v(label,path)
WHERE NOT EXISTS (SELECT 1 FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/administracao/ai-mails/jobs/'||v.path||'.cfm');
