## P10 — Estados, cidades e capital/interior

**Editor:** [UFs](https://business.roadrunners.run/estudo/?caderno=1&secao=7); [Concentração de mercado](https://business.roadrunners.run/estudo/?caderno=1&secao=8); estados vêm diretamente de evt.estado, sem cruzar cidades. **DataGrip:** INFOGRAFICO, blocos 13–14; cidades são agrupadas apenas por nome, reunindo homônimas de UFs diferentes.

**DBA:** regiao_capital_interior é uma fonte candidata, mas o primeiro SELECT usa uma coluna total inexistente e divide pelo total nacional. O relacionamento nome_cidade=evt.cidade não usa UF. Auditoria de 27/09: 434.079 participações sem correspondência; 381.706 linhas ligadas a outra UF. Esses efeitos pertencem àquela regra/população, não ao PDF inteiro.

**Decisão:** estados são comparáveis por fonte; cidades ganham UF na consulta candidata. Capital/interior abaixo usa id_localidade já presente na fato BI e contabiliza ausentes; tem população diferente e não certifica o gráfico histórico. O percentual é exibido dentro de cada região e com não classificados visíveis.