# Checklist para Novas Features

## Descoberta

- qual modulo existente mais se parece com a feature nova
- qual tabela ou schema sera usado
- a feature e admin-only ou partner-facing

## Estrutura

- criar rota / pasta
- definir `VARIABLES.template`
- incluir `backend_login.cfm` se area protegida
- registrar no menu lateral

## Banco

- se houver campo novo, criar SQL auxiliar
- se o schema pode variar, tratar ausencia de coluna com degradacao graciosa

## UI

- seguir shell visual atual do modulo
- validar desktop e mobile
- evitar tabelas impossiveis de usar no celular

## Backend

- proteger acoes por permissao
- usar `cfqueryparam`
- revisar redirects apos salvar / excluir / toggle

## Integracao

- documentar dependencia externa
- documentar token, credencial ou endpoint necessario
- nao assumir que rede / SMTP / API externa sempre responde

## Entrega

- registrar documentacao em `/docs` se o impacto for estrutural
- atualizar `/_codex` se mudar padrao, dominio ou integracao
