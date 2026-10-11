# Prévia pública com narrativa comparativa — 10/10/2026

Publicado em https://roadrunners.run/brasilquecorreprovas/2026/.

A abertura passa a apresentar mudanças de janeiro–setembro de 2025 para o mesmo período de 2026. Cada história mostra um indicador, sua interpretação e limites, uma pergunta e os recortes disponíveis na prévia profissional. Os seis percentuais anteriores continuam abaixo como retrato do período. A ação principal de conversão é solicitar acesso profissional no Business; o voucher permanece disponível.

## Histórias publicadas

- Participação feminina: 52,5% → 53,9%, diferença de +1,4 ponto percentual. O completo permite aprofundar por distância e região, além de idades e gerações.
- Resultados registrados: +27,3%. A ressalva é explícita: captura/importações afetam o número, que não representa sozinho crescimento do mercado. O completo oferece provas cadastradas, resultados coletados e comparações mensais; a chamada não promete decomposição causal ou coorte pareada.
- Fevereiro: −19,9% nos resultados registrados, apesar da alta do acumulado. O completo permite explorar meses, trimestres e estações. O indicador não mede demanda por inscrições.

Não foram expostos volumes absolutos, tabelas completas ou dados pessoais. Ausências continuam como `??`. As chamadas do completo descrevem conteúdo efetivamente disponível nas 37 páginas.

## Fonte e publicação

- Notebook único 6, seção 64: nova célula SQL **420**, congelamento **235**.
- A consulta usa o congelamento **233**, célula 251, que sustenta a publicação **41** da prévia profissional. Acrescenta apenas os campos comparativos públicos e conserva os seis indicadores anteriores.
- A view `estudo.lancamento_publico` lê explicitamente o resultado congelado 235/420, exigindo sucesso, uma linha, ausência de truncamento, produto ativo e publicação 41.
- A edição profissional continua na publicação 41; o anual interno continua em 418/234. Nenhuma consulta preexistente foi sobrescrita.

O notebook é a fonte das queries. Para atualizar a prévia pública, primeiro ler a versão corrente, revisar a consulta e a origem congelada, executar, congelar e validar o contrato público. Só então apontar a view ao novo congelamento aprovado. Alterar a query não publica automaticamente. Ao trocar a publicação do produto Q3, atualizar também a guarda da view; sem correspondência ela não fornece payload.

Recuperação da view anterior: `/var/backups/study-public-narrative-20261010-v1/rollback.sql`. Runtime publicado pelo deploy existente, com comparação e validação de hashes. O fixture local `public-preview.json` não foi enviado ao servidor.

## Validação

- 9 testes Node aprovados, incluindo números, contrato público, ausência de fallback privado, falha de carga e dados ausentes.
- 11 verificações HTTP aprovadas; 46 hashes de runtime conferidos (27 Business, 19 portal).
- Conteúdo e versões das **338 células preexistentes** preservados.
- Produção conferida em desktop e celular de 390 px: três histórias com dados reais, sem âncoras quebradas, erros de console ou transbordamento horizontal.
- Evidências: capturas no projeto RoadRunners, pasta `_codex/docs/brasil_que_corre_provas/publico_narrativa_2026_10_10/`. Recibos operacionais no projeto RoadRunners em `_codex/staging/publico-narrativa/validation.json`.

As artes e o kit anterior mantêm os seis indicadores originais; esta alteração não gerou novas artes ou PDFs.

## Revisão editorial posterior — provas cadastradas e kit

A célula 420 foi relida na versão 1 e atualizada pelo serviço do notebook com controle de versão, gerando versão 2 / congelamento 236. A chamada de fevereiro foi substituída por +33,9% de provas cadastradas em Jan–Set 2026 versus 2025, da fonte 233/publicação 41. O cadastro BR usa data final e inclui inativos/cancelados, sem comprovar realização. A view pública agora fixa 420/236; espera-se a chave `historias.provas`. As outras 338 células e a publicação profissional 41 foram preservadas.

Participação feminina exibida como 52,5% em 2025 → 53,9% em 2026, sem abreviação de pontos percentuais. Kit atualizado com PDF de sete páginas, dez artes distintas e legendas. Registros completos e evidências no projeto RoadRunners: `_codex/docs/brasil_que_corre_provas/kit_narrativa_2026_10_10/README.md`. Rollback da view anterior em `/var/backups/study-public-provas-20261010-v1/rollback.sql`; coordenar recuperação com o frontend. Arquivos de divulgação usam versões nos links para evitar cache antigo.
