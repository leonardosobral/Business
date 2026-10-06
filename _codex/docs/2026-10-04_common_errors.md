# Erros frequentes — 04/10/2026

## Business

Acompanhamento agora inicia com “Falhas de aplicação (sem 404)”. Categoria “Todas, incluindo 404” e categoria específica mantêm os registros acessíveis. Contadores respeitam a categoria; status/site preservam o comportamento anterior dos contadores. Logs originais, coleta, histórico e imagens ausentes preservados.

ErrorNormalizer.evidence decodifica uma camada de entidades HTML nos campos MESSAGE/TEMPLATE. A saída continua escapada no template. A identidade histórica de agrupamento não foi alterada. Não houve fusão, exclusão ou baixa de problemas antigos.

Chrome de produção verificado: 3.383 registros totais anteriores; 296 exibidos na visão padrão sem 404. Caminho do problema 19856 legível como /var/www/roadrunners.com.br/api/analytics/collect.cfm.

## RoadRunners

- org/index.cfm: tag vazia ou fornecedor ausente termina no handler 404 antes da consulta de tema que exigia inteiro.
- carteira/check_transacao.cfm: quatro chamadas de logQueryDebug protegidas pela existência de função. Consulta continua limitada ao usuário da requisição; não houve alteração de pagamento ou transação.
- api/analytics/collect.cfm: catches não tentam modificar cabeçalhos/corpo quando a resposta já está committed, evitando uma exceção secundária no tratamento de erro.

A falha secundária de cabeçalho foi reproduzida com cfflush em serviço sintético. O fingerprint sintético não coincidiu com o fingerprint do log de produção; portanto isto confirma a correção desse caminho, mas não prova que toda ocorrência histórica do coletor tinha essa causa. O erro original anterior ao catch não está disponível nos logs mascarados. Não marcar esses registros automaticamente como verificados.

## Validação/publicação

Fixtures CFML remotas isoladas reproduziram os defeitos antes da edição. Depois: suíte de triagem, guardas de acesso, quatro cenários de audiência e cinco de carteira (incluindo outro usuário), quatro organizadores ausentes e um válido. Compilação CF: 3/3 RR e 4/4 Business. Hashes confirmados em produção.

Verificação HTTP de organizadores na origem e domínio público: ausentes 404, yescom 200 e nenhuma exceção nova de org durante a janela. Audiência e carteira verificadas separadamente em runtime-endpoints.json. Coleta curl pode receber 204 pelo controle existente; não significa validação de persistência real.

Backups: /var/backups/rr-common-errors-20261004/baseline e /var/backups/business-common-errors-20261004/baseline. Scripts deploy_common_errors.py permitem verify/rollback com conferência de hashes. Recibos: _codex/staging/common-errors-20261004/. Não houve commit ou push.
