# Business — oportunidades de entrega, não exposição

Correção aprovada pelo usuário em 12/09/2026 após demonstrar que uma posição do Acre sem campanha não aparecia como vazia no resumo. **Publicada em 12/09/2026 às 23:23:07 BRT e conferida no Business autenticado.**

## Decisão que governa o indicador

O comercial precisa conhecer a demanda por espaços, inclusive onde não existe anúncio elegível. O denominador principal é oportunidade de entrega: uma posição aplicável observada em uma página, independentemente de haver peça, renderização ou um segundo de visibilidade. Anúncios preenchidos/servidos contam como preenchimento sem exigir exposição. A métrica de anúncio visto por um segundo permanece separada; não se inventa uma impressão para um espaço vazio.

O exemplo de aceitação é sintético, não dado de produção: **200 oportunidades no Acre, nenhuma campanha elegível, zero visualizações → 200 oportunidades, 0 preenchidas, 200 sem anúncio.** Havendo 40 preenchidas e nenhuma visão qualificada, a ocupação é 40/200 = 20%; as visualizações continuam zero.

## Causa da correção

No RoadRunners, `includes/analytics/slot_marker.cfm` converte `no_candidate` em `empty` e gera um marcador oculto. `assets/js/rr-audience.js` registra `slot_opportunity`, mas não `slot_viewable`, pois não existe área visível. A consulta anterior `occupancy.sql` exigia `slot_viewable` para potencial, preenchimento e vazio: removia esses vazios do denominador e permitia o enganoso 100%.

Os cinco arquivos rastreados foram comparados por SHA-256 com produção no diagnóstico. Há testes locais que confirmam o contrato do produtor. A coleta de oportunidades existente é reutilizada; esta correção não depende de alterar RoadRunners, de gerar tráfego artificial ou de modificar objetos de banco.

## Contrato corrigido

Fonte: `audience.events`, consulta somente leitura no Business pelo DSN explícito já existente `runnerhub`. Mesmos sete filtros tipados: período, ambiente, internos, dimensão regional, UF, família de página e dispositivo. Janela por Brasília, até o instante da consulta, incluindo hoje.

- `registered`: posições físicas registradas, inclusive as posteriormente consideradas não aplicáveis.
- `potential`: oportunidades sem exigência de visibilidade; exclui posições com evidência afirmativa de `not_applicable`/`hidden`. Falhas, posições desligadas e estados não resolvidos são mantidos como sem confirmação, não como ausência de anunciante.
- `filled`: evidência de preenchimento `filled`/`house` em sinal de posição, inclusive oportunidade/servido/render, ou em anúncio com IDs válidos. Institucionais entram; pagamento não é inferido.
- `empty`: estado vazio explicitamente registrado e sem preenchimento ou conflito operacional não resolvido. Um pedido sem resposta não prova falta de anunciante.
- `unclassified`: demais oportunidades; a interface informa que incluem falhas, desligadas e pendentes e não as apresenta como estoque vazio confirmado.
- `potential = filled + empty + unclassified`. Percentuais gerais e por formato usam essa mesma população.

A primeira oportunidade fixa metadados por página + posição + UF selecionada. Evidência de outra UF não preenche o recorte local; depois dos filtros, o total é deduplicado por página + posição. Rotações não multiplicam a demanda física. A mesma posição pode participar de recortes estaduais diferentes; somar todos esses recortes não substitui o total deduplicado.

Somente formatos e posições explicitamente mapeados viram Ads ou banners; conflitos e nomes desconhecidos ficam em outros formatos. O contrato de quatro linhas/colunas da consulta permanece compatível com a validação CFML e a falha isolada existentes.

## Interface e limites comerciais

O topo passa a mostrar **Oportunidades de entrega**, preenchidas e sem anúncio, com barras de Ads/banners. Visitantes e sessões continuam juntos. Anúncios vistos por um segundo aparecem à parte, com sua própria unidade, sem serem usados no percentual de preenchimento.

O filtro de UF existente deve permitir conferir Acre e voltar a todas as UFs. Uma visão comparativa comercial por todos os estados é etapa posterior, como indicado pelo usuário; não foi criada outra tabela ou previsão nesta correção.

Estas são oportunidades históricas observadas, não garantia de entrega futura. Opt-out/GPC, bloqueios, falhas de coleta, cobertura parcial e início recente limitam o universo medido. “Sem anúncio” descreve a situação registrada no período, não uma consulta do catálogo atual de campanhas. Posições sem confirmação não são estoque comercial livre comprovado. A aba Capacidade permanece explicitamente em exposições e não estima cliques, créditos, disponibilidade de campanha nem compromissos já vendidos.

## Publicação e verificações

Lote publicado: apenas `portal/audiencia/queries/occupancy.sql` e `portal/audiencia/occupancy.cfm`. Sem mudanças de CSS/JS, autenticação, DSN, coleta, carteira, cobrança, retenção, `tb_log` ou permissões. Query não é migração a executar no banco. Nenhuma operação Git realizada.

### Testes executados

- PostgreSQL local isolado, role somente SELECT: 1.565 assertions passaram, incluindo 200 oportunidades vazias no Acre sem visualizações, preenchimento sem exposição, filtros, regiões, formatos, rotações, estados pendentes e empates de timestamp. O teste primeiro reproduziu a falha contra a consulta anterior. Rerun independente pelo agente principal também passou.
- CFML focal renderizado: assertions passaram para oportunidade/vazio, servido sem visto por 1s, incerteza, zero e indisponibilidade; RED foi observado contra a view anterior.
- Contrato CFML do backend: 17 assertions passaram, mantendo falha isolada e reconciliação.
- Node charts + compatibilidade SQL Adobe: 6 testes passaram.
- Home completa renderizada em modo local `--render-only`: passou. Navegador controlado por CUA confirmou cartões e barras em 1280px e 390px, sem cortes nos rótulos; viewport temporário restaurado. O runner antigo de navegador não foi usado como evidência de aprovação: não dispunha de Playwright nesse ambiente.
- Revisão independente estática dos arquivos, testes e publicador: sem achados materiais. `git diff --check` e sintaxe do publicador passaram.

### Recibo de publicação

Destino `/var/www/business.roadrunners.run`; pacote e dois backups originais preservados em `/var/backups/business-audience-opportunities.HrOICK`, fora do webroot. Troca atômica por arquivo, consulta antes da view, com baseline imediatamente reconferido. Metadados preservados. Trinta arquivos protegidos de Business/RoadRunners permaneceram com o mesmo SHA-256.

| Arquivo | SHA-256 publicado |
| --- | --- |
| `portal/audiencia/queries/occupancy.sql` | `a6f008e5b962e033c9b960bff78fe7817e9e7997d4bc498e9e55d8468e0aa4bc` |
| `portal/audiencia/occupancy.cfm` | `5be2eebf3c7666baa03a0481b2ff378e37aed1ed01ab60aa78efe58a94331aa7` |

Pacote SHA-256 `b8121a83523d4a16fb8df9e207034ac5127de35ccceeaab6e83c3b816f9b8f4b`; manifesto `259a4ce793f5261be547514f318ea73319bdb840edbd264082fd5015a87a6e2d`. Hashes publicados, backups e metadados verificados novamente após a leitura funcional. SQL direto retorna HTTP 403; painel sem sessão retorna 302. Apache ativo. Serviço correto `cf2023.service` listado como `loaded active exited` (o nome genérico `coldfusion.service` não existe); o funcionamento da aplicação foi confirmado pela resposta autenticada do Adobe, sem reinício de serviço.

### Resultado real no painel

Leitura após publicação, em 12/09 às 23:23 BRT: 7 dias, ambiente prod, internos excluídos, contexto comercial, todas as páginas e dispositivos. Valores históricos, sujeitos a novas recepções e cache de até um minuto.

| Recorte / formato | Oportunidades | Preenchidas | Sem anúncio | Sem confirmação |
| --- | ---: | ---: | ---: | ---: |
| Todas as UFs — total | 5.258 | 2.677 (50,9%) | 2.151 (40,9%) | 430 (8,2%) |
| Todas as UFs — Ads | 2.884 | 492 (17,1%) | 2.151 (74,6%) | 241 (8,4%) |
| Todas as UFs — banners | 2.374 | 2.185 (92,0%) | 0 (0,0%) | 189 (8,0%) |
| AC — total | 48 | 21 | 27 | 0 |
| AC — Ads | 27 | 0 | 27 (100,0%) | 0 |
| AC — banners | 21 | 21 (100,0%) | 0 | 0 |

Anúncios vistos por 1s permanecem separados: 1.769 no geral e 14 no Acre, sem inventar visualização para os 27 Ads vazios. Percentuais por segmento podem somar 100,1% por arredondamento a uma casa, sem inconsistência nas contagens inteiras.

O Acre foi selecionado pela interface e o painel retornou a todas as UFs ao final. Sessão autenticada existente preservada, sem novo login/troca de conta, acesso ao banco por console ou navegação pública gerando Ads. O antigo 100% foi substituído pela ocupação baseada nas oportunidades efetivamente registradas.
