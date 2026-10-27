# Papéis e inclusão unificada de usuários Teams Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Alterar papel sem remover o vínculo e reunir as duas opções de adicionar usuário na gestão global, depois publicar.
**Architecture:** Novo changeAdminRole exclusivo global usa lock do Team, compara papel esperado, protege último OWNER, revoga convites pendentes e atualiza a linha existente com auditoria. Uma view global de Equipe administrativa mostra papéis editáveis e uma seção Adicionar usuário com duas opções expansíveis, conforme Empresas: usuário existente e convite por email. Painel dos responsáveis preservado.
**Tech Stack:** CF2025/CFML, PostgreSQL e utilitários Bootstrap/MDB existentes; sem dependências/DDL.
**Spec:** Pedido do usuário em 26/10/2026, implementação e publicação autorizadas.

## Global Constraints
- Papéis OWNER/ADMIN/VIEWER; último titular não pode ser rebaixado; membro continua na mesma linha/vínculo.
- Somente identidade global real, CSRF e papel esperado. Perfil global, filiação de atleta e email não mudam na edição de papel.
- Bloqueios Team → convite → admin, coerentes com inclusão/aceite existentes; revogar convite antigo evita substituição do novo papel.
- Formulários preservam filtros/valores em erros; confirmação nas mudanças de acesso.
- Duas opções de inclusão na mesma seção, expansíveis por teclado; busca ou erro abre a opção correspondente.
- Testes em rr_teams_test com rollback; nenhum acesso real ou email de teste; sem Git/DDL.
- Publicação somente de cinco CFML com baseline/backup/CAS e verificação real, preservando frentes.

## Review Focus
- Último titular e edições simultâneas não deixam Team sem OWNER.
- Papel obsoleto e membro de outro Team são rejeitados sem substituir permissões.
- Usuários comuns/delegados não editam papéis.
- Convites antigos não sobrescrevem papel novo; aceite comum continua funcionando.
- Opções de inclusão ficam juntas, com filtros e valores preservados em falhas.

### Task 1: Serviço de alteração de papel
**Files:** services/teams/Service.cfc; _codex/tests/teams/roles.cfm.
**Interface:** changeAdminRole(userId,teamId,memberId,role,expectedRole) -> void.
- [x] Teste RED método ausente; implementar e testar papéis, último titular, vínculo preservado, permissão, membro inválido, papel obsoleto, convites e auditoria com rollback.

### Task 2: Interface e publicação
**Files:** administracao/teams/includes/backend.cfm; home.cfm; includes/existing_user.cfm; novo includes/admins.cfm; _codex/scripts/test_teams_global.py; _codex/scripts/deploy_teams_roles.py.
- [x] Papéis editáveis por pessoa, POST change_admin_role com expected_role, PRG, feedback e confirmação.
- [x] Seção Adicionar usuário com duas opções juntas (details), mantendo busca/inclusão existente e convite por email com fluxo atual; preservar erros.
- [x] Testes HTTP de edição, CSRF, papel obsoleto/último titular e agrupamento das opções; compilação e revisão independente.
- [x] Conferir desktop/celular; baseline e backup; publicar somente cinco arquivos e conferir tela real sem alterar papel real de teste.
