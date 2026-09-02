# Fila administrativa de importações de resultados

## Objetivo

A rota `/administracao/importacoes-resultados/` oferece uma visão operacional da
tabela `public.tb_resultados_importacoes` e um ponto de entrada manual para o
adaptador RaceTag Pro.

Ela não utiliza a telemetria do Apache e não faz parte do Monitor da API. Cada
linha representa uma submissão realmente persistida pelo endpoint de integração
de resultados.

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
Essa referência é apenas uma pista visual e não cria vínculo automaticamente.

O valor persistido de `open_results_enabled` é a intenção declarada pelo provedor
no momento da submissão. Ele orienta a fila, mas não substitui a validação feita
pelo processador: quando o `event.json` informa um `openResultsEnabled` booleano
válido, esse valor prevalece.

## Filtros

A lista pode ser filtrada por busca livre, status de processamento, status de
publicação, cronometrador, cliente e período. Os indicadores respeitam período,
publicação, cronometrador, cliente e busca; o filtro de processamento é aplicado
somente à lista para permitir comparar os estados no mesmo recorte.

## Processamento manual RaceZone

Submissões com `cod_timer = racezone` e estado `pendente` ou `falhou` exibem uma
ação que abre `/racetag/` em uma nova aba quando o papel também possui
`result_imports.process`. A tela:

1. lê `data/events.json` quando disponível;
2. resolve o `event.json` pelo ID externo ou slug da URL pública;
3. valida que o documento possui percursos RaceTag Pro;
4. sugere eventos Road Runners pela sobreposição de data e UF, priorizando a
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
