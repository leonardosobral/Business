# Plano — Estudo no Business
Especificação: ../specs/2026-09-28-estudo-notebook-design.md. Execução na conversa, sem commits/branches.

1. Pré-flight: catálogo/papéis/permissões, baseline runtime e acervo atual. Testes antes de implementar.
2. Migração em _codex/sql/2026-09-28_estudo_notebook.sql: mover tabelas/sequências, criar cadernos/revisões/execuções/guards. Teste com fixture legada em PostgreSQL descartável, hashes, preservação, conflitos e papel de leitura.
3. Serviço estudo/includes/StudyNotebook.cfc e SqlReadGuard.cfc; endpoint estudo/api.cfm. Admin existente, CSRF em POST, optimistic locking. Testes CFML reais.
4. UI estudo/index.cfm, home.cfm, assets/notebook.js/css. Menu administrativo. Editor, seleção, resultados, histórico, freeze/export, estados de erro/conflito. Testes funcionais e browser.
5. Importação idempotente de fontes: caderno com os arquivos preservados DBA/DataGrip e mapa de conciliação, com hashes/proveniência. Não executar os originais.
6. Publicação: backup privado, compilação, migração transacional, Business, sem alterações no runtime RunnerHub antigo. Verificação de baseline, contagens/hashes e gates.
7. Revisão independente final conforme executing-plans. Corrigir achados importantes com testes. Desktop/mobile, execução e congelamento reais, documentação/recibo.

## Interfaces
StudyNotebook.init(datasource='runner_dba'); listBooks(); getNotebook(id); saveCell(id,version,type,lang,content,actor); createCell(notebookId,type,lang,content,actor); archiveCell(id,version,archived,actor); reorderCells(notebookId,ids,actor); createNotebook(bookId,title,actor); saveNotebook(id,version,title,actor); createBook(title,year,actor); revisions(cellId); runs(notebookId); execute(cellId,version,sql,actor); freeze(runId,title,note,actor); getRun(runId).
SqlReadGuard.validate(sql): retorna uma consulta sem ponto-e-vírgula final, ou Study.Validation.
API: list, notebook, saveCell, createCell, archiveCell, reorderCells, createNotebook, saveNotebook, createBook, revisions, runs, run, freeze, export. Envelope {ok,data} / {ok:false,error,code}; conflito 409, validação 400, acesso 403.
Autor resolvido pelo servidor. SQL executado é o conteúdo salvo ou trecho literal da revisão. IDs na UI como strings.
Resultado {columns:[nomes],rows:[objetos],rowCount,truncated}. Preservar JSON bruto PostgreSQL ao persistir.

## Evidências esperadas
- Migração mantém IDs/conteúdo; não altera snapshots. estudo_reader não escreve.
- SQL inseguro/múltiplo rejeitado; consultas válidas com comentários/aspas passam.
- Conflito 409; histórico imutável; congelamento sem reexecução, resistente a alteração de origem.
- Adobe compila; anônimo não acessa API/export; Business independe das APIs antigas.
- Browser desktop/390px sem overflow de página, células históricas e resultado reais.

## Foco da revisão
Pooled connection: READ ONLY/role e restauração; seleção/múltiplas instruções; JSON/NULL/precisão/aliases; CSRF/auth/export; salvar/executar concorrente; sidebar já modificado; migração com alterações simultâneas.

## Registro
- Contexto confirmado: Business usa runner_dba e require_admin.cfm; editor usa public.notebooks/public.notebook_cells; estudo.snapshots já existe.
- Planejamento documentado para executar a migração solicitada; não repetir aprovação funcional.
- Limites iniciais: 1.000 linhas / 5 MB / 45s; congelamento exige resultado completo.

- Ajuste explícito: ignorar runtime RunnerHub; migrar acervo e tabelas ao schema estudo e entregar somente Business admin. Integração da web será o próximo passo.

- Testes locais: PostgreSQL 9/9 passaram; CFML guard 21 e serviço (37 verificações totais) passaram antes da extensão Markdown legado. Importação das fontes repetida sem duplicação (15 novas seções / 29 células).
- Ruling: cfquery nativo para SQL sem parâmetros, pois QueryExecute no Lucee local remove um dos dois pontos de casts PostgreSQL. Escritas do serviço seguem parametrizadas com CAST.
- Ruling: função public.extrair_faixa_etaria habilitada após ler a definição em produção: IMMUTABLE, invoker, somente extração de texto/regex, sem tabelas ou efeitos externos. As demais funções customizadas continuam exigindo revisão.
- Ruling: manter lang=markdown nas células herdadas; novas células Texto usam lang vazio. O tipo antigo precisa continuar editável.
- Backup privado: /var/backups/business-estudo-20260928/database-before.json (14 seções, 43 células; catálogo de 4 snapshots existente).

- Concluído: migração e fontes publicadas; compilação Adobe 6/6, hashes 16/16; registro completo em _codex/docs/2026-09-28_estudo_business.md.
- Revisão final independente: cinco achados corrigidos (rascunhos/recarga, restauração persistente, precisão decimal, CSV e renomear caderno).
- Ruling: navegação por seletores de caderno/seção, abas Caderno/Execuções/Como usar; fontes em caderno próprio para editar como o acervo. Mantém a interface compacta no mobile.
- Validação real: execuções 4 e 5 congeladas; criação/edição/restauração comprovadas no Chrome; caderno legado 14/43; web pública inalterada.

- Conferência final de origem: 4 fontes DBA com CRLF normalizado para LF; hashes do arquivo e texto registrados separadamente, sem alterar SQL. Correção idempotente validada e aplicada. Produção: 14/14 fontes conferem; 2 cadernos / 30 seções / 73 células / 84 revisões; 16/16 hashes de runtime conferem.
