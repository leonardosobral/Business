# Baseline real dos consumidores após a carga DataGrip

Captura concluída em **09/11/2026 21:18:59 UTC (18:18:59 BRT)** por leitura SSH
delimitada dos arquivos e consulta de metadados pelo bridge existente. Nenhum
INSERT/UPDATE/DELETE/DDL foi executado, nenhum runtime foi publicado e nenhuma
alteração local foi sobreposta. O script DBA recebido não foi executado por esta
subtarefa.

## Resultado e arquivos

- **27/27 arquivos locais e de produção coincidem byte a byte**, incluindo fontes
  usadas pelo gerador de imprensa, CFC/leitor Business e wrappers do anual.
- `baseline.json`: pronto como `--baseline` do helper `../consumer-cutover/`, ainda
  dependente dos IDs novos e da evidência dos congelamentos/publicação técnica.
- `snapshots/local/` e `snapshots/production/`: cópias dos 27 arquivos, separadas
  pelas chaves `business/` e `portal/`, com checksums conferidos no transporte.
- `database-snapshot.json`: produtos, destinos, definição/owner/opções da view,
  metadados dos congelamentos387/418/420, anual mais recente e privilégios PG.
- `capture-report.json`: resumo, divergências vazias e confirmação da limpeza.
- `capture_baseline.py`: operador de leitura reutilizável. Ele escreve somente os
  snapshots/manifestos desta pasta. Para uma nova captura, preservar esta evidência
  histórica em pasta nova antes de reutilizá-lo.

O operador conferiu novamente hashes remotos ao fim da leitura e hashes locais
após o retorno, detectando eventual alteração durante a captura. O hash do gerador
canônico `reader-builder.py` também está registrado no baseline.

## Ponteiros capturados

| Item | Estado real observado |
|---|---|
| Produto profissional Q3 | ID1, `previa-2026-q3`, ACTIVE, publicação41/run233 |
| Destino técnico2026 | Publicação41, célula251, versão22 |
| Destino técnico2025 | Publicação37, célula249, versão19 |
| View pública | Produto41 + narrativa420/rev5/run239 |
| Owner da view | `runner_dba` |
| `security_barrier` | true |
| Anual interno | Último congelamento válido234, selecionado dinamicamente pela célula418 |

SHA256 da definição exata de `pg_get_viewdef(..., true)`:
`ee05be7bd4b56685eb01cd0e9c7fcc3a4a0f54fc8a80604e59b52717157252e4`.

Os pins atuais dos consumidores correspondem a esse estado: publicação41,
narrativa239/rev5. Não foram substituídos por placeholders nem IDs de teste.
O produto anual permanece DRAFT, sem publicação comercial.

## DML versus DDL no último corte

A consulta de catálogo PG desta captura retornou true para UPDATE de produtos,
INSERT em publicações, EXECUTE de `publicar_web`/`web_payload_conferido` e CREATE
no schema pelo usuário do datasource. **Isso não comprova autorização DDL pela
camada ColdFusion.**

Os flags do datasource registrados na revisão desta sessão em
`../dba-load-review/datasource-permission-flags.json` são:

| Operação | Flag registrada |
|---|---|
| SELECT / INSERT / UPDATE / DELETE | true |
| CREATE / ALTER / DROP | false |
| GRANT / REVOKE | false |

Não se releu nem alterou configuração do datasource nesta captura. A operação
solicitada no DataGrip carregou dados; não autoriza ampliar permissões.

1. Novas revisões/runs/congelamentos e publicação técnica usam os mecanismos
   existentes autorizados. `estudo.publicar_web` insere uma publicação imutável e
   move `web_destinos`, mas **não reponta o produto**.
2. O último corte do produto é um UPDATE em `estudo.produtos.publicacao_id`.
3. O último corte público é `CREATE OR REPLACE VIEW estudo.lancamento_publico`,
   com os IDs novos aprovados e `security_barrier=true`: é DDL e precisa do canal
   **DataGrip/DBA**. Não tentar contornar o flag da aplicação.
4. Executar destino2026, produto e view **na mesma transação guardada do DataGrip**,
   pois a view depende do ponteiro do produto. O snapshot privado42 aprovado foi
   registrado sem mover destinos; não usar `publicar_web` antes do corte para
   evitar ativação parcial. Não mudar só o produto pelo datasource e
   deixar a view pública vazia aguardando DDL posterior. Não mudar grants, owner,
   roles, credenciais ou datasource.
5. O helper `consumer-cutover` prepara o SQL guardado a partir deste baseline e
   dos IDs/evidências novos. Ele ainda não foi executado com alvos reais nesta
   captura. Preservar a definição antiga e os bytes de arquivos para recuperação.

## Próximo passo com IDs reais

O controlador deve fornecer a publicaçãoQ3/run de saída, narrativa420/run/revisão,
pareada387/run/revisão e anual418/run/revisão, com a evidência de congelamentos e
vínculos declarados nos metadados da publicação. O helper recusa pins antigos,
placeholder, divergência de hashes ou fonte não congelada. Até lá não há candidato
de runtime novo nesta pasta.

Congelar um anual novo já o torna visível ao rascunho interno porque a consulta usa
`ORDER BY frozen_at DESC,id DESC`; registrar esse efeito na ordem da entrega.
O helper não ativa o produto anual e não muda esse contrato.

O helper pontual `consumer-cutover` substitui os pins antigos pelos novos. Para
publicar runtime compatível ANTES da transação DataGrip, foi adicionado
`build_compatible.py`, descrito abaixo. Isso resolve a compatibilidade dos
consumidores entre os dois estados aprovados; a publicação de arquivos nas duas
aplicações e a transação de banco continuam operações distintas, com verificações
próprias. Não declarar atomicidade única entre banco e servidores.

Antes do deploy final, recapturar/verificar hashes remotos e ponteiros: este
baseline registra um instante e não protege contra mudanças posteriores. Preservar
alterações de outras frentes; nenhuma divergência pode ser resolvida sobrescrevendo
produção ou descartando trabalho local automaticamente.

RR Teams permanece retido. O helper confere o checkout e o candidato final; os
arquivos de suporte de validação ficam fora da allowlist de transferência, que
continua delimitada e exige a `.rsync-filter` raiz (`-F`). PDFs de Maratonas não
foram gerados, copiados ou substituídos.

## Pacote compatível antes do corte, pacote novo após confirmação

`build_compatible.py` reutiliza `consumer-cutover.validate_inputs` e os mesmos
JSONs `baseline`, `ids`, `evidence`. Não obtém IDs automaticamente, não aceita
placeholders e não possui acesso SSH/banco. As fontes são os bytes atuais validados
contra os 27 hashes reais. Nenhum arquivo do checkout é editado.

```sh
python3 /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/postload-consumers/build_compatible.py \
  --baseline /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/postload-consumers/baseline.json \
  --ids /pasta/ids-reais.json \
  --evidence /pasta/frozen-evidence-real.json \
  --output-dir /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/consumer-transition-NOVO
```

Ou API local: `build(baseline, ids, evidence, output_root)`. A pasta de saída
deve ser nova/isolada. O pacote é montado em diretório temporário próprio e movido
para a saída apenas depois das verificações. Erros limpam o temporário e não
deixam uma saída aparentemente concluída.

O patch de compatibilidade do CFC tem somente **cinco substituições exatas**,
documentadas em `compatible/patch-plan.json` e `compatible/runtime.patch`:

1. A fonte pareada carrega também `a.publicacao_id`, sem mudar sua extração ou
   validação de `notebook_fontes`, IDs/revisões, janela ou congelamento.
2. A restrição de publicação admite exatamente a publicação antiga e a nova.
3. `paired_public` usa duas linhas `VALUES(publication_id,run_id,revision)`, uma
   para **41→239/rev5**, outra para os IDs novos fornecidos. Cada run precisa
   continuar congelado, OK, completo, célula420 e na revisão aprovada.
4. O antigo `CROSS JOIN` vira
   `JOIN paired_public n ON n.publication_id=p.publicacao_id`. Uma publicação não
   pode usar a narrativa do outro par, mesmo que as taxas arredondadas coincidam.
5. `meta.comparativo_pareado.narrativa` recebe o run/revisão dessa linha vinculada.

As regex, conferências de amostra/contagens e taxas, fórmulas, precisão,
autorização e fallback de fonte ausente/inválida ficam byte a byte iguais fora
dessas substituições. A transformação inversa é validada antes de gerar arquivos.
Nenhuma lista de fontes arbitrária, wildcard de revisão ou opção para desativar
guardas é introduzida.

No JS, muda somente a condição de narrativa para uma lista literal de exatamente
dois IDs numéricos (`includes` estrito). Missing/null/string ou qualquer terceiro
ID continuam inválidos. As demais validações de coorte e cálculo não mudam.
Os wrappers Business/anual recebem versão de cache específica da transição.

Os quatro arquivos de imprensa principal são gerados dessas fontes compatíveis
pelas funções canônicas do `reader-builder.py`. O ramo2025 e as guardas existentes
permanecem idênticos. Maratonas não é gerado e os PDFs não são tocados. Node confere
JS e o hold RR Teams é executado no checkout e em cada pasta final de candidato.

Saídas:

- `compatible/`: oito candidatos de runtime, manifesto, diff sobre o baseline real
  atual e plano de patch pequeno com os dois pares explicitamente registrados.
- `final-only/`: os oito candidatos do helper original com somente os IDs novos;
  `runtime.patch` e os `before_sha256` são calculados **sobre os bytes compatíveis**,
  não sobre os bytes antigos de produção. Essa é a transição esperada posterior.
- `final-only/database-cutover-DBA.sql`: mesma proposta guardada da transação
  produto/view; deve ser revisada e executada no canal DataGrip autorizado.
- `build-report.json`: pares aprovados, IDs, caminhos dos dois manifestos e checks.

Ordem de uso pelo controlador:

1. Conferir congelamentos/publicação técnica e preparar os dois pacotes com IDs
   reais. Compilar/revisar o compatível; confirmar baseline real novamente.
2. Publicar SOMENTE a allowlist `runtime_files` de `compatible/`, manter os sete
   arquivos de suporte de hold e filtro fora da transferência rotineira, e verificar
   que Business/imprensa ainda leem o estado41/239 completo.
3. Executar a transação DataGrip de destino2026 + produto + view com os IDs novos, sem ampliar
   permissões. Verificar o estado novo nos dois leitores e no endpoint público.
4. Recapturar/confirmar os hashes reais da produção compatível e o resultado da
   transação. Só então publicar `final-only/` para remover os pins antigos.
   O campo `baseline_origin` desse manifesto explica que seus hashes anteriores
   são **esperados**, e ainda não representam uma nova captura de produção.
5. Verificar novamente novo estado, fontes, fallback e Teams. Arquivar evidências
   e backups, preservando métricas e mudanças de outras frentes.

Testes locais:

```sh
python3 -m unittest /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/postload-consumers/test_build_compatible.py
```

As fixtures usam IDs sintéticos8101–8105 somente dentro de temporários. Cobrem
exatamente duas tuplas, vínculo publicação/narrativa obrigatório sem cruzamento,
inversão byte a byte do CFC, JS estrito, recusa de drift/placeholder antes de criar
saída, ramo2025 idêntico e baseline correto para a fase final. São verificações
estáticas e de geração; SQL vivo, compilação CFML e HTTP ficam pendentes dos IDs
reais e da validação do controlador. Nenhuma execução PostgreSQL é feita por esses
testes ou pelo helper de compatibilidade.

## Recursos temporários

O bridge foi criado com prefixo exclusivo
`postload-consumers-read-2c4eb17052e04f88ac16c6d4025a04b6-`, protegido para loopback e
token de requisição, e removido pelo `finally` do operador existente. A leitura
remota confirmou `temporary_directories_left: []` depois do retorno. SSH e curl
terminaram; nenhum navegador/servidor/worker persistente foi iniciado.
