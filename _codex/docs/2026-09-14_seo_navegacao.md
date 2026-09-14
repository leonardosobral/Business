# Separação de SEO e Conteúdo — 14/09/2026

Pedido: separar menu e cabeçalho, pois SEO e conteúdo já têm funções próprias.

Publicado às **10:57:52 (Brasília)**:

- **SEO:** `/portal/seo/`, menu administrativo “Marketing e audiência”, item SEO. Cabeçalho SEO e título de navegador próprio. Os dois filtros enviam para essa rota.
- **Conteúdo das provas:** `/portal/conteudo/`, menu “Conteúdo e portal”. Cabeçalho e título próprios; sem abas compartilhadas com SEO.
- `/portal/conteudo/?visao=seo` redireciona após autenticação para a nova rota, preservando somente valores permitidos de site, prioridade e verificação. Não repassa query arbitrária nem dados de sessão.
- Os templates internos de relatório permanecem reutilizados em `portal/conteudo/seo.cfm` e `seo_report.cfm`; mudança de navegação sem duplicar o cálculo, a fila ou o snapshot.

Sete arquivos de runtime publicados. Backup: `/var/backups/seo-navigation-Business-h7rbayhl`. Recibo e hashes: `2026-09-14_seo_navegacao_publicacao.json`. Evidências: `/Users/Shared/RunnerHubReports/seo/navigation-20260914`.

A versão local do head continha uma atualização anterior de cache do CSS de Pesquisas (`20260824-8`), enquanto a produção usava `20260824-7`. O pacote alterou somente o título sobre o baseline de produção, mantendo a versão7 em produção e a versão8 local. Nenhum CSS alheio foi publicado. Login, autorização e os quatro arquivos de dados/backend SEO tiveram os hashes preservados.

Validação: seis testes existentes do menu, dois cenários CFML de renderização/filtro e compilação de sete templates no Adobe ColdFusion. No navegador autenticado, o link antigo preservou os três filtros, cada página destacou somente seu próprio item do menu, e os cabeçalhos não exibiram abas compartilhadas. Conferidos desktop e mobile390, sem rolagem horizontal; navegação por menu e envio do filtro de erros permaneceram em `/portal/seo/`.

O cliente HTTP não autenticado recebeu403 nas três rotas, sem exposição dos dados. Esse resultado não distingue bloqueio de borda do guard da aplicação. A sessão administrativa real funcionou nas duas telas. Não foram alteradas permissões nem o código de autenticação.

Para recuperar, conferir os hashes do recibo e restaurar os seis arquivos existentes do backup; só remover o novo `/portal/seo/index.cfm` após restaurar o menu e o endpoint legado e verificar ausência de dependências novas. Não sobrescrever mudanças concorrentes. Sem commit, branch ou push.
