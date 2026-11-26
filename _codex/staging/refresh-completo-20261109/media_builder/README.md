# Kit editorial derivado de uma fonte explícita

Gerador candidato preparado em 09/11/2026. Não contém acesso ao banco, publicação,
alteração de permissões, fonte remota ou import de conteúdo histórico. A data de
lançamento é 13/11/2026; data de coleta e todos os percentuais vêm do JSON recebido.
O fechamento dos novos dados e o corte coordenado com a view pública continuam
sob responsabilidade do controlador. As fixtures não comprovam renovação do BI.

## Entradas

- `--source /caminho/fonte-publica.json`: o contrato atual `{ok:true, release:{...}}`,
  seis indicadores públicos, histórias `pareadas`, `provas`, `resultados`, `mulheres`,
  janela 2026-01-01 a 2026-09-30 e `release.coleta` ISO válida.
- `--provenance /caminho/provenance.json`: `public_cell`, `public_run`,
  `publication_id`, `publication_run`, identificadores positivos explícitos;
  `status` é `candidate` (padrão) ou `reviewed`. O exemplo tem IDs nulos de propósito:
  preencher com os novos congelamentos conferidos; não há fallback para 239/41/233.
- `--output-dir /pasta/isolada/candidate`: a saída será criada abaixo dessa pasta,
  sem transferências e sem editar runtime.
- `--central-source /caminho/atual/index.cfm` (opcional): lê a central ATUAL e produz
  uma cópia candidata trocando somente o conteúdo de `copy-release` e
  `copy-convite`. Exige um de cada; recusa ausência/duplicidade. Checklist, owners,
  abas e demais bytes permanecem iguais. A chamada-resumo do kit fora das textareas,
  se ainda tiver taxas antigas, precisa de diff separado revisado pelo controlador.

Exemplo (preencher os caminhos e IDs reais):

```sh
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/media_builder/media_builder.py \
  --source /caminho/fonte-publica.json \
  --provenance /caminho/provenance.json \
  --output-dir /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/media-candidate \
  --central-source /Users/Shared/Projects/RunnerHub/Business/estudos/lancamento/index.cfm
```

`candidate` insere aviso de material candidato no HTML, textos e páginas de
contexto do PDF. `reviewed` remove a pendência sem afirmar que o BI foi renovado:
informa apenas que a fonte fornecida foi revisada. Só o controlador decide quando
usar esse estado, após validar os novos congelamentos.

## Interface Python e saídas

`build_model(payload, provenance)` valida e monta todas as cinco pautas;
`central_texts(model)` retorna os dois textos;
`patch_central(current_html, texts)` substitui estritamente as duas textareas;
`generate(payload, provenance, candidate_root, central_source=None)` gera o pacote
completo e devolve o manifesto. O módulo pode ser importado sem gerar arquivos.

Em `candidate_root/portal/brasilquecorreprovas/2026/kit/`:

- cinco pautas: calendário/coorte, gênero, resultados, distâncias e interior;
- dez artes PNG: 1080×1350 e 1920×1080;
- dois aliases antigos `fevereiro-comparativo-*`, cópias da arte calendário/coorte;
- `panorama-publico-jan-set-2026.pdf`, exatamente sete páginas;
- `index.html`, `legendas-e-fontes.txt`, `release-imprensa-2026.txt`,
  `convite-criadores.txt`.

Em `candidate_root/`: `central-texts.json`, central candidata opcional e `qa/`
com manifesto/hash de entradas e arquivos, modelo, caixas de texto, sete PNGs e
folha de contato do PDF. Números não são substituídos em PDFs prontos: todas as
artes são desenhadas a partir do modelo e rasterizadas do PDF correspondente.
Hash das entradas versiona todas as URLs de download e imagem.

São usados ReportLab, Pillow e pypdf do Python empacotado; `pdftoppm` precisa estar
no PATH. Fontes tipográficas são lidas dos assets existentes do RoadRunners.
`graphics.py` copia apenas os três primitivos gráficos já aprovados, com
proveniência documentada. Nenhum gerador antigo é executado ou importado.

## Verificação

```sh
/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  -m unittest /Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/media_builder/test_media_builder.py
```

Os testes usam a fonte antiga só como fixture de entrada e outra fixture com
TODOS os indicadores das cinco pautas alterados, taxas negativas, novos IDs e nova
data de coleta. A geração completa confirma sete páginas, 12 PNGs com dimensões
corretas, os valores novos em PDF/HTML/TXT e ausência dos valores antigos nesses
artefatos. Também cobrem fonte ausente/null/NaN, data inválida, inconsistência de
gênero, proveniência inválida e preservação da central fora das duas textareas.

`fixtures/old-source-candidate/` e `fixtures/changed-candidate/` são provas locais
marcadas como candidatas; os IDs 9001/9002/9003 da segunda são sintéticos. Não publicar.
Não foram gerados ou substituídos PDFs de Maratonas, guia interno ou plano v6.
