# Composição final da central e hotsite - 09/11/2026

Somente staging. Nenhum runtime canônico, banco ou publicação foi alterado.

O assembler pode consumir `manifest.json`: `files` usa chaves `business/...` e `portal/...`; cada item informa o caminho candidato relativo a esta pasta, `candidate_sha256` e `before_sha256`. São três arquivos:

- `candidate/business/estudos/lancamento/index.cfm`: duas textareas idênticas ao candidato `postload-media`; chamadas +2,2%/+38,7%; coleta 09/11; v7 atual; v6/v5 históricos. Checklist dinâmico, responsáveis, formulários, CSRF, cronograma, negociação ABRACEO e escopo preservados.
- `candidate/portal/brasilquecorreprovas/2026/pagina.html`: somente meta description, OG description, OG image alt e cache da imagem atualizados. Corpo, formulário editorial, placeholder CSRF, scripts, links 2025 e endpoint local preservados byte a byte.
- `candidate/portal/brasilquecorreprovas/2026/public-preview.json`: payload público inteiro da célula 420 rev7/run352. Somente `{ok,release}`, sem wrapper, SQL ou metadados privados. Seis indicadores e comparativos de 2025 preservados conforme a nova fonte; `diferenca_pp` interno mantido conforme precisão original. Nenhuma chamada pública em pontos percentuais foi adicionada.

`baseline/` e `baseline-manifest.json` guardam os atuais canônicos lidos antes da composição. `patches/` tem os três diffs. `candidate-manifest.json` detalha dependências e proveniência; `verification.json` registra QA offline. Reproduzir com `python3 compose.py`; a composição aborta caso o runtime mude em relação ao baseline.

A fixture passou pelo `readRelease()` do JavaScript canônico atual, sem modificá-lo. Asserções também conferiram a preservação dos blocos operacionais e do corpo público, textos de mídia exatos e os links v7/v6/v5 com o router candidato de `postload-internal-docs`.

Integrar junto ao kit de `postload-media` (mesmo nome de arte, novo cache OG) e aos três arquivos de `postload-internal-docs` (guia, execução v7, router). A view pública real continua sendo servida por `dados.cfm`; o shell vigente troca `public-preview.json` por esse endpoint e injeta CSRF. Nenhum dos dois arquivos dinâmicos foi editado.

Compilação CFML, layout de navegador e HTTP após publicação ficam com o controlador. Não foram criados browsers, servidores ou processos em background; o teste Node finito encerrou.
