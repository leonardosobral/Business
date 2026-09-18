# Descrições de eventos em português, inglês e espanhol

O Business preenche `tb_evento_corridas.descricao` com uma reescrita de
`descricao_original`, usando a API da OpenAI diretamente. Também traduz a
descrição portuguesa publicada (`descricao`) para `descricao_en` e `descricao_es`.
O n8n não participa deste fluxo. O mesmo cron oferece agenda, execução manual e
histórico; cada execução processa até três etapas, cada uma sendo um evento em um idioma.

## Contrato

`POST https://business.roadrunners.run/api/event-description-rewrite.cfm`

```json
{"limit":1,"dryRun":true,"language":"auto"}
```

`eventId` pode restringir a consulta a um evento. `language` aceita `auto`
(padrão), `pt-BR`, `en` ou `es`. `limit` aceita inteiros de 1 a 3 (padrão 1).
Cada etapa pode precisar de duas chamadas à IA. O lote tem orçamento de 85 segundos;
cada chamada usa no máximo 45 segundos, reduzidos ao tempo restante. Com menos de
10 segundos disponíveis, outra etapa não é iniciada. Isso preserva margem para
finalizar a resposta dentro dos 110 segundos do endpoint e 120 segundos do cron.
O limite é de etapas, não de provas completas: três etapas podem concluir os
três idiomas de uma prova ou avançar por provas diferentes.
O padrão é `dryRun=true`; a simulação consome chamadas à IA, retorna uma prévia
e não altera os eventos nem a auditoria. A prévia continua limitada a uma etapa, mesmo com `limit=3`. Uma tradução reaproveitada da auditoria
não faz novas chamadas à IA. Cada item de `results` informa o idioma efetivamente
processado e `durationMs`; traduções também informam `reused`.

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
- As traduções usam somente `descricao` como fonte, mantendo português e original
  intactos. Publicam no campo do idioma escolhido após a mesma verificação factual
  em duas etapas. A comparação final exige fonte portuguesa e campo de destino
  exatamente iguais aos valores lidos, incluindo a distinção entre `NULL` e vazio.
- Uma tradução preenchida somente é atualizada se ainda coincidir com a última
  saída publicada pelo cron para aquele idioma e a fonte portuguesa tiver mudado.
  Traduções manuais preexistentes ou editadas após o cron são preservadas.
- O mesmo `UPDATE` grava, em `descricao_traducoes_meta`, os hashes MD5 da fonte
  portuguesa e do texto publicado para o idioma, preservando os metadados do
  outro idioma. O site identifica traduções desatualizadas por essa marca, sem
  obter acesso à auditoria privada do Business.

## Fila e auditoria

Aplicar `schema.sql` com o proprietário já usado pelo datasource Business. Não
há criação de usuários, credenciais ou concessão de permissões.

`public.tb_evento_descricao_rewrites` guarda fonte, hash, descrição anterior,
descrição gravada, modelo, status e horários. Um lock transacional evita duas
etapas simultâneas. A gravação de cada etapa e sua auditoria são atômicas e
confirmadas antes de selecionar a próxima. Uma falha posterior não desfaz as
etapas anteriores. O lote não repete um par evento/idioma na mesma execução.
`public.tb_evento_descricao_translations` mantém auditoria separada por idioma e
tentativa, com os mesmos dados, contador de tentativas, próximo retry e vínculo
com a validação anterior quando uma saída é reaproveitada. `metadata_before`
preserva o bloco anterior do idioma para permitir restauração conjunta.

A fila `auto` prioriza eventos ainda não encerrados, depois o ID do evento e a
ordem português, inglês, espanhol. Assim, termina os idiomas de um evento antes
de seguir para o próximo. Uma tradução rejeitada, aguardando retry ou com erros
esgotados não impede o outro idioma ou os demais eventos de avançarem. A CTE
em `queue.cfm`, função `eventDescriptionQueueSql()`, é compartilhada pelo cron
e pelo painel de contadores, sem fazer chamadas à IA.

Uma versão de fonte já processada ou rejeitada não é tentada automaticamente de
novo. Falhas do provedor também ficam registradas, evitando repetição de custos.
Uma alteração real em `descricao_original` cria uma nova versão elegível se a
descrição continuar vazia. O MD5 identifica versões; não é usado como credencial
nem substitui a comparação exata do texto antes da gravação. Esse comportamento
de reescrita portuguesa foi preservado.

Para traduções, a deduplicação usa evento, idioma, hash e fonte portuguesa exata.
Rejeições factuais não são repetidas para a mesma versão/idioma. Falhas do
provedor têm no máximo três tentativas: o primeiro retry espera cinco minutos,
o segundo espera trinta. Após a terceira falha, a versão fica em
`errors_exhausted` para revisão operacional. Uma nova fonte tem histórico próprio.
Não há ciclos automáticos ilimitados de retry.

Uma saída já validada pode ser reaplicada sem IA quando a fonte muda de A para B
e volta para A, ou quando o campo traduzido é esvaziado. A auditoria registra a
reaplicação e sua origem em `reused_from_id`. A regra de preservar edição manual
também se aplica ao reaproveitamento. Uma tradução só corresponde à fonte atual
quando seus metadados contêm `source_hash=md5(descricao)` e
`description_hash=md5(campo_traduzido)`. Ausência de marca para o idioma ou texto
modificado após a publicação identificam conteúdo manual; dados malformados
na marca não devem autorizar a exibição de uma tradução antiga.

HTTP: `200` sucesso/prévia/fila vazia; `400` parâmetros; `401` assinatura; `405`
método; `409` execução em andamento; `422` reescrita rejeitada; `502` falha da IA;
`503` configuração, schema ou execução indisponíveis. Falhas não usam HTTP 200,
pois o cron classifica o resultado pelo status HTTP. Em lotes mistos, uma etapa
bem-sucedida não apaga o erro anterior: resultados e contadores mostram o progresso
confirmado. `stopReason=time_budget` é uma parada normal (HTTP 200 na ausência de
outros erros): a etapa interrompida é revertida e fica disponível para a próxima
execução, sem registrar rejeição nem consumir tentativa de retry. Uma exceção
inesperada retorna 503 com os resultados já confirmados e `stopReason=execution_error`.

## Instalação e operação

1. Pausar este cron, aplicar `schema.sql` e publicar o serviço, os dois templates
   CFML e `queue.cfm`. A migração adiciona os dois campos TEXT, o campo JSONB de
   metadados e a auditoria de traduções; é idempotente e preserva a auditoria
   portuguesa.
2. Aplicar `administracao/cron-jobs/event_description_rewrite_job.sql`. O cadastro
   é idempotente e começa pausado, com simulação, a cada cinco minutos.
3. Validar uma prévia e uma execução unitária, comparando os dados antes/depois.
4. No gerenciador `/administracao/cron-jobs/`, usar `{"limit":3,"dryRun":false}`
   e ativar o job após a validação. Na operação atual, a agenda é de um minuto;
   `language` omitido equivale a `auto`. Não manter outro agendamento n8n equivalente.
5. Acompanhar o histórico. Fontes rejeitadas podem ser tratadas pela edição de
   conteúdo já existente em `/eventos/`; o cron não as republica automaticamente.

Reaplicar o SQL de cadastro preserva agenda, corpo e estado de um job existente.
O código antigo no RunnerHub permanece preservado; nenhuma rota antiga foi
redirecionada ou removida por esta migração.

O painel `/administracao/cron-jobs/descricoes.cfm` mostra etapas pendentes,
novas tentativas e itens para revisão por idioma. Atualiza a cada 30 segundos
enquanto estiver visível. Cada idioma conta como uma etapa; as traduções de um
evento entram na contagem quando a descrição portuguesa fica pronta.

O agendador atual calcula o próximo horário um minuto após o término da chamada.
Como o runner consulta tarefas vencidas a cada minuto, a cadência observada com
essa configuração é de aproximadamente dois minutos entre inícios. Uma cadência
fixa por horário de início exige alteração no agendador central, que foi mantido
nesta entrega.

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
Para traduções, comparar `descricao` com `source_text` e restaurar somente o
campo de idioma da auditoria, incluindo o `NULL` anterior quando aplicável, e o
bloco do mesmo idioma em `descricao_traducoes_meta` a partir de `metadata_before`,
no mesmo `UPDATE`. Se o bloco anterior era ausente, remover apenas essa chave.
Conferir também que a marca atual ainda corresponde à saída sendo revertida e
preservar sempre o bloco do outro idioma.
Não restaurar por cima de uma edição posterior. Conservar a auditoria e o recibo
de publicação; arquivos novos podem ser retirados após a pausa, conferindo seus
hashes para não apagar alterações posteriores.

Referências da integração: [Responses com saída estruturada](https://developers.openai.com/api/docs/guides/structured-outputs)
e [modelo GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
