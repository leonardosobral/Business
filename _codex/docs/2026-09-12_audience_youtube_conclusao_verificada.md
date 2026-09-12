# YouTube — conclusão confirmada no Business

Verificação realizada em 12/09/2026, encerrada por volta de 16:48 BRT.
Sem publicação, SQL, acesso ao banco ou alteração de runtime/configuração.

## Resultado observado

Vídeo `jKaRQ7uJEFo`, “WADA NÃO VAI PROIBIR canetas de emagrecimento em 2027”,
aberto pelo card da listagem `/videos/` no modal editorial do RoadRunners.
A configuração renderizada identificava ambiente `prod` e `isInternal=true`.

Business: sete dias, contexto comercial, todas as UFs, família “Vídeos — lista”,
todos os dispositivos e produção. A primeira comparação inclui acessos internos.

| Medida para o vídeo | Antes | Depois | Depois, excluindo internos |
| --- | ---: | ---: | ---: |
| Aberturas | 0 | 1 | 0 |
| Visitantes da abertura | 0 | 1 | 0 |
| Inícios de vídeo | 0 | 1 | 0 |
| Conclusões | 0 | 1 | 0 |

Os valores foram lidos na linha do ID em “Conteúdo individual”, com recorte
idêntico antes/depois. O recorte comercial final excluiu os acessos internos;
o teste não aparece nele. Não atribuir esse incremento à audiência comercial.

## Procedimento e alcance da prova

- Registrada a linha de base no Business antes de abrir o vídeo.
- Reprodução no iframe do site; em seguida, uso da barra de tempo para avançar
  de aproximadamente 1:00 a 14:34, em vídeo com duração exibida de 14:53.
- Retomada pelo botão “Assistir vídeo” e reprodução do trecho restante.
  O player apresentou “Repetir vídeo” ao terminar.
- Modal fechado e Business atualizado; início e conclusão chegaram à tela.
- Filtro de acessos internos removido na aba temporária; ambos ficaram em zero.
- Nenhum erro de console foi capturado na aba de teste. Nenhum anúncio foi
  clicado, nenhum evento foi injetado e nenhuma função do coletor foi chamada
  manualmente. Não houve novo login ou mudança de escolha de privacidade.
- Somente as duas abas próprias de teste foram fechadas; abas/filtros do usuário
  e da outra frente ficaram intactos. Não houve alteração de viewport.

**A conclusão confirma que o player chegou ao fim após um início observado;
não comprova que o vídeo inteiro foi assistido.** O avanço foi intencional e
faz parte desta verificação do evento de término. Não é teste de retenção de
audiência ou de tempo integral assistido.

## Marcos de 25%, 50% e 75%

O contrato existente do tracker emite `video_progress` como posição alcançada
no player. A consulta atual do Business apresenta `video_start` e
`video_complete`, mas não agrega esses marcos de vídeo. A coluna de profundidade
é de notícias (`content_progress`), não evidência de quartis de reprodução.

Isoladamente, a verificação em navegador encerrou a pendência de conclusão
exibida no Business, mas não confirmou a persistência individual dos quartis.
O resultado SQL posterior abaixo encerra essa pendência, sem criar novas colunas
ou painel.

## Confirmação posterior pelo banco — resultado fornecido pelo usuário

Em 12/09, o usuário devolveu o resultado do
[SQL somente leitura](../sql/2026-09-12_audience_verificacao_final_readonly.sql)
para o vídeo `jKaRQ7uJEFo`, na janela interna de produção das 16:40 às 16:50 BRT
(limite final exclusivo). O agente não acessou o banco de produção.

Todos os sete contadores retornaram `1`: páginas com registros, com início,
com marco 25, com marco 50, com marco 75, com fim e com todos os sinais. Portanto,
os cinco sinais foram persistidos para a mesma visualização. A verificação dos
quartis está encerrada para esse teste. Mantêm-se os limites: houve avanço na
barra de tempo; os marcos não demonstram tempo integral assistido, são internos
e não passam a ser exibidos no painel por causa desta consulta.

Referências locais: [consulta de conteúdo](../../portal/audiencia/queries/content.sql),
[publicação original](2026-09-10_audience_youtube_publicado.md) e
[pendências atualizadas](2026-09-12_audiencia_escopo_e_pendencias.md).
