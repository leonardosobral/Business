UPDATE public.tb_resultados_importacoes target
SET status_processamento='cancelado', erro_codigo='superseded',
    erro_detalhe='Substituída pela submissão #' || CAST(completed.id_resultado_importacao AS text) || '.',
    data_atualizacao=now()
FROM result_import_context completed, result_import_context older
WHERE completed.public_id=CAST(:submission_id AS uuid)
  AND completed.status_processamento='processado'
  AND older.event_group=completed.event_group
  AND (older.data_recebimento,older.id_resultado_importacao) < (completed.data_recebimento,completed.id_resultado_importacao)
  AND target.id_resultado_importacao=older.id_resultado_importacao
  AND target.status_processamento IN ('pendente','falhou')
RETURNING target.id_resultado_importacao
