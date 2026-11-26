# Corte local dos consumidores Q3 — helper candidato

Este helper gera arquivos/diffs e uma proposta SQL para revisão DBA. Não conecta
a servidor/banco, não executa SQL, não publica e não modifica runtime. Não contém
IDs novos padrão: `ids.example.json` tem valores nulos e deve falhar até ser
preenchido com IDs reais explicitamente conferidos. Os IDs 8101–8105 existem somente
nos testes sintéticos e não são candidatos de produção.

## Corte revalidado

- `StudyAccess.read` ainda fixa publicação41 e narrativa420/rev5/run239; as fontes
  pareadas são lidas dos metadados `notebook_fontes` da publicação (célula387).
- `parcial.js` fixa narrativa239. O helper troca somente esses pins e a revisão
  pública, mantendo filtros, cálculos, precisão, auth, produto/benefícios e guardas.
- O wrapper Business e o anual têm versões fixas de cache: ambas precisam mudar
  junto com o JS. O helper muda exclusivamente esses tokens nesses wrappers.
- Imprensa tem cópias geradas de SQL/JS. O helper reutiliza as funções canônicas de
  `reader-builder.py` para os quatro arquivos da edição principal, com fontes
  validadas em memória e overlay dos novos CFC/JS. Mantém ramo2025, redirecionamentos,
  guardas e stylesheet. Não gera a parte Maratonas, nem altera imprensa por edição.
- O endpoint público continua `runnerhub` → `estudo.lancamento_publico`, sem acesso
  novo às tabelas privadas. A view atual depende do produto41 e run239. Atualizar
  só o produto quebra a view; a proposta SQL move produto e view na mesma transação.
- `estudo.publicar_web` criaria a publicação técnica e moveria `web_destinos` antes
  do corte; por isso **não foi usado** no fluxo aprovado desta sessão. A publicação
  privada42 foi registrada/validada sem referências ativas. O helper exige esse
  snapshot imutável existente e propõe mover destino2026/produto/view juntos apenas
  na transação DataGrip final. Não chama `publicar_web` nem reponta2025.
- O anual usa `StudyEditions.annual()`, último congelamento válido da célula418 por
  `frozen_at,id`. Não há pin novo nem ativação do produto anual. **Congelar a saída
  anual já muda o rascunho interno imediatamente**, antes do corte Q3. O helper
  registra o run esperado e exige a evidência de que ele é o último válido.

## Entradas obrigatórias

Executar `python3 consumer_cutover.py --describe` lista as 27 chaves de arquivos
que precisam de baseline, e os oito campos de IDs. Essa operação não escreve.

`--baseline` é JSON capturado por operação de leitura controlada. Para CADA chave
listada em `files`, preencher hashes SHA256 dos bytes locais e dos bytes reais em
produção. **Não preencher o hash de produção copiando o local**. O helper recusa
qualquer divergência e também calcula novamente o hash local na hora da geração.
Ele não pode detectar mudanças remotas posteriores à captura; recapturar/verificar
o baseline imediatamente antes da publicação final continua obrigatório.

Formato do baseline:

```json
{
  "captured_at": "2026-11-09T00:00:00-03:00",
  "files": {
    "business/estudos/includes/StudyAccess.cfc": {
      "local_sha256": "HASH_REAL",
      "production_sha256": "HASH_REAL"
    }
  },
  "generator_sha256": "HASH_DO_READER_BUILDER_LOCAL_CONFERIDO",
  "database": {
    "product_id": 1,
    "publication_id": 41,
    "publication_run": 233,
    "public_run": 239,
    "public_revision": 5,
    "paired_cell": 387,
    "public_cell": 420,
    "annual_cell": 418,
    "contract_version": 17,
    "destination2026": {"ano": 2026, "cell_id": 251, "publicacao_id": 41, "versao": 22},
    "destination2025": {"ano": 2025, "cell_id": 249, "publicacao_id": 37, "versao": 19},
    "view_definition": "TEXTO_EXATO_DE_pg_get_viewdef_com_pretty_true",
    "view_sha256": "SHA256_UTF8_DO_TEXTO_EXATO",
    "security_barrier": true
  }
}
```

Todos os arquivos de `--describe` são necessários, não só o exemplo acima. A
data ilustrativa não atesta captura; registrar a data real com timezone. Registrar
barreira da view a partir de `pg_class.reloptions`, além do texto da definição.
As células387/420/418 e saída251 são o contrato atual; mudança de célula exige
revisão explícita do helper. Ele falha em vez de ampliar automaticamente o escopo.

`--ids`: os oito campos do exemplo, preenchidos com inteiros positivos reais. A
publicação, saída Q3 e narrativa têm de ser novos em relação ao baseline; revisão
da narrativa tem de ser maior que a anterior. Rejeita null, bool, zero, texto de
placeholder e pins antigos. Os valores são usados apenas como referências.

`--evidence`: metadados lidos do banco após novos congelamentos/publicação técnica:

```json
{
  "publication": {
    "id": "INTEIRO_NOVO", "run": "INTEIRO_NOVO", "year": 2026, "cell": 251,
    "contract_version": 18,
    "payload_sha256": "HASH_HEX_REAL_64_CARACTERES",
    "paired_run": "INTEIRO_NOVO", "paired_revision": "INTEIRO_NOVO"
  },
  "runs": [
    {"id": "RUN_PUBLICO", "cell": 420, "revision": "REV_PUBLICA", "frozen": true,
     "status": "ok", "truncated": false, "row_count": 1, "payload_sha256": "HASH_HEX_REAL"},
    {"id": "RUN_PAREADO", "cell": 387, "revision": "REV_PAREADA", "frozen": true,
     "status": "ok", "truncated": false, "row_count": 1},
    {"id": "RUN_ANUAL", "cell": 418, "revision": "REV_ANUAL", "frozen": true,
     "status": "ok", "truncated": false, "row_count": 1}
  ],
  "annual_latest_run": "RUN_ANUAL"
}
```

Os textos ilustrativos devem ser substituídos por números JSON, não strings.
Hashes de payload são os SHA256 da representação PostgreSQL `jsonb::text`, em
UTF8: profissional em `web_publicacoes.payload`; público em
`notebook_runs.result->'rows'->0->'payload'`. Não usar o hash de um JSON salvo com
outra indentação. O vínculo pareado é o declarado nos metadados da publicação,
não simplesmente o último run387 encontrado.

## Execução e resultados

```sh
python3 /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/consumer-cutover/consumer_cutover.py \
  --baseline /pasta/baseline-real.json \
  --ids /pasta/ids-reais.json \
  --evidence /pasta/frozen-evidence-real.json \
  --output-dir /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/cutover-candidate-NOVO
```

A saída tem de ser uma pasta nova isolada. O helper recusa diretórios de runtime
e pastas de saída já existentes. Antes de escrever, valida todos os inputs,
baselines e transformações. Nenhum arquivo do checkout é editado.

- `candidate/business/`: CFC, parcialJS, wrapper leitor e wrapper anual.
- `candidate/portal/.../imprensa/principal/`: os quatro derivados canônicos.
- `runtime.patch`: diff unificado dos oito arquivos de runtime; nenhuma métrica é
  recalculada/substituída. Transformação inversa garante CFC idêntico ao original
  fora dos pins. A versão completa de 09/11 é a entrada, não um baseline antigo.
- `manifest.json`: IDs antes/depois, hashes de fontes/saídas, hash da projeção e
  destino anual esperado. **Só `runtime_files` é allowlist de transferência.**
- `database-cutover-DBA.sql`: proposta transacional, guardada por destinos2025/2026,
  transição de contrato exatamente17→18 e hash da view,
  produto atual, resultados congelados/revisões/hashes, vínculo da fonte387,
  janelaJan–Set, conciliação das taxas pareada/calendário com narrativa e contrato
  limitado da projeção pública. Confere também o anual mais recente. Atualiza
  destino2026 de41/vers22 para42/vers23, ponteiro do produtoQ3 e view pública juntos.
  Destino2025 é bloqueado/conferido e não alterado. Mantém `security_barrier=true` e não
  toca permissões, papel, datasource, runs ou métricas.
- `database-baseline.json`: definição/pins anteriores para preparar rollback
  recuperável no fluxo do controlador. Não é um rollback automático nem apaga
  publicações; preservar também bytes/manifestos de produção.

Node verifica sintaxe dos JS. O hold RR Teams é executado no checkout e na pasta
**final `candidate/portal`**. A pasta também recebe sete arquivos necessários ao
check e a `.rsync-filter`; são `validation_only_files`, fora da allowlist de
transferência. Não publicar essas cópias de perfil/menu/gates por engano nem fazer
rsync amplo da pasta. Transferências RR devem usar `-F` com a `.rsync-filter` da
raiz e arquivos delimitados. Nenhuma autorização de release RR Teams é inferida.

## Limites antes do corte real

A proposta SQL ainda requer revisão/execução pelo canal DBA autorizado, porque
o datasource da aplicação pode bloquear DDL. O helper não contorna essa proteção.
Não houve execução SQL nem validação semântica em PostgreSQL nesta subtarefa.
Compilação CFML, baseline remoto final, check das novas fontes/métricas, backup,
sequência entre arquivos e transação, HTTP autenticado/público, imprensa e gates
Teams GET/POST continuam com o controlador. Não há atomicidade mágica entre vários
arquivos e o banco: não executar a transação sem o pacote compatível preparado.

Não gera kit, PDFs, Maratonas ou lista nova de provas. O mapa
`../marathon-refresh-map.md` continua aplicável. O script DBA recebido do usuário
não é importado nem executado por este helper.

## Testes executáveis

```sh
python3 -m unittest /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/consumer-cutover/test_consumer_cutover.py
```

Os testes simulam o baseline remoto com bytes locais explicitamente como fixture.
Cobrem recusas de placeholders/pins antigos, divergência local/produção/definição,
evidência não congelada, vínculo pareado e anual incorretos; conferem inversão
exata do CFC, ramo2025 idêntico, guardas preservadas, IDs registrados, cacheanual,
geração de diff/SQL e hold no candidato final. Não atestam produção atualizada.
