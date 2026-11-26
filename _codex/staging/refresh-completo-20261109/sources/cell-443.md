# Maratonas — revisão web e auditoria de idades por prova · 19/10/2026

A versão web abre na prévia de janeiro a setembro de 2026. O seletor permite consultar 2025 anual. Os totais destes períodos diferentes não são usados para medir crescimento. A comparação temporal reúne as mesmas 17 provas, de janeiro a setembro nos dois anos, pelo agregador: 40.381 → 45.801 conclusões (+13,4%); retirando NB Porto Alegre, +5,1%. São resultados registrados, sujeitos à completude de captura.

As fichas individuais exibem somente as dez maiores maratonas de cada edição, ordenadas por conclusões. Os consolidados demográficos continuam incluindo toda a seleção: 41 provas em 2025 e 39 em 2026. Nenhuma prova menor foi retirada do denominador. Os PDFs anteriores permanecem arquivados; não foram regenerados nesta revisão.

## Auditoria por prova

As consultas novas reproduzem os filtros e classificações dos congelamentos 250/251, sem alterar as células anteriores. Os congelamentos 254/255 preservam a auditoria quinquenal anterior. Conforme nova orientação do usuário, os congelamentos 256/257 recalculam perfil e auditoria por prova com faixas de dez anos e são usados pela versão web atual. Incluem exemplos de categoria e comparação da faixa BI com a operacional por id_resultado. Exigem concluinte=true, tempo positivo, resultado homologado e status_final=0, além dos mesmos filtros de distância, seleção e exclusão de modalidades. A documentação correta é esta; um comentário anterior dizia indevidamente que não havia filtro adicional de conclusão.

| Situação | 2025 anual | 2026 jan–set |
|---|---:|---:|
| Base demográfica | 54.234 | 61.454 |
| Nascimento plausível | 8.684 | 4.220 |
| Faixa de categoria utilizável | 21.954 | 56.078 |
| Sem nascimento plausível nem faixa | 23.596 (43,5%) | 1.156 (1,9%) |
| Classificadas nos grupos etários | 30.551 (56,3%) | 60.161 (97,9%) |
| Faixa incompatível com os grupos | 87 (0,2%) | 137 (0,2%) |

Idade em 31/12 do ano da prova. Nascimento plausível tem prioridade. Grupos: Até29,30–39,40–49,50–59,60–69,70+. O grupo inicial reúne todas as idades abaixo de30, absorvendo categorias18–24,20–29 e até29; os demais têm dez anos, com70+ aberto. Não são imputadas idades individuais nem repartidas faixas que cruzam limites. Categorias30–39 e40–49 entram integralmente. Antes, o enquadramento quinquenal deixava11.417 participações2026 sem encaixe; agora são137. O ganho de11.280 classificações decorre da apresentação mais compatível com a fonte, não de nova coleta. Gerações conservam a regra por proximidade registrada nas consultas anteriores. Categorias sem informação, como M/F ou GERAL, não permitem inventar uma faixa.

2025 consulta public.tb_resultados; 2026 consulta estudo.vw_resultados_2026, derivada do BI tratado. A diferença entre anos não deve ser atribuída exclusivamente à coleta. Não houve divergência de idade_range entre BI e operacional nos registros auditados de 2026. Zero dados ficaram classificados como inválidos. Há registros de idade muito baixa que ainda devem ser conferidos na fonte, sem destaque editorial.

2025: Rio 13.132, SP City 5.386, Monumental de Brasília 1.848, Aracaju 1.363, Praia Grande 724, Jurerê 691 e Campinas 215 estão integralmente sem nascimento/faixa utilizável. Os textos capturados estão vazios ou registram somente modalidade/sexo. Isso comprova a lacuna na base, não a ausência de idade no resultado oficial.

2026: Litoral 404/404, Niterói 263/764 e Frevo 190/190 lideram a ausência de informação. As categorias decenais de Niterói e SP City agora são classificadas. SP City mantém somente53 sem informação e zero faixas incompatíveis. Os137 registros incompatíveis2026 se concentram em Praia Grande89, Meia e Maratona Cidade de Florianópolis22, Internacional de Floripa18, Campinas6 e PG2. Conferir exemplos no CSV; não recomendar recarga idêntica.

Para recuperação, conferir o resultado oficial e recarregar apenas se houver nascimento, idade individual ou categoria mais precisa disponível. O CSV e a web listam IDs, URLs cadastradas, quantidades e exemplos. As URLs são referências do cadastro; a disponibilidade e a precisão da fonte ainda precisam ser verificadas. Não foi feita nenhuma recarga nesta etapa.

Floripa 2026 mantém a conciliação documentada: perfil/histograma BI=3.594; desempenho oficial=3.592. Por isso a base demográfica total é 61.454 e a seleção de desempenho soma 61.452.
