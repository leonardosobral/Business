# Restauração do storage de percursos — 13/10/2026

## Causa e escopo

O servidor atual não possuía `/var/lib/roadrunners/percursos`, caminho ainda configurado tanto no Business (`config/percursos.local.cfm`) quanto no RoadRunners (`config/mapbox.local.cfm`). Os arquivos estavam preservados no servidor anterior, `172.233.26.63`. O storage externo ao webroot ficou ausente após a migração.

O Business tentava criar a pasta sob `/var/lib`, sem autorização do sistema operacional. O endpoint público de geometria retornava `503 storage_unavailable` porque não encontrava a raiz de armazenamento.

O usuário autorizou explicitamente restaurar os 257 arquivos, com backup e acesso restrito ao ColdFusion. Não houve alteração de código de runtime, configuração dos sites, banco de dados, autenticação, nem reinício de serviços.

## Execução e recuperação

- Origem: `/var/lib/roadrunners/percursos` no servidor anterior; dados de origem preservados.
- Destino: o mesmo caminho em `ssh.runnerhub.run`.
- 257 arquivos, cerca de 12 MB, conferidos individualmente por SHA-256 antes e depois da cópia.
- Conteúdo preparado em diretório temporário e ativado por rename, recusando sobrescrever um destino existente.
- Proprietário do storage restaurado: `coldfusion:coldfusion`; diretórios `0750`, arquivos `0640`. A instância antiga rodava como `nobody`; a nova roda como `coldfusion`.
- Backup privado: `/var/backups/percursos-storage-20261013/percursos.tar.gz`.
- Manifesto: `/var/backups/percursos-storage-20261013/source-sha256.json`.
- Relatório remoto: `/var/backups/percursos-storage-20261013/restoration.json`.
- Ferramenta local: `_codex/staging/percursos-storage-20261013/restore_storage.py`; execução única, recusa destino/backup existentes.

Se necessária recuperação posterior, preservar primeiro quaisquer arquivos novos ou modificados no destino; não sobrescrever cegamente com o snapshot de 13/10. O servidor anterior permanece como segunda cópia dos dados originais.

## Validação real

- URL relatado: `/evento/2027-maratona-internacional-de-floripa-fibra-2027/?route_geometry=1&id_evento_percurso=68665&arquivo=32&rev=8fb4609632d2`.
- Antes: HTTP 503, `storage_unavailable`.
- Depois: HTTP 200, `application/geo+json`, 15.809 bytes, aproximadamente 0,09 s na amostra, Feature/LineString com 564 coordenadas, percurso 1 versão 10.
- Leitura dos 257 arquivos e criação/leitura/remoção de arquivo de teste passaram executando como `coldfusion`.
- Página autenticada `https://business.roadrunners.run/percursos/` recarregada no Chrome: alerta de storage desapareceu e “Novo percurso” voltou a aparecer.

## Próxima migração

Incluir explicitamente este storage persistente, separado do webroot, no inventário de cópia e backup. Conferir hashes e usuário efetivo do serviço antes do corte. Validar uma geometria pública e a página administrativa após a troca.
