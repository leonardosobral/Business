<cfprocessingdirective pageencoding="utf-8"/>
<cfoutput>
<div class="d-flex flex-wrap justify-content-between align-items-start gap-3 mb-4">
    <div><h1 class="h3 mb-1">Meu ponto</h1><p class="text-muted mb-0">Suas horas de trabalho, semana após semana.</p></div>
    <span class="badge badge-secondary">Horário de Brasília</span>
</div>
<cfif len(pontoNotice)><div class="alert alert-success" role="status">#encodeForHTML(pontoNotice)#</div></cfif>
<cfif len(pontoError)><div class="alert alert-danger" role="alert">#encodeForHTML(pontoError)#</div></cfif>
<cfif NOT pontoReady>
    <div class="alert alert-info">O controle de horas está aguardando ativação. Seus registros aparecerão aqui quando estiver disponível.</div>
<cfelse>
    <section class="card mb-4" aria-label="Marcação de ponto">
        <div class="card-body p-4">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-4">
                <div>
                    <cfif qPontoActive.recordcount>
                        <p class="mb-1 fw-semibold"><cfif qPontoActive.estado EQ 'ativo'><span class="text-success">● Trabalhando</span><cfelse><span class="text-warning">● Em pausa</span></cfif></p>
                        <div class="display-6 fw-bold" data-ponto-timer data-seconds="#fix(qPontoActive.segundos)#" data-running="#qPontoActive.estado EQ 'ativo' ? 'true' : 'false'#">#pontoHoras(qPontoActive.segundos)#</div>
                        <p class="text-muted small mb-0">Início em #qPontoActive.inicio#. Pausas não entram no total.</p>
                    <cfelse>
                        <p class="mb-1 fw-semibold">Pronto para começar?</p>
                        <p class="text-muted mb-0">Inicie o ponto quando começar a trabalhar.</p>
                    </cfif>
                </div>
                <div class="d-flex flex-wrap gap-2">
                    <form method="post" action="#encodeForHTMLAttribute(pontoReturn)#" class="d-flex flex-wrap gap-2" data-ponto-submit>
                        <input type="hidden" name="csrf" value="#encodeForHTMLAttribute(pontoCsrf)#">
                        <cfif qPontoActive.recordcount>
                            <input type="hidden" name="id" value="#qPontoActive.id#"><input type="hidden" name="versao" value="#qPontoActive.versao#">
                            <cfif qPontoActive.estado EQ 'ativo'>
                                <button class="btn btn-warning" name="acao" value="pausar"><i class="fas fa-pause me-2" aria-hidden="true"></i>Pausar</button>
                            <cfelse>
                                <button class="btn btn-success" name="acao" value="retomar"><i class="fas fa-play me-2" aria-hidden="true"></i>Retomar</button>
                            </cfif>
                            <button class="btn btn-primary" name="acao" value="finalizar"><i class="fas fa-stop me-2" aria-hidden="true"></i>Finalizar agora</button>
                        <cfelse>
                            <button class="btn btn-success" name="acao" value="iniciar"><i class="fas fa-play me-2" aria-hidden="true"></i>Iniciar trabalho</button>
                        </cfif>
                    </form>
                    <cfif qPontoActive.recordcount><a class="btn btn-outline-secondary" href="#encodeForHTMLAttribute(pontoReturn & '&editar=' & qPontoActive.id)###ponto-editor">Corrigir horários</a></cfif>
                </div>
            </div>
            <cfif qPontoActive.recordcount>
                <p class="small text-muted mt-3 mb-0">Esqueceu de pausar ou finalizar? Use “Corrigir horários” para informar os períodos em que trabalhou. A jornada aberta ainda não entra nos totais consolidados.</p>
                <cfif qPontoActive.idade GT 57600><div class="alert alert-warning mt-3 mb-0">Este ponto está aberto há mais de 16 horas. Confira os horários antes de finalizar.</div></cfif>
            </cfif>
        </div>
    </section>
    <div class="row g-3 mb-4">
        <div class="col-md-4"><div class="card h-100"><div class="card-body"><p class="text-muted mb-1">Esta semana</p><div class="h3 mb-0">#pontoHoras(qPontoTotals.semana)#</div><small class="text-muted">De segunda-feira até hoje</small></div></div></div>
        <div class="col-md-4"><div class="card h-100"><div class="card-body"><p class="text-muted mb-1">Este mês</p><div class="h3 mb-0">#pontoHoras(qPontoTotals.mes)#</div><small class="text-muted">Horas consolidadas até hoje</small></div></div></div>
        <div class="col-md-4"><div class="card h-100"><div class="card-body"><p class="text-muted mb-1">Período selecionado</p><div class="h3 mb-0">#pontoHoras(qPontoTotals.periodo)#</div><small class="text-muted">Inclui #pontoHoras(qPontoTotals.viagens)# de viagens</small></div></div></div>
    </div>

    <div class="row g-4 mb-4">
        <div class="col-lg-7">
            <section class="card h-100" id="ponto-editor">
                <div class="card-body">
                    <h2 class="h5"><cfif qPontoEdit.recordcount>Consultar / corrigir registro<cfelse>Adicionar horas esquecidas</cfif></h2>
                    <cfif pontoEditId GT 0 AND NOT qPontoEdit.recordcount>
                        <p class="text-danger">Registro não encontrado.</p>
                    <cfelseif qPontoEdit.recordcount AND (qPontoEdit.tipo EQ 'viagem' OR qPontoEdit.estado EQ 'cancelado')>
                        <cfif qPontoEdit.tipo EQ 'viagem'><p>Viagem em #qPontoEdit.dia_viagem# · #pontoHoras(qPontoEdit.minutos_viagem*60)#.</p></cfif>
                        <cfif qPontoEdit.estado EQ 'cancelado'><p class="text-muted">Registro cancelado, preservado no histórico.</p><cfelse><p class="text-muted">Para mudar a data ou as horas, cancele este dia e registre novamente no formulário de viagem.</p></cfif>
                    <cfelse>
                        <p class="small text-muted">Informe cada período trabalhado. Para descontar uma pausa, separe o antes e o depois em duas linhas. Salvar encerra este registro.</p>
                        <form method="post" action="#encodeForHTMLAttribute(pontoReturn & (pontoEditId GT 0 ? '&editar=' & pontoEditId : ''))#" data-ponto-editor data-ponto-submit>
                            <input type="hidden" name="csrf" value="#encodeForHTMLAttribute(pontoCsrf)#">
                            <input type="hidden" name="acao" value="salvar">
                            <input type="hidden" name="id" value="#qPontoEdit.recordcount ? qPontoEdit.id : 0#">
                            <input type="hidden" name="versao" value="#encodeForHTMLAttribute(len(pontoError) AND pontoForm('acao') EQ 'salvar' ? pontoForm('versao', '0') : (qPontoEdit.recordcount ? qPontoEdit.versao : 0))#">
                            <input type="hidden" name="quantidade" value="#max(1,qPontoPeriods.recordcount)#" data-ponto-count>
                            <div data-ponto-periods>
                                <cfloop from="1" to="#max(1,qPontoPeriods.recordcount)#" index="pontoRow">
                                    <div class="row g-2 align-items-end mb-3" data-ponto-period>
                                        <div class="col-sm-5"><label class="form-label w-100">Início<input class="form-control" aria-label="Início do período #pontoRow#" type="datetime-local" step="1" name="inicio_#pontoRow#" value="#encodeForHTMLAttribute(qPontoPeriods.recordcount ? qPontoPeriods.inicio[pontoRow] : '')#" required></label></div>
                                        <div class="col-sm-5"><label class="form-label w-100">Fim<input class="form-control" aria-label="Fim do período #pontoRow#" type="datetime-local" step="1" name="fim_#pontoRow#" value="#encodeForHTMLAttribute(qPontoPeriods.recordcount ? qPontoPeriods.fim[pontoRow] : '')#" required></label></div>
                                        <div class="col-sm-2 pb-2"><button type="button" class="btn btn-sm btn-outline-danger" data-ponto-remove aria-label="Remover período">Remover</button></div>
                                    </div>
                                </cfloop>
                            </div>
                            <div class="d-flex flex-wrap gap-2"><button type="button" class="btn btn-outline-secondary" data-ponto-add>Adicionar período</button><button class="btn btn-primary">Salvar horários</button></div>
                        </form>
                    </cfif>
                    <cfif qPontoEdit.recordcount>
                        <div class="d-flex flex-wrap gap-2 mt-3">
                            <a class="btn btn-sm btn-outline-secondary" href="#encodeForHTMLAttribute(pontoReturn)#">Novo registro</a>
                            <cfif qPontoEdit.estado NEQ 'cancelado'>
                                <form method="post" action="#encodeForHTMLAttribute(pontoReturn)#" data-ponto-submit data-ponto-confirm="Cancelar este registro? Ele deixará de contar nas horas, mas continuará no histórico.">
                                    <input type="hidden" name="csrf" value="#encodeForHTMLAttribute(pontoCsrf)#"><input type="hidden" name="id" value="#qPontoEdit.id#"><input type="hidden" name="versao" value="#qPontoEdit.versao#">
                                    <button class="btn btn-sm btn-outline-danger" name="acao" value="cancelar">Cancelar registro</button>
                                </form>
                            </cfif>
                        </div>
                        <cfinclude template="includes/auditoria.cfm"/>
                    </cfif>
                </div>
            </section>
        </div>
        <div class="col-lg-5">
            <section class="card h-100"><div class="card-body">
                <h2 class="h5">Viagem a trabalho</h2>
                <p class="small text-muted">Registre os dias dedicados ao trabalho. Dias futuros ficam programados e entram no total quando a data chegar. Se a viagem mudar, cancele os dias correspondentes.</p>
                <form method="post" action="#encodeForHTMLAttribute(pontoReturn)#" data-ponto-submit data-ponto-trip>
                    <input type="hidden" name="csrf" value="#encodeForHTMLAttribute(pontoCsrf)#"><input type="hidden" name="acao" value="viagem">
                    <div class="row g-3 mb-3">
                        <div class="col-sm-6"><label class="form-label w-100">Primeiro dia<input class="form-control" type="date" name="viagem_de" value="#encodeForHTMLAttribute(pontoForm('viagem_de', qPontoClock.hoje))#" required></label></div>
                        <div class="col-sm-6"><label class="form-label w-100">Último dia<input class="form-control" type="date" name="viagem_ate" value="#encodeForHTMLAttribute(pontoForm('viagem_ate', qPontoClock.hoje))#" required></label></div>
                    </div>
                    <label class="form-label w-100">Horas por dia<input class="form-control" type="number" name="horas" value="#encodeForHTMLAttribute(pontoForm('horas', '8'))#" min="0.25" max="24" step="0.25" required></label>
                    <div class="form-check my-3"><input class="form-check-input" type="checkbox" name="fins_semana" value="1" id="ponto-weekend"<cfif structKeyExists(FORM,'fins_semana')> checked</cfif>><label class="form-check-label" for="ponto-weekend">Incluir sábados e domingos</label></div>
                    <p class="small text-muted">Feriados não são descontados automaticamente. Confira os dias antes de registrar.</p>
                    <p class="fw-semibold" data-ponto-trip-preview aria-live="polite"></p>
                    <button class="btn btn-primary">Registrar viagem</button>
                </form>
            </div></section>
        </div>
    </div>

    <section class="card mb-4"><div class="card-body">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3"><h2 class="h5 mb-0">Histórico de horas</h2>
            <div class="d-flex gap-2"><a class="btn btn-sm btn-outline-secondary" href="?de=#qPontoClock.semana_de#&ate=#qPontoClock.semana_ate#">Esta semana</a><a class="btn btn-sm btn-outline-secondary" href="?de=#qPontoClock.mes_de#&ate=#qPontoClock.mes_ate#">Este mês</a></div>
        </div>
        <form method="get" class="row g-2 align-items-end mb-4">
            <div class="col-sm-4"><label class="form-label w-100">De<input class="form-control" type="date" name="de" value="#pontoDe#" required></label></div>
            <div class="col-sm-4"><label class="form-label w-100">Até<input class="form-control" type="date" name="ate" value="#pontoAte#" required></label></div>
            <div class="col-sm-4 pb-2"><button class="btn btn-primary">Consultar período</button></div>
        </form>
        <cfif NOT qPontoDays.recordcount><p class="text-muted">Nenhuma hora consolidada neste período.</p><cfelse>
            <details class="mb-4" open><summary class="fw-semibold mb-3">Totais por dia</summary>
                <div class="table-responsive position-relative"><table class="table table-sm align-middle"><thead><tr><th scope="col">Dia</th><th scope="col">Horas</th><th scope="col">Origem</th></tr></thead><tbody>
                    <cfloop query="qPontoDays"><tr><td>#dia_label#</td><td>#pontoHoras(segundos)# <cfif programado><span class="badge badge-info">Programado</span></cfif></td><td><cfif viagem GT 0>Viagem<cfelse>Ponto</cfif></td></tr></cfloop>
                </tbody></table></div>
            </details>
        </cfif>
        <h3 class="h6">Registros e correções</h3>
        <cfif NOT qPontoHistory.recordcount><p class="text-muted mb-0">Nenhum registro neste período. Você pode adicionar horas anteriores no formulário acima.</p><cfelse>
            <div class="table-responsive position-relative"><table class="table align-middle"><thead><tr><th scope="col">Data / início</th><th scope="col">Tipo</th><th scope="col">Horas</th><th scope="col">Situação</th><th scope="col"><span class="visually-hidden">Ações</span></th></tr></thead><tbody>
                <cfloop query="qPontoHistory"><tr>
                    <td><cfif tipo EQ 'viagem'>#viagem_dia#<cfelse>#inicio#</cfif></td>
                    <td><cfif tipo EQ 'viagem'>Viagem<cfelse>Ponto</cfif><cfif ajustado><div class="small text-muted">Informado / ajustado</div></cfif></td>
                    <td><cfif estado EQ 'cancelado'>—<cfelse>#pontoHoras(segundos)#</cfif></td>
                    <td><cfif estado EQ 'cancelado'><span class="badge badge-secondary">Cancelado</span><cfelseif estado EQ 'ativo'><span class="badge badge-success">Aberto</span><cfelseif estado EQ 'pausado'><span class="badge badge-warning">Pausado</span><cfelseif tipo EQ 'viagem' AND programado><span class="badge badge-info">Programado</span><cfelse>Finalizado</cfif></td>
                    <td><a class="btn btn-sm btn-outline-secondary" href="#encodeForHTMLAttribute(pontoReturn & '&editar=' & id)###ponto-editor">Consultar / editar</a></td>
                </tr></cfloop>
            </tbody></table></div>
            <div class="d-flex flex-wrap gap-3 align-items-center justify-content-between">
                <small class="text-muted">Página #pontoPage# de #pontoPages# · #qPontoCount.total# registros. Jornadas que atravessam a meia-noite são divididas nos totais por dia.</small>
                <div class="d-flex gap-2"><cfif pontoPage GT 1><a class="btn btn-sm btn-outline-secondary" href="?de=#pontoDe#&ate=#pontoAte#&pagina=#pontoPage-1#">Anterior</a></cfif><cfif pontoPage LT pontoPages><a class="btn btn-sm btn-outline-secondary" href="?de=#pontoDe#&ate=#pontoAte#&pagina=#pontoPage+1#">Próxima</a></cfif></div>
            </div>
        </cfif>
    </div></section>
</cfif>
</cfoutput>
