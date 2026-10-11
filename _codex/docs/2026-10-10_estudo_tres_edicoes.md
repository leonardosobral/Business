# Estudo 2026 — três edições (10/10/2026)

## Destinos e responsabilidades

- Público Q3: https://roadrunners.run/brasilquecorreprovas/2026/ — seis destaques percentuais. RoadRunners consome a projeção pública da publicação congelada, sem dados reservados.
- Profissional Q3: https://business.roadrunners.run/estudos/leitor/?ano=2026 — 37 páginas revisadas, convite/voucher e administradores. Produto previa-2026-q3 fixado na publicação 41, run 233 da célula 251 rev39.
- Anual interno: https://business.roadrunners.run/estudo/anual/?ano=2026 — 43 páginas de trabalho; acesso exclusivamente administrativo. Base inicial até 30/09/2026, não fechamento anual. O produto comercial anual continua DRAFT.

Business é dono do notebook, acesso e montagem das edições. Os três destinos usam o mesmo caderno 6, sem duplicar consultas analíticas. 2025 fica preservado para histórico e comparações dinâmicas; encerrar a frente de reprodução estática.

## Notebook e atualização

Novas seções: 64 (Comece aqui — três edições), 65 (Anual — saída e pendências). Novas células: 416 (mapa), 417 (orientação), 418 (SQL de montagem anual). Primeira saída anual: run 234, célula 418 rev1. Não foram alteradas as 334 células preexistentes; a versão e o hash da query de saída 251 foram conferidos antes da operação aditiva.

A saída anual inicial preserva as 137 séries e comparações do run 233, adicionando meta.edicao_trabalho com sete temas, pendências, critérios de aceite e ponteiros às consultas originais. A edição profissional usa sua projeção de 113 séries. Preços, CNA, ritmo nacional de 42 km e auditoria de cadastro de maratonas são mostrados no anual com aviso de revisão.

Fluxo: ler a revisão vigente da query temática; alterar usando o controle de versão existente; executar, conferir e congelar. Atualizar a referência no pacote técnico e depois o run de origem da célula 418. Executar e congelar essa saída. O serviço StudyEditions entrega o último congelamento válido da célula identificada por source_key bqc-2026-anual-output. Salvar SQL ou executar sem congelar não atualiza o leitor. Nenhuma visita roda a coleta analítica.

A liberação de nova publicação Q3 e a ativação comercial anual são operações distintas. Alterar a base técnica ou congelar o anual não troca o produto Q3. Antes de qualquer edição, reler a versão do banco; os SQLs no staging são registro da implantação, não fonte para sobrescrever o DBA.

## Temas conservados no anual

Preços/kits/lotes; faixas CNA; ritmo nacional de 42 km; cadastro/universo das maratonas; importação definitiva de Floripa; fechamento do quarto trimestre; estudos verticais. A versão revisada de Floripa e os indicadores de idades/gerações já entregues continuam no Q3. Referências históricas arquivadas podem ser consultadas pelo controle de células arquivadas.

O leitor anual reaproveita a apresentação Q3 enquanto a base é Jan–Set. A inclusão do quarto trimestre exigirá atualizar as consultas, corte e textos/gráficos de período antes de comercializar o fechamento; esta implantação não faz uma coleta anual antecipada.

## Contrato e acesso

/estudo/anual/dados.cfm aceita apenas GET e ano=2026, retorna o JSON original do congelamento (preserva precisão), private/no-store e noindex. HTML e dados exigem identidade pessoal autenticada e administração ativa conferida no serviço existente. Anônimo 401, não administrador 403, ano/parâmetros inválidos 400, congelamento inválido 409. O notebook usa a API administrativa/CSRF existente para o novo catálogo editionCatalog.

## Implantação e validação

Arquivos: estudo/{home,index,api}.cfm, estudo/assets/notebook.{js,css}, estudo/includes/StudyEditions.cfc, estudo/anual/{_guard,index,dados}.cfm e estudos/leitor/{parcial,estudo}.js + estudo.css. Deploy incremental com baseline, backup, compilação CFML e verificação dos hashes. Backups: /var/backups/study-editions-20261010-v1; assets do leitor no release study-q3-launch-20261009-v1. Sem alteração de permissões, vouchers, pagamentos ou dados cadastrais.

Validado: serviços reais com 137/113 séries e preservação de 334 versões; permissões HTTP admin/anônimo/não-admin; dois testes de renderização (Q3 permanece com 37 páginas e sem blocos de trabalho; anual inclui fontes/pendências); desktop e viewport 390px sem overflow, console sem erros. Conferência visual feita sobre HTML e JSON reais do servidor em prévia local. Registros operacionais em RoadRunners/_codex/staging/edicoes-2026; capturas em RoadRunners/_codex/docs/brasil_que_corre_provas/edicoes_2026_10_10.
