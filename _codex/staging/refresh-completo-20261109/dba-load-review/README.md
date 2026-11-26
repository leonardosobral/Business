# Revisão da rotina DBA 2026 — somente leitura, 09/11/2026

**A rotina recebida não deve ser executada literalmente no banco vigente.** O SELECT pode ser adaptado para a atualização autorizada preservando os contratos atuais; o ciclo DROP/CREATE e os nove COMMITs não são uma substituição segura.

Nenhuma carga, DDL, DML, edição de notebook, alteração de função/view/runtime ou publicação foi executada nesta revisão. As consultas de evidência rodaram em transações READ ONLY, limite 45s, com resultados exclusivamente agregados. Arquivos nesta pasta são recibos locais; a consulta proposta não foi executada. Nenhum dado pessoal individual foi retornado.

## Material e compatibilidade estrutural

Fonte original: `/Users/leonardosobral/Downloads/script_perfil_br_corre_2026.sql`.
SHA256 **d9907382d2de1c9d396d4edb0d23c907c89aa0e74bca62cfa6783c99b34c6a08**. Nove INSERTs mensais cobrem janeiro–setembro, sem sobreposição. Há nove COMMITs e um DROP VIEW seguido de DROP TABLE.

As **20 colunas**, sua ordem e os tipos da tabela declarada coincidem com a fato atual; os INSERTs fornecem19 colunas explícitas, deixando o serial gerar a chave. A ordem CBAt/faixa no INSERT é diferente da ordem física, mas seus nomes explícitos correspondem ao SELECT: isso não é erro.

A definição da view pública recebida reproduz os sete INNER JOINs atuais. O estudo usa `estudo.vwbi_perfil_br_2026`, com sete LEFT JOINs sobre a fato, e depois complementa campos operacionais por id_resultado. Esses contratos devem sobreviver integralmente. A fonte não contém código de recriação desses adaptadores.

## O que os filtros fariam hoje

Snapshot **16:09:00-03**, confirmado nos controles de nulidade às16:11:25:

| Controle | Participações |
|---|---:|
|Universo aprovado: BR, data_final01/01–30/09, status0, resultado homologado e concluinte|**4.573.104**|
|SELECT original, após seus filtros e INNER JOIN de data|**4.573.104**|
|Elegíveis excluídos pelo conjunto de filtros adicionais|**0**|
|KIDS exato entre elegíveis|0|
|ModalidadeNULL entre elegíveis|0|
|TempoNULL entre elegíveis|0|
|Tipo de evento fora de rua/trail entre elegíveis|0|
|Resultado homologadofalse no recorte status0+concluinte|0|
|Resultado homologadoNULL no recorte status0+concluinte|0|
|Elegíveis sem correspondência de data_inicial na dimensão|0|
|Multiplicações por data_referencia duplicada|0|
|Eventos distintos no universo e no SELECT original|4.964|

Os `SUM(...) FILTER(...)` que retornaramNULL em `criteria.json` representam **soma sobre nenhum grupo**, isto é, zero ocorrências neste controle completo. Não são observações faltantes. `approved_flag_groups` contém apenas um grupo, com todas as4.573.104linhas: modalidade preenchida e diferente de KIDS, tempo preenchido e tipo permitido. `source-null-check.json` retornaCOUNTs explícitos0 para homologaçãofalse/NULL.

Logo, **os filtros divergentes não alteram o universo neste snapshot**. Ainda assim, não são o contrato aprovado: KIDS, modalidades ausentes, outros tipos e tempoNULL permanecem no total nacional quando forem elegíveis por status/homologação/conclusão. Faixas de desempenho aplicam seus filtros em seus recortes próprios. O filtro de homologação de resultado está comentado no arquivo e deve ficar explícito na adaptação; hoje não havia linha adicional a eliminar por esse critério. Não acrescentar filtro de homologação do evento, idade14+, PCD ou tempo positivo ao total.

Totais mensais do snapshot: **158.051;165.059;566.764;459.228;719.782;529.639;509.871;742.644;722.066**. A origem está viva; não misturar estes totais com capturas anteriores em que havia menos IDs.

## Dimensão de data e nulidade

`tbbi_dim_data` contém **7.305 datas/linhas únicas**, de 01/01/2010 a 31/12/2029. Nenhuma data duplicada e nenhuma ausência nas datas inicial/final dos resultados elegíveis do recorte. A igualdade de data_inicial encontra exatamente uma linha por evento.

Há **131.799 participações** em eventos com data_inicial diferente de data_final; **61 cruzam mês** e nenhuma cruza ano. O SELECT grava `id_data` pela data_inicial, mas `data_evento` pela data_final. Isso é o contrato já existente, não perda de IDs neste snapshot. O estudo deve continuar extraindo período/mês de data_evento/data_final. Trocar id_data para data_final seria mudança de semântica das dimensões e não está incluída nesta revisão.

A origem `tb_resultados` **permiteNULL em sexo e percurso**; a fato não permite. Controle exato do universo aprovado atual: **0 sexoNULL,0 percursoNULL,0 sexo com comprimento diferente de1**. Portanto não existe bloqueio atual de inserção nesses campos. Na validação imediatamente anterior à carga, qualquer novo caso deve bloquear para conciliação; não usar coalesce, truncar texto nem excluir IDs silenciosamente.

## Gerações: usar a assinatura de quatro argumentos

As duas assinaturas de `public.get_id_geracao` **estão vigentes** e inalteradas desde o inventário desta tarefa. A de dois argumentos já contém os limites e a aproximação central corrigidos. Ela só recebe range e ano, portanto não pode priorizar nascimento. A de quatro argumentos aplica a mesma regra, com nascimento individual plausível primeiro.

- **Operacional elegível atual:**4.573.104 participações em4.953 grupos de range/ano de nascimento plausível;1.569.824com nascimento plausível. As assinaturas2/4argumentos divergem para **509.932participações(11,1507%)**.
- **Fato vigente:**4.502.542 participações em4.945 grupos;585 IDs já não existem na origem operacional. As classificações gravadas coincidem com a assinatura de quatro argumentos para **todas as linhas** neste controle. Usar apenas dois argumentos alteraria **494.573 classificações vigentes(10,9843%)**, revertendo a prioridade de nascimento para essesIDs. A matriz completa está em `generation-bi.json`.
- As **860.031 alterações históricas** registradas em 06/10 incluíam tanto a correção da função anterior quanto a aplicação da prioridade do nascimento. Não se deve dizer que a assinatura atual de dois argumentos reverteria exatamente 860.031 linhas; o efeito medido hoje é 494.573 na fato vigente.

Para reduzir custo, as consultas agrupam previamente por range/ano de nascimento plausível, sem retornar nascimentos. Depois de validar plausibilidade contra a data real, usam01/01do ano do nascimento e31/12/2026somente como representantes equivalentes para chamar a função: a implementação vigente depende apenas do ano quando a plausibilidade já está determinada. Não é imputação de nascimento nem alteração de critério.

Substituição exata na projeção:

```sql
public.get_id_geracao(
  res.idade_range,
  extract(year FROM evt.data_final)::integer,
  res.data_nascimento,
  evt.data_final
) AS id_geracao
```

Hashes das definições, todos iguais aos do inventário anterior:

|Função|SHA256|
|---|---|
|get_id_geracao(range,ano)|a32059aaa3554479635269e2b320ad107409a16cb45b1edfd2714b971205497e|
|get_id_geracao(range,ano,nascimento,evento)|bd6be56306b8dbe8f96641c57ea7e60f08f04292ec67d303e02af29e2a9b13f5|
|get_id_categoria_cbat(range)|cef95b42f1b5dba006dbc30225cc5eb40be3064d34930db53413a364f883f9a5|

`get_id_dim_faixa(percurso,tempo)` retorna0 para tempoNULL, portanto sua função não exige a exclusão dessas participações do universo. `get_id_categoria_cbat` mantém sua regra BI por sobreposição; não deve substituir os classificadores do estudo que exigem contenção integral. Nenhuma função foi alterada.

## Por que o ciclo de DDL não é seguro

1. `estudo.vwbi_perfil_br_2026` depende **diretamente da tabela**, e os adaptadores de resultados dependem dela. DROP VIEW pública pode concluir; DROP TABLE seguinte falha pela dependência do estudo. Sob autocommit isso pode deixar a view pública ausente. Não usar CASCADE: apagaria contratos consumidores.
2. DROP/CREATE perderia OID, sequência atual, ACL e qualquer dependência. O arquivo concedeSELECT à view para runner/akkio_user eDML na tabela para runner, mas não restaura oSELECT de **estudo_reader** já existente em ambas. Mesmo recriando a tabela, o notebook não teria o mesmo acesso.
3. Nove COMMITs expõem estados de carga mensal parcial. Uma falha depois de qualquer mês pode deixar uma base incompleta. Rodar trechos novamente pode duplicar IDs: a fato não tem constraint/index que impeça duplicatas de id_resultado.
4. A view pública continua com INNER JOINs; dimensões ausentes, em especial localidade0, podem excluir participações. O adaptador de estudo com LEFT JOINs deve permanecer e a conservação porID precisa ser conferida novamente após carga. Não corrigir localidades com aliases inventados.

## Adaptação proposta, sem novos critérios

`recommended-select.readonly.sql` contém **apenas a projeçãoSELECT proposta, não executada**. Mantém os 19 campos de carga e as regras originais de lookup de localidade/organização/cronometrador, com mesmos mínimos e fallback 0. Calcula esses atributos uma vez por evento. O LEFT JOIN de usuários equivale ao `min(strava_id)` original porque o ID referenciado pela FK é único; preserva NULL para usuário 0/ausente.

Alterações substantivas sobre oSELECT recebido:

- Usar homologação explícita de resultado e as datas **>=01/01/2026e<01/10/2026**; o mesmo período já coberto pelos nove meses.
- Remover os filtros globais de KIDS/modalidade, tipo de corrida e tempoNULL, conservando o universo previamente aprovado mesmo que apareçam novos casos após esta captura.
- Chamar a assinatura de quatro argumentos de geração; manter as demais funções vigentes.
- Qualificar fontes/funções como `public`, preservando seus donos e contratos.
- Preservar a ligação de id_data pela data_inicial, auditada como 1:1; não alterar a view pública nem os adaptadores.

Para promover uma carga futuramente, o controlador ainda precisa de backup integral recuperável e validado, baseline da fato/dimensões/ACL/sequence, staging separado com unicidade por id_resultado, controles no mesmo snapshot e troca atômica que preserve OID/dependências/ACL da tabela atual. Os nove COMMITs/DROPs não integram essa promoção. Esta revisão não preparou nem executou DDL/DML de carga.

## Evidências

- `source-manifest.json`: hash do arquivo original,20 colunas e comparação das definições de funções.
- `metadata.json`: view/ACL/funções atuais, dependências diretas e dimensão de data.
- `source-constraints.json`: nulidade da origem e chaves/FKs.
- `criteria.json`: filtros/data e totais por mês em um snapshot.
- `generation-raw.json` e `generation-bi.json`: matrizes agregadas 2args/4args e classificação gravada.
- `source-null-check.json`:COUNTs exatos deNULL/sexo e homologação.
- `*.readonly.sql` e `inspect.py`: consultas somente leitura reproduzíveis.

Os helpers e baselines de outras frentes foram preservados. Todas as chamadas e pontes temporárias concluíram e foram removidas pelo finally; nenhum navegador/servidor de teste foi iniciado.
