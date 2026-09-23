BEGIN;

ALTER TABLE public.tb_evento_saude_historico
    ALTER COLUMN num_peito DROP NOT NULL;

CREATE INDEX IF NOT EXISTS tb_evento_saude_historico_inscricao_data_idx
    ON public.tb_evento_saude_historico (num_pedido, data_alteracao DESC)
    WHERE num_pedido IS NOT NULL;

COMMIT;
