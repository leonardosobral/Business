# Business Docs

Documentacao consolidada do projeto `Business`, escrita a partir de leitura estatica do codigo em `2026-05-11`.

## Objetivo

Este conjunto de documentos serve para:

- onboarding tecnico rapido
- mapeamento de modulos e responsabilidades
- suporte a futuras integracoes
- reducao de risco em manutencoes de um monolito CFML grande

## Indice

- [Arquitetura Geral](/Users/geraldoprotta/IdeaProjects/Business/docs/architecture.md)
- [Mapa de Módulos](/Users/geraldoprotta/IdeaProjects/Business/docs/modules.md)
- [Integrações e Dependências](/Users/geraldoprotta/IdeaProjects/Business/docs/integrations.md)
- [Help Desk](/Users/geraldoprotta/IdeaProjects/Business/docs/helpdesk.md)
- [Operação e Setup](/Users/geraldoprotta/IdeaProjects/Business/docs/operations.md)
- [Banco e Entidades](/Users/geraldoprotta/IdeaProjects/Business/docs/data-model.md)
- [Riscos e Débitos Técnicos](/Users/geraldoprotta/IdeaProjects/Business/docs/risks.md)

## Escopo desta analise

- Repositorio analisado: `/Users/geraldoprotta/IdeaProjects/Business`
- Base principal identificada: PostgreSQL via datasource `runner_dba`
- Framework principal: Adobe ColdFusion / CFML
- Interface principal: server-side rendering com MDBootstrap

## Observacao importante

Esta documentacao foi criada sem subir a aplicacao localmente e sem validar consultas contra o banco. Onde necessario, os textos indicam quando a conclusao veio de leitura do codigo e nao de execucao real.
