# Informações para revisar os 61 motivos pendentes

## Escopo

Business: `/portal/verificados/?filter_status=unclassified`. A consulta agora reúne evidências já existentes por perfil, sem criar concessões, alterar prazos, classificar motivos ou chamar a Pagar.me. Não há migração, alteração de checkout ou publicação no Road Runners.

Arquivos de runtime: `services/VerifiedAdmin.cfc`, `portal/includes/verified_backend.cfm`, `portal/verificados/home.cfm`, `portal/verificados/evidence.cfm` e `portal/verificados/verified.css`.

## O que aparece

- Filtros de contexto com contagem da fila inteira: TSD VIP/upgrade sem confirmação (57), VIP antigo do Desafio 365 (12), TSD Básica confirmada (12), nenhum cadastro de desafio (2), bio (26) e Instagram público (7). Grupos se sobrepõem; filtros adicionais podem reduzir a lista.
- Resumo por pessoa: cidade, bio informada pelo atleta, Instagram com publicação autorizada e etiquetas de contexto.
- “Cadastros e pedidos”: contas vinculadas, assessoria informada, inscrições atuais com produto/status/data/referência, histórico CNA separado, eventos financeiros e conferência financeira prévia quando disponível.
- Detalhe completo junto às origens e ao editor de motivos existentes. As quatro divergências VIP continuam em sua própria aba.

## Significado e limites

`C` significa confirmado no cadastro, não pagamento atualmente aprovado. Cadastro VIP/upgrade em outro status não confirma pagamento. A Básica não inclui selo. VIP de 2025 do Desafio 365 e registros CNA são históricos; não provam VIP vigente no TSD e podem se repetir entre fontes. Um dos 12 históricos consta como confirmado somente no CNA.

A bio é declaração do atleta, não comprovação independente de atuação profissional, imprensa ou elite. Instagram privado não é exibido. Notas livres de inscrição são reduzidas a avisos genéricos de upgrade ou cancelamento/estorno para não expor dados operacionais ocultos.

O histórico financeiro mostra somente eventos locais da Pagar.me associados a contas positivas e produtos conhecidos. Agrupa por pedido e produto, separa evento de pagamento, falha e cancelamento; cancelamento não é rotulado automaticamente como estorno. Conciliação só é mostrada se o estado do CRM e a auditoria concordarem no status e produto e houver data de verificação. Esta tela não consulta novamente a API nem conclui ausência de pagamento por falta de evento.

## Validação e publicação

Artefatos da tarefa: `_codex/staging/verified-pending-context-20261124/`.
- Teste CF nativo em transação somente de leitura: contagens, filtros, paginação, vínculos, limites de consulta, rejeição de entrada inválida e preservação dos selos/filas.
- Renderização real das templates em contexto de teste privado: autorização, CSRF, ação antiga bloqueada e escape de HTML malicioso.
- Revisão visual em navegador isolado, desktop e celular, com encerramento do navegador e servidor temporário.
- Publicação restrita aos cinco arquivos, com comparação do baseline, compilação CF, backup e reversão automática se os checks falharem.
- Verificação após publicação com os arquivos reais e consultas somente de leitura.

Baseline dos dados: 418 ativos, 332 com prazo, 86 permanentes, 61 motivos pendentes, 4 divergências VIP e 6 conciliações gerais pendentes. Nenhuma mudança de dados é necessária para esta entrega.

Publicação realizada em 24/11/2026. Backup recuperável: `/var/backups/business-verified-pending-context-c0111j6v`. Os cinco hashes publicados correspondem aos arquivos testados. Testes nativos: 198 verificações aprovadas; acesso direto bloqueado (403), CSRF inválido bloqueado (403) e ação antiga bloqueada (409).

Verificação posterior: nove consultas renderizadas com os arquivos publicados responderam 200 (lista, fila, segunda página, filtros, dois detalhes, divergências e VIP conciliado). Todos os ambientes temporários de teste foram removidos; navegador e servidor de prévia encerrados e conferidos.
