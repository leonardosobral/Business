# Relatório de erros — 5 a 7 de novembro de 2026

Janela: 48 horas, de 05/11 às 04:27 a 07/11 às 04:27, horário de Brasília. A análise usou os registros originais de `tb_log`, o estado da fila do Business, logs do ColdFusion e checagens públicas pontuais. Somente diagnóstico; nenhum status, dado ou runtime foi alterado.

## Resumo

| Site | Registros `erro` | Registros `404` | `erro` nas últimas 24h |
| --- | ---: | ---: | ---: |
| RoadRunners | 40 | 12.202 | 1 |
| OpenResults | 1 | 0 | 1 |
| Total desta consulta | 41 | 12.202 | 2 |

Os números são registros produzidos pelos mecanismos de log, não cobertura integral de todos os hosts. Não houve linhas atribuídas ao Business nessa consulta; isso não prova ausência de falhas no Business. Dos 40 registros RoadRunners, 36 indicavam `prod` e quatro `dev`.

Os três sites responderam HTTP 200 nos testes públicos: RoadRunners 0,82 s, Business 0,16 s, OpenResults 0,65 s. Apache e ColdFusion estavam ativos; Apache tinha três workers ocupados e 47 livres. A partição do servidor estava em 87% de uso, com aproximadamente 2,4 GB livres. Vale acompanhar o crescimento de logs e backups.

## O que merece ajuste

| Prioridade | Ponto | Evidência e recomendação |
| --- | --- | --- |
| Alta | Fila de acompanhamento do Business | Nenhum dos 41 erros estava vinculado a um problema. A última atualização registrada no coletor é 09/10 às 11:46. Retomar a coleta a partir do recorte recente e manter 404 esperados fora da fila de defeitos. Preservar os logs originais. |
| Alta | Registro de erros do OpenResults | O handler publicado ainda registra e envia por e-mail dumps de formulário e URL, e contém credencial SMTP no código. Recomendo adotar o registro estruturado com campos mínimos, agrupamento e limite de alertas; remover a credencial do código e rotacioná-la se estiver ativa. A ocorrência recente não foi identificada pelo formato estruturado. Não se verificou exposição a terceiros. |
| Média | OAuth Strava no perfil RoadRunners | Cinco falhas de expressão em `includes/backend/backend_perfil_publico.cfm:29`, última 05/11 às 15:43. O fluxo interpreta o JSON e usa `access_token` diretamente. Validar o status e os campos obrigatórios antes de gravar a conexão, tratando resposta rejeitada ou incompleta como falha de autorização com opção de reconectar. Conferir também o caminho de renovação, que usa o mesmo padrão. O conteúdo da resposta histórica não está disponível. |
| Média | Cabeçalho no login sincronizado | Duas falhas de template em `sso/comparador/_portal_nonce.cfm:10` em 05/11. A linha tenta definir `Cache-Control`; o histórico do projeto documenta falha nesse trecho quando a resposta já começou. Reproduzir a rota afetada e conferir preparação do nonce antes de enviar HTML. A mensagem técnica destas duas ocorrências foi omitida pelo gravador, portanto a causa não está comprovada. |
| Média | Diagnóstico insuficiente | Os 40 registros estruturados RoadRunners tinham mensagem genérica; o grupo de banco do ranking não preservou SQLSTATE. Manter resposta pública genérica e guardar, para admin, classe/SQLSTATE, arquivo/linha e mensagem técnica sanitizada. Assim se distingue erro de consulta, timeout e entrada inválida sem guardar tokens ou valores de usuário. |
| Baixa | Ícones e 404 esperados | Na amostra das 2.500 últimas respostas 404, 227 coincidiram com sondagens reconhecidas, 201 eram imagens e 63 eram caminhos `.well-known`. `apple-touch-icon.png` e `apple-touch-icon-precomposed.png` somaram 78 ocorrências. Vale fornecer os ícones oficiais ou remover referências internas quebradas. Tratar sondagens separadamente e checar referenciadores antes de redirecionar páginas de eventos. Esses números são da amostra, não extrapolação para as 12.202 respostas. |

## Ocorrências a acompanhar

- **Ranking Catarinense: 27 ocorrências**, cerca de 66% dos registros `erro`. Grupo de banco em `circuitocatarinense/ranking_data.cfm:206`, última às 10:58 de 05/11. O arquivo publicado tem data de 11:00:52 do mesmo dia. As duas páginas de ranking, rua e trail, responderam HTTP 200 e renderizaram conteúdo sem mensagem de erro nos testes. Sem recorrência registrada até o corte. A evidência favorece monitorar a versão atual antes de mexer novamente; o SQLSTATE original está ausente.
- **Desafio confirmado:** uma falha de expressão em 06/11 às 21:11, na linha que renderiza o link de grupo do TodosantoDia em `desafios/desafio_confirmado.cfm:256`. Conferir variáveis e catálogo no cenário autenticado; o log não identifica qual expressão falhou. ID original 51480056.
- **OpenResults:** uma ocorrência em 06/11 às 09:18, ID 51395150, sem campos técnicos reconhecidos na amostra limitada. Investigar pelo log original protegido antes de atribuir causa.
- **Busca DEV:** quatro falhas `missinginclude` em 05/11 entre 20:54 e 20:59. Conferir dependências da versão implantada no DEV. A evidência não aponta recorrência em produção.
- **Cupom:** uma falha de aplicação em 05/11 às 10:18, em `modal_cupom_link_conteudo.cfm:90`, no ramo de cupom inexistente. Reproduzir esse caminho e conferir se o aviso por e-mail pode falhar sem interromper a resposta; causa específica não confirmada.
- **Conteúdo:** seis registros de timeout próximos de 08:50 em 05/11 no log nativo do ColdFusion, fora da contagem de `tb_log`. Acompanhar se o pico voltar. Logs nativos podem duplicar a mesma falha em arquivos diferentes; não foram somados às contagens do banco.

Ordem sugerida: recuperar a visibilidade da fila, ajustar o handler do OpenResults e validar o retorno do Strava. Depois, reproduzir os casos de login e desafio com contexto completo. O diagnóstico temporário foi removido e não foram iniciados navegadores de teste.
