# Revisão do fluxo de erro do RoadRunners — 26/09/2026

## Escopo e evidência

Revisão do produtor RoadRunners e da interpretação no Business. Nenhum runtime alterado ou publicado nesta revisão. Leitura dos repositórios, comparação de SHA-256 com produção e consulta agregada limitada aos últimos 5.000 logs RR/erro/404 das últimas 24 horas, em transação somente leitura com timeout. A sonda temporária usou aplicação isolada com loopback/token e foi removida ao final.

Os três arquivos locais conferem com produção em `/var/www/roadrunners.com.br`:

- `Application.cfc`: `7172319683da6d57d9cc3b2e7cef4a615b14f1138e84655abc48a207c313a54e`.
- `404/index.cfm`: `9b8a54cc002044a0f7779f95ad349517425c4bdad8c43817bc62680c660b58d7`.
- `.htaccess`: `c6c3ce0fcb45438d24174f7771806166afd5182bcc2419b757bd9bb63a5ddca3`.

## Causas confirmadas

1. `Application.cfc:2937–2999`: OnError monta dump, envia cfmail, grava tb_log como erro e redireciona para `/404/`. Exceções internas e páginas inexistentes acabam no mesmo destino.
2. `404/index.cfm:5,13–28`: sempre responde 404 e insere outro log 404. Sem REDIRECT_URL/tag, registra `/404/`. Uma falha interna seguida pelo navegador pode gerar dois registros de tipos diferentes.
3. `404/index.cfm:19–21,23–28,32–44,233–234,284–299`: a página depende de bootstrap, backend, login, banco, tradução, header, busca, footer e modais. Falha durante esse processamento pode chegar novamente ao OnError; cada redirecionamento inicia outra requisição. Não há trava de repetição no fluxo. Um cliente pode encerrar a cadeia por limite de redirecionamentos; isso não torna o handler seguro.
4. `Application.cfc:2970–2991`: SMTP e INSERT não têm proteção independente. O envio precede o log. Uma falha síncrona ao preparar/enfileirar e-mail pode impedir a gravação; falha ao gravar no banco interrompe o restante. Não há fallback de log local nesse handler.
5. O cfmail é executado em cada exceção e tem To e CC. Não há deduplicação por assinatura, janela de silêncio ou teto global de alertas. Isso explica a possibilidade de tempestade de mensagens, mas esta revisão não consultou recibos/quota do Mandrill e não atribui a ele uma contagem exata de entregas.
6. O handler usa dados de SESSION/APPLICATION durante o próprio tratamento, embora a falha possa ocorrer na inicialização. Também permite que a presença de URL.debug desvie do tratamento normal. O novo fallback precisa ser independente de inicialização bem-sucedida e não expor dumps no ambiente público.
7. O Business respeita log_item: registros gravados como 404 são classificados como página não encontrada. Não há request_id comum que permita associar com certeza o erro e o redirecionamento históricos. Não é seguro converter todos os registros `/404/` para erro interno.

O microsite `maratonadefloripa/Application.cfc` também redireciona erros para `/404/`, embora seu cfmail esteja comentado. A API isolada em `public-api/Application.cfc:96` já usa log local protegido e resposta JSON 500, constituindo uma referência existente; seu contrato não precisa ser alterado.

## Amostra agregada

Consulta registrada em `_codex/staging/error-handler-audit/counts.json`:

- 2.930 registros RR no recorte de 24 horas (limite de 5.000 não atingido).
- 289 do tipo erro.
- 2.641 do tipo 404.
- 301 404 com destino genérico `/404`, `/404/`, `/en/404/` ou `/es/404/`.
- Zero registros de erro contendo `/404/index.cfm` nessa amostra.

Os 301 destinos genéricos são suspeitos, não falsos 404 comprovados individualmente. A ausência de erros mencionando o template não prova ausência de ciclo: o registro pode falhar ou a exceção apontar para outra dependência. Não foram provocados erros nem enviados e-mails de teste em produção.

## Desenho recomendado para a correção

- OnError responde 500 na própria requisição, sem redirecionar para 404. HTML mínimo para páginas e resposta adequada para endpoints JSON, com identificador de ocorrência e sem detalhes internos.
- Página 404 leve, isolada do bootstrap comum, sem login, tradução dinâmica, banco obrigatório, scripts ou modais. Preservar status 404 para recurso realmente inexistente; fallback estático no servidor para falhas da aplicação/infraestrutura. Auditar rotas legadas e o microsite para não manter outro emissor de falso 404.
- Registro técnico antes da notificação, com guard por requisição e etapas isoladas. Falha no banco tenta log local; falha no logger ou no e-mail não impede a resposta mínima nem gera outro alerta recursivo.
- Deduplicar alertas por ambiente/site e assinatura técnica, com reserva atômica para concorrência. Sugestão inicial: primeiro alerta, silêncio de 15 minutos para a mesma falha e teto global de 30 mensagens por hora para erros. Contar também tentativas malsucedidas para não insistir quando SMTP estiver indisponível. Contar repetições suprimidas e informá-las no próximo alerta permitido. Não alterar e-mails transacionais do portal.
- Manter todas as ocorrências no log; limitar as notificações. Adicionar status HTTP e request_id às novas evidências para correlacionar a resposta real. Se mudar o formato do log, adaptar o leitor do Business com compatibilidade para os registros antigos.
- Preservar histórico existente. Qualquer marcação de 404 histórico suspeito deve indicar incerteza, sem apagar nem reclassificar automaticamente.

## Validação necessária antes da publicação

Aplicação de testes isolada, com SMTP substituído por coletor sintético: erro de código, erro de inicialização, banco indisponível, SMTP indisponível, logger indisponível, falha dentro do tratamento, rota inexistente, rajada concorrente, diferentes assinaturas, isolamento por ambiente, limites de tempo e repetição. Confirmar status, ausência de redirecionamento/ciclo, uma ocorrência por requisição, limites de envio e ausência de dumps na resposta pública. Verificar rotas HTML e JSON e fallback 404 real. Baseline/backup seletivo em cada projeto antes de publicar; preservar mudanças preexistentes.
