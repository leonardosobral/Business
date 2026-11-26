## P07 — Gerações nas distâncias

**Editor:** não há SQL equivalente recuperado.

**DataGrip:** INFOGRAFICO_DISTANCIAS, blocos 9–10; os mesmos totais têm dois denominadores: geração dentro da distância e distância dentro da geração.

**DBA:** o arquivo de distâncias não contém esses dois blocos; a carga BI registra dimensões relacionadas, com outra população.

**Decisão:** a consulta abaixo reproduz a função get_id_geracao com CASE, conforme definição inspecionada em produção em 28/09/2026. A função não foi habilitada nem alterada no banco. Preserva ordem de prioridade e exclusão de zero; Alfa não aparece nos quatro grupos desta página.