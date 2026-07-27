# API de percursos do Business

API somente leitura para projetos internos consultarem os eventos que possuem
percursos publicados no repositório do Business.

## Autenticação

Configure no servidor uma das opções:

- variável de ambiente `BUSINESS_PERCURSOS_API_KEY`;
- propriedade `apiKey` em `config/percursos.local.cfm`.

A URL usada nos links absolutos pode ser definida por `apiBaseUrl` no mesmo
arquivo ou por `BUSINESS_PERCURSOS_API_BASE_URL`.

Envie a credencial em todas as requisições:

```http
Authorization: Bearer SUA_CHAVE
```

Também é aceito `X-API-Key: SUA_CHAVE`. Não coloque a chave em query string.

Para uso direto por navegador, configure as origens autorizadas em
`apiAllowedOrigins` ou na variável
`BUSINESS_PERCURSOS_API_ALLOWED_ORIGINS` (lista separada por vírgulas).
Integrações servidor-a-servidor não precisam configurar CORS.

## Listar e pesquisar eventos

```http
GET /api/percursos/?q=maratona&estado=SP&pagina=1&por_pagina=20
```

Parâmetros opcionais:

- `q`: nome/tag do evento, cidade ou nome do percurso;
- `estado`: UF;
- `data_inicio` e `data_fim`: intervalo `AAAA-MM-DD`;
- `pagina`: começa em 1;
- `por_pagina`: de 1 a 100.

Cada evento traz seus percursos disponíveis e o `idEventoPercurso`, identificador
que representa a modalidade exata do evento.

## Consultar um evento

```http
GET /api/percursos/evento.cfm?id_evento=123
```

Retorna os metadados e todos os percursos publicados do evento. Cada percurso
inclui a versão ativa, métricas, altimetria, `bbox` e `geometriaUrl`.

## Obter a geometria selecionada

Use a `geometriaUrl` devolvida pela listagem ou pelo detalhe:

```http
GET /api/percursos/geometria.cfm?id_evento_percurso=456&arquivo=789&rev=0a1b2c3d4e5f
```

A resposta é um GeoJSON `Feature` com `LineString` ou `MultiLineString`.
A URL não contém caminhos ou chaves do storage. Se uma nova versão passar a ser
a ativa, a URL antiga deixa de ser aceita.

## Regras de exposição

- somente percursos com status `publicado`;
- somente vínculos com a modalidade exata (`id_evento_percurso`);
- somente a versão ativa mais recente;
- rascunhos, arquivados e chaves internas de storage nunca são retornados.
