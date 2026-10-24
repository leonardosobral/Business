# Centauro: datas e preço à vista no feed Awin

Atualização posterior: os mapeamentos das demais lojas foram revisados e publicados às 17:51. Ver [preços promocionais](2026-10-17_awin-precos-promocionais.md). As regras e contagens de Centauro abaixo foram preservadas.

Publicado em 17/10/2026, às 17:21 de Brasília. **46 ofertas Centauro em 46 produtos; total de 95 ofertas em 64 produtos**. As 49 ofertas de outras lojas e os 26 vínculos de campanhas anteriores foram preservados. Importação real de seis feeds concluída sem erros.

## Diagnóstico confirmado

Anunciante 17806, feed 91869, Centauro BR 2024. Na lista autenticada: última verificação 2026-10-17T16:24:03Z, importação 16:25:05Z. Os 41.788 registros têm `valid_to` preenchido com inteiros de 1 a 10. O arquivo oficial com todas as colunas e o download com colunas explícitas apresentam a mesma anomalia; não é deslocamento de colunas do nosso parser.

A documentação da Awin define `valid_to` como data opcional de término. Nas amostras observadas na Centauro, os números coincidem com a quantidade de parcelas. Nenhum número foi convertido em uma data fictícia. Outro problema encontrado: `search_price` contém o preço original, enquanto `base_price` contém o preço à vista, com sufixo `BRL`. `base_price_amount` contém valor de parcela e não pode ser usado como total.

Conferência nas páginas da loja: Corre 4, cor H3, R$ 399,99 (original R$ 599,99); Pegasus 41 feminino, produto 990715/cor 52, R$ 519,99 no Pix (original R$ 999,99). Uma outra variante do Pegasus custa R$ 579,99 no Pix; ela não é o menor preço selecionado. Cores indisponíveis apareceram em links da amostragem inicial, porém não nos dois destinos selecionados acima. Disponibilidade de todos os SKUs não foi verificada na loja individualmente; a integração utiliza o estoque informado no feed.

## Regras e compatibilidade

Business é dono do tratamento. Somente a combinação anunciante **17806 + feed 91869**, com identidade da linha conferida, permite interpretar `valid_to` de **1 a 10** como vencimento não informado corretamente. Valores diferentes continuam rejeitados; outros anunciantes/feeds não recebem a exceção. `valid_from` numérico continua inválido. Uma data real, inclusive vencida/futura, continua sendo avaliada normalmente. As ofertas mantêm o prazo máximo de 24 horas, limitado também ao último `Last Checked` da origem. O consumidor continua removendo preços expirados a cada acesso.

São aceitos os formatos documentados pela Awin: data ISO, data/hora com T ou espaço, com ou sem offset. Horários sem fuso dos feeds BR usam America/Sao_Paulo. Data inicial sem hora começa à meia-noite; data final sem hora inclui o dia inteiro e vence na meia-noite seguinte. Datas impossíveis são rejeitadas, sem correção automática do calendário.

Para esse feed Centauro, o preço é `base_price`, desde que positivo, no formato decimal em BRL e menor ou igual a `search_price`. Valores ausentes, inválidos ou contraditórios são excluídos, sem fallback para preço original. Nenhum desconto é calculado a partir de campanhas, parcelas ou porcentagens. As demais lojas continuam usando `search_price`. Marca/modelo/geração, estoque, condição, conta, link de afiliado e bloqueios administrativos mantêm suas validações.

Contrato v1 permanece compatível. Campos aditivos na oferta: `priceSource` (`base_price`/`search_price`) e `priceType` (`cash`/`standard`). Relatório de feed contém `warnings.centauro_expiry_unavailable`, exibido no Business em Importação por loja e critérios de publicação. O leitor público já preserva campos adicionais. O card e o modal do Comparador identificam preços `cash` como à vista e orientam verificar pagamento/Pix na loja. Ofertas antigas sem esses campos continuam funcionando.

Resultado da Centauro: 41.788 linhas; 29 preços inconsistentes excluídos; 41.759 registros com aviso de vencimento; 1.246 SKUs vinculados a 46 produtos; 40.513 sem correspondência segura. O menor preço elegível por modelo/loja é publicado, com seu título e link. A rotina existente permanece a cada 30 minutos; não foi criado novo job, migração ou produto.

## Verificação e arquivos

- Business: `services/ComparadorAwinFeedService.cfc` e `administracao/comparador/awin/feed.cfm`; testes `awin-feed.cfm` (40) e `awin-feed-centauro-dates.cfm` (62).
- Comparador: `includes/produto_card.cfm`; documentação e evidências em `codex/docs/evidencias/awin-centauro-*.png`.
- 102 verificações unitárias CFML, incluindo isolamento da exceção, calendário, fuso, preço à vista e controles anteriores. 267 verificações de consulta/ordenação/filtro/fallback com snapshot privado. O filtro abaixo de R$ 400 inclui o Corre 4 da Centauro.
- Compilação ColdFusion 2025 dos três arquivos alterados e três dependências Business: 6/6. Sete checks HTTP de login, include protegido, método/autenticação do job, serviços não remotos e página pública.
- Importação real pelo Business, admin autenticado, POST e CSRF. Todas as **95 ofertas em 64 fichas públicas** verificadas por título, valor e URL. Comparação do snapshot anterior confirmou as 49 ofertas e bloqueios preservados. Campanhas continuam com 26 vínculos.
- Desktop e celular de 390 px verificados nos dois projetos, sem transbordamento horizontal. Token e configuração permaneceram privados: config 0640 root:988; snapshot 0600.

Testes executados em harness privado restrito a loopback, removido ao concluir. O teste de consulta datado usa o snapshot privado com as ofertas reais e o catálogo de 17/10; não é um contrato de contagem permanente. `awin-feed-centauro-dates.cfm` é independente de credenciais e não publica dados.

## Publicação e rollback

Release `20261017T202057Z-74596b8b`. Conferidos baselines locais/produção e hashes. Publicado primeiro o card do Comparador, compatível com o contrato anterior, depois os dois arquivos Business. Somente esses três arquivos de runtime foram enviados; nenhuma operação Git de escrita.

Backups: `/var/backups/awin-centauro-20261017/{comparador,business}/20261017T202057Z-74596b8b`; snapshot privado anterior em `state-before/20261017T202057Z-74596b8b-feed.json`. Para reverter, conferir alterações posteriores, reverter primeiro o produtor Business com o manifesto, reimportar (o produtor anterior excluirá Centauro) e depois reverter a apresentação pública. Restaurar snapshot antigo somente se ainda válido e sem perder bloqueios administrativos posteriores. Preservar credenciais, proprietário/grupo e modos; não restaurar preços vencidos.

Fontes: [campos oficiais e formatos de data Awin](https://help.awin.com/developers/docs/hosting-feeds), [lista de feeds](https://help.awin.com/developers/docs/product-feed-list-download), páginas de produto da Centauro indicadas no recibo. O tratamento é uma adaptação local ao mapeamento observado; a origem ainda deve corrigir seus campos para seguir o padrão Awin.
