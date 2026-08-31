-- Orders result set
SELECT
    cod_evento,
    numero_pedido,
    data_pedido,
    CURRENT_TIMESTAMP AS extracted_at,
    body
FROM public.tb_ticketsports_pedidos
WHERE cod_evento = 72611
ORDER BY numero_pedido;

-- Participants result set
SELECT
    cod_evento,
    numero_inscricao,
    numero_pedido,
    CURRENT_TIMESTAMP AS extracted_at,
    body
FROM public.tb_ticketsports_participantes
WHERE cod_evento = 72611
ORDER BY numero_inscricao;
