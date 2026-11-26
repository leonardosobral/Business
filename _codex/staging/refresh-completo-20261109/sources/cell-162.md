### Idades — duas fontes, geral e por sexo

Derivação explícita do bloco do editor: executa geral/F/M em tb_resultados e vw_resultados, mantendo 13–19, sobreposição e duas casas para comparar. As repetições por fonte/sexo são intencionais.

**Linhas de origem:** `editor:03_faixa_etaria.sql.txt:4`, `datagrip:INFOGRAFICO.sql.txt:9`.

A saída representa a base atual no momento da execução; não é o snapshot usado no PDF.

**Otimização da execução:** a revisão 1 atingiu 45s. A revisão seguinte agrega por intervalo/sexo antes do cruzamento. Preserva as populações, as sobreposições e os percentuais; reduz a repetição de varreduras.