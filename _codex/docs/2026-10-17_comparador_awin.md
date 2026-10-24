# Comparador — Integração Awin no Business

Entrega em 17/10/2026, conta publisher 1455398 (Road Runners).

## Comportamento publicado

O submenu PLATAFORMA → Comparador, já existente com Produtos, Promoções e ofertas e Filtros e cadastros, ganhou Integração Awin em `/administracao/comparador/awin/`.

- Consulta dos programas aprovados e campanhas ativas/futuras do Brasil (ou globais), com busca e filtros por programa, tipo e vigência.
- Atualização manual por administrador autenticado, em POST com CSRF, intervalo mínimo de 60 segundos e exclusão mútua.
- Geração de link de afiliado pela API, com `clickref=comparador`, para programa aprovado.
- Validades calculadas com o offset da origem e exibidas em America/Sao_Paulo. Campanhas vencidas deixam de aparecer mesmo sem nova consulta.
- Cache em arquivo substituído atomicamente somente após consulta completa; falhas preservam o histórico. Erros controlados são apresentados na própria tela.
- Credencial carregada exclusivamente no servidor, fora do webroot e do Git. Campos recebidos da Awin são escapados no HTML.

Não há gravação em catálogo, cupons ou banco de dados. Não foram ativados agendamento, importação de feeds, associação automática campanha/produto ou publicação automática de preços/descontos. O link Abrir catálogo leva à gestão existente para cadastro manual após conferir elegibilidade e condições.

## Contratos e configuração

Base fixa `https://api.awin.com`, Authorization Bearer, sem seguir redirects:

- GET `/publishers/1455398/programmes?relationship=joined`
- POST `/publisher/1455398/promotions`, filtros membership joined, regionCodes BR, status active/upcoming e type all; paginação até 200 registros, máximo de 20 páginas por estado.
- POST `/publishers/1455398/linkbuilder/generate`

ColdFusion pode converter chaves de structs literais para maiúsculas. Os corpos de requisição usam templates JSON desserializados para preservar `regionCodes`, `pageSize`, `advertiserId` e `destinationUrl`, sem alterar as configurações globais da aplicação.

Configuração privada: `/var/lib/runnerhub/business-awin/config.json` (root:colfusion, 0640), campos `publisherId` e `token`. Diretório pai 0750; cache/snapshot.json pertence ao usuário coldfusion, diretório 0700 e arquivo 0600. Não registrar, copiar para fontes ou expor o valor do token.

A chave/link de download do Create-a-Feed é independente do token da API. Um teste do feed aprimorado Nike pt_BR retornou 404; isso não comprova indisponibilidade dos demais feeds. A automação de preço/estoque depende de confirmar o feed disponível e definir correspondência por produto/variante. Promoções genéricas não devem ser convertidas automaticamente em preços finais.

## Arquivos

- `services/ComparadorAwinService.cfc`
- `administracao/comparador/awin/{index,backend,home}.cfm`
- `administracao/comparador/includes/navigation.cfm`
- `includes/estrutura/sidenav.cfm`
- `_codex/tests/comparador/awin.cfm`

Mudanças anteriores nos menus e no restante da gestão foram preservadas. Comparador público não foi alterado nesta entrega.

## Validação

- Compilação ColdFusion 2025: 7/7 fontes, incluindo o serviço de autorização existente.
- 24 testes focados: autorização, acesso delegado, POST/CSRF, URLs, regiões, vínculo do anunciante, datas, ausência de credencial na resposta, preservação do cache em falha e substituição atômica.
- Preview desktop e largura 390 px sem transbordamento horizontal do módulo.
- Produção sem login redireciona; acesso direto aos includes é bloqueado; métodos CFC não são remotos.
- Busca real por Corre retornou uma campanha da Centauro (Corre 4). Captura em `2026-10-17_comparador_awin.png`.
- Gerador testado pela sessão real: link Under Armour retornado com awinmid 18864, awinaffid 1455398, clickref comparador e destino preservado.
- Atualização pela sessão real de administrador concluída às 16:06 de Brasília: 10 programas, 38 campanhas vigentes e 0 futuras. Nenhum voucher na consulta observada.

## Publicação e recuperação

Runtime publicado com conferência dos hashes anteriores, backup recuperável e verificação posterior. Recibos em `2026-10-17_comparador_awin_release_initial.json` e `2026-10-17_comparador_awin_release.json`.

Backups no servidor:
- `/var/backups/business-awin-20261017/20261017T185900Z-a7100010`
- `/var/backups/business-awin-20261017/20261017T190451Z-a7100010`

Antes de recuperar, conferir se os arquivos atuais ainda correspondem aos hashes after do recibo. A segunda publicação contém a correção de serialização; para remover toda a entrega, restaurar os originais do primeiro backup e remover apenas os quatro arquivos novos do recibo. Preservar alterações posteriores de outras frentes. Não remover config/cache para um rollback apenas de runtime. Nenhuma migração ou alteração de dados precisa ser desfeita.

Documentação oficial consultada:
- https://help.awin.com/apidocs/api-authentication
- https://help.awin.com/apis/apidocs/promotions
- https://help.awin.com/apidocs/get-program-information
- https://help.awin.com/apidocs/generatelink
- https://help.awin.com/developers/docs/product-feed-list-download
