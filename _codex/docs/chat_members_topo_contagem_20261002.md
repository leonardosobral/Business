# Modal de membros — topo fixo e contagem de outros membros

## Comportamento publicado

Grupos e canais possuem cabeçalho fixo com título, botão Fechar e, nos canais,
aviso de privacidade. Cabeçalho fica fora da área rolável; somente o corpo com
lista/rodapé rola. O observer de carregamento gradual usa esse corpo como root,
preservando até 30 membros por lote, fallback por scroll e controle por teclado.

Nos canais, o rodapé em repouso mostra `e outros {N} membros`, em vez da
quantidade carregada. O servidor conta membros **ativos e elegíveis, sem bloqueio
de moderação**, que não têm vínculo confirmado de seguindo saindo do perfil do
leitor. Isso equivale ao total ativo do canal menos todos os seguidos ativos,
independentemente de cursor, limite ou quantidade carregada. Associações,
perfis e vínculos repetidos não duplicam a subtração. O próprio leitor, se
inscrito ativo, permanece no total (total menos seguidos), mas continua oculto
na lista do canal. Pendentes de aprovação não entram nesse total ativo.

API adiciona somente o agregado `other_members`: identidades não seguidas
continuam ocultas, inclusive para admins globais no modal público. Um canal
sem seguidos mantém o aviso de lista vazia e informa o agregado no rodapé.
Grupos mantêm o contador de membros carregados. Loading, erros e retry
continuam sendo apresentados no status do rodapé. Labels PT/EN/ES.

## Escopo

Seis arquivos RoadRunners:

- `includes/backend/backend_chat_groups.cfm`
- `api/chat/groups/members.cfm`
- `assets/js/runnerhub-chat-groups.js`
- `assets/css/runnerhub-chat.css`
- `mensagens/_group_thread.cfm`
- `mensagens/index.cfm` (versionamento dos dois assets alterados)

Dependência do pager e regras de governança não alteradas. Sem migração,
índices, alterações de timeout/credenciais/inscrições reais para teste.
Baseline local/prod/dev idêntico; beta divergente preservado, conforme
verificações das tarefas anteriores. Alterações de outras frentes preservadas.
Sem commit/push/PR.

## Verificação

- TDD: testes novos JS falharam no baseline mostrando `30 members` e `Empty`;
  teste CF falhou pela ausência do agregado. Após ajuste, JS do escopo 25/25.
- CF/SQL 27/27 em candidato e novamente nos runtimes publicados prod/dev,
  com 65 membros temporários: privacidade, múltiplos perfis e associações,
  total independente do limite e revalidação após desfazer seguir entre páginas.
  Fixtures e eventuais efeitos de refresh revertidos por transação; transporte
  de notificações substituído somente nos testes.
- Governança CF/SQL anterior: 49/49 em prod/dev publicados.
- Desempenho no canal real com 5.768 membros: 44 ms produção, 51 ms dev,
  retornando os 16 seguidos esperados; 4/4 checks em cada runtime publicado.
- Compilador Adobe: 5/5 templates em pasta limpa, incluindo dependência.
- Browser fixture em localhost consome o template, CSS e JS reais do candidato,
  substituindo somente labels CF e transporte externo: cabeçalho desktop
  permaneceu em y=43,20 enquanto corpo rolou 1.470 px e lista cresceu 30→45.
  Rodapé permaneceu `e outros 55 membros` nos dois lotes. Em 390×844,
  cabeçalho de canal e de grupo permaneceu em y=33,77 durante rolagem,
  sem overflow horizontal. Viewport restaurado e servidor local encerrado.
- UI de produção, sessão Victoria Coelho: canal Road Runners com 5 membros;
  lista mostra apenas Geraldo Protta, único seguido, e rodapé `e outros 4
  membros`. Cabeçalho novo e assets versionados confirmados; overflow externo
  hidden e corpo auto. Sem alterar login ou inscrições reais.
- Revisão independente dos seis arquivos sem findings. JS syntax e
  `git diff --check` passaram. RR ampliado 160/160; Business 347/352.
  As cinco falhas externas pré-existentes do Business:
  `google-agenda-browser.test.js` (`jsdom` ausente),
  `google-agenda-schema.test.js` e `google-drive-schema.test.js`
  (`@electric-sql/pglite` ausente), e dois checks em
  `mif-report-deployment-contract.test.js` (`modular manifest passes portable
  privacy and hash verification`, Python inexistente de outro usuário; `the
  modular feature never changes the existing registrations screen`, commit
  antigo `87ccfa7`). Não modificados por esta tarefa.

## Publicação e recuperação

Backup: `/var/backups/rr-chat-members-header-20261002-716AIM3f`, com os seis
originais em `prod`/`dev`, `baseline.sha256`, `published.sha256` e sondas em
`test-probes`. Instalação preservou UID/GID numéricos e modo, com substituição
atômica por arquivo e comparação de hash em ambos ambientes. Para rollback,
conferir mudanças posteriores e restaurar somente os seis caminhos arquivados.

Sondas CF restritas a loopback retiradas do webroot ao concluir: HTTP 404.
API anônima de membros permanece HTTP 401. Não publicar testes como endpoint
externo. Fixture de rolagem: `node _codex/tests/chat-members-scroll-server.cjs`
(loopback 33437, nenhum dado real); variável `RR_MEMBERS_RUNTIME` permite
verificar candidato separado do checkout.
