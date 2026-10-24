# Release LIVE — 20/10/2026

Infraestrutura preparada e testada somente em diretórios temporários locais. Não houve SSH, compilação remota, preparação remota ou publicação nesta etapa. O pacote de candidatos permanece sob responsabilidade do operador.

## Escopo e ordem

`publish.py` permite somente estes 12 arquivos, na ordem abaixo. Aceita um subconjunto não vazio e ordenado, sem duplicatas; `build_manifest.py` exige os 12 por padrão para evitar omissões acidentais. Usar `--allow-subset` apenas após revisar as dependências do subconjunto.

1. RoadRunners `assets/js/rr-live-funnel-ui.js` — novo, exige ABSENT.
2. RoadRunners `evento/parts/live_coupon.cfm` — novo, exige ABSENT.
3. Business `portal/audiencia/queries/live_journey.sql`.
4. Business `portal/audiencia/queries/content.sql`.
5. Business `portal/audiencia/live_journey.cfm`.
6. RoadRunners `services/AudienceMeasurementService.cfc`.
7. RoadRunners `assets/js/rr-audience.js`.
8. RoadRunners `assets/js/rr-audience.min.js`.
9. RoadRunners `includes/card_evento_live.cfm`.
10. RoadRunners `circuito/live_highlight.cfm`.
11. RoadRunners `evento/index.cfm`.
12. RoadRunners `includes/analytics/bootstrap.cfm`.

Os arquivos novos são instalados antes de ativar referências. As consultas/view Business precedem os produtores. O serviço e os trackers precedem a ativação final do bootstrap. Raízes remotas permanecem fixas: `/var/www/roadrunners.com.br` e `/var/www/business.roadrunners.run`.

## Montagem e uso pelo operador

Na pasta `live-funnel-20261020`, montar `release/candidate/{RoadRunners,Business}/<caminho relativo>`, copiando exclusivamente candidatos revisados. Não incluir testes, documentos, arquivos de configuração ou SQL de migração.

```sh
python3 build_manifest.py
python3 compile_private.py
python3 release_remote.py prepare
python3 release_remote.py verify
python3 release_remote.py publish
python3 release_remote.py verify
```

Esses comandos são exemplos para execução deliberada pelo operador; não foram executados nesta preparação. `build_manifest.py` é local e não escreve candidatos/baselines. Usa os bytes de `production-baseline` e confere os hashes com `baseline.json` e `baseline-extra.json`. Cria `release/runtime.tsv` com abertura exclusiva e falha se já existir. Novos arquivos recebem o contrato esperado `ABSENT`; isso não afirma que houve observação remota da ausência. **O `prepare` remoto comprova ausência real de ambos e confere todos os baselines antes de permitir publicação.** Se algum novo arquivo já existir, para sem modificar runtime.

O TSV não tem cabeçalho e cada linha contém `site<TAB>path<TAB>beforeSHA/ABSENT<TAB>afterSHA`. Não editar manifest/candidatos depois do prepare; uma alteração exige novo diretório privado e nova revisão do pacote. O recibo existente impede preparação automática duplicada. O modo publish exige estado preparado e fresco.

`compile_private.py` valida manifest e SHA locais, transfere um tar com nomes exatos e verifica novamente os hashes no servidor antes de compilar em `/var/tmp/rr-live-funnel-compile.*`. Usa o compilador Adobe como `nobody`; não executa os templates nem escreve nos webroots. A contagem de entradas deriva do manifest, e a compilação devolve log, código de saída e número de arquivos.

`release_remote.py` transfere para `/var/backups/rr-live-funnel.<sufixo>`, privado `0700`. Confere hashes do manifest e do publicador. Cada chamada remota é explícita. Os wrappers conservam verificação estrita de host SSH; importá-los não executa rede. Logs locais incluem recibos/resultados JSON; não contêm conteúdos de candidatos ou configurações, exceto diagnósticos emitidos pelo compilador.

## Proteções preservadas e ajustes revisados

O núcleo de backup/troca/rollback permanece o do publicador anterior. Exige root e release root-owned `0700`; recusa symlinks em componentes, hard links de alvos/candidatos/backups e filesystem diferente. `prepare` cria backups completos e metadados, reconfere tudo e não troca runtime. `publish` reconfere todos os alvos/backups/guards, grava intenção durável antes de cada troca e verifica resultado. Existentes usam rename atômico; novos usam criação exclusiva por hard link e não sobrescrevem arquivo surgido após checagem de ausência. UID/GID/modo/xattrs são preservados; mtime dos existentes avança para invalidar o cache de templates.

As proteções anteriores de config, autenticação, Ads, SW, endpoint coletor e árvores `_codex/sql` permanecem. O inventário de `Business/portal/audiencia/queries` passa a excluir **somente arquivos efetivamente selecionados no manifest**, permitindo as duas consultas autorizadas e detectando alterações nos demais SQLs. Um alvo permitido omitido do manifest vira guard explícito, inclusive sua ausência. Arquivos que eram alvos do release anterior e saíram deste escopo (home/backend Business, modal de cupom legado e duas partials do evento) também viraram guards explícitos.

Contagens e journal agora derivam dos alvos selecionados. A validação de índices do journal usa o tamanho do manifest, impedindo referência a um caminho permitido que foi omitido.

## Recuperação e limites

```sh
python3 release_remote.py rollback
python3 release_remote.py verify
```

Falha durante troca/verificação dispara rollback reverso. O rollback não depende dos candidatos e só restaura arquivos ainda iguais ao publicado em hash **e metadados**. Mudanças concorrentes são preservadas e reportadas como conflito. Novos removidos ficam em quarentena no release. Backups e estado devem permanecer disponíveis.

Manter uma janela exclusiva de outros publicadores: `flock` cobre este diretório de release, não todos os escritores do servidor. Há intervalo residual entre checagem e rename de arquivos existentes; a atomicidade é por arquivo, não uma transação dos 12 arquivos. Interrupção abrupta, SIGKILL ou timeout pode exigir recuperação explícita pelo journal. O rollback não desfaz cache ou eventos coletados. A verificação por hash não substitui a verificação final de HTTP/UI e métricas reais. Nenhuma ferramenta aqui executa migração ou SQL de negócio.

## Validação local

```sh
python3 -m unittest discover -s release-tools -p 'test_*.py'
python3 -m py_compile build_manifest.py compile_private.py release_remote.py release_support.py release-tools/publish.py
```

24 testes de filesystem/pacote: preservação de metadados e ausência, whitelist/ordem/duplicatas, subset e guards de omitidos, journal inválido, baseline e candidato alterados, symlink/hardlink, filesystem distinto, backup alterado, proteção de SQL, falha parcial, conflitos, concorrência na criação, rollback idempotente sem candidato, manifest exclusivo e imports sem rede. Só diretórios temporários locais são usados.
