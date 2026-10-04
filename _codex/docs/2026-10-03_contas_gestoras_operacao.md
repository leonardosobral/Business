# Contas gestoras — validação e operação

## Candidato e limites

As Tasks1–11 foram revisadas e integradas ao projeto:116 arquivos de código, testes e documentação, dos quais80 são runtime. A pedido do usuário, a construção de novos scripts de publicação foi interrompida e seu WIP foi excluído. A publicação usa o mecanismo existente.

Preparação de produção:baseline dos80 arquivos confirmado e backup recuperável em `/var/backups/business-agencies.9e63d359efd2`; compilação Adobe dos78 arquivos CFML finais passou78/78. A revisão final não identificou novo bloqueio de código. Até este checkpoint, os arquivos ainda não foram substituídos em produção e o banco não foi migrado. A flag permanece desabilitada.

O preflight confirmou a dependência de permissões do papel `runner` nas tabelas novas e em `tb_business_permissoes(id_permissao)` para locks, além de leitura de autorização pelo papel `ads_owner`. O SQL exato está em `.superpowers/sdd/2026-10-03-contas-gestoras/production-required-grants.sql`, pendente de autorização específica conforme AGENTS.md. Depois:estrutura aditiva, permissões autorizadas, duas migrations de compatibilidade Ads, publicação dos80 arquivos e verificação real no Chrome. A sessão administrativa do Chrome já foi aberta para essa verificação; isso ainda não é teste pós-publicação.

## Verificações locais

`node _codex/scripts/test_account_delegation.mjs --suite all` executa cada suíte uma vez em banco e servlet próprios. Inclui schema, policy, lifecycle, accounts, boundary, receiver, workspace, ads-db, ads, events, http. Executar sequencialmente: RunWAR4.8.3 também usa porta interna8779. Não manter browser fixture aberta ao lançar outro servlet.

`node _codex/scripts/test_account_delegation.mjs --suite http` é o fluxo integrado suplementar: criação, titular pendente, login novo, root/status, bloqueio operacional, revisão interna, atribuição, acesso direto e duas gestoras, campanha real DRAFT com ator correto, aceite, revogação e POST de aba antiga negado sem escrita. Outros suites mantêm matrizes reais próprias de Ads/Eventos/convites/fronteira.

Evidências e resultados finais: `../task-11-report.md`, `../task-11-all-final.log`, `_codex/tests/account-delegation/coverage.json`. A matriz diferencia passed/failed/not_run. Contadores de alvo negado comprovam guard antes do handler; não representam execução integral do módulo negado. Admin integrado usa handlers/templates reais com adapter local de contexto da página; não simula revisão completa da página administrativa legada.

Regressões exigidas: `bash _codex/scripts/test_business_remember_local.sh` com runtime cache e JOSE4J_TEST_JAR temporário oficial0.9.4; `bash _codex/scripts/test_business_existing_account_access_request.sh`; `bash _codex/scripts/test_business_duplicate_document_registration.sh`. As duas últimas são regressões estáticas existentes; remember executa CFML real.

## Interface

Chrome existente via playwright-cli0.1.18, viewport1280x900 e390x844 com JavaScript desligado. Screenshots inspecionadas em output/playwright. Teclado desktop Tab/Enter abre Equipe; filtro enum real corrigido. Mobile semJS mantém conteúdo, seletor e retorno à carteira por navegação/form POST nativos. A aba Histórico existe na navegação horizontal, mas a interação dedicada mobile não foi concluída (coverage not_run). O fluxo completo foi executado via HTTP real, sem duplicação integral em browser.

Fixture usa UTF-8 de template/web/resource e JVM file.encoding UTF-8; a primeira tentativa herdou LC_ALL=C/US-ASCII. Somente config temporária da engine foi corrigida, nunca os textos para screenshot. Assets remotos foram suprimidos somente na fixture, autenticação/provedor sintéticos. Não usar hooks locais de bootstrap em runtime distribuído.

## Atualização de instalação — 04/10/2026

Migração estrutural aditiva executada e verificada em produção:8 tabelas, marcador versão1. Backup do catálogo anterior em `/var/backups/business-agencies.9e63d359efd2/database-before-schema.json`. Não foram aplicados GRANTs, migrations Ads, habilitação ou upload de runtime. A comparação da estrutura foi validada corrigindo somente ordenação dos índices e precisão bigint da referência WIP local; não houve ajuste da estrutura instalada. Se a execução anterior do SQL de permissões falhou, executar ROLLBACK nessa conexão antes de tentar novamente.
