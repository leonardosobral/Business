## Comparativos por edição — maratonas, revisão de 19/10/2026

A edição 2025 passa a comparar **2024 × 2025, janeiro a dezembro nos dois anos**. A edição 2026 preserva **2025 × 2026, janeiro a setembro nos dois anos** (17 pares, congelamento246). Não comparar diretamente os totais anual2025 e parcial2026.

### Fontes e resultados

- Inventário2024: célula444, congelamento258. Derivado da versão atual da query425, com troca do ano. 88 candidatas,64 com conclusões elegíveis,44.041registros; **inventário não é seleção nacional validada**.
- Pareamento2024–2025: célula445 versão3, congelamento260. Seleção2025 preservada do congelamento244 e vínculos atuais lidos antes da execução.20pares operacionais. Exige um agregador positivo comum e uma candidata de maratona em cada ano; treinos sem percurso/resultado42km não contam como outra edição (caso Floripa). O congelamento259 foi um diagnóstico intermediário e não alimenta a web.
- ConciliaçãoCR: célula446 versão2, congelamento261. [Artigo da Contra-Relógio de27/11/2024](https://contrarelogio.com.br/ultima-atualizacao-do-ranking-cr-2024-agora-com-os-selecionados-nas-maratonas-de-curitiba-pelotas-sorocaba-e-monumental-cheque-sua-classificacao/),33provas e respectivos volumes individuais transcritos na query. Identificação de Goiânia ainda provisória e fora dos pares. A CR serve para conferir as provas; os volumes do comparativo são todos Road Runners.
- Após restringir os20pares à listaCR2024 com identificação confirmada: **19pares,36.689→47.464conclusões registradas, +29,3684756%**. Cálculo: `(sum(n2025)/sum(n2024)-1)*100`; não média das variações individuais.
- Os47.464registros cobrem **87,5170557%** dos54.234registros das41maratonas selecionadas em2025. Essa cobertura é de volume da nossa seleção, não percentual do mercado nacional.
- Tubarão (87→100registros) tem par operacional, mas não consta da listaCR2024 citada; fica fora deste comparativo. Os outros21eventos selecionados em2025 não tinham um par elegível no diagnóstico:6sem agregador e15sem candidata2024 vinculada. Cadastro de vínculo não foi alterado.

### Elegibilidade, limites e divergências

Mesmos filtros2025 para2024: Brasil, rua, data do evento no ano, percurso de42a42,2km, status_final=0, homologado/concluinte verdadeiros, tempo positivo, pcd=false; exclui modalidades especiais, revezamento, trail e similares conforme regex registrada em444. Conclusões não equivalem a pessoas únicas. Não houve tempo abaixo de2h nos19pares; ausência de anomalia não comprova coleta integral.

A variação é **descritiva dos resultados registrados**. Diferenças de coleta, filtros ou importação ainda podem afetar os volumes; não isola crescimento real e não é estimativa nacional. O campo resultado_completo não foi tomado como prova de completude.

**Inconsistência na própria referênciaCR:** as33linhas somam41.280concluintes; o total impresso é39.358, diferença1.922. Nenhum desses dois totais é denominador do comparativo. Os19pares somam36.698naCR e36.689naRR, diferença líquida−9, mas isso não indica igualdade por prova: há diferenças que se compensam. A query261 conserva todos os deltas individuais.

Pendências de conferência2024: Pelotas#26402 tem cadastro e link externo, mas nenhum resultado nem percurso42km; Internacional de Olinda#9173 tem348elegíveis ante470naCR; Foz#13752 tem473ante503; Goiânia#13082é uma identificação provável e tem230ante212,com1tempo abaixo de2h. No inventário fora da coorte também há possível duplicação de Xangri-Lá/Parkshopping, Rastro25km cadastrado como42km e revezamento Rota do Sol. Não consolidar esses casos como maratonas validadas sem revisão.

### Publicação

A versão web incorpora o resultado261 congelado em `pairs2025`;2026 mantém seu resultado original. Gráfico mostra os10maiores pares por volume no ano atual; tabela recolhida mostra todos19(2025) ou17(2026). Fontes recolhidas trazem os deltasCR e o problema do total. Demais resultados, publicações do estudo principal e queries preexistentes do DBA preservados. **PDFs não regenerados**, conforme solicitação de validar primeiro na web.
