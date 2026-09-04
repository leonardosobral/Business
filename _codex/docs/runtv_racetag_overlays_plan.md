# Planejamento RunTV — overlays RaceTag para OBS e vMix

## Objetivo

Criar uma família de páginas HTML transparentes para uso como Browser Source no OBS ou entrada Web Browser no vMix. As páginas devem apresentar rankings em tempo quase real com linguagem visual inspirada em transmissões automobilísticas: torre de classificação, posição destacada, tempo do líder, gaps, identificação clara da distância e da parcial e animações discretas de mudança de posição.

O primeiro pacote cobrirá a Maratona de Floripa 2025, mas a arquitetura deve aceitar outros eventos e provedores sem reescrever os overlays.

O catálogo técnico da fonte inicial está em [`racetag_floripa_2025_sources.json`](racetag_floripa_2025_sources.json).

## Decisões iniciais

- resolução de projeto: `1920 × 1080`, com escala responsiva para `1280 × 720`;
- fundo do documento totalmente transparente;
- componentes visuais podem ter preenchimentos sólidos ou semitransparentes, mas nenhuma camada ocupará todo o frame;
- overlays implementados em HTML, CSS e JavaScript nativos, sem dependência de Bootstrap ou CDN;
- backend e cache em CFML, seguindo a stack atual do Business;
- atualização por polling leve no MVP; SSE/WebSocket fica como evolução, não como dependência de lançamento;
- cada tela será controlada por parâmetros de URL e também gerada por um painel operacional;
- masculino e feminino aparecem juntos por padrão, com opção de gerar uma URL para apenas um sexo;
- dados `ct` e `tl` da RaceTag não serão expostos à camada de apresentação.

## Escopo das telas

### 1. Classificação parcial da elite

Uma tela compacta por distância/parcial, com dois painéis:

- Elite Masculina: dois primeiros;
- Elite Feminina: duas primeiras.

Campos exibidos:

- posição;
- número de peito;
- nome;
- tempo acumulado na parcial;
- gap para o líder do mesmo sexo;
- distância e nome do checkpoint.

O layout padrão será uma torre dupla M/F. Uma variante `sex=M` ou `sex=F` permitirá usar somente uma torre.

### 2. Resultado final da elite

Uma tela por distância com:

- dez primeiros masculinos;
- dez primeiras femininas.

Campos exibidos:

- posição;
- número de peito;
- nome;
- tempo líquido, com fallback para bruto;
- gap para o vencedor do mesmo sexo.

O resultado final terá variante combinada M/F e variante de sexo único. O estado visual usará elemento de chegada/bandeira quadriculada, mas manterá a mesma identidade da parcial.

### 3. Painel operacional

Tela autenticada para a equipe de transmissão:

- selecionar evento e provedor;
- escolher distância, parcial, tipo de tela e sexo;
- visualizar uma prévia sobre fundo quadriculado;
- copiar a URL pronta para OBS/vMix;
- escolher tema, escala, alinhamento e margem segura;
- ver horário da última leitura, versão da fonte e estado de atualização;
- forçar atualização e abrir a tela em uma nova aba.

## Matriz inicial de fontes e modalidades

| Distância | Evento RaceTag | Percurso | Parciais | Resultado final |
| --- | --- | --- | --- | --- |
| 42 km | `KNY9FL` | `1F1FF6K` — ELITE 42K | 7,8 km; 11,7 km; 21,097 km; 36 km | Top 10 M + Top 10 F |
| 21 km | `19IWN2A` | `KDENMA` — ELITE 21K | 7,5 km; 11 km; 16 km | Top 10 M + Top 10 F |
| 5 km | `KNY9FL` | `X4MMI6` — CORRIDA 5KM | não há parcial | Top 10 geral M + Top 10 geral F |

Não existe um percurso chamado “ELITE 5K” nessa fonte. O planejamento assume que, para 5 km, “elite” significa os dez melhores da classificação geral de `X4MMI6`, separados por sexo. Essa regra deve ficar configurável por evento.

Os percursos PCD não entram no primeiro pacote de telas, mas o modelo de configuração deverá permitir adicioná-los depois.

## Arquitetura proposta

```text
RaceTag event.json/results.json
              │
              ▼
     Adaptador RaceTag + cache
              │
              ▼
 Motor de normalização e ranking
        │                 │
        ▼                 ▼
 API de snapshots     Monitor operacional
        │
        ▼
 Overlays transparentes HTML
        │
        ▼
      OBS / vMix
```

### Camada 1 — provedores de dados

Definir um contrato interno comum:

```text
resolveEvent(sourceConfig)
loadEventDefinition(eventId)
loadResults(eventId)
normalizeEvent(event, results)
getSourceVersion(responseHeaders, payload)
```

O primeiro adaptador será `RaceTagProvider`. Futuramente o mesmo contrato poderá receber Runking ou uma API interna da RunnerHub.

Regras do adaptador RaceTag:

- aceitar somente hosts previamente permitidos;
- resolver slug em `events.json` quando necessário;
- unir `event.json` e `results.json` pelos IDs compactos;
- tratar `eventChanged.txt`, `resultChanged.txt`, `theme.json` e `team_results.json` como opcionais;
- usar `ETag`/`Last-Modified` para não baixar novamente arquivos de aproximadamente 3 MB sem necessidade;
- preservar o último snapshot válido quando a origem falhar.

### Camada 2 — cache e atualização

O gateway deverá buscar cada evento uma única vez por ciclo, independentemente da quantidade de overlays abertos.

Estratégia inicial:

- verificar marcador de alteração quando ele existir;
- caso o marcador retorne 404, executar `GET` condicional no `results.json`;
- intervalo da fonte configurável, inicialmente 5 a 10 segundos em evento ao vivo;
- cache normalizado em memória da aplicação;
- bloqueio “single flight” por evento para impedir downloads simultâneos;
- manter o último snapshot bom e registrar falhas consecutivas;
- marcar como `stale` após 30 segundos sem atualização bem-sucedida.

Os overlays consultarão somente a API interna, com payload pequeno, a cada 1 ou 2 segundos. A API poderá responder `304 Not Modified` quando o snapshot não mudar.

### Camada 3 — motor de ranking

O motor será uma função pura e testável, independente de HTML e CFML.

Regras comuns:

1. excluir registros com `s` preenchido (`DSQ`, `DNF` etc.);
2. filtrar pelo percurso configurado e pelo sexo;
3. parcial: calcular `checkpoint.t - athlete.st`;
4. chegada: usar `tn` positivo e, na ausência, `tg` positivo;
5. ordenar pelo tempo crescente;
6. recalcular posição; não usar `ck.r`;
7. calcular gap em relação ao primeiro colocado do mesmo sexo;
8. limitar a dois atletas na parcial e dez no resultado final.

Empates devem usar, nesta ordem:

- menor timestamp de passagem/chegada;
- menor número de peito, apenas como desempate técnico estável.

### Camada 4 — API de snapshots

Endpoint sugerido:

```text
GET /runtv/api/snapshot.cfm
    ?event=floripa-2025
    &distance=42
    &view=partial
    &checkpoint=W7VW2U
    &sex=all
```

Contrato resumido:

```json
{
  "meta": {
    "event": "floripa-2025",
    "eventName": "Maratona de Floripa 2025",
    "distanceKm": 42,
    "view": "partial",
    "checkpoint": {"id": "W7VW2U", "name": "PC1", "distanceM": 7800},
    "sourceUpdatedAt": "2025-08-31T08:15:00Z",
    "generatedAt": "2026-08-25T13:15:00-03:00",
    "version": "opaque-snapshot-version",
    "stale": false
  },
  "boards": {
    "M": [
      {"position": 1, "bib": 101, "name": "ATLETA", "time": "00:24:10", "gap": null},
      {"position": 2, "bib": 102, "name": "ATLETA 2", "time": "00:24:18", "gap": "+00:08"}
    ],
    "F": []
  }
}
```

O endpoint não retornará idade, equipe, categoria, campos personalizados nem identificadores de chip.

### Camada 5 — overlays

Uma única página deve renderizar todas as variantes:

```text
/runtv/overlay/
  ?event=floripa-2025
  &distance=42
  &view=partial
  &checkpoint=W7VW2U
  &sex=all
  &layout=tower
  &theme=runtv-dark
  &scale=1
  &anchor=bottom-left
```

Características técnicas:

- `html`, `body` e raiz com `background: transparent`;
- sem imagem ou cor de fundo global;
- largura e altura do frame fixadas pela Browser Source, não pelo componente;
- escala baseada em variáveis CSS;
- fontes e ícones hospedados localmente;
- DOM atualizado por diferença, sem reconstruir toda a tabela;
- entrada, saída e troca de posição com animações de 200–350 ms;
- suporte a `prefers-reduced-motion` e parâmetro `motion=off`;
- nenhum erro técnico aparece no ar.

## Direção visual

### Linguagem automobilística

- torre vertical com posição em bloco estreito;
- destaque forte para P1;
- tempos com fonte tabular/monoespaçada;
- gap em cor secundária;
- cabeçalho como faixa de telemetria: distância, checkpoint e sexo;
- divisores finos e diagonais discretas;
- animação curta quando um atleta assume posição;
- acento de bandeira quadriculada somente no resultado final.

### Composição

- área transparente fora da torre;
- margem segura padrão de 5% do frame;
- posição padrão no canto inferior esquerdo;
- parcial: aproximadamente 560–720 px de largura por torre dupla;
- final: duas torres lado a lado, cada uma com dez linhas compactas;
- nomes com truncamento visual, preservando o nome completo em `title` apenas para depuração;
- logos de evento/patrocinadores opcionais, nunca obrigatórios para renderizar dados.

### Estados de exibição

- `loading`: componente invisível até existir um snapshot válido;
- `ready`: dados normais;
- `empty`: cabeçalho discreto sem linhas, ou tela invisível conforme configuração;
- `stale`: mantém o último resultado no ar; alerta aparece somente no painel do operador;
- `error`: mantém o último resultado válido; nunca imprime stack trace ou mensagem técnica na transmissão.

## Estrutura de arquivos sugerida

```text
runtv/
├── index.cfm                         # painel operacional autenticado
├── overlay/
│   └── index.cfm                     # shell público dos overlays
├── api/
│   ├── snapshot.cfm                  # payload normalizado para o overlay
│   ├── health.cfm                    # estado das fontes para o operador
│   └── refresh.cfm                   # atualização manual autenticada
├── components/
│   ├── RaceDataProvider.cfc          # contrato/base dos provedores
│   ├── RaceTagProvider.cfc           # leitura e normalização RaceTag
│   ├── RunTvCache.cfc                # cache, versão e last-known-good
│   └── RunTvRanking.cfc              # ranking e gaps
├── config/
│   └── events.json                   # mapeamento evento/distância/percurso
├── assets/
│   ├── css/runtv.css
│   ├── js/overlay.js
│   ├── js/operator.js
│   ├── js/ranking-reference.js       # referência JS para testes cruzados
│   ├── fonts/
│   └── images/
└── tests/
    ├── fixtures/
    ├── ranking-tests.mjs
    └── overlay-smoke-tests.mjs
```

O módulo existente `leaderboard/tv` permanece funcionando durante a implementação. A RunTV nasce em rota separada e só substitui os overlays antigos após homologação.

## Segurança e acesso

- painel operacional exige sessão e permissão específica, por exemplo `runtv.manage`;
- overlay não deve depender de cookie de login, pois OBS/vMix precisa abri-lo diretamente;
- URLs de overlay podem usar token de leitura revogável ou slug não sensível;
- backend aceita apenas IDs e provedores cadastrados, nunca uma URL externa arbitrária;
- nomes são inseridos com `textContent`/escaping, não como HTML;
- API pública entrega apenas os campos necessários para transmissão;
- aplicar rate limit leve e cache de resposta.

## Plano de implementação

### Fase 0 — definição visual e operacional

Entregas:

- wireframes da parcial e do resultado final;
- escolha de cores, tipografia, logo e comportamento de animação;
- definição da margem segura e posições usuais no frame;
- confirmação da regra do 5K geral como “elite”.

Critério de saída: direção visual aprovada e matriz de telas fechada.

### Fase 1 — adaptador e cache RaceTag

Entregas:

- configuração dos dois eventos de Floripa;
- leitura de `event.json` e `results.json`;
- cache com ETag/Last-Modified e último snapshot válido;
- health check e logs sem dados pessoais desnecessários.

Critério de saída: uma leitura da origem atende qualquer quantidade de clientes e sobrevive a 404/timeout.

### Fase 2 — motor de ranking e contrato da API

Entregas:

- ranking de parcial e chegada;
- filtro por percurso/sexo;
- gaps e formatação de tempo;
- API de snapshot;
- testes contra fixtures arquivadas de 5, 21 e 42 km.

Critério de saída: top 2 e top 10 reproduzem deterministicamente as regras catalogadas.

### Fase 3 — overlay de parcial

Entregas:

- torre dupla M/F;
- variante de sexo único;
- seleção de checkpoint por URL;
- atualização sem piscar e animação de mudança de posição;
- transparência validada em checkerboard, OBS e vMix.

Critério de saída: todos os checkpoints de 21 e 42 km abrem por URLs independentes.

### Fase 4 — overlay de resultado final

Entregas:

- top 10 M/F para 5, 21 e 42 km;
- variante combinada e por sexo;
- tratamento de listas incompletas durante a chegada;
- bandeira visual de resultado final.

Critério de saída: seis classificações por sexo e três telas combinadas funcionam com a mesma página.

### Fase 5 — painel operacional

Entregas:

- seletor de evento, distância, parcial e tela;
- preview transparente;
- gerador/copiar URL;
- monitor de atualização e stale;
- gestão dos tokens de leitura.

Critério de saída: operador monta a cena sem editar query string manualmente.

### Fase 6 — homologação de transmissão

Entregas:

- teste de duas horas com atualização contínua;
- teste de perda de internet e recuperação;
- teste de nomes longos e campos ausentes;
- validação em 1080p e 720p;
- checklist de configuração para OBS/vMix;
- documentação de contingência e rollback.

Critério de saída: nenhuma tela branca, flash de fundo ou erro técnico aparece no programa.

## Testes obrigatórios

### Dados

- DSQ/DNF nunca entram no ranking;
- ausência de `tn` usa `tg`;
- passagem sem `st` é descartada;
- checkpoint inexistente retorna lista vazia;
- posição é recalculada e ignora `ck.r`;
- top 2/top 10 são respeitados por sexo;
- 5K usa a rota geral configurada;
- empate mantém ordem estável.

### Visual

- alpha real no fundo do frame;
- nenhum retângulo global opaco;
- nomes muito longos não quebram linhas;
- tempos usam dígitos tabulares e não deslocam colunas;
- alterações de posição não fazem a torre piscar;
- componente permanece dentro da safe area;
- renderização consistente no motor Chromium do software de transmissão.

### Resiliência

- origem 404/500/timeout;
- JSON incompleto ou temporariamente inválido;
- cache vazio na primeira carga;
- reinício da aplicação;
- dez ou mais Browser Sources simultâneas;
- recuperação automática após retorno da fonte.

## Riscos e mitigação

| Risco | Impacto | Mitigação |
| --- | --- | --- |
| Cada overlay baixar o `results.json` de 3 MB | tráfego e carga excessivos | gateway/cache central por evento |
| Arquivos opcionais RaceTag em 404 | tela travada | tratar como opcionais e usar ETag do resultado |
| Contagem de checkpoints inconsistente | classificação incorreta | calcular somente a parcial selecionada; chegada por `tn`/`tg` |
| “Elite 5K” não existir na origem | ambiguidade esportiva | regra configurável usando classificação geral |
| Fonte ficar indisponível durante a transmissão | perda do gráfico | congelar último snapshot válido e alertar operador |
| OBS/vMix abrir página sem sessão | overlay não carrega | URL de leitura sem cookie, com token próprio |
| Dependência de CDN falhar | fonte/layout quebrado | assets e fontes locais |
| Mudanças de esquema do provedor | dados ausentes | validação de contrato, health check e logs |

## Critérios de aceite do MVP

- fundo transparente comprovado no OBS e vMix;
- parciais top 2 M/F para todos os checkpoints de 21 e 42 km;
- finais top 10 M/F para 5, 21 e 42 km;
- uma única base de overlay atende todas as combinações por parâmetros;
- atualização de dados não provoca reload completo da página;
- falha da fonte mantém o último ranking válido no ar;
- painel gera URLs sem conhecimento técnico;
- API não expõe `ct`, `tl` ou outros campos desnecessários;
- testes automatizados cobrem ranking, gaps e filtros;
- overlays antigos em `leaderboard/tv` continuam disponíveis como contingência.

## Ordem recomendada para começar

1. validar o conceito visual com uma parcial 42K e um final 21K usando fixtures;
2. implementar o adaptador/cache e comparar o ranking com a RaceTag;
3. fechar o contrato de snapshot;
4. concluir os dois componentes de overlay;
5. criar o painel operacional;
6. homologar em OBS e vMix antes de conectar um evento ao vivo.

