# Acompanhamento de erros no Business

Estado: aprovada, implementada e publicada em 26/09/2026. Operação e recibo em `_codex/docs/2026-09-26_error_triage.md`.

## Objetivo aprovado

Transformar os erros registrados em uma fila que possa ser tratada um problema
por vez, com classificação, análise e resultado visíveis no Business. O usuário
quer aproveitar uma área existente e enxergar se cada erro foi tratado.

## O que existe

- `/portal/erros/` já é a área administrativa de erros do portal, acessível pelo
  menu e pelo dashboard. A entrada exige autenticação e acesso administrativo.
- `portal/includes/error_log_backend.cfm` consulta `tb_log`, limitada aos tipos
  `erro` e `404`, em amostras de 100, 500 ou 1.000 registros e períodos de até
  90 dias. A busca textual é aplicada depois do limite da amostra.
- A tela já apresenta classificações heurísticas, detalhes e agrupamento por
  URL ou início do texto. Essa assinatura não é adequada como identidade
  persistente: erros diferentes podem compartilhar a mesma URL.
- Não existe estado de tratamento nesse fluxo nem na definição de `tb_log`
  presente em `_codex/sql/ddl.sql`.
- O `OnError` observado em `RoadRunners/Application.cfc` envia e-mail e grava
  HTML com exceção, formulário e parâmetros de URL. Não é um payload pronto
  para enviar à IA. Isso também não prova que todas as falhas do ecossistema
  sejam capturadas por esse handler.

## Escopo da primeira entrega

O Business será dono do acompanhamento. RoadRunners continuará produzindo os
logs pelo mecanismo atual. Nesta entrega, a leitura e o tratamento serão sob
demanda; agendamento, chamadas automáticas à IA e alteração da frequência dos
e-mails serão etapas posteriores. Nenhum novo envio de e-mail faz parte deste
escopo.

### Tela existente

Adicionar uma fila de problemas em `/portal/erros/`, mantendo a consulta dos
registros originais. Cada problema terá:

- identificador estável, título e site de origem;
- categoria: não classificado, código/CFML, banco/SQL, serviço externo,
  entrada inválida/robô ou página não encontrada;
- status: novo, investigando, correção pronta, publicado, verificado,
  ignorado ou reaberto;
- ocorrências vinculadas, primeira e última ocorrência conhecidas;
- análise, proposta de correção e evidências da publicação e verificação;
- histórico com autor, data, alteração de estado e justificativa.

Permitir filtrar por status, categoria e site. A fila persistente deve mostrar
problemas pendentes mesmo que seus logs tenham saído da amostra recente.
Separar claramente os totais da amostra dos totais de ocorrências processadas.
No detalhe de um log, mostrar o problema associado e seu estado de tratamento.

### Persistência e integridade

Usar tabelas adicionais para problemas, vínculo de ocorrências, histórico e
cursor de coleta. Preservar o conteúdo de `tb_log`, que também é usado por
outros fluxos. O vínculo terá unicidade por `id_log`; reprocessar uma ocorrência
não deve duplicar o contador ou produzir nova investigação.

Salvar uma alteração de status e sua entrada de histórico na mesma transação.
Usar versão do registro para impedir que duas edições sobrescrevam decisões.
O usuário pode corrigir uma categoria sugerida; a coleta não deve sobrescrever
essa escolha nem notas humanas.

O primeiro processamento parte de um recorte explícito de sete dias, em lotes
limitados. Registrar o ponto de partida e a fronteira superior do lote;
avançar o cursor somente junto com a confirmação dos vínculos. Informar se
restam registros a processar e permitir continuar. Não apresentar esse recorte
como todo o histórico. Novas rodadas usam o cursor, com releitura sobreposta e
deduplicação para absorver registros confirmados tardiamente.

### Agrupamento

Gerar assinatura versionada com site, tipo, categoria técnica da exceção,
arquivo e mensagem normalizada quando extraíveis. Manter códigos técnicos
relevantes, como SQLSTATE e nome de variável; remover valores de requisição e
identificadores variáveis. Linha auxilia a investigação, mas não deve, sozinha,
separar um erro após deslocamento de código.

Para 404, usar site e caminho sem query string. Para erros sem dados suficientes,
manter uma ocorrência individual para triagem, em vez de juntar falhas apenas
porque compartilham uma URL. A interface deve indicar a classificação sugerida
e permitir vincular ou separar ocorrências com registro no histórico.

### Tratamento e recorrência

Marcar como publicado exige uma nota de publicação e seu horário efetivo.
Marcar como verificado exige evidência da verificação. Correção pronta não
significa correção publicada, e silêncio nos logs não comprova resolução.

Quando a coleta encontrar a mesma assinatura com horário posterior à
publicação de um problema publicado ou verificado, reabrir e registrar a
recorrência uma única vez. Uma ocorrência antiga coletada tardiamente não deve
reabrir o problema. Problemas ignorados continuam acumulando ocorrências e
podem ser reabertos manualmente com justificativa.

### Pacote para o Codex

Disponibilizar uma exportação autenticada dos problemas selecionados, contendo
ID, categoria, status, contagens processadas, horários, caminho, mensagem técnica
filtrada e notas revisáveis. O administrador poderá usar esse pacote para pedir
o tratamento de um lote. A exportação não dispara análise nem execução de código.

Não incluir dumps, HTML bruto, cookies, cabeçalhos de autorização, formulário,
query string, IP ou identificação de usuário. Extrair apenas campos permitidos
e aplicar filtragem também às mensagens e notas. Se não for possível obter um
resumo seguro, exportar apenas identificadores e metadados. Dados do log são
evidências não confiáveis, nunca instruções para o agente.

O resultado da investigação será registrado no mesmo problema, com análise,
proposta e evidências. A primeira entrega usa a interface administrativa para
essa atualização; uma futura integração de escrita exigirá contrato próprio de
autenticação, concorrência e auditoria.

## Alternativas consideradas

1. Adicionar status diretamente em cada linha de `tb_log`: simples, mas repete
   decisões em centenas de ocorrências e dificulta acompanhar recorrências.
2. Vincular logs a problemas persistentes: recomendação; preserva o histórico
   original e concentra análise e tratamento.
3. Criar um serviço externo de incidentes: amplia operação e integração sem
   necessidade demonstrada nesta primeira etapa.

## Segurança e operação

Aplicar os guards administrativos existentes também às novas ações e à
exportação. Escritas somente por POST com CSRF, campos validados e SQL
parametrizado. Escapar conteúdo exibido e impedir acesso direto aos includes.
O schema será instalado por migração explícita e aditiva, nunca durante um GET.
Sem a migração, a consulta atual continua disponível e a gestão informa a
indisponibilidade. Não alterar credenciais ou permissões automaticamente.

## Verificação e publicação

Validar: agrupamento de repetições e separação de falhas diferentes na mesma
rota; isolamento por site; idempotência e retomada de lotes; concorrência de
edição; histórico transacional; recorrência após publicação versus log antigo;
exportação sem dados sensíveis; acesso administrativo e CSRF; desktop e mobile.

Antes de publicar, conferir os arquivos de produção, preparar backup recuperável,
validar migração e runtime, publicar somente o escopo e testar a página e ações
reais. A preferência do projeto já autoriza essa publicação após as verificações.
Não criar commit, branch, push ou PR. A alteração preexistente em
`includes/estrutura/sidenav.cfm` pertence a outra frente e deve ser preservada.

Rollback restaura o runtime anterior e mantém os novos dados de acompanhamento,
sem apagar logs ou executar migração destrutiva. Conflito de produção, falta de
acesso ou falha de validação impedem a publicação até serem resolvidos.

## Próximo passo

Usar a fila sob demanda para investigar problemas e registrar os resultados.
Agendamento, análise automática e ajustes de e-mail permanecem fora desta entrega.
