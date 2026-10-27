# Espaçamento do cabeçalho compartilhado do Business

Correção publicada em 24/10/2026 às 13:54:00, horário de Brasília. O espaço excessivo combinava o bloco decorativo de 140 px do cabeçalho, um parágrafo residual do seletor de conta com cerca de 41,59 px e compensações locais de margem negativa de −55/−80 px.

O cabeçalho agora reserva a altura real da barra de navegação, medida ao carregar e quando ela muda de tamanho. O conteúdo recebe um recuo superior central de 16 px. O CSS neutraliza as compensações antigas somente nas páginas que usam esse cabeçalho; páginas independentes permanecem fora desse escopo. Em modo de delegação, a barra mantém o link para o seletor dedicado sem incluir o parágrafo redundante. O modal de troca de conta continua disponível no fluxo sem delegação.

## Escopo e publicação

Foram publicados somente [header.cfm](/Users/Shared/Projects/RunnerHub/Business/includes/estrutura/header.cfm), [navbar.cfm](/Users/Shared/Projects/RunnerHub/Business/includes/estrutura/navbar.cfm) e os novos [business-shell.css](/Users/Shared/Projects/RunnerHub/Business/assets/css/business-shell.css) e [business-shell.js](/Users/Shared/Projects/RunnerHub/Business/assets/js/business-shell.js).

O baseline dos dois templates correspondia ao checkout original; os assets novos estavam ausentes. A instalação preservou proprietário, grupo e permissões, publicou os assets antes dos templates e confirmou os quatro hashes. Os sete caminhos monitorados — CSS geral, CSS administrativo, modal de conta, template, head, sidenav e CSS da home — permaneceram no estado anterior de produção. As diferenças locais desses arquivos não foram publicadas. Evidência: [release-verify.json](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/release-verify.json).

## Validação

- Quinze testes Node focados aprovados; cinco testes novos, com quatro falhas reproduzidas antes da correção e todos passando depois.
- Doze cenários locais em larguras de 1280 e 390 px. Em desktop, a distância da barra ao conteúdo caiu de 104 para 16,4 px na home e de 88 para 16,4 px nas páginas administrativas. Os cenários independentes mantiveram seus 32 px. Dados: [antes](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/layout-before.json) e [depois](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/layout-after.json).
- Com a barra ampliada para 96 px, o espaço permaneceu em 16 px; sem JavaScript, o fallback apresentou 17,4 px. O [teste de redimensionamento](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/layout-resize.json) passou.
- Revisão independente sem achados; dois templates compilados no Adobe ColdFusion 2025. [Recibo de compilação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/release-compile.json).
- Chrome autenticado em produção confirmou 16,406 px na home, no Kanban e na Agenda, e 20,406 px no CRM. A captura está em [home-sem-gap.png](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/home-sem-gap.png).

O seletor de conta independente foi aberto em produção: opções disponíveis, sem o novo header ou stylesheet, e nenhuma conta foi selecionada. As medições e a checagem do seletor estão em [production-ui-check.json](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/production-ui-check.json). A navegação de validação de Desafios excedeu o limite de 10 segundos da ferramenta e não foi concluída; a variante de margem antiga de −80 px foi validada nos cenários locais, sem afirmar inspeção dessa rota em produção. A verificação a 390 px ocorreu na prévia local; a janela de produção não foi redimensionada.

A suíte geral registrou 257 aprovações em 263 testes. As mesmas seis falhas preexistentes continuam identificadas por nome no [node-suite.log](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/node-suite.log): ordenação de Plataforma; resumo individual de conteúdo; navegador da agenda Google; migrações de Kanban e Drive; isolamento da tela de inscrições. Esses casos não foram alterados nesta correção.

## Recuperação

Backup privado: `/var/backups/business-shell-gap-20261024-9wz2l4b6/baseline`. O estágio também preserva o candidato e o manifesto com hashes e metadados; os recibos de [preparação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/release-prepare.json) e [publicação](/Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/release-publish.json) identificam o pacote.

Para uma eventual reversão, mantendo o pacote local e o acesso SSH usados na preparação:

```sh
python3 /Users/Shared/Projects/RunnerHub/Business/_codex/staging/business-shell-gap-20261024/release.py rollback
```

O driver restaura os dois templates e retira os dois assets novos, preservando suas cópias no estágio. Alterações concorrentes ou divergência do pacote interrompem a reversão antes de sobrescrever trabalho posterior. Não houve migração de banco, alteração de credenciais, commit, push ou PR.
