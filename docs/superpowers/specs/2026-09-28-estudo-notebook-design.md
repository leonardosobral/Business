# Estudo no Business — especificação

Pedido de 28/09/2026: migrar o editor do RunnerHub para Business /estudo, exclusivo de administradores; mover tabelas para estudo; editar e executar SQL e congelar os resultados; centralizar e comparar as fontes recuperadas.

## Fluxo
Cadernos por estudo/ano, seções e células ordenadas de texto/SQL. Preservar os IDs e todo conteúdo das 14 seções atuais. Interface escura Business responsiva; abas Caderno, Execuções e Fontes, com navegação lateral por seção.
Edição com Salvar, histórico e versão esperada para impedir sobrescrita por outro admin. Criar/renomear cadernos e seções; criar/reordenar/arquivar/restaurar células.
Executar célula SQL ou seleção (Ctrl/Cmd+Enter), mostrar tabela/erro/vazio, congelar execução com título/observação e exportar JSON/CSV. Não reexecutar ao congelar nem ao abrir a página. HTML legado sanitizado, resultados como texto, nenhum JavaScript salvo executado.
Cada execução captura revisão, SQL efetivamente usado/hash, autor, início/fim/duração, estado, resultado e limites. Alterar o SQL depois não muda execuções anteriores. Congelamentos completos e imutáveis; resultados incompletos não podem ser congelados.

## Responsabilidades
Business: auth/admin/CSRF, editor, execução, histórico e resultados.
Banco: mover public.notebooks e public.notebook_cells para estudo; acrescentar cadernos, revisões e execuções. Preservar estudo.snapshots e seus contratos.
RunnerHub: somente fonte de leitura. Conforme ajuste explícito do usuário, ignorar o runtime antigo; será desligado/apagado depois. Não criar redirect ou camada de compatibilidade em public.
RoadRunners: acervo/documentação; a web publicada continua usando seus snapshots atuais.

## Execução de SQL
Um SELECT ou WITH de leitura. Células legadas com várias queries podem ser executadas por seleção, sempre pertencente à revisão salva.
Validador léxico: comentários aninhados, aspas, dollar quoting, uma instrução; rejeitar DML/DDL/controle de sessão/SQL dinâmico e funções com efeitos externos ou administrativos.
ColdFusion: transação REPEATABLE READ READ ONLY, papel estudo_reader dedicado sem login/escrita/membros, search_path fixo, statement_timeout 45s e lock_timeout 2s. Duas consultas concorrentes no máximo por locks transacionais. Cliente não escolhe datasource/role/timeout.
Limites: 1.000 linhas + sentinela, 100 colunas, 5 MB de JSON. Usar row_to_json PostgreSQL para preservar NULL/tipos/precisão; exigir nomes de colunas únicos e preservar ordem. Rejeitar congelamento incompleto. Paginação de 50 linhas no navegador.
O papel de leitura recebe somente SELECT nas fontes de public e objetos necessários de estudo; somente o serviço administrativo assume o papel durante a consulta. Validar restauração da conexão após sucesso/erro.

## Persistência
estudo.cadernos: id/título/ano/descrição/origem/metadados.
estudo.notebooks: colunas legadas + caderno_id, versão, arquivamento/autor.
estudo.notebook_cells: colunas legadas + versão, arquivamento/autor/origem JSONB.
estudo.notebook_revisions: versões imutáveis de cada célula.
estudo.notebook_runs: revisão, SQL/hash, autor/tempo/estado/erro, resultado JSONB, quantidade/truncamento, congelamento/título/nota.
Mover em transação com precondições, backup e comparação de contagem/hash. Triggers impedem alterações em revisões e conteúdo de resultados finalizados; congelar altera somente estado/título/nota uma vez. Arquivamento não apaga história.
Editor atual sobrescreve células; não inventar histórico anterior à migração.

## Fontes e conciliação
Registrar cópias DBA/DataGrip em caderno de fontes com arquivo/hash/origem; DDL/DML ficam como referência e não são executados em lote. Registrar diferenças comprovadas entre editor, DBA e PDF, sem declarar automaticamente uma fonte final. Preservar células HTML como resultado histórico colado, distinguindo das execuções capturadas.

## Validação/publicação
Testes reais PostgreSQL descartável e CFML local; compilação Adobe no servidor. Verificar migração, tipos/NULL, lexing/múltiplas instruções, timeout, limites, versões/conflitos, congelamento, CSRF e admin.
Backup de runtime e dados; baseline/hash em cada arquivo existente; publicar apenas escopo. Validar desktop/mobile autenticado, consulta real e congelamento, negação anônima e independência do editor antigo.
Publicação autorizada pelo AGENTS do Business. Sem commits, branches ou PRs. Preservar arquivos modificados de outras tarefas.

## Ajuste de escopo do usuário
O próximo passo, em outra entrega, é fazer a web do estudo consultar esta fonte. Nesta entrega os congelamentos ficam endereçáveis por caderno (estudo/ano), seção, célula/revisão e execução; nenhum consumidor público novo é ativado. Não editar/deployar RunnerHub antigo.
