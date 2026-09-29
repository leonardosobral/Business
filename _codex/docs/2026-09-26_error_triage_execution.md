# Execução do acompanhamento de erros — 26/09/2026

Especificação e plano aprovados; implementação sequencial concluída, revisada e publicada. Sem operações Git de escrita. Mudanças das outras frentes preservadas.

## Entrega e decisões

Quatro tabelas aditivas, normalizador conservador, coletor limitado a 200 ocorrências, fila administrativa, categoria/status, responsável, análise, proposta, evidências, histórico, agrupamento manual e exportação JSON. A consulta original dos logs mostra o vínculo e estado do acompanhamento.

A releitura dos IDs ainda sem vínculo dentro do recorte fixo absorve confirmações tardias. Edições usam versão; recorrência posterior à publicação reabre o problema. Textos livres não reconhecidos são omitidos da exportação e mantidos no Business.

A revisão independente encontrou quatro pontos, corrigidos com regressões observadas falhando antes da correção: origem da ocorrência conferida dentro da transação mesmo com versões iguais; SQLSTATE e hash do detalhe distinguem erros de banco; segmentos de caminhos 404 não estruturais são omitidos da apresentação/exportação; título gerado limitado a 180 caracteres. Os métodos de mover/separar recebem `expectedSourceId` adicional ao contrato planejado.

O escritor 404 também grava caminhos relativos; normalização ajustada e coberta por regressão. No Adobe CF, DML não garante retorno query; helper de banco usa retorno `any`.

A aplicação de teste usa schema efêmero com setup confirmado e remoção em finally, em vez de transação externa envolvendo serviços com transações próprias. Isso evita rollback aninhado do Adobe CF. A primeira tentativa de validação remota foi bloqueada pela revisão automática; o usuário autorizou explicitamente os testes remotos isolados, permitindo a execução seguinte.

A entrada foi publicada antes da nova home: funciona com a home antiga e inicializa o contexto necessário à nova.

## Evidências efetivas

- Adobe ColdFusion: 46 asserções CFML aprovadas e cinco guards HTTP 403. Incluem coleta concorrente, idempotência, ID tardio, recorrência, edição vencida, histórico, agrupamento manual, exportação e renderização/escape HTML.
- Node: três testes JS aprovados. Python: quatro testes do publicador aprovados, incluindo conflito de baseline e rollback preservando alteração posterior.
- Compilação oficial: nove templates de nove com sucesso, retorno zero.
- Inspeção visual sintética em desktop 1440px e mobile 390px; servidor local encerrado ao final.
- Migração explícita confirmou quatro tabelas; hashes dos 11 arquivos publicados conferidos.
- Produção sem sessão: fila e exportação redirecionam para autenticação (302); include de ações bloqueado (403).
- Sessão administrativa real: fila/detalhe abertos, dois lotes de 200 processados, total 400 ocorrências / 356 problemas. Problema #6 reúne 22 ocorrências. Download da exportação recebido pelo navegador.
- Nenhum problema real foi marcado como resolvido para testar gravação. Cenários de edição foram executados com dados sintéticos isolados.

Recibos locais: `_codex/staging/error-triage/test-service.json` e `release-{prepare,compile,migrate,publish,verify}.json`. O conteúdo do download real não foi relido no filesystem (Downloads indisponível); filtragem e serialização foram verificadas nos testes CFML.

O roteiro original contém intenções de teste mais granulares que os casos executados. Este registro e os recibos são a fonte dos resultados; não se afirma execução individual de todo item planejado.
