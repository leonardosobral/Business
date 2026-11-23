# Central de lançamento — cronograma e validação compartilhada

Publicado em 04/11/2026 em https://business.roadrunners.run/estudos/lancamento/.

O cronograma é o primeiro bloco de conteúdo da central, com cabeçalho compacto e link inicial na navegação. Oito etapas mantêm o lançamento de 13/11 e incluem “Aprovar contrato com a ABRACEO” até 12/11, com destaque enquanto pendente. Os materiais, textos, PDFs e links anteriores foram preservados.

Administradores podem validar ou reabrir cada etapa pelo checkbox. O progresso é compartilhado entre contas e dispositivos. Cada alteração registra autor, horário de Brasília e revisão; não há aprovações automáticas. A marcação é um registro interno da conferência, não uma assinatura contratual nem um disparo de comunicação.

## Implementação

- `estudos/lancamento/index.cfm`: cronograma primeiro e estado inicial renderizado no servidor.
- `estudos/lancamento/lancamento.css`: apresentação do progresso, contrato e controles, incluindo celular.
- `estudos/lancamento/checklist.js`: gravação, confirmação, reabertura, erros e conflito de revisão.
- `estudos/lancamento/checklist.cfm`: POST autenticado com CSRF; respostas de conflito incluem o estado atual autorizado.
- `estudos/includes/StudyAccess.cfc`: três métodos privados e dois públicos adicionados, reutilizando a checagem de administrador pessoal existente. Os métodos anteriores foram preservados integralmente.

Persistência aditiva na tabela existente `estudo.auditoria_comercial`, sem migration: ação `LAUNCH_STEP_VALIDATION`, entidade `launch_checklist`, entidade_id do produto `previa-2026-q3`. Os detalhes JSONB guardam `release=2026-q3-20261113`, `step`, `completed` e `previous_version`. A última linha de cada etapa define seu estado; o histórico é imutável. O salvamento usa lock transacional por etapa e revisão esperada para impedir sobrescrita concorrente. Não há alterações em queries, notebooks, congelamentos, acessos ou vouchers.

## Validação e publicação

Pacote restrito a cinco arquivos Business, com baseline conferido contra produção, compilação CFML e backup em `/var/backups/business-launch-checklist-20261104/baseline`. Publicação e cinco hashes verificados; workspace sincronizado sem sobrescrever outras frentes. O Road Runners não foi alterado.

Teste do serviço com componente candidato em ponte local e transação revertida: oito etapas, gravação e releitura, autor/data, reabertura, conflito de revisão, rejeição de etapa desconhecida e bloqueio de leitura/escrita por não administrador. Exigência de identidade verificada conferida. Os testes não deixaram nenhuma etapa validada nem linha de auditoria.

HTTP sem sessão: central 401, endpoint GET 405 e POST 401; CSS e JS 200. Chrome autenticado: oito controles habilitados, cronograma como primeiro bloco, release anterior preservado, desktop 1533 px e celular 390 px sem transbordamento horizontal. Marcações finais ficam a cargo da equipe.

Recibos, baseline, candidato e provas visuais em `_codex/staging/lancamento-checklist-20261104/`. A aba própria 283508529 foi encerrada e sua ausência conferida; viewport restaurado, pasta temporária de imagens removida e nenhum servidor de teste iniciado.

## Complemento de acompanhamento

Responsável e observações por etapa foram publicados também em 04/11/2026. Consulte [campos e histórico de acompanhamento](2026-11-04_estudos_lancamento_responsaveis.md).
