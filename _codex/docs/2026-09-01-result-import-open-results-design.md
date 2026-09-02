# Intenção de importação de resultados no payload

Data: 01/09/2026

## Objetivo

Adicionar ao contrato de submissão de resultados a flag booleana
`open_results_enabled`, persistindo a intenção recebida do provedor para que a
fila do Business possa exibi-la sem consultar remotamente o `event.json`.

A flag persistida melhora a triagem da fila, mas não substitui a validação
operacional feita no instante do processamento. Quando o `event.json` possui um
booleano válido, seu valor é a fonte autoritativa.

## Escopo

Esta mudança inclui:

- contrato de entrada e saída da API pública de result imports;
- persistência da flag na fila de importações;
- compatibilidade de idempotência com submissões anteriores à mudança;
- playground, OpenAPI e documentação pública;
- exibição da intenção recebida na fila e nos detalhes do Business;
- uso da flag persistida como fallback no processador RaceTag;
- migração e verificação idempotentes do banco;
- testes automatizados e validação de produção.

Não fazem parte desta versão:

- consulta remota de `event.json` durante o recebimento do webhook;
- consulta remota de `event.json` durante a renderização da fila;
- processamento automático por cron;
- alteração da regra de override, que continua exclusiva para administrador
  interno e exige confirmação explícita e CSRF.

## Contrato da API

O endpoint `POST /v1/result-imports/submissions.cfm` passa a aceitar:

```json
{
  "open_results_enabled": false
}
```

Regras:

- o campo é opcional;
- quando omitido, seu valor efetivo é `true`;
- quando presente, aceita somente os literais JSON `true` e `false`;
- strings, números, `null`, objetos e arrays são rejeitados com HTTP 400 e um
  erro de tipo inválido;
- o nome público é `open_results_enabled`, seguindo o padrão snake_case da API;
- o documento externo `event.json` mantém `openResultsEnabled`, conforme o
  formato da RaceTag;
- o campo é retornado tanto na resposta da submissão quanto em
  `GET /v1/result-imports/status.cfm`.

O OpenAPI declara o campo como `boolean`, opcional e com `default: true`. O
playground oferece um controle booleano ativado por padrão e sempre inclui o
valor escolhido no JSON de teste.

## Persistência

A tabela `public.tb_resultados_importacoes` recebe:

```sql
open_results_enabled boolean not null default true
```

A migração usa `ADD COLUMN IF NOT EXISTS`, mantém o default e valida que não há
valores nulos. Registros existentes recebem `true`, preservando o comportamento
histórico.

Não será criado índice específico, pois a primeira versão apenas exibe a flag e
não adiciona filtro SQL por esse campo.

## Idempotência e compatibilidade

`open_results_enabled` passa a compor o hash canônico do payload. Assim, reutilizar
a mesma `Idempotency-Key` com uma intenção diferente resulta em
`409 idempotency_conflict`.

Submissões criadas antes desta mudança possuem um hash legado que não contém a
flag. Para preservar retries antigos:

- a API calcula o hash novo e o hash legado;
- se encontrar uma submissão existente com hash novo idêntico, retorna o retry
  idempotente normalmente;
- se o valor efetivo solicitado for `true` e o hash persistido for igual ao hash
  legado, também aceita o retry;
- se o valor solicitado for `false`, o hash legado nunca é aceito;
- nenhum hash persistido será reescrito durante um retry.

Essa compatibilidade é limitada a `true`, que corresponde ao comportamento das
submissões anteriores e ao novo default.

## Fila do Business

A consulta da fila e a consulta de detalhes passam a selecionar
`open_results_enabled` diretamente do banco. Nenhuma chamada HTTP externa será
feita para montar a página.

A tabela exibe a coluna **Intenção recebida**:

- `true`: badge verde **Importar**;
- `false`: badge vermelho **Não importar**.

O painel de detalhes exibe o nome técnico `open_results_enabled` e informa que o
valor representa o payload recebido. O texto também explica que o processador
revalida o `event.json` atual.

O botão do processador permanece disponível para submissões Racezone pendentes
ou com falha. O badge não constitui a barreira de segurança; o processador
continua aplicando a regra no servidor.

## Precedência no processador RaceTag

Quando o processamento parte de uma submissão da fila, o processador carrega a
intenção persistida e depois consulta o `event.json`, que já é necessário para
identificar percursos e carregar os resultados.

| Payload persistido | `event.json` | Decisão |
| --- | --- | --- |
| `true` ou `false` | `true` | processamento normal autorizado |
| `true` ou `false` | `false` | bloqueado; apenas override de administrador interno |
| `true` ou `false` | valor inválido | bloqueado; apenas override de administrador interno |
| `true` | campo ausente | processamento normal autorizado por fallback |
| `false` | campo ausente | bloqueado por fallback; apenas override de administrador interno |

Para o modo avulso de administrador, que não possui submissão persistida, o
fallback equivale a `true` para manter a compatibilidade existente.

A tela mostra separadamente:

- **Intenção recebida pela API**;
- **Estado atual do event.json**;
- aviso de divergência quando os valores booleanos são diferentes;
- a decisão efetiva aplicada.

O override existente permanece com as mesmas garantias: administrador interno
real, confirmação explícita, CSRF e registro no log `business_result_imports`.
Uma conta externa, inclusive com papel OWNER ou ADMIN da própria conta, não pode
usar o override.

## Componentes afetados

### RoadRunners API

- `services/ResultImportSubmissionService.cfc`: validação, default, hashes e
  serialização da resposta;
- `repositories/ResultImportRepository.cfc`: inserção da coluna;
- `public-api/openapi.json`: schemas de request e response;
- `public-api/index.cfm`: documentação e playground;
- `public-api/assets/playground.js`: construção do payload de teste;
- SQL de migração e referências de schema.

### Business

- `administracao/importacoes-resultados/includes/backend.cfm`: seleção da flag;
- `administracao/importacoes-resultados/home.cfm`: badges da fila e detalhes;
- `racetag/includes/backend.cfm`: carregamento da intenção persistida;
- `racetag/form.cfm`: precedência, divergência e decisão efetiva;
- testes JavaScript/contratuais e documentação operacional.

## Erros e observabilidade

- payload com tipo inválido retorna erro determinístico antes de qualquer
  inserção;
- conflito de idempotência mantém o HTTP 409 existente;
- o valor persistido aparece na resposta de status para facilitar o diagnóstico
  do provedor;
- divergências entre payload e `event.json` ficam visíveis no processador;
- overrides continuam registrados no log operacional existente.

## Segurança

- o campo não concede permissão e não altera o escopo da credencial;
- a API mantém rejeição de campos desconhecidos e passa a validar estritamente o
  novo booleano;
- a fila apenas renderiza um booleano persistido;
- a decisão de processamento é reavaliada no servidor;
- o `event.json` inválido ou explicitamente desativado nunca autoriza o fluxo
  normal;
- o override não pode ser habilitado por dados do payload ou por JavaScript.

## Testes

Os testes devem cobrir:

- omissão resulta em `true`;
- `true` e `false` literais são aceitos;
- string, número, `null`, objeto e array são rejeitados;
- a flag participa do hash novo;
- retry legado é aceito apenas quando o valor efetivo é `true`;
- mesma chave com alteração da flag retorna conflito;
- request/status retornam `open_results_enabled`;
- repositório insere a coluna;
- fila renderiza **Importar** e **Não importar** sem fetch remoto;
- tabela de precedência do processador;
- somente administrador interno consegue confirmar override;
- OpenAPI e playground expõem o novo campo.

## Implantação e rollback

Ordem de implantação:

1. executar e verificar a migração de banco;
2. publicar API, OpenAPI, documentação e playground;
3. validar submissões com campo omitido, `true`, `false` e tipo inválido;
4. publicar Business e processador RaceTag;
5. compilar CFML, conferir hashes e validar as telas autenticadas.

O banco deve ser migrado antes do código porque API e Business selecionarão a
nova coluna. Em rollback de aplicação, a coluna pode permanecer: ela é aditiva,
possui default e não interfere no código anterior.

Antes de cada publicação serão criados backups dos arquivos substituídos. A
implantação será interrompida se a migração, os testes ou a compilação CFML
falharem.
