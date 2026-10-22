# Geolocalização com IA e kit — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Interpretar fontes via OpenAI e persistir locais independentes de prova e kit com evidência verificável.

**Architecture:** Leitor protegido fornece documentos inertes; cliente OpenAI retorna fatos estruturados; política confere citações/edição/finalidade e Geoapify valida precisão. Fila v3/checkpoints e JSONB do evento preservam os dois destinos sem alterar o significado das coordenadas legadas.

**Tech Stack:** CF2025, PostgreSQL, Python stdlib, Responses API, Geoapify.

**Spec:** `docs/superpowers/specs/2026-10-19-geolocalizacao-ia-kit-design.md`.

## Global Constraints

- Sem chave nova, operações Git, DDL pelo datasource ou mudanças de permissões.
- Geoapify compartilhado: 2.000/dia UTC, 1/s; cron minuto e lote 45s, sem sobreposição.
- Não sobrescrever dados existentes; cidade não é ponto confirmado; kit nunca preenche coordenada da prova.
- IA: modelo próprio validado, padrão `gpt-4.1-mini`, 1.000 chamadas/dia UTC, entrada/saída limitadas e cache.
- Publicar somente após migração, testes, revisão independente e backup dos arquivos do escopo.

## Review Focus

- Citação literal que contém kit mas é indevidamente classificada como prova: exigir finalidade e testar rejeição.
- Kit em município diferente: validar região própria, sem herdar silenciosamente cidade da corrida.
- Destinos editados enquanto IA responde: CAS e não sobrescrita transacionais.
- Tempo insuficiente após IA/geocodificação: checkpoint e retomada sem repetir chamadas.
- Evento já tem coordenadas: analisar kit, sem regravar a coordenada nem entrar em loop.

## Task 1: Documentos, contrato OpenAI e evidência

**Files:** Create `services/geocoding/{AIClient,LocationPolicy,DocumentReader}.cfc`; tests `_codex/tests/geocoding/{ai_contract,ai_locations}.cfm`.
**Interfaces:** `AIClient.extract(context, documents)` retorna `{ok,code,locations,usage,model}`; `LocationPolicy.validate(source, documents, extracted)` retorna alvos com evidência confiável ou motivos de revisão; `DocumentReader.read(source,deadline)` fornece documentos limitados e metadados.

- [ ] Escrever/run fixtures RED: kit/prova, cidade diferente, fonte antiga, citação inexistente, instrução maliciosa e recusa/resposta incompleta.
- [ ] Implementar cliente Responses estrito e validação factual; não há ferramentas externas do modelo.
- [ ] Executar fixtures GREEN e teste real limitado da integração, sem gravar eventos.

## Task 2: Fila v3 e gravação canônica

**Files:** Create `services/geocoding/{LocationStore,LocationWorker}.cfc`; migration `administracao/geolocalizacao/migration_ai_locais.sql`; tests `ai_integration.cfm`, `ai_workflow.cfm`.
**Interfaces:** Store enfileira/assume/checkpoint/finaliza alvos v3, reserva OpenAI, herda reservas Geoapify; Worker coordena análise/consulta em 45s com cache. Usa `LocationPolicy` da Task 1.

- [ ] Solicitar aplicação manual da migração aditiva; manter produção anterior até confirmação.
- [ ] Testes RED transacionais: dois destinos, legado protegido, kit em outro município, destino editado, quota, retomada e ausência de loop.
- [ ] Implementar CAS/auditoria e processamento, sem DDL runtime.
- [ ] Executar testes GREEN e suite legada completa.

## Task 3: Interface, ativação e publicação

**Files:** Modify `api/eventos/geolocalizar.cfm`, painel `includes/{backend,view}.cfm`, `services/geocoding/config.cfm`; create detalhes/cadastro de locais e testes de view/acesso; scoped deploy/verify scripts.
**Interfaces:** Endpoint seleciona Worker v3 apenas com schema/IA prontos; painel distingue alvos e revisão indexada/CSRF/revisão. Cadastro mostra JSONB sem expor credenciais.

- [ ] Testes RED de interface: destinos separados, cidade sem aprovação, edição concorrente e modelo/limites visíveis.
- [ ] Implementar interface e fallback seguro enquanto sem migração.
- [ ] Executar suite completa, revisão independente, corrigir importantes com RED→GREEN.
- [ ] Conferir baseline, backup e publicar runtime do escopo.
- [ ] Validar integração real, gravação por finalidade, cron e navegador. Salvar recibos; sem commit/push.
