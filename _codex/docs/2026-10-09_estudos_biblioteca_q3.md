# Lançamento Q3 — implementação de 09/10/2026

## O que está em produção

- Panorama público: https://roadrunners.run/brasilquecorreprovas/2026/
- Kit público: https://roadrunners.run/brasilquecorreprovas/2026/kit/
- Biblioteca pessoal e convites: https://business.roadrunners.run/estudos/
- Gestão: mesma biblioteca, aba **Gestão de convites**, exclusiva para administradores reais.
- Leitura completa: https://business.roadrunners.run/estudos/leitor/?ano=2026 — identidade e concessão conferidas no servidor, inclusive no JSON.

O panorama e o kit estão acessíveis por link, com `noindex` durante a preparação. A estreia editorial D0, divulgação, contatos e indexação ainda dependem da operação. Nenhuma mensagem foi enviada. Não há preço nem checkout anual ativos.

## Conteúdo e origem

A prévia compreende 01/01–30/09/2026 e usa a publicação imutável **41**, congelamento **233**, edição web **22**, coletada em 06/10. O produto `previa-2026-q3` guarda o `publicacao_id`; publicar o anual posteriormente não troca a prévia entregue aos convidados. Nenhuma query/célula/revisão do notebook foi alterada nesta etapa.

O público recebe apenas seis percentuais arredondados: 53,9% mulheres; 46,1% Millennials; 61,2% em percursos de rua positivos inferiores a 6 km; 47,5% no interior; 43,0% das participações Jan–Set no terceiro trimestre; 48,0% do volume nas 10% maiores provas da base de porte. Os universos e ressalvas acompanham cada indicador. São participações observadas, não atletas únicos nem uma estimativa censitária do mercado.

`estudo.lancamento_publico` é uma projeção por lista explícita de indicadores. O papel público `runner` lê apenas essa view para a nova rota. Totais e séries completas não são enviados escondidos ao navegador público. A fixture `public-preview.json` é exclusivamente de revisão local e não foi publicada.

O endereço antigo `/web/?ano=2026` encaminha ao panorama; `/web/dados.cfm?ano=2026` retorna 403. A edição 2025 e seu PDF continuam gratuitos e preservados. `/estudo/` permanece o notebook administrativo, independente da biblioteca `/estudos/`.

## Jornada operacional do piloto

1. Pessoa entra com Google no Business. A identidade pessoal verificada é suficiente para pedir acesso; aprovação empresarial e permissões para administrar eventos são independentes.
2. Pessoa envia pedido profissional/editorial ou registra preferência de contato sobre o anual. Solicitar não concede acesso. O interesse anual possui retirada explícita.
3. Administrador analisa os pedidos, ativa a campanha apropriada e emite voucher nominal, com e-mail e prazo. **Ativação não envia mensagens.**
4. O código é mostrado somente na emissão; o banco guarda SHA-256. A equipe copia e envia individualmente, após autorização da campanha/contato.
5. Destinatário entra com o mesmo e-mail e resgata. Resgate único cria acesso à prévia e elegibilidade a **50% na compra antecipada do anual**. Não libera o anual gratuitamente.
6. Admin pode revogar voucher ou acesso. O benefício da mesma origem é revogado junto; outro convite independente não é apagado.

Campanhas iniciais: **piloto**, **ABRACEO** e **editorial**, todas em rascunho, todas com 50% para quem resgatar. A campanha ABRACEO registra explicitamente que o acordo está em negociação. Não existe código coletivo, resgate anônimo, venda da prévia ou mensagem automática.

## Implementação e autorização

Oito tabelas novas no schema `estudo`: produtos, campanhas, vouchers, acessos, solicitações, interesses, benefícios e auditoria comercial. A auditoria é imutável. Datas de resgate incluem todo o dia informado, no fuso de Brasília.

O serviço reconsulta usuário ativo/excluído e administrador em toda ação; usa identidade pessoal estabelecida pelo Business, nunca um ID de cookie ou empresa selecionada. Rotas pessoais possuem allowlist exata na fronteira de delegação. O retorno Google admite somente destinos conhecidos da biblioteca, antes dos redirecionamentos empresariais. O notebook administrativo não teve seu guard ampliado.

O leitor reaproveita os arquivos visuais atuais, copiados de `/brasilquecorreprovas/web/`, com endpoint protegido. Para próximas alterações visuais, sincronizar explicitamente esses arquivos na pasta `Business/estudos/leitor/`; não copiar os endpoints públicos por cima dos guards privados. Uma atualização do congelamento Q3 também requer revisão explícita do produto, não seguir automaticamente o último ano publicado.

## Verificação e recuperação

- Compilação Adobe ColdFusion em produção antes de publicar.
- Baselines dos arquivos existentes comparados aos originais locais; somente 46 arquivos de runtime do escopo publicados, com backup.
- 25 verificações de serviço passaram em cenários com rollback: identidade, admin, pedido, opt-out, campanha, conflito de versão, voucher nominal/hash, duplicidade, resgate idempotente, benefício, pin, anual negado, auditoria e revogações independentes.
- Oito verificações da fronteira pessoal: preservação de contexto empresarial, rejeição de ações globais, parâmetros duplicados, autoridade de conta postada e rotas fora da lista.
- Chrome autenticado: biblioteca/admin e leitor completo; hotsite real em desktop e 390 px; seis percentuais, kit, imagens e fontes sem erro.
- HTTP anônimo na origem: projeção pública, 2025 preservado, 2026 completo negado, cookies antigos sem autoridade e redirecionamentos.
- Backup remoto: `/var/backups/study-q3-launch-20261009-v1/`. O operador faz compare-and-swap, compilação, hashes e backups das atualizações; não executar migrações antigas do notebook.

Os testes não deixam pedidos, vouchers, acessos ou interesses. As sequências podem ter lacunas devido ao rollback, o que é esperado. As campanhas reais continuam em rascunho.

## O que a equipe precisa fazer agora

Escolher os responsáveis e o grupo piloto; validar elegibilidade e acordo ABRACEO; escolher os primeiros criadores e autorizar contatos individuais; validar as peças antes de D0. Usar o plano operacional, briefing e rascunhos desta pasta. Os PDFs anteriores enviados aos founders estão preservados.

A gestão já mede pedidos pendentes, convites disponíveis, leitores com acesso e interesse no anual. Entrega de convites, visitas por canal, abertura efetiva e retorno em sete dias ainda precisam de registro operacional/instrumentação; não confundir acesso concedido com leitura. Não há disparador de e-mail, relatório de campanhas por criador ou monitoramento automático nesta entrega.

Para janeiro: validar preço, licença, datas e prazo do benefício; então ligar produto anual e elegibilidade ao checkout existente, com pagamento, estorno e concessão testados. R$ 497/R$ 248,50 e 06/01/11/01 continuam propostas; não foram publicados como oferta vigente.

## Curadoria Jan–Set de 10/10/2026

O serviço `StudyAccess.read` aplica ao produto `previa-2026-q3` a seleção editorial `q3-20261010-v1`, depois da autorização. A publicação imutável 41 continua com 137 séries; a resposta entrega 113 séries/702 valores, preservando precisão e fontes. Temas adiados (preços, CNA, ritmo nacional 42 km e auditoria cadastral) saem também do JSON/CSV. Nenhuma query ou célula do notebook foi alterada. Outros produtos e a edição 2025 não recebem esse filtro.

O leitor possui 37 páginas e uma página de temas previstos para o anual. Mantém idades/gerações, ritmo5/10/21 e as dez maratonas revisadas. Hotsite e biblioteca foram alinhados; assets possuem cachebuster da curadoria. Validação:29 verificações de serviço com rollback,11 HTTP,Chrome desktop/celular,sem estados vazios ou overflow. Evidências e plano de estreia10–14/10 em RoadRunners/_codex/docs/brasil_que_corre_provas/lancamento_q3_2026_10_09/.

## Entrada de contas sem acesso — 09/10/2026

A biblioteca abre em “Obter acesso” quando a pessoa ainda não pode ler a prévia. O voucher e a solicitação ficam na primeira tela, com introdução compacta. Quem já tem leitura liberada ou é administrador continua em “Minha leitura”. Links explícitos e intenções anual/editorial são preservados. Em “Minha leitura”, os botões “Resgatar voucher” e “Solicitar acesso” abrem a aba e focam o campo correspondente.

Após resgate bem-sucedido, o dashboard é atualizado e a aba “Minha leitura” é selecionada. O handler conserva a referência ao formulário antes do await, para o reset não depender de Event.currentTarget já expirado. Permissões, serviços e banco não foram alterados.

Runtime: estudos/index.cfm, biblioteca.js e biblioteca.css; assets versão20261009-3. Publicados com baseline, backup e compilaçãoCFML. Chrome com conta real sem acesso: entrada padrão, ambosCTAs/foco, destinosanual/editorial, teclado e390px verificados; nenhumoverflow ouerroconsole. Nenhum formulário foi enviado na validação visual.
