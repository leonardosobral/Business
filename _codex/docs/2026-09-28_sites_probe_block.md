# Bloqueio de sondagens — Business / OpenResults — 28/09/2026

Pedido: aplicar os bloqueios já publicados no RoadRunners aos dois sites, conferindo primeiro se o .htaccess local está sincronizado com produção.

Baseline: Business sem .htaccess na raiz local e de produção; OpenResults com arquivos idênticos (SHA256 99c73881270146b65992b75f01bb309fa3513c047aae60a4314fb3a794d8cfa9), sem mudanças locais prévias no arquivo.

Cada candidato reutiliza somente o bloco de regras de sondagem do RoadRunners e ErrorDocument 403 literal Access denied. OpenResults preserva ErrorDocument 404 /404/ e redirecionamento www. Sem modificação de configuração dos vhosts, autenticação ou beta/dev. Arquivos locais específicos em cada repositório. 81 testes isolados por candidato, com dados sintéticos restritos ao loopback e removidos ao final. Sem acesso ao conteúdo de credenciais reais.

Business publicado: novo .htaccess; manifesto registra a ausência anterior para rollback. Backup/manifesto em /var/backups/business-probe-block-20260928. 46 verificações HTTP na origem/endereço público, com bloqueios 403 e home/JavaScript público preservados. Hash publicado conferido.

OpenResults publicado após confirmação explícita adicional do usuário, requerida pela revisão automática. Backup em /var/backups/openresults-probe-block-20260928/baseline. Hash de produção confere com o candidato local. Verificação direta por HTTPS na origem falhou com curl 60 (validação de certificado); nenhuma validação TLS foi desativada. Verificação no endereço público, com TLS normal, passou: 23 respostas conferidas, incluindo bloqueios 403, home 200 e JavaScript público 200.

Recibos: _codex/staging/sites-probe-block/{business,openresults}. Publicador: _codex/scripts/deploy_sites_probe_block.py <site> <prepare|publish|verify|rollback>. No Business, rollback remove somente o novo arquivo se seu hash ainda coincidir com o candidato; no OpenResults restaura o backup com verificação de concorrência.
