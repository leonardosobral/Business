# Idades, gerações e cruzamentos com distância

Publicado em 01/10/2026: [2025 — recálculo](https://roadrunners.run/brasilquecorreprovas/web/?ano=2025&fonte=atual#idades), web v10/execução 95; [2026 — parcial](https://roadrunners.run/brasilquecorreprovas/web/?ano=2026#geracoes), web v7/execução 96. Caderno único [Business Estudo](https://business.roadrunners.run/estudo/?caderno=6), nota 299 rev1.

O responsável confirmou idade em 31/12 do ano da prova. O recálculo prioriza nascimento plausível (não futuro, idade 0–120), que não certifica o cadastro. Na ausência dele, a faixa textual válida da categoria só entra se estiver inteira em um grupo. Não duplica participações, reparte intervalos nem escolhe a primeira geração compatível. Ausentes, ambiguidades e menores de 14 permanecem no denominador e na apresentação.

Coortes fixas, alinhadas aos rótulos do PDF em 2025: Alfa nascimento a partir de 2010 e idade 14+; Z 1997–2009; Millennials 1981–1996; X 1965–1980; Boomers 1946–1964; anteriores a 1946 separados. Isso é uma regra revisada, diferente dos SQLs legados e da função pública `get_id_geracao`, que não foi alterada.

`gera_resultados` e `nova_gera_resultados` gravam nascimento e `extrair_faixa_etaria(categoria)` independentemente. A carga não registra se a categoria usa idade no evento ou em 31/12. A interpretação da faixa em 31/12 é uma decisão deste estudo. Existem fronteiras não uniformes na extração (10–17 pode virar [10,17)); não houve correção retroativa dos dados ou dessas funções.

| Ano | Consulta / versão | Congelamento | Base de participações |
| --- | --- | --- | ---: |
| 2023 | 295 rev1 | 88 | 1.406.551 |
| 2024 | 296 rev1 | 89 | 3.231.005 |
| 2025 | 294 rev1 | 87 | 5.279.220 |
| 2026 | 297 rev1 | 90 | 4.274.231 |

Todas: BR pela data final, status 0 e homologado. 2023–2025 são anos completos, com população equivalente à view atual, sem filtro adicional de conclusão. 2026 termina em 26/09 e exige conclusão. Cada fonte retorna 156 linhas agregadas, sem nascimento ou identificador individual; as somas de idade, geração e origem fecham na base geral e em F/M. Não comparar 2026 parcial com anos completos como se fossem períodos equivalentes.

Em 2025, 33,32% da base tem nascimento plausível; 50,75% depende da faixa da categoria; 15,93% não tem idade informada. A classificação das idades deixa 13,33% em intervalos indeterminados. As gerações deixam 14,59% indeterminados, além dos ausentes. Cobertura de origem e classificação são medidas distintas.

P07 considera rua e percurso positivo, com faixas contínuas >0 a <6, 6 a <11, 11 a <30 e >=30 km. Gerações dentro da distância usam todas as participações daquela distância, inclusive menores e desconhecidos. Distâncias dentro da geração usam somente as participações daquela geração com percurso positivo; as quatro parcelas somam 100%. Alfa e anteriores a 1946 passam a aparecer no recálculo.

O PDF e o CSV histórico continuam iguais. Os panoramas preservam 5.279.415 participações em 2025 e 4.214.040 em 2026, suas datas e populações próprias. Comparativos mensais, crescimento e coortes de edições também permanecem intactos. As novas coletas não são uma atualização desses indicadores nem uma estimativa do mercado. O corte oficial 14+ do universo nacional ainda está em conciliação; esta entrega mostra todas as participações, com menores e pendências separados.

## Publicação e validação

- 31 casos SQL sintéticos aprovados: célula 298 rev2, congelamento 92; arquivo `fronteiras.sql` e respostas agregadas preservadas.
- A primeira expectativa de [25,30) foi corrigida: corresponde a 25–29, mas atravessa Z/Millennials. Execução 91 permanece no histórico. Nenhuma fonte real precisou ser alterada.
- Saídas finais: 249 rev18/95 e 251 rev12/96. Candidatas intermediárias 93/94 não foram publicadas; a prévia identificou definições novas ausentes antes da correção.
- Contratos imutáveis novos 2025/5 e 2026/3; função de validação e contratos anteriores intactos. O contrato 2026/3 explicita o contador numérico do status `coletado_notebook`, já existente nas comparações. A primeira migração foi revertida por validação antes da correção.
- Preview oficial do Business exatamente igual aos candidatos. Pacotes antigos 2025/86, 80, 45 e 2026/81 continuam válidos.
- 66 testes do adaptador, gráficos e conciliações passaram; testes novos conferem limites, conservação, dois denominadores, referências/CSV e preservação dos outros capítulos.
- Chrome: prévia local em 390 px e produção desktop; filtros e alternância PDF/recálculo conferidos, sem erros de console. Em produção, a tentativa de emulação continuou em 1516 px e não foi contada como verificação mobile. A prévia e os dois arquivos publicados têm a mesma implementação.
- JSONs públicos idênticos aos congelamentos (acrescida apenas a identificação de publicação); hashes do runtime conferidos. `noindex,nofollow` e `private,no-store` preservados.
- 136 células originais intactas; somente as duas saídas de publicação foram revisadas. Seis células novas, no mesmo caderno. Nenhuma consulta original ou do DBA sobrescrita; revisões relidas e protegidas por versão esperada.

As fontes editáveis são `previa/estudo.js` e `previa/parcial.js`. O gerador manteve `web/` correspondente. Apenas esses dois arquivos JavaScript foram publicados; não houve mudança em auth, bootstrap, menu, PDF ou landing divulgada.

## Recuperação e arquivos

Runtime: `/var/backups/roadrunners-estudo-idades-20261001/runtime/RoadRunners`; restaurar os dois arquivos do baseline conforme o manifesto. Dados: republicar os congelamentos anteriores 2025/86 e 2026/81 pelo Business, com nota. Preservar contratos, células e histórico. As guardas da interface mantêm os pacotes anteriores utilizáveis.

Backup de banco: `/var/backups/business-estudo-web-20260928/database/idades-geracoes-contratos-v5-v3-status-20261001-before.json`. Migração correspondente no projeto Business, `_codex/sql/2026-10-01_estudo_web_idades_geracoes_contrato.sql`.

Esta pasta guarda coletas agregadas, consultas, candidatos, pacotes públicos, recibos, preservação e a captura de produção. O notebook continua sendo a fonte de autoria; os arquivos são evidência e apoio à revisão.

Ainda pendentes: contagens históricas exatas de volume, rótulos históricos do Norte, estações, regra de medalhas, dez métricas de perfil, cobertura de 84,1% e aceite integral das etapas 5/6.
