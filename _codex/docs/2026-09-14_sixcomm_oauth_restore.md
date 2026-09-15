# SixComm: restauração de OAuth em produção — 14/09/2026

## Resultado

Job 14 validado pela ação **Executar agora** do Business às **07:46:52**, horário de São Paulo: **200 OK**, `success=true`, `status=completed`, `transport=gmail_api`, 6.709 ms, 16 mensagens na busca, zero processadas/importadas e zero erros. Agendamento preservado: ativo, a cada 60 minutos; próxima execução exibida às 08:46. Histórico anterior mantido.

## Causa e recuperação

O segredo de integração já havia sido recuperado na tarefa anterior. Faltavam as credenciais OAuth disponíveis ao SixComm. O arquivo local do projeto News continha um cliente dedicado, mas a autorização Gmail persistida pertencia ao cliente Google original do Conteúdo.

Diagnóstico na aplicação ativa, sem gravações no banco ou leitura de mensagens:

- Não havia sobreposição das três chaves OAuth dedicadas em `news.tb_runtime_settings`.
- A conta salva correspondia a `contato@runnerhub.run` e a integridade criptográfica do token estava válida com o segredo preservado.
- O cliente dedicado do arquivo local retornou `401 unauthorized_client` ao renovar o token salvo.
- O cliente Google original do mesmo arquivo retornou `200` e renovou o acesso com o mesmo token.

Foram publicados somente `sixCommGmailClientId`, `sixCommGmailClientSecret` e `sixCommGmailRedirectUri` em `/var/www/conteudo.roadrunners.run/config/content.local.cfm`, usando a combinação original validada. `importerHandoffSecret` e a autorização persistida foram preservados. Não houve novo consentimento, criação de credenciais, alterações de escopos ou reinício da aplicação/serviço.

**Atenção:** não republicar integralmente o arquivo local do News: suas chaves dedicadas antigas não correspondem à autorização atualmente salva. A restauração final usa os valores de `googleOAuthClientId`, `googleOAuthClientSecret` e `googleOAuthRedirectUri` locais, mapeados apenas para as chaves dedicadas do SixComm em produção. O login administrativo geral não foi alterado nesta tarefa.

## Segurança e recuperação

- Baselines do componente Gmail e do leitor de configuração conferidos antes da publicação.
- Configuração mantida como `nobody:nogroup`, modo `640`; valores nunca incluídos neste documento ou no código versionável.
- Backup anterior à primeira restauração: `/var/backups/content-sixcomm-oauth.0d8rxvcj/content.local.cfm.before`.
- Backup anterior à combinação final: `/var/backups/content-sixcomm-oauth.je8zkdad/content.local.cfm.before`.
- Ambos têm manifesto com hashes e diretórios privados. O segundo representa o estado intermediário com o cliente dedicado incompatível; restaurá-lo reintroduz a falha de OAuth.
- Endpoints temporários de diagnóstico usaram a mesma validação HMAC e janela de tempo do importador. Ausência de autenticação e assinatura incorreta retornaram 401; respostas autenticadas continham apenas estados/códigos. Todos os endpoints temporários foram removidos ao fim das verificações.
- Uma tentativa inicial de diagnóstico por CLI não teve acesso ao driver PostgreSQL. Nenhum pacote foi instalado; o diagnóstico útil ocorreu na aplicação ativa.

## Arquivos auxiliares

`restore_sixcomm_oauth_20260914.py` e `publish_sixcomm_oauth_20260914.mjs` implementam restaurações pontuais, com baselines fixos, backup e troca atômica. Não são scripts de publicação genérica nem devem ser repetidos sem nova conferência de produção.

`diagnose_sixcomm_oauth_20260914.cfm`, `run_sixcomm_diagnostic_20260914.py` e `probe_sixcomm_original_client_20260914.mjs` registram o procedimento sem segredos. O diagnóstico CFML recusa execução sem a autorização validada pelo invólucro. Não publicar esses arquivos como endpoints permanentes.
