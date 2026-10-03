# Modal de membros do RR — paginação e privacidade

## Regras publicadas

Em `/mensagens/`, o modal carrega até 30 membros inicialmente e busca novos
lotes de até 30 ao chegar ao fim da rolagem. Há indicador de carregamento,
controle acessível de carregar mais e tentativa manual após erro. Uma falha
preserva as linhas existentes. Fechar/trocar o grupo cancela o transporte e
descarta respostas atrasadas. IDs já exibidos não são duplicados.

Grupos mostram todos os membros autorizados, com contatos confirmados
(seguindo **ou** seguidores) primeiro em toda a lista, não apenas em cada lote.
Mantêm-se a prioridade de solicitações/papéis dentro desses blocos e desempate
por nome e ID. Canais mostram **somente membros que o usuário segue**:
`tb_paginas_vinculos.tipo_vinculo=1`, `vinculo_validado=true`, origem do vínculo
no perfil do usuário e destino no perfil do membro. Seguidor não seguido,
vínculo não confirmado e o próprio usuário não aparecem. Essa restrição é
aplicada no servidor antes do limite, inclusive para admin global no modal.

O botão de membros dos canais fica disponível a inscritos ativos e admins
globais, assim como a leitura da conversa. Elegível ainda não inscrito precisa
aderir primeiro. API revalida leitura, elegibilidade e relação a cada lote.
Gestão administrativa do Business e regras de postagem permanecem inalteradas.
Publicadores locais `owner/admin` de canais já podiam publicar no baseline;
esta tarefa não modifica essa regra.

Paginação por cursor composto (contato, solicitação, papel, nome e ID),
parametrizado e vinculado a viewer, grupo e modo. Excluir o membro que marca o
cursor não quebra a continuação. Não há snapshot congelado: mudanças externas
de nome/papel/relação podem alterar a ordem; reabrir o modal reinicia a lista.
O limite máximo é 30, inclusive para requisições sem `limit` ou exageradas.

Foco fica no modal durante Tab/Shift+Tab e retorna ao acionador ao fechar.
Labels novas e erros do pager possuem versões PT/EN/ES. Sem migração, mudança
de credenciais ou inscrição real de usuários para teste.

## Escopo

Sete arquivos RoadRunners:

- `includes/backend/backend_chat_groups.cfm`
- `api/chat/groups/members.cfm`
- `assets/js/runnerhub-chat-members-pager.js` (novo)
- `assets/js/runnerhub-chat-groups.js`
- `assets/css/runnerhub-chat.css`
- `mensagens/_group_thread.cfm`
- `mensagens/index.cfm`

Os seis arquivos existentes de prod/dev correspondiam ao baseline local do
trabalho anterior. Beta estava divergente e não foi sobrescrito. Business usa
dev em sua integração assinada, por isso prod e dev receberam o mesmo escopo.
Alterações anteriores não relacionadas, incluindo reimportação de conteúdo,
foram preservadas. Sem commit/push/PR.

## Evidências

- TDD: testes novos falharam pela ausência de paginação antes da implementação.
- 11/11 testes JS do pager/modal real, com transporte substituído: início
  limitado, continuação, fim, erro/retry, deduplicação, cancelamento, troca de
  grupo, texto escapado, perfil e foco. 11/11 testes anteriores de comunidades.
- 22/22 checks CF/SQL com 65 usuários/membros temporários, seguindo e seguidores
  confirmados/não confirmados; contatos atravessam a fronteira dos lotes;
  privacidade é revalidada após desfazer seguir entre consultas. Todos fixtures
  foram revertidos por transação, sem transporte real de notificações.
- 49/49 checks CF/SQL anteriores de governança de comunidades.
- Ambas suítes CF foram repetidas nos arquivos **publicados** de prod e dev.
- Compilador Adobe em pasta limpa: 5/5 templates, incluindo helper dependente.
- Análise sintática JS, `git diff --check` nos dois projetos e revisão
  independente sem problemas bloqueantes. Os ajustes minor de tradução/foco
  foram incorporados e testados.
- UI real em produção, sessão já inscrita Victoria Coelho: canal com 3 membros
  mostra apenas Geraldo Protta, a única pessoa seguida. Modal conferido no
  viewport habitual e 390×844, sem overflow horizontal. Escape fechou e devolveu
  foco a Membros. A sessão não possuía grupo ativo; múltiplos lotes/grupos foram
  verificados com os fixtures e testes, sem alterar inscrições reais.
- Console registrou erro legado de inicialização MDB/backdrop também antes da
  publicação. O modal deste escopo abriu/fechou e recebeu a API normalmente.
- API de membros sem login: HTTP 401, sem itens. Hashes dos sete arquivos
  publicados conferidos nos dois runtimes. Sonda retirada: HTTP 404.

Suítes ampliadas finais: RR 160/160; Business 344/349. As cinco falhas do
Business são externas ao escopo: `jsdom` ausente para os testes antigos de
Agenda; duas migrations dependem de `@electric-sql/pglite` ausente; dois testes
MIF usam respectivamente um Python de outro usuário e o commit antigo `87ccfa7`.
Os arquivos envolvidos nessas falhas não foram modificados por esta tarefa.

## Publicação e recuperação

Backup: `/var/backups/rr-chat-members-20261002-we83isAm`, com subpastas `prod` e
`dev`, `runtime-before.tgz`, `baseline.sha256`, `new-files.txt` e
`published.sha256`. Restabelecer somente os seis caminhos arquivados após
conferir alterações posteriores. O asset novo deve ser movido para o backup
durante rollback, sem restauração ampla de diretórios.

A primeira tentativa concluiu prod e parou em dev ao preservar proprietário:
dois arquivos tinham UID `501` sem nome correspondente no servidor. A continuação
conferiu que cada caminho era baseline ou candidato já instalado; preservou
UID/GID numéricos (`501:50`) e modo, sem trocar permissões ou criar usuário.
O backup original não foi sobrescrito. O arquivo temporário vazio da instalação
interrompida foi movido para o backup (`dev/failed-install-temporary`).

Sonda CF de teste restrita a loopback, retirada do webroot ao concluir. Os testes
CF de banco não devem ser publicados como endpoint acessível externamente.
