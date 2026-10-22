# Central de Geolocalização — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Execução direta autorizada pelo usuário, sem novas pausas de planejamento. Steps use checkbox syntax.

**Goal:** Preencher somente coordenadas de locais confiáveis e apresentar cidades como sugestões privadas.

**Architecture:** Política pura de extração/validação separada de cliente HTTP, armazenamento e worker. UI global e endpoint HMAC utilizam os mesmos serviços e limites de consumo; gravações usam snapshot exato e auditoria atômica.

**Tech Stack:** Adobe ColdFusion 2025, PostgreSQL, Geoapify HTTPS, MDB existente, testes CFML nativos com fornecedor simulado.

**Spec:** `docs/superpowers/specs/2026-10-17-eventos-geolocalizacao-design.md` (aprovada em 17/10/2026).

## Global Constraints

- Somente `coordenadas` vazia é atualizada; cidades nunca são publicadas automaticamente.
- Tipos específicos `building`/`amenity`, confiança >=0,95 e contexto geográfico compatível.
- GET não provoca HTTP pago nem mutações. Admin real + POST/CSRF para ações; cron HMAC.
- Até cinco eventos/45 segundos, oito segundos por HTTP, três consultas por evento, 1.000 chamadas/dia padrão e teto 2.000.
- Sem segredos no Git, HTML, exceções ou históricos; sem mudanças de permissões do datasource.
- Preservar árvore suja; não criar branch/commit/push. Publicar só runtime deste escopo com baseline, backup e verificação real.

## Review Focus

- Homônimos de cidade e POI; um resultado de confiança alta no município errado não pode publicar.
- Endereço de kit e outros trechos de descrição não podem ser confundidos com a largada.
- Corrida entre revisão, worker e edição manual não pode substituir coordenada existente ou usar proposta antiga.
- Cooldown, orçamento e rate-limit precisam ser compartilhados entre cron e ação manual.
- Materialização de fontes/query e respostas de erro não pode levar chave, HTML ativo ou texto privado ao navegador/cron.

---

### Task 1: Política de localização

**Files:** Create `services/geocoding/Policy.cfc`; Test `_codex/tests/geocoding/policy.cfm`; Harness `_codex/scripts/test_geocoding_native.py`.

**Interfaces:** `Policy.snapshot(event) -> struct`, `sourceHash(snapshot) -> string`, `queries(snapshot) -> array`, `evaluate(snapshot,query,results) -> struct`, `coordinates(value) -> struct`, `authorize(admin,delegated,post,csrf) -> void`.

- [ ] Escrever fixtures literais de endereço confiável, cidade, rua, número errado, cidade/UF/país incorretos, confiança ausente, múltiplos POIs, kits, local indefinido, 0,0/faixa e autorização.
- [ ] Rodar `python3 _codex/scripts/test_geocoding_native.py policy`: RED esperado por componente ausente.
- [ ] Implementar extração estrita, normalização, comparação geográfica, precisão e resultados seguros.
- [ ] Reexecutar o mesmo comando: `GEO_POLICY_PASSED`, sem chamada externa ou dados alterados.

### Task 2: Persistência, cliente e processamento

**Files:** Create `services/geocoding/Store.cfc`, `GeoapifyClient.cfc`, `Worker.cfc`, `administracao/geolocalizacao/schema.sql`, `api/eventos/geolocalizar.cfm`, `administracao/geolocalizacao/geocoding_job.sql`, `services/geocoding/config.cfm`; Tests `_codex/tests/geocoding/integration.cfm`, `provider.cfm`, `endpoint.cfm`.

**Interfaces:** Store `isReady()`, `enqueue(ids,actor)`, `claim()`, `finish(work,result,actor)`, `reserveCall(limit)`, `providerState()`, `cacheGet(query)`, `cachePut(query,results)`, `review(id,action,actor,reason)`, `settings()`, `saveSettings(enabled,limit)`; Client `search(query,key)`; Worker `run(limit=5)` and `testConnection()`.

- [ ] Escrever testes RED de migração/estado ausente, reserva de limite, cache, fonte concorrente, lease, cidade não aplicada e HMAC/GET.
- [ ] Criar quatro tabelas novas e estado singleton de configuração, sem DDL no runtime; SQL de cadastro do cron começa pausado e é idempotente.
- [ ] Implementar compare-and-set, auditoria e limite transacionais; HTTP fora da transação. Separar a consulta do fornecedor para fixtures de teste, sem injetores expostos em HTTP.
- [ ] Implementar cliente fixo HTTPS, normalização de respostas, erros seguros, cooldown/rate-limit e retries limitados.
- [ ] Executar testes nativos de provedor/guards e integração com transações revertidas; não gravar eventos reais para testes. Se falta schema/credencial, registrar o bloqueio sem contornar proteções.

### Task 3: Interface global e configuração

**Files:** Create `administracao/geolocalizacao/index.cfm`, `includes/backend.cfm`, `includes/view.cfm`, `assets/geocoding.js`; Modify `includes/estrutura/sidenav.cfm`; Tests `_codex/tests/geocoding/view.cfm`, `access.cfm`; Docs `docs/eventos-geolocalizacao-geoapify.md`.

**Interfaces:** UI chama os métodos de Store/Worker com autorização antes de qualquer consulta; seleção limitada a 20 IDs, paginação 20, abas por `aba=fila|revisao|historico|configuracoes`.

- [ ] Escrever testes RED de 403, CSRF, filtros vazios/invalidos, escaping, revisão municipal sem aprovação e links de abas.
- [ ] Implementar fila/revisão/histórico/configurações com filtros, confirmação de aprovar endereço específico e enfileirar lote; sem chamadas pagas por navegação.
- [ ] Incluir link apenas no menu global e documentar IP, configuração privada e limites.
- [ ] Rodar testes de UI/autorizações e conferência autenticada após publicação.

### Task 4: Revisão e publicação

**Files:** Create `_codex/scripts/deploy_geocoding.py`, `_codex/deploy/geocoding-20261017.json`; Update ledger.

**Interfaces:** Manifesto de runtime com baseline SHA-256, backup fora do webroot, comparação de cada alvo, rollback condicional.

- [ ] Conferir chave local sem imprimi-la; comparar identificação/fingerprint e validar restrição Geoapify autorizada pelo usuário.
- [ ] Executar suíte nativa completa; revisão independente final do delta; corrigir importantes em RED→GREEN.
- [ ] Publicar migração pelo mecanismo autorizado e arquivos escopados, preservando configurações/arquivos alheios e criando backup recuperável. Não enfraquecer datasource para executar SQL.
- [ ] Conferir guards públicos, usuário global, abas e histórico reais. Testar conexão dentro do orçamento; comparar propostas específicas/municipais antes de ativar apenas o novo job.
- [ ] Registrar exatamente se o job ficou ativo ou pendente de ação externa e entregar links e instruções manuais restantes.

## Pre-flight

Task 1→2: snapshot e resultado de `evaluate` têm o mesmo contrato em worker e Store. Task 2→3: ações globais usam Store e não aceitam coordenadas arbitrárias do formulário. Task 2→4: novos objetos exigem migração autorizada, não DDL no datasource em cada chamada.

Decisão: requisitos locais proíbem operações Git sem pedido específico; execução será na árvore existente, com arquivos novos isolados por módulo e baseline do único runtime compartilhado (menu), sem branch/commit/push. A autorização de publicação já está expressa. A pausa de revisão de planejamento foi dispensada pelo usuário; segurança e conflitos de produção não foram dispensados.
