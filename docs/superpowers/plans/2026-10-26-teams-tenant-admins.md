# Gestão de usuários pelos responsáveis Teams Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Aplicar inclusão agrupada e edição de papéis ao painel dos responsáveis, com permissões por papel, e publicar.
**Architecture:** Política central no serviço: GLOBAL atribui OWNER/ADMIN/VIEWER; OWNER gerencia ADMIN/VIEWER; ADMIN inclui/convida VIEWER; VIEWER lê. Titularidade permanece global. Uma view portátil de equipe, com CSS próprio, será compartilhada entre painel dos responsáveis e gestão global para manter o padrão único.
**Tech Stack:** CFML/CF2025, PostgreSQL, HTML details e CSS escopado.
**Spec:** Pedido do usuário em 26/10/2026 e matriz de permissões comunicada na sessão.

## Global Constraints
- Não escalar acima do papel do ator nem cruzar Teams. Titularidade e último OWNER protegidos.
- Papel esperado, CSRF, convites pendentes e ordem de locks Team → convite → admin.
- ADMIN não altera pares/titulares nem substitui/revoga convite ADMIN. VIEWER não busca/adiciona/altera/convida.
- Convite de usuário já vinculado é recusado; editar papel é o caminho previsto.
- Preservar filtros e valores em erros, PRG, mesma separação entre acesso administrativo e vínculo de atleta.
- Sem Git/DDL/envio de emails ou concessão de acesso real de teste. Fixture rr_teams_test com rollback.
- Baseline/CAS, backup recuperável, publicação só dos arquivos do escopo e verificação real.

## Review Focus
- Ator passa na UI mas é revogado/rebaixado antes do POST: serviço revalida sob lock.
- ADMIN tenta conceder ADMIN/OWNER ou usar convites para rebaixar pares: bloquear.
- OWNER tenta mudar titularidade, membro externo ou papel obsoleto: bloquear.
- Busca/inclusão protegidas por Team e papel; VIEWER só consulta dados da própria equipe.
- Duas interfaces compartilham o componente e preservam filtros/erros sem misturar URLs.

### Task 1: Política e operações
**Files:** services/teams/Service.cfc; _codex/tests/teams/tenant_admins.cfm; fixtures existentes de papéis/convites.
- [x] RED para OWNER/ADMIN na inclusão e edição; implementar política no workspace e validar operações/convites sob lock.
- [x] GREEN para matriz completa, convites acima do ator, pares/titular, escopo, última titularidade e regressões globais.

### Task 2: Componente compartilhado e rotas
**Files:** teams/index.cfm; teams/includes/admins.cfm; teams/assets/admins.css; teams/includes/header.cfm; services/accountDelegation/RequestBoundary.cfc; administracao/teams/includes/admins.cfm; administracao/teams/index.cfm.
- [x] Componente compartilhado com URLs/filtros fornecidos pelo controlador, listas e formulários conforme política.
- [x] Lookup por user_busca, POST add_existing_admin/change_admin_role, expected_role, CSRF, PRG e flash no painel responsável; allowlist pessoal atualizada.
- [x] CSS portátil para ambas as telas; duas opções em details; leitura sem controles para Consulta; titularidade somente global.

### Task 3: Verificar e publicar
**Files:** scripts/testes/recibos/docs da tarefa.
- [x] HTTP OWNER/ADMIN/VIEWER/global, tentativas forjadas e isolamento, erros e agrupamento; compilar, revisar, conferir desktop/celular.
- [x] Baseline/backup/CAS, publicação só Business e probes reais globais e do responsável com identidade de leitura; sem acesso real de teste.

Completed and published 26/10/2026 Sao Paulo. Receipt: _codex/teams/tenant-admins/publication.json. No active non-global member for a real tenant probe; fixture personas and shared published component verified.
