## P04 — Faixas etárias

**Editor:** [Faixa etária](https://business.roadrunners.run/estudo/?caderno=1&secao=3). Tabela bruta, faixas por sobreposição (&&), geral; também inclui 40+/50+/60+. Primeiro grupo começa em 13.

**DataGrip:** INFOGRAFICO, blocos 5–9. View filtrada; o bloco de faixas está fixo em M e arredonda a uma casa. O HTML 72 mostra 13–19 = 3,48% geral, enquanto o PDF rotula 14–19 = 6,7%.

**DBA/BI:** a carga atribui uma categoria por função, com prioridade entre ranges; não é a mesma regra da sobreposição múltipla.

**Decisão:** a consulta abaixo separa população e sexo, preservando a regra histórica. Um mesmo intervalo pode entrar em várias faixas; percentuais somam 100% das associações, não de pessoas únicas. Corrigir para idades exclusivas exige uma nova metodologia.