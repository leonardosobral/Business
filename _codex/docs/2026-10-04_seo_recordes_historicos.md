# Recordes históricos de São Paulo — 04/10/2026

## Divergência confirmada, correção de dados pendente

O resumo das edições seleciona os resultados armazenados para a maior distância e prioriza a classificação por sexo. No agregado 17, o bloco público reproduz dois valores que divergem da fonte oficial de campeões:

| Edição | Categoria | Selecionado na base | Vencedor na fonte oficial |
| --- | --- | --- | --- |
| 2008, evento 40792 | Masculino, 42 km | 01:42:19 | 02:17:07 |
| 1998, evento 40802 | Feminino, 42 km | 02:16:54 | 02:39:58 |

O resultado masculino de 02:17:07 existe na base como segundo colocado. As duas linhas selecionadas têm pcd=false, homologado=true e classificacao_sexo=1; esses campos não comprovam a exatidão do dado. A origem da divergência ainda não foi determinada. Pode envolver a fonte histórica, categorização, cadastro ou transformação na importação. Não há evidência para atribuir fraude ou alterar atributos pessoais.

Fontes consultadas e referências:

- [Campeões históricos na Yescom](https://www.yescom.com.br/2018/maratonadesaopaulo/resultados/campeoes).
- [Resumo público no RoadRunners](https://roadrunners.run/evento/2027-maratona-internacional-de-sao-paulo-2027/).
- Fonte cadastrada de [2008 na Athlinks](https://www.athlinks.com/event/34587/results/Event/841532/Results).
- Fonte cadastrada de [1998 na Athlinks](https://www.athlinks.com/event/34587/results/Event/759962/Results).

A página histórica Yescom permite comparar os campeões dessas edições; não prova o recorde vigente em 2026. A lista completa da Athlinks não pôde ser acessada nesta investigação: a ferramenta web falhou e o navegador retornou ERR_BLOCKED_BY_CLIENT. O bloqueio não foi contornado.

## Entrega no Business

RR-14 foi registrado como pendente, com evidências e critérios de aceite. São 21 itens: 16 entregues e cinco pendentes. As notas técnicas, datas de auditoria e estados do Google não foram alterados. SH-02 permanece aberto.

A primeira publicação falhou no contrato de URLs da fila: foram inseridas referências externas num campo limitado a roadrunners.run e openresults.run. A versão anterior foi restaurada e sua renderização conferida. O erro de processo foi publicar após a falha do teste candidato. A correção mantém apenas a URL pública RoadRunners nesse campo; as referências externas estão nesta documentação.

O script desta publicação agora exige recibo de renderização aprovado, vinculado aos hashes do candidato e das dependências, além da compilação. O verificador confere as abas relatório e fila e só emite sucesso depois de todas as asserções. O runtime de validação e suas restrições de domínio permaneceram intactos.

A versão corrigida passou na compilação Adobe de um template, renderizações candidata e publicada, verificação do hash do arquivo e preservação de cinco dependências. Backup recuperável: /var/backups/seo-record-panel-20261004-v2/baseline. Não houve alteração de layout; esta entrega acrescenta um item ao componente existente.

Artefatos: _codex/staging/seo-record-evidence-20261004/ e _codex/staging/seo-record-panel-20261004-v2/. O estágio original conserva o registro de rollback.

## Próxima ação

Rastrear os metadados e o processamento das duas edições e reconciliar com a lista completa da fonte. Só então preparar correção reversível e verificar campeões, recordes e gráficos nos três idiomas. Não aplicar limites arbitrários de tempo nem substituir classificações por inferência. Nenhum resultado, vínculo, atributo pessoal, configuração de bots ou runtime público RoadRunners/OpenResults foi alterado nesta entrega.

## Rastreamento da importação

Consulta somente leitura de 04/10 encontrou três registros de processamento em 17/04/2026: dois para2008 e um para1998, todos com erro_execucao=false. Há7.346resultados finais em2008 e5.146em1998. Esse status registra execução, não correção factual.

Não há linhas em tb_resultados_temp nem logs em tb_resultados_processa_logs para esses IDs. A busca indexada por referencia=resultado e call_date entre01/04inclusive e18/04exclusive não encontrou webhooks contendo os IDs841532/759962 das fontes. Isso não prova inexistência de cópias anteriores, arquivos externos ou backups.

O coletor local RunnerHub/api/crawler/resultado/athLink_resultado_v3.js seleciona detalhe.intervals[0] ao montar o resultado e usa esse intervalo também para classificações. É um ponto a revisar com uma resposta real que contenha múltiplos intervalos; não há prova de que esse código tenha sido usado em17/04 nem de que tenha causado as duas divergências. Não executar o coletor: ele envia resultados ao webhook de produção.

A próxima ação depende de localizar a lista completa original, um payload retido ou backup dessas importações. Pergunta assíncrona enviada ao usuário sobre a localização dos arquivos. Nenhum campo dos atletas foi alterado e nenhum importador foi executado. Evidências resumidas em trace-conclusion.json; consultas em inspect_processing.py, inspect_comparison.py e inspect_webhook_matches.py. O resultado negativo foi verificado nos três arquivos JSON, não inferido da ausência de saída.
