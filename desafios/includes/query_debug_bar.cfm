<cfif isDefined("VARIABLES.desafiosQueryDebugEnabled")
    AND VARIABLES.desafiosQueryDebugEnabled
    AND structKeyExists(REQUEST, "desafiosQueryDebug")
    AND arrayLen(REQUEST.desafiosQueryDebug)>
    <cfset qDesafiosQueryDebug = queryNew("label,type,ms,rows", "varchar,varchar,integer,integer")/>
    <cfset VARIABLES.desafiosQueryTotalMs = 0/>

    <cfloop array="#REQUEST.desafiosQueryDebug#" index="queryDebugItem">
        <cfset queryAddRow(qDesafiosQueryDebug, 1)/>
        <cfset VARIABLES.desafiosQueryDebugRow = qDesafiosQueryDebug.recordcount/>
        <cfset querySetCell(qDesafiosQueryDebug, "label", queryDebugItem.label, VARIABLES.desafiosQueryDebugRow)/>
        <cfset querySetCell(qDesafiosQueryDebug, "type", queryDebugItem.type, VARIABLES.desafiosQueryDebugRow)/>
        <cfset querySetCell(qDesafiosQueryDebug, "ms", queryDebugItem.ms, VARIABLES.desafiosQueryDebugRow)/>
        <cfset querySetCell(qDesafiosQueryDebug, "rows", queryDebugItem.rows, VARIABLES.desafiosQueryDebugRow)/>
        <cfset VARIABLES.desafiosQueryTotalMs = VARIABLES.desafiosQueryTotalMs + queryDebugItem.ms/>
    </cfloop>

    <cfquery name="qDesafiosQueryDebugSorted" dbtype="query">
        SELECT *
        FROM qDesafiosQueryDebug
        ORDER BY ms DESC
    </cfquery>

    <style>
        .desafios-query-debug {
            position: fixed;
            left: 16px;
            right: 16px;
            bottom: 12px;
            z-index: 3000;
            border: 1px solid rgba(255,255,255,.18);
            border-radius: 8px;
            background: rgba(12, 15, 22, .96);
            color: #f4f6f8;
            box-shadow: 0 8px 30px rgba(0,0,0,.35);
            font-size: 12px;
        }

        .desafios-query-debug summary {
            cursor: pointer;
            display: flex;
            gap: 12px;
            align-items: center;
            justify-content: space-between;
            padding: 10px 12px;
            list-style: none;
        }

        .desafios-query-debug summary::-webkit-details-marker {
            display: none;
        }

        .desafios-query-debug .debug-grid {
            display: grid;
            grid-template-columns: minmax(180px, 1fr) 72px 72px 64px;
            gap: 8px;
            max-height: 220px;
            overflow: auto;
            padding: 0 12px 12px;
        }

        .desafios-query-debug .debug-row {
            display: contents;
        }

        .desafios-query-debug .debug-cell {
            border-top: 1px solid rgba(255,255,255,.08);
            padding: 6px 0;
            overflow-wrap: anywhere;
        }

        .desafios-query-debug .debug-head {
            color: rgba(244,246,248,.66);
            font-weight: 700;
            text-transform: uppercase;
        }

        .desafios-query-debug .debug-ms {
            color: #ffc107;
            font-weight: 700;
            text-align: right;
        }

        .desafios-query-debug .debug-type,
        .desafios-query-debug .debug-rows {
            text-align: right;
        }

        @media (max-width: 767.98px) {
            .desafios-query-debug .debug-grid {
                grid-template-columns: minmax(140px, 1fr) 64px 56px;
            }

            .desafios-query-debug .debug-type {
                display: none;
            }
        }
    </style>

    <details class="desafios-query-debug" open>
        <summary>
            <span>
                Query debug / desafios:
                <strong><cfoutput>#qDesafiosQueryDebugSorted.recordcount#</cfoutput></strong>
                consultas,
                total medido
                <strong><cfoutput>#numberFormat(VARIABLES.desafiosQueryTotalMs, "9,999")# ms</cfoutput></strong>
            </span>
            <span>
                Mais lenta:
                <strong><cfoutput>#htmlEditFormat(qDesafiosQueryDebugSorted.label)# (#numberFormat(qDesafiosQueryDebugSorted.ms, "9,999")# ms)</cfoutput></strong>
            </span>
        </summary>

        <div class="debug-grid">
            <div class="debug-cell debug-head">Query</div>
            <div class="debug-cell debug-head debug-type">Tipo</div>
            <div class="debug-cell debug-head debug-ms">Tempo</div>
            <div class="debug-cell debug-head debug-rows">Rows</div>

            <cfoutput query="qDesafiosQueryDebugSorted" maxrows="20">
                <div class="debug-row">
                    <div class="debug-cell">#htmlEditFormat(qDesafiosQueryDebugSorted.label)#</div>
                    <div class="debug-cell debug-type">#htmlEditFormat(qDesafiosQueryDebugSorted.type)#</div>
                    <div class="debug-cell debug-ms">#numberFormat(qDesafiosQueryDebugSorted.ms, "9,999")# ms</div>
                    <div class="debug-cell debug-rows"><cfif qDesafiosQueryDebugSorted.rows GTE 0>#numberFormat(qDesafiosQueryDebugSorted.rows, "9,999")#<cfelse>-</cfif></div>
                </div>
            </cfoutput>
        </div>
    </details>
</cfif>
