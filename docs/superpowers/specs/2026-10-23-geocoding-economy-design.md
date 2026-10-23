# Geolocalização econômica — desenho aprovado

Autorização: Sol padrão, Astra apenas em casos complexos, Batch para histórico; USD 2/dia e USD 30/mês; testar/publicar SEM reativar e sem testes pagos. Mantém a chave existente previamente aprovada. Não executar Git nem DDL. Preservar cost_audit.cfm de diagnóstico e outras frentes.

## Abordagem

Descartados: apenas reduzir cron (não limita gasto); apenas trocar modelo (não evita falhas/repetições); nova infraestrutura/faturamento administrativo (exige credenciais e permissões novas). Escolhida: camada econômica sobre o pipeline CFML existente, persistida em registros próprios da tb_geocoding_cache, sem alterar schema.

Orçamento em USD e períodos UTC. Reserva conservadora ANTES da fronteira paga, usando limite de saída e bytes UTF-8 do corpo + margem como limite superior de entrada; tarifa de escrita de cache mais cara. Trava transacional comum, reservas globais pendentes contam em todos os períodos até confirmação. Valores sem uso confiável não liberam saldo; não há expiração automática de reservas incertas. Confirmações são atribuídas ao dia de liquidação. Isso controla o gasto deste módulo, não a fatura de outros consumidores da chave. Tetos fixos USD 2/30 não editáveis pelo formulário existente.

Uma tentativa paga por modelo e impressão digital de evidência/prompt; reexecução/crash/timeout não faz reenvio cego. Sol gpt-6.1-sol com reasoning low, tier default, saída limitada. Astra só após resposta estrutural insuficiente ou ambiguidade interpretativa delimitada; nunca para superar recusa, falta de fonte, quota ou divergência factual real. No máximo uma escalada, dentro do mesmo orçamento. Evidências e validadores continuam obrigatórios.

Histórico = data final anterior à data atual em São Paulo. Usa Batch API, inicialmente um pedido por lote para reduzir risco de associação/crash na integração existente (desconto por pedido independe do número de linhas). Persistir arquivo/lote/custom_id antes de continuar; criar lote uma única vez. Resultado deve corresponder ao ID e à evidência solicitada. Poll separado recupera resultados mesmo se o trabalho original mudou; resultado antigo não pode publicar sobre evento alterado. Falha ambígua de criação mantém reserva e exige reconciliação, não reenvio. Cancelamento/falha sem prova de custo mantém reserva conservadora. Sem envio/poll automático enquanto enabled=false.

Seleção de texto por janelas determinísticas, preservando início/identificação e contexto de largada/kit; validar citações contra documentos integrais originais. Cache durável de resultados econômicos por evidência/edição/versão, sem refazer por simples TTL. Não ampliar confiança: cidade não é largada, kit não é corrida; preservar locais já confirmados, filtros de país/UF e decisão humana.

Painel mostra pausa, modelos, orçamento reservado/medido, pendências incertas e Batch. Publicação com baseline/backup/CAS; manter enabled=false e confirmar em servidor/navegador. Testes só fixtures e rollback; comparação paga de qualidade fica pendente de autorização posterior e sistema permanece pausado.
