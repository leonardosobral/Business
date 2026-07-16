# Gerenciador de usuários

## Objetivo

O módulo `/administracao/usuarios/` centraliza a gestão operacional de contas da plataforma para usuários `ADMIN` e `DEV`.

Ele permite:

- buscar contas por nome, e-mail, username ou ID;
- criar uma conta manual com e-mail real ou temporário;
- editar dados cadastrais, contato, localização e flags da plataforma;
- criar e editar todas as páginas vinculadas à conta;
- ativar, desativar, excluir logicamente e restaurar contas e páginas;
- consultar e editar agendas no gerenciador específico;
- vincular e desvincular resultados sem apagar o resultado esportivo;
- adicionar, aprovar e remover vínculos de seguidores/seguindo;
- consultar a auditoria administrativa;
- abrir o ambiente DEV como o usuário pelo handoff autenticado já existente.

Tokens, senhas e credenciais de integrações não são carregados ou exibidos na ficha.

## Autorização

- `ADMIN` e `DEV`: acesso operacional integral, inclusive alteração de `ADMIN`, `DEV` e `PARTNER`.
- durante a simulação de uma conta, o item é ocultado e o acesso direto à gestão global de usuários retorna `403`;
- o próprio usuário logado não pode desativar ou excluir sua conta;
- o gestor não pode remover simultaneamente de si mesmo as flags `ADMIN` e `DEV`;
- toda mutação usa `POST`, token CSRF e registro de auditoria.

## Exclusão lógica

Uma conta da plataforma possui resultados, inscrições, agendas, notificações e outros relacionamentos históricos. Por isso, “Excluir” não executa `DELETE FROM tb_usuarios`.

A exclusão administrativa:

- marca a conta como inativa e excluída em `tb_usuarios_gestao`;
- marca as páginas vinculadas como inativas e excluídas em `tb_paginas_gestao`;
- bloqueia autenticação e handoff no Road Runners;
- preserva dados esportivos e vínculos para auditoria;
- pode ser restaurada por um operador autorizado.

## Banco de dados

Antes de liberar as ações do módulo, aplique:

```text
administracao/usuarios/user_management_schema.sql
```

O script cria:

- `tb_usuarios_gestao`;
- `tb_paginas_gestao`;
- `tb_usuarios_gestao_auditoria`;
- índices e permissões necessárias para o usuário `runner`.

As tabelas usam estado separado para não confundir:

- conta ativa com `is_email_verified`;
- página ativa com `perfil_publico`;
- exclusão administrativa com exclusão física de dados históricos.

## Integração com o Road Runners

O Road Runners consulta os estados administrativos com fallback seguro quando o schema ainda não foi aplicado.

Foram integrados:

- carregamento da sessão principal em `Application.cfc`;
- busca por ID/e-mail usada no handoff entre ambientes;
- login pelo Google;
- carregamento do perfil público.

Uma sessão já aberta deixa de ser reconhecida quando a conta é desativada. Uma página inativa também deixa de resolver sua rota pública.

## Logar como no DEV

O botão envia um `POST` protegido por CSRF ao próprio Business. O backend reconfirma o gestor e a conta escolhida, registra a ação na auditoria e cria um token HMAC de 180 segundos compatível com o contrato existente do Road Runners:

```text
https://dev.roadrunners.run/?action=handoff_consume&token={TOKEN_ASSINADO}
```

Não é necessário manter outra sessão aberta no Road Runners de produção. O segredo HMAC vem de `APPLICATION.notificationDispatch.secret`, carregado por `RR_HANDOFF_SECRET` ou `notificationDispatchSecret`, e precisa ser o mesmo configurado no Road Runners. O ambiente DEV valida o operador original como `ADMIN` ou `DEV`, exige conta e página ativas, preserva o usuário original em `SESSION.devAuth` e permite retornar pelo fluxo existente.

## Ordem de implantação

1. Aplicar `administracao/usuarios/user_management_schema.sql` no banco compartilhado.
2. Publicar os arquivos do Business.
3. Publicar as alterações do Road Runners.
4. Testar com uma conta comum de homologação.
5. Validar desativação, restauração, página pública e handoff para DEV.

Em bancos que já receberam o schema antes da otimização da consulta de resultados, execute uma vez `administracao/usuarios/user_management_performance_indexes.sql`. O arquivo usa `CREATE INDEX CONCURRENTLY` e deve ser executado fora de uma transação explícita.

## Testes essenciais

- Admin cria conta com e sem e-mail informado.
- DEV cria e edita uma conta comum.
- DEV não altera uma conta Admin/Dev.
- Admin não desativa ou exclui a própria conta.
- conta desativada perde acesso ao Road Runners e ao Business.
- conta restaurada volta a autenticar quando possui página ativa.
- página desativada retorna 404 na rota pública.
- resultado pode ser vinculado e desvinculado sem ser apagado.
- vínculo social pendente pode ser aprovado ou removido.
- todas as ações aparecem na aba Auditoria.
