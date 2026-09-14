# Eventos analytics — Agenda unificada

## Escopo aprovado

Nova aba Agenda em `/portal/eventos-analytics/`, ordenada pelas provas futuras
mais salvas. O indicador é o saldo atual de atletas por prova, não inclusões nos
últimos dias, conversão dos visitantes, vendas ou inscrições confirmadas.

O fluxo principal logado do Road Runners exibe **Salvar** e envia
`acao=inscricao` (`evento/index.cfm`, confirmado também na página pública).
O código ainda mantém `calendario` em fluxos antigos e para visitantes deslogados.
Por isso a análise unifica os tipos e deixa de exibir “quero ir / inscritos”.
Nenhum botão, fluxo de login ou gravação do Road Runners foi alterado.

## Fonte e definição

- `public.tb_evento_corridas_checkin`: `id_fornecedor IS NULL` e tipos
  `calendario`/`inscricao`; deduplicação por `(id_evento,id_usuario)`.
- `public.tb_evento_corridas`: evento ativo, não cancelado, data final hoje ou
  futura em Brasília. Eventos em andamento estão incluídos. É o saldo de agenda
  compartilhado do ecossistema, não necessariamente originado no Road Runners.
- Inclui provas com apenas um atleta, mesmo sem qualquer registro de audiência.
  Não depende dos IDs das provas mais acessadas ou do mínimo de três visitantes.
- Ordem por atletas desc., data inicial e ID. Página de 50 linhas; totais usam
  todo o recorte, antes de paginar. O total de atletas é distinto entre provas,
  não a soma dos atletas de cada linha.
- UF da prova, texto e ID filtram a população inteira. Agenda normaliza o período
  para 7/30 dias e a fase para futuras. Período e tráfego afetam só os acessos.
- `audience.events`: aberturas `page_view`, deduplicadas por `page_view_id`,
  ambiente prod, hosts RR, páginas de evento; internos excluídos por padrão.
  Intervalo desde meia-noite de N−1 dias atrás até agora em Brasília, hoje parcial.
- Pendências do cadastro: localização, descrição, imagem, inscrição e percursos,
  seguindo o critério atual. Complementos herdados podem preencher a página.
- Falha de leitura mostra indisponibilidade, sem transformar erro em zero. O
  ranking de agenda tem consulta própria e não executa o relatório de acessos
  completo nem a consulta opcional de agenda das outras abas.

## Runtime

1. Novo `portal/audiencia/queries/event_agenda_ranking.sql`.
2. Novo `portal/eventos-analytics/agenda.cfm`, protegido por `require_admin`.
3. `portal/includes/event_interest_backend.cfm`: leitura de agenda + rótulo unificado.
4. `portal/eventos-analytics/home.cfm`: aba, filtros, navegação e interpretação.

Consultas somente leitura com DSN explícito `runnerhub`, cache de 1 minuto e
timeout de 8 segundos. Sem migrações, credenciais, permissões, coleta ou alterações
de dados. `event_interest.sql` e `event_agenda.sql` anteriores são preservados.

## Validação e publicação

SQL executado em PostgreSQL local isolado: deduplicação entre os dois tipos,
fornecedores/status desconhecidos, provas sem audiência, datas, cancelamento,
filtros, 7/30, internos, totais distintos e paginação. Registros de conteúdo e
duplicatas não aumentam aberturas. CFML testa renderização, filtros normalizados,
escaping, estados vazio/erro, autorização e rótulos unificados.

Publicador: `_codex/scripts/deploy_event_agenda.py`, derivado do mecanismo
reversível já utilizado. Alvos exatos com baseline/hash/metadados, backup, guarda
de arquivos fora do escopo e compilação nativa dos três candidatos CFML. Cinco
testes offline verificam publicação/rollback, concorrência, alteração do pacote e
verificação após instalação. Sem git ou reinício de serviço.

Estado: publicado e conferido em 14/09/2026, entre 13:59 e 14:03 BRT.
Backup recuperável: `/var/backups/business-event-agenda.928b362f0287`.
Recibos: `2026-09-14_event_agenda_release*.json`. Verificação final confirmou os
quatro alvos e 117 guardas; compilação nativa Adobe dos três CFM passou. Revisão
independente sem P1/P2; 21 cenários CFML passaram. Desempate por ID é textual,
estável e sem relevância para o saldo exibido.

Conferência autenticada no volume real, sem erro de leitura: 253 provas,
291 atletas distintos e 144 provas com campos para revisar. SC: 51 provas,
91 atletas e 27 com campos para revisar. Página 2 de SC exibiu a 51ª prova com
um atleta, mantendo os totais. Retorno SC → Todas restaurou o recorte; 30 dias
alterou corretamente os cabeçalhos de acessos sem alterar o saldo de agenda.

Exemplos reais: Criciúma 30 atletas; Aracaju 25; Salvador 23. Indomit Bombinhas
12k e Pomerode apareceram com 18 atletas cada e nenhuma abertura medida na semana,
comprovando que provas sem audiência não somem deste ranking. Em alta passou a
exibir os mesmos saldos sem a quebra antiga de inscritos. Aberturas/visitantes
continuam sendo navegador e não identidades dos atletas da agenda.

Desktop e largura de 390 px conferidos em preview e produção; viewport restaurado.
SQL e acesso direto à partial sem sessão responderam HTTP 403. Nenhum SQL de
instalação precisa ser executado. Não houve conexão direta ao banco de produção,
EXPLAIN de produção, migração, alteração de dados, commit ou reinício de serviço.
