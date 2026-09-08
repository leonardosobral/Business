# Percursos: cadastro pelo admin global

## Regra implementada

O admin global (`qPerfil.is_admin`) cadastra sem assumir uma conta. Escolhe
“Gestão da plataforma — sem conta organizadora” (padrão) ou uma conta ativa.
A autoria continua sendo o usuário autenticado. O arquivo nasce privado.

O fluxo tem duas etapas: cadastrar/processar o arquivo e, na tela do percurso,
buscar a prova por nome/ID, selecionar sua distância/modalidade e vincular.
O redirecionamento do cadastro leva à seção de vínculos. Eventos com e sem
organizador são permitidos; a distância/modalidade precisa existir no evento.
Falhar ou cancelar o vínculo não descarta o percurso já cadastrado.

Propriedade e associação com eventos são independentes. Um percurso da plataforma
pode servir a mais de um evento. Vincular não transfere propriedade nem publica o
arquivo. Substituir um arquivo já vinculado continua exigindo confirmação.

Somente admins globais editam/gerenciam versões e vínculos dos percursos da
plataforma. Contas de eventos vinculados herdam leitura, como já ocorria. Admins
podem transferir entre plataforma e conta ativa; vínculos e autoria são preservados
e a mudança é auditada. `is_dev` sozinho não concede escrita.

Usuários comuns mantêm a exigência de conta ativa com papel OWNER/ADMIN/OPERADOR.
O servidor rejeita propriedade da plataforma ou de outra conta enviada por eles.
Legados sem proprietário continuam pendentes: não viram propriedade da plataforma
automaticamente e devem ser atribuídos explicitamente por um admin.

## Publicação

1. Aplicar `_codex/sql/2026-09-07_percursos_gestao_plataforma.sql` no PostgreSQL com
   uma credencial de migração autorizada, após a migração de propriedade de julho.
   O script é transacional e reexecutável; não altera registros existentes.
2. Publicar `percursos/includes/backend.cfm`, `percursos/home.cfm`,
   `percursos/geometry.cfm` e `percursos/download.cfm` juntos.
3. Executar a homologação abaixo antes do uso operacional.

O schema inicial em `percursos/percursos_schema.sql` também foi atualizado; ele
não substitui a migração em uma instalação existente. A aplicação não executa DDL.
Antes da migração, o cadastro administrativo com conta continua disponível, mas a
opção de plataforma é bloqueada com uma mensagem específica.

O banco passa a aceitar exatamente um tipo de proprietário: conta preenchida com
`gestao_plataforma=false`, ou conta nula com `gestao_plataforma=true`. A restrição
`NOT VALID` mantém os legados pendentes, mas é aplicada a inserts e updates novos.
Não reaplicar a migração antiga de julho depois desta: ela recria a restrição que
exige conta em todos os percursos. Para rollback de código, primeiro atribuir a
contas os percursos da plataforma; não remover a coluna com percursos ainda nesse
estado, pois o código antigo não consegue gerenciá-los.

## Verificações

Teste local de contratos: `node --test _codex/tests/percursos-ownership.test.js`.
Ele avalia guardas extraídas do CFML, SQL condicional, proteção de escopo, auditoria,
fallback de schema e estrutura das tags. Não executa ColdFusion ou PostgreSQL.

Homologação integrada necessária (ambiente CFML com PostgreSQL/storage):

- Admin global sem conta: cadastrar GPX com elevação em gestão da plataforma;
  confirmar proprietário, autoria e redirecionamento para vínculos.
- Vincular à modalidade de evento sem organizador; repetir em evento com
  organizador e com mais de uma conta associada, sem associação automática de conta.
- Buscar por nome e ID; rejeitar par evento/modalidade divergente; exigir
  confirmação para substituir vínculo existente e permitir desvincular.
- Admin: cadastrar diretamente para uma conta ativa sem simulação; rejeitar conta
  suspensa, inexistente, IDs inválidos e CSRF inválido.
- Editar metadados, enviar/restaurar/excluir versão e abrir mapa/download de percurso
  da plataforma; transferir plataforma → conta → plataforma e conferir auditoria.
- OWNER/ADMIN de conta/OPERADOR: manter cadastro na própria conta. VIEWER e is_dev
  sem vínculo operacional não cadastram. POST forjado não cria na plataforma nem
  em conta de terceiros.
- Conta de evento vinculado lê mapa/download, mas não edita o percurso da
  plataforma. Conta sem vínculo não lê. Autor sem admin não ganha acesso pela
  exceção de legado quando o percurso é da plataforma.
- Legado pendente não pode ser editado/vinculado antes da atribuição explícita.
- Antes da migração: listagem/detalhe continuam abrindo, cadastro com conta funciona
  e seleção manual de plataforma no POST é rejeitada antes de processar o arquivo.
