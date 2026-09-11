# Audiência — inventário e backup RoadRunners

Em 07/09/2026 foi concluído o passo de inventário e backup privado dos alvos RoadRunners de produção, conforme a orientação do usuário de prosseguir etapa por etapa. Este registro não representa publicação nem ativação da coleta.

## Escopo e resultado

Servidor: `ssh.runnerhub.run`. A raiz `/var/www/roadrunners.com.br`, sem symlink, foi confirmada nos vhosts Apache de `roadrunners.run` e `www.roadrunners.run`. Somente essa raiz de produção foi inventariada; beta/dev não foram alterados.

Os [31 caminhos runtime](2026-09-07_audience_roadrunners_runtime_files.txt) são únicos e correspondem exatamente à seção RoadRunners do [manifesto local](2026-09-07_audience_release_manifest.json). Os 31 arquivos locais existem e seus hashes conferem com o manifesto. No servidor:

| Classificação | Quantidade |
| --- | ---: |
| Existentes, iguais à base do manifesto | 5 |
| Existentes, diferentes da base e do candidato | 14 |
| Ausentes | 12 |
| Total inventariado | 31 |

Os 19 arquivos existentes foram arquivados. A lista não inclui arquivos privados, testes, fixtures, `.env` ou configurações `.local`; `config/settings.cfm` integra o runtime compartilhado. O backup preserva o conteúdo que estava no servidor, independentemente de corresponder ao candidato local. As 14 diferenças ainda precisam de reconciliação antes de preparar uma publicação.

## Recibo verificado

- Captura: `2026-09-07T20:39:02.766608+00:00`.
- Diretório: `/var/backups/roadrunners-audience-20260907.qko32783`, `0700`, `root:root`.
- Arquivo: `/var/backups/roadrunners-audience-20260907.qko32783/before.tar.gz`, `0600`, `root:root`, 154.556 bytes.
- SHA-256 do arquivo: `5035a71b74d125dc6dc54dfc029b8ba500f75faaa337f1dc9b9337f107333ab3`.
- Recibo remoto: `/var/backups/roadrunners-audience-20260907.qko32783/receipt.json`, `0600`, `root:root`, 6.898 bytes.
- Recibo local da execução: `/private/tmp/rr-audience-backup-step.DWkv1j/backup-receipt.json`.

O executor confirmou que o inventário não mudou antes da criação do arquivo. Conferiu os 19 membros exatos, SHA-256 do conteúdo, tamanho, modo, UID/GID e mtime; comparou novamente os 31 alvos vivos e confirmou que permaneceram inalterados. Uma verificação independente posterior confirmou hash, tamanho e permissões do backup e executou GNU tar `--compare --gzip` contra a raiz de produção: saída 0, sem diferenças.

O helper operacional foi revisado antes do uso; SHA-256 `d5d9541a4a34da1bb3d159a78eb1f4ed6879cbb92e65665545876714cf293bd7`. A execução utilizou a mesma versão revisada. O backup e seu recibo estão fora da raiz pública.

## Limites e próxima etapa

Esta etapa não publicou arquivos runtime, não ativou coleta, não acessou o banco, não executou DDL, não instalou cron/agenda, não reiniciou/recarregou serviços e não alterou permissões existentes. Os modos privados acima são dos novos artefatos de backup. Nenhum código de autenticação ou configuração global do Business foi alterado.

A confirmação dos objetos de audiência na base `runnerhub` veio do operador via DataGrip, antes deste backup, e está registrada em [estado atual e gates](2026-09-07_audiencia_publicacao.md). Ela não constitui execução de banco por este helper. `runner_dba` permanece intocado por determinação explícita do usuário. Retenção executada, agenda instalada, coleta ativa e métricas reais não foram comprovadas.

O próximo passo de arquivos é revisar as diferenças dos 14 alvos existentes e a criação dos 12 ausentes, com este backup como referência. Este registro não autoriza restauração automática nem sobrescrita de alterações posteriores. O recibo JSON histórico da publicação Business foi preservado.
