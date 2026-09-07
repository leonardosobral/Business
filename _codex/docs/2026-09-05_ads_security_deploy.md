# Publicação das correções de segurança Ads/Business — 05/09/2026

Publicação autorizada pelo usuário após a revisão das pendências de deploy. Durante a preparação, o usuário confirmou que um update do Git havia reintroduzido versões antigas e autorizou reaplicar as correções preservando as demais alterações.

## Resultado

- Business: pacote de autenticação Google e identidade de sessão, escape de atributos no formulário de banners e CSRF na revisão de solicitações publicado às **22:00:58 UTC**. Total: **52 arquivos**, sendo 48 existentes e quatro novos helpers/CFCs.
- RoadRunners: exclusão de tráfego automatizado/especulativo da cobrança CPC publicada às **21:49:13 UTC**, somente em `api/ads/v1/cpc-click.cfm`.
- O consumidor da revisão de anúncios com seis argumentos já havia sido publicado às 19:47:07 UTC e não foi republicado neste pacote; registro em `2026-09-05_ads_review_consumer_deploy.md`.
- Nenhuma migration foi executada nesta publicação. A aplicação da migration de invariantes foi informada pelo usuário. Não foram aprovadas campanhas, disparados pagamentos ou realizados cliques pagos de teste.
- Não foram criados commits, branches ou worktrees.

## Correções reaplicadas após o update

Somente os trechos necessários foram reaplicados às versões atuais:

1. `cadastro/includes/backend.cfm`: troca de conta Google limpa a identidade de sessão e da requisição, o contexto da conta e tokens anteriores, e rotaciona a sessão.
2. `administracao/contas/includes/backend.cfm`: revisão de acesso exige POST e token CSRF da sessão antes da transação.
3. `portal/banners/home.cfm`: escape de oito valores de FORM interpolados em atributos do formulário, inclusive na reapresentação de erros.

Testes existentes reproduziram as regressões antes da reaplicação. Uma revisão independente, somente leitura, confirmou depois que não identificou bypass ou regressão concreta nesses três ajustes.

## Integridade e recuperação

Servidor: `ssh.runnerhub.run`, confirmado pelos vhosts Apache habilitados e correspondência dos hashes dos arquivos publicados com a base local atualizada.

### Business

- Raiz publicada: `/var/www/business.roadrunners.run`.
- Backup privado dos 48 arquivos anteriores: `/var/backups/business-auth-20260905.McB6sq/before/`.
- Manifesto remoto: `/var/backups/business-auth-20260905.McB6sq/manifest.txt`.
- Cópia durável local: `2026-09-05_business_security_deploy_manifest.txt` (colunas: hash anterior, hash publicado, caminho relativo; `MISSING` identifica os quatro novos arquivos).
- SHA-256 do manifesto: `1cd7682b34605f3f3ba36e3d879662e574f39eadba2424ebcd9ff396e2f21d4c`.
- SHA-256 do pacote: `7d0824a0ffecca65733bac81f85ff8d9ce7655eae942e59e328077e40898c9a8`.
- Todos os 52 destinos foram conferidos antes da publicação; correspondiam à base local atualizada. A configuração principal também correspondia, dispensando sobreposição de diferenças de ambiente.
- Publicação por rename no mesmo filesystem, atômica por arquivo, com `Application.cfc` principal por último. Modo e proprietário preservados nos existentes; novos arquivos `0644`, root:root. Os 52 hashes publicados foram reconferidos.
- Recuperação deve tratar o pacote de identidade como conjunto: restaurar os 48 arquivos do backup e tratar explicitamente os quatro novos caminhos indicados no manifesto. Antes de restaurar, verificar se houve mudança posterior para não sobrescrever outro deploy.

### RoadRunners CPC

- Destino: `/var/www/roadrunners.com.br/api/ads/v1/cpc-click.cfm`.
- Backup: `/var/backups/rr-ads-click-20260905.hrMnSJ/cpc-click.before.cfm`.
- SHA-256 anterior: `5cbf1d57163bf731ba2c4420508af95b345ce92e7d68563475618a242ceac5e2`.
- SHA-256 publicado: `846f76cc0c324d65fba8325d1a207895645ce228bf852ffce5390404f35bff82`.
- Rename no mesmo filesystem; modo `0644`, proprietário root:root preservados.

## Verificações executadas

### Testes locais

- `ads-admin-form-security.cfm`: 85 verificações, nenhuma falha.
- `business-auth-boundary.cfm`: 110 verificações, nenhuma falha.
- `business-auth-security.cfm`: 18 verificações, nenhuma falha.
- Contratos CFML do CPC RoadRunners: 270 verificações, nenhuma falha.
- Contratos shell: login routing; pending onboarding access; pending onboarding approvals; Ads phase2 business access — PASS.
- `git diff --check` — PASS.

Os testes CFML locais usam Lucee e adaptadores isolados para dependências externas. Não substituem o teste de login Google real no Adobe ColdFusion. Nenhum teste offline ou flag de testes foi publicado.

### Ambiente publicado

- Compilação nativa Adobe ColdFusion do candidato Business: **successful 52 / total 52** antes de alterar os arquivos vigentes.
- Compilação nativa de `/api/ads/v1` no RoadRunners: **successful 4 / total 4**.
- HTTPS Business: `/` e `/cadastro/` retornaram 200, com `Cache-Control: private, no-store`, formulário atualizado e sem erro CF embutido.
- Cookies CFID/CFTOKEN retornados com `Secure`, `HttpOnly` e `SameSite=Lax` (valores omitidos dos registros).
- HTTPS sem autenticação: `/ads/?view=admin`, `/administracao/contas/` e `/bi/` retornaram 302 para `/`.
- Callback GET sem credenciais: 302 para `/?login=1&auth_error=1`.
- CPC GET e HEAD sem IDs/tokens: 302 para `https://roadrunners.run/`; nenhum clique financeiro de teste.

## Pendências que esta publicação não encerra

- Validar login Google real e navegação autenticada (conta nova, pendente e existente), incluindo permissões por usuário/conta. Sessões antigas baseadas na identidade anterior podem exigir novo login.
- Homologar aprovação, reserva/aplicação única de voucher e revisão de campanha ponta a ponta, sem confundir compilação com validação funcional autenticada.
- R08–R11 do relatório de rollout continuam fora deste pacote: tempo de impressão com aba oculta; nome/alcance real da lateral do site; combinações mobile/tablet; justiça do lote de reconciliação de pagamentos.

O deploy deste pacote está concluído; isso não equivale à liberação de todos os gates do rollout comercial.
