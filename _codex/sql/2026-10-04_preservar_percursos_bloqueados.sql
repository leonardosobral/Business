-- Executar via release.py com baseline, backup e ensaios aprovados.
-- Não corrige dados históricos; preserva percursos editados manualmente.
CREATE OR REPLACE FUNCTION public.grava_evento_corridas_percursos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE

var_data_percurso   date;
var_num_dias        integer;
var_arr_percursos   numeric[];
var_unidade         varchar;
prc                 numeric;


BEGIN

    if NEW.categorias is distinct from  OLD.categorias then
        delete from  tb_evento_corridas_percursos where id_evento = NEW.id_evento and percurso_bloqueado = false;

        if NEW.categorias is null then
            return NEW;
        end if;

        if position('km' in lower(NEW.categorias)) > 0 then
            var_unidade := 'km';
        else
            if position('milha' in lower(NEW.categorias)) > 0 or position('milha' in lower(NEW.nome_evento)) > 0  then
                var_unidade := 'mi';
            else
                var_unidade := '--';
            end if;
        end if;

        var_arr_percursos := array_remove(string_to_array(regexp_replace(NEW.categorias, '[^0-9.,]','','g'),','),'');
        var_num_dias := (NEW.data_final - NEW.data_inicial) + 1;

        foreach prc in array var_arr_percursos loop
            if prc < 21 then
            var_data_percurso := NEW.data_inicial;
            else
                if prc < 42 then
                    if var_num_dias = 1 then
                    var_data_percurso := NEW.data_inicial;
                    else
                    var_data_percurso := NEW.data_inicial + 1;
                    end if;
                else
                    if var_num_dias = 1 then
                    var_data_percurso := NEW.data_inicial;
                    else
                    var_data_percurso := NEW.data_final;
                    end if;
                end if;
            end if;

            insert into tb_evento_corridas_percursos
            ( percurso_evento, unidade_de_medida, id_evento, data_percurso, tipo_corrida )
            values
            ( prc, var_unidade, NEW.id_evento, var_data_percurso, NEW.tipo_corrida )
            on CONFLICT (percurso_evento, id_evento) DO UPDATE
            SET
                percurso_evento   = excluded.percurso_evento,
                unidade_de_medida = excluded.unidade_de_medida,
                id_evento         = excluded.id_evento,
                data_percurso     = excluded.data_percurso
            -- A edição manual bloqueada prevalece sobre a geração automática.
            WHERE NOT tb_evento_corridas_percursos.percurso_bloqueado;
        end loop;
    end if;

    if NEW.organizador is distinct from OLD.organizador then
        insert into tb_evento_corridas_fornecedores
            ( id_evento, id_fornecedor_tipo, id_fornecedor )
        select
            NEW.id_evento,
            1,
            fo.id_fornecedor
        from  tb_fornecedores fo
            where to_tsvector(unaccent(fo.nome_fornecedor)) @@ plainto_tsquery('portuguese',unaccent(trim(NEW.organizador)))
        on CONFLICT (id_evento, id_fornecedor_tipo, id_fornecedor) DO UPDATE
        SET
            id_fornecedor   = excluded.id_fornecedor;
    end if;

RETURN NEW;
END
$function$
;

CREATE OR REPLACE PROCEDURE public.grava_evento_corridas_percursos(IN p_id_evento integer, IN p_nome_evento character varying, IN p_data_ini date, IN p_data_fim date, IN p_categorias character varying)
 LANGUAGE plpgsql
AS $procedure$
DECLARE

var_percurso        integer;
var_data_percurso   date;
var_num_dias        integer;
var_arr_percursos   numeric[];
var_unidade         varchar;
prc                 integer;

BEGIN
    if p_categorias is null then
        return;
    end if;
    if position('km' in lower(p_categorias)) > 0 then
        var_unidade := 'km';
    else
        if position('milha' in lower(p_categorias)) > 0 or position('milha' in lower(p_nome_evento)) > 0  then
            var_unidade := 'mi';
        else
            var_unidade := '--';
        end if;
    end if;

    var_arr_percursos := array_remove(string_to_array(regexp_replace(p_categorias, '[^0-9.,]','','g'),','),'');
    var_num_dias := (p_data_fim - p_data_ini) + 1;

    foreach prc in array var_arr_percursos loop
        if prc < 21 then
           var_data_percurso := p_data_ini;
        else
            if prc < 42 then
                if var_num_dias = 1 then
                   var_data_percurso := p_data_ini;
                 else
                   var_data_percurso := p_data_ini + 1;
                end if;
            else
                if var_num_dias = 1 then
                   var_data_percurso := p_data_ini;
                 else
                   var_data_percurso := p_data_fim;
                end if;
            end if;
        end if;

        insert into tb_evento_corridas_percursos
          ( percurso_evento, unidade_de_medida, id_evento, data_percurso )
        values
          ( prc, var_unidade, p_id_evento, var_data_percurso )
        on CONFLICT (percurso_evento, id_evento) DO UPDATE
        SET
            percurso_evento   = excluded.percurso_evento,
            unidade_de_medida = excluded.unidade_de_medida,
            id_evento         = excluded.id_evento,
            data_percurso     = excluded.data_percurso
            -- A edição manual bloqueada prevalece sobre a geração automática.
            WHERE NOT tb_evento_corridas_percursos.percurso_bloqueado;
    end loop;

END
$procedure$
;
