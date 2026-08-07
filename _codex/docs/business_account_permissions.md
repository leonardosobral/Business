# Permissões de conta Business

## Objetivo

Permitir que empresas de integração usem módulos operacionais sem receber
`is_admin`, `is_partner`, eventos próprios ou exceções por nome/ID no código.

## Modelo

- `tb_business_permissoes`: catálogo de capacidades funcionais;
- `tb_conta_permissoes`: concessão da capacidade a um papel da conta;
- `tb_conta_integracoes_resultados`: escopo de submissões pertencentes à conta;
- `tb_conta_usuarios`: continua definindo os papéis `OWNER`, `ADMIN`, `OPERADOR`
  e `VISUALIZADOR`.

As capacidades iniciais são:

- `result_imports.view`;
- `result_imports.process`.

Processar implica visualizar para o mesmo papel. A tela de contas aplica essa
regra ao salvar. `OWNER` herda as capacidades concedidas a `ADMIN`, além de
eventuais concessões diretas ao próprio papel.

## Autorização

O include `includes/backend/business_permissions.cfm` carrega as capacidades do
papel na conta ativa. Páginas protegidas declaram uma capacidade e incluem
`require_business_permission.cfm`.

Para importações de resultados, a capacidade libera o menu e a página. Toda
consulta ou mutação de um usuário de conta continua limitada por uma integração
ativa compatível com:

```text
client_id + cod_timer + external_account_id
```

Uma integração pode abranger todas as contas externas do mesmo cliente. Esse é
o escopo indicado para a conta Business do próprio provedor. Uma conta de um
cliente final deve usar um `external_account_id` específico.

O banco impede dois escopos globais ativos para o mesmo cliente/timer e também
impede que o mesmo `external_account_id` ativo pertença a duas contas. Um escopo
global do provedor pode coexistir com escopos específicos de seus clientes.

Administradores internos têm bypass global. Ao simular uma conta, o bypass é
desativado e as permissões reais daquela conta são utilizadas.

Sem integração ativa, o usuário autorizado pode abrir a fila, mas não recebe
nenhum resultado e não consegue reservar uma submissão para processamento.

## Gestão

A aba **Acessos** em `/administracao/contas/` permite:

1. selecionar capacidades por papel;
2. cadastrar `client_id`, `cod_timer` e escopo externo;
3. remover integrações existentes.

Convites e aprovações de contas não promovem mais usuários automaticamente para
`is_partner`; o vínculo ativo em `tb_conta_usuarios` já autoriza o login no
Business.

## Deploy

Aplicar primeiro:

```text
_codex/sql/2026-08-06_tb_conta_permissoes_integracoes_resultados.sql
```

Depois publicar o código do Business. Enquanto a migração não existir, usuários
de conta recebem acesso negado e a aba de contas informa a pendência; o acesso
global dos administradores internos continua disponível.
