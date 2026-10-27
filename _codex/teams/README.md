# Road Runners Teams — fontes e operação

Fontes Business: `services/teams/`, `teams/` e `administracao/teams/`.
Os quatro pontos compartilhados são a entrada do Business, o retorno do login
Google, a navegação e a fronteira de contexto de conta. Teams usa identidade
pessoal, sem herdar permissões empresariais.

As fontes específicas do site RR ficam em `roadrunners/teams/`. Os scripts
de sincronização/publicação acrescentam os assets canônicos de `teams/assets/`
e os serviços compartilhados de `services/teams/`, sem Mailer/EmailTransport.
`patch_shared.py` registra os pontos de integração com os dois sites; os
scripts de publicação de cada etapa registram os respectivos manifestos.

Banco e fixture: ver `INSTALACAO.md` e `_codex/sql/2026-10-26_rr_teams*.sql`.
Operação publicada e recuperação: `_codex/docs/2026-10-26_teams_operacao.md`.
Os scripts SQL não devem ser reaplicados nem os envios ativados apenas para
executar testes ou preparar um commit.

Testes ColdFusion: `_codex/tests/teams/`, executados com
`python3 _codex/scripts/test_teams_native.py <cenario>` por SSH `rr-prod`,
em staging privado restrito a localhost. `native_harness.py` é o apoio isolado
do módulo. A fixture usa `rr_teams_test`; o cenário `source` verifica a
pré-condição de instalação inicial, com job ainda desativado. Após ativação,
usar o verificador operacional para conferir o estado publicado.

Os testes HTTP usam `test_teams_http.py` e `test_teams_global.py` e não enviam
emails reais. As ferramentas `check_teams.py`, `deploy_teams*.py`,
`operate_teams.py`, `preview_teams.py` e `sync_teams_rr.py` mantêm evidências,
baselines e backups próprios; ler o modo de cada script antes de executar.

Baselines de produção, prévias com dados e recibos gerados são locais e não
entram no Git. Os scripts que publicam ou operam uma instalação existente
precisam dos seus recibos locais; não substitua evidências ausentes por dados
inventados. Não incluir credenciais, configuração privada ou conteúdo de
prévia em um commit.
