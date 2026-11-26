# Idades e gerações — método revisado em 05/10/2026

Decisões do responsável: idade em **31/12 do ano da prova**; faixa cruzando gerações atribuída inteira à geração mais próxima. Sem nascimento, usamos a idade central inteira: `floor((idade mínima + idade máxima inclusiva)/2)`. Cada participação recebe uma única atribuição. No empate entre duas idades centrais, escolhemos a menor; essa aproximação não certifica a idade individual.

Nascimento plausível tem prioridade: data até a prova e idade de 0 a 120 em 31/12. A faixa da categoria só é usada na sua ausência. Os ranges corrigidos pelo DBA já estão incorporados aos novos recortes. Categorias como **GERAL F SOCIO** continuam sem idade; o nome da categoria não permite inferir uma faixa etária.

| Geração | Nascimento fixo | Idade em 2025 | Idade em 2026 |
|---|---|---|---|
| Alfa, somente 14+ | 2010 em diante | 14–15 | 14–16 |
| Z | 1997–2009 | 16–28 | 17–29 |
| Millennials | 1981–1996 | 29–44 | 30–45 |
| X | 1965–1980 | 45–60 | 46–61 |
| Boomers | 1946–1964 | 61–79 | 62–80 |
| Anteriores a 1946 | Até 1945 | 80+ | 81+ |

Em 2026, a faixa **45–49** tem centro **47** e vai inteira para **X**. Se uma pessoa dessa categoria tem nascimento plausível em 1981, sua idade de 45 em 31/12 a classifica como **Millennial**. Sem nascimento, 14–19 tem centro 16: Alfa em 2026 e Z em 2025. As coortes de nascimento ficam fixas; os limites de idade mudam a cada ano.

Faixas finitas de 14+ que atravessam somente duas gerações permitem a aproximação. Faixas abertas que atravessam grupos, que incluem menores de 14 e que cruzam mais de duas gerações continuam indeterminadas. Ranges inválidos não são imputados. A classificação nas faixas etárias padrão exige contenção integral e é distinta da aproximação de geração.

**Percentual de geração** = participações da geração / todas as participações do gênero na população × 100. Menores de 14, ausentes e indeterminados permanecem no denominador, em grupos separados. A aproximação fica quantificada em “Faixa atribuída por proximidade”: em 2026 Jan–Set são **603.970**, **13,42% de 4.500.869**.

**Variação Alfa + Z revisada** = `share(ano) − share(ano base)`, em **pontos percentuais**, em que `share = (Alfa 14+ + Z) / todas as participações do gênero × 100`. Não é crescimento de quantidade. A edição 2025 compara anos completos de 2023, 2024 e 2025 na população da view atual; 2026 compara Jan–Set de 2024, 2025 e 2026 com conclusão registrada. A fórmula histórica do PDF continua desconhecida, e os destaques históricos ficam separados da nova fórmula.

SQLs, resultados, revisões e congelamentos estão no [caderno único 6 do Business](https://business.roadrunners.run/estudo/?caderno=6):

| Fonte | Célula | Congelamento |
|---|---:|---:|
| 2023 anual | 346 | 156 |
| 2024 anual | 348 | 158 |
| 2025 anual | 349 | 159 |
| 2024 Jan–Set | 352 | 162 |
| 2025 Jan–Set | 354 | 164 |
| 2026 Jan–Set | 357 | 167 |
| Variações Alfa + Z | 380 | 190 |

As fontes anteriores do DBA foram preservadas. O recálculo de idades e gerações de 2025 mantém as outras páginas nas suas próprias coletas; não representa uma nova coleta integral de todos os temas do ano. A web lê saídas congeladas, sem executar essas consultas durante a visita.
