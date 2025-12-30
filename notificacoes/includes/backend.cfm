<cfquery name="qNotificaCount">
    SELECT count(*) as total
    FROM tb_notifica notifica
</cfquery>

<cfquery name="qNotificaCountClicks">
    SELECT count(*) as total
    FROM tb_notifica notifica
    WHERE data_leitura is not null
</cfquery>

<cfquery name="qNotificaCountConversoes">
    select count(*) as total, sum(tran.valor_transacao)/100 as valor_total
    from tb_transacoes tran WHERE tran.status_atual = 'order.paid'
    AND tran.id_usuario IN
    (SELECT t.id_usuario
    FROM public.tb_notifica t
    WHERE data_leitura is not null
    AND (select data_inscricao from desafios where id_usuario = t.id_usuario and desafio = 'todosantodia' order by status limit 1) > '2025-12-29 14:40:00');
</cfquery>
