# Kit real do congelamento352 — candidato local revisado

Gerado a partir do payload da célula420 rev7 / execução congelada352,
referência profissional publicação privada42 / run351. A fonte explícita está em
`fonte-publica.json`, extraída de `../postload/runs/420.json`; a proveniência
revisada está em `provenance.json`. Não foi usado o endpoint público antigo.

O status `reviewed` foi autorizado pelo controlador após conferência da fonte.
Significa material revisado; **não significa publicado nem ponteiros cortados**.
Nenhuma consulta de banco, upload ou alteração de runtime ocorreu nesta subtarefa.

## Entrega

- `candidate/portal/brasilquecorreprovas/2026/kit/`: 17 arquivos, incluindo dez
  artes distintas em dois formatos, dois aliases históricos, PDF de sete páginas,
  página HTML, legendas/fontes, release e convite.
- `candidate/business/estudos/lancamento/index.cfm`: central candidata, trocando
  exclusivamente o conteúdo de `copy-release` e `copy-convite`.
- `candidate/central-texts.json`: mesmos dois textos para integração delimitada.
- `candidate/qa/manifest.json`: hashes de todos os 17 arquivos públicos e entradas.
- `candidate/qa/pdf-contact.png`, `pdf-1.png` a `pdf-7.png`: provas visuais.
- `verification.json`: verificações da fonte, arquivos, dimensões e central.

Taxas confirmadas nos artefatos: **+2,2%** nas edições pareadas, **+38,7%** no
calendário, **+29,3%** nos resultados, mulheres **52,5%→53,8%**, percursos curtos
**61,4%**, interior **48,0%**; coleta09/11/2026 e lançamento13/11/2026.
Os seis indicadores do JSON de origem também foram conferidos contra a sequência
validada pelo controlador. O kit mantém as cinco pautas aprovadas.

PDF e textos não contêm as chamadas antigas2,1/33,9/27,3/53,9/61,2/47,5,
nem provenance239/41/233 ou coleta06/10. Os aliases de fevereiro são cópias da nova
arte calendário/coorte, não conteúdo antigo promovido.

Conferência visual: folha de contato das sete páginas e cinco portraits vistos;
sem texto cortado/sobreposto. As dez artes possuem dimensões esperadas1080×1350
ou1920×1080. Os6 testes do gerador também passaram.

## Preservação da central e limites

Hash da central atual usada como baseline:
`9f80c3e46f7a229e41ce43bcacf6f3d8eac84bae69458a609e654c25026d81db`.
Fora das duas textareas, a comparação de bytes retorna **zero diferenças**;
checklist, owners, abas, instruções e demais conteúdo de09/11 foram preservados.
`central-baseline.cfm` guarda a cópia de leitura usada na conferência.

A chamada do cartão do kit e outros textos fora das textareas podem ainda citar
taxas antigas: foram preservados por escopo e precisam do diff separado do
controlador antes da publicação coordenada. Não publicar esta central candidata
isoladamente como se todo o conteúdo já estivesse conciliado.

Não houve geração/alteração de PDFs de Maratonas, guia ou execuçãov7. Não foi
iniciado navegador ou servidor. Os subprocessos de rasterização terminaram e os
diretórios temporários próprios foram removidos pelo contexto do gerador.

Reprodução local: executar `prepare_kit_real.py` com o Python empacotado que dispõe
de ReportLab, pypdf e Pillow, mantendo Poppler no PATH. O script lê os caminhos
explicitamente acima, gera somente esta pasta de staging e repete as verificações.
