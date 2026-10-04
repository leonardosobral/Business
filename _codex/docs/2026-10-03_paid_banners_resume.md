# Banners CPC — retomada após update

Runtime publicado e verificado em03/10/2026. Migração aplicada anteriormente pelo operador; não reaplicada. ATUALIZAÇÃO POSTERIOR: usuário autorizou explicitamente liberar banners para contas normais; seleção CPC habilitada em produção, mantendo aprovação obrigatória. Backup da flag `/var/backups/paid-banner-enable.07xo9e4m`; SHA habilitado `6128dd5c5495824577c251fde9dbdaeaab8cd7c92ee2d53a119027e229d6c64e`. Registro final: `2026-10-03_paid_banners_rollout.md`. Os parágrafos abaixo são o histórico da publicação inicial, anterior à autorização.

Business HEAD 59ef5d0; RoadRunners HEAD 4f3ef2f2. Baselines locais/produção de 23 alvos preservados em `.superpowers/sdd/2026-09-16_paid_banners_plan/2026-10-03-baseline/`, com inventário de hashes.

O update manteve os novos arquivos pagos, mas reverteu parte da integração. Recuperar endpoints CPC no renderer e lookup BANNER no clique, preservando novas proteções de tráfego. Reconciliar Business sobre o dashboard HOUSE/escopo/uploads já existentes em produção; não sobrepor com cópias locais anteriores. Preservar rótulo de navegação de produção e mudanças alheias.

Primeira tentativa bloqueada por ENOSPC (115 MiB livres), antes de inicializar PostgreSQL. 35 testes JS passaram. Nenhum runtime foi alterado nessa tentativa. O usuário liberou espaço; retomada com aproximadamente 535 MiB, testes pesados sequenciais.

Após liberação de espaço (13 GiB), o harness financeiro completo passou nos 11 grupos em PostgreSQL isolado (`ads-paid-banner-zYSFKm`), incluindo concorrência real, carteira compartilhada, revisão, escopo, estorno e proteção de drift. Fixture parada ao final.

RoadRunners: os dois pontos revertidos foram recuperados sem remover o detector Firefox upstream. Revisão independente dos cinco arquivos runtime aprovada; renderer8, endpoint324 e tracker67 verificações passaram. Fixture do include real conferida em1280 e390px: sem overflow, imagens responsivas carregadas e disclosure preservado.

Business: recuperação concluída localmente e congelada. Preservados dashboard HOUSE/escopo/uploads de produção e auth upstream, restaurados isolamento EVENT e integração CPC. Abas Desempenho/Banners/Cadastro mantêm campanha e período ao criar/editar/fechar/salvar. Revisão de Task2 e da correção de filtros aprovadas; controller confirmou 12 checks de render.

SQL fonte-derivada passou: 3 queries pagas + 11 EVENT/ledger. Testes RoadRunners recuperados após update: config18 e sidebar27 PASS, sem alteração adicional de runtime.

Revisão final combinada aprovada: `.superpowers/sdd/2026-09-16_paid_banners_plan/final-current-review.md`. Sem Critical/Important; Minor de imagens órfãs em rejeição local anterior ao SQL explicitamente deferido e não bloqueante.

Manifesto final publicado: `_codex/docs/2026-10-03_paid_banners_reviewed_release.json`; recibo `2026-10-03_paid_banners_reviewed_prepare.json` e variantes `-publish.json`/`-verify.json`. Backup `/var/backups/house-banner-scope.b2300dfa0143`, compilação Adobe CF21/21, 22runtime e94proteções. Publish e verify exit0, phasepublished. Dependências novas primeiro, router Business por último.

Verificação autenticada real concluída com janela de uso do Chrome autorizada: painel global/CPC, filtros90dias, HOUSE6banners/3ativos, formulário pago daLive! e carteiraR$408,82igualaoAds. Sem upload/submit/aprovação; contexto Todasascontas restaurado. RoadRunnersBA mantém doisEVENTCPC eHOUSEcarregado. Nenhum anúncio clicado. Não reutilizar recibos anteriores. Não ativar campanha real ou flag de cobrança automaticamente; próxima etapa é homologação operacional autorizada, separada deste deploy.
