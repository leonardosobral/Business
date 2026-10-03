## Geografia conciliada — 30/09/2026

Consulta #267, revisão 2, congelamento #52. Substitui a alternativa da fato BI apenas nos recálculos de capital/interior. Não altera os valores do PDF nem os cadastros de cidades/eventos.

O vínculo valida cidade + UF normalizadas e únicas. Código positivo do evento precisa concordar com essa chave; sem código, aceita apenas correspondência única. A dimensão é ligada por id_localidade e sua cidade/UF também precisa concordar. Ambiguidade, conflito e ausência permanecem no denominador como Não classificada. Região vem da UF validada, mesmo quando capital/interior não pode ser definido.

2025: rua/BR, status 0 e homologado, ano inteiro. 5.235.016 participações em 5.002 eventos; capital 3.068.448 (58,61%), interior 2.138.486 (40,85%), não classificada 28.082 (0,54%). Os 24 conflitos de código somam 27.901; duas cidades sem correspondência somam 181. Cobertura de classificação geográfica de 99,46% não é cobertura de coleta do mercado.

2026: rua/BR, status 0, homologado e concluinte, até 26/09, coletado em 30/09. 4.226.552 participações em 4.461 eventos; capital 2.225.653 (52,66%), interior 1.992.831 (47,15%), não classificada 8.068 (0,19%). Há 1.890 participações sem região; continuam no total nacional. Este novo recorte tem coleta e população próprias. Não atualiza os comparativos mensais, coortes ou totais congelados da prévia, e não deve ser comparado diretamente ao 2025 anual com critérios diferentes.

A saída contém as pendências por evento para revisão administrativa. Exemplos 2025: evento 27508, Itajaí/SC, código 4200051; evento 26862, Iranduba/AM, código 1300029. Eles não são reclassificados à força nem têm seu cadastro modificado. Não há descarte nem multiplicação de participações: os totais antes e depois dos joins foram conferidos.

Na web, percentuais usam todas as participações do respectivo recorte, inclusive não classificadas. Barras e ressalva visível evitam normalizar as duas categorias conhecidas para 100%. O PDF mantém os gráficos originais.
