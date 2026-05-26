# Guia de Edição

## Antes de editar

1. identificar o modulo pela rota
2. abrir o `index.cfm` correspondente
3. localizar o backend incluido
4. entender se a tela usa:
   - query fixa
   - reflection de schema
   - `URL.acao`
   - `FORM.action`

## Regras praticas deste projeto

### 1. Preserve `VARIABLES.template`

Ele controla destaque no menu lateral. Ao criar modulo novo, sempre registrar a rota no `sidenav`.

### 2. Nao assuma schema fixo sem conferir

Algumas telas leem `information_schema.columns` e se adaptam dinamicamente.

### 3. Cuidado com vazamento de variaveis CFML

Varios arquivos misturam `cfoutput`, loops e interpolacao. Ao editar:

- confira se `#...#` esta dentro de contexto valido
- evite `cfoutput` aninhado sem necessidade

### 4. Preserve fluxo de permissao

Muitas acoes administrativas dependem de:

- `qPerfil.recordcount`
- `qPerfil.is_admin`

Nao simplifique isso sem revisar o impacto.

### 5. Em modulos de tabela, validar mobile

Varios modulos sofrem com:

- quebra de colunas
- filtros ruins no mobile
- largura minima excessiva

### 6. Validar acoes por query string

Padrao recorrente:

- `?acao=...`
- `?status=...`
- `?pagina=...`

Ao criar ou alterar botoes, valide os redirects apos a acao.

## Ao criar modulos novos

Checklist minimo:

1. criar pasta do modulo
2. criar `index.cfm`
3. criar `home.cfm`
4. criar backend especifico se necessario
5. registrar item no menu
6. definir `VARIABLES.template`
7. garantir check de permissao

## Ao tocar em integracoes

- nao trocar credenciais no codigo sem mapear todos os pontos de uso
- documentar novos campos de banco em SQL auxiliar
- deixar a UI tolerante quando coluna ainda nao existir

## Ao tocar em APIs de leaderboard

- preservar formato de retorno esperado
- lembrar que varios endpoints retornam XML, nao JSON
- evitar mudancas silenciosas em nomes de tags de retorno
