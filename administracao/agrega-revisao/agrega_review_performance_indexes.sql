-- Indices de performance para a Revisao de Agregadores no Business.
-- Aplicar no banco fora de uma transacao explicita, pois CREATE INDEX CONCURRENTLY
-- nao pode rodar dentro de BEGIN/COMMIT.

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_evento_agrega_review_groups_status_fast_idx
    ON public.tb_evento_agrega_review_groups(status, max_score DESC, data_atualizacao DESC, id_evento_agrega_review_group DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_evento_agrega_review_groups_status_id_idx
    ON public.tb_evento_agrega_review_groups(status, id_evento_agrega_review_group DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS tb_evento_agrega_review_candidates_group_status_idx
    ON public.tb_evento_agrega_review_candidates(id_evento_agrega_review_group, status, id_evento_agrega_review_candidate);
