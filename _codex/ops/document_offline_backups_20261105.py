"""Document the verified offline archives, without copying any backup contents to Git."""
from pathlib import Path
import json,os,datetime,hashlib
root=Path('/Users/geraldoprotta/Backups/RunnerHub/172.233.2.76/2026-11-05');project=Path(__file__).resolve().parents[2]
archives=[];mapping={}
for folder,key in [('geocoding-test-evidence','directories'),('var-backups','sources')]:
 m=json.loads((root/folder/'verified-manifest.json').read_text());archive=Path(m['archive_local_path']);count=sum(map(len,m[key].values()))
 entry={'name':folder,'archive_local_path':str(archive),'archive_sha256':m['archive_sha256'],'archive_bytes':archive.stat().st_size,'top_level_items':len(m[key]),'verified_members':count,'manifest_local_path':str(root/folder/'verified-manifest.json')};archives.append(entry)
 for name in m[key]:
  if name in mapping:raise RuntimeError('Duplicate backup mapping')
  mapping[name]={'archive':folder,'member':name}
index={'version':1,'date':'2026-11-05','server_ipv4':'172.233.2.76','ssh_alias':'rr-prod','original_directory':'/var/backups','storage_mode':'offline','local_root':str(root),'archives':archives,'items':mapping,'verification':'All members and file SHA-256 verified; two sample files restored and checked. Sources rechecked before removal.','scope':'Items present in the captured inventories. Does not recover earlier deleted test evidence.','new_backups':'New backups created after this migration may remain on the server.'}
(root/'offline-backups-index.json').write_text(json.dumps(index,ensure_ascii=False,indent=2)+'\n');os.chmod(root/'offline-backups-index.json',0o600)
sums=''.join(a['archive_sha256']+'  '+str(Path(a['archive_local_path']).relative_to(root))+'\n' for a in archives);(root/'SHA256SUMS').write_text(sums);os.chmod(root/'SHA256SUMS',0o600)
readme=f'''# Backups offline — servidor 172.233.2.76

Migração de 05/11/2026, autorizada pelo usuário para liberar espaço do servidor web de produção. Origem: `/var/backups`; acesso: `rr-prod` / `ssh.runnerhub.run`.

Destino permanente na máquina de Geraldo:

`{root}`

Os arquivos ficam fora do repositório Git. Pasta privada (0700), arquivos de backup e manifestos (0600). Os archives preservam conteúdo, diretórios, links, modos e IDs originais de proprietário/grupo; os manifestos guardam os hashes dos arquivos.

| Archive | Itens na raiz original | Entradas verificadas | Tamanho compactado |
|---|---:|---:|---:|
'''+''.join(f"| `{Path(a['archive_local_path']).relative_to(root)}` | {a['top_level_items']} | {a['verified_members']} | {a['archive_bytes']/1048576:.1f} MiB |\n" for a in archives)+'''
`offline-backups-index.json` associa cada nome original ao archive e ao caminho interno. `verified-manifest.json`, dentro de cada subpasta, contém os hashes e os metadados detalhados. `restore-check/result.json` registra a restauração de duas amostras com conferência de hash.

## Verificar as cópias

No Terminal da máquina que guarda os arquivos:

```sh
cd "/Users/geraldoprotta/Backups/RunnerHub/172.233.2.76/2026-11-05"
shasum -a 256 -c SHA256SUMS
```

## Restaurar um backup específico

1. Consulte o índice para descobrir qual archive contém `NOME_DO_BACKUP`.
2. Confirme espaço no destino e ausência de arquivos que seriam sobrescritos. Restaurar um backup não significa publicar automaticamente seu conteúdo.
3. Como o alias `rr-prod` usa root, a extração seletiva abaixo preserva os IDs e modos originais no servidor. Substitua o nome do backup e o caminho do archive conforme o índice:

```sh
ssh rr-prod 'tar -xzpf - -C /var/backups --same-owner --same-permissions "NOME_DO_BACKUP"' < "/Users/geraldoprotta/Backups/RunnerHub/172.233.2.76/2026-11-05/var-backups/var-backups.tar.gz"
```

A transferência é por streaming: não cria uma segunda cópia do archive comprimido no disco do servidor. Extraia apenas o backup necessário. Para evidências geocoding, use o archive da subpasta `geocoding-test-evidence`.

## Registro no servidor e continuidade

- `/var/backups/OFFLINE-BACKUPS.md`: aviso de mudança para backup offline e localização destas instruções.
- `/var/backups/offline-backups-index.json`: índice dos backups e hashes dos archives.
- Esta migração é pontual. Backups novos poderão voltar a ser criados no servidor; os nomes presentes no índice indicam quais foram movidos.
- As cópias dependem da disponibilidade desta máquina para restauração.
- O escopo cobre os itens presentes nos inventários desta migração. As evidências históricas de testes removidas por engano na tentativa anterior, já informadas ao usuário, não foram recuperadas por esta cópia.
'''
(root/'README.md').write_text(readme);os.chmod(root/'README.md',0o600)
summary=f'''# Backups de produção movidos para armazenamento offline — 05/11/2026

Servidor web: `172.233.2.76` (`rr-prod`, `ssh.runnerhub.run`). Diretório original: `/var/backups`.

Destino privado e permanente na máquina do usuário: `{root}`.

Foram preparados dois archives, cobrindo {len(mapping)} itens de raiz existentes nos inventários. Cada arquivo foi conferido por SHA-256 e metadados; duas amostras foram restauradas e verificadas. Os originais só foram liberados após a verificação da cópia e reconferência de cada origem. Mudanças concorrentes interrompem a remoção.

'''+''.join(f"- `{Path(a['archive_local_path']).relative_to(root)}` — SHA-256 `{a['archive_sha256']}`.\n" for a in archives)+'''
A documentação de restauração fica no `README.md` da pasta offline; o índice detalhado está em `offline-backups-index.json`. No servidor, a mudança é registrada por `/var/backups/OFFLINE-BACKUPS.md` e `/var/backups/offline-backups-index.json`, com acesso restrito. Os arquivos de backup não foram adicionados ao Git.

Esta é uma migração pontual, sem agendamento de novas transferências. Não recupera evidências antigas de testes removidas antes do inventário, incidente já comunicado ao usuário. Novos backups poderão surgir no servidor após a migração.

O resultado final de espaço, inventário e teste multipart está em `_codex/deploy/offline-backups-20261105.json`.
'''
(project/'docs/operations/2026-11-05-offline-server-backups.md').write_text(summary)
print(json.dumps({'ok':True,'offline_root':str(root),'items':len(mapping),'archives':len(archives)}))
