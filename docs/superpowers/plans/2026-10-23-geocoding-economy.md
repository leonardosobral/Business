# Geocoding Economy Implementation Plan

> Execução nativa com superpowers:executing-plans e TDD; revisão independente final. Sem commits/branches/push: não autorizados.

**Goal:** Publicar Sol/Astra seletivo/Batch e orçamento 2 USD/dia/30 USD/mês, permanecendo pausado.
**Architecture:** Policy e client compacto; Budget transacional sobre cache existente; BatchTransport/BatchClient e Economy orquestram pedidos únicos e resultados; LocationWorker mantém validadores e publicação.
**Tech Stack:** CF2025, PostgreSQL existente, Responses/Batch API; nenhuma dependência nova.
**Spec:** docs/superpowers/specs/2026-10-23-geocoding-economy-design.md

## Global Constraints
- Chaves existentes; enabled=false mantido; zero chamadas pagas nos testes; nenhum DDL/Git.
- Limites USD 2/dia e USD 30/mês UTC incluem reservas incertas e Batch pendente, inclusive de períodos anteriores.
- Nenhuma cidade vira largada; mesma validação literal e geográfica, proteção contra edição alterada e decisões humanas.

## Review Focus
- Duas reservas concorrentes e virada de dia/mês não podem ultrapassar teto.
- Timeout/crash depois de envio não pode produzir reenvio pago ou liberar reserva.
- Batch com resposta fora de ordem/ID diferente/falha parcial não pode publicar dado errado.
- Pausa impede qualquer novo envio e poll; orçamento fechado não impede recuperar resultados já pagos quando habilitado.
- Sol não pode escalar para contornar recusa/quota/fontes ausentes/conflito factual real.

## Tasks
- [x] 1. RED/GREEN Policy: modelos, corpo limitado, UTF-8/reserva, histórico e escalada. Criar EconomyPolicy.cfc/EconomyAIClient.cfc; fixtures economy_policy.cfm.
- [x] 2. RED/GREEN Budget: reserve(key,model,tier,usd), update(key,patch), settle(key,reply), status(), pending(). Criar AIBudget.cfc; namespace isolado e transações com rollback, concorrência e viradas. Sem schema novo.
- [x] 3. RED/GREEN Batch: request/submit/poll com transporte substituível e arquivos temporários privados; persistência de IDs, estado incerto e observer em resultados tarifáveis. Criar BatchTransport.cfc/BatchClient.cfc; fixtures sem rede externa.
- [x] 4. RED/GREEN Economy: lookup/run/poll, reaproveitamento durável, uma tentativa/modelo/fonte e fallback seletivo. Criar Economy.cfc; integrar LocationWorker e config Sol; preservar fontes e validadores. Fixtures de pipeline pausado, orçamento e Batch.
- [x] 5. Interface: modelos/custos/pausa em Configurações, pendências e limites não confundidos com Geoapify. Regressões existentes, revisão independente, correções.
- [x] 6. Publicar só runtime com backup/CAS e dependências; provisionar diretório temporário privado; testar runtime instalado sem rede paga; verificar enabled=false, dados/fila preservados e navegador. Não reativar.

## Ledger
- Desenho segue a aprovação explícita da proposta na conversa; sem nova rodada de aprovação de planejamento.
- Reuso da chave existente já autorizado; sem ler/exibir valor ou alterar destino.
- Reusar checkout atual e preservar alterações locais; nenhuma operação Git de escrita.
- A regra de orçamento usa reserva pessimista e retenção de incertezas; prefere parar antes do teto a liberar valor sem prova.
- Task 1: complete — policy/contract RED→GREEN no CF2025, inclusive despacho this.requestBody para corpo compacto.
- Task 2: complete — budget/periods/concurrent/legacy; duas reservas simultâneas só aprovam uma; retenção entre períodos; histórico pré-existente congelado sem duplicação e sem TTL.
- Task 3: complete — batch/pause RED→GREEN; ID incorreto não publica; resultado válido liquida uma vez; pausa após upload não cria lote e permite retomar somente criação comprovadamente não enviada.
- Task 4: complete — flow/pause/resume e pipeline; preservados validadores, fontes integrais e decisões humanas.
- Task 5: complete — 51 suítes nativas + testes Python do leitor; recibo _codex/deploy/geocoding-economy-tests-20261023.json. Harness bloqueia HTTP OpenAI por padrão, mesmo se injeção de fixture falhar.
- Final review: reviewer independente review_geocoding_economy; nenhum crítico ou minor. Dois importantes corrigidos: pausa entre fronteiras HTTP e atributos conflitantes bloqueando escalada. Ambos reproduzidos RED, corrigidos GREEN e suíte completa verde.
- Final review: comportamentos não avaliados pelo reviewer (fornecedor real, preços/schema/modelos disponíveis, runtime e permissões) ficam cobertos por documentação oficial previamente consultada e verificação local/publicação; comportamento pago e qualidade do novo modelo não foram exercitados e exigem piloto posterior.
- Ruling: um pedido por job Batch na primeira versão — mantém desconto e associação durável simples; custo se inadequado: mais chamadas de controle e menor throughput de lotes grandes, não maior tarifa de tokens.
- Ruling: incluir consumo anterior conhecido, com cálculo conservador e snapshot imutável — não conceder outros US$30 no meio do mês; custo se superestimado: bloquear antes da fatura efetiva, explicitado na tela.
- Ruling: nenhuma geração paga no teste — manter a pausa e evitar consumo não validado; custo: qualidade e latência reais de Sol/Astra/Batch ainda precisam de piloto autorizado.
- Preservação: menu publicado corresponde ao recibo openai-usage-20261023, embora difira de HEAD; hash real confirmado, versão de produção preservada sem publicá-lo.
- Task 6: complete — 11 arquivos publicados, backup recuperável /var/backups/business-geocoding-sources-q60ea52f; guards HTTP e hashes aprovados, frentes preservadas conferidas antes/depois. Diretório privado coldfusion:coldfusion 750.
- Runtime instalado: economy_acceptance passou, arquivo de evidência privado /var/backups/geocoding-tests-5yyv4o8i. Sol configurado, enabled=false, chamadas novas=0, tetos 2/30. Consumo anterior conhecido congelado em limite superior de US$69,655598 no mês; não é fatura confirmada. Nenhum gasto novo iniciado.
- Navegador autenticado: configuração publicada mostra Sol/Astra/Batch, orçamento e estado pausado. Indicadores 29.778 sem coordenadas, 20 na fila, 349 revisões, 95 preenchidos e 2.984 sugestões municipais iguais ao baseline anterior à publicação.
- Git preservado: nenhuma alteração de HEAD/index/branches/remotos. Código, testes, documentação e recibos ficam locais, sem commit/push.
