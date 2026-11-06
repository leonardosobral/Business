# Backups de produção movidos para armazenamento offline — 05/11/2026

Servidor web: `172.233.2.76` (`rr-prod`, `ssh.runnerhub.run`). Diretório original: `/var/backups`.

Destino privado e permanente na máquina do usuário: `/Users/geraldoprotta/Backups/RunnerHub/172.233.2.76/2026-11-05`.

Foram preparados dois archives, cobrindo 2447 itens de raiz existentes nos inventários. Cada arquivo foi conferido por SHA-256 e metadados; duas amostras foram restauradas e verificadas. Os originais só foram liberados após a verificação da cópia e reconferência de cada origem. Mudanças concorrentes interrompem a remoção.

- `geocoding-test-evidence/old-geocoding-test-evidence.tar.gz` — SHA-256 `9ddbf114e5d43c7abe9cd7b7183824f3282b9d21d657805434f9ff41b47e8fc4`.
- `var-backups/var-backups.tar.gz` — SHA-256 `be978607a91cc05f90434811e446c1c8cf68d02161b86491966ae0d59a7cfa2f`.

A documentação de restauração fica no `README.md` da pasta offline; o índice detalhado está em `offline-backups-index.json`. No servidor, a mudança é registrada por `/var/backups/OFFLINE-BACKUPS.md` e `/var/backups/offline-backups-index.json`, com acesso restrito. Os arquivos de backup não foram adicionados ao Git.

Esta é uma migração pontual, sem agendamento de novas transferências. Não recupera evidências antigas de testes removidas antes do inventário, incidente já comunicado ao usuário. Novos backups poderão surgir no servidor após a migração.

O resultado final de espaço, inventário e teste multipart está em `_codex/deploy/offline-backups-20261105.json`.

Resultado final: nenhum backup do inventário permaneceu online. `/var/backups` passou a ocupar 452 KiB, apenas com o aviso e o índice. O disco de 20 GiB ficou com aproximadamente 414 MiB disponíveis (98% de ocupação). O rsyslog estava ativo. Um POST multipart sintético de 1 MiB ao endpoint real de percursos alcançou a proteção normal de login (302), sem `No space left on device`; não houve autenticação nem criação de percurso de teste.
