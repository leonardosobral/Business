PACOTE COMPLETO — 11 CIDADES — 20/10/2026

Substitui a hipótese de Rio já persistido. O coordenador constatou erro de
entidade no assistente e informou que a campanha/grupo Rio não existem.
O pacote original de 10 grupos permanece intacto na pasta superior.
Nenhum upload foi executado por este agente.

Ordem para prévia e eventual aplicação individual:
00-create-campaign.csv: 1 campanha PAUSADA.
01-ad-groups.csv: 11 grupos PAUSADOS.
02-responsive-search-ads.csv: 11 RSA PAUSADOS.
03-keywords.csv: 55 keywords PAUSADAS (33 frase, 22 exatas).
Rio: LIVE | Rio de Janeiro RJ.
Demais nomes, anúncios, destinos e UTMs seguem o pacote anterior.

00 cria:
Campaign = RR | LIVE 2026 | Pesquisa por cidade | Cupom 15%
Campaign status = Paused
Campaign type = Search
Networks = Google search
Budget = 20.00 (na moeda da conta; confirmar BRL na prévia)
Budget type = Daily
Bid strategy type = Manual CPC
Campaign end date = 2026-12-19
Language = pt
Location = 11 nomes canônicos de cidades separados por ponto e vírgula.

Manual CPC é somente o estado intermediário solicitado. NÃO ativar assim:
antes de habilitar, ajustar pela interface para maximizar cliques com teto
CPC R$ 0,50 e segmentação por PRESENÇA. O template de criação não documenta
campo para presença nem teto CPC da estratégia maximizar cliques.
Não há lance de keyword no pacote; esse lote não declara CPC configurado.
Não confundir orçamento diário com limite total da campanha.

O campo Campaign end date é suportado pelo modelo oficial, em YYYY-MM-DD.
19/12 foi a data expressamente solicitada; Salvador ocorre em 20/12.
Os grupos de etapas anteriores não possuem desligamento automático neste
CSV; requerem encerramento conforme calendário de cada etapa.

Locais verificados na base oficial de geotargets 2026-10-06, todos City/Active:
Bonito/MS 1031495; Rio de Janeiro/RJ 1001655; Fortaleza/CE 1001538;
Recife/PE 1001625; Belo Horizonte/MG 1001566; Porto Alegre/RS 1001686;
Niterói/RJ 1001650; Osasco/SP 1001754; Brasília/DF 1001541;
Foz do Iguaçu/PR 1031634; Salvador/BA 1001533.
O CSV usa nomes canônicos completos conforme o exemplo oficial. IDs acima
servem para conferir a resolução na prévia. geo-selected.json preserva a
seleção e a URL da base. Bonito/PE e entradas de nomes canônicos mais longos
foram excluídos; conferir que a prévia resolve os 11 municípios esperados.

Validação: cabeçalhos comparados literalmente com os modelos oficiais;
gerador @oai/artifact-tool e parser CSV independente; 1/11/11/55 linhas.
Títulos até25/30; descrições até81/90; sem Ribeirão ou Fortaleza duplicado.
Prévia na conta ainda necessária. Se 00 falhar, não prosseguir aos demais.
Se houver sucesso parcial, não reaplicar todo o lote Add.

Modelo oficial Create New Campaign(s), consultado 20/10/2026:
https://support.google.com/google-ads/answer/10702525?hl=en
https://storage.googleapis.com/support-kms-prod/lx4kKazVwHuqcFVQPZAKJJ5EUQAV5VBBMrn2
Download preservado em ../campaign-official-template.
Cabeçalhos e notas preservados em ../campaign-official-template-cells.json.

Geotargets oficiais:
https://developers.google.com/google-ads/api/data/geotargets
https://developers.google.com/static/google-ads/api/data/geo/geotargets-2026-10-06.csv.zip

Presença versus presença/interesse (padrão):
https://support.google.com/google-ads/answer/1722038?hl=en

Demais fontes de cabeçalhos, limites RSA e fluxo de prévia estão no
../README.txt, que documenta o pacote anterior de 10 grupos.
