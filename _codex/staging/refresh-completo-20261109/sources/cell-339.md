# Sugestões para a evolução do estudo — referência Ticket Sports

Proposta registrada em 05/10/2026 após a leitura do PDF Perfil do Atleta Brasileiro Ticket Sports 2025/2026. São candidatos a novas telas, ainda sem queries/resultados publicados. Manter neste caderno6; a web continua consumindo somente saídas revisadas e congeladas.

## Fontes e populações

Ticket Sports: público com pelo menos uma inscrição na plataforma, eventos/modalidades diversos (PDF p.3 e p.15), dados de compras. Nosso panorama: conclusões de provas, com a população/corte de cada indicador; perfil usa usuários cadastrados, uma base própria. Preços atuais são ofertas resumidas por evento, sem quantidades vendidas. Sexo, idade, geografia, meses, distâncias e desempenho já existem na web; enriquecer comparativos existentes em vez de duplicar telas.

Referência de preços: PDF p.20, 2025 presencial R$125,53, virtual R$99,36, linha Média R$112,45. Não pressupor fórmula, ponderação, exclusão de PCD/idoso/kids ou taxas. O percentual +14,71% acompanha a linha Média; não significa necessariamente variação só dos presenciais. A comparação presencial2024(R$119,39)→2025 é de aproximadamente5,14%. Não transportar valores desta plataforma para conclusões, nem afirmar crescimento dos nossos preços2026. A nota337 e fonte338/#146 registram a normalização pendente.

## Ordem proposta

1. **Preços comparáveis da categoria geral adulta.** Aproveitar opções capturadas por categoria/modalidade/distância/kit/lote. Preservar preço bruto, apartar descontos/restrições/kids/caminhada e mostrar desconhecidos. Comparar kits equivalentes e explicitar qual lote/data está sendo usado; não multiplicar pela metade nem descartar todos os baratos. Exige classificação e regra de escolha da opção. Prioridade para corrigir a leitura econômica, sem estimar vendas.

2. **Tamanho e concentração das provas.** Mediana de concluintes por evento/modalidade; faixas de tamanho; participação dos maiores eventos no volume. Potencial com resultados e eventos existentes, sem precisar identificar pessoas. Sempre distinguir modalidades de uma mesma prova, coleta parcial e elegibilidade; usar as mesmas provas/corte para variação anual. Complementa a comparação por pares já publicada, não mede faturamento nem lotação sem capacidade/inscritos.

3. **Recorrência: quantas provas por corredor.** Distribuição1,2,3,4,5+ eventos e mediana por pessoa, por ano. Inspirada na p.21. Potencial apenas na população com vínculo de identidade confiável (id_usuario>0 e associação validada); resultados deduplicados por pessoa/evento, sem somar modalidades como várias provas. Medir primeiro a cobertura desse vínculo. Não unir homônimos pelo nome; não extrapolar a frequência dos usuários vinculados para milhões de conclusões. Primeira aparição na base não significa primeiro evento da vida.

4. **Retorno à mesma prova.** Percentual dos concluintes identificados de2025 que reaparecem na edição2026, dentro dos pares do mesmo evento vinculados corretamente. Pairs/circuitos devem estar separados e as duas coletas comparáveis. Mostrar também novos identificados, retornantes e não observados. Não observado em2026 não prova abandono da corrida; prova futura/incompleta não conta como ausência. É uma extensão útil dos agregadores e da coorte de crescimento já existente.

5. **Progressão nas distâncias.** Pessoas identificadas que passam de5 para10,21 ou42km, com ordem de datas e número mínimo de observações. Resultados homologados e distâncias normalizadas; mesma identidade/regras da recorrência. Comparar desempenhos em distâncias equivalentes, sem dizer que um percurso mais longo ou mais rápido equivale automaticamente à melhora. Exige cobertura de identidade; identificar primeiro registro conhecido, não estreia na vida.

6. **Turismo de corrida.** Cidade/UF de residência versus cidade/UF da prova, fora do município e fora da UF; destinos mais frequentes. Inspirada na p.6. A geografia atual da web é do evento, não da residência. Potencial em amostra identificada com localidade confiável; código/UF, sem cruzar só nome de cidade. Residência atual não reconstitui residência histórica. Não usar cidade da assessoria/equipe como domicílio do atleta.

7. **Equipes e assessorias nas provas.** Expandir o percentual do perfil já existente com presença nos resultados, composição por gênero/distância e recorrência. Inspirada no módulo de grupos p.23–29. Há campos equipe/assessoria, mas nomes e finalidade precisam normalização; equipe no resultado não confirma assessoria paga ou compra pelo módulo. Desconhecidos ficam explícitos; evita converter a população do perfil em população nacional.

## Dependem de novas fontes

Grade de camisetas (p.12) é útil para organizadores, mas depende das quantidades efetivamente escolhidas por modelo/tamanho, não dos kits ofertados. Dias/horários e meses de compra (p.13–14), pagamento/parcelamento (p.17–18), dispositivos de compra (p.19) e receita por modalidade (p.16) dependem de transações. Analytics de visita ou mês da prova não substitui compra. Nenhuma fonte de vendas desse tipo foi disponibilizada para esta análise; não reproduzir essas telas com proxy que mude o significado.

## Execução futura

Para cada novo indicador: definir pergunta/população/corte/grão/identidade, conferir fonte viva antes de editar, salvar SQL no caderno, executar/congelar, auditar cobertura e denominadores, adicionar ao contrato e saída da web de modo aditivo. Não alterar consultas do DBA ou selecionar automaticamente o congelamento mais recente. Começar por preços comparáveis e tamanho das provas; recorrência/retorno/progressão dependem da auditoria de identidade.
