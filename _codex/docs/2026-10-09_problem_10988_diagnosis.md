# Investigação do problema 10988 — 09/10/2026

Pedido: investigar, sem autorização nova de correção/publicação neste turno. Nenhum runtime, registro de acompanhamento ou dado de produção foi alterado. Diagnósticos CFML temporários foram restritos a loopback e removidos ao terminar.

## Evidência confirmada

Problema RR, categoria database, 14 ocorrências, status new, primeira 27/09/2026 23:22:18, última 09/10/2026 10:46:32 (datas apresentadas pelo banco). Arquivo /var/www/roadrunners.com.br/desafios/backend_desafio_confirmado.cfm. A amostra de 08/10 aponta linha 54, parâmetro do ID Strava na consulta de sequências; a de 09/10 aponta linha 158, QueryExecute da consulta diária do desafio. Ambas possuem o mesmo fingerprint e hash de detalhe.

Fingerprint: e8ea1f47eb452e2d6dca45bb3b90cb66f725e58b2463cf452489513c10358d3f.
Hash de detalhe: acd1c82353b5fe5205d391cab6d217479df9641a5dae0d9a69b24c8f3767f365.
SQLSTATE vazio. Mensagem persistida: Erro interno ao processar a solicitação.

Dos 14 vínculos, 12 já não possuem linha original em tb_log. Restam os logs 46339389 e 46417356. Não foi identificada neste turno a operação responsável por essa remoção. A exclusão anteriormente solicitada para o problema 26292 era limitada a outra exceção/site e não é evidência da origem dessa ausência.

O reporter ativo conserva somente mensagens de uma lista curta; as demais tornam-se genéricas. O detalhe é normalizado e transformado em SHA-256, sem guardar o texto de origem. Assim o log atual agrupa a falha, mas não preserva o diagnóstico necessário para explicá-la. Não se recupera a mensagem original a partir do hash.

## Código e testes

O backend obtém o ID de Usuario.strava_id ou URL.id_strava na validação de certificado. Usa cf_sql_integer em três parâmetros, enquanto athlete_id no banco é bigint e id_athlete_donation é integer. Essa incompatibilidade de largura é um risco concreto do código, mas não foi demonstrada como causa deste problema.

Consultas SELECT isoladas com ID vazio, não numérico, maior que integer e datas inválidas produziram exceções diferentes; os detalhes vazios não correspondem ao hash de detalhe persistido. O include de produção foi executado em aplicação isolada com dados de entrada sintéticos e sem inscrição/alteração de dados; as duas passagens completaram. Isso não equivale a reproduzir a requisição real nem descarta falha dependente do atleta, regra do desafio, período ou estado transitório da conexão.

A busca por esse arquivo nos logs atuais e rotacionados exception/application/coldfusion-error/coldfusion-out não encontrou mensagem original adicional. Não foram encontrados bloqueios ativos do banco na amostra consultada.

## Conclusão e próximo passo

Local e fluxo identificados; causa exata ainda não confirmada. Não classificar como 404, invasão, índice ausente ou ID inválido sem evidência. A próxima intervenção recomendada é preservar mensagem técnica, detalhe, SQLSTATE e contexto mínimo da consulta em diagnóstico restrito ao administrador, mantendo a resposta pública genérica e sem armazenar tokens/cookies. Preferir captura específica deste backend antes de modificar regras SQL com base em hipótese. Após obter evidência ou reproduzir com o contexto real, corrigir e testar o cenário exato.
