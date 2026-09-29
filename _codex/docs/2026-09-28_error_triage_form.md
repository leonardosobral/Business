# Formulário de tratamento — 28/09/2026

Reprodução isolada: valores de option gerados por iteração de struct no Adobe CF vêm em maiúsculas. listFind na validação era sensível a caixa, rejeitando status/categoria legítimos. O serviço agora normaliza os dois enums para minúsculas antes de validar/gravar; opções dos filtros e do formulário também são emitidas em minúsculas. Formulários já abertos continuam compatíveis. Valores desconhecidos continuam rejeitados, com mensagem específica para cada campo.

Campos obrigatórios: título, status, categoria; evidência para publicado/verificado; horário efetivo para publicado; motivo para ignorado/reaberto. Responsável, análise e proposta são opcionais. O JS atualiza required, asteriscos e resumo conforme a escolha. A validação do servidor permanece autoritativa. Verificado exige publicação anteriormente registrada.

Horário efetivo usa datetime-local com precisão de segundos. Preserva horário registrado ou digitado em POST; na ausência de ambos, sugere database_now no fuso do banco. A interface informa que é uma sugestão, a ser ajustada para o horário real se a publicação ocorreu antes. Não grava data ou status automaticamente.

Regressão CFML usando valores extraídos do HTML real, compatibilidade com formulário antigo em maiúsculas, data registrada preservada, sugestão do banco e reenvio com data editada. 71 asserções CFML e 6 proteções HTTP; 4 testes JS. Sem migração. Backup seletivo: /var/backups/business-error-triage-form-20260928/baseline. Runtime: ErrorTriage.cfc, workspace.cfm, triage.js e home.cfm (versão de cache do JS).

Publicação conferida: compilação 3/3 CFML, hashes dos quatro arquivos iguais ao candidato. Problema #6 aberto na interface autenticada, opções em minúsculas, data preenchida e required dinâmico observados; layout desktop e celular 390×844 conferidos. Nenhuma gravação feita no problema real. Evidências em `_codex/staging/error-triage-form/desktop.png` e `mobile.png`.
