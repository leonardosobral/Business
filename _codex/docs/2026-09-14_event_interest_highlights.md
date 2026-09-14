# Em alta — volume baixo, semana e mês

Regra aprovada pelo usuário: 7 dias padrão e opção 30; provas ativas de hoje ou
futuras com pelo menos 3 visitantes distintos. Ordenação por visitantes, depois
aberturas e ID. Crescimento não é requisito. Até 20 linhas; contador considera
todas as elegíveis, sem limite de 20. Agenda permanece saldo atual separado.

## Períodos e interpretação

- Janela atual começa à meia-noite de N−1 dias atrás e termina agora em Brasília.
  Inclui hoje parcial; base anterior deslocada N dias, até o mesmo horário.
- Crescimento só calculado com audiência anterior maior que zero e histórico do
  site presente antes da base e em todos os dias das duas janelas. Essa presença
  não certifica coleta sem interrupções. Sem base completa, mostra volume observado
  e “Destaque no período”, sem percentual nem comparação com zero artificial.
- Com cobertura comparável, base zero e volume atual positivo é “Novo interesse”,
  não crescimento infinito. Bases anteriores de 1–2 visitantes são sinalizadas.
- Na aba Em alta, o seletor oferece 7/30 dias. Links antigos com Hoje/90 normalizam
  para 7/30. Nas demais abas, acessos mantêm 1/7/30/90 e interesse usa 7/30, com
  janela explicitada no card e na coluna. Filtros de prova, estado, texto e internos
  preservados. O filtro de provas passadas não gera destaques futuros.

## Runtime e validação

Somente `portal/audiencia/queries/event_interest.sql`,
`portal/includes/event_interest_backend.cfm`, `portal/eventos-analytics/home.cfm`.
Contrato SQL mantém os parâmetros anteriores; `meta.trend_days` é aditivo. Leitor
continua com DSN runnerhub e consultas somente leitura. Sem alterações de banco,
coleta, agenda, autenticação, permissões ou outras frentes.

Testes PostgreSQL local isolado exercitam baixo volume, ausência de base, crescimento,
estabilidade, queda, base zero, exclusão de 2 visitantes/passadas/inativas, ordem
semanal/mensal, paginação e agenda. Relógio fixo para limites de horário.
CFML: 14 cenários renderizados, incluindo 7/30, histórico parcial, novo interesse,
queda, erros, escaping e autorização. Compatibilidade SQL Adobe passou. Revisão
independente estática sem P1/P2. Preview local conferido.

Primeiro pacote `/var/backups/business-event-interest.34dcc6b21049` sofreu rollback
automático, confirmado por verify: a adaptação do publicador marcava o próprio SQL
autorizado também como guarda imutável. Corrigida a classificação de ORDER no
publicador derivado, mantendo hashes/metadados before/candidate/after de cada alvo,
backup e todas as guardas de arquivos fora do escopo. O publicador compartilhado
original não foi alterado. Teste offline reproduziu a falha antes da correção;
5 testes passaram depois, incluindo alterações concorrentes e tampering.

Novo pacote preparado com baseline da versão restaurada e backup privado.
Recibos: `2026-09-14_event_interest_highlights_release_v2*.json`.
Script: `_codex/scripts/deploy_event_interest_highlights.py` (prepare/publish/verify/rollback).

Estado: publicado e verificado em produção em 14/09/2026, por volta de 13:10 BRT.
Backup recuperável: `/var/backups/business-event-interest.55848139de00`.
Verificação final confirmou os 3 alvos e 116 guardas; os 2 arquivos CFML também
passaram pela compilação nativa antes da publicação.

Conferência autenticada: 19 provas em destaque na janela de 7 dias e 19 na de
30 dias (o histórico da coleta ainda é curto). Filtro SC: 3 destaques — Avaí Run,
Mons Ultra Trail e Maratona de Criciúma. Alternância Todos → SC → Todos e seletor
7/30 funcionaram. Percentuais permaneceram ausentes sem histórico comparável;
agenda exibiu os dados reais. Layout conferido em desktop e largura de 390 px;
viewport restaurado ao final. Nenhuma execução de SQL pelo usuário é necessária.
