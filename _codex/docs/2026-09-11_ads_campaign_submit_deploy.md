# Campanhas — enviar para análise como ação principal

Publicação autorizada pelo usuário e concluída em 11/09/2026 às 18:26:27 UTC.

## Fluxo

- Etapa 4: **Enviar para análise** salva campanha, locais e pedido de revisão na mesma transação. Não aprova nem ativa anúncio.
- **Salvar como rascunho** é alternativa explícita. POST antigo sem `campaign_intent` continua salvando somente rascunho.
- Falhas interrompem o fluxo antes da confirmação de sucesso; o tratamento existente reapresenta os dados do formulário.
- Confirmações distintas e retorno à categoria de rascunhos tanto ao salvar quanto ao enviar. Pedidos enviados mostram o status de revisão já existente.
- Rascunhos elegíveis têm Enviar/Reenviar para análise visível fora de Gerenciar. Permissões, CSRF e requisitos de conta/evento permanecem.
- Nenhuma migration, aprovação automática ou envio retroativo de campanhas.

## Publicação

Destino: `/var/www/business.roadrunners.run`, host `ssh.runnerhub.run`.
Backup privado: `/var/backups/business-campaign-submit-20260911.RiG1EW/`.
Cada arquivo anterior está salvo como `<basename>.before`. Hashes de produção anteriores, candidatos e backups conferidos antes da substituição atômica por arquivo. Backend publicado antes do formulário; modo 0644, UID:GID 501:50.

| Arquivo | SHA-256 publicado |
| --- | --- |
| `ads/includes/backend.cfm` | `66ee6f549e4000295e9139d129b98ca10d7a9d02b9902aa0135aeee71c175196` |
| `ads/includes/workspace_campaign_form.cfm` | `bb7ad779ac03a6dad014fddfca42391926c5bac0910e942ae569a10347a84320` |
| `ads/includes/workspace_campaigns.cfm` | `b5ea4ebb987c669c44a8f6bc4c9d74c012df75dccb78a86f9ae490d418f0cbcb` |
| `assets/js/ads-campaign-wizard.js` | `43c3d39f84fec9baea680c76e67b42af2289a76eddccc052f64c865cef1adb06` |

JavaScript versionado `?v=20260911-2`, hash público conferido.

## Verificação

- TDD: teste CFML reproduziu ausência de save+submit e botão oculto em Gerenciar; teste Node reproduziu ausência do controle de visibilidade do botão secundário. Ambos passaram após implementação.
- 23 testes Node passaram.
- Teste CFML executa os fragmentos reais de fluxo e HTML com chamadas de banco simuladas: separação de intenções, ID salvo enviado à revisão, falhas em cada chamada sem confirmação, ações visíveis por status e ausência de envio para leitor. Não é teste de integração com PostgreSQL.
- Suítes shell de onboarding e permissões passaram. Atualizado o contrato textual do botão de rascunho para o novo rótulo.
- ColdFusion de produção compilou **14/14** templates.
- Chrome autenticado: aba separada na conta Live!, navegação real pelos quatro passos e captura visual da etapa final. Confirmados os dois botões e a explicação de aprovação obrigatória. Não foi clicado nenhum botão de envio/salvamento.
- Listagem autenticada abriu sem erro. Os rascunhos observados já estavam em análise, portanto o botão direto para rascunhos não enviados foi verificado pelo teste CFML, não por um envio real.
- Aba de conferência fechada; conta selecionada e aba original preservadas. Nenhum anúncio criado/alterado/aprovado, clique patrocinado, crédito consumido ou reinício de serviço realizado.

Rollback: conferir hashes atuais para preservar mudanças posteriores, restaurar formulário/listagem/JavaScript dos `.before` e por último backend. Recompilar templates. Não restaurar outros arquivos.
