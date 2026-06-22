# Analise do importador CRM de inscritos

Data da analise: 2026-06-21

## Pergunta

Validar se as tabelas provisiorias `tb_listas_importadas`, `tb_listas_conteudos` e
`tb_listas_usuarios` atendem ao objetivo de importar planilhas/CSVs de inscritos de
eventos, normalizar participantes, cruzar com Road Runners e gerar score de lead.

## Resumo executivo

A estrutura provisoria nao atende como modelo final do recurso de CRM. Ela funciona
como uma lista achatada basica, mas falta o que torna o importador confiavel:

- preservacao da linha bruta importada (`jsonb`) para auditoria e remapeamento;
- controle de arquivo/lote, hash, status, erros e mapeamento de colunas;
- campos essenciais de identidade e inscricao: data de nascimento, sexo, status de
  pagamento/cancelamento, origem, cupom/campanha, valor, data de pedido/pagamento;
- chave canonica de participacao por evento, percurso/distancia e pessoa;
- relacionamento robusto com `tb_usuarios`, `tb_resultados`, `tb_leaderboard_startlist`
  e bases de inscricao existentes;
- indices e constraints para consultas CRM, deduplicacao e reprocessamento.

O desenho recomendado e manter tres camadas: importacao, linhas brutas/normalizadas
e participacao canonica de CRM.

## Arquivos analisados

Arquivos em `_codex/crm`:

| Arquivo | Abas | Linhas efetivas | Observacao |
| --- | ---: | ---: | --- |
| `LISTA INSCRITOS - MIF 2017.xlsx` | 1 | 4.991 | Sem cabecalho; apenas nome, distancia, email, cidade, estado. |
| `LISTA INSCRITOS FOCO RADICAL - MIF 2018.xlsx` | 1 | 5.987 | Foco Radical; pedido, status, situacao, produto, valor, atleta, contato e camiseta. |
| `LISTA INSCRITOS TICKET SPORTS - MIF 2018.xlsx` | 1 | 1.344 | Ticket/TicketAgora; numero inscricao, protocolo, pedido, status, pagamento e contato. |
| `LISTA INSCRITOS - MIF 2019.xlsx` | 1 | 10.101 | Lista final Vidya; numeral, pace, pelotao, kit, origem, endereco e status. |
| `LISTA INSCRITOS - MIF 2022.xlsx` | 4 | 13.246 | Abas por distancia: 42K, 21K, 10K, KIDS; formato TicketSports rico. |
| `LISTA INSCRITOS - MIF 2023.xlsx` | 1 | 12.134 | Formato compacto; origem, modalidade, documento, telefone, UF, pedido e camiseta. |
| `LISTA INSCRITOS - MIF 2024.xlsx` | 1 | 15.510 | TicketSports rico; 78 colunas, incluindo perguntas customizadas e produtos repetidos. |

Total da amostra: 63.313 linhas efetivas, 47.915 emails unicos e 47.596 documentos
unicos. Ha muitos emails repetidos em linhas diferentes, o que e esperado em compras
familiares, assessorias ou responsaveis comprando para dependentes. Portanto, email
sozinho nao pode ser tratado como identidade perfeita do atleta.

## Familias de layout encontradas

### 1. Lista minima

2017 nao tem cabecalho nem documento/telefone/data de nascimento/status.

Colunas observadas:

1. nome
2. distancia
3. email
4. cidade
5. estado

Esse arquivo so permite gerar lead fraco por email e nome, com baixa confianca para
deduplicacao.

### 2. Exportacao transacional TicketSports/TicketAgora

2018 Ticket, 2022 e 2024 tem campos bem ricos:

- numero de inscricao;
- protocolo;
- categoria/modalidade;
- nome, nascimento, email, documento, sexo, telefone/celular;
- endereco;
- cupom, origem, campanha;
- forma de pagamento, data de pagamento, pedido, status;
- camiseta;
- perguntas customizadas.

Esse e o formato mais adequado para alimentar uma tabela canonica de participacao.

### 3. Foco Radical

2018 Foco Radical usa nomes de colunas diferentes:

- pedido;
- data e data de pagamento;
- status e situacao;
- produto, quantidade, valor;
- atleta inscrito, email, RG, CPF, sexo, data de nascimento;
- endereco, telefone, equipe, camiseta.

Nao traz numero de inscricao/peito separado, mas traz pedido e produto, que permitem
normalizar distancia e status.

### 4. Lista final / consolidada

2019 e 2023 parecem listas ja consolidadas por operacao:

- 2019 tem numeral, pelotao, pace, kit, origem e status `OK`;
- 2023 tem `ORIGEM`, `MODALIDADE`, `NOME`, `DN`, `DOC`, `SEXO`, `CELULAR`,
  `N do pedido`, camiseta e assessoria.

Esses formatos sao bons para CRM, mas nem sempre preservam o status financeiro do
pedido ou a cidade completa.

## Campos minimos que o modelo precisa suportar

### Campo de importacao

- arquivo original, hash e nome da aba;
- fornecedor/plataforma;
- evento Road Runners (`id_evento`) e evento externo quando existir;
- usuario/conta que importou;
- status do processamento;
- mapa de colunas usado;
- totais processados, validos, invalidos e duplicados;
- logs/erros por linha.

### Campo de linha bruta

- numero da linha;
- `raw jsonb` com todas as colunas originais;
- `normalized jsonb` com os campos extraidos;
- status de validacao;
- erros e avisos.

### Campo canonico de participacao

- atleta/participante canonico;
- evento, ano, distancia/percurso e modalidade;
- numero de inscricao, pedido, protocolo, numero de peito;
- status de inscricao/pagamento/cancelamento;
- origem, cupom, campanha, assessoria/equipe;
- camiseta e respostas customizadas;
- dados basicos de contato e identidade;
- vinculo com usuario Road Runners;
- vinculo com resultado e indicador `correu`.

## Avaliacao das tabelas atuais

### `listas_importadas`

Tabela antiga e achatada. Nao tem chave primaria, lote, arquivo, fornecedor, status,
linha bruta ou controle de reprocessamento. Serve no maximo como scratch table.

### `tb_listas_importadas`

Pontos positivos:

- tem cabecalho de lote/lista;
- relaciona fornecedor, usuario que importou e evento;
- separa tipo de lista.

Lacunas:

- `id_fornecedor` obrigatorio pode bloquear importacoes onde o fornecedor ainda nao
  foi cadastrado;
- nao guarda nome do arquivo, hash, tamanho, aba, separador CSV, encoding, contagem
  de linhas, status de processamento ou erro;
- nao guarda mapeamento das colunas;
- nao relaciona conta/organizador;
- nao tem controle de idempotencia para impedir a mesma planilha de ser importada
  duas vezes.

### `tb_listas_conteudos`

Pontos positivos:

- tem campos basicos de contato;
- tem inscricao/pedido/categoria/modalidade;
- permite guardar numero de peito, tempo e classificacao.

Lacunas criticas:

- nao tem `data_nascimento` nem `sexo`, que aparecem em quase todos os arquivos ricos;
- nao tem `raw jsonb`, logo qualquer coluna nao mapeada se perde;
- nao tem numero da linha de origem;
- nao tem status de pedido/pagamento/cancelamento;
- nao tem origem, cupom, campanha, forma de pagamento, data de pedido/pagamento,
  valor ou protocolo;
- mistura campos de inscricao com resultado (`tempo_bruto`, `classificacao`), mas nao
  tem `id_resultado`, `concluinte`, `status_final` ou fonte do resultado;
- `numero_peito integer` pode falhar para valores sujos de planilhas;
- nao tem constraints de deduplicacao por importacao/linha ou por chave externa;
- nao tem indices para email, documento, evento, pedido, inscricao ou numero de peito.

### `tb_listas_usuarios`

Pontos positivos:

- tenta separar o match com `tb_usuarios`.

Lacunas:

- nao tem chave primaria nem unique;
- nao guarda tipo de match, confianca, origem, data ou se o vinculo foi revisado;
- nao resolve casos de multiplos candidatos ou email compartilhado;
- nao tem indice explicito para consultas por usuario.

## Tabelas existentes que devem entrar no desenho

### `tb_ticketsports_participantes`

E um bom precedente para a camada de importacao: guarda campos importantes indexaveis
e o `body jsonb` com o payload original.

### `tb_inscricoes`

Ja representa inscricao operacional por evento e usuario, mas nao e suficiente como
destino do CRM importado:

- depende de `id_usuario` para a chave natural principal;
- nao tem email;
- nao tem status de pedido;
- nao modela bem leads externos que ainda nao existem em `tb_usuarios`;
- pode ser usada depois do matching, mas nao como staging nem como fonte canonica
  de todos os inscritos importados.

### `tb_resultados`

Deve ser a fonte principal para responder "correu?". O cruzamento pode usar:

- `id_evento + percurso + num_peito`, quando numero de peito existe;
- `id_usuario`, quando houver match;
- fallback por nome normalizado + data de nascimento + percurso, com confianca menor.

Campos relevantes: `concluinte`, `status_final`, `tempo_total`, `tempo_bruto`,
`pace`, classificacoes e `id_resultado`.

### `tb_leaderboard_startlist`

Pode ajudar quando houver lista de largada/startlist antes do resultado final. Nao
substitui a participacao canonica de CRM porque nao guarda contato, documento ou email.

## Estrutura SQL recomendada

### 1. Cabecalho da importacao

```sql
create table crm.tb_crm_importacoes (
    id_importacao bigserial primary key,
    nome_lista varchar not null,
    id_evento integer references public.tb_evento_corridas on update set null on delete set null,
    id_fornecedor integer references public.tb_fornecedores on update restrict on delete restrict,
    id_usuario_importacao integer references public.tb_usuarios on update restrict on delete restrict,
    tipo_lista varchar not null default 'inscritos',
    fonte varchar,
    arquivo_nome varchar not null,
    arquivo_hash varchar not null,
    arquivo_mime varchar,
    aba_nome varchar,
    colunas_raw jsonb,
    mapeamento jsonb,
    status_processamento varchar not null default 'recebido',
    total_linhas integer default 0 not null,
    total_validas integer default 0 not null,
    total_invalidas integer default 0 not null,
    total_duplicadas integer default 0 not null,
    erro_processamento text,
    data_criacao timestamp default current_timestamp not null,
    data_processamento timestamp,
    data_atualizacao timestamp default current_timestamp not null,
    unique (arquivo_hash, coalesce(aba_nome, ''))
);
```

### 2. Linhas importadas

```sql
create table crm.tb_crm_importacao_linhas (
    id_importacao_linha bigserial primary key,
    id_importacao bigint not null references crm.tb_crm_importacoes on update cascade on delete cascade,
    numero_linha integer not null,
    raw jsonb not null,
    normalizado jsonb,
    nome_atleta varchar,
    email varchar,
    email_norm varchar,
    tipo_documento varchar,
    documento varchar,
    documento_norm varchar,
    telefone varchar,
    telefone_norm varchar,
    data_nascimento date,
    sexo varchar,
    cidade varchar,
    estado varchar,
    pais varchar,
    numero_inscricao varchar,
    numero_pedido varchar,
    protocolo varchar,
    numero_peito varchar,
    percurso numeric,
    modalidade varchar,
    categoria varchar,
    status_inscricao varchar,
    origem varchar,
    campanha varchar,
    cupom varchar,
    camiseta varchar,
    assessoria varchar,
    data_pedido timestamp,
    data_pagamento timestamp,
    valor numeric,
    status_validacao varchar default 'pendente' not null,
    erros jsonb,
    avisos jsonb,
    unique (id_importacao, numero_linha)
);

create index tb_crm_importacao_linhas_email_idx
    on crm.tb_crm_importacao_linhas (email_norm);

create index tb_crm_importacao_linhas_documento_idx
    on crm.tb_crm_importacao_linhas (documento_norm);

create index tb_crm_importacao_linhas_evento_percurso_idx
    on crm.tb_crm_importacao_linhas (id_importacao, percurso);
```

### 3. Participante canonico de CRM

```sql
create table crm.tb_crm_participantes (
    id_crm_participante bigserial primary key,
    nome varchar not null,
    nome_norm varchar not null,
    email varchar,
    email_norm varchar,
    documento varchar,
    documento_norm varchar,
    telefone varchar,
    telefone_norm varchar,
    data_nascimento date,
    sexo varchar,
    cidade varchar,
    estado varchar,
    pais varchar default 'BR',
    id_usuario integer references public.tb_usuarios on update cascade on delete set null,
    match_usuario_status varchar default 'nao_processado' not null,
    match_usuario_confianca numeric,
    data_criacao timestamp default current_timestamp not null,
    data_atualizacao timestamp default current_timestamp not null
);

create unique index tb_crm_participantes_documento_uidx
    on crm.tb_crm_participantes (documento_norm)
    where documento_norm is not null and documento_norm <> '';

create index tb_crm_participantes_email_idx
    on crm.tb_crm_participantes (email_norm);

create index tb_crm_participantes_nome_nasc_idx
    on crm.tb_crm_participantes (nome_norm, data_nascimento);
```

Observacao: email nao deve ser unique, porque os arquivos mostram emails compartilhados
por varios atletas.

### 4. Participacao/evento canonico

```sql
create table crm.tb_crm_evento_participacoes (
    id_crm_evento_participacao bigserial primary key,
    id_crm_participante bigint not null references crm.tb_crm_participantes on update cascade on delete cascade,
    id_importacao_linha bigint references crm.tb_crm_importacao_linhas on update cascade on delete set null,
    id_evento integer references public.tb_evento_corridas on update restrict on delete restrict,
    id_fornecedor integer references public.tb_fornecedores on update restrict on delete set null,
    ano_evento integer,
    numero_inscricao varchar,
    numero_pedido varchar,
    protocolo varchar,
    numero_peito varchar,
    percurso numeric,
    modalidade varchar,
    categoria varchar,
    status_inscricao varchar,
    status_participacao varchar default 'inscrito' not null,
    data_pedido timestamp,
    data_pagamento timestamp,
    origem varchar,
    campanha varchar,
    cupom varchar,
    camiseta varchar,
    assessoria varchar,
    valor numeric,
    id_resultado integer references public.tb_resultados on update cascade on delete set null,
    correu boolean,
    concluinte boolean,
    tempo_total time,
    pace time,
    match_resultado_status varchar default 'nao_processado' not null,
    match_resultado_confianca numeric,
    atributos jsonb,
    data_criacao timestamp default current_timestamp not null,
    data_atualizacao timestamp default current_timestamp not null
);

create index tb_crm_evento_participacoes_evento_idx
    on crm.tb_crm_evento_participacoes (id_evento, percurso);

create index tb_crm_evento_participacoes_participante_idx
    on crm.tb_crm_evento_participacoes (id_crm_participante);

create index tb_crm_evento_participacoes_resultado_idx
    on crm.tb_crm_evento_participacoes (id_resultado);

create unique index tb_crm_evento_participacoes_inscricao_uidx
    on crm.tb_crm_evento_participacoes (id_evento, id_fornecedor, numero_inscricao)
    where numero_inscricao is not null and numero_inscricao <> '';
```

## Processo SQL sugerido

### Etapa 1: carregar bruto

Cada arquivo/aba vira uma linha em `crm.tb_crm_importacoes`. Cada linha da planilha
vira uma linha em `crm.tb_crm_importacao_linhas`, com `raw jsonb` preservado.

### Etapa 2: normalizar

Normalizar email, documento, telefone, sexo, percurso, datas e status. Exemplos:

```sql
update tb_crm_importacao_linhas
set email_norm = lower(trim(email)),
    documento_norm = nullif(regexp_replace(coalesce(documento, ''), '[^0-9A-Za-z]', '', 'g'), ''),
    telefone_norm = nullif(regexp_replace(coalesce(telefone, ''), '[^0-9]', '', 'g'), ''),
    sexo = upper(left(trim(sexo), 1))
where id_importacao = :id_importacao;
```

### Etapa 3: deduplicar pessoa

Ordem de confianca:

1. documento normalizado + data de nascimento;
2. documento normalizado;
3. email + nome normalizado + data de nascimento;
4. nome normalizado + data de nascimento + cidade/UF;
5. email sozinho apenas como match fraco.

### Etapa 4: vincular `tb_usuarios`

O match mais seguro hoje e por email, porque `tb_usuarios` nao tem documento. Quando
existir mais de um atleta no mesmo email, o match deve ficar com baixa confianca ou
exigir revisao.

### Etapa 5: vincular resultado e marcar "correu"

Ordem de confianca:

1. `id_evento + percurso + numero_peito`;
2. `id_evento + id_usuario`;
3. `id_evento + percurso + nome normalizado + data_nascimento`;
4. fallback manual/revisao.

`correu` deve vir de `tb_resultados`, especialmente `concluinte`, `status_final`,
`tempo_total` e `homologado`.

### Etapa 6: score de lead

Criar view/materialized view em cima da tabela canonica, nao gravar score direto na
linha importada.

Sinais iniciais:

- recencia da ultima inscricao;
- frequencia de inscricoes;
- distancia preferida;
- se correu/concluiu;
- repeticao no mesmo evento/organizador;
- cidade/UF proxima do evento futuro;
- vinculo com usuario Road Runners;
- engajamento posterior em CRM/email, quando existir.

## Decisao recomendada

Nao evoluir diretamente as tabelas `tb_listas_*` como modelo final. Elas podem ser
aproveitadas conceitualmente, mas o ideal e criar uma estrutura nova `tb_crm_*` ou
renomear/migrar antes de qualquer uso real.

Prioridade tecnica:

1. Criar camada de importacao com `raw jsonb` e mapeamento.
2. Criar tabela canonica de participante e participacao por evento.
3. Rodar backfill das planilhas MIF como piloto.
4. Validar contagens por ano/distancia/status contra os arquivos originais.
5. Implementar matching com `tb_usuarios` e `tb_resultados`.
6. Criar uma primeira view de score.

## Ponto de atencao CRM/LGPD

Os arquivos contem dados pessoais e contatos importados de organizadores. O modelo
deve registrar fonte, finalidade, data de importacao e status de consentimento/base de
uso quando isso for usado para campanhas. Nao se deve assumir automaticamente que
`optin_usuario` de `tb_usuarios` cobre contatos importados de terceiros.

## Atualizacao: dumps TicketSports API 2025/2026

Arquivos adicionados em 2026-06-21:

- `tb_ticketsports_pedidos.xlsx`
- `tb_ticketsports_participantes.xlsx`

Esses arquivos sao dumps das tabelas operacionais ja existentes no banco e usadas em
`/inscricoes` para controle de cupons. O modulo atual de inscricoes consulta
`tb_ticketsports_participantes` e `tb_ticketsports_pedidos`, filtra principalmente o
evento `72611`, exige pedido `Pago` e agrupa por `body ->> 'tituloCupom'`. Ou seja:
essas tabelas ja funcionam como staging API TicketSports, mas hoje a aplicacao so usa
uma fracao dos dados.

Resumo dos dumps:

| Tabela | Linhas | Chave | Observacao |
| --- | ---: | --- | --- |
| `tb_ticketsports_pedidos` | 39.817 | `numero_pedido + cod_evento` | Pedido, status, pagamento, responsavel, valores e participantes no `body`. |
| `tb_ticketsports_participantes` | 47.784 | `numero_inscricao + cod_evento` | Participante, documento, email, modalidade, cupom, produtos e questionario no `body`. |

Eventos encontrados:

| `cod_evento` | Evento | Linhas participantes |
| ---: | --- | ---: |
| 37071 | MARATONA INTERNACIONAL DE FLORIPA 2024 | 15.334 |
| 70020 | MARATONA INTERNACIONAL DE FLORIPA 2025 | 18.552 |
| 72611 | MARATONA INTERNACIONAL DE FLORIPA FIBRA 2026 | 13.405 |
| 72266 | Carioca Family Run | 470 |
| 72357 | Coop Run | 23 |

Decisao apos revisar `/inscricoes`: manter `tb_ticketsports_*` como staging operacional
de API e criar uma materializacao para o CRM. A migration
`_codex/sql/2026-06-21_tb_crm_importador_leads.sql` cria a estrutura canonica e a
funcao `crm.crm_sync_ticketsports(p_cod_evento)` para transformar os dados crus em:

- versoes de evento (`crm.tb_crm_evento_versoes`);
- cabecalhos de importacao (`crm.tb_crm_importacoes`);
- linhas brutas auditaveis (`crm.tb_crm_importacao_linhas`);
- pessoas/leads deduplicados (`crm.tb_crm_pessoas`);
- pedidos (`crm.tb_crm_pedidos`);
- participacoes canonicas (`crm.tb_crm_participacoes`).

Isso evita duplicar o papel das tabelas `tb_ticketsports_*` e tambem evita acoplar o
CRM ao modelo limitado de cupom do `/inscricoes`.

Atualizacao de arquitetura: os objetos canonicos do CRM ficam no schema `crm`, nao no
`public`. A migration cria o schema, remove permissoes implicitas de `PUBLIC`, concede
`USAGE` ao papel `runner` e concede apenas os privilegios necessarios nas tabelas,
views, sequencias e na funcao de sincronizacao. As tabelas `public.tb_ticketsports_*`
continuam como fonte operacional da API.

## Operacao atual de importacao e vinculo de conta

Fluxo pela tela:

1. Admin acessa `/crm`.
2. Filtra ou informa o `cod_evento` TicketSports, por exemplo `72611`.
3. Usa `Sincronizar TicketSports` para materializar `public.tb_ticketsports_*` nas
   tabelas canonicas do schema `crm`.
4. Seleciona uma conta Business e usa `Vincular a conta`.
5. A partir disso, usuarios da conta passam a ver no `/crm` apenas as participacoes
   das versoes de evento vinculadas a ela.

Fluxo por SQL:

```sql
-- sincroniza todos os cod_evento que existem em public.tb_ticketsports_pedidos
select * from crm.crm_sync_ticketsports(null);

-- sincroniza apenas um evento TicketSports
select * from crm.crm_sync_ticketsports(72611);

-- vincula qualquer fonte externa ao evento Road Runners e processa resultados
select *
from crm.crm_link_fonte_evento(
    'ticketsports', -- fonte: ticketsports, csv, excel, outro parceiro etc.
    40782,          -- id_evento em public.tb_evento_corridas
    '72611',        -- codigo externo da fonte, opcional
    null,           -- id_parceiro em public.tb_parceiros, opcional
    null            -- id_usuario que fez o vinculo, opcional
);

-- wrapper de compatibilidade para TicketSports
select * from crm.crm_link_ticketsports_evento(72611, 40782, null);

-- sincroniza o evento e vincula sua versao CRM a uma conta Business
select *
from crm.crm_link_ticketsports_conta(
    72611, -- cod_evento TicketSports
    123,   -- id_conta
    null   -- id_usuario que fez o vinculo, opcional
);

-- processa vinculo entre leads CRM e usuarios Road Runners de uma conta
select * from crm.crm_match_usuarios(123);

-- admin: processa toda a base CRM
select * from crm.crm_match_usuarios(null);
```

O projeto nao tem uma coluna explicita `cod_ticketsports` em
`public.tb_evento_corridas`. Existem caminhos que podem representar esse vinculo:

- `public.tb_evento_corridas_relaciona(id_evento, id_parceiro, id_evento_parceiro)`,
  desde que o parceiro TicketSports esteja cadastrado em `public.tb_parceiros`;
- `public.tb_evento_corridas_importacao.cod_evento/id_evento_match`, quando a staging
  de eventos foi usada;
- URLs de inscricao/hotsite que contenham o codigo TicketSports;
- vinculo manual/generico via `crm.crm_link_fonte_evento`.

Quando `crm.tb_crm_evento_versoes.id_evento` estiver preenchido e o evento ja existir
em `public.tb_conta_eventos`, a funcao `crm.crm_sync_ticketsports` tambem cria o
vinculo automaticamente em `crm.tb_crm_conta_evento_versoes`. Quando esse casamento
nao existir, use `crm.crm_link_ticketsports_conta`.

Decisao de arquitetura: `public.tb_evento_corridas.id_evento` e a ancora canonica do
CRM. `fonte`, `cod_evento_externo` e `id_parceiro` sao metadados opcionais da origem.
Isso cobre:

- TicketSports com `cod_evento`;
- outra plataforma com codigo proprio;
- Excel/CSV sem codigo externo;
- multiplas fontes vendendo inscricoes do mesmo evento Road Runners.

Na interface `/crm`, o filtro principal de evento deve usar `id_evento`, nao
`cod_evento_externo`, para consolidar TicketSports, CSV, Excel e outros fornecedores
na mesma visao de leads da prova.

Para upload de arquivo, a tela deve pedir primeiro o `id_evento` Road Runners. O fluxo
ideal e:

1. criar/garantir a versao de fonte com `crm.crm_link_fonte_evento`;
2. criar o cabecalho com `crm.crm_criar_importacao_arquivo`;
3. gravar as linhas cruas em `crm.tb_crm_importacao_linhas`;
4. mapear colunas e normalizar para pessoas/pedidos/participacoes;
5. rodar `crm.crm_match_resultados` para marcar quem correu e quem reconheceu resultado;
6. rodar `crm.crm_match_usuarios` como fallback para usuarios sem resultado reconhecido.

Exemplo do contrato SQL para um upload CSV/Excel:

```sql
select *
from crm.crm_criar_importacao_arquivo(
    40782,              -- id_evento Road Runners
    'excel',            -- fonte
    'Lista organizador',-- nome_importacao
    'inscritos.xlsx',   -- arquivo_nome
    null,               -- arquivo_hash
    null,               -- id_usuario_importacao
    null,               -- codigo externo opcional
    null                -- id_parceiro opcional
);
```

Observacao: o vinculo em `crm.tb_crm_conta_evento_versoes` controla acesso ao CRM. Se
o mesmo evento tambem precisar aparecer em outros modulos Business, como inscricoes,
ads ou cupons, o vinculo oficial continua sendo `public.tb_conta_eventos`.

## Vinculo com Road Runners

O indicador "Vinculados ao RR" no `/crm` conta pessoas do CRM com
`crm.tb_crm_pessoas.id_usuario` preenchido. Esse campo aponta para `public.tb_usuarios`.

O processamento fica na funcao `crm.crm_match_usuarios(p_id_conta)`. Ela e
conservadora de proposito:

- exige e-mail igual entre CRM e `public.tb_usuarios`;
- exige que o e-mail exista em apenas um usuario Road Runners;
- vincula com alta confianca quando nome normalizado ou data de nascimento batem;
- vincula por e-mail unico apenas quando aquele e-mail tambem pertence a uma unica
  pessoa no CRM;
- deixa pendente quando o e-mail aparece em varias pessoas do CRM, evitando vincular
  familiares/assessorias no usuario errado.

Campos atualizados:

- `crm.tb_crm_pessoas.id_usuario`;
- `crm.tb_crm_pessoas.match_usuario_status`;
- `crm.tb_crm_pessoas.match_usuario_confianca`.

## Vinculo com resultados Road Runners

Este e o caminho mais forte para CRM: depois que uma versao TicketSports aponta para
`public.tb_evento_corridas.id_evento`, a funcao `crm.crm_match_resultados(p_id_conta,
p_id_evento)` cruza as participacoes importadas com `public.tb_resultados`.

Regras usadas, em ordem de confianca:

- evento + numero de peito + nome normalizado;
- evento + nome normalizado + data de nascimento;
- evento + nome normalizado + percurso, quando o nome e unico nos dois lados;
- evento + nome normalizado unico nos dois lados.

Campos atualizados em `crm.tb_crm_participacoes`:

- `id_resultado`;
- `correu`;
- `concluinte`;
- `status_resultado`;
- `tempo_total`;
- `pace_resultado`;
- `match_resultado_status`;
- `match_resultado_confianca`;
- `lead_score` e `lead_score_componentes`.

Quando `public.tb_resultados.id_usuario` esta preenchido, a mesma rotina tambem
preenche `crm.tb_crm_pessoas.id_usuario`. Esse vinculo tem prioridade pratica sobre
o fallback por e-mail, porque prova que aquela pessoa reconheceu um resultado em uma
corrida Road Runners.
