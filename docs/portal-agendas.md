# Agendas de eventos

O modulo `/portal/agendas/` cria listas de eventos vinculadas a um usuario da plataforma e distribui essas listas por JSON, XML ou embed HTML/JS.

## Instalacao

1. Execute `/portal/agendas/agenda_schema.sql` no banco `runner_dba`. O script e idempotente e tambem deve ser executado para atualizar uma instalacao existente.
2. Publique os arquivos do Business.
3. Acesse `Ferramentas > Agendas` com um usuario Admin, Dev ou Partner.

Em uma instalacao que ja possui o schema base, `/portal/agendas/agenda_visual_options_migration.sql` aplica somente as colunas de fonte e arredondamento.

O script cria:

- `tb_agendas`: configuracao, proprietario, dominio e status.
- `tb_agenda_eventos`: selecao e ordenacao das agendas manuais.
- `tb_agenda_filtros`: regras das agendas dinamicas.
- `tb_agenda_credenciais`: hashes das credenciais XML.
- `tb_agenda_acessos`: auditoria de entregas e recusas.

## Modos

### Manual

Os eventos sao pesquisados por nome ou ID, agregador de edicoes, distancia, estado, cidade, tipo e periodo. Depois de adicionados, permanecem na Agenda ate a remocao e podem ser ordenados manualmente.

### Dinamica

Os eventos sao resolvidos em tempo real. Valores do mesmo campo usam `OU`; campos diferentes usam `E`.

Exemplo: `estado=SC`, `estado=PR`, `distancia=10` e `tipo=rua` significa `(SC OU PR) E 10 km E rua`.

As distancias cadastradas em metros ou milhas sao convertidas para quilometros durante a comparacao. Uma Agenda dinamica sem regras inclui todos os eventos da visualizacao, respeitando o limite configurado.

## Visualizacoes

- `futuros`: eventos ativos, nao cancelados, com `data_final >= current_date`.
- `resultados`: eventos ativos e passados com `url_resultado` ou registros em `tb_resultados_resumo`.

As duas visualizacoes ficam sempre disponiveis na previa e nos codigos de publicacao. Quando `visao` nao e informada na requisicao, o fallback tecnico e `futuros`.

Todos os formatos apontam o evento para `https://roadrunners.run/evento/{tag}/`.

## Aparencia

Cada Agenda define um tema de cards `claro` ou `escuro`, uma cor hexadecimal para o card da data, a fonte dos cards de eventos e o nivel de arredondamento. A cor do texto da data e calculada automaticamente para manter contraste.

As fontes permitidas sao `trebuchet`, `verdana`, `georgia`, `tahoma` e `monospace`. Os niveis de arredondamento sao `atual` (16 px), `medio` (10 px), `suave` (5 px) e `reto` (0 px). Os valores sao enumerados e normalizados pelo servidor; nao ha entrada livre de CSS.

O documento do embed, o `body`, o iframe e o container criado pelo carregador usam fundo transparente. Assim, o fundo visivel e sempre o da pagina que incorporou a Agenda; o tema escolhido afeta apenas cards, textos, bordas e chips.

Os cards nao exibem chip de tipo. Somente distancias numericas inteiras iguais ou superiores a `3` sao exibidas como chips. Distancias decimais e valores menores que `3` continuam disponiveis nos dados JSON/XML, mas nao aparecem na interface incorporada.

## JSON

```text
GET /api/portal/agendas/?agenda={CHAVE}&visao=futuros
GET /api/portal/agendas/?agenda={CHAVE}&visao=resultados
```

O JSON e destinado a navegadores. A requisicao precisa apresentar `Origin` ou `Referer` correspondente ao dominio da Agenda. A resposta usa CORS especifico, `ETag` e cache curto.

O objeto `agenda.appearance` informa:

- `theme`: `claro` ou `escuro`.
- `background`: sempre `transparent`.
- `dateCardColor`: cor hexadecimal configurada.
- `dateTextColor`: cor de contraste calculada pelo servidor.
- `cardFont`: fonte configurada para os cards de eventos.
- `cardRadius`: nivel de arredondamento configurado.

## XML

```text
GET /api/portal/agendas/feed.cfm?agenda={CHAVE}&visao=futuros&token={TOKEN}
GET /api/portal/agendas/feed.cfm?agenda={CHAVE}&visao=resultados&token={TOKEN}
```

O token tambem pode ser enviado no header:

```text
X-RR-Agenda-Token: {TOKEN}
```

O feed segue o namespace `https://roadrunners.run/schemas/agenda/v1`. A referencia estrutural esta em `/api/portal/agendas/agenda-v1.xsd`.

O elemento `metadata` inclui `appearance` com os atributos `theme`, `background`, `dateCardColor`, `dateTextColor`, `cardFont` e `cardRadius`.

A credencial aparece somente na criacao ou rotacao. O banco guarda apenas SHA-256. Rotacionar uma credencial revoga imediatamente a anterior.

Quando `Origin` ou `Referer` existe, o XML tambem valida o dominio. Em consumo servidor a servidor esses headers normalmente nao existem; nesse caso a credencial e a autenticacao efetiva. Um dominio, isoladamente, nao consegue autenticar de forma confiavel uma requisicao feita por outro servidor.

## Embed JS

```html
<div id="rr-agenda-exemplo"></div>
<script
  async
  src="https://business.roadrunners.run/api/portal/agendas/embed.js"
  data-agenda="CHAVE_PUBLICA"
  data-view="futuros"
  data-target="rr-agenda-exemplo">
</script>
```

Valores aceitos em `data-view`: `futuros` e `resultados`.

O script cria um iframe fluido com `width: 100%` e limite maximo de 680 pixels. Nao existe largura minima: iframe, container, cabecalho e cards se adaptam ao espaco disponivel, inclusive abaixo de 280 pixels. O iframe usa `Content-Security-Policy: frame-ancestors` restrito ao dominio cadastrado, CSS e JavaScript autorizados por nonce, links em nova aba e redimensionamento por `postMessage` validado pelo script hospedeiro.

O site consumidor deve manter uma politica de referencia que permita ao menos a origem, como `strict-origin-when-cross-origin`. Politicas `no-referrer` impedem a validacao inicial do dominio.

## Seguranca

- O gerenciamento exige usuario Admin, Dev ou Partner e token CSRF.
- Admin e Dev visualizam e gerenciam todas as Agendas e podem selecionar o proprietario na criacao ou edicao.
- Partner visualiza e gerencia somente as Agendas em que `tb_agendas.id_usuario` corresponde ao seu usuario autenticado. Na criacao, o proprietario e atribuido pelo servidor e nao pode ser alterado pelo formulario.
- A restricao de propriedade dos Partners e aplicada nas listagens, metricas, abertura por URL e operacoes POST; ocultar o seletor na interface nao e usado como mecanismo de seguranca.
- O dominio e normalizado antes de ser salvo.
- Subdominios so sao aceitos quando a opcao correspondente estiver ativa.
- Agendas fora do status `ativa` nao sao entregues publicamente.
- O JSON recusa requisicoes sem origem autorizada.
- O embed combina verificacao de origem com CSP `frame-ancestors`.
- O XML exige credencial aleatoria rotativa armazenada somente como hash.
- Cada Agenda e IP aceita ate 120 entregas por minuto antes de responder HTTP 429.
- A auditoria registra formato, dominio, HTTP status, quantidade de eventos, IP e duracao.
- Falhas no registro de auditoria nao interrompem a entrega.

## Arquivos

- `/portal/agendas/index.cfm`: entrada administrativa.
- `/portal/agendas/home.cfm`: interface de gerenciamento.
- `/portal/agendas/agenda_visual_options_migration.sql`: migracao incremental das opcoes visuais.
- `/portal/includes/agenda_management_backend.cfm`: CRUD e pesquisas.
- `/includes/backend/agenda_service.cfm`: resolucao e seguranca compartilhadas.
- `/api/portal/agendas/index.cfm`: JSON.
- `/api/portal/agendas/feed.cfm`: XML.
- `/api/portal/agendas/embed.js`: carregador incorporavel.
- `/api/portal/agendas/render.cfm`: cards protegidos por dominio.
