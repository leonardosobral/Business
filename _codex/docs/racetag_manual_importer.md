# Importador manual RaceTag Pro

## Objetivo

O módulo `/racetag/` é a etapa manual entre a fila pública de submissões e a
publicação dos resultados. Ele foi reativado para validar a integração RaceZone
antes de qualquer automatização por cron.

Somente administradores podem acessar ou executar o módulo.

## Diferenças entre os processadores encontrados

### `/RunnerHub/api/racezone`

- começa com um evento Road Runners já escolhido;
- recebe diretamente a URL de `event.json`;
- lê o `results.json` agregado;
- transforma os atletas em `tb_resultados_temp`;
- chama `gera_resultados` e `atualiza_classific_f1`;
- exibe grade temporária, grade final, totais e logs.

### `Business/_legado/racetag`

- contém essencialmente o mesmo processamento e o mesmo feedback;
- começa um passo antes, pela URL pública do RaceTag Pro;
- lê `data/events.json`, identifica o evento externo e tenta encontrar o evento
  Road Runners por local e datas;
- estava inacabado: dependia do separador não convencional `##`, perdia o estado
  ao trocar selects e exigia igualdade rígida entre `place` e `cidade`.

### Módulo ativo `/racetag/`

O módulo ativo mantém o processador detalhado de `_legado/racetag/parse.cfm`, mas
corrige a etapa anterior:

- aceita URL técnica `.../data/{id}/event.json` ou pública `.../#/{slug}`;
- usa `external_event_id` da fila quando disponível;
- reaproveita vínculo anterior do mesmo cliente, conta externa e evento externo;
- permite navegar pelos eventos retornados por `events.json`;
- sugere vínculos por datas e UF, priorizando cidade exata;
- preserva todos os campos do formulário entre as confirmações;
- exige `POST` com CSRF antes de alterar resultados;
- reserva e atualiza o estado da submissão da fila;
- executa carga, procedures e atualização da fila dentro de transação;
- atualiza `url_wiclax` e `url_resultado` somente após execução válida.

## Operação

Na fila administrativa, use o botão de engrenagens de uma submissão RaceZone
pendente ou com falha. A nova aba já recebe:

- URL técnica;
- URL pública;
- ID externo;
- evento Road Runners, se a API já o vinculou.

Confira o evento externo, confirme o evento interno e só então use **Processar
resultado agora**. O feedback detalhado do processador permanece na página para
inspeção inicial.

## Limites desta fase

- execução exclusivamente manual;
- formato atual RaceTag Pro com `results.json` agregado;
- nenhum evento Road Runners é criado automaticamente;
- o formato antigo com um arquivo `result/{route}.json` por percurso continua no
  processador separado `RunnerHub/api/racezone_legacy` e não foi ativado aqui;
- o adaptador ativo ainda inclui a transformação consolidada no diretório
  `_legado`; ela deve ser movida para um serviço próprio antes do cron.
