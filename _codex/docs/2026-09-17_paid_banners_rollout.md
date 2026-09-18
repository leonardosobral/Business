# Banners CPC — rollout em preparação

## Estado

Não publicado. O SQL foi aplicado pelo operador, com COMMIT corroborado no log
DataGrip em 17/09/2026 às 18:46:35. A nova seleção paga ainda está desabilitada.
Nenhuma campanha foi criada, aprovada, ativada ou cobrada pelo agente em produção.

Fonte canônica do andamento:
`.superpowers/sdd/2026-09-16_paid_banners_plan/progress.md`.

## Contrato

- Banners CPC têm painel separado e carteira compartilhada com eventos.
- OWNER/ADMIN/OPERADOR gerenciam a conta; VISUALIZADOR apenas consulta.
- Aprovação de banners depende da identidade global real e da última revisão.
- CPC elegível tem preferência; HOUSE continua gratuito e é fallback de inventário.
- A flag de seleção paga é separada das flags EVENT, desligada por padrão e por ambiente.
- Desligar seleção não deve interromper recibos já emitidos nem conciliação financeira.
- Não alterar os dois spots nem o ranking dos anúncios de eventos nesta entrega.

## Evidências já obtidas

- Migration SHA256 `b706b0921e58d5101f341da4c62f541bcb14b9eee42a058d1d5fa2cd5270da39`.
- Task1: revisão independente aprovada e 11 grupos SQL reais PASS, inclusive corrida
  EVENT+BANNER no mesmo saldo, replay, hold, orçamento e estorno idempotente.
- Task2: painel integrado, duas falhas de recuperação corrigidas e revisão independente
  aprovada. Nova execução pelo controlador: 51 verificações CFML PASS; consultas reais
  do painel (3 BANNER + 11 EVENT/extrato) validadas em PostgreSQL descartável.
- Runtime Business corrigido compilado nativamente: 17/17 arquivos CFML, em preparação
  privada `/var/backups/house-banner-scope.9cf3376c1ba0` (não publicado).
- Regressão JavaScript atual: 35 testes PASS (wizard, métricas, ordem dos eventos,
  símbolos CF, painel HOUSE, upload e escopo), além de viewability DOM-ready PASS.
- Publicador: 11 testes PASS; transportes simulados, nenhum acesso de publicação.
- Baseline de runtime comparado com produção. A diferença localizada em
  `RoadRunners/includes/ads_v1/banner_slot.cfm` é o rótulo localizado de publicidade;
  a cópia de produção está preservada em `production-before` e deve ser mantida.

## Gates pendentes

1. Task2 concluída localmente; desktop/mobile de fixture verificados em 1280/390px.
   Verificação do fluxo autenticado real continua pendente da publicação.
2. Task3 em implementação: entrega CPC/HOUSE, flag, recibos e proteção de bots.
3. Revisão global da integração e compilação Adobe CF dos candidatos exatos.
4. Manifesto explícito com hashes de antes/depois, backup recuperável e publicação
   apenas dos caminhos autorizados por `_codex/scripts/deploy_paid_banners.py`.
5. Verificação real das telas e regressão HOUSE sem cliques pagos de teste.

## Recuperação

O publicador existente valida baseline e metadados e mantém backup recuperável.
O comando de rollback só será registrado após existir recibo de preparação real.
Não apagar ou reverter ledger, reviews ou migration como rollback de interface.
Não publicar SQL nem `config/ads.local.cfm` através do manifesto de runtime.

## Verificação após publicação

- Confirmar hashes publicados e integridade dos caminhos protegidos pelo publicador.
- Abrir `/portal/banners/` autenticado como administrador global: painel CPC global,
  fila de revisão e acesso explícito ao HOUSE, sem alterar campanhas.
- Selecionar conta e conferir painel/formulário CPC e link ao saldo compartilhado;
  não salvar, aprovar, ativar ou gerar clique cobrado como teste em produção.
- Abrir a visão HOUSE explícita e confirmar que inventário e escopo continuam presentes.
- Conferir homepage RoadRunners: peça carregada, rótulo Publicidade, endpoint HOUSE
  enquanto o gate CPC está desligado e dois espaços de anúncios de eventos preservados.
- Registrar limitações: envio multipart e ciclo pago real não são homologados por mera
  navegação; os testes locais cobrem os contratos, mas homologação paga exige ação
  autorizada do operador e configuração explícita por ambiente.
