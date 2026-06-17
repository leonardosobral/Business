<cfinclude template="../includes/media_backend.cfm"/>
<cfset VARIABLES.mediaHiddenColumns = "id_media,media_url,media_tipo,media_metatags,media_canal_slug,youtube_duration_iso,youtube_duration_seconds"/>
<cfset VARIABLES.mediaHasDurationSeconds = false/>
<cfset VARIABLES.mediaHasDurationIso = false/>
<cfloop query="qMediaColumns">
  <cfif qMediaColumns.column_name EQ "youtube_duration_seconds">
    <cfset VARIABLES.mediaHasDurationSeconds = true/>
  <cfelseif qMediaColumns.column_name EQ "youtube_duration_iso">
    <cfset VARIABLES.mediaHasDurationIso = true/>
  </cfif>
</cfloop>

<style>
  .media-table {
    min-width: 1200px;
  }

  .media-table td,
  .media-table th {
    vertical-align: middle;
  }

  .media-cell {
    max-width: 360px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .media-actions-cell {
    min-width: 220px;
  }

  .media-thumbnail-cell {
    width: 112px;
    min-width: 112px;
  }

  .media-thumbnail-button {
    width: 96px;
    height: 54px;
    border: 0;
    padding: 0;
    border-radius: 0.5rem;
    overflow: hidden;
    background: var(--mdb-secondary-bg);
  }

  .media-thumbnail-button img {
    width: 100%;
    height: 100%;
    display: block;
    object-fit: cover;
  }

  .media-video-frame {
    width: 100%;
    aspect-ratio: 16 / 9;
    min-height: 320px;
    border: 0;
    border-radius: 0.5rem;
    background: #000;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Videos</h3>
              <p class="text-muted mb-0">Gerencie os videos importados a partir dos canais de video e a exibicao no portal Road Runners.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de itens</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qMediaCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o controle de videos do Portal.
            </div>
          <cfelseif NOT qMediaColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Nao foi possivel localizar as colunas da tabela <strong>tb_media</strong>.
            </div>
          <cfelse>
            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover media-table">
                <thead>
                  <tr>
                    <th class="media-thumbnail-cell">Thumb</th>
                    <cfoutput query="qMediaColumns">
                      <cfif (qMediaColumns.column_name EQ "youtube_duration_iso" AND VARIABLES.mediaHasDurationIso)
                        OR (qMediaColumns.column_name EQ "youtube_duration_seconds" AND VARIABLES.mediaHasDurationSeconds AND NOT VARIABLES.mediaHasDurationIso)>
                        <th>Duração</th>
                      </cfif>
                      <cfif NOT ListFindNoCase(VARIABLES.mediaHiddenColumns, qMediaColumns.column_name)>
                        <cfswitch expression="#qMediaColumns.column_name#">
                          <cfcase value="media_titulo"><cfset VARIABLES.mediaColumnLabel = "Titulo"/></cfcase>
                          <cfcase value="data_publicação,data_publicacao"><cfset VARIABLES.mediaColumnLabel = "Publicacao"/></cfcase>
                          <cfcase value="pub_status"><cfset VARIABLES.mediaColumnLabel = "Status"/></cfcase>
                          <cfcase value="media_canal_nome"><cfset VARIABLES.mediaColumnLabel = "Canal"/></cfcase>
                          <cfdefaultcase><cfset VARIABLES.mediaColumnLabel = qMediaColumns.column_name/></cfdefaultcase>
                        </cfswitch>
                        <th>#htmlEditFormat(VARIABLES.mediaColumnLabel)#</th>
                      </cfif>
                    </cfoutput>
                    <th class="media-actions-cell">Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  <cfoutput query="qMedia">
                    <cfset VARIABLES.mediaPkValue = qMedia[VARIABLES.mediaPk][qMedia.currentRow]/>
                    <tr>
                      <td class="media-thumbnail-cell">
                        <cfif VARIABLES.mediaHasUrl AND len(trim(qMedia["media_url"][qMedia.currentRow]))>
                          <button type="button" class="media-thumbnail-button js-media-video js-media-thumbnail" data-media-url="#htmlEditFormat(qMedia["media_url"][qMedia.currentRow])#" data-media-title="Midia ###htmlEditFormat(VARIABLES.mediaPkValue)#" aria-label="Abrir video">
                            <img alt="Miniatura do video" loading="lazy"/>
                          </button>
                        <cfelse>
                          <span class="text-muted small">-</span>
                        </cfif>
                      </td>

                      <cfloop query="qMediaColumns">
                        <cfset VARIABLES.mediaColumnName = qMediaColumns.column_name/>
                        <cfset VARIABLES.mediaColumnValue = qMedia[VARIABLES.mediaColumnName][qMedia.currentRow]/>
                        <cfif (VARIABLES.mediaColumnName EQ "youtube_duration_iso" AND VARIABLES.mediaHasDurationIso)
                          OR (VARIABLES.mediaColumnName EQ "youtube_duration_seconds" AND VARIABLES.mediaHasDurationSeconds AND NOT VARIABLES.mediaHasDurationIso)>
                          <cfset VARIABLES.mediaDurationSeconds = 0/>
                          <cfset VARIABLES.mediaDurationFormatted = "-"/>
                          <cfif VARIABLES.mediaHasDurationSeconds AND NOT isNull(qMedia["youtube_duration_seconds"][qMedia.currentRow]) AND isNumeric(qMedia["youtube_duration_seconds"][qMedia.currentRow])>
                            <cfset VARIABLES.mediaDurationSeconds = val(qMedia["youtube_duration_seconds"][qMedia.currentRow])/>
                          <cfelseif VARIABLES.mediaHasDurationIso AND NOT isNull(qMedia["youtube_duration_iso"][qMedia.currentRow]) AND len(trim(qMedia["youtube_duration_iso"][qMedia.currentRow]))>
                            <cfset VARIABLES.mediaDurationIso = qMedia["youtube_duration_iso"][qMedia.currentRow]/>
                            <cfset VARIABLES.mediaDurationHoursMatch = reFindNoCase("([0-9]+)H", VARIABLES.mediaDurationIso, 1, true)/>
                            <cfset VARIABLES.mediaDurationMinutesMatch = reFindNoCase("([0-9]+)M", VARIABLES.mediaDurationIso, 1, true)/>
                            <cfset VARIABLES.mediaDurationSecondsMatch = reFindNoCase("([0-9]+)S", VARIABLES.mediaDurationIso, 1, true)/>
                            <cfif arrayLen(VARIABLES.mediaDurationHoursMatch.pos) GTE 2 AND VARIABLES.mediaDurationHoursMatch.pos[2] GT 0>
                              <cfset VARIABLES.mediaDurationSeconds = VARIABLES.mediaDurationSeconds + (val(mid(VARIABLES.mediaDurationIso, VARIABLES.mediaDurationHoursMatch.pos[2], VARIABLES.mediaDurationHoursMatch.len[2])) * 3600)/>
                            </cfif>
                            <cfif arrayLen(VARIABLES.mediaDurationMinutesMatch.pos) GTE 2 AND VARIABLES.mediaDurationMinutesMatch.pos[2] GT 0>
                              <cfset VARIABLES.mediaDurationSeconds = VARIABLES.mediaDurationSeconds + (val(mid(VARIABLES.mediaDurationIso, VARIABLES.mediaDurationMinutesMatch.pos[2], VARIABLES.mediaDurationMinutesMatch.len[2])) * 60)/>
                            </cfif>
                            <cfif arrayLen(VARIABLES.mediaDurationSecondsMatch.pos) GTE 2 AND VARIABLES.mediaDurationSecondsMatch.pos[2] GT 0>
                              <cfset VARIABLES.mediaDurationSeconds = VARIABLES.mediaDurationSeconds + val(mid(VARIABLES.mediaDurationIso, VARIABLES.mediaDurationSecondsMatch.pos[2], VARIABLES.mediaDurationSecondsMatch.len[2]))/>
                            </cfif>
                          </cfif>
                          <cfif VARIABLES.mediaDurationSeconds GT 0>
                            <cfset VARIABLES.mediaDurationHours = int(VARIABLES.mediaDurationSeconds / 3600)/>
                            <cfset VARIABLES.mediaDurationMinutes = int((VARIABLES.mediaDurationSeconds MOD 3600) / 60)/>
                            <cfset VARIABLES.mediaDurationRemainderSeconds = VARIABLES.mediaDurationSeconds MOD 60/>
                            <cfset VARIABLES.mediaDurationFormatted = numberFormat(VARIABLES.mediaDurationHours, "00") & ":" & numberFormat(VARIABLES.mediaDurationMinutes, "00") & ":" & numberFormat(VARIABLES.mediaDurationRemainderSeconds, "00")/>
                          </cfif>
                          <td class="media-cell">
                            <span class="<cfif VARIABLES.mediaDurationSeconds GT 0 AND VARIABLES.mediaDurationSeconds LTE 180>text-danger fw-bold</cfif>">#htmlEditFormat(VARIABLES.mediaDurationFormatted)#</span>
                          </td>
                        </cfif>
                        <cfif NOT ListFindNoCase(VARIABLES.mediaHiddenColumns, VARIABLES.mediaColumnName)>
                          <td class="media-cell">
                            <cfif VARIABLES.mediaColumnName EQ "pub_status">
                              <cfset VARIABLES.mediaCellPublished = IsBoolean(VARIABLES.mediaColumnValue) ? VARIABLES.mediaColumnValue : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.mediaColumnValue))/>
                              <span class="badge <cfif VARIABLES.mediaCellPublished>badge-success<cfelse>badge-danger</cfif>">
                                <cfif VARIABLES.mediaCellPublished>Publicado<cfelse>Oculto</cfif>
                              </span>
                            <cfelseif ListFindNoCase("data_publicação,data_publicacao", VARIABLES.mediaColumnName) AND NOT isNull(VARIABLES.mediaColumnValue) AND isDate(VARIABLES.mediaColumnValue)>
                              #lsDateFormat(VARIABLES.mediaColumnValue, "dd/mm/yyyy")#
                              <small class="text-muted d-block">#lsTimeFormat(VARIABLES.mediaColumnValue, "HH:mm")#</small>
                            <cfelse>
                              #htmlEditFormat(VARIABLES.mediaColumnValue)#
                            </cfif>
                          </td>
                        </cfif>
                      </cfloop>

                      <td class="media-actions-cell">
                        <div class="d-flex flex-wrap gap-2">
                          <cfif VARIABLES.mediaHasPubStatus>
                            <cfset VARIABLES.mediaCurrentPubStatus = qMedia["pub_status"][qMedia.currentRow]/>
                            <cfset VARIABLES.mediaIsPublished = IsBoolean(VARIABLES.mediaCurrentPubStatus) ? VARIABLES.mediaCurrentPubStatus : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.mediaCurrentPubStatus))/>
                            <a class="btn btn-sm <cfif VARIABLES.mediaIsPublished>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=pub_status&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&status=#NOT VARIABLES.mediaIsPublished#&pagina=#VARIABLES.mediaPage#">
                              <cfif VARIABLES.mediaIsPublished>Ocultar<cfelse>Exibir</cfif>
                            </a>
                          </cfif>

                          <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&pagina=#VARIABLES.mediaPage#" onclick="return confirm('Tem certeza que deseja remover este video do banco de dados?');">
                            Remover
                          </a>
                        </div>
                      </td>
                    </tr>
                  </cfoutput>
                </tbody>
              </table>
            </div>

            <cfif VARIABLES.mediaTotalPages GT 1>
              <nav aria-label="Paginacao de videos">
                <ul class="pagination pagination-sm justify-content-center flex-wrap mt-3 mb-0">
                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.mediaPage LTE 1>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#max(1, VARIABLES.mediaPage - 1)#">Anterior</a>
                    </li>
                  </cfoutput>

                  <cfloop from="#max(1, VARIABLES.mediaPage - 3)#" to="#min(VARIABLES.mediaTotalPages, VARIABLES.mediaPage + 3)#" index="mediaPageIndex">
                    <cfoutput>
                      <li class="page-item <cfif mediaPageIndex EQ VARIABLES.mediaPage>active</cfif>">
                        <a class="page-link" href="./?pagina=#mediaPageIndex#">#mediaPageIndex#</a>
                      </li>
                    </cfoutput>
                  </cfloop>

                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.mediaPage GTE VARIABLES.mediaTotalPages>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#min(VARIABLES.mediaTotalPages, VARIABLES.mediaPage + 1)#">Proxima</a>
                    </li>
                  </cfoutput>
                </ul>
              </nav>
            </cfif>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>

<div class="modal fade" id="mediaVideoModal" tabindex="-1" aria-labelledby="mediaVideoModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="mediaVideoModalLabel">Video</h5>
        <button type="button" class="btn-close" data-mdb-dismiss="modal" aria-label="Fechar"></button>
      </div>
      <div class="modal-body">
        <iframe id="mediaVideoIframe" class="media-video-frame" src="" title="YouTube video player" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
        <div id="mediaVideoFallback" class="alert alert-warning mt-3 d-none">
          Nao foi possivel identificar o video do YouTube a partir da URL informada.
        </div>
      </div>
    </div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    var modalElement = document.getElementById('mediaVideoModal');
    var iframe = document.getElementById('mediaVideoIframe');
    var title = document.getElementById('mediaVideoModalLabel');
    var fallback = document.getElementById('mediaVideoFallback');
    var modal = modalElement && window.mdb ? new mdb.Modal(modalElement) : null;

    function getYouTubeId(value) {
      var source = String(value || '').trim();
      var match;

      if (!source) return '';
      if (/^[A-Za-z0-9_-]{11}$/.test(source)) return source;

      match = source.match(/(?:youtube\.com\/watch\?v=|youtube\.com\/embed\/|youtube\.com\/shorts\/|youtu\.be\/)([A-Za-z0-9_-]{11})/);
      if (match && match[1]) return match[1];

      match = source.match(/[?&]v=([A-Za-z0-9_-]{11})/);
      return match && match[1] ? match[1] : '';
    }

    document.querySelectorAll('.js-media-video').forEach(function (button) {
      button.addEventListener('click', function () {
        var videoId = getYouTubeId(button.getAttribute('data-media-url'));
        var modalTitle = button.getAttribute('data-media-title') || 'Video';

        title.textContent = modalTitle;
        fallback.classList.toggle('d-none', !!videoId);
        iframe.classList.toggle('d-none', !videoId);
        iframe.src = videoId ? 'https://www.youtube.com/embed/' + videoId + '?autoplay=1' : '';

        if (modal) modal.show();
      });
    });

    document.querySelectorAll('.js-media-thumbnail').forEach(function (button) {
      var videoId = getYouTubeId(button.getAttribute('data-media-url'));
      var image = button.querySelector('img');

      if (videoId && image) {
        image.src = 'https://img.youtube.com/vi/' + videoId + '/mqdefault.jpg';
      } else {
        button.classList.add('d-none');
      }
    });

    if (modalElement) {
      modalElement.addEventListener('hidden.mdb.modal', function () {
        iframe.src = '';
      });
    }
  });
</script>
