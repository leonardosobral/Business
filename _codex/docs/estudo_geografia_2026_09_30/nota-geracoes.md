## Gerações — auditoria da regra legada, 30/09/2026

Consulta #268, revisão 1, congelamento #51. Auditoria de participações, sem dados pessoais. Não é nova classificação editorial nem comparação de evolução entre anos.

As faixas de P05 são [0,15), [16,28), [29,44), [45,60), [60,infinito). Ficam lacunas nas idades 15, 28 e 44. O operador && verifica qualquer sobreposição: uma faixa ampla entra em mais de uma geração.

Em 2025, de 5.279.415 participações homologadas/status 0 no Brasil (todas as modalidades): 1.112.908 atravessam mais de uma geração, produzindo 2.499.303 atribuições; 1.181.280 não têm idade; 216 têm intervalo vazio; 15 não encontram faixa; 466.840 sobrepõem apenas uma faixa mas ultrapassam seus limites; 2.518.156 ficam integralmente contidas em uma faixa legada. Normalizar as atribuições para 100% esconde essas diferenças.

Exemplos: [25,30) significa 25 a 29 anos e soma 331.514 participações, atribuídas a Z e Millennials. [40,50) soma 288.972, atribuídas a Millennials e X. [0,100) soma 54.200 e cruza as cinco gerações.

No diagnóstico 2026 até 26/09, com filtro adicional concluinte, 1.033.699 participações cruzam várias faixas legadas, 662.812 têm idade nula. Usar as mesmas idades de 2025 em 2026 não mantém uma coorte de nascimento; esses números são somente diagnóstico.

P07 usa outra regra: get_id_geracao transforma idade_range em anos e escolhe a primeira sobreposição. Isso evita múltiplas linhas, mas atribui faixas amplas à geração mais antiga compatível. A função usa limites 1946/1965/1981/1996/2011 e também 2010 para Alfa, que retorna 0; não é equivalente às faixas de P05. A inversão dos limites exclusivos da idade exige conferir a data de referência antes de ser corrigida.

Próximo critério a implementar: declarar a data de referência da idade e limites de nascimento sem sobreposição; classificar somente faixas integralmente contidas em uma geração; manter ambíguas/nulas/fora do universo explícitas. Não usar distribuição proporcional inventada nem a primeira geração possível. Só então recalcular os mesmos critérios para 2025 e 2026. As saídas legadas e a referência histórica permanecem disponíveis para comparação; a auditoria não valida sua distribuição como demografia exata.
