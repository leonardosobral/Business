# Publicador do destaque LIVE no circuito

Artefato local para revisão. Esta tarefa não executou SSH nem alterou runtime.
O mecanismo vem do publicador de mensuração LIVE revisado, SHA-256
`512feca9b058db452dd6cb2189e813055f671a657d3b4a36975c2d4a97521d04`,
com escopo, ordem, contagens e guardas adaptados para este release.

## Dois destinos, nesta ordem

| Site | Caminho | Baseline |
|---|---|---|
| RoadRunners | `circuito/live_highlight.cfm` | `ABSENT` |
| RoadRunners | `circuito/index.cfm` | SHA-256 efetivo de produção |

O include novo entra antes da página que o consome. A única raiz de escrita em
runtime é `/var/www/roadrunners.com.br`. Business é acessado somente para leitura
das proteções, em `/var/www/business.roadrunners.run`.

## Preparação do pacote pelo responsável

Use `/var/backups/rr-live-highlight.<hex minúsculo>` com dono root e modo `0700`.
A CLI recusa outro prefixo e caracteres fora de `0-9a-f` no sufixo.
Não reutilize diretório de uma preparação abortada. O pacote contém:

```text
publish.py
runtime.tsv
candidate/RoadRunners/circuito/live_highlight.cfm
candidate/RoadRunners/circuito/index.cfm
```

`runtime.tsv` tem exatamente duas linhas sem cabeçalho, na ordem acima, com
quatro campos separados por TAB:

```text
site<TAB>caminho relativo<TAB>beforeSHA ou ABSENT<TAB>afterSHA
```

Os hashes são SHA-256 minúsculos dos bytes efetivos. A primeira linha exige
`ABSENT`; a segunda exige o hash da produção, sem presumir igualdade com o
checkout. Os diretórios de destino precisam existir. Candidatos, release e pais
dos destinos devem estar no mesmo filesystem. Confira o hash do publicador após
a transferência. Depois de `prepare`, não edite TSV, candidatos ou backups.

## Comandos explícitos

Exemplo de sintaxe para o responsável executar após a revisão:

```sh
release_dir=/var/backups/rr-live-highlight.a1b2c3d4
python3 "$release_dir/publish.py" "$release_dir" prepare
python3 "$release_dir/publish.py" "$release_dir" verify
python3 "$release_dir/publish.py" "$release_dir" publish
python3 "$release_dir/publish.py" "$release_dir" verify
```

`prepare` valida escopo, ordem, hashes, arquivos regulares e ausência de symlinks
em todos os componentes. Guarda um backup exato, seus metadados e a ausência do
novo include em `before`/`state.json`. Reconfere runtime, backups e proteções,
sem alterar os sites. Contagens são calculadas a partir do manifesto.

`publish` reconfere todos os baselines e guardas antes de escrever. Monta cada
arquivo completo no mesmo filesystem; o novo usa criação exclusiva atômica por
hard link do stage seguido de remoção do nome temporário. O existente usa rename
atômico. UID/GID/modo/atributos estendidos são preservados no existente; novos
recebem `root:root`, `0644`. O mtime publicado é atualizado, avançando pelo menos
um segundo em relação ao original para permitir recompilação do template CF.
Backup/rollback mantêm o mtime original. Inode/ctime mudam na troca; atime pode
mudar por leitura de verificação, conforme o filesystem.

`verify` confere hashes, metadados, backups e guardas segundo o estado registrado:
baseline em `prepared`/`rolled_back`, candidatos em `published`. Estado incompleto
ou conflito não conclui sucesso. A operação grava intenções e resultados em
`state.json` e `operations.jsonl` com sincronização de disco.

## Proteções

Os 11 arquivos da mensuração implantada são guardas explícitas em
`MEASUREMENT_GUARDS`: quatro Business (incluindo `live_journey.sql`) e sete
RoadRunners. O include SQL novo do release anterior agora também faz parte do
inventário protegido de `Business/portal/audiencia/queries`.

Continuam protegidos Ads/CPC, autenticação Business, configurações, serviços de
controle, coleta, SW e os arquivos do release anterior de classificação de
entrega de banners. As árvores `config`/`_codex/sql` dos dois sites e as consultas
de audiência Business têm inventários e hashes comparados. Apenas
`circuito/index.cfm` sai das guardas, por ser um dos dois alvos autorizados.

Guardas são somente leitura e aceitam arquivos regulares com hard links, como
configuração compartilhada. Uma alteração pelo outro link também modifica o
hash e bloqueia publicação. Alvos, candidatos e backups continuam exigindo um
único link. Symlinks são recusados. Nenhum SQL é executado, nenhuma configuração
ou recurso do Google Ads é alterado e nenhum serviço é reiniciado.

## Recuperação

Falha parcial ou falha na verificação final dispara rollback em ordem inversa.
SIGINT/SIGTERM/SIGHUP entram nesse fluxo; queda do host, SIGKILL ou falha física
podem exigir a execução explícita usando o journal durável:

```sh
python3 "$release_dir/publish.py" "$release_dir" rollback
python3 "$release_dir/publish.py" "$release_dir" verify
```

Rollback só troca um arquivo que ainda tenha o hash **e metadados** publicados.
Arquivo já igual ao baseline é mantido. Mudanças concorrentes são preservadas,
registradas em `rollbackConflicts` e retornam erro. O novo include só é retirado
se ainda corresponde ao publicado; seus bytes ficam no release em
`removed-rollback-*`. A restauração não depende dos candidatos e pode ser
repetida para alvos já restaurados. Não altere hashes para forçar restauração.

Mantenha janela exclusiva de outros escritores/publicadores. O `flock` é por
diretório de release, não trava aplicações ou outros releases. Para arquivos
existentes, a conferência por hash imediatamente antes do rename ainda tem o
intervalo residual de POSIX sem compare-and-swap por hash; a exclusão de outros
escritores é necessária. A atomicidade é por arquivo, não entre os dois. Rollback
restaura arquivos e não reverte estado de banco, cache ou eventos coletados.

## Validação offline

```sh
python3 /Users/Shared/Projects/RunnerHub/Business/_codex/staging/live-highlight/release-tools/test_publish.py
```

Nove testes usam somente diretórios temporários e UID/GID locais, sem rede ou
webroots reais. Cobrem o ciclo de dois alvos, mtime/metadados/ausência, drift de
cada uma das 11 guardas de mensuração, drift de runtime, rollback parcial e com
conflito, criação exclusiva, configuração com hard link e escopo/hashes/links
inválidos. Raízes injetadas existem somente no uso do módulo pelos testes; a CLI
mantém raízes fixas. O resultado executado está em `verification.log`.
