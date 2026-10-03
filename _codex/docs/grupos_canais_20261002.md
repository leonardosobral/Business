# Grupos e canais — 02/10/2026

## Comportamento

Gerenciador: `/administracao/chat/grupos-especiais/`, menu **Grupos e canais**.
Somente `tb_usuarios.is_admin=true` cria, configura ou modera comunidades. Os
admins globais acessam, leem e publicam sem associação, inscrição ou convite,
inclusive em rascunhos e comunidades pausadas. Papéis legados não concedem
administração; publicadores de canais mantêm sua capacidade de publicação.

- Grupos: membros conversam. Canais: responsáveis publicam, inscritos leem.
- Público aberto, desafio/circuito com inscrição confirmada (`desafios.status=C`),
  treino/evento ou inscrição em etapa de agregador.
- Circuitos oficiais conhecidos continuam no seletor mesmo sem cadastro de
  campanha legada ou com campanha inativa; isso não reativa inscrições.
- Treinos usam `tb_inscricoes` e `tipo_corrida=treino`. Eventos e etapas também
  reconhecem a declaração explícita `INSCRICAO` em `tb_evento_corridas_checkin`.
  Agenda/calendário, resultados e presença não são inscrição.
- Vínculo oficial com evento é independente da regra de participação.
- Inclusão automática opcional: ativação/sincronização e acesso ao chat.
  Quando desligada, a sincronização só revalida vínculos existentes.
- Público aberto nunca matricula toda a plataforma automaticamente.
- Elegíveis podem entrar voluntariamente; histórico só depois da entrada.
- Saída voluntária e remoção não são revertidas pela inclusão automática.
- Convites são enviados por admins globais e respeitam a elegibilidade.
- Comunidades existentes aparecem na listagem. Configurá-las conserva ID,
  mensagens e membros; regras compostas antigas são preservadas pelo editor
  avançado até uma escolha explícita de novo público.

Não há migration, alteração de credencial, criação real de comunidade,
sincronização em massa ou mudança das regras existentes nesta publicação.

## Arquivos

Business: `home.cfm`, `includes/backend.cfm` e novos `assets/manager.js` /
`manager.css` na rota; alteração pontual do rótulo no sidenav.

RoadRunners: helpers `backend_chat_groups.cfm` e
`backend_chat_special_groups.cfm`, API administrativa e ações, `mensagens/index.cfm`,
`mensagens/_group_thread.cfm` e os dois scripts `runnerhub-chat*.js`.

## Publicação e validação

Business consulta **dev.roadrunners.run** na integração assinada já configurada.
Os mesmos oito arquivos de chat foram publicados no RR prod e dev após comparar
os baselines (idênticos); a configuração não foi alterada. A versão de produção
do sidenav tinha diferenças em relação ao checkout: foi preservada e recebeu
somente a troca do rótulo, sem publicar alterações alheias.

Backups recuperáveis:

- `/var/backups/chat-communities-rr-20261002-Q5dqoOOe`
- `/var/backups/chat-communities-dev-20261002-L7kxA1oO`
- `/var/backups/chat-communities-business-20261002-449lu5Zw`
- `/var/backups/chat-communities-catalog-20261002-BNcHeOcM` (ajuste final do catálogo)

Os três primeiros backups contêm `runtime-before.tgz`, baseline, relação de
arquivos novos e hashes publicados. O backup do catálogo guarda a cópia anterior
do helper por runtime e os hashes finais. Restaurar apenas os caminhos listados, conferindo
antes se houve alterações posteriores. Os dois assets novos podem ser movidos
para o backup durante rollback. Não executar restauração ampla de diretórios.

Verificações realizadas:

- Compilador nativo Adobe ColdFusion: 15/15 templates compilados.
- `_codex/tests/chat-communities-spec.cfm`: 49 checks CF/SQL, sem falhas, com
  rollback dos fixtures e transporte de notificações substituído; repetidos
  contra os arquivos publicados de prod e dev.
- `chat-community-form.test.cjs` + `chat-community-entry.test.cjs`: 11/11.
- Integração HMAC real: listagem e seis seletores de referências funcionais.
- Browser autenticado global: listagem, seleção, simulação de 748 inscritos
  em Todo Santo Dia sem modificar membros e edição de regra legada preservada.
  Layout conferido no viewport usual e em 390px; sem salvar configuração real.
- Revisão independente corrigiu reativação após adoção de comunidade pausada,
  refresh da lista após entrada voluntária e prioridade da referência selecionada.
- Browser confirmou Brasil Gigante e os dois circuitos Catarinenses no seletor
  final, inclusive sem cadastro de campanha em `desafios_eventos` para o primeiro.
- A rota anônima exige login (302); as APIs rejeitam assinatura ausente; sondas
  removidas do webroot retornaram 404.
- `git diff --check` e análise sintática dos três scripts JavaScript.

Suíte ampliada local: 316/320 passam. Quatro falhas fora do escopo:
duas dependem de `@electric-sql/pglite` ausente; uma usa Python de outro usuário
(`/Users/leonardosobral/...`); outra compara inscrições com commit antigo
`87ccfa7`. Os testes e caminhos dessas falhas não foram alterados nesta tarefa.

As sondas temporárias de validação são restritas a loopback e removidas do
webroot após a verificação. Não publicar os testes CF de banco publicamente.

Nenhum commit, push ou PR solicitado ou realizado.
