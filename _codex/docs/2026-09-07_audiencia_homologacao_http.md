# Audiência — homologação CFML/HTTP e decisões de ativação

> Registro da rodada anterior (45 verificações). O painel e os controles então pendentes foram implementados na continuação: [Fechamento da implementação](2026-09-07_audiencia_painel_finalizacao.md). Consulte esse documento para os testes atuais e os bloqueios reais de ativação. Este registro preserva a investigação do logout e a evolução da homologação.

## Resultado

Passaram **45 verificações HTTP no Adobe ColdFusion**, com ingestão em PostgreSQL 16 descartável e renderização das consultas reais do Business. A coleta de produção continua desligada. Não houve deploy de aplicação no Business/produção, migração em base de produção, alteração de login ou investimento em mídia.

Esta execução fecha o teste integrado do coletor e do relatório em fixtures protegidas. Não substitui login Google real, homologação das páginas completas do site nem os controles operacionais necessários para ativar a coleta pública.

## Correções encontradas pela execução real

### RoadRunners

Arquivo `services/AudienceMeasurementService.cfc`:

- Um lote válido retornava HTTP 400 porque a validação de quatro rótulos opcionais tratava o resultado zero de `reFind` sobre string vazia como valor inválido. O Adobe confirmou a falha na linha de validação dos rótulos. Agora o vazio é aceito explicitamente; valores preenchidos continuam limitados à lista de caracteres e a 100 caracteres. Slots e anúncios continuam exigindo seus campos obrigatórios nas validações posteriores.
- Após essa correção, o lote passava na validação CFML, mas a ingestão rejeitava a duração numérica com `Invalid duration`. As durações são agora convertidas para Java `long` depois da validação de dígitos/faixa, para serializar inteiros JSON compatíveis com o contrato SQL. A fração de visibilidade continua numérica decimal.
- A variável local `client` foi renomeada para `audienceClient`, evitando conflito com o escopo reservado no Lucee CLI. A chave externa `client` e o contrato da persistência permanecem iguais.

O teste `_codex/tests/audience-service-contract.cfm` ganhou casos para vazio explícito, caracteres inválidos, 101 caracteres e serialização inteira de 0, 1000 e 86400000. Não foram alterados cobrança Ads, leilão, tokens de anúncios ou migração de produção.

Backups locais anteriores às correções: `/private/tmp/rr-audience-native-before.xjMw12` e `/private/tmp/rr-audience-duration-before.80j0RB`. São cópias temporárias, não substituem versionamento.

### Business

Arquivo `portal/audiencia/queries/filter.sql`:

- O parser de parâmetros do Adobe confundia o literal SQL de dois hífens usado para UF desconhecida com comentário. Uma matriz mínima confirmou: parâmetro simples, parâmetro repetido, CTE e string vazia funcionavam; o literal de dois hífens causava erro antes do JDBC.
- O marcador é agora construído com `repeat('-', 2)`. O valor apresentado continua `--`; regras de região, filtros e contagens não mudam. Não foi necessário duplicar parâmetros nem alterar o tipo booleano do filtro.

Novos utilitários de teste: `_codex/scripts/test_audience_cfml_local.sh`, `_codex/scripts/test_audience_native_http.mjs` e `_codex/tests/audience-native-http/`. Esses arquivos **não devem ser publicados como funcionalidades do site**.

## Evidência de verificação

- **45 verificações Adobe/HTTP:** bloqueio externo, token de acesso à fixture, datasource descartável, bootstrap nativo, SP de origem/SC comercial, schema ausente, métodos/tipos/tamanhos inválidos, assinatura adulterada/expirada, origem incorreta, flag desligada, lote válido, `text/plain`, replay idempotente, posição vazia renderizada/visível, guard administrativo, acesso direto aos includes, sete consultas reais, nove KPIs esperados e tratamento de indisponibilidade.
- **37 assertivas SQL Business:** passaram novamente após a alteração do marcador desconhecido.
- **27 assertivas RoadRunners→Business:** passaram novamente com as consultas finais, leitura como `runner_dba` e transações somente leitura.
- **Contrato PostgreSQL 16:** migração reaplicável, ingestão, deduplicação e isolamento financeiro passaram.
- **Contrato CFML puro:** passou contra o checkout final, sem adaptações da lógica e sem `Application.cfc` ou datasource.
- **25 testes Node do tracker** e regressão Ads DOM-ready passaram nesta continuação; não houve mudança de JavaScript nesta etapa.
- Revisões independentes não encontraram P1/P2 nas correções de rótulos/durações nem no isolamento do harness. Verificação de sintaxe dos runners e whitespace passou.

Comandos no Business:

```sh
bash _codex/scripts/test_audience_cfml_local.sh
node _codex/scripts/test_audience_report_local.mjs
node _codex/scripts/test_audience_native_http.mjs --run-isolated-dev
```

Comandos no RoadRunners:

```sh
node _codex/scripts/test_audience_inventory_local.mjs
node _codex/scripts/test_audience_business_integration_local.mjs
node --test _codex/tests/audience-tracker.test.js
node _codex/scripts/test_ads_v1_viewability_dom_ready.mjs
```

O runner CFML aceita caminhos por argumentos/variáveis `AUDIENCE_CFML_*`; o cache CommandBox/Lucee atual é temporário. Se ele não existir, o comando falha sem alterar aplicação ou buscar um datasource. Os testes PostgreSQL/HTTP exigem permissão para processos e sockets fora da sandbox.

## Isolamento e recuperação

O harness cria um diretório aleatório exclusivo sob o dev e comprova HTTP 403 externo **antes** de copiar CFML. Há uma segunda proteção por endereço loopback e token efêmero. As aplicações têm nomes únicos, sessões/cookies desabilitados, nenhum include do `Application.cfc` real e datasources exclusivos apontando a um PostgreSQL local descartável por túnel SSH loopback.

Para impedir qualquer fallback ao datasource global, somente o literal do nome do datasource é remapeado nas cópias temporárias do serviço e backend; a lógica de validação, ingestão, consultas e view permanece a real. O harness confere a quantidade exata de substituições. Antes dos testes, verifica configuração efetiva, nome do banco, papel de acesso e marcador exclusivo. Não consulta credenciais nem tabelas de produção.

A última rodada passou em `/var/www/dev.roadrunners.run/rr-audience-http-XM0chz`. Ao terminar, a rota foi removida por movimentação para a cópia privada `/var/tmp/rr-audience-http-XM0chz-closed`; o túnel foi encerrado e o PostgreSQL parado. As rodadas anteriores também foram encerradas e movidas para diretórios privados com sufixo `-closed`. Diagnósticos locais finais: `/var/folders/ct/41b1hy657kq5s56h529h2y3m0000gn/T/rr-audience-native-hp9XNI`.

Os diagnósticos são apenas para dados sintéticos protegidos. Mensagens de exceção podem conter fragmentos SQL; não transformar essas fixtures em endpoints públicos. O coletor público continua retornando erros genéricos.

Não houve commits, branches ou push. Alterações preexistentes foram preservadas.

## Decisões confirmadas pelo usuário

- **Opt-out:** medir inicialmente, respeitar GPC e oferecer recusa/alteração posterior da preferência.
- **90 dias de eventos detalhados.** Uma eventual retenção maior de agregados comerciais exige desenho separado; não está implementada nem deve ser presumida.
- **SC** permanece o piloto controlado, comparando “Ache sua corrida” e “Monte seu histórico”. Expansão pode incluir SP. Verba não definida; nenhuma campanha externa foi criada.

## Próximo pacote na data desta rodada — implementado na continuação, não ativado

1. Integrar recusa e mudança de preferência à interface, conectadas ao opt-out técnico existente. Recusa deve parar a fila e remover identificadores persistidos; não prometer apagar retroativamente eventos anteriores.
2. Implementar e testar retenção de 90 dias e expiração/rotação dos identificadores, com execução operacional verificável. Não manter armazenamento indefinido por ausência de rotina.
3. Excluir bots/sinais de navegação especulativa e limitar a frequência de requisições. HMAC não prova presença humana.
4. Configuração persistente e segregada por ambiente, defaults desligados e segredo operacional fora do Git. Não criar endpoint público para ligar a medição.
5. Atualizar e revisar o aviso de privacidade conforme o comportamento real, homologar páginas completas e login/permissões reais. Só depois aplicar migração e publicar/habilitar produção.

## Pergunta sobre logout do Business

As alterações de audiência desta continuação não mudaram autenticação. Às 03:10 UTC de 07/09, os hashes remotos de `Application.cfc` e `includes/backend/backend_login.cfm` correspondiam ao checkout e os arquivos publicados tinham timestamp de 05/09. O processo Java do ColdFusion estava em execução desde 01/09, sem reinício durante esta homologação. Não foi aberto navegador nem enviada qualquer sessão/cookie do usuário nos testes.

A atualização de segurança Business publicada em 05/09 trocou o reconhecimento de identidade legado por `SESSION.businessAuthenticatedIdentity` validado. O registro dessa publicação já avisava que sessões antigas poderiam precisar de novo login. O timeout de sessão de **50 minutos** já existia antes. Esses são mecanismos plausíveis para o novo login, mas não identificamos o evento exato da sessão do usuário. Se ocorreu durante uso ativo, a investigação deve continuar antes de atribuir a causa à expiração. A escolha de conta não foi adicionada pela medição; o botão Google já tinha seleção e prompt automáticos desativados.

## Método e referências

As skills `superpowers:executing-plans`, `superpowers:systematic-debugging`, `superpowers:test-driven-development` e `superpowers:verification-before-completion` orientaram a sequência: reproduzir no runtime real, isolar cada fronteira, corrigir minimamente e repetir os contratos. Revisão independente conferiu isolamento e preservação dos contratos.

Referências técnicas primárias: [datasources de aplicação Adobe](https://helpx.adobe.com/dk/coldfusion/cfml-reference/application-cfc-reference/application-variables.html), [getApplicationMetadata](https://helpx.adobe.com/coldfusion/cfml-reference/coldfusion-functions/functions-e-g/getapplicationmetadata.html), [JavaCast](https://guides.adobe.com/coldfusion/en/docs/cfml-reference/__references__/javacast.html), [QueryExecute](https://guides.adobe.com/content/coldfusion-docs/en/docs/cfml-reference/queryexecute.html). O defeito com o literal SQL foi comprovado pelo experimento nativo, não inferido dessas referências.
