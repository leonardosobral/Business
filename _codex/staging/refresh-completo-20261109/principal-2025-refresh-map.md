# Estudo principal 2025 — mapa para renovação coordenada

Levantamento somente leitura em 09/11/2026. Base: inventário `notebook-before.json`, fontes atuais em `sources/`, recibos já produzidos em `runs/` e leitura dos textos/metadados das projeções congeladas. Nenhuma fonte operacional foi executada por esta subtarefa, nenhum SQL foi salvo/alterado, nenhuma tabela/runtime/publicação foi modificada.

## Conclusão operacional

**Decisão vigente do controlador,09/11/2026:** a edição principal anual2025 não será renovada integralmente nesta rodada. O foco permanece2026 e referênciasJan–Set2025. As fontes compartilhadas já coletadas ficam preservadas para uso coordenado; a lista de fontesanuais abaixo é um plano futuro, sem autorização de executá-las agora. Uma atualização ampla2025exigirá nova projeção completa. **Nunca usar novos totaisJan–Setcomo denominadoresanuais.**

A edição principal 2025 é **anual 01/01–31/12/2025**, atualmente destino 2025/v19, **publicação37 → execução205 → célula249 rev34**, contrato 13, 131 séries. Isso é diferente da referênciaJan–Set2025 do comparativo 2026.

**Executar novamente249, ou só trocar todos os IDs que aparecem nela, não renova a edição inteira.** O SQL atual herda quase tudo do congelamento150 e altera efetivamente idades/gerações e cruzamentos de346/348/349 e diferençasAlfa+Z de380. As outras fontes declaradas são, majoritariamente, guardas de existência; não fornecem novos valores aos demais blocos2025. O metadado herdado `notebook_fontes` tampouco enumera fielmente as substituições recentes de geração. A projeção nova precisa substituir cada família de `comparacoes.atual`, renovar sua proveniência e conservar separadamente os valores históricos do PDF.

Não há dependência da carga da fatoBI2026 para coletar as fontes **exclusivamente2025/2024/2023** abaixo. As consultas mistas359/378/368 incluem2026 no mesmo statement e devem ser coordenadas com a decisão da BI, embora seu ramo2025 seja operacional.

## Linhagem real da projeção atual

A cadeia principal congelada é:

`205 ← 150 ← 142 ← 135 ← 130 ← 120 ← 108 ← 100 ← 95 ← 86 ← 80 ← 72 ← 63 ← 55 ← 45 ← 35/32`.

| Camada publicada/herdada | O que acrescentou ou substituiu |
|---|---|
|32,249rev2|Base de apresentação2025 em `estudo.web_bases`, mais155/#6 gênero,157/#7 total,159/#8 eventos,177/#15 distância,179/#16 distância dentro do sexo,181/#17 presença5km e207/#25 calendário.|
|35|Referência literal do PDF paraP13,255/#34.|
|45|Dez maratonas fixas2025,259rev2/#41.|
|55|Capital/interior,267rev2/#52.|
|63|Performance/CNA,274rev2/#60.|
|72|Médias revisadas de maratonas e atividades,283/#70 e284/#71; fontes operacionais281/#67 e282/#69.|
|80|Regiões/UF por287/#75 e cidades288rev2/#77.|
|86|Volumes anuais2023–2025 por292/#83.|
|95|Regra antiga de idade/geração294/#87,295/#88,296/#89; valores hoje substituídos pela regra V2 em 205.|
|100|Estações300/#97 e pódio301/#98, ambos derivados de congelamentos.|
|108|Perfil305rev4/#104, dez indicadores e regra de peso20–300kg.|
|120|Cobertura312rev3/#117 e auditoria14+314/#118.|
|130|Mapeamento329/#129 e cinco referências históricas ausentes conservadas comoNULL.|
|135|Resumo das dez maratonas331rev2/#134.|
|142|Cadastro/coleta333/#137 e referênciaNYRR334/#138. Idêntica à139 emJSONB, nova publicação operacional.|
|150|Porte/concentração341/#148.|
|205|Idades, gerações e cruzamentos346/#156(2023),348/#158(2024),349/#159(2025), diferenças380rev1/#190. O restante continua herdado de150.|

## Fontes operacionais2025 que faltam renovar

As versões e execuções abaixo são do baseline, antes de novas coletas desta rodada. Cada consulta mantém seu próprio universo; não harmonizar filtros silenciosamente para os da referênciaJan–Set2025.

| Célula/revisão e congelamento antigo | Família e contrato | Situação/recomendação |
|---|---|---|
|155v1/#6|Gênero2024/2025; compara editor, DataGrip eBI. O DataGrip 2025 exige tempo positivo; não equivale ao gênero do comparativoQ3.|Coletável numa renovação anual futura, adiada; preservar cada versão e selecionar explicitamente o ramo já publicado. O ramoBI2025 continua uma fonte física própria.|
|157v1/#7|Total2025 editor/DataGrip, ano completo; DataGrip usa `vw_resultados`.|Coletável numa renovação anual futura, adiada; não trocar pelo347/Q3.|
|159v1/#8|Eventos2024/2025, BR, rua/trail; cadastrados, coletados e elegíveis.|Coletável numa renovação anual futura, adiada.|
|177v1/#15;179v1/#16;181v1/#17|Faixas de distância, distribuição dentro do sexo, presença5 km 2025, rua/`vw_resultados`.|Coletável numa renovação anual futura, adiada.|
|195v1/#21;199v1/#22|Regiões2024/2025 por geral/F/M eUF2025, `vw_resultados`.|Coletável numa renovação anual futura, adiada; alimentam287.|
|207v1/#25|Meses/trimestres2025 editor/DataGrip.|Coletável numa renovação anual futura, adiada; alimenta estações após projeção/referências novas.|
|259v2/#41|Dez maratonas2025 da seleção histórica fixa; contagens, sexo, tempos com população revisada.|Coletável numa renovação anual futura, adiada; não substituir pela seleção nacional41provas do vertical nem pela seleção dinâmica2026.|
|274v2/#60|Ritmo/performance eCNA2025 anual. Limites e população próprios, sem limiar de plausibilidade.|Coletável numa renovação anual futura, adiada;351 é apenas2026.|
|281v2/#67|Médias dos menores tempos, top10/100/percentuais, mesmas dez maratonas2025.|Coletável numa renovação anual futura, adiada; desempate porid_resultado determinístico.|
|282v2/#69|AtividadesStrava2025, exclui `aspect_type=delete` do total publicado, todos os tipos preenchidos no denominador.|Coletável numa renovação anual futura, adiada; os nove meses2026 já renovados não substituem esta fonte anual2025.|
|292v1/#83|Volumes anuais2023/2024/2025, BR/todas idades/modalidades, bruto e status0/homologado.|Coletável numa renovação anual futura, adiada; é a comparação anual deP03.|
|346 v1/#156;348 v1/#158;349 v1/#159|Idades/geraçõesV2 anuais2023/2024/2025, nascimento plausível prioritário e aproximação central aprovada.|Coletável numa renovação anual futura, adiada; são as substituições vigentes, não reexecutar294/295/296 como fonte final.|
|356 v1/#166|Auditoria14+2025 anual eJan–Set, status0/homologado, sem alterar totais.|Coletável numa renovação anual futura, adiada; substitui314 na saída renovada, sem reduzir o denominador geral.|

## Fontes compartilhadas já renovadas ou previstas nesta rodada

| Fonte atual | Abrangência útil para2025 | Recibo encontrado nesta rodada |
|---|---|---|
|361v1|Perfil de contas até31/12/2025 e até30/09/2026, atributos observados hoje.|**#267 congelado**; substituir305/#104 só no ramo2025, mantendo regra de peso e explicação temporal.|
|363v1|Mapeamento2025 anual e2026 Q3, mesma regra porID doStats.|**#268 congelado**; reutilizável para2025 em vez de329/#129.|
|364v1|Cadastro/coleta de maratonas2025 anual e2026 Q3, unidadeevento.|**#269 congelado**; reutilizável para2025 em vez de333/#137.|
|355v1|Cobertura do cadastro2025 anual/Q3 e2026 Q3, eventos/coleta/elegíveis separados.|**#270 congelado**; reutilizável para2025 em vez de312/#117.|
|365+369–376|Partições de atividadesJan–Set2026.|**#277–285 congelados**; utilidade apenas2026;2025 continua282.|
|347v1|PanoramaJan–Set2025 com concluinte.|**#273 congelado**; serve ao comparativoQ3, não ao total/gênero anual 2025.|
|352v1;354v1|GeraçõesJan–Set2024 eJan–Set2025 com regra deconclusão.|**#275 e#274 congelados**; servem aos deltas2026 Q3, não substituem348/349anuais.|
|421v1|Capital/interiorJan–Set2025, homologado/concluinte.|**#276 congelado**; referência públicaQ3, não capital/interioranual2025.|
|359v2|Cidades2025 anual +2026 Q3; resultados 2025 sem filtro adicional deconcluinte.|Prevista na renovação2026; ramo2025 pode substituir288/#77 com validação de igualdade de população.|
|378v2|Capital/interior2025 anual +2026 Q3.|Prevista na renovação2026; ramo2025 pode substituir267/#52, preservando a diferença de universo em relação421.|
|368v2|Porte2025 anual +2026 Q3.|Prevista na renovação2026; ramo2025 pode substituir341/#148, com população e data2025 idênticas.|

Os recibos acima foram lidos do diretório `runs/` durante o levantamento; novas coletas do controlador podem ter avançado depois desta fotografia.

## Derivadas que precisam nova revisão antes de executar

| Derivada | Dependências e cuidado |
|---|---|
|283v1/#70|ConciliaçãoP13 sobre281/#67 revisado,264/#48 legado e255/#34PDF. Trocar a referência revisada para a coleta nova281. O legado/PDF são evidência histórica; só recolher264 se for desejada uma comparação legada atual, identificada como tal.|
|284v1/#71|Atividades por11 tipos.2025 vem282/#69; o SQL também lê fontes antigas2026 e pacote63. Renovar a referência2025 e manter denominador de todos os tipos, inclusiveRun; nunca somar só os11 tipos para obter o denominador.|
|287v1/#75|Geografia:195/#21 e199/#22, além do antigo pacote2026/#74. Renovar os dois ramos2025; preservar ou atualizar separadamente o ramo2026.|
|300v1/#97|Estações por meses inteiros derivadas dos pacotes95/96. Precisa projeção mensal2025 renovada; só executar sem editar repete dados antigos.|
|301 v1/#98|Pódio a partir do pacote95. Recalcular depois de atualizar contagens259 e médias281 na projeção;11critérios, tempos arredondados ao segundo eRANK com empates.|
|331 v2/#134|Resumo das dez maratonas a partir259/#41 e309/#111. Renovar o ramo2025 por nova259, inclusiveCASE/guardas porID; o ramo2026 é outro recorte.|
|380 v2/#225|DiferençasAlfa+Z: anuais346/348/349 eQ3352/354/357. Reapontar todas as fontes para uma rodada coerente. Para2025, usar só comparações anuais2025 vs 2023/2024. A 249 atual ainda lê380v1/#190; atualizar para a revisão vigente com referências novas.|
|249 v34/#205|Montar nova projeção integral das famílias renovadas; não usar150 como fonte atual dos blocosque deveriam mudar. Conservar oPDF e overlaysverificados, precisãoJSONB, ausênciasNULL, notas de universo e contratos.|

## Comparações2024 e referências oficiais

- **Gênero2024:**155/#6, ramoDataGrip 2024; não vem da BI 2026.
- **Regiões2024:**195/#21, agregado em287/#75.
- **Volume/eventos2024:**292/#83 e159/#8, com universos próprios; a anual2025usa ano completo.
- **Gerações2024:**348/#158anual para publicação2025.352/#162éQ3para comparação2026, renovada em#275.
- **Base histórica PDF 2025:**`estudo.web_bases` e255/#34 P13. Valores publicados permanecem históricos, distintos do recálculo atual; as cinco referências não recuperadas continuamNULL. Não transformar publicaçãoPDF em nova coleta.
- **NYRR 2025:**principal 37 herda334/#138, captura documentada03/10/2026, **59.226**. Existe evidência oficial posterior já congelada em449v2/#263, consulta de19/10, **59.219**, URL `https://results.nyrr.org/event/M2025/overview`; causa dossete registros de diferença não apurada. Reexecutar 334 não consulta NYRR e repete 59.226. Para adotar 59.219 na renovação, apontar explicitamente essa evidência mais recente e preservar 59.226 como divulgação anterior; não atribuir a mudança à base brasileira. Fonte 263 pertence avertical e seu restante não substitui o estudo principal.
- **Floripa oficial:**402/#210éoverlay de 2026, Geral/Elite 3.592, mantido na performance de maratonas 2026. Não se aplica à principal 2025 nem deve entrar em totais nacionais/coorte por mera associação. Casos Boston/NB e seleções verticais 244/245 têm produtos e contratos próprios; não substituir automaticamente as dez maratonas fixas 2025.
- **2026NYRR:**mesmo após a realização emnovembro, continua fora do corte Jan–Set2026. Manter NULL como fora do escopo; a nota de situação pode ser ajustada sem importar volume Q4.

## Ordem recomendada para uma futura renovação anual, adiada

Nenhum passo desta lista deve ser executado na rodada atual, além do reaproveitamento das fontes compartilhadas já coletadas quando necessário ao2026/Q3.

1. Numa futura rodada anual autorizada, coletar os18IDs independentes que faltam: **155,157,159,177,179,181,195,199,207,259,274,281,282,292,346,348,349,356**. São leituras de fontes existentes; conservar versões e SQL e o limite de duas execuções. A155inclui consulta BI 2025 comparativa; se a preocupação é carga concorrente, agendar separada.
2. Reutilizar os congelamentos compartilhados existentes **361/#267,363/#268,364/#269,355/#270**; aguardar359/378/368coordenados com2026 ou projetar o2025 já disponível apenas depois de coleta validada. Evitar recoleta duplicada do mesmo assunto.
3. Revisar osIDs nas derivadas283/284/287/300/301/331/380, ou compor suas transformações equivalentes numa nova saída versionada, com todos os IDs explícitos. Executar/congelar só depois das fontes operacionais.
4. Preparar nova 249 com todas as famílias renovadas, preservando PDF/NULL/overlays, validar131 séries ou explicar qualquer alteração aditiva de contrato; comparar geografia, meses, totais, perfil e dez maratonas por família. `coletado_em` geral herdado26/09não comprova renovação de todos os temas: registrar datas/fontes por tema.
5. Publicar apenas quando o pacote 2025 e o pacote Q3 2026 forem conciliados pelo controlador, com baseline/backup próprios; não presumir que promover 2026 também promove 2025. Nenhuma publicação realizada por esta subtarefa.
