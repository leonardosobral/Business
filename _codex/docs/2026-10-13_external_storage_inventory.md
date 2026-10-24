# Dependências fora de /var/www — diagnóstico em 13/10/2026

Inspeção somente leitura dos caminhos literais de runtime em `/var/www`, referências a `getTempDirectory()`, links simbólicos e variáveis de caminho do processo ColdFusion, comparando servidor antigo `172.233.26.63` e atual `ssh.runnerhub.run`. Nenhum armazenamento, configuração ou permissão foi alterado neste diagnóstico. Segredos não fazem parte dos artefatos do inventário.

## Achados

| Caminho | Consumidor | Antigo | Atual / impacto |
| --- | --- | --- | --- |
| `/var/lib/roadrunners/percursos` | Business e RoadRunners, arquivos GPX/GeoJSON | Presente | Restaurado na tarefa anterior, 257 arquivos conferidos; leitura/escrita validada |
| `/var/lib/runnerhub/reports/mif-2026` | Business, relatório privado da Maratona de Floripa | Presente, cerca de 28 MB | Ausente. `relatorios/maratona-floripa-2026/includes/data.cfm` exige `manifest.json` e datasets validados por hash; aborta com 503 se ausentes. Não foi encontrada variável de runtime `MIF_REPORT_DATA_ROOT` substituindo esse caminho |
| `/etc/roadrunners/credentials/medical-mail.json` | RoadRunners, `MedicalConfirmationMailer`, herdado por `TrainingConfirmationMailer` | Presente | Ausente. O leitor padrão do componente depende diretamente deste arquivo; `available()` retorna false na falha de leitura. Não foi disparado e-mail nem comprovada uma tentativa real de envio nesta auditoria |
| `/var/lib/runnerhub-secrets/content-google-oauth.local.cfm` | Conteúdo, fallback Google OAuth | Presente | Ausente. Os três campos Google OAuth estão preenchidos em `config/content.local.cfm` no servidor atual. Não concluir falha de login por ausência do fallback; validade das credenciais e sobreposições do banco não foram testadas |
| `/var/log/apache2/api.roadrunners.run-telemetry.log` | Business, monitor de API | Presente | Presente, root:adm 0640, mas `os.access(..., R_OK)` executado como `coldfusion` retorna false. Configuração aponta para este log. Não foram alteradas permissões |

## Diretórios operacionais

`/opt/coldfusion2025/cfusion/logs` e `/opt/coldfusion2025/cfusion/tmpCache` existem e permitem leitura/escrita ao usuário do serviço. Diversos módulos usam `getTempDirectory()` para processamento transitório de uploads, exportações e importações. Não se deve copiar cegamente todo o temporário antigo como se fosse armazenamento persistente.

A referência `/home/www/site.clubetumtum.com.br/root/assets/img/produtos/quadrada` do comparador legado já estava ausente no servidor antigo; não é evidência de regressão desta migração. Referências de testes, URLs `/data/...` e binários candidatos do crawler foram separadas de dados persistentes. Node e Chromium não foram encontrados nos caminhos literais candidatos em nenhum dos dois servidores; isso não prova uma regressão nova nem exclui configuração alternativa.

## Escopo e limites

Inventário estático amplo com verificações de existência e permissões específicas, não uma homologação completa de cada aplicação. A busca excluiu dependências, assets, cópias de staging e arquivos maiores que 2 MB. Caminhos construídos dinamicamente, configurações armazenadas no banco e integrações remotas podem exigir inspeção adicional. Os resultados estruturados estão em `_codex/staging/external-storage-20261013/{current,old}.json` e o coletor em `inventory.py`.

Próxima intervenção indicada: restaurar os datasets do relatório, tratar a credencial privada de e-mail com autorização específica e ajustar somente o acesso necessário ao log de telemetria, incluindo a política de rotação para não perder a leitura novamente. Não executar cópia ampla de `/etc`, `/var/lib` ou `/tmp`.

## Execução autorizada posteriormente — 13/10/2026

Após o usuário responder “prossiga”, foram restaurados os três caminhos ausentes: 167 arquivos do relatório (166 artefatos e manifesto) e os dois arquivos privados de configuração. Todos os 169 arquivos conferidos por SHA-256 com a origem. Destinos inexistentes foram exigidos antes da cópia; nenhum arquivo existente foi sobrescrito. Dados de origem preservados. Arquivos root:coldfusion 0640 e diretórios privados 0750.

Backup privado no servidor atual: `/var/backups/external-storage-20261013/`, com `private-assets.tar.gz`, manifesto de hashes e relatório. Os segredos não foram gravados em arquivos locais da tarefa nem impressos pela rotina de restauração.

Telemetria: ACL de passagem para coldfusion em `/var/log/apache2`, e apenas leitura no arquivo `api.roadrunners.run-telemetry.log`. Sem inclusão do serviço no grupo adm e sem acesso aos demais logs. `/usr/local/sbin/runnerhub-telemetry-acl` reaplica as ACLs; o hook foi incluído em `postrotate` de `/etc/logrotate.d/apache2`. Baseline do arquivo de configuração e das ACLs em `.../telemetry/`. `logrotate --debug /etc/logrotate.conf` passou; teste sintético de troca do inode e reaplicação da leitura passou. Nenhuma rotação forçada nem reinício foi executado.

Validações:

- Relatório real aberto no Chrome autenticado, com métricas e gráficos renderizados.
- Diagnóstico CFML temporário, restrito a loopback e removido ao final: 166 artefatos do manifesto válidos por tamanho e hash; credenciais disponíveis nos componentes MedicalConfirmationMailer e TrainingConfirmationMailer; fallback OAuth legível e configuração efetiva de arquivo preenchida; log de telemetria legível.
- Nenhum e-mail enviado, nenhum fluxo OAuth externo executado e nenhuma mutação de banco realizada.
- Monitor real abre sem erro de leitura. Entretanto, o arquivo atual tem zero bytes, e a tela tem somente linhas históricas fora da janela.

### Pendência distinta: origem da telemetria

O Apache atual não contém referências a `api.roadrunners.run`/telemetria em `sites-enabled` ou `conf-enabled`. O servidor anterior mantém o VirtualHost da API e seu `CustomLog` dedicado; seu log contém dados recentes (186.697 bytes na amostra). O endpoint público `/v1/discovery/runner-apps.cfm` respondeu HTTP 200. Corrigir acesso ao arquivo local não transporta o tráfego de outro servidor. Integrar a coleta entre servidores ou migrar a operação da API é um escopo distinto das restaurações de arquivos e ACLs realizadas. Não afirmar que o monitor está recebendo tráfego novo no servidor atual.

Para rollback das ACLs, usar os textos registrados em `telemetry/acl-before.json`; restaurar `apache2.before` apenas se não houver mudanças posteriores e remover o hook/helper desta tarefa. Para os dados privados, preservar novas alterações antes de qualquer rollback; não substituir cegamente por snapshot antigo.
