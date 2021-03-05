load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area, the forcing and directories vary between
; LASSO simulations
  gtype = "pdf"
  sims  = "SID8"
  phys  = "GFS_v16beta" ; "GFS_v16beta","GSD_v1","csawmg","GFS_v15p2",
;-------> "GFS_v16beta_MYNN","v16beta_MYNNrad","v16beta_Thomp","satmedmf"
  sn    = "8"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  ctrl = "MSDA+UFSsflx"
  t1   = phys
  t2   = phys+"_MYNN"

  file_all = "output.nc"

  dirlas  = "/glade/work/damico/LASSO_"+date+"_rawmodel/raw_model/"
;  dirstop = "/glade/u/home/damico/SCMv4_1/gmtb-scm/scm/bin/"
;  dirstop = "/glade/u/home/damico/SCMv4/gmtb-scm/scm/bin/"
  dirstop = "/glade/u/home/damico/SCMv4p1_update/gmtb-scm/scm/bin/"

  dirc  = "output_LASSO_"+date+"_"+ctrl+"_SCM_"+t1+"/"
  dirt1 = "output_LASSO_"+date+"_"+sims+"_SCM_"+t1+"/"
  dirt2 = "output_LASSO_"+date+"_"+sims+"_SCM_"+t2+"/"
; End user modification area

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4.*atan(1.)

  print("Started: "+systemfunc("date"))

; Add LASSO files
  flas = addfile(dirlas+"LASSO_20190714_SUBSET.nc","r")

; Time for LASSO
  hwrf = flas->Time_hr
  twrf = flas->Time_s

; Add SCM files
  fctl = addfile(dirstop+dirc+file_all,"r")
  ft1  = addfile(dirstop+dirt1+file_all,"r")
  ft2  = addfile(dirstop+dirt2+file_all,"r")

; SCM time
  tscm = ft1->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hrs since "+udate

; Variables from LASSO
  thtlas_K   = flas->T      ; potential temperature
  qvlas_kgkg = flas->QVAPOR ; water vapor mixing ratio
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height

; Calculate air temperature for LASSO from potential temperature
  tmplas_K             = thtlas_K
  tmplas_K             = thtlas_K / ((P00 / preslas_Pa)^(R_dry / c_p))
  tmplas_K@description = "AIR TEMPERATURE"

; Calculating LASSO saturation vapor pressure and saturation specific
; humidity
  svplas_hPa = 6.11 * (10^((7.5*(tmplas_K - 273.15)) / (273.3 + \
                          (tmplas_K - 273.15))))
  svplas_Pa  = svplas_hPa * 100.

  qvsatlas_kgkg = 0.622 * (svplas_Pa / preslas_Pa)

; Calculating LASSO relative humidity
  rhlas = (qvlas_kgkg / qvsatlas_kgkg) * 100.

  rhlas@description = "Relative Humidity"
  rhlas@units       = "%"
  rhlas!0           = "Time"
  rhlas!1           = "bottom_top"

; LASSO potential temperature with consideration for saturation (needed for
; virtual potential temperature calculation).
  thtlas_Ksat = new((/ dimsizes(thtlas_K) /),float)
  do i=0,dimsizes(twrf)-1,1
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (rhlas(i,j) .lt. 98.9) then
        thtlas_Ksat(i,j) = thtlas_K(i,j)
      else
        thtlas_Ksat(i,j) = thtlas_K(i,j)
        thtlas_Ksat(i,j) = tmplas_K(i,j) * ((P00 / preslas_Pa(i,j))^ \
                                            (R_dry *(1 - (0.23 * \
                                             qvlas_kgkg(i,j))) / c_p))
      end if
    end do
  end do

; LASSO virtual potential temperature
  thtvlas_K = thtlas_Ksat
  thtvlas_K = thtlas_Ksat * (1 + (0.61 * qvlas_kgkg))

  thtvlas_K@description = "virtual potential temperature"

; END LASSO variable reading and calculations ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SCM variables
  presctl_Pa = fctl->pres
  tmpctl_K   = fctl->T
  qvctl_kgkg = fctl->qv
  prest1_Pa  = ft1->pres
  tmpt1_K    = ft1->T
  qvt1_kgkg  = ft1->qv
  prest2_Pa  = ft2->pres
  tmpt2_K    = ft2->T
  qvt2_kgkg  = ft2->qv

; Calculating SCM saturation vapor pressure and saturation specific
; humidity
  svpctl_hPa = 6.11 * (10^((7.5*(tmpctl_K - 273.15)) / (273.3 + \
                          (tmpctl_K-273.15))))
  svpctl_Pa  = svpctl_hPa * 100.

  qvsatctl_kgkg = 0.622 * (svpctl_Pa / presctl_Pa)

  svpt1_hPa = 6.11 * (10^((7.5*(tmpt1_K - 273.15)) / (273.3 + \
                          (tmpt1_K-273.15))))
  svpt1_Pa  = svpt1_hPa * 100.

  qvsatt1_kgkg = 0.622 * (svpt1_Pa / prest1_Pa)

  svpt2_hPa = 6.11 * (10^((7.5*(tmpt2_K - 273.15)) / (273.3 + \
                          (tmpt2_K-273.15))))
  svpt2_Pa  = svpt2_hPa * 100.

  qvsatt2_kgkg = 0.622 * (svpt2_Pa / prest2_Pa)

; Calculating SCM relative humidity
  rhctl_64 = (qvctl_kgkg / qvsatctl_kgkg) * 100.

  rhctl_64@description = "Relative Humidity"
  rhctl_64@units       = "%"
  rhctl_64!0           = "Time"
  rhctl_64!1           = "bottom_top"
  rhctl_64!2           = "horiz_dim_layer"

  rht1_64 = (qvt1_kgkg / qvsatt1_kgkg) * 100.

  rht1_64@description = "Relative Humidity"
  rht1_64@units       = "%"
  rht1_64!0           = "Time"
  rht1_64!1           = "bottom_top"
  rht1_64!2           = "horiz_dim_layer"

  rht2_64 = (qvt2_kgkg / qvsatt2_kgkg) * 100.

  rht2_64@description = "Relative Humidity"
  rht2_64@units       = "%"
  rht2_64!0           = "Time"
  rht2_64!1           = "bottom_top"
  rht2_64!2           = "horiz_dim_layer"

; SCM temperature to potential temperature
  thtctl_K = new((/ dimsizes(tmpctl_K) /),float)
  do i=0,dimsizes(tscm)-1,1
    do j=0,dimsizes(presctl_Pa(0,:,0))-1,1
      if (rhctl_64(i,j,:) .lt. 98.9) then
        thtctl_K(i,j,:) = tmpctl_K(i,j,:)
        thtctl_K(i,j,:) = tmpctl_K(i,j,:) * ((P00 / presctl_Pa(i,j,:))^ \
                                            (R_dry / c_p))
      else
        thtctl_K(i,j,:) = tmpctl_K(i,j,:)
        thtctl_K(i,j,:) = tmpctl_K(i,j,:) * ((P00 / presctl_Pa(i,j,:))^ \
                                             (R_dry *(1 - (0.23 * \
                                              qvctl_kgkg(i,j,:))) / c_p))
      end if
    end do
  end do

  thtctl_K@description = "potential temperature"

  thtt1_K = new((/ dimsizes(tmpt1_K) /),float)
  do i=0,dimsizes(tscm)-1,1
    do j=0,dimsizes(prest1_Pa(0,:,0))-1,1
      if (rht1_64(i,j,:) .lt. 98.9) then
        thtt1_K(i,j,:) = tmpt1_K(i,j,:)
        thtt1_K(i,j,:) = tmpt1_K(i,j,:) * ((P00 / prest1_Pa(i,j,:))^ \
                                           (R_dry / c_p))
      else
        thtt1_K(i,j,:) = tmpt1_K(i,j,:)
        thtt1_K(i,j,:) = tmpt1_K(i,j,:) * ((P00 / prest1_Pa(i,j,:))^ \
                                           (R_dry *(1 - (0.23 * \
                                            qvt1_kgkg(i,j,:))) / c_p))
      end if
    end do
  end do

  thtt1_K@description = "potential temperature"

  thtt2_K = new((/ dimsizes(tmpt2_K) /),float)
  do i=0,dimsizes(tscm)-1,1
    do j=0,dimsizes(prest2_Pa(0,:,0))-1,1
      if (rht2_64(i,j,:) .lt. 98.9) then
        thtt2_K(i,j,:) = tmpt2_K(i,j,:)
        thtt2_K(i,j,:) = tmpt2_K(i,j,:) * ((P00 / prest2_Pa(i,j,:))^ \
                                           (R_dry / c_p))
      else
        thtt2_K(i,j,:) = tmpt2_K(i,j,:)
        thtt2_K(i,j,:) = tmpt2_K(i,j,:) * ((P00 / prest2_Pa(i,j,:))^ \
                                           (R_dry *(1 - (0.23 * \
                                            qvt2_kgkg(i,j,:))) / c_p))
      end if
    end do
  end do

  thtt2_K@description = "potential temperature"

; SCM Virtual potential temperature calculation
  thtvctl_64 = thtctl_K
  thtvctl_64 = thtctl_K * (1 + (0.61 * qvctl_kgkg))

  thtvctl_64@description = "virtual potential temperature"

  thtvctl_K = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    thtvctl_K(i,:) = linint1(presctl_Pa(i,:,0),thtvctl_64(i,:,0),False, \
                             preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(thtvctl_K(i,j))) then
        thtvctl_K(i,j) = thtvctl_64(i,j,0)
      end if
    end do
  end do

  thtvt1_64 = thtt1_K
  thtvt1_64 = thtt1_K * (1 + (0.61 * qvt1_kgkg))

  thtvt1_64@description = "virtual potential temperature"

  thtvt1_K = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    thtvt1_K(i,:) = linint1(prest1_Pa(i,:,0),thtvt1_64(i,:,0),False, \
                            preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(thtvt1_K(i,j))) then
        thtvt1_K(i,j) = thtvt1_64(i,j,0)
      end if
    end do
  end do

  thtvt2_64 = thtt2_K
  thtvt2_64 = thtt2_K * (1 + (0.61 * qvt2_kgkg))

  thtvt2_64@description = "virtual potential temperature"

  thtvt2_K = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    thtvt2_K(i,:) = linint1(prest2_Pa(i,:,0),thtvt2_64(i,:,0),False, \
                            preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(thtvt2_K(i,j))) then
        thtvt2_K(i,j) = thtvt2_64(i,j,0)
      end if
    end do
  end do

; END SCM variable reading and calculations ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Averaging time periods, two hour time averages for 3, 5, 7, 9, 11, 13,
; and 15 hrs. Lots of code and crunching here, so the program will be
; slowed further.
  thtvlas_03 = thtvlas_K(closest_val(3600.,twrf):closest_val(10800.,twrf)-1, \
                         :)
  thtvctl_03 = thtvctl_K(closest_val(3600.,tscm):closest_val(10800.,tscm)-1, \
                         :)
  thtvt1_03  = thtvt1_K(closest_val(3600.,tscm):closest_val(10800.,tscm)-1, \
                        :)
  thtvt2_03  = thtvt2_K(closest_val(3600.,tscm):closest_val(10800.,tscm)-1, \
                        :)

  thtvlas_tavg03 = dim_avg_n_Wrap(thtvlas_03,0)
  thtvctl_tavg03 = dim_avg_n_Wrap(thtvctl_03,0)
  thtvt1_tavg03  = dim_avg_n_Wrap(thtvt1_03,0)
  thtvt2_tavg03  = dim_avg_n_Wrap(thtvt2_03,0)

  thtvlas_05 = thtvlas_K(closest_val(10800.,twrf):closest_val(18000.,twrf)-1, \
                         :)
  thtvctl_05 = thtvctl_K(closest_val(10800.,tscm):closest_val(18000.,tscm)-1, \
                         :)
  thtvt1_05  = thtvt1_K(closest_val(10800.,tscm):closest_val(18000.,tscm)-1, \
                        :)
  thtvt2_05  = thtvt2_K(closest_val(10800.,tscm):closest_val(18000.,tscm)-1, \
                        :)

  thtvlas_tavg05 = dim_avg_n_Wrap(thtvlas_05,0)
  thtvctl_tavg05 = dim_avg_n_Wrap(thtvctl_05,0)
  thtvt1_tavg05  = dim_avg_n_Wrap(thtvt1_05,0)
  thtvt2_tavg05  = dim_avg_n_Wrap(thtvt2_05,0)

  thtvlas_07 = thtvlas_K(closest_val(18000.,twrf):closest_val(25200.,twrf)-1, \
                         :)
  thtvctl_07 = thtvctl_K(closest_val(18000.,tscm):closest_val(25200.,tscm)-1, \
                         :)
  thtvt1_07  = thtvt1_K(closest_val(18000.,tscm):closest_val(25200.,tscm)-1, \
                        :)
  thtvt2_07  = thtvt2_K(closest_val(18000.,tscm):closest_val(25200.,tscm)-1, \
                        :)

  thtvlas_tavg07 = dim_avg_n_Wrap(thtvlas_07,0)
  thtvctl_tavg07 = dim_avg_n_Wrap(thtvctl_07,0)
  thtvt1_tavg07  = dim_avg_n_Wrap(thtvt1_07,0)
  thtvt2_tavg07  = dim_avg_n_Wrap(thtvt2_07,0)

  thtvlas_09 = thtvlas_K(closest_val(25200.,twrf):closest_val(32400.,twrf)-1, \
                         :)
  thtvctl_09 = thtvctl_K(closest_val(25200.,tscm):closest_val(32400.,tscm)-1, \
                         :)
  thtvt1_09  = thtvt1_K(closest_val(25200.,tscm):closest_val(32400.,tscm)-1, \
                        :)
  thtvt2_09  = thtvt2_K(closest_val(25200.,tscm):closest_val(32400.,tscm)-1, \
                        :)

  thtvlas_tavg09 = dim_avg_n_Wrap(thtvlas_09,0)
  thtvctl_tavg09 = dim_avg_n_Wrap(thtvctl_09,0)
  thtvt1_tavg09  = dim_avg_n_Wrap(thtvt1_09,0)
  thtvt2_tavg09  = dim_avg_n_Wrap(thtvt2_09,0)

  thtvlas_11 = thtvlas_K(closest_val(32400.,twrf):closest_val(39600.,twrf)-1, \
                         :)
  thtvctl_11 = thtvctl_K(closest_val(32400.,tscm):closest_val(39600.,tscm)-1, \
                         :)
  thtvt1_11  = thtvt1_K(closest_val(32400.,tscm):closest_val(39600.,tscm)-1, \
                        :)
  thtvt2_11  = thtvt2_K(closest_val(32400.,tscm):closest_val(39600.,tscm)-1, \
                        :)

  thtvlas_tavg11 = dim_avg_n_Wrap(thtvlas_11,0)
  thtvctl_tavg11 = dim_avg_n_Wrap(thtvctl_11,0)
  thtvt1_tavg11  = dim_avg_n_Wrap(thtvt1_11,0)
  thtvt2_tavg11  = dim_avg_n_Wrap(thtvt2_11,0)

  thtvlas_13 = thtvlas_K(closest_val(39600.,twrf):closest_val(46800.,twrf)-1, \
                         :)
  thtvctl_13 = thtvctl_K(closest_val(39600.,tscm):closest_val(46800.,tscm)-1, \
                         :)
  thtvt1_13  = thtvt1_K(closest_val(39600.,tscm):closest_val(46800.,tscm)-1, \
                        :)
  thtvt2_13  = thtvt2_K(closest_val(39600.,tscm):closest_val(46800.,tscm)-1, \
                        :)

  thtvlas_tavg13 = dim_avg_n_Wrap(thtvlas_13,0)
  thtvctl_tavg13 = dim_avg_n_Wrap(thtvctl_13,0)
  thtvt1_tavg13  = dim_avg_n_Wrap(thtvt1_13,0)
  thtvt2_tavg13  = dim_avg_n_Wrap(thtvt2_13,0)

  thtvlas_15 = thtvlas_K(closest_val(46800.,twrf):closest_val(54000.,twrf)-1, \
                         :)
  thtvctl_15 = thtvctl_K(closest_val(46800.,tscm):closest_val(54000.,tscm)-1, \
                         :)
  thtvt1_15  = thtvt1_K(closest_val(46800.,tscm):closest_val(54000.,tscm)-1, \
                        :)
  thtvt2_15  = thtvt2_K(closest_val(46800.,tscm):closest_val(54000.,tscm)-1, \
                        :)

  thtvlas_tavg15 = dim_avg_n_Wrap(thtvlas_15,0)
  thtvctl_tavg15 = dim_avg_n_Wrap(thtvctl_15,0)
  thtvt1_tavg15  = dim_avg_n_Wrap(thtvt1_15,0)
  thtvt2_tavg15  = dim_avg_n_Wrap(thtvt2_15,0)

; END TIME averaging ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Height range for plotting
  hl3k = closest_val(3000.,hgtlas_m(2,:))

; END VARIABLE input and calculations
; Open workstation for plotting
  wks = gsn_open_wks(gtype,sims+"_VituralTheta_NOMYNN")

; Resources for potential temperature plots
  tres = True

  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@gsnLeftString    = "(a) 0700-0900 CST"
  tres@tiXAxisString    = "Virtual Potential Temp. (K)"
  tres@tiYAxisString    = "Height (m)"
  tres@vpWidthF         = 0.99
  tres@vpHeightF        = 0.5
  tres@trXMinF          = 303.
  tres@trXMaxF          = 321.
  tres@trYMaxF          = 3000.
  tres@xyLineColor      = "darkorange1"

; Define ranges for all 3 hour heights
  thtvlas_havg03 = thtvlas_tavg03(0:hl3k(0))
  thtvctl_havg03 = thtvctl_tavg03(0:hl3k(0))
  thtvt1_havg03  = thtvt1_tavg03(0:hl3k(0))
; Define THE height range
  hlas_range    = hgtlas_m(2,0:hl3k(0))

; Plot LASSO 03 hour
  pltlas = gsn_csm_xy(wks,thtvlas_havg03,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg03,hlas_range,tres)

; Resources and plot for t1
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg03,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Resources for potential temperature legends
  genres                    = True
  genres@XPosPercent        = 17.5
  genres@YPosPercent        = 71
  lineres                   = True
  lineres@lgLineColors      = (/ "darkorange1","purple4","black" /)
;  lineres@lgDashIndexes     = (/ 0,0,0,1 /)
;  lineres@lgLineColors      = (/ "darkorange1","black" /)
  lineres@lgDashIndexes     = (/ 0,0 /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "LASSO","CTRL","TEST1" /)
;  textres@lgLabels          = (/ "LASSO",t1 /)

; Draw plots and legend, frame workstation
;  drawNDCGrid(wks)
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 05 hour LASSO
  tres@gsnLeftString    = "(b) 0900-1100 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 05 hour
  thtvlas_havg05 = thtvlas_tavg05(0:hl3k(0))
  thtvctl_havg05 = thtvctl_tavg05(0:hl3k(0))
  thtvt1_havg05  = thtvt1_tavg05(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg05,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg05,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg05,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 07 hour LASSO
  tres@gsnLeftString    = "(c) 1100-1300 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 07 hour
  thtvlas_havg07 = thtvlas_tavg07(0:hl3k(0))
  thtvctl_havg07 = thtvctl_tavg07(0:hl3k(0))
  thtvt1_havg07  = thtvt1_tavg07(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg07,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg07,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg07,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 09 hour LASSO
  tres@gsnLeftString    = "(d) 1300-1500 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 09 hour
  thtvlas_havg09 = thtvlas_tavg09(0:hl3k(0))
  thtvctl_havg09 = thtvctl_tavg09(0:hl3k(0))
  thtvt1_havg09  = thtvt1_tavg09(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg09,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg09,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg09,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 11 hour LASSO
  tres@gsnLeftString    = "(e) 1500-1700 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 11 hour
  thtvlas_havg11 = thtvlas_tavg11(0:hl3k(0))
  thtvctl_havg11 = thtvctl_tavg11(0:hl3k(0))
  thtvt1_havg11  = thtvt1_tavg11(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg11,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg11,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg11,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 13 hour LASSO
  tres@gsnLeftString    = "(f) 1700-1900 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 13 hour
  thtvlas_havg13 = thtvlas_tavg13(0:hl3k(0))
  thtvctl_havg13 = thtvctl_tavg13(0:hl3k(0))
  thtvt1_havg13  = thtvt1_tavg13(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg13,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg13,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg13,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 15 hour LASSO
  tres@gsnLeftString    = "(g) 1900-2100 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 15 hour
  thtvlas_havg15 = thtvlas_tavg15(0:hl3k(0))
  thtvctl_havg15 = thtvctl_tavg15(0:hl3k(0))
  thtvt1_havg15  = thtvt1_tavg15(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg15,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtvctl_havg15,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtvt1_havg15,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
;  overlay(pltlas,pltt2)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  print("Completed: "+systemfunc("date"))

end

