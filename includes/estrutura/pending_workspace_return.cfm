<cfif isDefined("VARIABLES.businessPendingWorkspace")
    AND VARIABLES.businessPendingWorkspace
    AND isDefined("VARIABLES.template")
    AND VARIABLES.template NEQ "/">
    <style>
        .pending-workspace-return {
            align-items: center;
            background: rgba(244, 177, 32, .08);
            border: 1px solid rgba(244, 177, 32, .35);
            border-radius: .55rem;
            display: flex;
            gap: 1rem;
            justify-content: space-between;
            margin-bottom: 1.5rem;
            padding: .85rem 1rem;
        }

        .pending-workspace-return-copy {
            min-width: 0;
        }

        .pending-workspace-return-eyebrow {
            color: #f4b120;
            display: block;
            font-size: .72rem;
            font-weight: 800;
            letter-spacing: .05em;
            text-transform: uppercase;
        }

        .pending-workspace-return-title {
            color: rgba(255, 255, 255, .9);
            display: block;
            font-weight: 700;
            margin-top: .1rem;
        }

        @media (max-width: 575.98px) {
            .pending-workspace-return {
                align-items: stretch;
                flex-direction: column;
            }

            .pending-workspace-return .btn {
                width: 100%;
            }
        }
    </style>

    <nav class="pending-workspace-return" aria-label="Navegação dos primeiros passos">
        <span class="pending-workspace-return-copy">
            <span class="pending-workspace-return-eyebrow">Conta em análise</span>
            <span class="pending-workspace-return-title">Continue acompanhando seus quatro primeiros passos.</span>
        </span>
        <a class="btn btn-warning flex-shrink-0" href="/">
            <i class="fa-solid fa-arrow-left me-2" aria-hidden="true"></i>
            Voltar aos primeiros passos
        </a>
    </nav>
</cfif>
