# Correções para o rollout de Ads — 04/09/2026

Execução autorizada após o update dos projetos. Base: [revisão completa](2026-09-04_ads_banners_rollout_review.md).

## Escopo e ordem

1. Business: identidade autenticada pelo servidor, validação do token Google antes de qualquer escrita e fechamento dos caminhos de login equivalentes. Preservar cadastro sem conta, contas pendentes, seleção/simulação, BI e retorno à pesquisa.
2. SQL compartilhado: aprovação vinculada à versão/evento revisados; impedir ativação sem revisão; permitir preparar a campanha quando o evento foi aprovado antes da conta.
3. Business: atributos do formulário HOUSE escapados e revisão de cadastro protegida por POST + CSRF.
4. RoadRunners: impedir débito por crawlers/prefetch conhecidos sem quebrar o redirecionamento nem cliques humanos rápidos.
5. Executar regressões locais, revisão independente do patch e registrar ordem de publicação e limitações.

Não inclui publicação, execução de migrations em produção, aprovação/alteração de campanhas reais, alterações de saldo, commits ou worktrees. Migrations serão entregues para aplicação explícita.

## Verificação

- Casos negativos e controles legítimos em CFML local e PostgreSQL descartável.
- Contratos existentes de onboarding, campanha, pagamentos, banners, renderização e métricas.
- Revisão de caminhos alternativos e concorrência após o patch.
- Login Google real e homologação Adobe ColdFusion continuam sendo gates de publicação; testes locais não serão apresentados como homologação em produção.

## Compatibilidade prevista do login

O cookie com o ID do usuário não será mais credencial. Sessões antigas não verificadas exigirão novo login Google. O tempo de sessão nativa existente é de 50 minutos de inatividade; o cookie antigo de 30 dias não fornece uma sessão persistente segura. O acesso à conta continuará sendo revalidado separadamente da identidade.

## Implementação entregue

| Item | Barreira implementada | Evidência local |
| --- | --- | --- |
| R01 | Identidade de sessão versionada; Google RS256 validado por jose4j (assinatura, emissor, audiência, expiração, subject, e-mail verificado e nonce); callback POST com CSRF antes de escrever no banco; aliases antigos não criam identidade. | 18 verificações criptográficas e 110 de callback/identidade; RSA real offline, adaptadores externos substituídos. |
| R02/R03 | Edição material cancela revisão, cada envio tem ID novo e a decisão exige o ID exibido; ativação CPC exige revisão/conta/evento correspondentes. | 24 contratos SQL e duas disputas concorrentes; migration aplicada duas vezes no banco descartável. |
| R06 | OWNER provisório pode preparar a campanha para evento já aprovado enquanto a conta está pendente. | As duas ordens conta/evento, mais negativo para evento solicitado por outro usuário. |
| R04 | Oito atributos do formulário HOUSE escapados, inclusive após erro. | Renderização CFML de payloads, catch do backend e controles com valores legítimos. |
| R07 | Aprovar/recusar cadastro exige POST + CSRF da sessão antes da transação, para OWNER e admin. | Conjunto combinado R04/R07: 85 verificações nativas. |
| R05 | Bot/scanner/prefetch conhecido não chama a função de débito; URL de destino é resolvida por token/delivery válido, sem consumir o clique humano posterior. | 270 verificações do endpoint CFML; banco/HTTP/log substituídos, sem débito real. |

No R01, as leituras de cookies de identidade foram substituídas mecanicamente por `REQUEST.businessIdentity` nos consumidores, inclusive BI, pesquisa, auditoria e aliases legados. Não foram alteradas as permissões de conta para ampliar acesso. O BI usa a mesma aplicação/sessão e inicialização do Business; sua autorização legada de parceiro continua restrita ao BI. Logout/troca de conta apagam identidade e CSRF/contexto anterior. Cookies nativos de sessão são Secure/HttpOnly/SameSite=Lax; páginas de login e respostas autenticadas recebem `no-store`.

Foi usada a biblioteca jose4j 0.9.4 já presente no Adobe ColdFusion do servidor (`cfusion/lib/jose4j.jar`), sem adicionar dependência binária ao projeto. As chaves vêm exclusivamente do JWKS HTTPS fixo do Google, com cache e timeouts. Falhas não registram tokens nem expõem claims. Referência: [validação Google](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token).

O vínculo de usuários pelo e-mail verificado mantém a política existente do produto; esta etapa não migra identidades globais para um índice único de subject Google nem implementa uma nova prova de propriedade para e-mails externos ao Gmail/Workspace. Isso deve ser considerado no desenho de recuperação/vinculação de identidade, separado desta correção de token não verificado.

## Arquivos e aplicação

- Migration **nova, incremental e canônica**: `RoadRunners/_codex/sql/2026-09-04_ads_review_activation_invariants.sql`. Não executar o relatório read-only anterior como migration, nem reaplicar a foundation inteira.
- Consumidor correspondente: `Business/ads/includes/backend.cfm`, readiness e chamada `review_campaign` com seis argumentos.
- Detalhes SQL/rollback: `RoadRunners/_codex/docs/2026-09-04_ads_review_activation_invariants.md`.
- Detalhes do clique: `RoadRunners/_codex/docs/2026-09-04_ads_cpc_click_traffic.md`.
- Testes novos Business: `_codex/tests/business-auth-security.cfm`, `business-auth-boundary.cfm`, `ads-admin-form-security.cfm`.
- Os contratos antigos de roteamento e de rota de voucher foram alinhados à extração do callback e à lista atual de abas; não houve remoção de assertivas de autorização.

Aplicar migration primeiro, depois o consumidor Business. Publicar o conjunto R01 **junto**, incluindo os dois Application.cfc, os novos helpers/CFCs e os consumidores de identidade; publicar apenas o callback ou apenas o Application.cfc cria uma versão incompleta. Preservar configuração local do ambiente e eventuais diferenças de implantação. RoadRunners recebe também o endpoint CPC e o ajuste correspondente da auditoria estática. Nada disso foi publicado nesta execução.

## Gates ainda abertos antes do rollout

1. Homologar no **Adobe ColdFusion** com sessão HTTP/cookies reais: home → Google → conta existente/nova/pendente; seleção/simulação; retorno à pesquisa/BI; logout; expiração; troca Google e segunda aba. Os testes executados usam Lucee 5.3.10.120/Java 8 e jose4j real, não uma sessão Google real.
2. Aplicar a migration e validar os fluxos HTTP de edição/reenviar/aprovar, inclusive decisão de uma tela antiga. O PostgreSQL local usa as funções/triggers reais, mas tabelas públicas mínimas; não simula todas as dependências da base legada.
3. Auditar campanhas **já ativas** contra revisão e vínculo. A migration protege novas decisões/ativações; não pausa campanhas existentes retroativamente.
4. Confirmar os pontos R08–R11 do relatório: tempo de viewability com aba oculta; rótulo/alcance real do sidebar; elegibilidade mobile/tablet; justiça do lote de reconciliação. Esta rodada priorizou os cinco P1 e R06/R07 e não implementou essas mudanças adicionais.
5. Executar smoke de entrega/métricas/financeiro controlado em homologação. O teste de clique usa adaptadores e não prova o debit SQL real; scanners disfarçados de navegador sem sinais conhecidos não são resolvidos apenas por esse filtro.

Situação: correções preparadas e testadas localmente; **rollout não liberado apenas com estes testes**. Não houve campanha/saldo alterado, migration em produção, deploy, commit ou branch nova.

## Reprodução da validação

Os testes CFML agora exigem `RUNNERHUB_OFFLINE_CFML_TESTS=1` **somente no processo local**; sem o opt-in retornam 404 antes de inicializar fixtures. Nunca definir essa variável no servidor web e não incluir `_codex/tests` no pacote público. Exemplo com CommandBox disponível no PATH:

```sh
RUNNERHUB_OFFLINE_CFML_TESTS=1 JOSE4J_TEST_JAR=/caminho/local/jose4j-0.9.4.jar box execute _codex/tests/business-auth-security.cfm
RUNNERHUB_OFFLINE_CFML_TESTS=1 JOSE4J_TEST_JAR=/caminho/local/jose4j-0.9.4.jar box execute _codex/tests/business-auth-boundary.cfm
RUNNERHUB_OFFLINE_CFML_TESTS=1 box execute _codex/tests/ads-admin-form-security.cfm
```

Nesta máquina foi usado `java -cp '/Users/Shared/Projects/ColdFusion Certification/box' cliloader.LoaderCLIMain -CommandBox_home=/private/tmp/runnerhub-cfml-security.P0LhsU/commandbox execute ...` no lugar de `box execute`. O diretório temporário é runtime de testes, não uma cópia do projeto; as alterações estão nos projetos originais. O teste CPC equivalente está no RoadRunners e usa o mesmo opt-in.

Verificações finais executadas:

- CFML: 18 + 110 + 85 verificações Business e 270 do endpoint CPC, sem falhas.
- PostgreSQL: 24 contratos + duas ordens concorrentes; contrato existente de ranking também passou. A sandbox inicialmente bloqueou memória compartilhada; os testes passaram com execução local autorizada fora dessa restrição.
- Node: 27 testes Business; contrato DOM-ready da viewability RoadRunners passou.
- Shell: 18 suítes Business (incluindo vouchers após correção da assertiva obsoleta de rota) e sete suítes estáticas/contratuais RoadRunners passaram.
- Auditoria de datasource: `runnerhub`, sem `runner_dba` no runtime Ads; sintaxe do runner Node e `git diff --check` dos dois projetos passaram.
- O smoke HTTP existente de Googlebot não foi concluído nesta rodada (DNS da sandbox); não é usado como prova do patch local. Nenhum clique pago ou novo anúncio foi disparado para testar.

Revisão independente: nenhuma falha concreta restante nos limites revisados de identidade, formulário HOUSE, CSRF e filtro CPC. A revisão SQL encontrou a regressão PAUSED→CANCELED sem reenvio; foi reproduzida, corrigida e revalidada. A revalidação indevida do papel atual do revisor histórico também foi removida após teste negativo, mantendo a autorização no momento da decisão. As limitações de homologação acima permanecem.
