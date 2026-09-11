# Audiência de promoções estáticas — implementação incremental

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan. Steps use checkbox syntax.

**Goal:** incluir as promoções institucionais ativas restantes no inventário existente, sem mudar o layout ou gerar eventos financeiros.

**Architecture:** RoadRunners acrescenta marcadores às imagens já renderizadas; o tracker existente emite oportunidade, montagem e exposição da posição. Business já agrega `slot_state = house` por posição/família/dispositivo. Não há novo tipo, tabela, SQL ou interface de relatório.

**Tech Stack:** CFML, JavaScript nativo, Node test runner, fixture local e navegador.

**Spec:** `_codex/docs/estrategia_audiencia_inventario_e_midia_proposta.md`, seções de inventário institucional e critérios de visibilidade; continuação aprovada pelo usuário em 11/09/2026. Este lote concretiza uma pendência já aprovada, não altera o desenho do painel.

**Estado final:** Task 1 implementada, revisada, validada e publicada em 11/09/2026 às 00:28:43 de Brasília, após autorização de continuidade à pergunta de publicação do lote. Evidências: `_codex/docs/2026-09-11_audiencia_promos_estaticas_entrega.md` e `_codex/docs/2026-09-11_audience_static_promos_publicado.md`. Os passos abaixo preservam a sequência executada; o ledger registra a conclusão e os hashes.

## Global Constraints

- Preservar opt-out/GPC, retenção de 90 dias, DSN `runner`, permissões de `runner_dba`, login, configurações, Ads, cobrança e `tb_log`.
- Uma posição física conta uma vez por página, inclusive quando alterna a peça. 50% por 1 segundo contínuo, documento visível, imagem carregada. Não reservar espaços nem ativar código comentado.
- Sem campanha/delivery inventados, requisição ao motor Ads, navegação ou ação de OAuth nos testes. A UF permanece no contexto assinado existente.
- Não criar branches/commits/push. Trabalhar em candidato isolado a partir dos arquivos atuais; aplicar somente após revisão e conferência dos hashes anteriores. Não publicar neste lote sem autorização específica.
- Business é consumidor do contrato atual; não alterar consultas/UI que já suportam o novo uso. Testes locais não equivalem a números de produção.

## Task 1: Instrumentar imagens de promoções ativas e validar o contrato existente

**Files (RoadRunners, candidato isolado):**
- Modify: `atleta/parts/sidebar_desktop.cfm`
- Modify: `includes/estrutura/barra_lateral.cfm`
- Modify: `canal/index.cfm` (somente imagens da posição institucional lateral)
- Modify: `desafios/desafio_confirmado.cfm` (somente imagem da promoção Todo Santo Dia)
- Modify: `assets/js/rr-audience.js`
- Modify: `includes/analytics/bootstrap.cfm` (somente hash do tracker)
- Test: `_codex/tests/audience-static-promos.test.js`, reutilizando harness existente quando possível.
- Test/support: fixture e runner locais em `_codex/tests/` e `_codex/scripts/` somente se necessários para executar os templates sem banco.

**Interfaces:** os marcadores são atributos da própria `img`; mantém-se HTML, classes, hrefs, condições e ordem. O tracker precisa verificar o carregamento da própria imagem, além das descendentes, porque `querySelectorAll('img')` não inclui o elemento raiz.

Valores dos cinco slots físicos:

| Template/ramo ativo | `data-audience-slot` | `data-audience-placement` |
|---|---|---|
| Perfil: Maratonas OU Strava, mesma posição | `rr-profile-sidebar-promo` | `rr-sidebar-static-promo` |
| Lateral legada: Catarinense OU Todo Santo Dia, mesma posição | `rr-legacy-sidebar-promo` | `rr-sidebar-static-promo` |
| Lateral legada: Maratonas inferior | `rr-legacy-sidebar-marathons` | `rr-sidebar-static-promo` |
| Canal: Maratonas OU Strava, mesma posição | `rr-channel-sidebar-promo` | `rr-sidebar-static-promo` |
| Desafio confirmado 365: imagem da chamada Todo Santo Dia | `rr-challenge-detail-promo` | `rr-content-static-promo` |

Todos recebem `data-audience-state="house"`; não recebem IDs de campanha/delivery, nem `data-ads-*`, requested ou served. A aplicabilidade vem dos ancestrais responsivos existentes, sem restrição de viewport inventada. Não instrumentar `profile_mini.cfm` sem caller ativo comprovado.

- [x] Escrever teste que lê os marcadores reais dos ramos ativos dos templates, alimenta o tracker real e falha por ausência dos novos slots. Esperar uma oportunidade e montagem por posição aplicável, nenhum evento `ad_*`, `slot_request` ou `slot_served`, e nenhum `slot_viewable` antes de 1000 ms. Ramos alternativos têm a mesma chave física. Código CFML comentado deve ser excluído corretamente ou usar saída renderizada do template.
- [x] Reproduzir imagem-raiz quebrada/não carregada: oportunidade é permitida, montagem/exposição não. Após imagem carregar, exigir novo segundo contínuo. Cobrir desktop/mobile conforme os ancestrais reais, aba oculta, reentrada e deduplicação. Guard mínimo na função `layoutGeometry`, dentro de `requireImages`:

```javascript
if (el.tagName === 'IMG' && (!el.complete || !el.naturalWidth)) return { ready: false, ratio: 0 };
```

- [x] Registrar RED antes de editar runtime; implementar os oito ramos de imagem com os atributos acima e o guard. Não extrair novo componente nem modificar o coletor financeiro. Atualizar versão no bootstrap com os 12 primeiros hexadecimais do SHA-256 do tracker.
- [x] GREEN: executar testes focados, `node --test --test-reporter=dot _codex/tests/audience-*.test.js`, `node --check assets/js/rr-audience.js` e CFML isolado dos templates quando disponível. Registrar comando e resultado, sem banco/rede externa.
- [x] Preparar fixture local com HTML real renderizado (dependências de domínio substituídas na fronteira), imagens locais e tracker real para o controlador validar desktop/mobile no navegador. Não criar fixture que envie eventos a produção.
- [x] Revisão independente do diff antes/depois isolado: conformidade e qualidade, proteção da geometria, ramos ativos, identidade física, ausência de alterações financeiras/visuais e preservação de mudanças anteriores.
- [x] Aplicar somente os arquivos revisados nos projetos locais após verificar baseline. Confirmar hashes e regressões finais. Documentar arquivo de publicação, backup previsto, ausência de SQL adicional e que a contagem começa após publicar.
- [x] Publicar o lote autorizado com backup, conferência remota dos seis hashes/metadados e validação de posições aplicáveis no Business. Recibo de 11/09/2026 registra desktop/mobile e restauração dos filtros.

## Fora desta entrega

Não mudar slots colapsados para reservar área: isso altera layout e requer um desenho próprio. Não prometer UF física recuperada (403 pendente), retenção agendada, projeção comercial sem semanas completas ou campanha paga sem verba. Não retirar o writer de view de evento em `tb_log`.
