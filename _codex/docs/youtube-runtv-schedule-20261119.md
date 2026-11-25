# Programação RunTV no importador YouTube

O lote existente de `videos.list` também consulta `liveStreamingDetails`. O importador grava `scheduledStartTime` em `public.tb_media.youtube_scheduled_start_at`, um `timestamptz` separado de `data_publicacao`; a exibição no RR converte para o horário de Brasília. Datas sem fuso ou metadados incompletos não sobrescrevem o agendamento conhecido; um vídeo confirmado como comum não mantém agendamento. Não há nova chamada ao YouTube por visitante.

No cron geral, uma consulta adicional em lote atualiza até 50 vídeos publicados priorizando o destaque da home, além de vídeos vinculados a eventos e publicados nos últimos 60 dias ou com transmissão ainda relevante. Isso alcança vídeos destacados que não entraram na página de uploads. Para manutenção, o POST já autenticado aceita `{"schedulesOnly":true,"dryRun":true}` para simular ou `dryRun:false` para atualizar somente a programação, sem importar ou publicar vídeos e sem escrever no feed. A resposta informa verificados, agendados e atualizados.

Migração: no repositório RoadRunners, `_codex/sql/migrations/2026-11-19_runtv_scheduled_start.sql`. Antes da migração, o cron geral continua funcionando sem gravar a programação, e o modo exclusivo informa que falta a coluna. Aplicação do site RR em PROD não faz parte deste trabalho.
