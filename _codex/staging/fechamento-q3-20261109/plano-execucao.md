# Fechamento editorial Jan–Set 2026 — plano de implementação

> Executar os ajustes aceitos pelo usuário em 09/11, preservando alterações alheias, sem commit/push. A lista revisada salva na central (revisão543) é a especificação.

Objetivo: deixar o conteúdo principal de janeiro a setembro pronto para a conferência editorial final e lançamento de13/11.

Arquitetura: Business mantém notebook, acesso e leitor profissional. RoadRunners apresenta o hotsite público. Usar congelamentos existentes (Q3 publicação41/run233, projeção pública239); nenhuma nova coleta nem alteração automática de query do DBA.

## Tarefas e responsáveis técnicos

- [x] Leitor profissional (agente `comparativo_profissional`): ler o contrato atual e a fonte congelada do comparativo; acrescentar o destaque de edições pareadas junto do calendário, com população e limites visíveis, fonte/contagens exportáveis quando disponíveis. Preservar acesso, dados e exportações existentes. Validar corte Jan–Set, identidade do congelamento, ausências e apresentação.
- [x] Materiais internos (agente `pdfs_fechamento`): atualizar por gerador o guia1p e uma nova execução v6 com as cinco pautas e chamadas2,1/33,9; preservar a v5. Entregar candidatos e renderizações para publicação pelo controlador; não tocar runtimecentral nem arquivo.cfm.
- [x] Hotsite (controlador): corrigir descrição social e usar a arte vigente de comparação já existente; manter noindex até a decisão do lançamento e preservar acessos de imprensa. Verificar metadados e assets reais.
- [x] Central (controlador): apontar execução atual para v6, classificar Maratonas como apoio editorial separado em revisão, manter o anual explicitamente em preparação. Atualizar observações com concluído/pendente sem validar etapas humanas, nomear pessoas por inferência ou enviar convites.
- [x] Integração/publicação (controlador): conferir baseline remoto, preparar backup recuperável, validar os candidatos e publicar apenas runtime de escopo. No RR rodar gateTeams no checkout e candidato e checar404 após publicação. Compilar CFML e confirmarHTTP/arquivos reais.
- [x] Conferência final: testar leitura, gráficos, fontes/exportações do bloco novo, hotsite e materiais; desktop/mobile. Revisor independente lê o patch. Registrar pendências humanas e encerrar apenas recursos temporários próprios.

## Decisões mantidas

Escopo público: três comparativos e seis destaques percentuais. Profissional: capítulos atualmente revisados, adicionando visibilidade ao comparativo das mesmas provas. Anual: preços/kits/lotes, CNA, ritmo nacional42 eQ4. VerticalMaratonas separado, sem promessa dePDF novo.

Não são autorização desta tarefa: assinar contrato, disparar comunicação, tornar o anual ativo, alterar credenciais/permissões, fechar ou expandir acesso de imprensa. Responsáveis são aguardados em pergunta assíncrona; convites e piloto real continuam da equipe.

## Focos de verificação

Fonte faltante não vira zero; +2,1% e+33,9% usam universos diferentes; 2025/2026 têm mesma janela nominal; edições congela­das e usuário sem acesso não mudam; PDFs legíveis e links válidos. Nenhum tema anual em revisão deve reaparecer como aprovado noQ3.

## Andamento

09/11 — plano autorizado pela continuidade solicitada; execução paralela por domínio. Isolamento por staging/candidatos, sem branch/commit e sem interferência em outras mudanças locais.

09/11 — Usuário confirmou Leo e Carlos como responsáveis conjuntos por lançamento, editorial, convites e suporte; registrar nas etapas operacionais correspondentes sem atribuir aprovação de contrato ou venda anual.

09/11 — publicados8arquivosBusiness e5RR; compilaçãoCFML e13hashesverificados;17HTTPincluindo10GET/POST404Teams.37páginas,36snapshotsinalterados;116séries/706comparações. Notebook: somente nota419 rev2; consultas/congelamentos preservados. Etapas continuam sem validação humana.
