# Widgets do painel de desafios

A configuração fica em `public.desafios_eventos.config_painel`. A migração
`2026-11-19_desafios_config_painel.sql` no RoadRunners cria a coluna e configura o Foco.
O Business lê a configuração pelo `tag` do desafio.

- `widgets` é a lista ordenada dos cartões a exibir. As chaves disponíveis são
  `no_desafio`, `em_andamento`, `vip`, `confirmados`, `pendentes`, `inscritos`,
  `atletas_com_atividade` e `dias_com_atividade`.
- `progresso: "dias_com_atividade"` habilita a apuração de dias de atividade.
  O painel conta um dia por atleta confirmado com uma atividade válida de
  qualquer modalidade do Strava. Usa a data local da atividade dentro do
  período do desafio, a partir da inscrição.
- `periodo_padrao` define a lista exibida ao abrir o painel. Aceita `inscritos`,
  `confirmados`, `pendentes` e, com o modo de dias de atividade, `atividade`.
  Quando a URL inclui `periodo`, o filtro da URL tem prioridade.

O Foco abre no **Resumo**, com o funil no lugar da faixa de cartões. A aba
**Atletas** abre em `inscritos` quando não há filtro. Esse padrão vem da
migração `2026-11-19_desafios_config_painel_periodo_padrao.sql`.

O gráfico **Atividades registradas por dia** soma uma atividade por atleta
por dia. O gráfico de inscrições usa a data de cadastro. Ambos incluem zeros
nos dias sem registros entre o primeiro e o último dia exibido.

O ranking **Modalidades mais praticadas** usa essa mesma seleção de atividades
válidas. Cada treino do Strava conta para sua modalidade, inclusive quando um
atleta registra mais de um treino no mesmo dia. O ranking prefere `sport_type`
e usa `type` para atividades sem esse campo. **Atletas únicos** conta cada
inscrito uma vez por modalidade, mesmo quando ele treina mais de uma variante
agrupada na mesma categoria.

No Foco, o **Resumo** reúne o funil, as séries diárias, a frequência dos
últimos sete dias e a retenção por semana de inscrição. As etapas do funil
abrem a aba **Atletas** com o filtro correspondente. Um histórico de atividade
ou de ponto mantém a passagem pelo Strava no funil. O filtro de conexão atual
avalia as credenciais disponíveis para o cron.

A frequência inclui todos os inscritos, com um registro por atleta e por dia.
A retenção agrupa quem treinou na semana da inscrição e verifica o retorno
na semana seguinte. As semanas incompletas ficam em andamento.

A aba **Pontos** lê a fila `tb_strava_foco_points`. Exibe as confirmações dos
últimos 30 dias, a confirmação mais recente e as pendências por motivo.
Os filtros separam fila, HTTP 408 em revisão, outras revisões, HTTP 404
rejeitado, outras rejeições e dias elegíveis sem envio. Cada linha abre o
histórico do atleta, com data da atividade, número de tentativas, horário e
retorno da última tentativa e horário da confirmação. Os horários seguem
Brasília.

O recorte **Sem envio registrado** procura atividades processadas e elegíveis
nos últimos 30 dias. Para esse recorte, `config_painel.envio_pontos_desde`
registra o início efetivo do envio em ISO 8601 UTC, de acordo com
`startEpoch` da integração Strava/Foco de produção. A apuração de dias sem
envio depende desse campo. As informações do histórico vêm do último estado
persistido por atleta e por dia.

Uma configuração vazia carrega os widgets anteriores. Os circuitos com painéis
próprios mantêm seus painéis. Os dias de atividade medem participação. O
resultado dos envios de pontos à Foco Radical fica na fila da integração.

Para os desafios que usam a apuração de corrida, a consulta agrega atividades
e pagamentos dos inscritos. A migração `2026-11-19_strava_activities_athlete_date.sql`
cria o índice de leitura que atende essa apuração.
