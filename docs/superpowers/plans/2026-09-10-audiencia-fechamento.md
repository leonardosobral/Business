# Fechamento incremental de audiência

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** avançar nas lacunas já aprovadas, sem interromper a coleta ou aposentar logs ainda utilizados.

**Architecture:** o RoadRunners produz eventos; o Business consome o contrato existente. Nesta entrega, a reprodução de YouTube utiliza os tipos `video_start`, `video_progress` e `video_complete` já aceitos pelo coletor e banco. A correção de cache de localização é independente da reprodução e não substitui a solução do bloqueio HTTP 403 do provedor.

**Tech Stack:** CFML, JavaScript nativo, Node test runner e CFML isolado.

**Spec:** `_codex/docs/estrategia_audiencia_inventario_e_midia_proposta.md`, continuação aprovada em 10/09/2026 e solicitação de aposentadoria condicional de `tb_log`.

**Revisão de escopo em 12/09/2026:** o usuário retirou a segunda parte, de mídia e crescimento, desta tarefa; ela está sendo tratada em outra frente. Este plano continua restrito à mensuração. Estado consolidado e próximas entregas: [escopo e pendências](../../../_codex/docs/2026-09-12_audiencia_escopo_e_pendencias.md).

## Restrições

- Preservar opt-out/GPC, retenção detalhada de 90 dias, autenticação, DSN `runner`, Ads e cobrança.
- Não modificar `runner_dba`, configurações Cloudflare ou criar acesso ao banco.
- Não desligar `tb_log`, apagar histórico, alterar OR/CT ou misturar duas fontes no mesmo período.
- Não criar commits, branches ou gastar verba de mídia.
- A validação local não constitui comprovação em produção.

## 1. Reprodução YouTube no modal compartilhado

Arquivos RR: `assets/js/rr-audience.js`, `includes/modal/modal_youtube.cfm`, `includes/analytics/bootstrap.cfm`, testes em `_codex/tests/`.

- [x] Teste RED de `bindYouTube(player, id)` com estados reais da API simulados na fronteira externa: ready/paused/buffering não iniciam; playing inicia; quartis limitados; ended exige início observado; aba oculta e opt-out não coletam; stop cancela callbacks.
- [x] Implementar observador que consulta `getPlayerState`, `getCurrentTime`, `getDuration`; reusar deduplicação e envio existentes. Quartis representam posição alcançada, não tempo integral assistido. `getVideoUrl` confirma o ID, sem transmitir a URL.
- [x] Integrar API oficial somente ao abrir o modal; manter embed funcionando quando API/medição falha; descartar callbacks de vídeos anteriores; restaurar iframe ao fechar/trocar; preservar HTML5.
- [x] Testar abertura, fechamento, troca rápida, API atrasada/indisponível e integração com o tracker real; executar regressões existentes. 69/69 testes Node RR, 5/5 Business e contrato CFML passaram.
- [x] Atualizar hash do asset no bootstrap e documentar ordem de publicação e validação do painel.
- [x] Publicar somente os três arquivos de vídeos com backup. Publicado em 10/09/2026 às 10:34:32 Brasília; reprodução desktop/móvel e dois inícios reais confirmados no Business, sem duplicar após reabertura. Conclusões/quartis ainda sem comprovação ponta a ponta. Recibo: `_codex/docs/2026-09-10_audience_youtube_publicado.md`.
- [x] Continuação em 12/09: término real do player e incremento de início/conclusão confirmados no Business, com teste interno excluído do recorte comercial. Houve avanço pela barra de tempo; não comprova reprodução integral. Quartis continuam sem comprovação individual pela tela. [Registro](../../../_codex/docs/2026-09-12_audience_youtube_conclusao_verificada.md).

## 2. Recuperação do cache negativo de geolocalização

Arquivos RR: `services/LocationResolver.cfc`, teste/runner isolados, documentação.

- [x] RED: cookies BR/BR e cache negativo legado não impedem lookup; cache negativo novo vence em cinco minutos; positivo e país estrangeiro continuam válidos.
- [x] GREEN: classificar ausência de UF brasileira separadamente da flag legada `isFallback`; timestamp no cache; política curta negativa, política positiva intacta.
- [x] Verificar sem banco/rede: 30 verificações CFML no candidato passaram; revisão independente aprovada. O 403 e a confiabilidade de geo headers dependem de solução separada de infraestrutura. Lote local independente, ainda não publicado.

## 3. Transição futura do log de eventos

Arquivo Business: `_codex/docs/2026-09-10_tb_log_eventos_transicao.md`.

- [x] Mapear writers, readers, hotsite e diferença entre requisição no servidor e abertura observada pelo cliente.
- [x] Registrar condições futuras de cobertura, migração dos relatórios, data de corte e tratamento de histórico >90 dias, sem executar desligamento. Usuário reforçou que esta frente fica para o final; nenhuma alteração de writer/reader realizada.

## Fora da conclusão desta etapa

Este é o registro do lote de 10/09, não a lista atual de pendências. Cards/leitura, promoções estáticas, classificação dos estados de entrega e piloto institucional lateral tiveram publicações posteriores, com limites registrados nos respectivos recibos. A previsão comercial ainda depende de semanas completas e da cobertura identificada. Consultar o [estado consolidado de 12/09](../../../_codex/docs/2026-09-12_audiencia_escopo_e_pendencias.md) para não reabrir entregas concluídas.

O piloto de aquisição, seus criativos, verba e acompanhamento de custos foram retirados deste plano por solicitação do usuário em 12/09. A medição de origem/UTM já existente permanece. A aposentadoria específica do log de visualização em `tb_log` continua condicional e por último.
