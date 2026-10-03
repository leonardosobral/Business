## P13/P15 — revisão de 30/09/2026

Fontes lidas antes das alterações: células 213–216, 221–224, 240, 242, 249/251 e 263–266. As fontes SQL do DBA/DataGrip e a reprodução legada permanecem intactas. O caderno único é o 6; novas candidatas e comparações ficam nas seções já existentes. A web continua lendo o pacote publicado, sem consultar tabelas de atividade ou resultado a cada visita.

### Menores tempos das maratonas 2025

Célula 281 rev2, congelamento 67: 50 médias dos menores tempos, com ordenação global por tempo e ID do resultado. Top 10/100 seleciona min(n,10/100) conclusões; os grupos percentuais selecionam ceil(n*p), com p=5%, 10%, 50%. A média é arredondada ao segundo; empates seguem ID para manter o tamanho determinístico. Retorna quantidade, população, limite e quantidade de registros empatados no tempo limite.

Todas as dez populações conferem com o congelamento 41: 43.395 conclusões no total, eventos históricos selecionados, BR/rua/2025 pela data final, 42–42,2 km, status 0, homologado, concluinte, tempo positivo, PCD=false e exclusões de modalidade do SQL legado. Não é recuperação da base histórica do PDF nem correção dos cadastros.

Célula 283 rev1, congelamento 70: referência PDF/34, cálculo legado/48 e cálculo revisado/67 lado a lado. Na Maratona de Aracaju, o Top 10 legado inclui 20 resultados e tem média 03:00:03 (valor do PDF); a seleção global revisada inclui 10 e tem média 02:38:51. Diferença de regra deve ficar explícita, sem substituir a referência histórica. Em provas com menos de 2.000 conclusões, os melhores 5% podem ter menos de 100 resultados e média menor que Top 100: comparar ordem de médias pelo tamanho real de cada grupo, não pela posição das colunas.

2026 não recebe estes IDs/valores: a seleção é própria do ano e os tempos suspeitos já registrados em Floripa/SP City continuam exigindo revisão. Medalhas seguem sem regra recuperada.

### Atividades da plataforma

O SELECT original é a célula 223 rev1, congelamento 29: atividades de 2025 por activity_date e tipo não nulo, incluindo registros sinalizados como excluídos pelo Strava. Sua população bruta de 1.157.156 confere exatamente com a nova auditoria. O tratamento do webhook em api/integrations/strava/batch-refresh.cfm também reconhece aspect_type=delete como exclusão.

Célula 282 rev2, congelamento 69: total bruto, indicação delete e total sem essa indicação por tipo em 2025. São 17.588 exclusões entre registros com tipo; 3 sem tipo ficam fora de ambos os denominadores. Base revisada: 1.139.568. Célula 280 rev1, congelamento 65: dados de 2026 até 26/09, 313.818 brutos, 5.398 indicações delete e base derivada revisada de 308.420, sem tipo nulo. Coleta própria de 30/09; não altera as provas ou comparativos já congelados.

Célula 284 rev1, congelamento 71: deriva 22 valores (11 tipos × 2 anos) de 69/65, com percentual bruto e referência PDF de 2025. Denominador inclui Run e todos os tipos válidos, não apenas os onze destacados. Contagem representa atividades importadas, não usuários únicos ou resultados de provas. Ano inteiro de 2025 e parcial de 2026 não são comparáveis como volumes anuais.

Mapeamento exato: WeightTraining=Fortalecimento; Walk=Caminhada; Workout=Treino livre; Ride=Pedal; Swim=Natação; Yoga=Yoga; VirtualRide=Rolo; Hike=Trilha; Elliptical=Elíptico; Crossfit=Crossfit; StairStepper=Stepper. Não agrupar TrailRun como Hike nem renormalizar os onze percentuais para 100%. A web usa as cores do PDF para os cinco tipos principais e cinza para os demais.

### Cards de perfil ainda pendentes

As dez métricas da página 15 não foram recuperadas. Os scripts “perfil” do DBA tratam da tabela de participações em provas, sem consultas para associação de resultados, agenda, equipe, desafios, conexão/premium, seguidores, peso ou tênis. A tabela atual de usuários tem alguns campos candidatos, mas ela não prova o universo histórico, denominadores ou o significado do sinal “+”. Não publicar uma população improvisada para preencher os cards. A pergunta sobre +26% segue pendente.

### Saídas e validação

2025: célula 249 rev11, congelamento 72, derivado de 63. Somente 61 comparações alteradas (50 grupos + 11 atividades); histórico, totais e outros recortes preservados. Conciliação: 309 recalculados no notebook, 58 compatíveis por arredondamento, 44 divergentes e 155 ainda sem recálculo.

2026: célula 251 rev8, congelamento 74, derivado de 64. Somente 11 comparações de atividades alteradas; 453 calculadas e 82 pendentes. Totais, mulheres, meses, provas cadastradas/coletadas, coortes e tempos suspeitos preservados. Revisões iniciais com timeout ficaram no histórico; a otimização muda apenas o processamento. Congelamento 73 não deve ser promovido: a contagem de estados foi conferida na revisão seguinte 74.

Contrato oficial dos dois pacotes aprovado antes de publicar. Testes verificam número de resultados por grupo, bases idênticas, médias ordenadas pelo tamanho, exclusões por tipo, denominador de todos os tipos, ausência de valores inventados, referência e comparativos preservados. As quantidades ficam na tabela “Ver valores e fonte” e no CSV.
