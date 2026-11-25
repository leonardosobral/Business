# Central de lançamento — faixa compacta e data destacada

Publicado em 04/11/2026 em https://business.roadrunners.run/estudos/lancamento/.

Cada etapa passa a exibir somente uma faixa principal: data grande à esquerda, título, responsável, validação e botão “Expandir” à direita. O botão abre todo o restante na própria etapa: próximo passo, descrição, responsável editável, observações e salvamento. Não há um segundo controle visível para abrir o editor. Ao abrir, o botão muda para “Recolher”. Rascunhos não salvos continuam identificados na faixa.

Datas são apresentadas a partir do texto existente do serviço: dia(s) em destaque e mês/dia da semana abaixo; o prefixo “ATÉ” e a indicação de proposta para janeiro foram mantidos. O conteúdo das oito observações e o estado das validações não foram alterados.

## Implementação

Três arquivos de runtime: `estudos/lancamento/index.cfm`, `estudos/lancamento/lancamento.css` e `estudos/lancamento/checklist.js`. Painel nativo details com summary oculto, controlado por botão externo com aria-controls, aria-expanded e nome acessível da etapa. Abertura por link direto preservada. Editor sem subpainéis visíveis. Formulários, serviço, endpoint, revisões e CSRF existentes preservados.

## Publicação e verificações

Baseline de produção conferido, backup em `/var/backups/business-launch-compact-band-20261104/baseline`, JavaScript validado por node --check, CFML compilado e três hashes verificados após publicação. Workspace sincronizado no escopo. Não houve deploy Road Runners.

Chrome autenticado: oito faixas recolhidas por padrão, com alturas de 86–111 px em 1533 px. A data numérica simples tem 42 px. Expandir por clique mostra próximo passo e todos os campos; recolher por Enter funciona e aria-expanded reflete o estado. Summary secundário não é visível. Celular 390 px sem transbordamento horizontal; campos do painel com fonte de 16 px e largura de 312 px. Guardas HTTP: central anônima 401, endpoint GET 405/POST anônimo 401, CSS/JS 200.

Hash do conjunto imutável de acompanhamento comparado antes e depois: mesmas oito linhas, maior ID 520, mesmo hash. Nenhuma gravação no banco nesta tarefa; responsáveis, observações e validações mantidos.

Recibos e provas: `_codex/staging/lancamento-faixa-compacta-20261104/`. Aba própria 283508623 encerrada e ausência confirmada; viewport restaurado e pasta temporária de imagens removida. Nenhum servidor de teste iniciado.
