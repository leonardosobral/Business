BEGIN;

CREATE TABLE IF NOT EXISTS public.tb_atleta_verificacao_solicitacao (
    id_solicitacao serial PRIMARY KEY,
    id_pagina integer NOT NULL REFERENCES public.tb_paginas(id_pagina) ON DELETE CASCADE,
    id_usuario_solicitante integer NOT NULL REFERENCES public.tb_usuarios(id),
    status varchar(16) NOT NULL DEFAULT 'pendente',
    origem varchar(16) NOT NULL DEFAULT 'usuario',
    justificativa text NOT NULL,
    observacao_admin text,
    data_solicitacao timestamp NOT NULL DEFAULT now(),
    data_decisao timestamp,
    id_usuario_decisao integer REFERENCES public.tb_usuarios(id),
    data_atualizacao timestamp NOT NULL DEFAULT now(),
    CONSTRAINT tb_atleta_verificacao_status_ck
        CHECK (status IN ('pendente', 'aprovado', 'rejeitado', 'revogado')),
    CONSTRAINT tb_atleta_verificacao_origem_ck
        CHECK (origem IN ('usuario', 'admin', 'legado')),
    CONSTRAINT tb_atleta_verificacao_justificativa_ck
        CHECK (length(trim(justificativa)) BETWEEN 5 AND 2000),
    CONSTRAINT tb_atleta_verificacao_observacao_ck
        CHECK (observacao_admin IS NULL OR length(trim(observacao_admin)) BETWEEN 5 AND 2000)
);

CREATE UNIQUE INDEX IF NOT EXISTS tb_atleta_verificacao_pendente_uq
    ON public.tb_atleta_verificacao_solicitacao (id_pagina)
    WHERE status = 'pendente';

CREATE INDEX IF NOT EXISTS tb_atleta_verificacao_fila_idx
    ON public.tb_atleta_verificacao_solicitacao (status, data_solicitacao DESC, id_solicitacao DESC);

CREATE INDEX IF NOT EXISTS tb_atleta_verificacao_pagina_idx
    ON public.tb_atleta_verificacao_solicitacao (id_pagina, data_solicitacao DESC, id_solicitacao DESC);

INSERT INTO public.tb_atleta_verificacao_solicitacao (
    id_pagina,
    id_usuario_solicitante,
    status,
    origem,
    justificativa,
    data_solicitacao,
    data_decisao,
    data_atualizacao
)
SELECT pag.id_pagina,
       pag.id_usuario_cadastro,
       'aprovado',
       'legado',
       'Selo ativo antes da implantação do fluxo de solicitações.',
       now(),
       now(),
       now()
FROM public.tb_paginas pag
WHERE pag.verificado = true
  AND NOT EXISTS (
      SELECT 1
      FROM public.tb_atleta_verificacao_solicitacao sol
      WHERE sol.id_pagina = pag.id_pagina
  );

GRANT SELECT, INSERT, UPDATE ON public.tb_atleta_verificacao_solicitacao TO runner;
GRANT SELECT, USAGE ON SEQUENCE public.tb_atleta_verificacao_solicitacao_id_solicitacao_seq TO runner;

COMMIT;
