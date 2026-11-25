# Widgets do painel de desafios

A configuração fica em `public.desafios_eventos.config_painel`. A migração
`2026-11-19_desafios_config_painel.sql` no RoadRunners cria a coluna e configura o Foco.
O Business lê a configuração pelo `tag` do desafio.

- `widgets` é a lista ordenada dos cartões a exibir. As chaves disponíveis são
  `no_desafio`, `em_andamento`, `vip`, `confirmados`, `pendentes`, `inscritos`,
  `atletas_com_atividade` e `dias_com_atividade`.
- `progresso: "dias_com_atividade"` habilita os dois cartões de atividade.
  O painel conta um dia por atleta confirmado com uma atividade válida de
  qualquer modalidade do Strava. Usa a data local da atividade dentro do
  período do desafio, a partir da inscrição.
- `periodo_padrao` define a lista exibida ao abrir o painel. Aceita `inscritos`,
  `confirmados`, `pendentes` e, com o modo de dias de atividade, `atividade`.
  Quando a URL inclui `periodo`, o filtro da URL tem prioridade.

O Foco abre em `inscritos` e exibe os cartões de inscritos e de atividade.
A migração `2026-11-19_desafios_config_painel_periodo_padrao.sql` aplica essa
configuração ao registro existente.

Uma configuração vazia carrega os widgets anteriores. Os circuitos com painéis
próprios mantêm seus painéis. Os dias de atividade medem participação. O
resultado dos envios de pontos à Foco Radical fica na fila da integração.

Para os desafios que usam a apuração de corrida, a consulta agrega atividades
e pagamentos dos inscritos. A migração `2026-11-19_strava_activities_athlete_date.sql`
cria o índice de leitura que atende essa apuração.
