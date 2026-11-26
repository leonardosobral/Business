# Maratonas2025/2026 — candidato após carga de09/11

Esta pasta contém uma reconstrução do vertical completo sobre o canônico de23/10, com leituras e congelamentos novos. O HTML/JS de runtime não foi alterado nem publicado por esta subtarefa. Os PDFs antigos não foram gerados nem incluídos no candidato.

A curadoria foi conservada:50 candidatas documentadas e41 selecionadas em2025;39 IDs selecionados em2026. Os mesmos IDs alimentam as consultas de perfil, desempenho e décadas. As duas novas candidatas do inventário2026 —35906, Maratona Rota do Sol Nascente(78 conclusões), e49893, Maratona Dr.Gordon(26) — ficam na fila de revisão, sem inclusão automática. As cinco exclusões explícitas positivas de2025 também permanecem excluídas pelos motivos anteriores.

| Medida |2025 anual|2026 Jan–Set|
|---|---:|---:|
| Provas selecionadas |41|39|
| Conclusões editoriais |54.234|61.452|
| População de perfil/histograma |54.234|61.469|
| Perfil anterior |54.234|61.454|
| Sem informação utilizável de idade |23.596|1.170(antes1.156)|

Floripa usa3.609 registros no perfil/histograma BI e mantém3.592 classificados Geral/Elite da captura oficial210 no desempenho editorial. A diferença atual é17; não se imputa idade à captura oficial nem se somam as populações. Boston, RaceTag/Runking e Nova York conservam suas capturas/datas anteriores. O principal2025 permanece explicitamente histórico205; inventário, seleção, perfil, desempenho, coorte e contexto amplo2025 têm suas recapturas próprias, sem transformar Jan–Set em ano completo.

A coorte2025×2026 permanece17 pares,40.381→45.801(+13,422%). O Brasil Gigante preserva8 etapas,7 no corte e6 pares comparáveis; seus volumes editoriais permanecem19.409 e17.164 nos seis pares, enquanto a adesão operacional passa de1.519 para1.562 contas com resultado e de164 para180 em2+etapas. Vínculos atuais podem ser retrospectivos; nenhuma taxa identifica efeito causal do circuito.

## Arquivos e reprodução

- `runtime/business/estudos/lancamento/`: HTML e renderer candidatos; cinco CSVs canônicos sob `arquivos/`.
- `runtime/portal/brasilquecorreprovas/imprensa/maratonas/`: leitor regenerado pelo `reader-builder.py` canônico, particionado por edição e com as mesmas regras de acesso.2025 não recebe Boston/BrasilGigante/cenários2026.
- `runs/`: recibos de execução/congelamento e resultados agregados; `sql/`: SQLs derivados salvos; `metadata-current.json`: revisão/hash lidos antes da cadeia.
- `attempt-history/`: execuções intermediárias preservadas. Foi detectado e corrigido o uso indevido de `last_frozen` já renovado para remapear IDs literais antigos. O mapa de origem usa `../notebook-before.json`; versões/hashes atuais servem exclusivamente como trava antes de salvar. Os testes rejeitam242/252/258 onde a fonte foi renovada.
- `delta-report.json` e `editorial-review-queue.csv`: diferenças, candidatas e exclusões pendentes. A ausência no inventário nunca é tratada como zero.
- `candidate-manifest.json`: arquivos/hash e fontes; `validation.json`: capítulos/listas, conservação e renderização sem navegador; `csv-validation.json`: contagens, nulos e contratos dos exports.

```sh
python3 test_derive.py
python3 build_vertical.py
node --check runtime/business/estudos/lancamento/maratonas-detalhado.js
node --check runtime/portal/brasilquecorreprovas/imprensa/maratonas/maratonas-detalhado.js
node validate.cjs
python3 validate_csv.py
```

`collect_vertical.py` só executa as seis células operacionais autorizadas424/426/435/437/442/452. `derive.py` só salva/executa/congela as nove derivadas autorizadas427/428/429/432/433/445/446/449/453; compara revisão+hash relidos e mantém o histórico. Todas as análises usam o executor existente com45s e no máximo um slot desta subtarefa. Nenhum comando amplia privilégios, altera objetos públicos ou publica arquivos.

Fonte final incorporada: principal2026 célula251rev42/run351, contrato18. Derivados atuais433rev4/run357,449rev5/run358 e453rev7/run359. Seus22 vínculos de célula/run foram relidos e conferidos no banco em `notebook-verification.json`. O snapshot privado real42/run351 foi incorporado como referência; produto, destino e view ativos continuam sob controle do publicador. Esta subtarefa não troca ponteiros. Se o controlador registrar o snapshot correspondente, o candidato deve ser regenerado após recongelar433/449/453 com essa referência real. `principal-publication.json`, quando presente, deve conter o run e o ID real da publicação correspondente; não preencher IDs futuros.

## Limites da validação

A montagem confere seleção↔detalhes, somas de gêneros/idades/histogramas, diferença Floripa, cortes cumulativos, coortes, distribuição de adesão, igualdade dos top10 do principal e das fichas, todas as nove chaves do pacote e os41/39 registros das listas completas. O renderer foi executado em NodeVM nos dois anos e nas duas partições de imprensa; essa verificação não substitui captura visual, compilação CFML nem HTTP autenticado, que pertencem ao controlador antes da publicação. Os links dos CSVs conservam o contrato atual de `arquivo.cfm`.

Antes de deploy RR, o controlador deve aplicar a verificação do hold RR Teams no checkout e no candidato final, além de preservar as exclusões existentes. Esta pasta não contém pacote de deployment nem autorização para publicar por conta própria.
