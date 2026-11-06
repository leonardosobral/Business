# Job 15 — erro de execução ao validar horário no início do texto

O agendador retornava HTTP 503, `execution_error`, com contadores zerados. A seleção da fila, criação da auditoria e persistência passaram em testes transacionais revertidos. O diário de consumo confirmou respostas HTTP 200 da OpenAI nas falhas históricas.

A reprodução com o texto real e provedor simulado revelou `Left(text, 0)` em `clockFormatContext`. O matcher Java retorna posições começando em zero; quando o primeiro token é um horário, não há prefixo. O ColdFusion exige comprimento diferente de zero para `Left`. `durationParts` apresentava o mesmo caso limite.

A correção trata explicitamente ambos os prefixos vazios, sem modificar modelos, prompts, credenciais, validações factuais, limites, transações, filas ou agendamento. Horários e durações alterados continuam rejeitados; traduções válidas continuam exigindo revisão semântica independente.

Regressão reproduzida antes da correção. Suíte nativa aprovada: 362 verificações, 29 verificações de endpoint/autenticação, auditoria transacional com rollback e cinco verificações de privacidade. Os testes automatizados usam provedor simulado.

Único runtime publicado: `services/EventDescriptionRewriteService.cfc`. Backup: `/var/backups/business-rewrite-boundary-b0cy38wb`. Evidências e resultado real após a publicação: `_codex/deploy/rewrite-boundary-20261105.json`. Sem operações Git.

Lote real após a publicação: três itens selecionados e processados, uma descrição pt-BR atualizada (45425) e duas traduções do evento 45424 rejeitadas pelas verificações existentes. O retorno foi HTTP 422 de validação, sem `execution_error`; as rejeições agora são persistidas e recebem links de auditoria (16578/en e 16579/es), permitindo que a fila avance. A comparação confirmou diferenças nos conjuntos de números/horários e um endereço de e-mail diferente (além de maiúsculas/minúsculas ou pontuação final). Nenhuma proteção foi relaxada para transformar essas rejeições em sucesso.
