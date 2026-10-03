## P09 — Regiões e gêneros · 30/09/2026

Consulta 287 rev1, congelamento 75: 85 percentuais derivados de contagens imutáveis; não executa nova coleta regional. Fontes 21/195 rev1 e 22/199 rev1 (somente DataGrip, vw_resultados), congeladas em 28/09; 2026 deriva da saída 74, originada do snapshot 33 v3.

Dentro da região inclui F, M e o saldo de outros/não informados. Distribuição de cada gênero usa denominador nacional próprio: 2025 F=2.790.252 e M=2.487.225; 2026 F=2.268.950 e M=1.943.942. Norte vem da contagem da fonte; 2026 região não informada é o saldo nacional após as cinco regiões, F=8.061/M=6.598. Nenhuma categoria é normalizada para fechar artificialmente 100%.

Conferido visualmente contra a p.9 do PDF: os rótulos gerais de 2024 são Nordeste 19,3% e Sul 18,1%, enquanto a fonte 21 resulta Nordeste 18,1% e Sul 19,3% (arredondados). Existe divergência entre a referência e a fonte, com rótulos aparentemente invertidos. A base histórica não foi guardada: não concluir automaticamente que o PDF ou a consulta esteja errado. Manter referência, recálculo e pendência explícitos. Norte F/M não é legível nesses dois gráficos históricos; não foi inventado por diferença.

Saída 2025: célula 249 rev13 / congelamento 80, contrato 3. Saída 2026: célula 251 rev10 / congelamento 81, contrato 2. Contratos anteriores preservados. O novo contrato aceita apenas as categorias explicitamente registradas nesta versão e continua rejeitando campos desconhecidos e alterações de referência. Comparação P09/P10 segue na próxima consulta; não certifica equivalência de população.

## P10 — UFs e cidades · 30/09/2026

UFs: fonte 22/DataGrip, 5.279.415 participações; todas as UFs e as nove destacadas no PDF mais Outros, contagens preservadas. Não usa fonte Editor, cujo universo é diferente.

Cidades: célula 288 rev2 / congelamento 77. Consulta 201 rev1 / 23 continua intacta. Valida nome/UF único e concordância do código positivo; normaliza apenas acentos latinos, caixa e espaços. Agrega resultados por evento antes do cruzamento, sem multiplicar participações. Não usa cidade sem UF. Não altera cadastros.

2025 anual: BR, status 0, homologado, todas as modalidades/idades, sem filtro adicional de conclusão; base própria 5.279.220. 5.247.745 em cidades validadas. 31.081 em 26 eventos com código divergente e 394 em 3 eventos sem correspondência; todos permanecem no denominador. Exibe as 14 cidades da referência PDF, mesmo quando o ranking atual muda. A fonte 23 tinha base 5.279.415: diferenças também envolvem a base viva/coleta posterior, não apenas normalização.

2026 até 26/09: BR, status 0, homologado e concluinte, todas as modalidades/idades; coleta própria em 30/09, base 4.274.231. 4.266.163 em cidades validadas; 8.068 em 19 eventos sem correspondência, mantidos no denominador. Ranking das 14 cidades validadas mais frequentes, labels com UF. Brasília/DF é uma linha (190.151), não duas variantes. 2025 Brasília/DF tem 228.132 participações validadas.

A base deste novo ranking não substitui os 4.214.040 do panorama, os comparativos mensais, crescimento ou coortes; demais recortes de 2026 preservados. Capital/interior é outro recorte próprio de rua (fonte 52), também preservado. A primeira execução de cidades 76 ficou truncada (1000 linhas) e não foi congelada; revisão 2 retorna 36 linhas completas de destaques/integridade/qualidade.
