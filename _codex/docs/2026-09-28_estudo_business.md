# Estudo administrativo no Business — 28/09/2026

Publicado em https://business.roadrunners.run/estudo/, somente para administradores. O menu Estudo está no Business. Nenhum consumidor público foi acrescentado.

## Acervo e migração
- Movidas public.notebooks e public.notebook_cells, incluindo sequências, para estudo; não foram criadas views de compatibilidade.
- Preservadas as 14 seções / 43 células do editor antigo com seus IDs, conteúdos e datas. Backup, lock exclusivo e comparação SHA-256 antes/depois executados na mesma migração.
- Novo caderno “Fontes e conciliação — 2025”: 6 arquivos recebidos do DBA (inclui texto extraído do DOCX), 8 arquivos DataGrip, hashes/proveniência e mapa com diferenças já confirmadas. Os originais são armazenados como conteúdo; scripts DDL/DML não foram executados.
- Adicionada pela interface a seção “Validação da migração — 28/09/2026”, célula 115. Estado final verificado: 2 cadernos, 30 seções, 73 células, 84 revisões.
- Quatro cópias do DBA tinham CRLF; o editor importou LF. O SHA-256 do arquivo foi mantido e o hash do texto importado foi registrado separadamente em origem.sha256_texto_importado, com nota visível e revisão. Conferência final: 14/14 textos iguais às fontes após essa normalização; conteúdo SQL sem alteração.
- Os 4 registros anteriores de estudo.snapshots mantiveram IDs e hashes; a web do estudo continua com sua fonte atual.
- RunnerHub antigo foi ignorado conforme instrução explícita. Seus endpoints não foram adaptados e não devem mais ser usados para editar o acervo migrado.

## Uso
Escolher caderno e seção; criar células Texto, SQL ou HTML; salvar explicitamente. Executar salva primeiro o texto alterado e executa uma consulta ou o trecho selecionado. Ctrl/Cmd+Enter executa SQL. Abrir uma seção não executa SQL.

Resultados aparecem em tabela, com 50 linhas por página. Congelar preserva a execução já capturada com título, notas, SQL/hash, revisão, autor e tempos; não executa a query outra vez. JSON exportado conserva o documento do PostgreSQL. CSV conserva a representação textual de inteiros e decimais, com proteção de fórmulas textuais.

Revisões impedem sobrescrever silenciosamente a edição de outro admin. Durante operações que recarregam o conteúdo, os editores ficam bloqueados. Arquivar preserva a célula; “Células arquivadas” permite restaurar mesmo após sair/recarregar.

Criar e renomear cadernos/seções; reordenar células; consultar revisões e execuções. A interface lista as últimas 100 revisões por célula e últimas 100 execuções por seção; o banco mantém todas. Paginação do histórico, pesquisa e publicação curada para a web podem ser evoluções posteriores.

## Banco e execução
- estudo.cadernos / notebooks / notebook_cells: organização e estado editável.
- estudo.notebook_revisions: versões imutáveis.
- estudo.notebook_runs: execução vinculada à revisão; resultado JSONB e congelamento imutáveis.
- estudo.notebook_migrations: recibo e hashes da migração.
- Papel estudo_reader: sem login, sem superuser, sem escrita; SELECT nas fontes autorizadas. Usado com SET LOCAL ROLE em transação REPEATABLE READ READ ONLY. Configurações e papel são locais à transação.
- Limites: 45s de statement_timeout, 2s de lock_timeout, duas execuções concorrentes no módulo, 1.000 linhas, 100 colunas, 5 MB do payload de linhas. Truncamentos são visíveis e não podem ser congelados.
- Aceita SELECT/WITH, uma instrução, com análise de comentários, strings e identificadores. Funções analíticas do PostgreSQL em lista explícita. public.extrair_faixa_etaria foi inspecionada: IMMUTABLE, invoker, regex/texto sem efeitos externos; habilitada para as consultas legadas.
- API POST com sessão administrativa e token CSRF. Autor vem da identidade autenticada. Queries não recebem datasource, role ou limites do cliente.

## Validação observada
- PostgreSQL descartável: 9 testes de migração, IDs/sequências, revisões, congelamento, exclusão/TRUNCATE, papel de leitura e conflitos.
- Correção de metadados de origem aplicada duas vezes na fixture: idempotente; os 14 hashes conferem.
- Importação repetida na fixture: sem duplicação (15 seções / 29 células acrescentadas).
- CFML local: guard 22 checks; guard + serviço 42 checks acumulados. Conflito, NULL, bigint, truncamento, erro SQL, restauração de papel, aliases duplicados, Markdown herdado, renomeação e restauração.
- JavaScript: 8 checks de representação numérica/CSV; sintaxe validada.
- Revisão independente encontrou perda de rascunho em recargas concorrentes, restauração inacessível após reload, precisão decimal e lacunas CSV/renomeação. Todos corrigidos. No Chrome, campos deixaram de ser editáveis durante a consulta.
- Adobe: compilação 6/6 arquivos CFML; 16 arquivos do módulo/menu conferidos por hash após publicação.
- Compatibilidade confirmada e corrigida no Adobe: comandos sem linhas removem a variável de retorno; SQL dinâmico no cfquery precisa de PreserveSingleQuotes; booleanos usam cf_sql_bit. Referência: https://helpx.adobe.com/coldfusion/cfml-reference/coldfusion-functions/functions-m-r/preservesinglequotes.html
- Chrome autenticado: acervo e fontes carregam; criar seção/célula, salvar, executar, congelar, reabrir, arquivar, recarregar e restaurar funcionaram.
- Desktop e 390px: conteúdo e controles verificados; largura de página/body de 390px, sem overflow horizontal da página. Override removido.
- Sem cookies: página/API/list/export/run redirecionam ao login, sem dados do módulo. Não houve teste com conta real não-admin ou POST autenticado com token CSRF inválido; esses gates também foram inspecionados no código.
- JSON/CSV exportados pelo navegador: estudo-execucao-5.json (1.613 bytes), estudo-execucao-5.csv (195 bytes). O evento de download da ferramenta não sinalizou; existência e tamanho foram confirmados no disco. macOS recusou leitura do conteúdo de Downloads; representação/codec foi verificada por testes e pela tabela real.

## Coletas congeladas
- Execução 4: célula 4 / revisão 1 / caderno legado, query original de contagem 2025. Retornou 5.599.435 linhas de resultados, em 2,251s. Congelada com as ressalvas de população: não é retrato da base do PDF nem métrica final revisada.
- Execução 5: célula 115 / revisão 2, conferência técnica da migração. Papel estudo_reader, 14 seções, 43 células legadas; bigint, decimal e NULL preservados. Os valores numéricos de validação estão identificados como testes.
- A célula 115 foi arquivada (v3) e restaurada após reload (v4). A execução 5 permaneceu vinculada à revisão 2 e inalterada.
- Execuções 1–3 registram falhas da validação inicial no Adobe. A execução 3 interrompida foi finalizada como erro; não há razão para remover esse histórico.

## Operação e recuperação
Script: _codex/scripts/deploy_estudo.py.
Sequência de SQL para instalação a partir do legado: 2026-09-28_estudo_notebook.sql, 2026-09-28_estudo_sources.sql e 2026-09-28_estudo_source_metadata.sql. A última etapa registra a normalização de finais de linha sem mudar o SQL das fontes.
Backup inicial privado: /var/backups/business-estudo-20260928/database-before.json.
Runtime anterior: /var/backups/business-estudo-20260928/baseline.
Correções posteriores: subdiretório updates, cada publicação com baseline, backup e compilação.
Recibos locais: _codex/staging/estudo/release-*.json.

Não reaplicar a migração sobre o destino existente. O rollback de runtime não desfaz o banco. Recuperação de dados exige manutenção e avaliação dos registros produzidos após o corte; o backup original e as revisões devem ser preservados. Nenhum commit, branch ou push foi feito.

Próxima etapa solicitada: escolher os congelamentos revisados que alimentarão a versão web. Congelar hoje não publica automaticamente nenhum dado.
