# Reescrita de descrições de eventos

O Business preenche `tb_evento_corridas.descricao` com uma reescrita de
`descricao_original`, usando a API da OpenAI diretamente. O n8n não participa
deste fluxo. O cron existente oferece agenda, execução manual e histórico.

## Contrato

`POST https://business.roadrunners.run/api/event-description-rewrite.cfm`

```json
{"limit":1,"dryRun":true}
```

`eventId` pode restringir a consulta a um evento. `limit` deve ser 1: cada evento
pode precisar de duas chamadas à IA, dentro do timeout de 120 segundos do cron.
O padrão é `dryRun=true`; a simulação consome chamadas à IA, retorna uma prévia
e não altera os eventos nem a auditoria.

Autenticação: `X-RR-Handoff-Timestamp` e `X-RR-Handoff-Signature`, com
HMAC-SHA256 de `timestamp + "." + corpo` e janela de cinco minutos. O segredo é
`cronSecrets.business_internal` em `config/business.local.cfm`.

A chave vem de `OPENAI_API_KEY` ou `businessLocalConfig.openAiApiKey`. O modelo
padrão é `gpt-4.1-mini`, configurável por `businessLocalConfig.eventDescriptionModel`.
Esses valores são lidos a cada chamada; não é necessário reiniciar a aplicação.
Credenciais e URL do provedor não são aceitas no corpo da requisição.

## Preservação dos dados

- Apenas originais com mais de 200 caracteres e descrições nulas/vazias entram
  na fila. Eventos ainda não encerrados têm prioridade; eventos passados também
  podem ser processados, como no fluxo anterior.
- A fonte não é truncada. Texto normalizado acima de 20.000 caracteres é
  rejeitado para tratamento manual. HTML da fonte vira texto, preservando links.
- O prompt pede alteração de redação e organização, mantendo todos os fatos,
  inclusive nomes, datas, horários, distâncias, locais, largadas, kits, valores,
  regras, negações e informações ainda indefinidas. Dados do cadastro não são
  usados para corrigir o texto original.
- Uma validação local confere números, distâncias/unidades, horários e links.
  Uma segunda chamada compara os fatos e suas relações. Divergências impedem
  a gravação. Essas verificações reduzem o risco; não são uma prova matemática
  de equivalência factual. Casos ambíguos devem ser revisados.
- A saída é texto escapado para HTML, com `<br>` para quebras. Não é permitido
  HTML ativo gerado pela IA.
- O `UPDATE` altera somente `descricao` e exige que ela continue vazia e que
  `descricao_original` permaneça exatamente igual à fonte consultada. Não altera
  categorias, datas do cadastro, distâncias estruturadas ou `data_processamento`.

## Fila e auditoria

Aplicar `schema.sql` com o proprietário já usado pelo datasource Business. Não
há criação de usuários, credenciais ou concessão de permissões.

`public.tb_evento_descricao_rewrites` guarda fonte, hash, descrição anterior,
descrição gravada, modelo, status e horários. Um lock transacional evita duas
execuções simultâneas. A gravação do evento e a auditoria são atômicas.

Uma versão de fonte já processada ou rejeitada não é tentada automaticamente de
novo. Falhas do provedor também ficam registradas, evitando repetição de custos.
Uma alteração real em `descricao_original` cria uma nova versão elegível se a
descrição continuar vazia. O MD5 identifica versões; não é usado como credencial
nem substitui a comparação exata do texto antes da gravação.

HTTP: `200` sucesso/prévia/fila vazia; `400` parâmetros; `401` assinatura; `405`
método; `409` execução em andamento; `422` reescrita rejeitada; `502` falha da IA;
`503` configuração, schema ou execução indisponíveis. Falhas não usam HTTP 200,
pois o cron classifica o resultado pelo status HTTP.

## Instalação e operação

1. Aplicar `schema.sql` e publicar o serviço e os dois templates CFML.
2. Aplicar `administracao/cron-jobs/event_description_rewrite_job.sql`. O cadastro
   é idempotente e começa pausado, com simulação, a cada cinco minutos.
3. Validar uma prévia e uma execução unitária, comparando os dados antes/depois.
4. No gerenciador `/administracao/cron-jobs/`, usar `{"limit":1,"dryRun":false}`
   e ativar o job após a validação. Não manter outro agendamento n8n equivalente.
5. Acompanhar o histórico. Fontes rejeitadas podem ser tratadas pela edição de
   conteúdo já existente em `/eventos/`; o cron não as republica automaticamente.

Reaplicar o SQL de cadastro preserva agenda, corpo e estado de um job existente.
O código antigo no RunnerHub permanece preservado; nenhuma rota antiga foi
redirecionada ou removida por esta migração.

## Validação e recuperação

```sh
node _codex/scripts/test_event_description_rewrite_cfml_local.mjs
node _codex/scripts/test_event_description_endpoint_local.mjs
node _codex/scripts/test_event_description_sql.mjs
```

O primeiro executa o serviço em CFML isolado. Os outros usam PostgreSQL
descartável, cobrindo o fluxo do endpoint e suas consultas reais, sem conexão ao
banco de produção.

Para suspender, desativar apenas este job. Para reverter uma descrição específica,
usar `description_before` da auditoria somente se a descrição atual ainda for
exatamente `description_after` e o original continuar igual a `source_text`.
Não restaurar por cima de uma edição posterior. Conservar a auditoria e o recibo
de publicação; arquivos novos podem ser retirados após a pausa, conferindo seus
hashes para não apagar alterações posteriores.

Referências da integração: [Responses com saída estruturada](https://developers.openai.com/api/docs/guides/structured-outputs)
e [modelo GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
