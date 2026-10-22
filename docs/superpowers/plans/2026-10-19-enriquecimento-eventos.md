# Enriquecimento de eventos — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Enriquecer o cadastro na mesma chamada Astra, publicando somente vazios confiáveis e evitando falsas divergências de nomes geográficos.
**Architecture:** Estender o contrato do AIClient; políticas puras de equivalência/evidência; persistência e revisão no fluxo LocationStore/LocationWorker existente. Reutilizar JSONB e auditoria, com publicação de atributos independente da cota Geoapify.
**Tech Stack:** Adobe ColdFusion 2025, PostgreSQL JSONB, Responses API, Python para testes/publicação.
**Spec:** docs/superpowers/specs/2026-10-19-enriquecimento-eventos-design.md

## Global Constraints

- Manter chave, gpt-6-astra, 1.000 análises/dia, Geoapify 2.000/dia e 1/s.
- Não sobrescrever automaticamente valores preenchidos; proteger fontes, destinos, lease e revisão em transação.
- Nenhum DDL, commit, branch, push ou mudança alheia. Publicar só runtime do escopo, com baseline e backup recuperável.
- Pedido já aprovado para execução/publicação; continuar sem novas pausas de planejamento. Credencial atual explicitamente autorizada em mensagem anterior.

## Review Focus

- Siglas parecidas não podem igualar países/UFs diferentes; homônimos de cidade continuam bloqueados.
- Um trecho literal não basta se trata do kit, de outra edição ou de outro atributo.
- Alteração humana durante a análise/revisão deve bloquear publicação obsoleta.
- Uma aplicação própria não pode gerar reenfileiramento infinito nem nova chamada paga ao retomar Geoapify.
- Falha de fonte, saída truncada e falta de quota não podem apagar fatos anteriores ou virar confirmação falsa.

### Task 1: Equivalências geográficas e política de fatos

**Files:** services/geocoding/RegionNames.cfc, EnrichmentPolicy.cfc, LocationPolicy.cfc, Policy.cfc; _codex/tests/geocoding/enrichment_policy.cfm.
**Interfaces:** RegionNames.country/state/evidenceText; EnrichmentPolicy.definitions/nativeSnapshot/validate/current/equivalent; LocationPolicy.identityVerified/editionMatches/fieldEvidence.
- [x] Escrever testes para equivalências, conflitos, fonte/edição/finalidade e preenchimento de vazios; rodar RED.
- [x] Implementar políticas e rodar GREEN e regressões de localizações.

### Task 2: Contrato único e persistência atômica

**Files:** services/geocoding/{AIClient,LocationStore,LocationWorker,EnrichmentStore}.cfc; fixtures enrichment_contract/integration/workflow.
**Interfaces:** AIClient.requestBody retorna attributes; EnrichmentStore.publish(work,progress,actor) retorna work/progress; LocationStore.reviewField(id,index,action,actor,revision).
- [x] Testar contrato, conflitos, CAS, aplicação antes de Geoapify, retomada e não reenfileiramento; rodar RED.
- [x] Implementar contrato/persistência com allowlist e auditoria; rodar GREEN e suíte completa.

### Task 3: Interface, chamada real e publicação

**Files:** administracao/geolocalizacao/includes/{backend,view,ai_locations_view,enrichment_view}.cfm; eventos/includes/{localizacoes_confirmadas,enriquecimento_confirmado}.cfm; scripts de teste/deploy/verificação; docs/geolocalizacao-ia-kit.md.
- [x] Testar apresentação, escaping, ações/revisões e acesso; rodar RED.
- [x] Implementar detalhes por abas e visualização do cadastro, sem justificativa obrigatória.
- [x] Executar suíte nativa completa, leitura de fontes e chamada real limitada; revisão independente do escopo.
- [x] Conferir baseline, backup e publicar só arquivos próprios; validar hashes, runtime e cron reais.

## Ledger

Registro em .superpowers/sdd/2026-10-19-enriquecimento-eventos/progress.md. Sem commits por preferência explícita do projeto. Reutilizar checkout atual, pois contém o módulo ainda não versionado e mudanças de outras frentes; nenhuma operação Git de escrita.
