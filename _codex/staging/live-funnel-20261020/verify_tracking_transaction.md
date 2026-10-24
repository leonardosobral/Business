# Prova proposta de persistência LIVE pós-publicação

Status: **preparada, não executada remotamente**. Nenhuma inserção realizada por esta frente.

Arquivos revisáveis: `verify_tracking_transaction.py` (orquestração/bridge) e `verify_tracking_transaction.cfm` (fixture e assertions). O modo padrão apenas imprime plano/hash. `--execute` é a ação explícita do coordenador após publicação.

```sh
python3 _codex/staging/live-funnel-20261020/verify_tracking_transaction.py
python3 _codex/staging/live-funnel-20261020/verify_tracking_transaction.py --execute
```

O executor verifica que o SHA-256 do `AudienceMeasurementService.cfc` publicado corresponde ao manifesto revisado do release. Cria bridge temporário sob `_codex` do Business, protegido por `Require local`, POST e token aleatório, acessível apenas por loopback; apaga o diretório em `finally`. Não modifica o coletor, Application de produção, segredo de produção, usuários, autenticação, grants, migrações ou permissões existentes. A aplicação temporária mapeia o diretório real de serviços do RoadRunners.

A fixture usa o CFC publicado, com segredo efêmero em memória para gerar e validar seu próprio contexto assinado; `environment=prod`, `isInternal=true`, UUIDs novos e conteúdo sintético `9999999999`/`9999999998`. Não usa conta real, informação pessoal, cupom real, GCLID ou dados de navegação. O evento `isInternal` é a classificação de um contexto de teste e não concede acesso ao produto.

São oito registros: exposição, tentativa, sucesso e erro de cópia, informação, inscrição existente, cidade selecionada e todas as cidades. Antes da escrita, cinco variantes inválidas devem falhar em `validateBatch` (limiar, tempo, conteúdo divergente, kind divergente e campo Ads).

`persist()` usa o datasource **runnerhub**. Toda leitura/assertion da fixture usa exatamente esse datasource, evitando conexões distintas de `runner_dba`. Dentro da única transação:

1. Aplica limites locais de statement/lock, sem configuração permanente.
2. Executa `validateBatch` + `persist` reais, incluindo `audience.ingest_events` instalado.
3. Confere oito linhas, keys/kinds/IDs, contexto interno, origem/campanha e duração/ratio. Confere campos Ads vazios.
4. Usa `xmin` versus o ID da transação atual para provar que as linhas pertencem à transação que será revertida.
5. Reenvia os dois lotes. Confere que quantidade continua oito e hash das linhas não mudou. `accepted` pode continuar oito no replay porque a função conta os updates de `ON CONFLICT`; não tratar accepted=0 como condição de dedupe.
6. Executa rollback explícito. Fora da transação, exige zero linhas para os UUIDs sintéticos.

Uma exceção dentro da transação provoca rollback pelo bloco CFML. A saída de sucesso só existe após a consulta pós-rollback. Falha/timeout deve ser examinada antes de reexecutar; não tratar perda de resposta como sucesso. Nenhum código de retry automático ou modo commit existe.

Sucesso grava `tracking-transaction-verification.json` local, com `real_persistence=true`, `same_database_transaction=true`, `all_internal=true`, `deduplicated_rows=8`, `rows_after_rollback=0`, hash do serviço e UUIDs de teste.

## O que esta prova cobre

Prova execução do CFC publicado, rejeição de payload inválido, conexão/grants reais do datasource de ingestão, função SQL instalada, colunas, constraints, armazenamento e idempotência, com ausência final de dados sintéticos. Ela vai além de compile/unit/mock.

## Limite deliberado

**Não prova HTTP público de `/api/analytics/collect.cfm`**, decisão de host em APPLICATION, filtro bot/GPC/rate limiting nem emissão pelo navegador. `public_http_collector_tested=false` é explícito no resultado. Uma chamada HTTP válida separada usaria outra conexão e não participaria do rollback externo; por isso não se simula essa garantia. A validação CUA do coordenador após publicação complementa a prova, verificando asset efetivo, ações, POST/recepção e comportamento de consentimento.

Validações locais realizadas: parser Python do executor e código remoto; modo plano sem conexão; parser CFML com corpo dentro de `if(false)` (nenhuma chamada a serviço/datasource). Essas validações confirmam apenas sintaxe/preparação do script proposto, não o resultado do BD real.
