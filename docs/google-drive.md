# Documentos do Google Drive no Business

Módulo: `/administracao/drive/`. Conta autorizada: **contato@runnerhub.run**.

O módulo usa a mesma conexão OAuth da Agenda e do card do Meet. Ele cria uma pasta raiz dedicada no Meu Drive da conta e permite aos administradores globais navegar, buscar, criar subpastas, criar Google Docs e Sheets, enviar arquivos, renomear, baixar arquivos comuns, enviar itens à lixeira, abri-los no Google e autorizar itens já existentes por meio do Google Picker.

O escopo usado é `https://www.googleapis.com/auth/drive.file`, recomendado pelo Google para acesso limitado aos arquivos criados pelo aplicativo. O Business não solicita os escopos amplos e restritos `drive` ou `drive.readonly`.

## Ativação rápida

1. No mesmo projeto Google Cloud usado pela Agenda, ative a [Google Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com) e a [Google Picker API](https://console.cloud.google.com/apis/library/picker.googleapis.com).
2. Abra a configuração da [tela de consentimento OAuth e acesso a dados](https://console.cloud.google.com/auth/scopes). Inclua o escopo `https://www.googleapis.com/auth/drive.file`. Mantenha também os escopos já usados por Agenda, identidade e Meet.
3. Em [APIs e serviços → Credenciais](https://console.cloud.google.com/apis/credentials), abra o **ID do cliente OAuth 2.0** do tipo Aplicativo da Web que já é usado pela Agenda. Em **Origens JavaScript autorizadas**, inclua exatamente `https://business.roadrunners.run` — sem caminho e sem barra final. Não remova o URI de redirecionamento já usado pela Agenda.
4. Ainda em **Credenciais**, crie uma **chave de API** exclusiva para o Picker. Edite a chave e aplique:
   - **Restrições de aplicativo → Sites**: `https://business.roadrunners.run/*`;
   - **Restrições de API → Restringir chave → Google Picker API**.
5. Copie o **Número do projeto** em [IAM e administrador → Configurações](https://console.cloud.google.com/iam-admin/settings). Ele é numérico e será o App ID do Picker; não use o ID textual do projeto.
6. Configure os dois valores no ambiente do processo ColdFusion:

   ```text
   RR_GOOGLE_DRIVE_PICKER_API_KEY=chave_criada_no_passo_4
   RR_GOOGLE_DRIVE_APP_ID=numero_do_projeto_do_passo_5
   ```

   Se o servidor usa `config/business.local.cfm`, coloque os equivalentes no struct `businessLocalConfig`:

   ```cfml
   "googleDrivePickerApiKey" = "chave_criada_no_passo_4",
   "googleDriveAppId" = "numero_do_projeto_do_passo_5",
   ```

7. Publique estes arquivos no servidor:
   - `Application.cfc`;
   - `administracao/agenda/oauth/callback.cfm`;
   - a pasta `administracao/drive/` completa;
   - `includes/estrutura/sidenav.cfm`.
8. Se ainda não tiver feito isso, execute `administracao/drive/drive_schema.sql` no PostgreSQL `runner_dba`. Exemplo, ajustando conexão e caminho:

   ```sh
   psql -d runner_dba -f administracao/drive/drive_schema.sql
   ```

9. Reinicie a aplicação ColdFusion pelo procedimento do servidor. Se estiver usando o mecanismo já existente, acesse uma única vez `https://business.roadrunners.run/?resetApp`; essa URL encerra a requisição, então depois abra o painel normalmente.
10. Acesse `https://business.roadrunners.run/administracao/agenda/`, desconecte a conexão antiga caso esteja ativa e clique em **Conectar Google**. Entre exclusivamente com **contato@runnerhub.run** e aceite a nova permissão de Documentos. Um refresh token já salvo não ganha um novo escopo automaticamente.
11. Acesse `https://business.roadrunners.run/administracao/drive/` e clique em **Criar pasta RunnerHub Business**, caso ela ainda não exista. Faça isso apenas uma vez.
12. Clique em **Abrir no Drive** e compartilhe a pasta raiz com a equipe usando a interface do Google. O Business não altera compartilhamentos nesta versão.

## Configuração opcional

O padrão é uma pasta chamada `RunnerHub Business` e uploads de até 25 MB. Para alterar, configure no ambiente do processo ColdFusion:

| Variável | Padrão | Uso |
|---|---:|---|
| `RR_GOOGLE_DRIVE_ROOT_NAME` | `RunnerHub Business` | Nome usado somente ao criar a pasta raiz pela primeira vez |
| `RR_GOOGLE_DRIVE_MAX_UPLOAD_BYTES` | `26214400` | Limite por arquivo, entre 1 MB e 100 MB |
| `RR_GOOGLE_DRIVE_PICKER_API_KEY` | vazio | Chave pública de navegador, restrita ao domínio do Business e à Picker API |
| `RR_GOOGLE_DRIVE_APP_ID` | vazio | Número numérico do projeto Google Cloud |

Como alternativa, use `googleDriveRootName`, `googleDriveMaxUploadBytes`, `googleDrivePickerApiKey` e `googleDriveAppId` no struct de `config/business.local.cfm`. Depois de qualquer alteração, reinicie a aplicação. Alterar o nome configurado não renomeia uma pasta raiz já criada.

## Uso e dicas

- Use **Novo** ou **Enviar** no próprio Business para que os itens sejam criados com o acesso `drive.file`.
- Para um arquivo ou pasta colocado manualmente pelo Google Drive, abra no Business a pasta em que o item foi colocado, clique em **Adicionar do Drive**, selecione os itens e confirme. A lista é atualizada automaticamente.
- O Picker começa na pasta atual, mas o servidor aceita apenas itens cuja hierarquia termine na pasta raiz segura do Business. Um item selecionado fora dessa raiz é ignorado.
- Como `drive.file` concede acesso por item, selecionar somente uma pasta pode não tornar todos os filhos preexistentes visíveis. Se algum não aparecer, entre nessa pasta pelo Business e use **Adicionar do Drive** novamente para selecionar seus arquivos; selecione vários de uma vez quando for conveniente.
- Google Docs e Sheets são editados no Google pelo botão de abrir. Arquivos comuns podem ser baixados pelo painel.
- **Enviar à lixeira** usa a lixeira do Google Drive; a recuperação e a exclusão definitiva continuam sendo feitas no Google.
- A lista consulta o Google ao vivo, em páginas de 100 itens. O Business não mantém cópia do conteúdo dos arquivos.
- Se o painel disser que falta permissão, reconecte pela Agenda e confirme que `drive.file` aparece entre os acessos concedidos.

## Segurança e operação

- Página, API e download exigem a autenticação existente e `require_admin.cfm`; portanto, somente administradores globais efetivos acessam o módulo.
- Toda alteração usa POST com token CSRF. Downloads são GET autenticados e retornados como anexo com `nosniff`.
- Antes de listar, renomear, baixar ou excluir, o servidor percorre a hierarquia de pais no Google e comprova que o item está dentro da pasta raiz registrada. O ID enviado pelo navegador nunca basta por si só.
- A pasta raiz não pode ser renomeada nem enviada à lixeira pelo painel. Executáveis e scripts são bloqueados no upload, e o limite é aplicado no cliente e novamente no servidor.
- Criações, uploads, renomeações e envios à lixeira ficam registrados em `tb_google_drive_auditoria`, sem armazenar conteúdo dos arquivos ou tokens.
- O refresh token permanece criptografado na tabela já usada pela Agenda. O Picker obtém no navegador um access token temporário contendo somente `drive.file`; ele fica apenas na memória da página, não é enviado ao backend e não é salvo em `localStorage` ou cookie.
- O Client ID e a chave de API aparecem no navegador por definição do Picker. A proteção da chave depende das restrições de site e de API configuradas no Google Cloud; ela não deve ser usada sem essas restrições.
- Compartilhamento, restauração da lixeira, exclusão definitiva, atalhos e exportação de arquivos Google não fazem parte desta versão.

## Verificação local

```sh
node --test _codex/tests/google-drive.test.js
```

O runner `_codex/tests/GoogleAgendaCfmlCheck.java` também compila o serviço e a API do Drive no Lucee e executa regressões offline. A homologação final deve usar a conta e a API reais.

Referências oficiais: [visão geral do Google Picker](https://developers.google.com/workspace/drive/picker/guides/overview), [guia do Picker para Web](https://developers.google.com/workspace/drive/picker/guides/web-picker), [exemplo Web com Google Identity Services](https://developers.google.com/workspace/drive/picker/guides/web-picker-sample), [referência de `DocsView.setParent`](https://developers.google.com/workspace/drive/picker/reference/picker.docsview.setparent), [escolha de escopos do Drive](https://developers.google.com/workspace/drive/api/guides/api-specific-auth), [busca e listagem](https://developers.google.com/workspace/drive/api/guides/search-files) e [tratamento de `appNotAuthorizedToFile`](https://developers.google.com/workspace/drive/api/guides/handle-errors).
