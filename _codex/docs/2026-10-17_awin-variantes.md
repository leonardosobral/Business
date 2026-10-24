# Variantes e imagens Awin

Os três serviços de integração passaram a conservar gênero, cor, foto e logo das ofertas e campanhas. Contrato V1 aditivo: `variantOffers` contém SKUs completos por gênero/cor/foto, enquanto o pai e a chave de bloqueio loja:produto permanecem compatíveis com a gestão. `programmes.logoUrl` e os logos das campanhas vêm da API, com validação por anunciante. Fingerprints de campanhas não mudaram.

Publicado em 17/10/2026, release `20261017T222940Z-d2910071`, seguido de importação autenticada às 19:30 BRT: 97 vínculos/65 produtos, 1.858 variantes com foto/logo, seis feeds concluídos e 26 campanhas com logo. Bloqueios e regras de campanhas preservados; sem migração de banco.

Teste privado `comparador-awin-variantes.cfm`: 80 verificações aprovadas no CF2025. Requer aplicação isolada bloqueada a loopback, com mapping `/services` para cópias dos serviços candidatos; testa CSV sintético e não publica dados. Não instalar a fixture no Business público. Recibos detalhados nos JSONs adjacentes.

A documentação completa do consumidor, regra M/F/U e desconhecido, allowlist de fotos, testes e implantação fica em `../Comparador/codex/docs/2026-10-17_awin-variantes.md`. Backups recuperáveis em `/var/backups/awin-variant-offers-20261017/business/20261017T222940Z-d2910071`; conferir hashes antes de rollback e preservar bloqueios, histórico e confirmações recentes.
