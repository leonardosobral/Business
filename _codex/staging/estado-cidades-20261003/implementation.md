# Filtro de cidade nas páginas de estado — 03/10/2026

Implementado e publicado no Road Runners. O seletor Cidade aparece junto de Estado no computador e no celular, aceita pesquisa sem acentos e oferece Todas as cidades. Reutiliza `/estado/{uf}/{cidade}/`; a cidade continua validada dentro da UF no servidor.

O menu inclui todas as cidades com eventos cadastrados no estado, sem o limite anterior de dez. Cidades sem provas nos filtros atuais mostram zero e ficam sem link, preservando a cidade selecionada e a possibilidade de limpar a seleção. A lateral mantém as dez cidades com mais provas nos filtros correntes. O contêiner lateral existe mesmo quando a lista começa vazia, permitindo sua atualização após ampliar o período.

Distância, período, rua/trail, Brasil/mundo, cupom e badges seguem na navegação entre cidades e estados. Trocar estado remove a cidade anterior. Os links e o canonical mantêm as rotas regionais existentes; canonical não inclui combinações de filtros.

As contagens usam `qEventosBase`, que já incorpora eventos futuros, distância e badges, e aplicam as mesmas regras de período/modalidade/território/cupom da lista, exceto a cidade. `/api/eventos.cfm` entrega contagens somente na primeira página das requisições com UF. O controlador compartilhado não mudou. A assinatura semântica dos filtros impede uma resposta antiga de atualizar as novas facetas. A distância inicial da URL agora entra ativa na configuração do controlador da página de estado, evitando sua perda ao alterar outro filtro.

Arquivos de runtime publicados:

- `estado/index.cfm`
- `api/eventos.cfm`
- `includes/backend/backend_estado_cidades.cfm`
- `assets/js/runnerhub-estado-cidades.js`
- `assets/css/runnerhub-estado-cidades.css`

Teste novo: `_codex/tests/estado-city-navigation.test.cjs`. Execute com `node --test _codex/tests/estado-city-navigation.test.cjs _codex/tests/search-page.test.js`.

Verificação realizada:

- 31 testes Node passaram (8 do novo fluxo e 23 da busca existente); JS e `git diff --check` sem erros.
- Três templates compilados pelo Adobe ColdFusion de produção; oito asserts CFML com fixtures sintéticas passaram. O runtime local de uma tarefa anterior estava indisponível; a verificação foi feita no Adobe real, em fixture temporária restrita a loopback, removida ao terminar.
- Renderização isolada com dados públicos da Bahia encontrou 230 cidades, 184 provas no período padrão e 65 em 30 dias. Esses números são uma fotografia da validação, não métricas permanentes.
- Caso de calendário inicialmente vazio foi reproduzido e corrigido; lateral voltou após mudar o período. Resposta antiga simulada não substituiu as contagens atuais. Escape fechou o seletor e devolveu o foco ao botão.
- Desktop 1280px e móvel 390px verificados no navegador; tela publicada móvel com `scrollWidth=390`.
- Página pública da Bahia e seleção real de Alagoinhas verificadas; limpar cidade e trocar para Santa Catarina preservou `cupom=true`. Aplicar cupom em Alagoinhas atualizou o total do estado para uma prova e a cidade selecionada para zero, conforme a lista.
- HTTP 200 confirmado para estado, cidade com período/distância/modalidade, API com filtros e os dois assets. Canonical da cidade permaneceu `/estado/ba/alagoinhas/`.
- Revisão final somente leitura com Astra: um achado Important (resposta antiga) e um caso da lateral vazia, ambos corrigidos com verificações RED→GREEN. Nenhum achado pendente.

Publicação com baseline conferido e backup recuperável em `/var/backups/rr-estado-cidades-20261003/baseline`. Cinco hashes de runtime confirmados; sete arquivos de outras frentes permaneceram iguais. Não houve mudança de banco, anúncios, autenticação, cron ou operações Git.

Registros operacionais desta conversa: `/Users/Shared/Projects/RunnerHub/Business/_codex/staging/estado-cidades-20261003/` (`release-amend.json`, `release-publish.json`, `release-verify.json`, `http-verification.json`, fixtures e capturas). Reversão preparada pelo `release.py rollback`, que recusa sobrescrever alterações concorrentes posteriores.

A implementação não é uma nova auditoria SEO nem comprova melhora de posicionamento/conversão. A medição comercial e o acompanhamento no Search Console continuam como próximas etapas do plano.
