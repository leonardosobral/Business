# Fila administrativa de importações de resultados

## Objetivo

A rota `/administracao/importacoes-resultados/` oferece uma visão operacional da
tabela `public.tb_resultados_importacoes` e um ponto de entrada manual para o
adaptador RaceTag Pro.

Ela não utiliza a telemetria do Apache e não faz parte do Monitor da API. Cada
linha da visão principal representa a chamada mais recente de um evento externo.
O link **Histórico** abre todas as submissões persistidas daquele grupo.

A entrada na fila usa **Processamento: Pendente** por padrão. A opção **Todos**
continua disponível e é preservada nos links de atualização, paginação e detalhes
por `status=` explícito. O histórico de um evento não herda o padrão Pendente:
continua mostrando todas as suas chamadas, inclusive canceladas e arquivadas.

## Acesso

- administradores internos podem consultar todas as submissões;
- usuários de conta precisam da capacidade `result_imports.view` para o seu papel;
- sem integração ativa em `tb_conta_integracoes_resultados`, a página permanece
  acessível, mas a fila fica vazia e o processamento não pode ser iniciado;
- usuários de conta veem somente submissões compatíveis com o `client_id`,
  `cod_timer` e escopo de `external_account_id` da integração;
- usa o datasource padrão `runner_dba` do Business;
- não exibe tokens nem o `payload_hash` da submissão;
- a listagem não altera o estado por `GET`;
- o processamento exige confirmação em uma segunda tela e `POST` com CSRF.

Submissões `pendente` ou `falhou` podem ser descartadas por usuários com
`result_imports.process`. O descarte usa `POST` com CSRF e repete a validação do
escopo no `UPDATE`; ele altera o estado para `cancelado`, preservando o registro
e a chave de idempotência. Canceladas ficam fora da listagem sem filtro, mas
continuam disponíveis pelo indicador/filtro **Canceladas**.

## Informações exibidas

- identificador público e identificador interno;
- data de recebimento, início, processamento e atualização;
- cliente da API e código do cronometrador;
- status de publicação recebido: `extraoficial`, `final` ou `atualizacao`;
- intenção recebida no payload da API em `open_results_enabled`, exibida como
  **Importar** ou **Não importar** sem consultar a origem remota;
- status de processamento: `pendente`, `processando`, `processado`, `falhou` ou
  `cancelado`;
- evento associado e referências de evento informadas pelo integrador;
- URLs dos dados e da publicação oficial;
- tentativas, total de resultados e eventual erro;
- `Idempotency-Key`, útil para reconciliar reenvios.

Quando ainda não há vínculo Road Runners, a coluna de evento mostra a primeira
referência disponível entre a tag informada, o `external_event_id`, o fragmento
ou último segmento da URL pública e o ID presente em `.../data/{id}/event.json`.
Quando há um único vínculo anterior bem-sucedido ou uma URL específica coincidente
com `url_resultado`/`url_wiclax` de um evento ativo, esse evento aparece como
pré-selecionado também no importador. A confirmação continua manual; ambiguidade
não gera escolha automática nem alteração do cadastro por GET.

O valor persistido de `open_results_enabled` é a intenção declarada pelo provedor
no momento da submissão. Ele orienta a fila, mas não substitui a validação feita
pelo processador: quando o `event.json` informa um `openResultsEnabled` booleano
válido, esse valor prevalece.

## Filtros

A lista pode ser filtrada por busca livre, status de processamento, status de
publicação, cronometrador, cliente e período. Os indicadores respeitam período,
publicação, cronometrador, cliente e busca; o filtro de processamento é aplicado
somente à lista para permitir comparar os estados no mesmo recorte.

## Agrupamento e arquivamento (14/09/2026)

- A identidade é isolada por `client_id`, `cod_timer` e `external_account_id`.
  A URL técnica `data/{id}/event.json` tem preferência; depois vem a URL pública
  RaceTag com fragmento de evento. Uma URL genérica não identifica uma prova:
  nesses casos usa-se o ID externo com sua origem, ou mantém-se a chamada isolada.
- URLs são comparadas integralmente (apenas espaços e barras finais são
  normalizados), nunca por `LIKE '%slug%'`. Eventos de outro domínio não são
  vinculados só por terem o mesmo slug. Casos inconclusivos exigem escolha manual.
- A chamada representativa é escolhida antes dos filtros da visão principal;
  filtrar publicação não promove uma versão anterior como se fosse a última.
- O corte usa `(data_recebimento, id_resultado_importacao)` da submissão que foi
  processada com sucesso, **não** a hora em que o processamento terminou. Empates
  no recebimento são desempatados pelo ID sequencial.
- Após sucesso, chamadas anteriores `pendente`/`falhou` são arquivadas na mesma
  transação: estado persistido `cancelado`, `erro_codigo = superseded`, e referência
  à submissão substituta. Não apaga linhas, IDs nem chaves de idempotência.
- Registros `processando`, `processado` e cancelamentos manuais não são alterados
  por essa limpeza. Chamadas posteriores permanecem disponíveis.
- O backlog anterior à implantação recebe a classificação **Arquivado** por
  consulta quando já existe sucesso posterior. Não há migração nem escrita por
  GET. A mesma consulta impede o processamento via links antigos.
- O importador serializa pelo evento externo e revalida o corte dentro da
  transação antes de carregar resultados, inclusive para abas abertas anteriormente.
- **Arquivadas** e **Canceladas** são filtros distintos. O histórico mantém ambos.
  Indicadores operacionais contam eventos; os de arquivo/cancelamento contam chamadas.

Implementação compartilhada: `services/ResultImportQueueService.cfc` e SQLs em
`services/queries/` (bloqueados para HTTP por `.htaccess`). Não muda a API pública,
não cria cron e não busca arquivos remotos ao abrir a fila.

Validação local integrada: `node _codex/scripts/test_result_import_groups.mjs`
(PostgreSQL temporário + CommandBox/Lucee existentes). Compilação nativa Adobe CF
e backup/hash-check fazem parte de `_codex/scripts/deploy_result_import_groups.py`.

## Processamento manual RaceZone

Submissões com `cod_timer = racezone` e estado `pendente` ou `falhou` exibem uma
ação que abre `/racetag/` na mesma aba quando o papel também possui
`result_imports.process`. A tela:

1. lê `data/events.json` quando disponível;
2. resolve o `event.json` pelo ID externo ou slug da URL pública;
3. valida que o documento possui percursos RaceTag Pro;
4. sugere eventos Road Runners pela sobreposição do período com um dia de
   tolerância antes e depois, na mesma UF, priorizando a
   mesma cidade;
5. exige confirmação explícita do vínculo;
6. executa o processador legado completo e mantém seu feedback detalhado;
7. atualiza a submissão para `processando`, `processado` ou `falhou`.

O menu administrativo também expõe o importador para uso manual sem uma
submissão da fila. Esse modo avulso permanece exclusivo de administradores
internos; usuários externos sempre começam por uma submissão autorizada da fila.
O cron/worker automático continua fora desta fase.

## Configuração da conta

A conta do provedor não precisa possuir eventos em `tb_conta_eventos`. Um
administrador configura capacidades e integrações na aba **Acessos** de
`/administracao/contas/`, após aplicar:

```text
_codex/sql/2026-08-06_tb_conta_permissoes_integracoes_resultados.sql
```

Para a credencial RaceZone atual, o cadastro esperado usa `client_id` igual ao
valor configurado na API, `cod_timer = racezone` e a opção de abranger todas as
contas externas quando a conta Business representar o próprio provedor.
