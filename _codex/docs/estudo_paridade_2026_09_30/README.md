# Referência ampliada do estudo web de 2025

Publicado em 30/09/2026 no caderno único 6. Sem alterações de runtime do Business: a entrega acrescenta dados e um contrato versionado no schema estudo, usando os serviços existentes de criação, execução, congelamento e publicação.

A seção 48 recebeu a nota 254 e a célula SQL 255 com oito séries transcritas do PDF p.13. Execução 34 congelada. A célula de saída 249 está na revisão 4; execução 35 congelada e publicada como web v2. São 50 tempos e 30 campos de medalhas. Não são novos cálculos analíticos. Todos os valores anteriores e o JSON de 2026 foram preservados integralmente. A seção 37 recebeu o acompanhamento por página na célula 256.

A migration `../../sql/2026-09-30_estudo_web_contrato_v2.sql` cria `estudo.web_base_versoes`, com imutabilidade e sem concessão ao PUBLIC, e estende `web_payload_conferido` para selecionar a referência pela versão do contrato. Ausência do campo ou versão 1 usa a base original; versão 2 exige a nova referência cadastrada para o ano. Formato, categorias, referência e identidade do congelamento continuam sendo verificados. As bases originais e publicações são imutáveis e permaneceram inalteradas.

Testes revertidos aceitaram as execuções 32, 33 e 35, e recusaram versão desconhecida, mudança de referência, categoria duplicada e campo não permitido. A nova tabela recusou UPDATE. Verificação pós-publicação confirmou preservação de todas as séries/comparações/totais anteriores de 2025 e do pacote completo de 2026. Chrome autenticado confirmou a execução 34 na seção 48 e web v2/execução 35 na aba Versão web.

Backup de dados/função: `/var/backups/business-estudo-web-20260928/database/paridade-contract-v2-before.json`. SQL aplicado preservado ao lado do backup. Para reverter dados publicados, selecionar a execução 32 na aba Versão web e publicar com nota. Não é necessário apagar registros/tabelas ou restaurar a função antiga. A função antiga fica em `funcao_anterior.sql` apenas como referência técnica.

Pendências: critérios dos melhores grupos e medalhas, volume histórico 2023–2025, rótulos do Norte, cobertura, idades/gerações, joins geográficos, estações, limites CNA e métricas de perfil. A reprodução visual não certifica esses cálculos nem autoriza preencher 2026 com valores de 2025.

Evidências completas e screenshots no projeto RoadRunners: `_codex/docs/brasil_que_corre_provas/paridade_2026_09_30/`. Relatório de interface: `_codex/docs/brasil_que_corre_provas/paridade_web_2025.md`.
