# Percursos de eventos no Road Runners com Mapbox

## Status do documento

- Tipo: especificação técnica para implementação
- Projetos envolvidos: `Business` e `RoadRunners`
- Data da análise: 24/07/2026
- Fonte: leitura estática do código atual; consultas e storage não foram executados

## Objetivo

Exibir, nas páginas públicas dos eventos no Road Runners, o arquivo de percurso que foi vinculado no Business a uma modalidade específica do evento.

A visualização nova deve usar Mapbox GL JS e substituir progressivamente o embed legado do Strava, oferecendo:

- mapa vetorial interativo;
- traçado com identidade visual do RR;
- largada e chegada;
- marcadores de quilometragem;
- alternância entre mapa e satélite;
- enquadramento automático do percurso;
- tela cheia;
- terreno 3D quando fizer sentido;
- resumo de distância e altimetria;
- perfil de elevação sincronizável com o mapa;
- funcionamento responsivo e acessível.

## Fora do escopo inicial

- edição do percurso no RR;
- navegação curva a curva;
- envio do arquivo original ao navegador;
- download público do original;
- upload de arquivos para o Mapbox Studio;
- substituição imediata de todos os mapas Strava;
- publicação de percursos sem vínculo com uma modalidade do evento.

## Estado atual

### Business

O Business já possui:

- `tb_percursos`: entidade do percurso, pertencente a uma conta;
- `tb_percurso_arquivos`: versões e metadados dos arquivos;
- `tb_evento_percursos_gpx`: vínculo entre o percurso do repositório e o percurso/modalidade do evento;
- `tb_evento_corridas_percursos.id_evento_percurso`: identificador da modalidade exata;
- índice único parcial que limita cada `id_evento_percurso` a um único percurso do repositório;
- storage privado contendo:

```text
{storage}/
  {id_percurso}/
    {versao}/
      original.{gpx|kml|kmz|geojson|fit}
      route.geojson
      optimized.gpx
```

O endpoint `percursos/geometry.cfm` é administrativo, exige autenticação do Business e não deve ser consumido pela página pública do RR.

### Road Runners

A consulta principal da página está em:

```text
includes/backend/backend_evento.cfm
```

O JSON `qEvento.lista_percursos` contém atualmente:

- distância;
- unidade;
- tipo de corrida;
- badges da modalidade.

Ele ainda não contém `id_evento_percurso` nem informações do percurso vinculado.

A visualização ativa está no bloco **DISTANCIAS** de:

```text
evento/index.cfm
```

Nesse bloco, o badge `mapa` cria um embed de rota do Strava. O arquivo `evento/parts/mapa_distancias.cfm` contém uma implementação semelhante, mas não é o ponto ativo identificado na página atual.

## Decisões de arquitetura

### 1. Usar Mapbox GL JS, não iframe

O termo “embed do Mapbox” deve ser implementado como um componente Mapbox GL JS dentro da página. Um iframe limitaria estilos, marcadores, perfil de elevação, troca dinâmica de percurso e integração com as abas existentes.

### 2. Manter o storage privado

O navegador não receberá:

- `storage_key`;
- `geojson_storage_key`;
- caminho absoluto do storage;
- URL do Business autenticado;
- credencial de serviço.

O RR terá um endpoint público same-origin que recebe somente `id_evento_percurso`, o identificador do arquivo vigente e uma revisão derivada do hash.

### 3. Montar o storage no RR como somente leitura

Arquitetura recomendada:

```text
Business ── grava ──> storage persistente de percursos
                           │
                           └── montagem somente leitura ──> RoadRunners

Banco compartilhado ──> Business vincula/publica
                   └──> RR resolve vínculo e autorização pública
```

Configuração sugerida no RR:

```text
RR_PERCURSOS_STORAGE_PATH=/caminho/do/storage/compartilhado
```

O caminho deve apontar para a mesma raiz configurada em `BUSINESS_PERCURSOS_STORAGE_PATH`, mas o processo do RR precisa apenas de leitura.

O fallback atual para `getTempDirectory()` é aceitável somente em desenvolvimento. Produção exige storage persistente, com backup, compartilhado entre os dois ambientes ou acessível por storage de objetos.

Se a infraestrutura não permitir montagem compartilhada, usar uma API interna do Business com autenticação de serviço, consumida apenas pelo backend do RR. O navegador deve continuar acessando uma URL same-origin do RR.

### 4. Gerar uma geometria própria para web

`route.geojson` pode preservar até 1 milhão de pontos. Ele é adequado como representação normalizada de alta fidelidade, mas não como payload de uma página pública.

Cada versão deverá gerar também:

```text
route.web.geojson
```

Regras da derivação:

- preservar o primeiro e o último ponto de cada segmento;
- preservar os pontos escolhidos com a elevação original;
- simplificar separadamente cada segmento;
- usar simplificação adaptativa até atingir no máximo 20 mil pontos no total;
- manter ao menos dois pontos em cada segmento válido;
- limitar longitude e latitude a seis casas decimais;
- limitar elevação a uma casa decimal;
- remover propriedades que não são usadas pela visualização;
- minificar o JSON;
- nunca substituir `route.geojson`;
- executar na criação da versão, não a cada request público.

O limite de 20 mil pontos é um orçamento inicial. Deve ser validado com percursos longos em celulares reais. A documentação oficial do Mapbox recomenda limpar, reduzir precisão, minificar e carregar GeoJSON por URL quando a fonte é grande.

### 5. Uma instância do mapa por página

As abas de distância devem controlar uma única instância do Mapbox:

- ao trocar de aba, atualizar a fonte GeoJSON e os metadados;
- chamar `map.resize()` depois de a área se tornar visível;
- não criar um objeto `Map` para cada distância;
- inicializar o mapa apenas quando o card entrar próximo da viewport.

Isso reduz memória, contextos WebGL e cobranças por map load. No Mapbox GL JS v3, cada instanciação de `Map` conta como um map load.

## Regra de publicação

Um percurso poderá ser entregue publicamente somente quando todas as condições forem verdadeiras:

1. existe `tb_evento_percursos_gpx.id_evento_percurso`;
2. o vínculo aponta para o mesmo evento da página;
3. existe uma versão ativa do arquivo;
4. `tb_percursos.status = 'publicado'`;
5. existe `route.web.geojson` válido para essa versão.

Decisão sobre `visibilidade`:

- `status = 'publicado'` é a aprovação editorial necessária para aparecer no evento;
- o vínculo por `id_evento_percurso` define o escopo público dentro da página do evento;
- `visibilidade` controla a descoberta do percurso fora das páginas de evento;
- portanto, um percurso publicado e vinculado pode aparecer no evento mesmo que sua visibilidade seja `privado` ou `compartilhado`.

Essa separação evita obrigar o operador a tornar o percurso pesquisável em uma futura biblioteca pública apenas para exibi-lo no evento.

Percursos em `rascunho` ou `arquivado` devem se comportar como inexistentes na API pública.

## Alteração de banco necessária

Adicionar os metadados do artefato otimizado para web:

```sql
ALTER TABLE public.tb_percurso_arquivos
    ADD COLUMN IF NOT EXISTS web_geojson_storage_key varchar(512),
    ADD COLUMN IF NOT EXISTS web_quantidade_pontos integer,
    ADD COLUMN IF NOT EXISTS web_tamanho_bytes bigint,
    ADD COLUMN IF NOT EXISTS web_sha256 char(64),
    ADD COLUMN IF NOT EXISTS web_gerado_em timestamp without time zone;

ALTER TABLE public.tb_percurso_arquivos
    ADD CONSTRAINT tb_percurso_arquivos_web_pontos_chk
    CHECK (
        web_quantidade_pontos IS NULL
        OR web_quantidade_pontos >= 2
    );
```

Antes de aplicar a constraint, conferir se ela já existe no ambiente. A migration definitiva deve ser idempotente e registrar a alteração no diretório SQL usado pelo projeto.

### Versão vigente

Enquanto o modelo não tiver um conceito separado de “versão publicada”, considerar vigente:

```sql
WHERE arquivo.ativo = true
ORDER BY arquivo.versao DESC
LIMIT 1
```

Não usar apenas `MAX(versao)` sem filtrar `ativo`.

## Consulta do manifesto no RR

O `json_build_object` de `qEvento.lista_percursos` deve incluir `id_evento_percurso` e um objeto `arquivo_percurso`.

Consulta de referência:

```sql
SELECT json_agg(
    json_build_object(
        'id_evento_percurso', modalidade.id_evento_percurso,
        'percurso', modalidade.percurso_evento,
        'unidade', modalidade.unidade_de_medida,
        'tipo_corrida', modalidade.tipo_corrida,
        'arquivo_percurso',
            CASE
                WHEN percurso.status = 'publicado'
                 AND arquivo.id_percurso_arquivo IS NOT NULL
                 AND arquivo.web_geojson_storage_key IS NOT NULL
                THEN json_build_object(
                    'disponivel', true,
                    'id_percurso', percurso.id_percurso,
                    'id_percurso_arquivo', arquivo.id_percurso_arquivo,
                    'versao', arquivo.versao,
                    'geometria_url',
                        '/api/events/route-geometry.cfm?id_evento_percurso='
                        || modalidade.id_evento_percurso::text
                        || '&arquivo=' || arquivo.id_percurso_arquivo::text
                        || '&rev=' || left(arquivo.web_sha256, 12),
                    'distancia_m', arquivo.distancia_gpx_m,
                    'pontos', arquivo.web_quantidade_pontos,
                    'elevacao_min_m', arquivo.elevacao_min_m,
                    'elevacao_max_m', arquivo.elevacao_max_m,
                    'ganho_elevacao_m', arquivo.ganho_elevacao_m,
                    'bbox',
                        json_build_array(
                            arquivo.bbox_min_lng,
                            arquivo.bbox_min_lat,
                            arquivo.bbox_max_lng,
                            arquivo.bbox_max_lat
                        )
                )
                ELSE NULL
            END,
        'badges', (
            -- manter a subconsulta atual de badges
        )
    )
    ORDER BY modalidade.percurso_evento
)
FROM tb_evento_corridas_percursos modalidade
LEFT JOIN tb_evento_percursos_gpx vinculo
    ON vinculo.id_evento_percurso = modalidade.id_evento_percurso
   AND vinculo.id_evento = modalidade.id_evento
LEFT JOIN tb_percursos percurso
    ON percurso.id_percurso = vinculo.id_percurso
LEFT JOIN LATERAL (
    SELECT arquivo.*
    FROM tb_percurso_arquivos arquivo
    WHERE arquivo.id_percurso = percurso.id_percurso
      AND arquivo.ativo = true
    ORDER BY arquivo.versao DESC
    LIMIT 1
) arquivo ON true
WHERE modalidade.id_evento = evt.id_evento;
```

Observações:

- conservar integralmente os badges atuais para o fallback Strava;
- ordenar as modalidades de forma determinística;
- não incluir chaves de storage no JSON;
- não incluir a geometria no HTML;
- usar `CFQUERYPARAM` no endpoint, mesmo que a consulta da página venha do registro do evento.

## Endpoint público de geometria

### Rota

```http
GET /api/events/route-geometry.cfm?id_evento_percurso={id}&arquivo={id_percurso_arquivo}&rev={hash}
```

### Validação

O endpoint deve:

1. aceitar apenas inteiros positivos em `id_evento_percurso` e `arquivo`, e hexadecimal em `rev`;
2. consultar o vínculo por `id_evento_percurso`;
3. confirmar que `tb_evento_percursos_gpx.id_evento` é igual ao evento da modalidade;
4. confirmar `tb_percursos.status = 'publicado'`;
5. resolver o arquivo ativo mais recente;
6. exigir que `arquivo` seja o arquivo público vigente e que `rev` corresponda ao início de `web_sha256`;
7. montar o caminho somente a partir de `web_geojson_storage_key` vindo do banco;
8. normalizar e validar o caminho contra a raiz configurada;
9. responder somente `Feature` com `LineString` ou `MultiLineString`;
10. nunca aceitar path, filename ou storage key na URL.

### Resposta 200

```json
{
  "type": "Feature",
  "properties": {
    "idEventoPercurso": 123,
    "idPercurso": 456,
    "versao": 2
  },
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [-48.123456, -15.123456, 1012.4],
      [-48.123100, -15.123000, 1014.1]
    ]
  }
}
```

### Headers

```http
Content-Type: application/geo+json; charset=utf-8
X-Content-Type-Options: nosniff
ETag: "{web_sha256}"
Cache-Control: public, max-age=3600, stale-while-revalidate=86400
```

Como a URL contém o ID global do arquivo e uma revisão do hash, é possível evoluir para cache imutável:

```http
Cache-Control: public, max-age=31536000, immutable
```

Isso só deve ser usado se um arquivo nunca for regravado no mesmo caminho. Uma correção precisa criar nova versão. O ID do arquivo evita colisão quando um vínculo é substituído por outro percurso que também esteja na versão 1; `versao` isoladamente não seria uma chave de cache segura.

### Status HTTP

- `400`: parâmetros inválidos;
- `404`: vínculo, percurso publicado, versão ou arquivo não encontrado;
- `304`: ETag ainda válido;
- `422`: GeoJSON armazenado inválido;
- `503`: storage indisponível.

Para o público, não diferenciar “não existe” de “existe, mas não está publicado”.

## Componente visual no RR

Arquivos sugeridos:

```text
evento/parts/mapa_percurso_mapbox.cfm
assets/js/event-route-mapbox.js
assets/css/event-route-mapbox.css
api/events/route-geometry.cfm
```

O bloco em `evento/index.cfm` deve ficar responsável apenas por:

- abas das modalidades;
- container do componente;
- fallback;
- atributos ou JSON de configuração.

A lógica do mapa deve ficar no arquivo JavaScript dedicado.

### Ordem de escolha por modalidade

1. Se `arquivo_percurso.disponivel = true`, renderizar Mapbox.
2. Senão, se existir badge `mapa`, renderizar o embed Strava.
3. Senão, exibir “Percurso ainda não disponível”.

Uma falha de rede ou de WebGL no Mapbox deve tentar o fallback Strava da mesma modalidade. Se não houver fallback, mostrar uma mensagem estática sem quebrar o restante da página.

### Estrutura visual mínima

```text
[ 5 km ] [ 10 km ] [ 21 km ]

┌──────────────────────────────────────┐
│ [Mapa/Satélite] [3D] [Reenquadrar]   │
│                                      │
│             MAPBOX                  │
│                                      │
└──────────────────────────────────────┘

10,02 km · ganho 184 m · 812–927 m
[ perfil de elevação ]
```

### Camadas

Implementar inicialmente:

- `route-casing`: linha externa escura para contraste;
- `route-line`: linha principal com cor da marca;
- `route-start`: marcador verde;
- `route-finish`: marcador vermelho;
- `route-km`: marcadores discretos a cada quilômetro.

Configuração conceitual:

```javascript
map.addSource("event-route", {
  type: "geojson",
  data: geometryUrl,
  lineMetrics: true
});

map.addLayer({
  id: "route-casing",
  type: "line",
  source: "event-route",
  layout: {
    "line-cap": "round",
    "line-join": "round"
  },
  paint: {
    "line-color": "#ffffff",
    "line-width": 8,
    "line-opacity": 0.9
  }
});

map.addLayer({
  id: "route-line",
  type: "line",
  source: "event-route",
  layout: {
    "line-cap": "round",
    "line-join": "round"
  },
  paint: {
    "line-color": "#e53935",
    "line-width": 5
  }
});
```

Com Mapbox Standard, avaliar um `slot` que mantenha o percurso acima do terreno e abaixo dos rótulos importantes.

### Enquadramento

Usar o `bbox` do manifesto:

```javascript
map.fitBounds(
  [
    [bbox[0], bbox[1]],
    [bbox[2], bbox[3]]
  ],
  {
    padding: { top: 48, right: 48, bottom: 48, left: 48 },
    duration: 0
  }
);
```

Em telas pequenas, aumentar o padding inferior se o resumo ficar sobreposto ao mapa.

### Perfil de elevação

O eixo horizontal representa distância acumulada e o vertical, elevação:

- considerar apenas coordenadas com terceiro valor numérico;
- ocultar o perfil quando não houver elevação suficiente;
- limitar a série desenhada a no máximo 2 mil amostras;
- ao mover o ponteiro no gráfico, destacar a posição correspondente no mapa;
- fornecer resumo textual para usuários que não usam o gráfico.

O perfil não deve inferir altimetria do terreno Mapbox quando o arquivo não a possui. A informação exibida deve vir do arquivo aprovado no Business.

### Acessibilidade

- título que identifique evento e distância;
- controles com `aria-label`;
- operação por teclado;
- foco visível;
- resumo textual de distância e elevação;
- cores com contraste suficiente;
- não depender somente de verde/vermelho para diferenciar largada e chegada;
- respeitar `prefers-reduced-motion`;
- desativar animações automáticas quando essa preferência estiver ativa.
- manter logo e atribuição exigidos pelo Mapbox visíveis e sem sobreposição.

## Configuração do Mapbox

### Biblioteca

Usar Mapbox GL JS v3 e fixar uma versão testada. Não usar URL `latest`.

Na data desta documentação, a documentação oficial apresenta a versão 3.25.0. A versão efetivamente adotada deve ser centralizada nos assets do RR e atualizada de forma controlada.

### Token

Usar somente token público `pk.*`:

- criado especificamente para o Road Runners;
- apenas com escopos de leitura necessários;
- restrito às URLs de produção e desenvolvimento;
- nunca usar token secreto `sk.*` no navegador;
- nunca versionar um token secreto.

Variável de configuração sugerida:

```text
RR_MAPBOX_PUBLIC_TOKEN
```

O token público pode ser inserido no HTML de configuração do componente. A segurança vem de escopos mínimos e restrições de URL.

### Content Security Policy

Se o RR aplicar CSP, incluir os destinos exigidos pelo Mapbox GL JS:

```text
worker-src blob:;
img-src data: blob:;
connect-src https://api.mapbox.com https://events.mapbox.com;
```

Mapbox Standard e recursos 3D podem exigir:

```text
script-src 'wasm-unsafe-eval';
```

Se `blob:` não for aceitável em `worker-src`, usar o bundle CSP específico do Mapbox e servir o worker pela mesma origem, conforme a documentação oficial.

Caso os arquivos JS e CSS venham do CDN do Mapbox, ajustar também `script-src` e `style-src`. A preferência para produção é integrar a biblioteca aos assets versionados do RR.

### Estilo

Primeira versão:

- mapa: `mapbox://styles/mapbox/standard`;
- satélite: `mapbox://styles/mapbox/standard-satellite`;
- terreno 3D opcional com `raster-dem`;
- exagero de terreno inicial entre `1.0` e `1.3`, evitando distorcer a percepção do percurso.

Ao trocar o estilo, as fontes e camadas customizadas precisam ser recriadas após `style.load`, ou configuradas para persistir.

## Performance

Metas iniciais em rede móvel intermediária:

- `route.web.geojson` preferencialmente abaixo de 1 MB comprimido;
- no máximo 20 mil pontos;
- primeira pintura do card sem esperar a geometria;
- mapa carregado apenas quando próximo da viewport;
- uma instância de `Map` por página;
- geometria servida por URL, não serializada no HTML;
- compressão Brotli ou gzip no servidor;
- suporte a ETag;
- sem recriar mapa ao alternar distância;
- sem carregar terreno 3D antes de o usuário solicitar, em dispositivos móveis.

Se os arquivos continuarem grandes mesmo simplificados, a evolução indicada é gerar tiles vetoriais. Não começar com Mapbox Tiling Service: uma rota por modalidade cabe no modelo GeoJSON otimizado e permanece sob controle do RR.

## Observabilidade

Registrar no servidor:

- `id_evento_percurso`;
- arquivo e versão resolvidos;
- status HTTP;
- tempo de leitura;
- tamanho entregue;
- ETag;
- erro de storage ou validação;
- nunca registrar o conteúdo integral da geometria.

Eventos de frontend sugeridos:

- `event_route_map_view`;
- `event_route_distance_change`;
- `event_route_style_change`;
- `event_route_3d_enable`;
- `event_route_fallback_strava`;
- `event_route_load_error`.

Não enviar coordenadas completas para analytics.

## Plano de implementação

### Fase 1 — artefato web no Business

1. Criar a migration dos campos `web_*`.
2. Implementar simplificação no `PercursoGpxService`.
3. Gerar `route.web.geojson` para novos uploads e novas versões.
4. Criar backfill administrativo para versões já existentes.
5. Exibir no Business o estado “geometria web pronta”.
6. Bloquear a publicação, ou sinalizar claramente, quando o artefato web falhar.

### Fase 2 — leitura pública no RR

1. Montar o storage como somente leitura.
2. Configurar `RR_PERCURSOS_STORAGE_PATH`.
3. Criar `/api/events/route-geometry.cfm`.
4. Implementar ETag, cache e respostas de erro.
5. Adicionar testes de path traversal e regras de publicação.

### Fase 3 — manifesto da página

1. Alterar `includes/backend/backend_evento.cfm`.
2. Incluir `id_evento_percurso` em toda modalidade.
3. Incluir somente metadados públicos do arquivo vigente.
4. Preservar badges e mapa Strava.
5. Ordenar as modalidades.

### Fase 4 — componente Mapbox

1. Adicionar assets e configuração do token.
2. Criar o componente com uma instância de mapa.
3. Integrar ao bloco de distâncias em `evento/index.cfm`.
4. Implementar linha, largada, chegada, km e enquadramento.
5. Adicionar resumo e perfil de elevação.
6. Adicionar mapa/satélite, tela cheia e 3D sob demanda.
7. Implementar fallback Strava.

### Fase 5 — rollout

1. Liberar por feature flag.
2. Habilitar inicialmente apenas para ADMINs.
3. Validar um evento de rua, um trail e um percurso MultiLineString.
4. Habilitar para uma pequena lista de eventos.
5. Acompanhar erros, payload e map loads.
6. Expandir gradualmente.
7. Remover o fallback Strava somente após auditoria completa.

Feature flag sugerida:

```text
RR_EVENT_ROUTE_MAPBOX_ENABLED
```

## Matriz de comportamento

| Arquivo vinculado | Status | Artefato web | Badge Strava | Resultado |
|---|---|---:|---:|---|
| sim | publicado | sim | qualquer | Mapbox |
| sim | publicado | não | sim | Strava |
| sim | publicado | não | não | indisponível |
| sim | rascunho | qualquer | sim | Strava |
| sim | rascunho | qualquer | não | indisponível |
| sim | arquivado | qualquer | sim | Strava |
| não | — | — | sim | Strava |
| não | — | — | não | indisponível |

## Testes obrigatórios

### Business

- importar GPX, KML, KMZ, GeoJSON e FIT;
- gerar `route.geojson` e `route.web.geojson`;
- confirmar que o original e a geometria completa não mudaram;
- confirmar limite de pontos da versão web;
- preservar segmentos, largada, chegada e elevação;
- gerar nova versão sem sobrescrever a anterior;
- backfill idempotente.

### Endpoint RR

- rejeitar ID textual, negativo, zero e decimal;
- retornar somente percurso publicado;
- rejeitar vínculo inconsistente entre evento e modalidade;
- rejeitar arquivo antigo ou que não seja mais o vigente;
- impedir `../` e qualquer path recebido do cliente;
- responder `304` com `If-None-Match`;
- responder `404` sem revelar estado editorial;
- responder GeoJSON válido para LineString e MultiLineString;
- continuar funcionando sem sessão.

### Interface

- alternar entre duas ou mais distâncias sem criar outro `Map`;
- reenquadrar corretamente;
- chamar `resize()` depois da troca de aba;
- funcionar em 320 px de largura;
- suportar teclado;
- respeitar redução de movimento;
- ocultar perfil sem elevação;
- cair para Strava quando o endpoint falhar;
- não carregar o script Strava quando todas as modalidades usam Mapbox;
- não quebrar a página quando WebGL estiver indisponível.

## Critérios de aceite

A entrega estará pronta quando:

1. um percurso publicado e vinculado no Business aparecer na modalidade correta do evento no RR;
2. substituir o vínculo no Business trocar o percurso mostrado sem alterar o código do RR;
3. rascunhos e arquivados nunca forem expostos pela API pública;
4. o navegador não receber chaves ou caminhos do storage;
5. a página usar no máximo uma instância Mapbox;
6. a geometria pública for derivada e limitada, nunca o arquivo de até 1 milhão de pontos;
7. largada, chegada, distância, elevação e bounds forem coerentes;
8. o fallback Strava continuar funcionando durante o rollout;
9. erros do mapa não impedirem o restante da página de carregar;
10. a atribuição do Mapbox permanecer visível;
11. token, CSP, cache e analytics seguirem as regras deste documento.

## Arquivos que deverão ser alterados

### Business

```text
percursos/percursos_schema.sql
percursos/includes/PercursoGpxService.cfc
percursos/includes/backend.cfm
percursos/home.cfm
_codex/sql/{migration_web_geometry}.sql
```

### Road Runners

```text
includes/backend/backend_evento.cfm
evento/index.cfm
evento/parts/mapa_percurso_mapbox.cfm
api/events/route-geometry.cfm
assets/js/event-route-mapbox.js
assets/css/event-route-mapbox.css
Application.cfc ou configuração equivalente
```

## Referências oficiais

- [Mapbox GL JS — Getting Started](https://docs.mapbox.com/mapbox-gl-js/guides/get-started/)
- [Mapbox GL JS — sources e layers](https://docs.mapbox.com/mapbox-gl-js/guides/styles/work-with-layers/)
- [Mapbox GL JS — fitBounds](https://docs.mapbox.com/mapbox-gl-js/example/fitbounds/)
- [Mapbox GL JS — terreno 3D](https://docs.mapbox.com/mapbox-gl-js/example/add-terrain/)
- [Mapbox GL JS — segurança e CSP](https://docs.mapbox.com/mapbox-gl-js/guides/security-and-testing/)
- [Mapbox — access tokens](https://docs.mapbox.com/help/dive-deeper/access-tokens/)
- [Mapbox — fontes GeoJSON grandes](https://docs.mapbox.com/help/troubleshooting/working-with-large-geojson-data/)
- [Mapbox GL JS — pricing e map loads](https://docs.mapbox.com/mapbox-gl-js/guides/pricing/)
