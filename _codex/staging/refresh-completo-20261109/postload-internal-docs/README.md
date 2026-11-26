# PDFs internos - candidato local de 09/11/2026

Pacote isolado, sem publicação, alteração do runtime, SQL, Git ou PDF de Maratonas.

Entregas em `runtime/business/estudos/lancamento/`:

- `arquivos/brasil-que-corre-provas-guia-rapido-q3.pdf`: 1 página, mesmo nome do guia vigente.
- `arquivos/brasil-que-corre-provas-lancamento-q3-execucao-v7.pdf`: 8 páginas. A execução v6 vigente também tem 8 páginas.
- `arquivo.cfm`: somente uma rota adicional `execucao-v7`; `_admin.cfm` e as rotas v6/v5 permanecem idênticos. O diff está em `arquivo-v7.patch`.

`candidate-manifest.json` registra os três destinos, hashes candidatos e baselines. `baseline/` conserva os bytes lidos antes da adaptação: index, router, guia, v6, v5 e geradores originais. Os PDFs v6 e v5 continuam no runtime e não fazem parte da substituição.

## Conteúdo e fontes

Snapshot privado 42, célula 251/run 351; projeção pública célula 420/run 352; pareamento célula 387/run 329. Coleta de 09/11, corte Jan-Set 2026 e referência Jan-Set 2025. Os três congelamentos usados estão em `../postload/runs/`; seus hashes constam do manifesto.

Chamadas: 615 pares, +2,2% nas mesmas provas, +38,7% no calendário e +29,3% no volume registrado. Participação feminina 52,5% em 2025 e 53,8% em 2026; percursos curtos 61,4%; interior 48,0%. Universos distintos e participações sem unicidade de pessoas continuam explícitos.

Escopo mantido: público com seis cards e três comparativos; profissional com 37 páginas; anual separado em rascunho interno (DRAFT). Preços, kits/lotes, CNA, ritmo nacional de 42 km e Q4 permanecem no anual em revisão. Benefício e propostas de janeiro conservam o status anterior; não são nova oferta ativa.

Leo e Carlos continuam responsáveis. Estreia em 13/11, piloto em 10-11/11, contrato ABRACEO em negociação até 12/11. O lote de 95 vouchers READY com resgate até 24/11 é informação preservada do plano anterior, não uma nova coleta de vouchers.

## Reprodução e QA

As cópias dos geradores originais foram adaptadas em `generators/`, mantendo formato, posições, cores e os mesmos arquivos Poppins/Libre Franklin. Não executar os geradores canônicos antigos para esta revisão; estes candidatos usam saída explícita em `output/pdf/`.

Usar o Python empacotado com ReportLab e pypdf:

```sh
PY=/Users/leonardosobral/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3
STAGE=/Users/Shared/Projects/RunnerHub/Business/_codex/staging/refresh-completo-20261109/postload-internal-docs
python3 "$STAGE/prepare.py"
"$PY" "$STAGE/generators/gerar_pdf_guia_rapido.py" --output-dir "$STAGE/output/pdf"
"$PY" "$STAGE/generators/gerar_pdf_execucao_v7.py" --output-dir "$STAGE/output/pdf"
/opt/homebrew/bin/pdftoppm -r 105 -png -singlefile "$STAGE/output/pdf/brasil-que-corre-provas-guia-rapido-q3.pdf" "$STAGE/qa/guia"
/opt/homebrew/bin/pdftoppm -r 80 -png "$STAGE/output/pdf/brasil-que-corre-provas-lancamento-q3-execucao-v7.pdf" "$STAGE/qa/execucao"
"$PY" "$STAGE/verify.py"
```

As nove páginas renderizadas em `qa/` foram inspecionadas: texto legível, sem corte ou sobreposição. QA offline passou para páginas, números e datas, ausência de chamadas antigas, fontes incorporadas, caixas de texto e links (11 no guia, 3 na execução). Uma revisão estática independente confirmou dados e preservação. A evidência está em `verification.json` e nos textos extraídos em `qa/`.

Os comandos de geração e renderização foram finitos e encerraram. Não foram criados navegadores, servidores, drivers, workers ou watchers.

## Integração coordenada

O `index.cfm` real foi lido e preservado. Ele ainda aponta a execução v6 como plano atual; o controlador precisa coordenar seu link e sua indicação de histórico ao integrar os demais materiais. Esta tarefa entrega apenas o patch de router autorizado.

Conferir os baselines do manifesto antes de copiar os três arquivos, preservar v6/v5 e verificar os downloads autenticados e cabeçalhos reais após a publicação coordenada. Os links de rede foram validados estruturalmente; nenhuma navegação ou publicação foi feita aqui.
