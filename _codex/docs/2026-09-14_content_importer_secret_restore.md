# Restauração do segredo de importação do Conteúdo

## Incidente e causa confirmada

Job 3, **Conteúdo Corrida No Ar**, retornava HTTP 500 / `misconfigured` / `IMPORTER_HANDOFF_SECRET não configurado.`. Último sucesso antes do incidente: 13/09/2026 23:01; primeira falha no histórico: 14/09/2026 00:02 (America/Sao_Paulo).

O serviço cf2023 iniciou em 14/09/2026 02:09 UTC (13/09 23:09 em São Paulo). A variável `IMPORTER_HANDOFF_SECRET` não estava presente no processo Java e `/var/www/conteudo.roadrunners.run/config/content.local.cfm` não existia. O Business ainda possuía a referência `cronSecrets.conteudo_internal` preenchida. Nenhum valor de credencial foi exibido ou copiado para este repositório.

## Alteração autorizada

Após aprovação expressa do usuário, foi criado somente o arquivo de configuração do Conteúdo com `importerHandoffSecret`, reutilizando o segredo existente do Business. Nenhuma chave foi gerada ou rotacionada. Proprietário/permissões equivalentes ao arquivo protegido do Business: `nobody:nogroup`, `0640`.

Aplicação de Conteúdo recarregada pelo ponto existente `reset.cfm`, sem reiniciar o serviço ColdFusion nem as demais aplicações. O primeiro cliente HTTP foi recusado; a recarga pela mesma URL pública usando curl retornou HTTP 200. Nenhuma regra de acesso foi alterada e não foi usado acesso direto à origem para contornar o proxy.

Registro recuperável da ausência anterior e candidato protegido no servidor: `/var/backups/content-importer-secret.Zo5F4h/`. Script sem segredos no repositório: `_codex/scripts/restore_content_importer_secret_20260914.py`. A restauração recusa sobrescrever configuração existente. Não reexecutar o modo `restore` sobre o ambiente já corrigido.

## Validação

- Sem autenticação: HTTP 401 / unauthorized.
- Assinatura incorreta: HTTP 401 / unauthorized.
- Assinatura correta com JSON `[]`: HTTP 400 / invalid_body; prova a passagem pelo HMAC sem chegar à importação. Timestamp do teste alinhado ao formato local utilizado pelo runner do Business, não a epoch UTC.
- Job 3 executado manualmente pelo painel em **14/09/2026 07:22:02**: **success, HTTP 200 OK, 794 ms**.
- Resultado: 10 processados, 1 criado, 1 atualizado, 8 duplicados/ignorados, 0 erros. Preservado o body `{"import_status":"review"}`.
- Agendamento permaneceu ativo com intervalo de 60 minutos. Próxima execução indicada após o teste: 08:22. Nenhuma execução de outro job foi disparada manualmente.
- Falhas anteriores permanecem no histórico como auditoria; não foram apagadas.

## Persistência e cuidados

O Application.cfc já carrega a chave do arquivo local como alternativa ao ambiente. Preservar `config/content.local.cfm` em futuras publicações e backups; não sincronizar uma pasta `config` vazia com exclusão de arquivos remotos. O mesmo segredo participa de outras integrações do Conteúdo e da proteção de credenciais cifradas: não gerar um novo valor para corrigir apenas ausência de carregamento.

Rollback operacional deve ser coordenado: o estado anterior era configuração ausente e importações bloqueadas. Restaurar esse estado desativaria novamente a integração. Não fazer rollback por sobrescrita de todo o diretório ou por reinício global.
