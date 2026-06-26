-- Indices de performance para a Revisao Foco Radical no Business.
-- Aplicar no mesmo banco usado pelas tabelas tb_foco_event_match_* e tb_evento_foco_vinculos.
-- Use fora de uma transacao explicita, pois CREATE INDEX CONCURRENTLY nao pode rodar dentro de BEGIN/COMMIT.

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_evento_foco_vinculos_active_competition_idx
    ON public.tb_evento_foco_vinculos (competition_id)
    WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_evento_foco_vinculos_active_event_idx
    ON public.tb_evento_foco_vinculos (id_evento, data_atualizacao DESC, id_evento_foco_vinculo DESC)
    WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_foco_event_match_candidates_review_idx
    ON public.tb_foco_event_match_candidates (id_evento, competition_id, score DESC)
    WHERE status = 'active' AND exact_place = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_foco_event_match_state_review_idx
    ON public.tb_foco_event_match_state (status, data_atualizacao DESC, id_evento);
