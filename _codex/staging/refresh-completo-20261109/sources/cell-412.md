## Atualização de 06/10/2026 — função de gerações corrigida

**Aplicada no PostgreSQL em 06/10/2026 às 22:48 (-03), por autorização do usuário.** Esta atualização resolve o item da auditoria referente à função. O inventário e a nota anteriores descrevem a captura anterior à alteração e ficam preservados.

### Critério aplicado

- Boomers: nascimento 1946–1964, ID 1; X: 1965–1980, ID 2; Millennials: 1981–1996, ID 3; Z: 1997–2009, ID 4; Alfa: 2010 em diante e idade 14+, ID 5.
- Ano de referência: ano da prova; idade individual em **31/12**, igual ao ano da prova menos o ano do nascimento.
- Sem nascimento plausível, faixa válida inteira em uma geração é classificada diretamente. Faixa finita 14+ cruzando exatamente duas coortes vai à geração da idade central; no empate entre duas idades centrais, usa a menor (mais jovem).
- Faixas abertas, ausentes, inválidas, com menores de 14 ou cruzando mais de duas coortes retornam ID 0. Anteriores a 1946 também retornam 0, pois a dimensão BI não possui ID próprio para esse grupo. O notebook do estudo continua separando esses motivos nos recortes detalhados.
- Conversão corrigida: `[14,20)` significa 14–19; em 2026, nascimento 2007–2012. A aproximação central usa idade 16 / nascimento 2010 / Alfa.

### Duas formas de chamar

A assinatura existente `get_id_geracao(int4range, integer)` foi mantida e passa a aplicar o novo critério da **faixa**. Foi preservado o OID 6018234, proprietário runner_dba e ACL original. A função é IMMUTABLE e SECURITY INVOKER, sem acesso a tabelas.

Para aproveitar o nascimento, a carga deve usar a nova assinatura de **quatro argumentos**:

```sql
public.get_id_geracao(
    r.idade_range,
    EXTRACT(YEAR FROM e.data_final)::integer,
    r.data_nascimento::date,
    e.data_final::date
)
```

Nascimento plausível: não futuro em relação à prova e idade em 31/12 entre 0 e 120. Ele prevalece sobre o range; menores de 14 retornam 0 pelo recorte do estudo. Sem nascimento plausível, a função usa o range. Se o ano informado divergir do ano da data da prova, retorna 0.

Exemplos conferidos no banco:

| Chamada | ID / geração |
| --- | --- |
| Faixa 14–19 em 2025, sem nascimento | 4 / Z |
| Faixa 14–19 em 2026, sem nascimento | 5 / Alfa |
| Faixa 40–49 em 2026, sem nascimento | 3 / Millennials (idade central 44) |
| Faixa 14–19 em 2026, nascimento em 2008 | 4 / Z (nascimento prevalece) |
| Sem range, nascimento em 1996, prova 2026 | 3 / Millennials |

### Validação e próximos dados

**53 casos específicos + 46.224 faixas/anos**, comparados a um classificador independente por contenção, cruzamento de coortes e idade central: **zero divergências**. Cobertura: nascimentos nos limites, 2023–2030, faixa aberta/vazia/ausente, intervalos amplos, menores de 14, idades/anos extremos, nascimento ausente/futuro/implausível, prioridade do nascimento e inconsistência de ano da prova. Primeiro teste revertido; aplicação confirmou os mesmos casos na transação antes do commit.

A alteração da função **não recalculou os IDs já gravados nas tabelas fato**. O DBA deve usar a chamada com nascimento na carga/recálculo e conferir os totais antes/depois. As 27.444 linhas de 14–19 identificadas na auditoria não devem ser todas movidas para Alfa: quando existe nascimento plausível, ele decide a geração.

Também permanecem pendentes as localidades ausentes na dimensão e as permissões de leitura das fontes BI. Nenhum destino web, snapshot publicado ou consulta existente foi alterado nesta aplicação.

### SQL aplicado — registro para o DBA

O executor do notebook continua aceitando somente consultas de leitura. O DDL abaixo documenta a alteração já aplicada; não deve ser executado pelo botão de consulta.

```sql
-- Critério do estudo, autorizado em 06/10/2026.
-- Mantém assinatura e IDs: 0=fora do recorte/indeterminado; 1=Boomers; 2=X;
-- 3=Millennials (1981–1996); 4=Z (1997–2009); 5=Alfa (>=2010, idade 14+).
-- Idade referida a 31/12. A faixa inteira vai à geração da idade central quando
-- cruza exatamente duas gerações; empate entre idades centrais usa a menor.
CREATE OR REPLACE FUNCTION public.get_id_geracao(
    p_faixa_idade int4range,
    p_ano_referencia integer
) RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
CALLED ON NULL INPUT
SECURITY INVOKER
AS $function$
DECLARE
    v_inferior integer;
    v_superior_exclusivo integer;
    v_nascimento_mais_antigo integer;
    v_nascimento_mais_recente integer;
    v_geracao_mais_antiga integer;
    v_geracao_mais_recente integer;
    v_nascimento_central integer;
BEGIN
    IF p_faixa_idade IS NULL OR p_ano_referencia IS NULL
       OR p_ano_referencia NOT BETWEEN 1900 AND 9999
       OR isempty(p_faixa_idade) OR lower_inf(p_faixa_idade) THEN
        RETURN 0;
    END IF;

    v_inferior := lower(p_faixa_idade);
    v_superior_exclusivo := upper(p_faixa_idade);
    IF v_inferior < 14 OR v_inferior > 120
       OR v_superior_exclusivo IS NULL OR v_superior_exclusivo > 121 THEN
        RETURN 0;
    END IF;

    -- [14,20) contém 14–19. Em 2026, os nascimentos são 2007–2012.
    v_nascimento_mais_antigo := p_ano_referencia - (v_superior_exclusivo - 1);
    v_nascimento_mais_recente := p_ano_referencia - v_inferior;
    v_geracao_mais_antiga := CASE
        WHEN v_nascimento_mais_antigo < 1946 THEN 0
        WHEN v_nascimento_mais_antigo < 1965 THEN 1
        WHEN v_nascimento_mais_antigo < 1981 THEN 2
        WHEN v_nascimento_mais_antigo < 1997 THEN 3
        WHEN v_nascimento_mais_antigo < 2010 THEN 4
        ELSE 5 END;
    v_geracao_mais_recente := CASE
        WHEN v_nascimento_mais_recente < 1946 THEN 0
        WHEN v_nascimento_mais_recente < 1965 THEN 1
        WHEN v_nascimento_mais_recente < 1981 THEN 2
        WHEN v_nascimento_mais_recente < 1997 THEN 3
        WHEN v_nascimento_mais_recente < 2010 THEN 4
        ELSE 5 END;

    IF v_geracao_mais_antiga = v_geracao_mais_recente THEN
        RETURN v_geracao_mais_antiga;
    END IF;
    -- Os IDs 0–5 seguem a ordem das coortes; diferença 1 = duas coortes vizinhas.
    IF v_geracao_mais_recente - v_geracao_mais_antiga <> 1 THEN
        RETURN 0;
    END IF;

    -- Divisão inteira positiva: floor, com preferência pela idade menor no empate.
    v_nascimento_central := p_ano_referencia
        - (v_inferior + v_superior_exclusivo - 1) / 2;
    RETURN CASE
        WHEN v_nascimento_central < 1946 THEN 0
        WHEN v_nascimento_central < 1965 THEN 1
        WHEN v_nascimento_central < 1981 THEN 2
        WHEN v_nascimento_central < 1997 THEN 3
        WHEN v_nascimento_central < 2010 THEN 4
        ELSE 5 END;
END;
$function$;

-- Sobrecarga explícita: nascimento plausível prevalece sobre o range.
-- Não muda chamadas existentes de dois argumentos. Sem nascimento plausível,
-- aplica o critério da faixa; sem range suficiente, retorna 0.
CREATE OR REPLACE FUNCTION public.get_id_geracao(
    p_faixa_idade int4range,
    p_ano_referencia integer,
    p_data_nascimento date,
    p_data_evento date
) RETURNS integer
LANGUAGE sql
IMMUTABLE
CALLED ON NULL INPUT
SECURITY INVOKER
AS $function$
SELECT CASE
    WHEN p_ano_referencia IS NULL OR p_ano_referencia NOT BETWEEN 1900 AND 9999
      OR (p_data_evento IS NOT NULL
          AND extract(year FROM p_data_evento)::integer <> p_ano_referencia) THEN 0
    WHEN p_data_nascimento IS NOT NULL AND p_data_evento IS NOT NULL
      AND p_data_nascimento <= p_data_evento
      AND p_ano_referencia - extract(year FROM p_data_nascimento)::integer BETWEEN 0 AND 120
    THEN public.get_id_geracao(
        int4range(
            p_ano_referencia - extract(year FROM p_data_nascimento)::integer,
            p_ano_referencia - extract(year FROM p_data_nascimento)::integer + 1,
            '[)'
        ),p_ano_referencia
    )
    ELSE public.get_id_geracao(p_faixa_idade,p_ano_referencia)
END;
$function$;
```
