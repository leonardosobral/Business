# Brasil Gigante — associação ao canal no momento da inscrição

## Resultado

Ao persistir uma inscrição no Circuito Brasil Gigante, o próprio participante
passa imediatamente a integrar os grupos/canais ativos, com associação automática
habilitada e critério `challenge: circuitobrasilgigante`. Não precisa abrir o chat
para disparar a associação. A configuração existente do canal Brasil Gigante,
ID 3, já estava correta; faltava o disparo no cadastro do circuito.

O comportamento respeita confirmação exigida por cada regra, combinações `all`
e `any`, outros pré-requisitos, associação manual, canais pausados/rascunhos,
usuários inativos/excluídos, remoções, rejeições e saída voluntária. Repetir a
inscrição atualiza o JSON do cadastro sem duplicar associação nem alterar o status
da inscrição. O canal atual permite status `I`; não exige `C`.

Os inscritos anteriores já estavam sincronizados: 5.770 inscrições, 5.768
membros ativos e dois removidos pela moderação. Nenhuma operação de inclusão em
massa foi necessária ou realizada. Esses números foram conferidos novamente
após os testes. As remoções existentes foram preservadas.

## Implementação

Circuito Brasil Gigante:

- Novo `cbg-includes/challenge_signup.cfm`: `bgSaveChallengeRegistration`
  centraliza o upsert já utilizado nos três fluxos e chama o motor RR após
  sucesso na gravação. Falha de persistência propaga; falha do hook mantém a
  inscrição salva e escreve diagnóstico técnico em `brasil-gigante-chat.log`,
  sem corpo cadastral ou parâmetros SQL. A revalidação no acesso ao chat continua
  existindo como recuperação. Dependências ausentes ainda impedem o cadastro.
- `cadastro/flow/validacao_step.cfm`: cadastro atual.
- `inscricao/validacao.cfm`: cadastro legado.
- `cadastro-documentos/flow/documentos_step.cfm`: criação/atualização da inscrição
  durante validação documental. Uploads, emails e regras documentais preservados.

RoadRunners:

- `includes/backend/backend_chat_special_groups.cfm`:
  `rrChatSpecialRefreshChallengeSignup` seleciona somente comunidades pertinentes
  e reutiliza o avaliador de regras. Invalida cache de elegibilidade pré-inscrição.
- `rrChatSpecialRefreshUser` recebe `notifyMembers=true` opcional; o cadastro usa
  `false` para não depender de transporte externo de notificações/Push no request
  de inscrição. Chamadas existentes do chat mantêm o comportamento anterior.
- O UPSERT também verifica o status persistido, impedindo sobrescrever saída,
  remoção ou rejeição concorrente entre SELECT e INSERT. A revisão identificou
  essa condição; proteção adicionada ao predicado do banco. Não foi realizada
  uma simulação concorrente com inscrições persistidas de usuários reais.

Includes compartilhados usam caminhos relativos de irmãos, seguindo o
acoplamento já existente entre os sistemas. Prod usa `roadrunners.com.br`; dev
usa `dev.roadrunners.run`. Os três consumidores evitam carregar UDFs novamente
na mesma requisição, compatível com o ColdFusion legado.

## Validação

- TDD: o baseline falhou pela ausência do serviço de associação. Os POSTs originais
  dos dois cadastros falharam em incluir o participante; seus POSTs corrigidos
  passaram. Teste `_codex/tests/brasil-gigante-chat-signup-spec.cfm`: **23/23**.
- SQL e associação reais, transação revertida: status `I`, inscrição repetida,
  confirmação posterior, cache anterior, manual/rascunho/pausado, regra adicional,
  `any`, remoção, saída e rejeição sem flag, usuário inválido e isolamento entre
  usuários. Não há inscrição ou membro de fixture persistido.
- Repetidos depois de publicar em prod/dev. Cold load do include compartilhado
  também validado dentro das duas aplicações nativas do circuito: **23/23**.
- Os POSTs são trechos extraídos sem modificar o conteúdo dos templates reais,
  até a primeira ação de resultados, com os includes relativos preservados.
  A apresentação inteira não roda na transação: suas consultas legadas e QoQ
  usam outro datasource. O upload documental não foi realizado com dados reais.
- Governança existente **49/49**, paginação/privacidade **27/27**, desempenho
  **4/4**, em prod/dev publicados. Canal de 5.768 membros: 49/45 ms, 16 seguidos.
- Compilador Adobe ColdFusion: **5/5 templates finais**. Diff whitespace aprovado
  nos três checkouts; revisão independente e proteção apontada incorporada.
- `/cadastro/` público HTTP 200; API de membros anônima permanece HTTP 401.
- Suíte Node RR **160/160**. Business ampliada **347/352**, com as mesmas cinco
  falhas externas prévias, sem alterar os arquivos dessas áreas:
  - `google-agenda-browser.test.js`: módulo `jsdom` ausente.
  - `google-agenda-schema.test.js`: `@electric-sql/pglite` ausente.
  - `google-drive-schema.test.js`: `@electric-sql/pglite` ausente.
  - `mif-report-deployment-contract.test.js`, `modular manifest passes portable
    privacy and hash verification`: Python de outro usuário inexistente.
  - Mesmo arquivo, `the modular feature never changes the existing registrations
    screen`: comparação com commit histórico `87ccfa7`, alterações anteriores.

## Publicação e recuperação

Somente cinco arquivos de runtime, nos dois pares de ambientes: RR motor e
Circuito serviço + três consumidores. Baseline local/prod/dev idêntico, conferido
antes de cada publicação. Instalação atômica por arquivo, UID/GID numéricos e modo
preservados; hashes de todos os dez destinos conferidos após execução real.
Beta não alterado. Sem migração, alteração de configuração ou credenciais,
commit, branch, push ou PR. Mudanças de outras frentes preservadas.

Backup recuperável: `/var/backups/rr-bg-signup-20261002-a3dAAoq0`, contendo
originais em `prod`/`dev`, `baseline.sha256`, `published.sha256`, lista dos
dois novos includes e sondas privadas arquivadas. Para rollback, conferir
alterações posteriores e restaurar apenas os caminhos da tarefa. Retirar o
include novo de modo recuperável somente depois de restaurar os consumidores.

Sondas são restritas a loopback; ao concluir foram movidas para o backup e as
URLs verificadas como HTTP 404. Não publicar testes como endpoints externos.
Runner e candidato estão arquivados para auditoria/reprodução. O teste requer
`chatTestRoot`, `circuitTestRoot` e `circuitPostTestRoot` relativos à sua pasta;
a última raiz contém os POSTs extraídos em `circuit` e, para teste vermelho,
`baseline`. Recriar em pasta técnica temporária e sempre usar rollback.
