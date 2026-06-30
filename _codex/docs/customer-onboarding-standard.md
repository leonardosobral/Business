# Customer Onboarding Standard

Objetivo: telas da area nao-admin devem mostrar a proxima acao clara antes de mostrar listas vazias ou paineis tecnicos.

## Estados principais

1. Sem evento vinculado: guiar para `/eventos/#primeiro-evento`.
2. Solicitacao pendente: mostrar acompanhamento e evitar CTAs que parecam liberados.
3. Evento aprovado incompleto: guiar para editar o primeiro evento com campos pendentes.
4. Evento pronto: liberar marketing, cupons e inscricoes como operacao continua.
5. Dados ainda nao integrados: explicar o estado e oferecer suporte.

## Componentes compartilhados

- `business-step-grid`: grade de passos de ativacao.
- `business-step`: card de passo.
- `business-step.is-current`: proxima acao.
- `business-step.is-complete`: etapa concluida.
- `business-step.is-muted`: etapa bloqueada ou futura.
- `business-empty-state`: estado vazio com explicacao e CTA.
- `business-mini-metric`: metrica compacta de contexto.

## Telas migradas

- Home da conta: checklist de ativacao da operacao.
- `/administracao/contas/`: painel compacto de conta para cliente final, focado em equipe/usuarios; eventos aparecem como contexto e CTA para `/eventos/`, enquanto a aba de eventos fica restrita ao admin. No admin, lista de contas e detalhe ficam lado a lado quando houver espaco, e a busca de eventos permite vinculo em lote.
- `/assinaturas/`: plano atual, recursos incluidos e caminho de atendimento comercial sem valores ficticios.
- `/eventos/`: guia pos-vinculo para completar publicacao e operar a prova; estado sem evento mostra apenas um caminho inicial, o pedido de novo vinculo fica colapsado quando nao e a acao principal, e listas grandes ficam limitadas/rolaveis por padrao tambem no admin.
- `/inscricoes/`: estados vazios para sem evento e sem dados integrados.
