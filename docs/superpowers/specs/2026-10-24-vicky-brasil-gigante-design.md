# Lembrete D−7 — Circuito Brasil Gigante

Pedido aprovado: criar, testar e publicar lembrete automático sete dias antes de cada etapa, a todos os inscritos no circuito, via webchat e WhatsApp. Não depende da agenda individual.

Usar o worker/fila/auditoria existente da Vicky, sem IA e sem cron novo. Regra `brasil_gigante_d7`, público `desafios` (produto ou desafio `circuitobrasilgigante`), etapas oficiais vinculadas ao agregador `brasil-gigante`. Sete dias de calendário no horário de Brasília. Uma interação por atleta/etapa/canal, sem retroativos; manter preferências, consentimentos, vínculos ativos e silêncio. Não autoriza inscrever usuários no WhatsApp nem alterar consentimento.

Web: `**Mais uma etapa está chegando**\n\nLembre-se de reconhecer seus resultados nas etapas já concluídas e manter o seu perfil atualizado.` WhatsApp: modelo aprovado `atualize_cbg`, respeitando a estrutura real de parâmetros do modelo. Regra visível/editável no Business com público e gatilho claros; 7 dias fixos. A ativação faz parte do pedido; não realizar envios manuais de teste a atletas.

Abordagem: estender o fluxo existente com geração específica para o circuito; não reutilizar a regra de agenda (público errado), nem criar outro disparador independente (duplicação operacional). Reutilizar `trigger_type=manual`, já permitido no schema, distinguido pelo código específico no gerador; não executar DDL.

Publicação somente arquivos do escopo nos ambientes Business e RR que executam o worker; baseline, backup recuperável, testes privados sem envio e validação no navegador. Preservar outras frentes e geolocalização pausada. Sem commit/push.
