# Fila administrativa de importações de resultados

## Objetivo

A rota `/administracao/importacoes-resultados/` oferece uma visão operacional da
tabela `public.tb_resultados_importacoes` e um ponto de entrada manual para o
adaptador RaceTag Pro.

Ela não utiliza a telemetria do Apache e não faz parte do Monitor da API. Cada
linha representa uma submissão realmente persistida pelo endpoint de integração
de resultados.

## Acesso

- somente usuários administradores;
- usa o datasource padrão `runner_dba` do Business;
- não exibe tokens nem o `payload_hash` da submissão;
- a listagem não altera o estado por `GET`;
- o processamento exige confirmação em uma segunda tela e `POST` com CSRF.

## Informações exibidas

- identificador público e identificador interno;
- data de recebimento, início, processamento e atualização;
- cliente da API e código do cronometrador;
- status de publicação recebido: `extraoficial`, `final` ou `atualizacao`;
- status de processamento: `pendente`, `processando`, `processado`, `falhou` ou
  `cancelado`;
- evento associado e referências de evento informadas pelo integrador;
- URLs dos dados e da publicação oficial;
- tentativas, total de resultados e eventual erro;
- `Idempotency-Key`, útil para reconciliar reenvios.

## Filtros

A lista pode ser filtrada por busca livre, status de processamento, status de
publicação, cronometrador, cliente e período. Os indicadores respeitam período,
publicação, cronometrador, cliente e busca; o filtro de processamento é aplicado
somente à lista para permitir comparar os estados no mesmo recorte.

## Processamento manual RaceZone

Submissões com `cod_timer = racezone` e estado `pendente` ou `falhou` exibem uma
ação que abre `/racetag/` em uma nova aba. A tela:

1. lê `data/events.json` quando disponível;
2. resolve o `event.json` pelo ID externo ou slug da URL pública;
3. valida que o documento possui percursos RaceTag Pro;
4. sugere eventos Road Runners pela sobreposição de data e UF, priorizando a
   mesma cidade;
5. exige confirmação explícita do vínculo;
6. executa o processador legado completo e mantém seu feedback detalhado;
7. atualiza a submissão para `processando`, `processado` ou `falhou`.

O menu administrativo também expõe o importador para uso manual sem uma
submissão da fila. O cron/worker automático continua fora desta fase.
