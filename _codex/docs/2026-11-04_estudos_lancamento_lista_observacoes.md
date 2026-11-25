# Central de lançamento — lista e plano de observações

Publicado e preenchido em 04/11/2026 em https://business.roadrunners.run/estudos/lancamento/#cronograma, a pedido do proprietário.

Os oito cards estreitos foram substituídos por linhas largas. Prazo, título, responsável e validação ficam no cabeçalho; a primeira linha das observações mostra o próximo passo. “Ver observações e editar” abre a descrição e a edição na própria etapa. No desktop, o campo de observações usa a largura restante ao lado do responsável e ajusta sua altura ao conteúdo; no celular, os campos ficam empilhados com fonte de 16 px. Rascunhos não salvos continuam identificados e preservados; os links diretos de etapa abrem seu editor.

## Observações centralizadas

Preenchidas as oito etapas com PRÓXIMO PASSO, PRONTO e FALTA, incluindo pendências até 13/11 e atividades posteriores de acompanhamento/anual. A conferência anterior à gravação encontrou zero anotações e validações. Os responsáveis permaneceram vazios para atribuição pela equipe; nenhuma etapa foi marcada como concluída.

O conteúdo foi salvo pela interface autenticada do Business, com a sessão de administrador existente, CSRF e revisão esperada. Foram acrescentados oito eventos imutáveis LAUNCH_STEP_DETAILS, IDs 513–520; os textos foram relidos após recarregar a página e comparados integralmente com o banco. Não há preenchimento automático no render ou em futuros deployments: a equipe passa a manter os campos pelo editor.

Fontes da conferência em 04/11: materiais e recibos anteriores do lançamento, hotsite/kit/imprensa respondendo 200, produtos e campanhas atuais e estado anterior do checklist. A proposta de observações está em `observacoes-propostas.json` na pasta de staging; é um registro desta carga, não uma fonte que sobrescreva edições posteriores.

Pendências reais destacadas:

- Aprovar contrato, uso da marca e comunicação da parceria com a ABRACEO até 12/11.
- Executar o piloto com 5–10 convidados: a conferência encontrou zero resgates, zero acessos concedidos e zero representantes declarados. Campanhas piloto/editorial estão em rascunho.
- Alinhar o benefício de 0% da campanha abraceo-primeiro-acesso com a proposta de 50% de desconto no anual para o público elegível.
- Decidir o tratamento da área de imprensa, ainda temporariamente aberta sem login/código.
- Nomear responsáveis, aprovar destinatários, horário e canais e executar divulgação/convites. Os 95 vouchers ABRACEO estão prontos, com resgate até 24/11.

A publicação não altera benefícios, vouchers, acessos, contrato nem a abertura da imprensa. Esses pontos foram registrados para decisão/execução. As pendências do anual são descritas como posteriores à prévia; janeiro permanece uma proposta.

## Runtime e verificação

Somente três arquivos alterados: `estudos/lancamento/index.cfm`, `estudos/lancamento/lancamento.css` e `estudos/lancamento/checklist.js`. Serviços e endpoint existentes foram preservados. Nenhuma alteração em queries, notebook ou congelamentos.

Baseline conferido, JavaScript validado por node --check, CFML compilado, backup recuperável em `/var/backups/business-launch-list-notes-20261104/baseline`, três hashes de runtime verificados e workspace sincronizado. Guards HTTP sem sessão: central 401, endpoint GET 405 e POST 401; CSS/JS 200.

Chrome: oito observações gravadas, releitura após reload, resumo atualizado e editores recolhidos; zero etapas validadas. Editor desktop com 886 px para observações, sem rolagem interna do texto inspecionado. Desktop 1533 px e celular 390 px sem transbordamento horizontal; campos móveis em uma coluna e fonte de 16 px.

Recibos e provas em `_codex/staging/lancamento-lista-observacoes-20261104/`: readiness-before.json, observacoes-propostas.json, notes-after.json, notes-verify.json, prepare/publish/verify/sync.json, http-qa.json e qa/browser-qa.json.

A aba própria 283508553 foi encerrada e sua ausência confirmada. Viewport restaurado, pasta temporária de imagens removida; nenhum servidor de teste iniciado. Não houve envio de mensagens ou publicação em canais de divulgação.

## Apresentação compacta posterior

Na mesma data, as linhas foram reduzidas à faixa principal, com data ampliada e botão à direita que abre todo o restante. Consulte [faixa compacta do cronograma](2026-11-04_estudos_lancamento_faixa_compacta.md). O conteúdo das observações foi preservado.

## Benefício do primeiro acesso corrigido

Ainda em 04/11/2026, o benefício ABRACEO foi configurado para 50% na compra antecipada do anual, com resgate por voucher/CNPJ e proteção contra duplicidade. As observações atuais da central já refletem a correção; o estado anterior acima permanece como histórico da conferência. Consulte [correção do benefício anual](2026-11-04_estudo_abraceo_beneficio_anual_50.md).
