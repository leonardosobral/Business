Google Ads — LIVE 2026 — pacote para revisão
Preparado em 20/10/2026. Nenhum upload ou alteração de conta foi executado.

Campanha existente esperada, com nome EXATO:
RR | LIVE 2026 | Pesquisa por cidade | Cupom 15%

ARQUIVOS PARA UPLOAD, NESTA ORDEM
01-ad-groups.csv: 10 novos grupos.
02-responsive-search-ads.csv: 10 anúncios responsivos; 8 títulos e 4 descrições por anúncio.
03-keywords.csv: 50 palavras-chave, 3 de frase e 2 exatas por cidade.

CSV UTF-8 com BOM, vírgula como delimitador e CRLF. A primeira linha contém
os cabeçalhos; sem notas dos modelos, exemplos, fórmulas ou linhas extras.
Todos os grupos, anúncios e palavras-chave têm status Paused explícito.
Após importar, os três níveis precisam estar habilitados para veicular,
além de a campanha estar habilitada e os anúncios aprovados.
Os arquivos não contêm orçamento, lances, segmentação geográfica ou criação
de campanha. Upload destinado à conta individual da campanha, não ao MCC.

ESCOPO
Bonito/MS, Fortaleza/CE, Recife/PE, Belo Horizonte/MG, Porto Alegre/RS,
Niterói/RJ, Osasco/SP, Brasília/DF, Foz do Iguaçu/PR e Salvador/BA.
Rio de Janeiro/RJ já possui Grupo de anúncios1, com anúncio e 5 palavras-chave.
rio-review.json traz apenas uma proposta de revisão para esse grupo existente.
Não importar novas linhas Add para Rio nem reaplicar os CSVs após sucesso:
os arquivos de criação não são um procedimento de sincronização idempotente.
Fortaleza usa evento 37570; duplicado 45366 e Ribeirão 48557 foram excluídos.

DESTINOS E TEXTO
Final URL de cada anúncio aponta à respectiva página de evento Road Runners.
UTM: utm_source=google, utm_medium=cpc,
utm_campaign=live_pesquisa_cidades_202610, utm_content=cidade-uf sem acentos.
Palavras-chave herdam a URL do anúncio. Nenhuma URL de palavra-chave sobrescreve
esse destino. Verificar na prévia se há tracking template/suffix preexistente
na conta ou campanha que gere parâmetros conflitantes.
Oferta: 15% com código ROADRUNNERS, conforme views e página do evento.
Os textos não afirmam vendas, compras concluídas ou conversões medidas.
Não se anuncia ser o site oficial da LIVE; o destino é o Road Runners.

CABEÇALHOS E VALORES CONFERIDOS NOS MODELOS OFICIAIS
Grupos: Action, Campaign, Ad group, Status.
RSA: Action, Ad status, Campaign, Ad group, Ad type, Headline 1 até Headline 8,
Description, Description 2, Description 3, Description 4, Final URL.
ATENÇÃO: a primeira descrição é Description, sem número 1.
Keywords: Action, Campaign, Ad group, Keyword, Match Type, Keyword status.
Action=Add; Ad type=Responsive search ad; Match Type=Phrase match/Exact match.
O tipo de correspondência está na coluna específica; o texto de Keyword
não inclui aspas de frase ou colchetes de exata.
Os exemplos oficiais aceitam Campaign e Ad group por nome; IDs são omitidos.
Cada cabeçalho foi comparado literalmente com a linha completa do respectivo
XLSX baixado da página oficial. Os arquivos *-official-template preservam
os downloads originais; template-cells.json preserva a extração dos cabeçalhos.

PRÉVIA NA INTERFACE WEB — AINDA NÃO EXECUTADA
1. A campanha precisa existir como alvo de Uploads. Um rascunho ainda no
   assistente de criação não foi confirmado como alvo suportado; estes CSVs
   não o materializam. Se a prévia não encontrar a campanha, parar e resolver
   o estado da campanha na interface, mantendo o orçamento/geo já definidos.
2. Na conta correta: Ferramentas > Ações em massa > Uploads.
3. Enviar 01 e escolher Visualizar/Preview. Confirmar 10 criações de grupos
   pausados, somente nesta campanha. Aplicar apenas após revisão.
4. Após os grupos existirem, repetir Preview/revisão/aplicação para 02 e 03.
   Resultados esperados: 10 anúncios e 50 keywords, sem alterações ao Rio.
5. Conferir o resultado de cada upload antes de avançar. Se houver erro ou
   sucesso parcial, usar o relatório para preparar somente as linhas faltantes;
   não reaplicar o lote completo cegamente.
6. Revisar status, política de anúncios e destinos na conta. Os limites locais
   e a conformidade ao modelo não substituem essa validação do Google.

VALIDAÇÃO LOCAL
build.mjs usa @oai/artifact-tool para montar e ler as três tabelas.
Valida 11 cidades selecionadas, 10 novas, exclusão de duplicados/Ribeirão,
vínculo canônico/cupom ativo/página com cupom, campos oficiais e comprimentos.
Máximos observados: título 25/30; descrição 81/90.
Validação adicional por parser CSV independente: 10/10/50 linhas; grupos e
anúncios únicos; 30 Phrase match + 20 Exact match; URLs/UTM corretos;
status Paused e ausência de campos de orçamento/geo.
validation.json registra os resultados do gerador.
Base: ../city-matrix.json e ../city-matrix-selected.csv, consulta de 20/10.
As páginas de destino sem UTM retornaram HTTP 200 na matriz. Checkout não
foi testado. A matriz documenta a divergência de expiração no registro mestre
do cupom; as views e páginas atuais mostram o cupom ativo até 31/12/2026.

FONTES OFICIAIS CONSULTADAS EM 20/10/2026
Modelos de upload em lote (links Create Ad Group(s), Create Responsive Search
Ad(s), Add Keyword(s)):
https://support.google.com/google-ads/answer/10702525?hl=en

Formatar planilhas (CSV aceito, status e criação):
https://support.google.com/google-ads/answer/10702623?hl=en

Upload e prévia antes de aplicar:
https://support.google.com/google-ads/answer/10702433?hl=en

Anúncios responsivos, limites 30/90 e combinações de recursos:
https://support.google.com/google-ads/answer/7684791?hl=en

Downloads exatos dos modelos, também registrados em sources.json:
Grupos: https://storage.googleapis.com/support-kms-prod/eSiqsHfH2KNrnD4wnYuMX49DlTkbbz2C10Bs
RSA: https://storage.googleapis.com/support-kms-prod/4AQnEPOMnm95I6VILqWdg1xypQ9KlaXG2IgY
Keywords: https://storage.googleapis.com/support-kms-prod/ZPXjGm9HgYzegUH8aExrVUm3tHTp5rrvAc9a
