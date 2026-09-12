# Publicação reversível da mensuração LIVE

Ferramenta local preparada para revisão. Nenhum comando deste documento foi
executado contra os webroots ou por SSH por esta tarefa. Não executa SQL,
migrações, cobrança, Ads, reinício de serviços ou limpeza de cache.

## Escopo fixo

`publish.py` usa Python 3 com biblioteca padrão, em Linux. A CLI exige root,
diretório root-owned com modo `0700` e caminho
`/var/backups/rr-live-measurement.<sufixo alfanumérico>`.

Os únicos destinos de escrita em runtime são os 11 caminhos abaixo, nesta ordem:

| Ordem | Site | Caminho | Baseline |
|---|---|---|---|
| 1 | Business | `portal/audiencia/queries/live_journey.sql` | `ABSENT` |
| 2 | Business | `portal/audiencia/live_journey.cfm` | `ABSENT` |
| 3 | Business | `portal/includes/audience_backend.cfm` | SHA-256 de produção |
| 4 | Business | `portal/audiencia/home.cfm` | SHA-256 de produção |
| 5 | RoadRunners | `services/AudienceMeasurementService.cfc` | SHA-256 de produção |
| 6 | RoadRunners | `assets/js/rr-audience.js` | SHA-256 de produção |
| 7 | RoadRunners | `includes/modal/modal_cupom_link_conteudo.cfm` | SHA-256 de produção |
| 8 | RoadRunners | `evento/index.cfm` | SHA-256 de produção |
| 9 | RoadRunners | `evento/parts/barra_acoes.cfm` | SHA-256 de produção |
| 10 | RoadRunners | `evento/parts/edicoes_evento.cfm` | SHA-256 de produção |
| 11 | RoadRunners | `includes/analytics/bootstrap.cfm` | SHA-256 de produção |

As raízes fixas são `/var/www/business.roadrunners.run` e
`/var/www/roadrunners.com.br`. Não há opção da CLI para alterá-las.
O consumidor Business entra antes do produtor RoadRunners; serviço e JS entram
antes dos CTAs, e bootstrap entra por último. O script não cria diretórios nos
webroots: todos os pais dos arquivos devem existir.

## Artefatos a montar após a revisão

O responsável pela publicação prepara o diretório privado contendo:

```text
publish.py
runtime.tsv
candidate/Business/<quatro caminhos acima>
candidate/RoadRunners/<sete caminhos acima>
```

`runtime.tsv` tem exatamente 11 linhas, sem cabeçalho ou linhas vazias, com quatro
campos separados por TAB:

```text
site<TAB>caminho relativo<TAB>beforeSHA ou ABSENT<TAB>afterSHA
```

Os nomes dos sites são exatamente `Business` e `RoadRunners`. Hashes devem ser
SHA-256 com 64 caracteres hexadecimais minúsculos, obtidos dos bytes efetivos.
Os dois novos caminhos exigem `ABSENT`; os outros nove exigem hash e precisam
existir. Um hash local não substitui a leitura do baseline de produção. A versão
do candidato `evento/index.cfm` conserva os dois blocos de sidebar/footer que já
existiam em produção: isso não é funcionalidade nova desta publicação.

Confira os hashes do script e dos artefatos após a transferência. Não edite o
TSV, candidatos, backups ou `state.json` depois de `prepare`. Prepare um novo
diretório de release se qualquer artefato mudar. Os candidatos deste pacote são
os que o responsável revisou; o script não escolhe, baixa ou altera código.

## Modos

Exemplo de sintaxe; substituir o caminho pelo diretório concreto revisado:

```sh
release_dir=/var/backups/rr-live-measurement.EXEMPLO
python3 "$release_dir/publish.py" "$release_dir" prepare
python3 "$release_dir/publish.py" "$release_dir" verify
python3 "$release_dir/publish.py" "$release_dir" publish
python3 "$release_dir/publish.py" "$release_dir" verify
```

`prepare` confere ordem, whitelist, hashes dos candidatos, ausência/presença,
links simbólicos em todos os componentes dos caminhos, arquivos regulares sem
hard links nos alvos/candidatos/backups e mesmo filesystem entre release,
candidatos e pais dos destinos.
Registra nove backups exatos em `before/{site}/{path}`, metadados em `state.json`
e ausência explícita dos dois novos. Reconfere backups, runtime e proteções
antes de finalizar a preparação. Não modifica runtime.

`publish` exige uma preparação ainda não usada e reconfere **todos** os baselines,
metadados, backups e proteções antes da primeira troca. Cada arquivo é montado
integralmente e validado no mesmo filesystem. Os nove existentes usam rename
atômico; os dois novos usam criação atômica exclusiva por hard link do stage
pronto, seguida da remoção do nome temporário. Assim, criar um arquivo novo
simultaneamente não permite sobrescrevê-lo depois da checagem `ABSENT`.

Arquivos existentes mantêm UID, GID, modo e atributos estendidos. O mtime
publicado é uma cópia independente com `max(agora, mtime original + 1 segundo)`,
para que o ColdFusion detecte alteração de template. Os novos recebem
`root:root`, modo `0644`, mtime atual e nenhum atributo herdado do candidato.
Backup e rollback preservam o mtime original. Inode/ctime mudam pela troca
atômica; atime pode mudar por leitura de verificação conforme o filesystem.

Antes de cada troca o script grava e sincroniza a intenção em `state.json` e
reconfere o baseline daquele caminho. Depois da troca sincroniza os diretórios
e registra o resultado. Ao final, verifica os 11 hashes, metadados publicados
e proteções. `operations.jsonl` é o registro operacional sem conteúdo dos
arquivos ou valores de configuração.

`verify` é explícito: em estado `prepared` ou `rolled_back` valida o baseline;
em `published` valida os candidatos publicados. Também valida os backups e
proteções. Estados incompletos ou com conflitos falham, sem concluir sucesso.

## Proteções de escopo

`GUARD_FILES` no script enumera arquivos de Ads/CPC, controle de requisições,
autenticação Business, configuração, endpoint de coleta, SW, dashboard e
`RoadRunners/circuito/index.cfm`. Também inclui os arquivos do release anterior
de classificação de entrega de banners. Esses arquivos nunca são alvos.

`GUARD_TREES` captura inventários e hashes das árvores `config` e `_codex/sql`
dos dois sites e `Business/portal/audiencia/queries`, excluindo somente a nova
consulta autorizada. Presença, ausência e adição/remoção de itens são comparadas.
Configuração opcional ausente fica registrada como ausência. Um link simbólico
encontrado nas proteções interrompe a operação. O script não exibe conteúdo de
configurações e não executa os SQLs. A proteção é a lista e as árvores
explicitadas no script; não é uma auditoria de todo o servidor.
Somente a leitura das proteções aceita arquivos regulares com hard links:
configurações compartilhadas são lidas e conferidas por hash, sem copiar ou
alterar o inode. Uma alteração por outro hard link também altera o hash e
interrompe a publicação. Alvos, candidatos e backups mantêm a exigência de um
único link.

## Falha e rollback

Falha durante publicação, inclusive verificação final, dispara rollback dos
alvos cuja troca foi tentada, em ordem inversa. SIGINT, SIGTERM e SIGHUP também
entram nesse fluxo. SIGKILL, queda do host ou falha física de disco podem impedir
a execução: o journal durável permite executar o modo explícito ao retomar.

```sh
python3 "$release_dir/publish.py" "$release_dir" rollback
python3 "$release_dir/publish.py" "$release_dir" verify
```

Rollback não depende dos candidatos. Confere o backup antes de restaurar cada
existente e só troca um arquivo cujo hash **e metadados** ainda correspondam ao
publicado. Arquivo já igual ao baseline é mantido. Mudança concorrente é
preservada, registrada em `rollbackConflicts`, e a operação retorna erro. Os
novos só são retirados se ainda correspondem ao publicado; seus bytes ficam
guardados em `removed-rollback-*` no release. Nenhuma proteção modificada por
outro escritor é restaurada pelo script.

Conflitos exigem revisão do responsável; não substituir hashes nem usar um
comando de cópia incondicional para forçar o rollback. Uma segunda execução de
rollback é idempotente para os alvos já restaurados. Uma falha de preparação
deixa o runtime intacto e pode deixar backups parciais: use outro diretório de
release, sem reaproveitar a preparação incompleta.

Mantenha uma janela exclusiva de outros publicadores/escritores desses arquivos.
O `flock` protege execuções deste mesmo diretório de release; não trava aplicações
ou outros publicadores. Para os arquivos existentes, os hashes são reconferidos
imediatamente antes do rename, mas POSIX não oferece compare-and-swap por hash:
há um intervalo residual entre leitura e rename que só a exclusão de outros
escritores elimina. A sequência é atômica por arquivo, não uma transação conjunta
dos dois sites. Backups restauram arquivos; não restauram cache da aplicação,
eventos coletados nem qualquer estado de banco.

## Testes locais

```sh
python3 /Users/Shared/Projects/RunnerHub/Business/_codex/staging/live-measurement/release-tools/test_publish.py
```

Os testes importam o módulo com raízes injetadas em diretórios temporários e
UID/GID do processo local. Essa injeção não está disponível na CLI de produção.
Não fazem rede, não leem webroots reais e não exigem root. Cobrem ciclo completo,
baseline e ausência, metadados/mtime, ordem/whitelist, hash, symlink, hard link,
filesystem diferente, tamper de backup, mudanças em proteções/SQL, falha parcial,
concorrência no rollback e na criação do novo arquivo, e rollback idempotente
sem candidato. O resultado executado está em `verification.log`.
