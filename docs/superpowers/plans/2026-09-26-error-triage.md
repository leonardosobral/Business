# Acompanhamento de erros — plano de implementação

**Concluído e publicado em 26/09/2026.** As listas abaixo preservam o roteiro planejado. Resultados efetivos e adaptações estão em `_codex/docs/2026-09-26_error_triage_execution.md`; recibo operacional em `_codex/docs/2026-09-26_error_triage.md`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Não criar commits: a instrução do projeto prevalece sobre as recomendações dessas skills.

**Goal:** Permitir acompanhar, classificar e tratar os problemas originados nos logs pela área administrativa já existente.

**Architecture:** O Business lê `tb_log` em lotes e mantém problemas, vínculos e histórico em tabelas adicionais. Serviços CFML cuidam de normalização e persistência; a página existente ganha uma fila persistente, edição e exportação autenticada.

**Tech Stack:** Adobe ColdFusion/CFML, PostgreSQL, MDBootstrap, testes CFML e Node existentes, publicação seletiva via SSH.

**Spec:** `docs/superpowers/specs/2026-09-26-error-triage-design.md`, aprovada pelo usuário em 26/09/2026.

## Global Constraints

- Business é dono do acompanhamento; nenhum runtime de RoadRunners será alterado.
- Preservar `tb_log`, autenticação existente e a alteração preexistente de `includes/estrutura/sidenav.cfm`.
- Não configurar automação, executar chamadas de IA ou alterar os e-mails nesta entrega.
- Migração explícita e aditiva; nenhuma criação de tabelas em GET.
- Acesso administrativo; POST com CSRF para escritas; SQL parametrizado e HTML escapado.
- Publicar após verificações, baseline e backup recuperável; não criar commit, branch, tag, push ou PR.
- Registrar decisões e resultados em `_codex/docs/2026-09-26_error_triage_execution.md` para continuidade entre sessões.

## Review Focus

- Logs antigos com HTML incompleto: manter ocorrência individual quando faltar identidade técnica; não agrupar apenas por URL.
- IDs confirmados fora de ordem: a fronteira de IDs não pode excluir definitivamente um registro confirmado tardiamente.
- Duas edições ou coletas simultâneas: não duplicar vínculo, contador ou histórico; rejeitar edição de versão vencida.
- Erro anterior à publicação coletado depois: não reabrir; ocorrência realmente posterior deve reabrir uma vez.
- Segredos em mensagem, caminho ou nota: exportar somente conteúdo filtrado; em caso de dúvida, omitir texto mantendo metadados.

## Arquivos e responsabilidades

Novos arquivos:

- `_codex/sql/2026-09-26_error_triage.sql`: migração aditiva; não servir como download público.
- `portal/erros/includes/ErrorNormalizer.cfc`: extração permitida, assinatura e filtragem para exportação.
- `portal/erros/includes/ErrorTriage.cfc`: consultas, coleta, edição, vínculo/separação, histórico e exportação.
- `portal/erros/includes/init.cfm`: contexto autenticado, disponibilidade do schema, filtros e dados da tela.
- `portal/erros/includes/actions.cfm`: validação de POST/CSRF, chamadas do serviço e redirecionamento após gravação.
- `portal/erros/includes/workspace.cfm`: fila, resumo da coleta, detalhe do problema e formulários.
- `portal/erros/export.cfm`: download JSON administrativo, limitado aos problemas selecionados.
- `portal/erros/assets/triage.js`: seleção para exportar e prevenção de duplo envio, sem regras de autorização no cliente.
- `portal/erros/assets/triage.css`: ajustes responsivos escopados à nova área.
- `_codex/tests/error-triage-normalizer.cfm`, `error-triage-service.cfm`, `error-triage.test.cjs`: comportamento e fronteiras HTTP/UI.
- `_codex/scripts/deploy_error_triage.py`: preparar, compilar, publicar, verificar hashes e restaurar somente o escopo.
- `_codex/docs/2026-09-26_error_triage.md`: operação, comandos de teste e recibo da publicação.

Arquivos existentes a alterar:

- `portal/erros/index.cfm`: carregar inicialização e ações depois dos guards e antes de produzir HTML.
- `portal/erros/home.cfm`: incluir a fila e mostrar o vínculo/status nos detalhes e na lista de logs.
- `portal/includes/error_log_backend.cfm`: consultar vínculos dos IDs exibidos em uma consulta adicional, somente quando o schema estiver disponível.

## Task 1: Modelo de dados e normalização

**Interfaces:** `ErrorNormalizer.normalize(struct log) -> struct` retorna `signature`, `signatureVersion`, `suggestedCategory`, `title`, `path`, `technicalMessage`, `confidence`. `safeExportText(string value) -> string` retorna conteúdo filtrado ou vazio.

- [ ] Escrever testes CFML com fixtures sintéticas para repetição com query strings diferentes, mesma rota com exceções distintas, sites distintos, linha deslocada, 404 e HTML malformado. Esperar assinatura igual somente para o mesmo defeito; fallback individual inclui `id_log`.
- [ ] Executar o teste no runtime isolado de validação e registrar falha pela ausência do normalizador.
- [ ] Implementar extração de campos de exceção com limites de tamanho, sem executar/renderizar o HTML. Não interpretar a primeira URL do dump como caminho técnico confiável. Usar hash SHA-256 de uma representação com separadores inequívocos e versão explícita.
- [ ] Testar filtragem de e-mail, IP, UUID de usuário, cookie, bearer token, senha, query string e valores de formulário. A exportação não deve incluir nenhum valor sensível das fixtures; texto não reconhecido deve ser omitido.
- [ ] Criar migração com as tabelas abaixo; usar o padrão de schema `public` e datasource `runner_dba`, sem alterar grants ou owner existentes:
  - `tb_error_problem`: ID, assinatura única, versão da assinatura, site, título, categoria sugerida e efetiva, status, primeira/última ocorrência, contador, análise, proposta, evidências, horário efetivo de publicação, responsável, versão e timestamps.
  - `tb_error_occurrence`: `id_log` único, problema, horário e metadados técnicos filtrados. Sem FK para `tb_log`, para que retenção futura do log não apague o acompanhamento.
  - `tb_error_history`: ID, problema, ação, estado anterior/novo, autor, nota e timestamp; índice por problema e ID.
  - `tb_error_collector`: uma linha com início do recorte, fronteira do ciclo, último ID processado e timestamps.
- [ ] Definir checks de status (`new,investigating,ready,published,verified,ignored,reopened`) e categoria (`unclassified,code,database,external,input,not_found`), contador não negativo, versão positiva e índices de fila/site/status.
- [ ] Executar a migração duas vezes em schema de teste transacional e verificar idempotência, unicidade de vínculo e assinatura, checks e preservação de dados. Reexecutar os testes do normalizador; esperar zero falhas.

## Task 2: Coleta idempotente e recorrência

**Consumes:** normalizador e schema da Task 1.

**Interfaces:** `ErrorTriage.collect(numeric actorId) -> struct` retorna `processed`, `newProblems`, `reopened`, `remaining`, `startedAt`, `upperId`; `ready() -> boolean`. Construtor recebe datasource/schema apenas do código, validados como identificadores, para executar os mesmos métodos em schema de teste isolado.

- [ ] Escrever testes de lote de 200, repetição de lote, duas coletas concorrentes, falha antes de confirmar cursor e log confirmado tardiamente com ID menor. Esperar cada ocorrência vinculada exatamente uma vez.
- [ ] Executar e registrar as falhas antes de implementar o coletor.
- [ ] Implementar transação com bloqueio da linha do coletor, timeout limitado e captura da fronteira superior do ciclo. Fixar início em sete dias antes da primeira coleta. Filtrar exclusivamente `erro` e `404`.
- [ ] Processar no máximo 200 registros por ação. O vínculo único governa incrementos; atualizar cursor na mesma transação. Consultar pendências até a fronteira capturada; registros novos entram no ciclo seguinte.
- [ ] Ao concluir um ciclo, reconciliar registros ainda sem vínculo desde o início fixo do recorte, inclusive IDs menores que o cursor. A releitura não depende apenas de uma janela curta, evitando perder commits muito tardios. Não avançar o ponto inicial automaticamente nem varrer outros tipos de log.
- [ ] Escrever testes de recorrência: publicado/verificado + ocorrência posterior reabre; ocorrência anterior não reabre; ignorado preserva status; segundo log após reabertura não duplica evento de reabertura.
- [ ] Implementar recorrência por horário de origem comparado ao horário efetivo de publicação, com bloqueio do problema. Preservar análise, categoria humana e responsável; incrementar versão quando o problema for alterado.
- [ ] Executar integração em schema de teste e medir consulta no recorte real em modo somente leitura. Se o banco não sustentar o limite/timeout, ajustar consulta/índice aditivo antes de avançar; não aceitar uma coleta que bloqueie a aplicação.

## Task 3: Gestão e exportação

**Consumes:** schema, normalizador e serviço da Task 2.

**Interfaces:** métodos `list(struct filters)`, `detail(numeric id)`, `save(numeric id,numeric expectedVersion,struct fields,numeric actorId)`, `moveOccurrence(numeric logId,numeric targetId,numeric sourceVersion,numeric targetVersion,string reason,numeric actorId)`, `splitOccurrence(numeric logId,numeric sourceVersion,string reason,numeric actorId)`, `exportProblems(array ids)`. Nenhum método remoto.

- [ ] Escrever testes de edição válida, versão vencida, categoria inválida, nota obrigatória para ignorar/reabrir, publicação sem horário/evidência e verificação sem evidência. Esperar rollback completo nos casos inválidos.
- [ ] Implementar gravação com versão e histórico na mesma transação. Limitar título a 180 caracteres e cada nota a 8.000; não truncar silenciosamente texto enviado pelo usuário.
- [ ] Testar vínculo/separação: origem e destino devem existir e ter o mesmo site; atualizar contagens e primeira/última ocorrência; registrar histórico em ambos. Rejeitar versão vencida sem mover nada.
- [ ] Implementar bloqueios em ordem crescente de ID para evitar deadlock. Separação cria assinatura individual com referência à ocorrência; registro vazio permanece auditável e é identificado como sem ocorrências. O coletor não desfaz vínculos manuais.
- [ ] Testar fila com problema fora da amostra recente, filtros combinados e paginação de 25 itens. Implementar contagem e lista com o mesmo filtro parametrizado; limitar página aos resultados existentes.
- [ ] Escrever teste de exportação de até 20 IDs, inexistentes/duplicados, caracteres HTML e instruções maliciosas presentes no log. Esperar JSON com versão do formato, metadados permitidos e aviso de conteúdo não confiável, sem HTML bruto ou dados pessoais.
- [ ] Implementar exportação usando o normalizador também sobre notas, retornar título/mensagem vazios quando não houver extração segura e não registrar o pacote em logs da aplicação.
- [ ] Executar todos os testes de serviço e normalização; esperar zero falhas e nenhuma fixture persistida fora do schema de teste.

## Task 4: Integração na área Portal → Erros

**Consumes:** métodos da Task 3; `qPerfil.id` e autorização administrativa existentes.

- [ ] Escrever testes HTTP para acesso anônimo, usuário sem permissão, acesso direto aos includes, GET de ação e POST sem CSRF. Esperar nenhum dado exportado e nenhuma mutação.
- [ ] Implementar inicialização e ações antes de qualquer output. Gerar token de sessão próprio; conferir método, token e autorização em todas as ações. Usar Post/Redirect/Get em sucesso e preservar formulário em conflito/erro de validação.
- [ ] Renderizar fila, filtros, contagens processadas, recorte inicial e botão “Processar próximo lote”. Não executar coleta em GET. Exibir “Instalação do acompanhamento pendente” se faltarem tabelas, preservando a consulta original.
- [ ] Renderizar detalhe com status, categoria, responsável, análise, proposta, publicação, verificação, histórico e ocorrências paginadas. Adicionar ações de vincular/separar com justificativa.
- [ ] Adicionar status e link do problema aos logs já exibidos. Carregar os vínculos em lote; evitar uma consulta por linha. Diferenciar “Ainda não processado” de “Novo”.
- [ ] Implementar seleção de até 20 problemas e download JSON via POST administrativo com CSRF, `Cache-Control: no-store` e `Content-Disposition: attachment`. Não oferecer link GET que contenha token.
- [ ] Testar JS com `node --test _codex/tests/error-triage.test.cjs`; verificar limite de seleção e prevenção de duplo envio. Inspecionar desktop 1440px e mobile 390px no navegador, incluindo formulário longo e mensagem de conflito.
- [ ] Executar os testes HTTP de autorização/CSRF e a regressão da consulta original. Esperar zero falhas; registrar screenshots sem conteúdo sensível.

## Task 5: Revisão, publicação e verificação real

**Consumes:** runtime e testes das Tasks 1–4.

- [ ] Comparar o escopo final com a especificação e realizar revisão independente antes de publicar; registrar achados e correções com seus testes.
- [ ] Escrever/testar o publicador com diretório temporário local: conflito de hash aborta antes de escrever; arquivo novo preexistente aborta; backup recuperável; upload incompleto não troca a entrada; rollback não sobrescreve mudança posterior.
- [ ] Capturar hashes e metadados dos três arquivos existentes em produção e confirmar ausência dos novos destinos. Copiar somente esse baseline para backup privado. Não incluir `sidenav.cfm` ou outras alterações locais.
- [ ] Compilar candidatos com `/opt/ColdFusion/cfusion/bin/cfcompile.sh` em diretório privado. Usar fixtures sem dados reais e executar testes CFML no runtime de homologação protegido; não aceitar apenas testes de correspondência textual.
- [ ] Conferir conectividade, schema e privilégios existentes. Aplicar a migração aditiva explicitamente em transação pelo mecanismo operacional do projeto. Se faltar acesso, informar bloqueio sem alterar credenciais ou grants.
- [ ] Revalidar baseline imediatamente antes da troca. Publicar dependências primeiro, depois backend, home e entrada. Preservar modos/owner; registrar hashes depois da cópia.
- [ ] Testar sem autenticação e com sessão administrativa: abrir fila e logs, processar um lote real, exportar um pacote e conferir que a segunda coleta não duplica ocorrências. A coleta inicial não deve alterar status humanos.
- [ ] Validar edição e conflito com fixtures identificáveis em transação reversível; não marcar erros reais como resolvidos apenas para teste. Remover mecanismos temporários de verificação e confirmar inacessibilidade pública.
- [ ] Registrar arquivos publicados, backup, migração, testes, resultado HTTP e limitações em `_codex/docs/2026-09-26_error_triage.md`. Em falha de runtime, restaurar arquivos do baseline sem apagar as tabelas novas.

## Revisão do plano

Cobertura: tela existente, categorias/status, persistência, agrupamento,
processamento limitado, concorrência, recorrência, histórico, exportação,
acesso administrativo, testes e publicação correspondem às Tasks 1–5.
Nenhuma nova dependência, chamada à IA ou alteração no produtor de logs.

Execução proposta: nesta sessão, com implementação sequencial e revisão
independente ao final. As etapas dependem dos mesmos contratos; agentes de
implementação paralelos acrescentariam coordenação sem acelerar essa sequência.
