## 2026 — Fontes BI do DBA: auditoria de adoção

O DBA criou `public.tbbi_fat_perfil_br_2026` (fato) e `public.vwbi_fat_perfil_br_2026` (view). Fontes registradas em **06/10/2026**, para o escopo **01/01 a 30/09/2026**. Esta seção reúne controles de adoção no caderno único **Brasil que Corre Provas — Estudo e publicação**. As células existentes foram lidas e preservadas; os destinos web continuam usando os congelamentos já publicados.

### Volumes auditados

| Fonte | Participações | Resultados distintos | Provas com participações |
| --- | ---: | ---: | ---: |
| Fato 2026 | 4.502.542 | 4.502.542 | 4.789 |
| View 2026 | 4.352.383 | 4.352.383 | 4.556 |
| Diferença | 150.159 | 150.159 | 233 |

Datas na fato: **02/01 a 30/09**. Nenhuma linha no quarto trimestre. Todas as linhas da fato têm correspondência em `tb_resultados` e respeitam os filtros do estudo: país BR, status final 0, resultado homologado e concluinte verdadeiro. Eventos e datas coincidem entre as fontes.

Na fato: **2.424.692 participações femininas (53,8516% do total)**; 2.076.518 masculinas; 1.332 com sexo X. São participações, não atletas únicos. O panorama congelado publicado tinha 4.500.869 participações; a diferença líquida é **+1.673**, sem atribuição automática a crescimento real. Agosto: 730.574 contra 730.611 publicados; setembro: 700.835 contra 699.125 publicados.

### Ponto a conciliar com o DBA: localidades

A view usa sete INNER JOINs. As **150.159 linhas descartadas (3,3350% da fato)** não encontram o `id_localidade` em `tbbi_dim_localidade`; as outras seis dimensões não apresentam ausências nesta auditoria. Os LEFT JOINs de controle não multiplicam linhas: continuam 4.502.542.

Exemplos de resultados presentes na fato e ausentes na view:

- Brooks Run the Bridge 2026, São Paulo/SP, evento 47090: **8.494**.
- Athenas Run Stronger 2026, São Paulo/SP, evento 43796: **6.211**.
- Circuito das Estações 2026 — Outono — Brasília/DF, evento 37835: **4.949**.

A diferença de 233 provas compara os IDs distintos presentes em cada fonte, não a quantidade de provas cadastradas no portal. Conferir a carga/chave de localidades e preservar o total nacional enquanto pendências geográficas forem resolvidas. Não corrigir por associação somente pelo nome da cidade.

### Idades e gerações

A fato possui **643.190 ranges nulos**. Destes, **271.540** têm nascimento plausível na base operacional, que pode ser usado pela regra já aprovada: idade em **31/12 do ano da prova**. Há **21 ranges divergentes** entre fato e operacional nesta captura. Categoria sem idade, como GERAL F SÓCIO, continua desconhecida se também não houver nascimento plausível.

Os IDs de geração existentes precisam ser conciliados com a regra do estudo. A função `get_id_geracao(int4range,integer)` localizada no banco usa sobreposição, Millennials 1981–1995 e Z 1996–2010; o ramo Alfa retorna ID 0 (não definido), embora a dimensão possua Alfa no ID 5. A regra aprovada no estudo usa Millennials 1981–1996, Z 1997–2009 e Alfa a partir de 2010 (recorte adulto 14+), com prioridade do nascimento plausível. Na ausência dele, uma faixa finita 14+ que cruza somente duas gerações vai inteira à geração da idade central `floor((inferior + superior_exclusivo - 1) / 2)`.

Exemplo: a fato registra **27.444 participações** com faixa `[14,20)` e ID 4 (Z). Pela regra de aproximação do estudo, **quando não há nascimento plausível**, 14–19 em 2026 tem idade central 16 e referência de nascimento 2010, portanto Alfa. Não significa que todas as 27.444 linhas devam ser movidas: com nascimento individual, a classificação depende desse nascimento.

A classificação de faixas etárias no estudo exige contenção integral; a função BI de categoria CBAt usa sobreposição. Os IDs prontos não substituem automaticamente os classificadores revisados. A fato não inclui nascimento, tipo da corrida nem flags operacionais de conclusão/status; os recortes que dependem deles precisarão de cruzamento por ID.

### Execução no notebook

A auditoria acima foi obtida por consultas agregadas via ColdFusion em transações **READ ONLY**. As consultas abaixo estão salvas para repetir os controles. **Ainda não há execução congelada destas novas células:** o papel `estudo_reader`, usado pelo executor do notebook, não possui SELECT nas duas fontes 2026. Também falta SELECT na nova dimensão `tbbi_dim_organizacao_2026`, usada pelo controle de integridade.

Pedido técnico para o DBA liberar as fontes e a dimensão de organização no notebook:

```sql
GRANT SELECT ON public.tbbi_fat_perfil_br_2026,
  public.vwbi_fat_perfil_br_2026,
  public.tbbi_dim_organizacao_2026 TO estudo_reader;
```

Após conciliar localidades, classificadores e permissões, executar e congelar os controles; então adaptar as células de saída 2026 com controle de versão. Não publicar a view reduzida como se representasse o total da fato.
