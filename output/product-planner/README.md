# Planner de produtos — MVP para revisão

Protótipo local, sem publicação nem mudanças no runtime do Business. Abra `index.html` em um navegador ou sirva esta pasta por HTTP local.

Inclui os cinco produtos solicitados, criação e edição de fichas, ICP, condições comerciais, preço sugerido separado do vigente, múltiplas metas anuais ou por período, realizado manual e etapas de entrega com automação por etapa. Filtros, abas acessíveis por teclado e links diretos preservam a navegação. Os conteúdos iniciais são propostas identificadas como rascunhos, sem preços, vendas ou automação inventados.

Os dados são salvos em localStorage por navegador e origem. Não são compartilhados entre pessoas, navegadores, dispositivos ou portas diferentes. A exportação contém apenas a última versão salva; importação validada substitui o catálogo após confirmação. Exportar antes de limpar os dados do navegador. Este armazenamento não substitui a futura persistência compartilhada do Business.

## Decisões do usuário em 06/10/2026

- Metas podem ter prazo próprio ou cobrir um ano, como 2027.
- Desafio vale por 12 meses desde o pagamento, independentemente do ano civil.
- O público comercial dos organizadores deve considerar o dono da conta; funcionários são usuários operacionais. Contas sem titular confirmado precisam de tratamento explícito no futuro Funil.
- Churn do Desafio é não voltar após a anuidade; tolerância após vencimento ainda precisa ser definida. Churn de organizadores depende do produto.
- Produtos iniciais: Desafio, Patrocínio (banners/anúncios), Transmissão, Perfil.Run e API/dashboard de dados.
- Funil futuro: entrada → cadastro → uso de funcionalidade → pagamento → renovação ou saída. Grupos: cadastrado sem uso observado, usuário não pagante que usa funcionalidades e usuário pagante. Histórico de compra e vigência precisam de indicadores próprios para acomodar ex-clientes e evitar confundir falta de evidência com não pagamento.
- Perfil.Run não foi equiparado automaticamente ao selo mensal. Condições, entregáveis e relação entre ofertas permanecem a validar.

## Antes da integração

Após os ajustes, adicionar armazenamento compartilhado com validação no servidor, acesso de leitura à equipe autorizada, edição por responsáveis autorizados, histórico de alterações e controle de concorrência. Confirmar os preços mínimos, políticas de desconto, escopo e automação de cada produto. Integrar o realizado a fontes de contratação comprovadas em etapa posterior, com cobertura explícita.

O usuário pediu ajustes antes de colocar no ar. Não há migration, alteração de menu ou publicação nesta etapa.
