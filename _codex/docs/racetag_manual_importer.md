# Importador manual RaceTag Pro

## Objetivo

O módulo `/racetag/` é a etapa manual entre a fila pública de submissões e a
publicação dos resultados. Ele foi reativado para validar a integração RaceZone
antes de qualquer automatização por cron.

Administradores internos podem acessar todas as submissões e manter o modo
avulso. Usuários de conta podem executar o módulo quando seu papel possui
`result_imports.process` e a submissão pertence a uma integração ativa da conta.

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
- reaplica o escopo da conta ao abrir e ao reservar a submissão;
- impede que usuários externos troquem a URL validada pela API ou processem uma
  submissão de outro cliente;
- reserva e atualiza o estado da submissão da fila;
- executa carga, procedures e atualização da fila dentro de transação;
- atualiza `url_wiclax` e `url_resultado` somente após execução válida.

O payload da API usa `open_results_enabled`. Ao ler `event.json`, a tela avalia
o campo original da RaceTag, `openResultsEnabled`:

- `true` no `event.json` autoriza o processamento normal, mesmo que o payload
  recebido anteriormente tenha informado `false`;
- `false` no `event.json` bloqueia a importação, mesmo que o payload tenha
  informado `true`;
- ausência usa a intenção persistida do payload da API; sem uma submissão da
  fila, mantém compatibilidade com fontes legadas e assume `true`;
- valor presente que não seja booleano bloqueia por segurança;
- somente administradores internos podem confirmar uma exceção manual para
  qualquer decisão efetiva de bloqueio. A exceção exige CSRF, confirmação
  explícita e é registrada no log `business_result_imports`.

| `event.json` | Payload persistido | Decisão normal | Fonte efetiva |
| --- | --- | --- | --- |
| `true` | qualquer valor | processar | `event.json` |
| `false` | qualquer valor | bloquear | `event.json` |
| inválido | qualquer valor | bloquear | `event.json` |
| ausente | `true` | processar | payload da API |
| ausente | `false` | bloquear | payload da API |
| ausente | inexistente | processar | compatibilidade legada |

A tela destaca separadamente a intenção recebida pela API, o valor atual do
`event.json`, eventuais divergências e a decisão efetiva. A fila administrativa
usa somente o valor persistido, sem fazer requisições remotas durante a listagem.

A resposta atual da fonte pode ser expandida na mesma tela para consultar status
HTTP, headers e o corpo bruto de `event.json`. A exibição do corpo é limitada aos
primeiros 256 KB e representa o conteúdo atual da URL, não uma fotografia do
momento em que a submissão chegou ao webhook.

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

Se a decisão efetiva bloquear o envio, o processamento normal não aparece. Uma
eventual exceção operacional deve ser executada por um administrador interno
usando **Processar manualmente mesmo assim**.

## Limites desta fase

- execução exclusivamente manual;
- o futuro cron deve aplicar a mesma regra de `openResultsEnabled` e nunca usar a
  exceção administrativa automática;
- contas externas precisam iniciar pela fila; somente administradores internos
  podem usar uma URL avulsa;
- formato atual RaceTag Pro com `results.json` agregado;
- nenhum evento Road Runners é criado automaticamente;
- o formato antigo com um arquivo `result/{route}.json` por percurso continua no
  processador separado `RunnerHub/api/racezone_legacy` e não foi ativado aqui;
- o adaptador ativo ainda inclui a transformação consolidada no diretório
  `_legado`; ela deve ser movida para um serviço próprio antes do cron.
