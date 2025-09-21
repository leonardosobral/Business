<!--- Section: Summary --->
<section class="mb-5">

  <div class="row gx-xl-5">
    <div class="col-lg-4 mb-4 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-thermometer-half fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">Temperature</p>
              <h2 class="mb-0">
                25
                <span class="" style="font-size: 0.875rem">
                  <span>°C</span></span>
              </h2>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-lg-4 mb-4 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-wind fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">Air quality</p>
              <h2 class="mb-0">
                97
                <span class="" style="font-size: 0.875rem">
                  <span>%</span></span>
              </h2>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-lg-4 mb-lg-0">
      <div class="card shadow-0">
        <div class="card-body">
          <div class="d-flex align-items-center">
            <div class="flex-shrink-0">
              <div class="p-3 badge-primary rounded-4">
                <i class="fas fa-tint fa-lg fa-fw"></i>
              </div>
            </div>
            <div class="flex-grow-1 ms-4">
              <p class="text-muted mb-1">Humidity</p>
              <h2 class="mb-0">
                60
                <span class="" style="font-size: 0.875rem">
                  <span>%</span></span>
              </h2>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
    
</section>

<!--- Section: MSC --->
<section class="">

  <div class="row gx-xl-5">

    <div class="col-lg-8 mb-4 mb-lg-0 h-100">

      <div class="card shadow-0">
        <div class="card-body">

          <!--- Pills navs --->
          <ul class="nav nav-tabs nav-fill mb-4" id="ex1" role="tablist">
            <li class="nav-item" role="presentation">
              <a class="nav-link active" id="ex1-tab-1" data-mdb-pill-init href="#ex1-pills-1" role="tab"
                 aria-controls="ex1-pills-1" aria-selected="true">Kitchen</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-2" data-mdb-pill-init href="#ex1-pills-2" role="tab"
                 aria-controls="ex1-pills-2" aria-selected="false">Bedroom</a>
            </li>
            <li class="nav-item" role="presentation">
              <a class="nav-link" id="ex1-tab-3" data-mdb-pill-init href="#ex1-pills-3" role="tab"
                 aria-controls="ex1-pills-3" aria-selected="false">Living room</a>
            </li>
          </ul>
          <!--- Pills navs --->

          <!--- Pills content --->
          <div class="tab-content" id="ex1-content">
            <div class="tab-pane fade show active" id="ex1-pills-1" role="tabpanel" aria-labelledby="ex1-tab-1">

              <div class="bg-image rounded-4">
                <img src="https://mdbootstrap.com/img/Photos/dashboard/home/kitchen.jpg" class="w-100"
                     alt="Louvre Museum" />
                <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                  <div class="d-flex justify-content-between align-items-start h-100 p-4">
                    <small class="text-white">
                      23.05.2022 18:45
                    </small>

                    <span class="badge badge-light">
                      <i class="fas fa-video me-1 text-danger"></i>
                      <span>Recording</span>
                    </span>
                  </div>
                </div>
              </div>

            </div>
            <div class="tab-pane fade" id="ex1-pills-2" role="tabpanel" aria-labelledby="ex1-tab-2">
              <div class="bg-image rounded-4">
                <img src="https://mdbootstrap.com/img/Photos/dashboard/home/bedroom.jpg" class="w-100"
                     alt="Louvre Museum" />
                <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                  <div class="d-flex justify-content-between align-items-start h-100 p-4">
                    <small class="text-white">
                      23.05.2022 18:45
                    </small>

                    <span class="badge badge-light">
                      <i class="fas fa-video me-1 text-danger"></i>
                      <span>Recording</span>
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div class="tab-pane fade" id="ex1-pills-3" role="tabpanel" aria-labelledby="ex1-tab-3">
              <div class="bg-image rounded-4">
                <img src="https://mdbootstrap.com/img/Photos/dashboard/home/living-room.jpg" class="w-100"
                     alt="Louvre Museum" />
                <div class="mask" style="background-color: rgba(0, 0, 0, 0.1)">
                  <div class="d-flex justify-content-between align-items-start h-100 p-4">
                    <small class="text-white">
                      23.05.2022 18:45
                    </small>

                    <span class="badge badge-light">
                      <i class="fas fa-video me-1 text-danger"></i>
                      <span>Recording</span>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!--- Pills content --->

        </div>
      </div>

    </div>

    <div class="col-lg-4 mb-4 mb-lg-0">

      <div class="card shadow-0 mb-5 h-100">

        <div class="card-header">
          <small>Energy consumption by room</small>
        </div>
        <div class="card-body h-100 d-flex align-items-center">

          <div id="chart-consumption-by-room" class="w-100"></div>

        </div>
      </div>

    </div>

  </div>

</section>

