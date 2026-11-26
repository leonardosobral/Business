# Maratonas do Brasil — estudo vertical
Primeira edição de trabalho para a palestra do parceiro Circuito Brasil Gigante em 20/10/2026. Mesma base do estudo geral, sem alterar consultas do DBA ou os congelamentos publicados. O capítulo básico continua no estudo geral; esta seção centraliza aprofundamentos para um futuro produto pago separado. Não há venda ou publicação pública ativada nesta etapa.

## Escopo e unidade
2025: ano completo. 2026 observado: 01/01 a 30/09. A unidade é participação concluída registrada, não pessoa única, inscrição vendida ou censo nacional. Calendário cadastrado não comprova realização. Cada id_evento precisa de auditoria para descartar duplicações e modalidades indevidas.

Fontes: public.tb_resultados para 2025 (regra autoral da célula 347); estudo.vw_resultados_2026 para 2026 (adapter do BI do DBA). Critério geral: status_final=0, homologado=true, concluinte=true, evento BR, data_final no período. Maratonas convencionais: rua, ranking não false, distância 42–42,2 km, tempo líquido positivo, PCD=false e exclusão textual de modalidades especiais e revezamento. Registros desconhecidos não são imputados. Tempos suspeitos geram pendência, não exclusão silenciosa.

Floripa 2026: a fonte oficial RaceTag recuperada está na célula 402 / execução 210; se aplicada, deve substituir integralmente a contagem da mesma prova, nunca somar ambas.

## Referência externa
https://contrarelogio.com.br/ranking-cr/
Listas de provas candidatas ao Ranking CR são referência de cobertura, não censo de eventos realizados nem total de concluintes. O ranking seleciona atletas por tempo e idade. Conferir prova, ano, data, cidade e realização, medição e envio de resultados separadamente. A conciliação integral das listas é uma etapa própria.

## Entregas
1. Resumo visual para palestra: 2025, distâncias, maratonas, prévia Q3/2026 e limites.
2. Auditoria por prova e congelamentos reproduzíveis.
3. Projeção anual apenas como cenário explícito, com sazonalidade de 2025; jamais apresentar como observado ou previsão validada de mercado.
4. Evolução do produto: distribuição por sexo, idade/geração, desempenho, concentração, geografia/calendário, edições pareadas e cobertura CR. BQ depende de regras e idade específicas; não reaproveitar classificação geracional para qualificação.
