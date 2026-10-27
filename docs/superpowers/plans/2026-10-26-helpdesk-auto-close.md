# Helpdesk Auto Close Implementation Plan

> Execução inline com executing-plans/TDD; seguir pedido de implementar automação e preferência Business de publicar. Sem operações Git de escrita.

**Goal:** Encerrar automaticamente chamados sem interação do usuário por mais de 48 horas após resposta do atendimento, exceto Em atendimento.
**Architecture:** Serviço isolado com seleção e transação; endpoint POST autenticado pelo segredo atual do scheduler; job no gerenciador existente a cada 15 minutos.
**Tech Stack:** CF2025/PostgreSQL.
**Spec:** docs/superpowers/specs/2026-10-26-helpdesk-auto-close-design.md

## Global Constraints
- Não fechar Em atendimento, Fechado ou última mensagem do usuário; notas internas não iniciam/renovam prazo.
- Mais de 48 horas, não igual; relógio do banco consistente com timestamps legados.
- Mensagem pública + fechado atomicamente, sem duplicação, sem notificações externas de teste.
- Sem DDL, novas credenciais, alteração de autorização ou Git; preservar outras frentes.

## Review Focus
- Resposta simultânea do cliente ou atendente e fechamento concorrente não deixam status fechado sobre resposta nova.
- Empate de timestamps usa id da mensagem; nota interna e usuário administrador solicitante não contam como resposta de equipe.
- Falha no insert/update não deixa status/mensagem parcial; execução repetida e sobreposta não duplica.
- Endpoint sem segredo, verbo errado, body inválido ou limite adulterado não mutam dados.
- Primeiro ciclo pode tratar backlog; dry run deve mostrar exatamente a regra, inclusive chamado121 se elegível.

## Tasks
- [x] 1. Fonte real e RED/GREEN seleção: criar services/HelpdeskAutoClose.cfc com candidatesSql(), message(), run(limit,dryRun); fixtures CTE para limite48h/status/autoria/última pública, transação revertida para atomicidade e repetição.
- [x] 2. RED/GREEN autenticação/input; api/helpdesk/auto-close.cfm; alias business_helpdesk_auto_close no resolver do cron; testar endpoint e regressão do helper existente.
- [x] 3. Revisão independente única, testes gerais e CAS; instalar job desativado, dry run instalado, ativar após validação e conferir ciclo automático/ticket121 no navegador.

## Ledger
- Pedido pontual com condições explícitas: não introduzir nova pausa de planejamento. Decisões declaradas: última mensagem pública, 15min/lote50, exclui fechado e preserva Em atendimento.
- Trabalho no checkout atual, preservando pendências de aquisição/Vicky e sem branch/commit/push. Serviço novo evita modificar o gerenciador ou respostas do portal.
- Interfaces: Task1 produz run(limit,dryRun) e auth/request helpers; Task2 consome esses métodos no POST; Task3 verifica hashes, dry run e job existente.
- Publicados somente os três arquivos de runtime do módulo. Backup: /var/backups/business-helpdesk-close-r4_wnagf. Sem DDL, troca de credenciais ou operações Git.
- Cinco suites nativas/HTTP aprovadas, além de 273 testes gerais. Revisão independente sem bloqueios. A lacuna de HTTP apontada foi coberta por cinco casos e por dry run autenticado da instalação real.
- Limite de validação: a guarda de snapshot obsoleto foi simulada; não houve teste de estresse com conexões realmente sobrepostas nem falha injetada entre insert e update. Atomicidade usa transação PostgreSQL; verificação de repetição e rollback sintético passou.
- Dry run real: 81 elegíveis, nenhuma alteração. Ativação exclusiva do job26; primeiro lote100 para cobrir o backlog81, sem execução manual do worker. Snapshot anterior arquivado em /var/backups/business-helpdesk-close-test-t8wdayg3.
- Primeiro ciclo do scheduler às 10:27:01 UTC em 26/10: HTTP200, selecionados81/fechados81. Chamado121 confirmado Fechado com exatamente o aviso automático mais recente às 07:27:01 local; verificado no navegador.
- Após esse ciclo, restaurado lote50, intervalo15min, sem alterar a próxima execução. Geolocalização permanece pausada. Comprovação: /private/tmp/business-helpdesk-auto-close-20261026.png.
