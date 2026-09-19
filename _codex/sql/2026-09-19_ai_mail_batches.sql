-- Lotes persistentes para análise e tratamento conjunto no AI-mails.
-- Migração aditiva e idempotente.

ALTER TABLE public.tb_ai_mail_usage
  ADD COLUMN IF NOT EXISTS operation varchar(20) NOT NULL DEFAULT 'thread';
CREATE INDEX IF NOT EXISTS ai_mail_usage_operation_date
  ON public.tb_ai_mail_usage (operation, created_at);

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
