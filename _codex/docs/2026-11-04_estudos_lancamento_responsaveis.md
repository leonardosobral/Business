# Etapas do lançamento — responsável e observações

Publicado em 04/11/2026 em https://business.roadrunners.run/estudos/lancamento/.
Complementa o cronograma e checklist compartilhado publicados na mesma data.

Cada uma das oito etapas agora tem responsável (nome ou equipe, até 120 caracteres), observações sobre pendências/bloqueios/próximos passos (até 2.000 caracteres, com múltiplas linhas) e botão “Salvar informações”. Os campos podem ser limpos. O salvamento é compartilhado entre administradores e mostra quem atualizou e quando, em horário de Brasília.

Editar responsável ou observações não valida nem reabre a etapa. A revisão e o autor da validação continuam separados dos dados de acompanhamento. Rascunhos em outras etapas são preservados quando uma etapa é salva ou validada. Em conflito, a tela mantém o rascunho e exibe a versão atual da equipe; o usuário pode carregar essa versão ou salvar seu rascunho explicitamente sobre ela, ainda sujeito a nova conferência de revisão.

## Persistência e compatibilidade

Reutilizada a auditoria imutável `estudo.auditoria_comercial`, sem nova tabela ou migration. Entidade `launch_checklist`, produto `previa-2026-q3`, release `2026-q3-20261113`. Novos eventos `LAUNCH_STEP_DETAILS` guardam `step`, `responsible`, `notes` e `previous_version`. A projeção mantém revisão própria `details_version`, autor e data separados dos eventos existentes `LAUNCH_STEP_VALIDATION`.

O método anterior `adminValidateLaunchStep` foi preservado integralmente. O POST de `checklist.cfm` continua aceitando a chamada antiga sem `operation`, assumindo `validate`. A nova operação `details` requer os campos de acompanhamento e a revisão esperada. Ambas exigem sessão verificada, administrador pessoal e CSRF. A concorrência usa o lock transacional por etapa e comparação de revisão antes de acrescentar o evento. Não houve mudanças em notebook, queries, congelamentos, concessões ou vouchers.

## Arquivos e publicação

Cinco arquivos Business: `estudos/includes/StudyAccess.cfc`, `estudos/lancamento/index.cfm`, `estudos/lancamento/checklist.cfm`, `estudos/lancamento/checklist.js` e `estudos/lancamento/lancamento.css`.

Baseline conferido com produção, candidato compilado, publicação restrita com backup em `/var/backups/business-launch-responsibles-20261104/baseline` e cinco hashes verificados. Workspace sincronizado preservando as demais frentes. O Road Runners não foi alterado.

## Verificações executadas

- Serviço candidato: gravação e releitura por outra instância, acentos/apóstrofos/quebras de linha, codificação de saída HTML, autor e data, limpeza dos campos, limite de tamanho e rejeição de etapa/revisão inválidas.
- Validação e acompanhamento preservam reciprocamente seus dados; gravação sem mudança não cria revisão extra. Gravação com revisão desatualizada é rejeitada.
- Escrita por não administrador e acesso sem identidade verificada rejeitados. Todas as gravações do teste do serviço foram revertidas em transação e seus IDs confirmados ausentes.
- JavaScript passou em `node --check`; CFML compilado no servidor. Sem sessão: central 401, endpoint GET 405 e POST 401; JS e CSS 200.
- Chrome autenticado: oito formulários habilitados; edição mostra “Alterações não salvas”. Rascunho temporário foi apagado antes do envio, e o salvamento dos campos vazios percorreu a API real com sucesso, mantendo revisão 0 e validação pendente. Nenhum responsável ou observação de teste ficou salvo.
- Desktop 1533 px e celular 390 px sem transbordamento horizontal; campos móveis com fonte de 16 px. Cronograma permanece primeiro e materiais anteriores preservados.
- Aba própria 283508534 encerrada e ausência conferida, viewport restaurado, pasta temporária de imagens removida. Nenhum servidor de teste foi iniciado.

Recibos, testes, baselines e provas visuais em `_codex/staging/lancamento-responsaveis-20261104/`.

## Lista e conteúdo inicial

Em 04/11/2026, a apresentação foi convertida para linhas largas com edição expansível e as oito observações receberam o panorama do lançamento. Consulte [lista e observações centralizadas](2026-11-04_estudos_lancamento_lista_observacoes.md).
