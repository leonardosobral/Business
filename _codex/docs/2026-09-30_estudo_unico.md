# Caderno único — publicado em 30/09/2026

Pedido: reunir reprodução por página e publicação em um lugar só.

## Alteração publicada

Caderno 6 passa a **Brasil que Corre Provas — Estudo e publicação**, primeiro da lista e padrão. Recebe as 15 seções do caderno 4, com prefixo 2025, além das duas saídas 2025/2026 já existentes. Preserva IDs das seções e células, SQLs, revisões, execuções e publicações. O caderno 4 fica como alias via `cadernos.merged_into`, ausente do seletor, com links antigos reconhecidos pelo frontend. Novas seções e renomeações em um caderno incorporado são rejeitadas.

Fontes e conciliação fica identificado como referências; legado permanece ao final. A seção 56 criada pelo usuário em Fontes é preservada. A associação de execuções na query de saída continua explícita; esta mudança organiza a área de trabalho e não recalcula ou publica indicadores.

Arquivos locais: `estudo/includes/StudyNotebook.cfc`, `estudo/assets/notebook.js`, `estudo/index.cfm`, `estudo/home.cfm`. Migration: `_codex/sql/2026-09-30_estudo_unico.sql`.

## Validação e bloqueio

Baseline remoto dos quatro arquivos coincidiu com a cópia local antes da alteração. A migration passou em transação revertida, com asserts de acervo inalterado e preservação dos hashes de células, execuções e payloads públicos. Cinco verificações do seletor passaram (ID atual, alias antigo, referências, ausência de parâmetro e ID inexistente). Sintaxe JS e diff check passaram.

Compilação original falhou porque `/dev/sda` está em 100% de uso, 0 disponível (19GB). Compilação dos três CFML concluída em `/dev/shm` (`successful 3`, `total 3`), sem alteração de configuração. O aviso Java de espaço temporário persiste. Diagnóstico somente leitura: journal 873MB, logs ColdFusion 628MB, Apache 222MB, backups totais 159MB. Não foi feita manutenção desses arquivos.

Após o usuário liberar espaço, a retomada confirmou 1,3GB disponíveis e gravação de 4KB como `nobody`. Baseline/candidato sem alterações concorrentes, nova simulação revertida aprovada, compilação normal em `/var/tmp` com `successful 3 / total 3` e sem avisos. Migration aplicada em transação com backup privado; quatro arquivos publicados e hashes verificados.

Caderno 6 é o padrão, com 17 seções e 97 células. Caderno 4 incorporado, fora do seletor. Todos os conteúdos de células, execuções, destinos web e payloads públicos mantiveram seus hashes/valores. A seção 56 de referência foi preservada.

Chrome autenticado: link antigo `?caderno=4&secao=38` chegou a `?caderno=6&secao=38`; queries existentes e histórico de execuções acessíveis; aba Versão web mostrou 2025/#32 e 2026/#33. Conferido em desktop e 390px, sem transbordamento horizontal. Nenhuma query analítica foi reexecutada e nenhuma publicação de dados foi trocada.

Evidências: `estudo_unico_2026_09_30/{applied,integrity,runtime,compile,publish,verify}.json` e screenshots. RoadRunners não precisou de mudança de runtime.

## Procedimento executado na retomada

1. Resolver capacidade de disco e validar gravação do runtime ColdFusion.
2. Conferir alterações concorrentes de código/banco. O preflight da migration exige o mesmo acervo observado; não remover essa validação se houver mudanças, atualizar o plano a partir de novo backup.
3. Aplicar migration com backup e transaction. O script preparado está em `/private/tmp/estudo-unico/`, mas pode ser regenerado a partir da migration e helpers existentes.
4. Publicar somente os quatro arquivos após revalidar baseline; verificar hashes.
5. Chrome: abrir link antigo `?caderno=4&secao=38`, confirmar caderno 6/seção 38; conferir consultas, histórico, saída de cada ano e aba Versão web. Validar também celular.
6. Comparar hashes dos payloads públicos e acervo com a evidência antes; nenhuma nova publicação é necessária.

Stage/backup remoto: `/var/backups/business-estudo-unico-20260930/runtime/Business/` (candidate, baseline e manifest). Rollback de dados: restaurar metadados dos cadernos/seções do backup, retirar alias, preservando células e execuções; não apagar tabelas nem runs. Documentar estado final ao concluir.
