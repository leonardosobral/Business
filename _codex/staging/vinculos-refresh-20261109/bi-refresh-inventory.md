# Inventário BI — 09/11/2026 (somente leitura)

## Evidências

- `bi-metadata-readonly.json`: papéis, DDL lógico/colunas, permissões, tamanhos e estatísticas.
- `bi-load-sources-readonly.json`: referências das funções, células relacionadas, contratos das três views de estudo e funções de geração.
- `bi-source-cell-*.sql`: cópias locais das células atuais, lidas diretamente do notebook.

Nenhuma função de carga, DDL, DML, publicação ou navegador foi executado. As únicas escritas foram estes recibos locais em staging.

## Origem vigente

`public.tbbi_fat_perfil_br_2026` é tabela física, de propriedade `runner_dba`, ~622 MB. Não há coluna de carga, timestamp ou versão. Não há trigger, constraint ou índice associado. A sequence pertence a runner_dba. Estatísticas acumuladas mostram 4.502.542 inserções e 860.031 updates; última autoanálise em 06/10/2026 23:03:56-03. Estas estatísticas não substituem nova contagem exata.

`public.vwbi_fat_perfil_br_2026` é view simples sobre a tabela com sete INNER JOINs; não busca novos resultados operacionais. `estudo.vwbi_perfil_br_2026` reproduz a estrutura usando sete LEFT JOINs, conservando IDs sem dimensão. `estudo.vw_resultados_2026` usa a fato como universo e preenche colunas ausentes por LEFT JOIN com `tb_resultados`; portanto mudanças de nomes/nascimento/modalidade podem ser atuais, mas novos resultados ausentes da fato nunca entram. `estudo.vw_resultados_comparativo_2025_2026` usa resultados operacionais para 2025 e esse adaptador para 2026.

A tabela ainda é a base carregada em 06/10 conforme estatísticas e fontes do notebook. Não é uma fonte live regenerada automaticamente. A comparação agregada abaixo confirma novos IDs no operacional; a fato continua com o mesmo universo registrado em06/10.

## Rotina de carga e privilégios

Consulta a `pg_proc` por nomes perfil/BI/carga e depois por referência de corpo a `tbbi_fat_perfil%`/`tbbi_dim_organizacao_2026` não encontrou rotina de carga. Nenhuma célula do notebook contém carga2026: há somente auditoria407–413, projeção414, notas415 e consumidores256/327. Scripts DBA2025 antigos existem, porém possuem filtros diferentes (excluem KIDS, exigem tempo, rua/trail), portanto não são carga2026 reproduzível.

A conexão da ponte está como `runner_dba`, superuser; permissões técnicas não bloqueiam backup/reload, mas essa capacidade não determina escopo autorizado. A fato/view2026 e organização2026 já concedem SELECT a estudo_reader.

## Preservação

Há `estudo.bi_geracoes_2026_revisao_20261006` para valores de geração anteriores (860.031 alterações documentadas). Não foi encontrado backup integral/snapshot por linha da fato2026. Notebook preserva execuções congeladas e publicações anteriores, mas isso não equivale a backup dos 4,5 milhões de fatos.

## Caminho reversível recomendado

1. Capturar contagem/IDs elegíveis operacionais BR, data final >=2026-01-01 e <2026-10-01, status_final=0, homologado e concluinte; comparar por IDs com fato2026. Toda idade/modalidade no total; controles de rua/distância permanecem próprios das séries.
2. Preservar integralmente a tabela atual (dump recuperável com checksum/validação ou snapshot separado) antes de qualquer reload. Preservar definições/ACL/sequences/views e registrar timestamp/hash da baseline. Não usar os scripts DROP TABLE/VIEW de2025.
3. Preferir nova fonte versionada em `estudo` para atualização do estudo, mantendo fonte DBA pública e histórico intactos. Manter o contrato das views existentes e aplicar uma troca transacional depois dos controles; rollback restaura as definições anteriores. Uma alternativa é reload transacional da própria fato pública, que exige reconstrução fiel de todas as 20 colunas e afeta consumidores fora do estudo.
4. Se reconstruir fato, reusar geração aprovada via `get_id_geracao(range,2026,nascimento,data_evento)`; IDgeração vigente depende da plausibilidade individual. Não reusar função CBAt por sobreposição para séries cuja regra é contenção. Dimensões de organização/localidade exigem mapeamento auditado e nunca podem eliminar resultado do universo.
5. Auditar unicidade por id_resultado; nenhuma duplicação de dimensão; conservação total/sexo/meses/eventos; divergências de elegibilidade e datas; alterações/ausências por dimensão. Só então trocar adaptadores e reexecutar notebooks derivados.

A solução exata depende da decisão do responsável entre atualizar a fonte DBA pública ou criar snapshot operacional versionado do estudo. Inventário não executou nenhuma das duas.

## Comparação agregada autorizada depois do inventário

Todas as consultas seguintes rodaram em transação `READ ONLY`, com `statement_timeout=45s`, e retornaram antes do limite.

- **15:38:45:** fato exata = **4.502.542 linhas/IDs únicos**, 4.789 eventos, 150.159 id_localidade0, nenhuma data foraJanSet. IDs23085895–31190231.
- **15:38:58:** operacional elegível = **4.572.137 linhas/IDs únicos**, 4.963 eventos, 2.460.899F, 2.109.686M, 1.552demais. MesesJan–Set158051/165059/566764/459228/719782/529639/510008/742644/720962. IDs23085895–32563726.
- **15:39:24:** comparação em um único snapshot = **4.501.814IDs comuns +70.186 novos**, **728fatos fora da elegibilidade atual**; 0evento divergente, 170datas divergentes entreIDs comuns. Operacional deste snapshot soma **4.572.000**, líquido+69.458sobreBI. A diferença de137entre consultas consecutivas demonstra que não se deve misturar snapshots de instantes diferentes. Reconciliar toda a saída a uma captura consistente.
- **15:40:15:** dos728IDs fora da elegibilidade, **585não existem mais em tb_resultados** e **143têm data de evento foraJanSet**. Não há outros motivos sobrepostos: nenhum concluinte/status/homologação/país divergente entre os restantes. CalendárioBRJanSet tem291cadastros incluídos após06/10 23:15; max(data_inclusao)=04/11/2026 10:01:40. `data_processamento` não serve como indicador atual de carga: max no calendário é12/07/2026. `tb_resultados` não possui timestamp de inclusão/alteração.

Recibos exatos: `bi-fact-count-readonly.json`, `bi-raw-count-readonly.json`, `bi-id-diff-readonly.json`, `bi-lost-reasons-readonly.json`. Helper reproduzível: `compare-bi-readonly.py` (não executa DDL/DML).
