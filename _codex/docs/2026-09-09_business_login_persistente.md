# Login persistente do Business

Pedido: sessão de pelo menos 24 horas e cookies de autenticação por 30 dias.

## Comportamento

- `Application.cfc` principal e `bi/Application.cfc`: `createTimeSpan(1,0,0,0)`, equivalente a 24 horas de inatividade. O BI continua na aplicação compartilhada `RunnerHubBusiness`.
- Cookie `__Host-business_remember`: credencial aleatória com selector de 128 bits e segredo de 256 bits. `Max-Age=2592000`, `Expires` correspondente, `Path=/`, `Secure`, `HttpOnly`, `SameSite=Lax`, sem `Domain`.
- A tabela `public.tb_business_remember_devices` contém somente o hash SHA-256 do segredo, a identidade Google já verificada e os prazos/revogação. Nenhuma identidade é inferida dos cookies legados.
- Um login Google válido emite a credencial. Sessões já verificadas também são promovidas durante o próximo acesso, dispensando nova seleção da conta Google.
- Sem sessão CF, a credencial válida restaura a identidade e rotaciona a sessão. Contexto de conta e permissões continuam sendo resolvidos pelos backends existentes; não são concedidos pelo cookie.
- A credencial é rotacionada ao restaurar sessão e a cada 24 horas de uso; cada rotação renova os 30 dias. Requisições normais consultam a persistência no máximo a cada cinco minutos por sessão.
- A rotação usa transação e bloqueio de linha. O hash anterior é aceito durante 120 segundos para acomodar abas/requisições simultâneas; a resposta concorrente não sobrescreve o cookie novo.
- Sair e trocar conta Google revogam o dispositivo antes de limpar a sessão e expiram o cookie. A revogação também usa selector/usuário da sessão quando o cookie não é enviado. Outros dispositivos não são revogados.
- Perfil desativado/excluído, mudança de e-mail, expiração e revogação bloqueiam restauração. Sessões vinculadas ao dispositivo são revalidadas, inclusive quando o cookie está ausente.
- Rotas de logout, `logout=1`, marcador de logout e ação de troca de conta não disparam restauração automática.
- Se o banco/tabela estiver indisponível, um login Google válido permanece como sessão de 24 horas; uma sessão anônima não é restaurada. O log `business_auth` registra a indisponibilidade sem credenciais. Em falha do banco durante logout, o cookie e a sessão locais são apagados, mas a revogação remota precisa ser tratada operacionalmente.

## Banco e implantação

1. Aplicar `_codex/sql/2026-09-09_business_remember_devices.sql` no PostgreSQL da aplicação, por conexão administrativa confiável. A migration é aditiva, usa transação, mantém o papel `runner_dba` existente e não altera usuários, papéis ou dados de outros módulos.
2. Publicar primeiro o serviço e helpers, depois os consumidores. A entrada compartilhada é publicada antes do callback/logout novos, e `Application.cfc` principal por último. Não é necessário reiniciar ColdFusion nem chamar `resetApp`.
3. Conferir os hashes e respostas HTTP, depois validar uma sessão de navegador. O cookie novo demonstra emissão efetiva; compilação isolada não comprova disponibilidade da tabela.

A tabela não armazena tokens brutos nem privilégios. Registros expirados/revogados podem ser removidos por manutenção DBA usando `expires_at`; não há exclusão de dados de outras tabelas ou job provisionado neste pacote.

## Validação

`JOSE4J_TEST_JAR=/caminho/jose4j.jar bash _codex/scripts/test_business_remember_local.sh`

O script usa PostgreSQL temporário local, Lucee/CommandBox já instalado e fixtures sintéticas. Interrompe a instância temporária ao terminar. Não acessa contas ou dados de produção.

- Persistência com PostgreSQL real: 28 verificações.
- Fluxos CFML de autenticação, restauração, logout, troca de conta, BI, cadastro e indisponibilidade do banco: 138 verificações.
- Assinatura, claims, nonce e rejeição de cookies legados: 18 verificações.
- Total: 184 verificações aprovadas na preparação. Contratos de roteamento de login e acesso Ads pendente/por papel também aprovados; `git diff --check` sem erros.

Os adaptadores do teste de fluxo substituem apenas os escopos/requisições, consultas de perfil legado, headers, redirects, log e operações de sessão do motor. Persistência, validação de token, SQL de dispositivos e rotação transacional usam os componentes reais e PostgreSQL local. Testes não são publicados.

## Estado de produção

Código publicado em **09/09/2026 às 22:46:30 de Brasília (10/09, 01:46:30 UTC)**: dez arquivos, seis substituídos e quatro novos. Sessão de 24 horas publicada na raiz e no BI. Em 10/09 o usuário confirmou a execução da migration no servidor; a revalidação abaixo confirmou que a consulta de persistência passou a funcionar no runtime publicado.

SSH do banco continua rejeitado por mudança de host key; a chave registrada não foi alterada e a verificação não foi desabilitada. A alternativa solicitada ao operador é executar a migration pelo DataGrip já utilizado no projeto. Nenhuma migration, alteração de papel, segredo ou dado de usuário foi executada pelo agente em produção.

- Backup privado dos seis originais: `/var/backups/business-remember-20260909.talmkY/before/` no host `ssh.runnerhub.run`.
- Candidato e journal de publicação no mesmo diretório privado. Todos os destinos correspondiam aos hashes esperados antes da troca; os dez hashes foram verificados novamente depois. Metadados dos seis arquivos existentes preservados.
- Pacote: `_codex/releases/2026-09-09_business_remember_linux.tar.gz`, SHA-256 `cfb627471c29bd1da46d3365dce95f6412cd61255b4912ed697c36509df2f6de`.
- Manifesto publicado: `_codex/releases/2026-09-09_business_remember_published.sha256`.
- Adobe ColdFusion: `successful 10 / total 10` na compilação do candidato privado antes da publicação.
- Pós-publicação: home/cadastro/logout HTTP 200; BI/Ads anônimos HTTP 302 para `/`; cookie inválido + `id=1` não concede acesso e expira `__Host-business_remember`; callback GET incompleto retorna 302 para `/?login=1&auth_error=1`.
- Conteúdos HTML sem erro CF embutido. Página pública e modal Google conferidos no navegador; não foi feita entrada com uma conta Google real.
- ColdFusion permaneceu com PID `1780425`, iniciado em 01/09; sem restart/reset. O máximo administrativo de sessão é dois dias, compatível com as 24 horas da aplicação.

Rollback, se necessário: comparar os arquivos vigentes com o manifesto, restaurar conjuntamente os seis consumidores/configurações do backup e só então retirar os quatro arquivos novos. Verificar alterações posteriores antes de qualquer recuperação. A tabela aditiva pode permanecer; tokens deixam de ser consumidos pela versão anterior. Nenhum rollback foi necessário.

### Revalidação após aplicação do SQL — 10/09/2026

Às 08:38:53 de Brasília, uma requisição HTTPS a `/ads/` enviou uma credencial sintética com formato válido (selector/segredo hexadecimais), mas inexistente. Isso percorre o SELECT real em `BusinessRememberDevice.restore`, incluindo a tabela nova, usuários e gestão de usuários. O retorno foi HTTP 302 para `/` com expiração explícita de `__Host-business_remember`. Esse header é emitido após retorno normal vazio da consulta; a captura de indisponibilidade não o emite.

O arquivo `business_auth.log` continuou contendo somente a ocorrência anterior das 08:22:42, sem erro novo durante a verificação. Os dez hashes publicados permanecem idênticos ao manifesto. A migração já pode ser consumida pelo código, sem novo deploy ou restart.

A aba Chrome disponível estava deslogada mesmo após recarregar. Não houve emissão de credencial para uma conta real nesta verificação, nem leitura/injeção de cookies de usuário. O primeiro login Google (ou o próximo acesso de uma sessão ainda autenticada, respeitado o intervalo de cinco minutos) emite o cookie de 30 dias. A emissão e restauração autenticadas em produção ainda dependem desse acesso; os testes locais de escrita, rotação, expiração e revogação permanecem documentados acima.
