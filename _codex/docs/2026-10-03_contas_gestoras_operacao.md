# Contas gestoras — publicação e operação

## Estado atual — 04/10/2026

Publicado e ativado em produção. Foram integrados116 arquivos revisados de código, testes e documentação e publicados80 arquivos de runtime, com backup e conferência de hashes. O usuário executou o SQL de permissões e autorizou explicitamente a ativação global. Nenhuma agência, relação com cliente, pessoa ou pagamento foi alterado para testes.

A estrutura aditiva tem8 tabelas e marcador versão1. As duas migrations de compatibilidade Ads foram executadas na mesma transação, com comparação exata de funções, owners e ACLs antes/depois. Todas as permissões requeridas foram verificadas. A flag global está ligada na configuração persistente e no APPLICATION vivo; ambas as conexões runnerhub e runner_dba reconheceram a estrutura. Zero agências estavam habilitadas na ativação.

## Uso

Em Administração → Contas, abrir a conta e acessar a aba Gestoras. O admin interno pode classificar como Agência, Ticketeira ou Outros e habilitar a conta como gestora. Isso não concede automaticamente acesso aos clientes: relações, consentimento e atribuições da equipe continuam necessários. O seletor permite escolher explicitamente a conta e a forma de acesso.

A carteira da gestora usa as abas Clientes, Equipe, Convites e Histórico. Uma conta criada pela gestora permanece pendente de aprovação interna. Convites de titularidade não tornam a agência dona do cliente. Campanhas, compras, histórico financeiro e Eventos têm permissões distintas.

## Verificação

Suíte local completa:11 suítes isoladas, zero skipped, exit0. Integração HTTP cobriu criação, titular pendente, aprovação, equipe, duas gestoras, campanhas, aceite, revogação e POST de aba antiga negado sem escrita. Regressões de autenticação e cadastro passaram. Os78 arquivos CFML do pacote original passaram no compilador Adobe.

No Chrome autenticado em produção: listagem/detalhe de contas, Publicidade e Eventos carregaram. O teste real de Eventos encontrou inclusão duplicada de funções no Adobe; os dois handlers foram corrigidos para incluir os auxiliares apenas quando as funções ainda não existem em VARIABLES. A correção foi publicada com backup próprio e a página passou a listar normalmente os eventos.

Após ativar: a aba Gestoras exibiu os controles e as classificações Agência/Ticketeira/Outros; o seletor de contas abriu e o POST de seleção Administração RunnerHub retornou ao painel administrativo. Não foram salvos cadastros nem habilitadas agências nesses testes. O ciclo completo de delegação com cliente real e perfil médico positivo em produção não foi executado; não confundir os testes locais com essa homologação.

## Evidências e recuperação

Backup privado no servidor: `/var/backups/business-agencies.9e63d359efd2`. Contém baseline dos arquivos, catálogo anterior, recibos de migração/publicação, correção de Eventos e configuração anterior à ativação. Não restaurar cegamente o runtime antigo após uso delegado: isso pode remover a proteção de formulários antigos. Uma desativação deve preservar guardas, schema, auditoria e dados; configurar false também precisa atualizar o APPLICATION vivo. Operações já autorizadas em andamento podem terminar.

Evidências locais em `.superpowers/sdd/2026-10-03-contas-gestoras/`: `production-final-verification.json`, `production-published.json`, `production-events-include-fix.json`, `production-feature-enabled.json`, `production-enabled-verified.json`, `production-compatibility-installed.json` e `task-11-all-final.log`.

A construção de novo publicador foi interrompida por instrução do usuário. Os scripts WIP da Task12 não foram integrados. A publicação reutilizou o mecanismo existente. Não foram realizados commit, branch, push ou PR.

## Testes locais

`node _codex/scripts/test_account_delegation.mjs --suite all` executa schema, policy, lifecycle, accounts, boundary, receiver, workspace, ads-db, ads, events e http em bancos/servlets isolados. Executar sequencialmente por causa da porta interna8779 do RunWAR. A matriz detalhada está em `_codex/tests/account-delegation/coverage.json`.
