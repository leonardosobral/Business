# Geolocalização autônoma — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Execução direta e publicação autorizadas, sem novas pausas de planejamento.

**Goal:** Pesquisar fontes e regulamentos automaticamente, preencher apenas locais confiáveis e agilizar a revisão sem motivo obrigatório.

**Architecture:** Extrator HTTPS público isolado em Python, interpretação/cache/evidência em CFML e política conservadora existente; mesmo cron, tabelas e orçamento.

**Tech Stack:** Python 3 stdlib, Adobe CF2025/CFPDF/CFExecute, PostgreSQL, Geoapify.

**Spec:** `docs/superpowers/specs/2026-10-17-geolocalizacao-fontes-design.md`.

## Global Constraints

- Nunca substituir coordenada existente ou publicar município como largada.
- Fontes limitadas: 12 s, quatro documentos, HTML 1 MiB/PDF 3 MiB; TLS com IP público validado/pinado, sem cookies/segredos/shell.
- Mesmas proteções HMAC, global real, POST/CSRF, lease, revision e CAS; orçamento 1.000 chamadas/dia/45 s por lote.
- Sem DDL, mudanças de credenciais/permissões, instalação de pacotes ou operações Git. Preservar mudanças alheias e publicar com backup.

## Review Focus

- DNS rebinding/redirect para rede privada não pode gerar requisição interna.
- Retirada de kit e regulamento de outra edição não podem fornecer local automático.
- HTML/JSON-LD duplicados com locais diferentes bloqueiam aplicação, mesmo com geocode perfeito.
- Cache ou revisão antiga não podem sobreviver a alteração de URL/data/nome.
- Revisão sem justificativa continua auditada, com CAS e proibição de aprovar cidade.

### Task 1: Extrator público limitado

**Files:** Create `services/geocoding/source_fetcher.py`, `_codex/tests/geocoding/test_source_fetcher.py`.

**Interfaces:** `normalize_url(url,base='')->str`; `public_addresses(host)->list`; `fetch_document(url,deadline)->dict`; `collect(payload)->dict` com pages/robots/diagnostics. HTML produz texto, título, JSON-LD e links; PDF produz base64. Entradas base64 JSON por CLI, saída JSON limitada.

- [x] Escrever testes de protocolo/credenciais/IP/DNS misto, HTML/JSON-LD, links, robots e tamanho; executar unittest RED.
- [x] Implementar stdlib, conexão HTTPS pinada e limites; executar unittest GREEN.

### Task 2: Evidências e política

**Files:** Create `services/geocoding/Sources.cfc`, testes `sources.cfm`; modify Policy e Store cache.

**Interfaces:** `Sources.research(snapshot,deadline)->struct {version,evidence,diagnostics,queries}`; `Sources.parseDocument(source,document)->struct`; `Policy.queries(source,research={})`; Store `resourceGet(key)`, `resourcePut(key,value,days)`.

- [x] Testes RED de Event JSON-LD, nome/data incompatíveis, PDF textual, kit, conflitos e cache; rodar nativo.
- [x] Implementar interpretação limitada e proveniência; integrar endereço/venue sem relaxar política; rodar fontes e policy GREEN.

### Task 3: Fila autônoma e revisão rápida

**Files:** Modify Policy snapshot, Store seed/review/overview/page; Worker; backend/view/js; tests integration/view/access/worker.

**Interfaces:** Snapshot v2 com nome/data/URLs; pesquisa antecede lookup, decisão contém evidence/diagnostics; revisão reason opcional e próxima proposta sob filtros; aba cidades separada.

- [x] Testes RED de URL/data alteradas, reanálise automática, revisão sem motivo, audit default e município proibido.
- [x] Implementar fila e pesquisa dentro do tempo/limites; revisão POST com confirmação, sem checkbox e sem motivo obrigatório; separar cidades e métricas. Rodar suíte completa GREEN.

### Task 4: Revisão e publicação

**Files:** New scoped deploy script/receipt, update guia operacional e ledger.

- [x] Smoke real de HTML/regulamento sem aplicar coordenadas; revisão independente do delta e correção dos importantes em RED→GREEN.
- [x] Comparar baseline publicado, backup e publicar apenas módulo; validar hashes, guards, navegação e revisão no navegador autenticado.
- [x] Verificar execução real do cron, evidências e continuidade automática; registrar capacidades/limitações reais.

## Pre-flight

Task 1→2: páginas retornam texto/JSON-LD ou PDF base64, sem body em auditoria. Task 2→3: queries adicionais carregam autoEligible e prova de edição; snapshot original permanece imutável. Task 3→4: mudança de versão invalida propostas anteriores sem substituir coordenadas existentes.
