## P09 — Regiões e gênero

**Editor:** [UFs](https://business.roadrunners.run/estudo/?caderno=1&secao=7). O segundo bloco seleciona uf.uf como regiao; o HTML 75 contém SE/NE/S/CO/N. O HTML foi atualizado em 30/01 e o SQL em 01/02/2026: vínculo de execução não comprovado.

**DataGrip:** INFOGRAFICO, bloco 15, usa uf.regiao corretamente, mas está fixo em 2024/M.

**DBA:** cruza cidade por nome sem UF e pode perder/multiplicar linhas. O bloco chamado capital/interior também contém sexo por região; não é equivalente ao agrupamento direto pela UF do evento.

**Decisão:** derivar de DataGrip com ano/sexo explícitos. A correção do bloco do editor é uf.uf → uf.regiao, registrada como derivação; o original não foi sobrescrito.