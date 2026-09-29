SET LOCAL lock_timeout='3s';
SELECT pg_advisory_xact_lock(9282026,4);
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,3,'markdown','','### Conciliação executada — 28/09/2026

**24 consultas executadas e congeladas em 28/09/2026.** As tabelas de resultados ficam nas próprias células SQL e na aba “Execuções e congelados”; não é necessário copiar HTML.

Este caderno confronta o PDF de 2025 com o editor migrado, os oito arquivos DataGrip e o pacote do DBA. São 15 seções, incluindo as páginas analíticas 3–15, e 23 pares de consultas comparados. Os cadernos anteriores e seus HTMLs foram preservados.

**Fonte prioritária:** conforme a informação do responsável, a `vw_resultados` foi preparada depois e provavelmente alimentou o estudo. Essa procedência orienta a conciliação. A definição inspecionada hoje é uma view comum sobre `tb_resultados`, com `status_final = 0 AND homologado = true`; por isso esta coleta representa a base atual de 2025. Não recupera automaticamente o estado do banco usado em março de 2026.

**Primeiras evidências:** a view retorna 5.279.415 participações, compatíveis com “5,3 milhões”; as quatro faixas de distância coincidem numericamente com o PDF. No top 10 de maratonas, sete contagens coincidem e três diferem. Compatibilidade não certifica a metodologia inteira.

**Ainda a conciliar:** cobertura de 84,1%; idades por sobreposição; recortes anuais de gerações; normalização de localidades; estações do ano; critérios de pódio e médias por grupos; dez cartões de perfil. Cada página registra seus filtros, diferenças e pendências. A web pública ainda não consome estes congelamentos.','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p00-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p00' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p00-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

**24 consultas executadas e congeladas em 28/09/2026.** As tabelas de resultados ficam nas próprias células SQL e na aba “Execuções e congelados”; não é necessário copiar HTML.

Este caderno confronta o PDF de 2025 com o editor migrado, os oito arquivos DataGrip e o pacote do DBA. São 15 seções, incluindo as páginas analíticas 3–15, e 23 pares de consultas comparados. Os cadernos anteriores e seus HTMLs foram preservados.

**Fonte prioritária:** conforme a informação do responsável, a `vw_resultados` foi preparada depois e provavelmente alimentou o estudo. Essa procedência orienta a conciliação. A definição inspecionada hoje é uma view comum sobre `tb_resultados`, com `status_final = 0 AND homologado = true`; por isso esta coleta representa a base atual de 2025. Não recupera automaticamente o estado do banco usado em março de 2026.

**Primeiras evidências:** a view retorna 5.279.415 participações, compatíveis com “5,3 milhões”; as quatro faixas de distância coincidem numericamente com o PDF. No top 10 de maratonas, sete contagens coincidem e três diferem. Compatibilidade não certifica a metodologia inteira.

**Ainda a conciliar:** cobertura de 84,1%; idades por sobreposição; recortes anuais de gerações; normalização de localidades; estações do ano; critérios de pódio e médias por grupos; dez cartões de perfil. Cada página registra seus filtros, diferenças e pendências. A web pública ainda não consome estes congelamentos.') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p00-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,9,'markdown','','### Conciliação executada — 28/09/2026

- Total bruto do editor: **5.599.435**. Total tratado da view: **5.279.415**, compatível com o destaque abreviado “5,3 milhões” do PDF.
- Mulheres: **52,85%** no recorte DataGrip de 2025 com tempo positivo; o PDF publica **52,9%**. Isso é compatível na precisão publicada, sem provar identidade da base histórica.
- Eventos cadastrados: **6.167 em 2024** e **9.360 em 2025**. Com pelo menos um resultado na view: **3.214 e 5.121**, respectivamente. Estes são eventos encontrados na base atual, não uma estimativa de todas as provas brasileiras.
- “Pelo menos um resultado coletado” é uma definição distinta de completude da coleta. O destaque **84,1%** continua com denominador pendente.

**Evidência congelada:** #6 (célula 155, revisão 1), #7 (célula 157, revisão 1), #8 (célula 159, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 6, "cell_id": 155, "version": 1, "sql_sha256": "34355c02373b83da6feda1a2ed2c41d00ed632469d85c34af14a9236838b36de"}, {"id": 7, "cell_id": 157, "version": 1, "sql_sha256": "83585bfd2de0dcabe30f9a9f3d7656fe9f5ea601531d138a7af4803344a2e609"}, {"id": 8, "cell_id": 159, "version": 1, "sql_sha256": "c5a34c1e05821a94b49c5fae3232133708ec7ed6dcfc493d3d52623acb713a5c"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p03-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p03' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p03-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

- Total bruto do editor: **5.599.435**. Total tratado da view: **5.279.415**, compatível com o destaque abreviado “5,3 milhões” do PDF.
- Mulheres: **52,85%** no recorte DataGrip de 2025 com tempo positivo; o PDF publica **52,9%**. Isso é compatível na precisão publicada, sem provar identidade da base histórica.
- Eventos cadastrados: **6.167 em 2024** e **9.360 em 2025**. Com pelo menos um resultado na view: **3.214 e 5.121**, respectivamente. Estes são eventos encontrados na base atual, não uma estimativa de todas as provas brasileiras.
- “Pelo menos um resultado coletado” é uma definição distinta de completude da coleta. O destaque **84,1%** continua com denominador pendente.

**Evidência congelada:** #6 (célula 155, revisão 1), #7 (célula 157, revisão 1), #8 (célula 159, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p03-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

A variante da view produz, no total, **6,69% em 13–19**, **14,40% em 30–34** e **14,72% em 35–39**. O PDF mostra 6,7%, 14,4% e 14,7%, mas rotula a primeira faixa como **14–19**.

As 12 contagens do recorte geral somam **6.620.729**, acima das 5.279.415 linhas da view: um intervalo de idade pode se sobrepor a mais de uma faixa. Os percentuais usam a soma dessas atribuições como denominador. Não interpretar as faixas como uma partição exclusiva de pessoas ou participações.

A execução inicial #9 ultrapassou 45 segundos e ficou registrada como erro. A revisão 2 agrega intervalos antes do cruzamento; testes com intervalos sobrepostos, vazios e nulos confirmaram equivalência. A execução #10 terminou em 10,087 segundos.

**Evidência congelada:** #10 (célula 163, revisão 2).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 10, "cell_id": 163, "version": 2, "sql_sha256": "e0c82b1eebfa652866a9ff6ebd7cb6d9f8d00408f16a69c166f31be35e301328"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p04-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p04' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p04-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

A variante da view produz, no total, **6,69% em 13–19**, **14,40% em 30–34** e **14,72% em 35–39**. O PDF mostra 6,7%, 14,4% e 14,7%, mas rotula a primeira faixa como **14–19**.

As 12 contagens do recorte geral somam **6.620.729**, acima das 5.279.415 linhas da view: um intervalo de idade pode se sobrepor a mais de uma faixa. Os percentuais usam a soma dessas atribuições como denominador. Não interpretar as faixas como uma partição exclusiva de pessoas ou participações.

A execução inicial #9 ultrapassou 45 segundos e ficou registrada como erro. A revisão 2 agrega intervalos antes do cruzamento; testes com intervalos sobrepostos, vazios e nulos confirmaram equivalência. A execução #10 terminou em 10,087 segundos.

**Evidência congelada:** #10 (célula 163, revisão 2).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p04-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,7,'markdown','','### Conciliação executada — 28/09/2026

A versão DataGrip **2024 / M** reproduz os cinco percentuais do recorte masculino do PDF: **2,9 / 18,2 / 49,1 / 22,5 / 7,3**. Já a versão **2025 / F** retorna **3,4 / 17,6 / 51,8 / 21,8 / 5,4**, com pequenas diferenças em relação ao quadro feminino publicado.

Os três blocos históricos preservam filtros diferentes: **2023 geral, 2024 masculino e 2025 feminino**. Eles não formam uma série anual comparável entre si. A saída BI é outra população/regra e mantém “Não Definido” visível; não deve substituir silenciosamente as faixas do PDF.

**Evidência congelada:** #11 (célula 167, revisão 2), #12 (célula 169, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 11, "cell_id": 167, "version": 2, "sql_sha256": "d43cf6201f1894997a0d5fe033a5b2a4d8a3f0feba532b31cd51a2895085fea9"}, {"id": 12, "cell_id": 169, "version": 1, "sql_sha256": "2b06fa6d0888f974dfceba54a9237551cda2f0bf3c1f2eb6c38c146902b5ecc5"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p05-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p05' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p05-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

A versão DataGrip **2024 / M** reproduz os cinco percentuais do recorte masculino do PDF: **2,9 / 18,2 / 49,1 / 22,5 / 7,3**. Já a versão **2025 / F** retorna **3,4 / 17,6 / 51,8 / 21,8 / 5,4**, com pequenas diferenças em relação ao quadro feminino publicado.

Os três blocos históricos preservam filtros diferentes: **2023 geral, 2024 masculino e 2025 feminino**. Eles não formam uma série anual comparável entre si. A saída BI é outra população/regra e mantém “Não Definido” visível; não deve substituir silenciosamente as faixas do PDF.

**Evidência congelada:** #11 (célula 167, revisão 2), #12 (célula 169, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p05-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,13,'markdown','','### Conciliação executada — 28/09/2026

As quatro faixas da view retornam **59,1% / 28,4% / 11,1% / 1,4%**, iguais aos valores publicados. A coincidência numérica não elimina a revisão dos rótulos: o SQL usa `<6`, `6–10,99`, `11–29,99` e `>=30` km; os limites BETWEEN são inclusivos.

Na distribuição detalhada, 5 km representa **54,04%**, contra **53,96%** no PDF. A presença de 5 km é **3.728 de 5.002 eventos com resultados de rua (74,53%)**, contra 74,6% publicado.

A comparação dentro de cada sexo utiliza denominador próprio, conforme explicado na célula de método. Nos arquivos originais havia um denominador conjunto para F+M; essa alteração está identificada, não foi tratada como consulta original.

**Evidência congelada:** #13 (célula 173, revisão 1), #14 (célula 175, revisão 1), #15 (célula 177, revisão 1), #16 (célula 179, revisão 1), #17 (célula 181, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 13, "cell_id": 173, "version": 1, "sql_sha256": "89ff26290a94792aeed469bd9e9031d9cd93319d138184cc436eb53f8d8f08de"}, {"id": 14, "cell_id": 175, "version": 1, "sql_sha256": "f2ff5a9a789619919b9ed705f5217f7ec87e586d3d86d5012e98457761790b59"}, {"id": 15, "cell_id": 177, "version": 1, "sql_sha256": "4249ddb14acc98d1ac78e2a95dfd78684062fc1b5424e03f8b6b13b27a2c2ebe"}, {"id": 16, "cell_id": 179, "version": 1, "sql_sha256": "a666ce7ab026028e8d888a974beca94db22a5070e6456d802c8533be4b33e6b6"}, {"id": 17, "cell_id": 181, "version": 1, "sql_sha256": "39874eab9731c5acaebaae71106f2aa10956dba6b8befd19356349100354325f"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p06-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p06' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p06-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

As quatro faixas da view retornam **59,1% / 28,4% / 11,1% / 1,4%**, iguais aos valores publicados. A coincidência numérica não elimina a revisão dos rótulos: o SQL usa `<6`, `6–10,99`, `11–29,99` e `>=30` km; os limites BETWEEN são inclusivos.

Na distribuição detalhada, 5 km representa **54,04%**, contra **53,96%** no PDF. A presença de 5 km é **3.728 de 5.002 eventos com resultados de rua (74,53%)**, contra 74,6% publicado.

A comparação dentro de cada sexo utiliza denominador próprio, conforme explicado na célula de método. Nos arquivos originais havia um denominador conjunto para F+M; essa alteração está identificada, não foi tratada como consulta original.

**Evidência congelada:** #13 (célula 173, revisão 1), #14 (célula 175, revisão 1), #15 (célula 177, revisão 1), #16 (célula 179, revisão 1), #17 (célula 181, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p06-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

Entre as participações classificadas em 6–10 km, os percentuais por geração coincidem com o PDF: **Z 6,3%, Y 46,6%, X 38,6%, Boomers 8,5%**.

Em 30 km ou mais há diferenças: **X 51,0%** no congelamento contra **51,7%** publicado; **Y 40,6%** contra **40,1%**. A regra de classificação deriva da função inspecionada hoje e exclui geração zero. Isso não representa toda a população com idade desconhecida.

**Evidência congelada:** #18 (célula 185, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 18, "cell_id": 185, "version": 1, "sql_sha256": "244e526b3c96c730f075d1c2ac3e27d73534342eb585abc3f98b1e7b443b5087"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p07-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p07' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p07-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

Entre as participações classificadas em 6–10 km, os percentuais por geração coincidem com o PDF: **Z 6,3%, Y 46,6%, X 38,6%, Boomers 8,5%**.

Em 30 km ou mais há diferenças: **X 51,0%** no congelamento contra **51,7%** publicado; **Y 40,6%** contra **40,1%**. A regra de classificação deriva da função inspecionada hoje e exclui geração zero. Isso não representa toda a população com idade desconhecida.

**Evidência congelada:** #18 (célula 185, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p07-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,7,'markdown','','### Conciliação executada — 28/09/2026

A versão geral do DBA reproduz as faixas publicadas de **10 km (2,5 / 14,1 / 30,6 / 52,8%)**, **21 km (4,1 / 40,3 / 41,2 / 14,3%)** e **42 km (3,8 / 12,6 / 26,5 / 24,6 / 32,4%)**. Em 5 km, a faixa 25–30 minutos deu **16,2%**, contra 16,3% no PDF.

Os blocos DataGrip executados preservam **5 km feminino** e **10/21/42 km masculino**. Os recortes complementares publicados ainda precisam ser derivados explicitamente. Os operadores de fronteira e o tratamento de zero/nulo foram mantidos como nos scripts; “Sub” no título nem sempre corresponde a `<` no SQL.

**Evidência congelada:** #19 (célula 189, revisão 1), #20 (célula 191, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 19, "cell_id": 189, "version": 1, "sql_sha256": "9307917c333cc1726ba455f62abb6092b2958e7c031ac944cad3b64162f658c9"}, {"id": 20, "cell_id": 191, "version": 1, "sql_sha256": "458d73b37563e7826fd698c83b0db4d56e279fd0342110178e43eeae5825b9c7"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p08-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p08' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p08-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

A versão geral do DBA reproduz as faixas publicadas de **10 km (2,5 / 14,1 / 30,6 / 52,8%)**, **21 km (4,1 / 40,3 / 41,2 / 14,3%)** e **42 km (3,8 / 12,6 / 26,5 / 24,6 / 32,4%)**. Em 5 km, a faixa 25–30 minutos deu **16,2%**, contra 16,3% no PDF.

Os blocos DataGrip executados preservam **5 km feminino** e **10/21/42 km masculino**. Os recortes complementares publicados ainda precisam ser derivados explicitamente. Os operadores de fronteira e o tratamento de zero/nulo foram mantidos como nos scripts; “Sub” no título nem sempre corresponde a `<` no SQL.

**Evidência congelada:** #19 (célula 189, revisão 1), #20 (célula 191, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p08-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

No recorte geral de 2025, a view retorna **Sudeste 47,5%, Nordeste 19,9%, Sul 17,5%, Centro-Oeste 9,2% e Norte 5,9%**. O PDF mostra 47,6%, 19,7%, 17,5%, 9,3% e 5,8%.

As seis saídas distinguem ano e sexo. “Regiões dentro de cada sexo” e “sexos dentro de cada região” têm denominadores diferentes; a tabela congelada fornece contagens para a segunda derivação, mas não se deve reutilizar diretamente o percentual da primeira.

**Evidência congelada:** #21 (célula 195, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 21, "cell_id": 195, "version": 1, "sql_sha256": "1b31ba2b6068e028299020fcf411b5a9faf6e775a7451debcfff2c9b7bcbbc6b"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p09-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p09' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p09-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

No recorte geral de 2025, a view retorna **Sudeste 47,5%, Nordeste 19,9%, Sul 17,5%, Centro-Oeste 9,2% e Norte 5,9%**. O PDF mostra 47,6%, 19,7%, 17,5%, 9,3% e 5,8%.

As seis saídas distinguem ano e sexo. “Regiões dentro de cada sexo” e “sexos dentro de cada região” têm denominadores diferentes; a tabela congelada fornece contagens para a segunda derivação, mas não se deve reutilizar diretamente o percentual da primeira.

**Evidência congelada:** #21 (célula 195, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p09-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,9,'markdown','','### Conciliação executada — 28/09/2026

São Paulo/UF aparece com **25,9%** na view e 26,2% no PDF. Na tabela de cidades, São Paulo/SP soma **647.968 (12,27%)**, contra 12,4% publicado.

A chave inclui UF, mas ainda é textual: **BRASÍLIA/DF (204.519)** e **BRASILIA/DF (23.492)** aparecem separadas. Isso registra uma pendência de normalização; não foram fundidas sem uma regra de localidade.

Na alternativa BI, o cruzamento é pelo **id_localidade**. Permanecem **125.710 participações sem classificação de localidade (2,40%)**, visíveis na saída. É outra população, com resultado nacional diferente; não é uma substituição automática da query geográfica original.

**Evidência congelada:** #22 (célula 199, revisão 1), #23 (célula 201, revisão 1), #24 (célula 203, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 22, "cell_id": 199, "version": 1, "sql_sha256": "a8779ec92a887de05bde6554b892bc896b44e5a3e24ebd353996544b1d4e7ddf"}, {"id": 23, "cell_id": 201, "version": 1, "sql_sha256": "3b1cc76899663992236954373028b57895098f361d73b76f4eb23d0be32b484c"}, {"id": 24, "cell_id": 203, "version": 1, "sql_sha256": "361857bf52d2aed9de109bea35122cb125eead44d196f4c8c3a92d95b47f7e04"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p10-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p10' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p10-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

São Paulo/UF aparece com **25,9%** na view e 26,2% no PDF. Na tabela de cidades, São Paulo/SP soma **647.968 (12,27%)**, contra 12,4% publicado.

A chave inclui UF, mas ainda é textual: **BRASÍLIA/DF (204.519)** e **BRASILIA/DF (23.492)** aparecem separadas. Isso registra uma pendência de normalização; não foram fundidas sem uma regra de localidade.

Na alternativa BI, o cruzamento é pelo **id_localidade**. Permanecem **125.710 participações sem classificação de localidade (2,40%)**, visíveis na saída. É outra população, com resultado nacional diferente; não é uma substituição automática da query geográfica original.

**Evidência congelada:** #22 (célula 199, revisão 1), #23 (célula 201, revisão 1), #24 (célula 203, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p10-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

Novembro continua sendo o mês com maior volume: **697.187 participações tratadas (13,21%)**, contra **13,4%** no PDF. O quarto trimestre soma **1.743.230 (33,02%)**, contra **33,5%** publicado.

A tabela atual contém os 12 meses, inclusive janeiro e fevereiro, e quatro trimestres com denominador anual. A regra de **estações** não foi localizada; os percentuais publicados estão preservados como referência, sem criar uma regra nova por suposição.

**Evidência congelada:** #25 (célula 207, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 25, "cell_id": 207, "version": 1, "sql_sha256": "43e8855ae972b257a9faecd0b8b3d7b7460ddd3befd2d78822d3b39f2f6ff67d"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p11-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p11' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p11-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

Novembro continua sendo o mês com maior volume: **697.187 participações tratadas (13,21%)**, contra **13,4%** no PDF. O quarto trimestre soma **1.743.230 (33,02%)**, contra **33,5%** publicado.

A tabela atual contém os 12 meses, inclusive janeiro e fevereiro, e quatro trimestres com denominador anual. A regra de **estações** não foi localizada; os percentuais publicados estão preservados como referência, sem criar uma regra nova por suposição.

**Evidência congelada:** #25 (célula 207, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p11-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

Sete das dez contagens coincidem com o PDF. As diferenças estão em:

| Maratona | PDF | Coleta atual | Diferença |
|---|---:|---:|---:|
| SP City | 5.380 | 5.386 | +6 |
| São Paulo | 4.851 | 4.869 | +18 |
| Curitiba | 3.012 | 3.040 | +28 |

O total das dez passou de **43.362** publicados para **43.414** no recorte atual. Como a edição e o ano são os mesmos, essas diferenças não medem crescimento anual da prova; podem envolver atualização da base e diferenças de critério.

O menor tempo de Curitiba veio como **01:56:00**, contra **02:15:13** publicado. Fica sinalizado para revisar resultado, modalidade e filtros antes de promover essa estatística. Nenhum registro foi corrigido ou removido nesta conciliação.

**Evidência congelada:** #26 (célula 211, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 26, "cell_id": 211, "version": 1, "sql_sha256": "3dfcf0808925f9632f68f27950291fbb167d751bccc76ec2b602d17ac70778a9"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p12-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p12' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p12-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

Sete das dez contagens coincidem com o PDF. As diferenças estão em:

| Maratona | PDF | Coleta atual | Diferença |
|---|---:|---:|---:|
| SP City | 5.380 | 5.386 | +6 |
| São Paulo | 4.851 | 4.869 | +18 |
| Curitiba | 3.012 | 3.040 | +28 |

O total das dez passou de **43.362** publicados para **43.414** no recorte atual. Como a edição e o ano são os mesmos, essas diferenças não medem crescimento anual da prova; podem envolver atualização da base e diferenças de critério.

O menor tempo de Curitiba veio como **01:56:00**, contra **02:15:13** publicado. Fica sinalizado para revisar resultado, modalidade e filtros antes de promover essa estatística. Nenhum registro foi corrigido ou removido nesta conciliação.

**Evidência congelada:** #26 (célula 211, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p12-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

A seleção fixa de Curitiba passou de **1.367 para 1.390** abaixo de 4h, de **132 para 139** abaixo de 3h e de **10 para 13** abaixo de 2h30, comparando PDF e recálculo atual. SP City e São Paulo também apresentam diferenças; o Rio mantém 5.242 / 334 / 11.

Esses números usam os dez IDs e limites estritos definidos na célula. Ainda não reproduzem o quadro de pódio nem as médias Top10/Top100/Top5%/Top10%/Top50%. O tempo mínimo de Curitiba sinalizado na página anterior também afeta a interpretação dessas faixas.

**Evidência congelada:** #27 (célula 215, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 27, "cell_id": 215, "version": 1, "sql_sha256": "57dc05deb9c2d037e97ae783dbb1148ed685de8a9a41ae0acdd93cbf122a1e8b"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p13-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p13' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p13-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

A seleção fixa de Curitiba passou de **1.367 para 1.390** abaixo de 4h, de **132 para 139** abaixo de 3h e de **10 para 13** abaixo de 2h30, comparando PDF e recálculo atual. SP City e São Paulo também apresentam diferenças; o Rio mantém 5.242 / 334 / 11.

Esses números usam os dez IDs e limites estritos definidos na célula. Ainda não reproduzem o quadro de pódio nem as médias Top10/Top100/Top5%/Top10%/Top50%. O tempo mínimo de Curitiba sinalizado na página anterior também afeta a interpretação dessas faixas.

**Evidência congelada:** #27 (célula 215, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p13-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

As quatro distâncias e oito faixas foram congeladas. Exemplos: branca de 5 km **73,59%** contra **73,51%** no PDF; branca de 10 km **53,09%**, igual ao publicado; branca de 42 km **57,82%** contra **57,84%**.

As regras CNA são distintas das faixas de performance da página 8. As pequenas diferenças atuais não demonstram sozinhas erro na publicação, pois não existe uma cópia histórica completa da base.

**Evidência congelada:** #28 (célula 219, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 28, "cell_id": 219, "version": 1, "sql_sha256": "2c3733bf9bf8e39c229aa8754110448d7e5c43bc12d672e8d5f7f897138b77a1"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p14-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p14' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p14-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

As quatro distâncias e oito faixas foram congeladas. Exemplos: branca de 5 km **73,59%** contra **73,51%** no PDF; branca de 10 km **53,09%**, igual ao publicado; branca de 42 km **57,82%** contra **57,84%**.

As regras CNA são distintas das faixas de performance da página 8. As pequenas diferenças atuais não demonstram sozinhas erro na publicação, pois não existe uma cópia histórica completa da base.

**Evidência congelada:** #28 (célula 219, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p14-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

A query encontrou **110.058 atividades WeightTraining (9,51%)**, **91.809 Walk (7,93%)**, **75.111 Workout (6,49%)** e **61.151 Ride (5,28%)** em 2025. O gráfico publica 9,5%, 7,93%, 6,49% e 5,21% para os rótulos correspondentes.

O denominador da consulta inclui corrida e conta **atividades, não usuários**. Os rótulos traduzidos e as exclusões precisam ser confirmados. Os dez cartões de perfil continuam sem consulta reconciliada; não foram inferidos a partir da amostra de personas.

**Evidência congelada:** #29 (célula 223, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 29, "cell_id": 223, "version": 1, "sql_sha256": "aafab3adf9a86404cc98deec21654b2085b1d7b28a1c46b5da0a1b104a84720d"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p15-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p15' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p15-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

A query encontrou **110.058 atividades WeightTraining (9,51%)**, **91.809 Walk (7,93%)**, **75.111 Workout (6,49%)** e **61.151 Ride (5,28%)** em 2025. O gráfico publica 9,5%, 7,93%, 6,49% e 5,21% para os rótulos correspondentes.

O denominador da consulta inclui corrida e conta **atividades, não usuários**. Os rótulos traduzidos e as exclusões precisam ser confirmados. Os dez cartões de perfil continuam sem consulta reconciliada; não foram inferidos a partir da amostra de personas.

**Evidência congelada:** #29 (célula 223, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p15-coleta-20260928'; END IF; END $verify$;
INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,origem,source_key) SELECT notebook_id,5,'markdown','','### Conciliação executada — 28/09/2026

O diagnóstico bruto encontrou **5.599.435 linhas**; a regra da view mantém **5.279.415**. O campo `concluinte=true` sinaliza **5.280.837** linhas, portanto não é sinônimo exato dos filtros da view.

Na população bruta há **1.265.472 linhas sem idade_range**, **318.457 com tempo nulo** e **142 com tempo zero**. As categorias podem se sobrepor e não devem ser somadas como pessoas distintas.

Todos os 24 congelamentos são completos dentro do limite de saída do notebook; nenhuma tabela foi truncada. A tentativa #9 com timeout foi preservada como erro e substituída por uma execução bem-sucedida da revisão otimizada. Congelamentos anteriores e HTMLs históricos permanecem intactos.

**Evidência congelada:** #30 (célula 227, revisão 1).','{"kind": "executed_reconciliation", "date": "2026-09-28", "runs": [{"id": 30, "cell_id": 227, "version": 1, "sql_sha256": "6755652b9da27420452ae59ffa5406b57c89ffb0930a774b82b3d918355205cc"}], "status": "candidate_current_data_not_historical_certification"}'::jsonb,'pdf-2025-p99-coleta-20260928' FROM estudo.notebooks WHERE source_key='pdf-2025-p99' ON CONFLICT(source_key) DO NOTHING;
DO $verify$ BEGIN IF NOT EXISTS(SELECT 1 FROM estudo.notebook_cells WHERE source_key='pdf-2025-p99-coleta-20260928' AND content='### Conciliação executada — 28/09/2026

O diagnóstico bruto encontrou **5.599.435 linhas**; a regra da view mantém **5.279.415**. O campo `concluinte=true` sinaliza **5.280.837** linhas, portanto não é sinônimo exato dos filtros da view.

Na população bruta há **1.265.472 linhas sem idade_range**, **318.457 com tempo nulo** e **142 com tempo zero**. As categorias podem se sobrepor e não devem ser somadas como pessoas distintas.

Todos os 24 congelamentos são completos dentro do limite de saída do notebook; nenhuma tabela foi truncada. A tentativa #9 com timeout foi preservada como erro e substituída por uma execução bem-sucedida da revisão otimizada. Congelamentos anteriores e HTMLs históricos permanecem intactos.

**Evidência congelada:** #30 (célula 227, revisão 1).') THEN RAISE EXCEPTION 'Conflito de nota pdf-2025-p99-coleta-20260928'; END IF; END $verify$;
