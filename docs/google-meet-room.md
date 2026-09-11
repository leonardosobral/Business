# Sala virtual do Google Meet no Business

O dashboard dos administradores globais mostra um card **Sala virtual da equipe**. Ele informa se a sala está ativa, quantas pessoas estão conectadas, os nomes retornados pelo Google Meet e o horário da última atualização. O botão **Entrar na sala** abre o Meet em uma janela dedicada.

A barra superior desses administradores também mostra uma versão compacta antes das notificações: indicador de estado, até três avatares com iniciais, excedente `+N` e acesso direto à sala. Os nomes completos permanecem disponíveis no tooltip. Foram usadas iniciais porque o recurso `participants` do Meet fornece nome e identificador, mas não uma URL de foto; assim não é necessário ampliar os escopos OAuth.

Esta implementação mantém o Google Meet como aplicação de videoconferência. O Business não captura áudio, vídeo ou chat e não tenta incorporar a interface do Meet em um `iframe`.

## Arquitetura implementada

1. O navegador do administrador consulta `/administracao/meet/status.cfm` a cada 20 segundos enquanto a aba está visível.
2. O endpoint, protegido por login e `require_admin.cfm`, usa a conexão OAuth já mantida pela Agenda Google.
3. O servidor consulta `spaces.get` usando o código da sala.
4. Quando existe `activeConference`, consulta os participantes e mantém apenas os que não possuem `latestEndTime`, isto é, os que ainda não encerraram a participação.
5. A resposta do Google é compartilhada entre administradores por um cache de 15 segundos no `APPLICATION` scope.
6. O navegador cria os chips de nomes com `textContent`; nomes informados por participantes nunca são tratados como HTML.

Não há tabela nova nem migração SQL. A presença é efêmera e não é armazenada como histórico.

Referências oficiais: [visão geral da API do Meet](https://developers.google.com/workspace/meet/api/guides/overview), [consultar uma sala e `activeConference`](https://developers.google.com/workspace/meet/api/guides/meeting-spaces#get-meeting), [listar participantes ativos](https://developers.google.com/workspace/meet/api/guides/participants#list-participants) e [escopos OAuth do Meet](https://developers.google.com/workspace/meet/api/guides/authenticate-authorize).

## 1. Confirmar a conta proprietária da sala

A integração OAuth do Business aceita exclusivamente **contato@runnerhub.run**. Para que o status funcione mesmo quando essa conta não estiver participando da chamada, a sala permanente deve pertencer a ela.

1. Abra o evento recorrente correspondente no Google Calendar e confirme que o organizador é `contato@runnerhub.run`; ou abra a sala no Meet com essa conta e confirme os controles de anfitrião.
2. Se a sala pertencer a outra pessoa, a opção mais previsível é criar uma nova sala permanente estando autenticado como `contato@runnerhub.run` e substituir o link usado pela equipe.
3. Copie o link completo, no formato `https://meet.google.com/abc-defg-hij`. Não inclua senhas, tokens ou outros parâmetros na configuração.

O Google documenta que proprietários e participantes podem consultar registros de participantes. A propriedade é exigida operacionalmente aqui para evitar que a leitura dependa de `contato@runnerhub.run` estar dentro de cada conferência: [permissões de participantes](https://developers.google.com/workspace/meet/api/guides/participants).

## 2. Habilitar a Google Meet REST API

Use o mesmo projeto Google Cloud do OAuth da Agenda — o projeto que contém o Client ID configurado em `RR_GOOGLE_CALENDAR_CLIENT_ID`.

1. Entre no [Google Cloud Console](https://console.cloud.google.com/) com uma conta que administre esse projeto.
2. Selecione o projeto correto no seletor superior.
3. Abra a página da [Google Meet REST API](https://console.cloud.google.com/apis/library/meet.googleapis.com).
4. Clique em **Ativar**. Se a tela mostrar **Gerenciar**, a API já está habilitada.
5. Não é necessário habilitar Google Workspace Events API nem Pub/Sub para esta versão.

## 3. Autorizar o novo escopo no aplicativo OAuth

O código agora solicita o escopo sensível, somente leitura:

```text
https://www.googleapis.com/auth/meetings.space.readonly
```

Esse escopo permite ler metadados de salas às quais a conta autorizada tem acesso. Ele não permite capturar áudio ou vídeo.

1. No projeto Google Cloud, abra [Google Auth Platform](https://console.cloud.google.com/auth/overview).
2. Em **Acesso a dados** ou **Data Access**, inclua `meetings.space.readonly` entre os escopos declarados pelo aplicativo.
3. Preserve os escopos existentes de OpenID e Google Calendar.
4. Preserve a URI de redirecionamento exatamente como:

   ```text
   https://business.roadrunners.run/administracao/agenda/oauth/callback.cfm
   ```

5. Se todas as contas envolvidas pertencem ao mesmo Google Workspace, prefira o tipo de público **Interno**. Para aplicativo externo em modo de testes, mantenha `contato@runnerhub.run` como test user e considere que o refresh token pode expirar em sete dias. Consulte [OAuth consent e escolha de escopos](https://developers.google.com/workspace/guides/configure-oauth-consent).
6. Se o Admin Console do Workspace restringir aplicativos OAuth, libere o Client ID para esse escopo em **Segurança → Controles de API → Controle de acesso de apps**. Consulte [controlar acesso de apps](https://support.google.com/a/answer/7281227).

Aplicações externas que disponibilizam escopos sensíveis para usuários fora da própria organização podem precisar da verificação do Google. A classificação do escopo está na [documentação de autorização do Meet](https://developers.google.com/workspace/meet/api/guides/authenticate-authorize#meet-rest-api-scopes).

## 4. Publicar os arquivos

Publique estes arquivos junto com as demais alterações do release:

```text
Application.cfc
administracao/agenda/oauth/callback.cfm
administracao/meet/includes/service.cfm
administracao/meet/status.cfm
assets/js/business-meet-room.js
includes/estrutura/home_admin_dashboard.cfm
docs/google-agenda.md
docs/google-meet-room.md
config/business.local.example.cfm
```

Não execute SQL novo. Se a Agenda Google ainda não estiver instalada, aplique antes `administracao/agenda/agenda_schema.sql`, conforme [`google-agenda.md`](google-agenda.md).

## 5. Configurar a sala no servidor

Adicione ao ambiente do processo ColdFusion:

```text
RR_GOOGLE_MEET_ROOM=https://meet.google.com/abc-defg-hij
```

Substitua `abc-defg-hij` pelo código real. Também é aceito somente o código, mas o link completo é mais fácil de auditar.

Opcionalmente, configure o cache compartilhado entre 5 e 60 segundos:

```text
RR_GOOGLE_MEET_CACHE_SECONDS=15
```

Quinze segundos é o valor recomendado. O navegador consulta o Business a cada 20 segundos; o cache impede que vários administradores multipliquem as chamadas ao Google.

Como alternativa às variáveis de ambiente, acrescente ao struct já existente de `config/business.local.cfm`, sem substituir as outras chaves:

```cfml
"googleMeetRoom" = "https://meet.google.com/abc-defg-hij",
"googleMeetCacheSeconds" = 15,
```

Esse arquivo é ignorado pelo Git. O link não é uma credencial, mas deve continuar restrito à configuração operacional da empresa.

## 6. Recarregar a aplicação

Depois de publicar e configurar:

1. Reinicie a aplicação ColdFusion pelo procedimento normal do servidor; ou acesse `https://business.roadrunners.run/?resetApp` e depois abra novamente o Business.
2. Na próxima requisição, confirme que `APPLICATION.googleMeet` foi carregado. Visualmente, o card deve deixar de mostrar **Configuração pendente**.

Variáveis de ambiente têm precedência sobre `config/business.local.cfm`.

## 7. Reconectar a conta Google

O refresh token existente foi emitido sem o escopo do Meet e precisa ser substituído.

1. Entre no Business como admin global.
2. Abra [Agenda Google](https://business.roadrunners.run/administracao/agenda/).
3. Clique em **Reconectar Google**.
4. Escolha exclusivamente `contato@runnerhub.run`.
5. Autorize todas as permissões exibidas, incluindo a leitura do Google Meet.
6. Ao retornar à Agenda, confirme a mensagem de conexão bem-sucedida.
7. Volte ao [dashboard Business](https://business.roadrunners.run/).

Se o Google não devolver um refresh token, remova a autorização anterior em [Conta Google → Conexões com apps de terceiros](https://myaccount.google.com/connections), volte à Agenda e conecte novamente. Isso não exclui eventos nem a sala.

## 8. Homologar

Faça o teste com pelo menos duas contas:

1. Com a sala vazia, abra o dashboard como admin global. O card deve mostrar **Sala vazia** e os botões de entrada devem funcionar.
2. Entre na sala com uma conta da equipe.
3. Aguarde até 20 segundos ou clique no botão de atualizar do card.
4. Confirme **Sala ativa**, a quantidade e o nome do participante.
5. Entre com uma segunda conta e repita a atualização.
6. Saia com uma das contas e confirme que ela desaparece após a atualização seguinte.
7. Teste **Entrar na sala** no card e no mini status; ambos devem reutilizar a mesma janela dedicada.
8. Se o navegador bloquear a janela, permita pop-ups para `business.roadrunners.run`.
9. Abra `/administracao/meet/status.cfm` autenticado como admin e confirme que a resposta é JSON. Em uma sessão não administrativa, o endpoint deve responder com acesso restrito.

Participantes por telefone, anônimos, em Companion mode ou dispositivos de sala podem aparecer na contagem, conforme a definição da [API de participantes](https://developers.google.com/workspace/meet/api/guides/participants).

Antes da homologação manual, execute o teste de contrato do navegador e dos arquivos:

```bash
node --test _codex/tests/google-meet-room.test.js
```

O runner CFML existente também compila o novo serviço e testa a normalização da sala e dos participantes. As dependências e o comando estão documentados em [`google-agenda.md`](google-agenda.md#verificação-reproduzível).

## Diagnóstico

### Configuração pendente

- `RR_GOOGLE_MEET_ROOM` não chegou ao processo ColdFusion;
- a aplicação não foi reiniciada;
- o link não corresponde ao formato `https://meet.google.com/abc-defg-hij`.

### Google desconectado

- o schema da Agenda ainda não foi aplicado; ou
- não existe refresh token em `tb_google_agenda_conexao`.

Abra `/administracao/agenda/` e conecte a conta.

### Google não autorizou a leitura

- a Meet REST API não foi habilitada no mesmo projeto do Client ID;
- o OAuth ainda usa o refresh token antigo;
- o escopo foi bloqueado pelo Admin Console;
- `contato@runnerhub.run` não é proprietário da sala.

Reconecte a conta depois de revisar os passos 1–3.

### Sala não encontrada

- confira se o código pertence à sala atual;
- abra o link manualmente como `contato@runnerhub.run`;
- confirme a propriedade/organização da sala;
- lembre que códigos de reunião podem ser dissociados ou reutilizados; o Google recomenda que eles não sejam tratados como identificadores permanentes. Consulte [`spaces.get`](https://developers.google.com/workspace/meet/api/reference/rest/v2/spaces/get).

## Privacidade e uso

O card mostra somente o estado atual. Não grava horários de entrada/saída, duração, ranking, ponto ou indicador individual. O Google declara que dados da API do Meet não devem ser coletados para avaliação de desempenho dos usuários: [Meet REST API overview](https://developers.google.com/workspace/meet/api/guides/overview#use-cases).

Se futuramente houver necessidade legítima de histórico ou eventos instantâneos, faça uma revisão separada de finalidade, transparência e retenção antes de implementar Google Workspace Events API e Pub/Sub.
