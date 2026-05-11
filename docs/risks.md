# Riscos e Débitos Técnicos

## Resumo executivo

O projeto funciona e cobre muitos dominios, mas carrega riscos tecnicos importantes que precisam ficar documentados para qualquer evolucao futura.

## Riscos principais

### 1. Segredos hardcoded

Foram encontrados no codigo:

- credenciais SMTP
- chaves e tokens
- client IDs
- links com tokens em query string

Exemplos:

- [Application.cfc](/Users/geraldoprotta/IdeaProjects/Business/Application.cfc)
- [includes/backend/backend_login.cfm](/Users/geraldoprotta/IdeaProjects/Business/includes/backend/backend_login.cfm)
- [crm/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/crm/EmailSenderService.cfc)
- [emailmkt/EmailSenderService.cfc](/Users/geraldoprotta/IdeaProjects/Business/emailmkt/EmailSenderService.cfc)

### 2. Acoplamento alto

Padrao recorrente:

- SQL, regra de negocio e renderizacao na mesma unidade
- dependencias intensas de `COOKIE`, `URL`, `FORM` e `VARIABLES`

Impacto:

- manutencao mais arriscada
- testes mais dificeis
- refactors com maior chance de regressao

### 3. Pouca separacao de permissao

Em varios pontos, a seguranca depende de verificacoes locais por pagina. Isso pode gerar inconsistencias entre modulos.

### 4. Ausencia de testes automatizados

Nao foram encontrados:

- testes unitarios
- smoke tests
- pipeline de validacao automatica

### 5. Reflection dinamica em tabelas

Modulos como Portal e Treinos Config usam `information_schema` para montar telas dinamicamente.

Vantagem:

- flexibilidade

Risco:

- qualquer mudanca de schema afeta comportamento e renderizacao

### 6. Mistura de UI moderna e legado

Ha coexistencia de:

- area logada em MDBootstrap
- landing e modulos antigos com assets `lib/`

Impacto:

- duplicacao de estilo
- experiencias inconsistentes
- manutencao visual mais custosa

## Riscos operacionais

### SMTP

Se o provedor mudar ou bloquear credenciais, CRM e Email Marketing quebram diretamente.

### APIs externas

`cfhttp` para RaceTag, Runking, Google Maps e outros servicos cria dependencia operacional de terceiros.

### Cookies

O modelo de autenticacao depende fortemente de cookies persistidos no browser, o que exige cuidado adicional em seguranca e expiracao.

## Prioridades recomendadas

### Curto prazo

- externalizar segredos
- documentar ambiente
- mapear modulos criticos
- proteger melhor endpoints sensiveis

### Medio prazo

- consolidar auth e autorizacao
- reduzir SQL espalhado em views
- padronizar backend por dominio

### Longo prazo

- criar camada de servicos
- cobrir fluxos criticos com testes
- modularizar dominios mais complexos
