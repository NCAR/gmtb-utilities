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
  sims  = "SID8" ; "SID8","MSDA+UFSsflx"
  sn    = "8"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_"+date+"_rawmodel/raw_model/"

; End user modification area
  print("Started: "+systemfunc("date"))

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4*atan(1.)

; Add LASSO subset file
  flas = addfile(rdir+"LASSO_"+date+"_SUBSET.nc","r")

; Add UFS netCDF file
  fufs = addfile("UFS_Selection_"+date+".nc","r")

; Time for LASSO
  hwrf = flas->Time_hr
  twrf = flas->Time_s

  ntw = dimsizes(hwrf)

; Time for UFS
  utim        = fufs->Time
  hrufs       = tofloat(utim)
  hrufs@units = hwrf@units
  hrufs!0     = "Time"

  tufs       = hrufs
  tufs       = hrufs * 60. * 60.
  tufs@units = "seconds since "+udate

; Variables from LASSO
  lat_w      = flas->lat
  lon_w      = flas->lon
  preslas_Pa = flas->P
  hgtlas_m   = flas->height
  thtlas_K   = flas->T
  qvlas_kgkg = flas->QVAPOR

; LASSO longitude conversion to match UFS
  lon_wEE = lon_w
  lon_wEE = lon_w + 360.

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
; UFS variables
  lat_u      = fufs->lat
  lon_u      = fufs->lon
  hgtufs_u   = fufs->GEOP_HGT
  presufs_Pa = fufs->lv_ISBL0
  tmpufs_u   = fufs->T
  qvufs_u    = fufs->QVAPOR

  ntu = dimsizes(hrufs)
  nzu = dimsizes(presufs_Pa)
  nyu = dimsizes(lat_u)
  nxu = dimsizes(lon_u)

; Calculation of saturation specific humidity and relative humidity to
; determine saturation
  svpufs_hPa = 6.11 * (10^((7.5*(tmpufs_u - 273.15)) / (273.3 + \
                          (tmpufs_u-273.15))))
  svpufs_Pa  = svpufs_hPa * 100.

  qvsatufs_kgkg = new((/ dimsizes(svpufs_Pa) /),float)
  do i=0,dimsizes(presufs_Pa)-1,1
    qvsatufs_kgkg(:,i,:,:) = 0.622 * (svpufs_Pa(:,i,:,:) / presufs_Pa(i))
  end do

; Calculating UFS relative humidity
  rhufs_u = (qvufs_u / qvsatufs_kgkg) * 100.

  rhufs_u@long_name = "Relative humidity"
  rhufs_u@units     = "%"
  rhufs_u!0         = "Time"
  rhufs_u!1         = "lv_ISBL0"
  rhufs_u!2         = "lat"
  rhufs_u!3         = "lon"

; Calculation of UFS potential temperature with saturated consideration for
; virtual potential temperature
  thtufs_u = new((/ dimsizes(tmpufs_u) /),float)
  do i=0,ntu-1,1
    do j=0,nzu-1,1
      do k=0,nyu-1,1
        do l=0,nxu-1,1
          if (rhufs_u(i,j,k,l) .lt. 98.9) then
            thtufs_u(i,j,k,l) = tmpufs_u(i,j,k,l)
            thtufs_u(i,j,k,l) = tmpufs_u(i,j,k,l) * ((P00 / presufs_Pa(j))^ \
                                                     (R_dry / c_p))
          else
            thtufs_u(i,j,k,l) = tmpufs_u(i,j,k,l)
            thtufs_u(i,j,k,l) = tmpufs_u(i,j,k,l) * ((P00 / presufs_Pa(j))^ \
                                                     (R_dry * (1 - (0.23 * \
                                                      qvufs_u(i,j,k,l))) / \
                                                      c_p))
          end if
        end do
      end do
    end do
  end do

; Calculate virtual potential temperature for UFS
  thtvufs_u = thtufs_u
  thtvufs_u = thtufs_u * (1 + (0.61 * qvufs_u))

  thtvufs_u@long_name = "Virtual potential temperature"

; Horizontal interpolation of UFS area-wide data to the single LASSO point
  thtvufs_loc = linint2_points_Wrap(lon_u,lat_u,thtvufs_u,False, \
                                    lon_wEE,lat_w,0)

; UFS data is hourly, while LASSO is every ten minutes; the times need
; to be the same
  thtvufs_time   = new((/ dimsizes(hwrf),nzu,1 /),float)
  do i=0,nzu-1,1
    thtvufs_time(:,i,0) = linint1_Wrap(hrufs,thtvufs_loc(:,i,0),False, \
                                       hwrf,0)
  end do

; Matching the vertical spacing (UFS to LASSO)
  thtvufs_K = new((/ dimsizes(hwrf),dimsizes(preslas_Pa(0,:)),1 /),float)
  do i=0,dimsizes(hwrf)-1,1
    thtvufs_K(i,:,0) = linint1_Wrap(presufs_Pa,thtvufs_time(i,:,0), \
                                    False,preslas_Pa(i,:),0)
  end do

  thtvufs_K!0 = "Time"
  thtvufs_K!2 = "pts"

; Averaging time periods, two hour time averages for 3, 5, 7, 9, 11, 13,
; and 15 hrs.
  thtvlas_03 = thtvlas_K(closest_val(3600.,twrf):closest_val(10800.,twrf)-1, \
                         :)
  thtvufs_03 = thtvufs_K(closest_val(3600.,twrf):closest_val(10800.,twrf)-1, \
                         :,0)

  thtvlas_tavg03 = dim_avg_n_Wrap(thtvlas_03,0)
  thtvufs_tavg03 = dim_avg_n_Wrap(thtvufs_03,0)

  thtvlas_05 = thtvlas_K(closest_val(10800.,twrf):closest_val(18000.,twrf)-1, \
                         :)
  thtvufs_05 = thtvufs_K(closest_val(10800.,twrf):closest_val(18000.,twrf)-1, \
                         :,0)

  thtvlas_tavg05 = dim_avg_n_Wrap(thtvlas_05,0)
  thtvufs_tavg05 = dim_avg_n_Wrap(thtvufs_05,0)

  thtvlas_07 = thtvlas_K(closest_val(18000.,twrf):closest_val(25200.,twrf)-1, \
                         :)
  thtvufs_07 = thtvufs_K(closest_val(18000.,twrf):closest_val(25200.,twrf)-1, \
                         :,0)

  thtvlas_tavg07 = dim_avg_n_Wrap(thtvlas_07,0)
  thtvufs_tavg07 = dim_avg_n_Wrap(thtvufs_07,0)

  thtvlas_09 = thtvlas_K(closest_val(25200.,twrf):closest_val(32400.,twrf)-1, \
                         :)
  thtvufs_09 = thtvufs_K(closest_val(25200.,twrf):closest_val(32400.,twrf)-1, \
                         :,0)

  thtvlas_tavg09 = dim_avg_n_Wrap(thtvlas_09,0)
  thtvufs_tavg09 = dim_avg_n_Wrap(thtvufs_09,0)

  thtvlas_11 = thtvlas_K(closest_val(32400.,twrf):closest_val(39600.,twrf)-1, \
                         :)
  thtvufs_11 = thtvufs_K(closest_val(32400.,twrf):closest_val(39600.,twrf)-1, \
                         :,0)

  thtvlas_tavg11 = dim_avg_n_Wrap(thtvlas_11,0)
  thtvufs_tavg11 = dim_avg_n_Wrap(thtvufs_11,0)

  thtvlas_13 = thtvlas_K(closest_val(39600.,twrf):closest_val(46800.,twrf)-1, \
                         :)
  thtvufs_13 = thtvufs_K(closest_val(39600.,twrf):closest_val(46800.,twrf)-1, \
                         :,0)

  thtvlas_tavg13 = dim_avg_n_Wrap(thtvlas_13,0)
  thtvufs_tavg13 = dim_avg_n_Wrap(thtvufs_13,0)

  thtvlas_15 = thtvlas_K(closest_val(46800.,twrf):closest_val(54000.,twrf)-1, \
                         :)
  thtvufs_15 = thtvufs_K(closest_val(46800.,twrf):closest_val(54000.,twrf)-1, \
                         :,0)

  thtvlas_tavg15 = dim_avg_n_Wrap(thtvlas_15,0)
  thtvufs_tavg15 = dim_avg_n_Wrap(thtvufs_15,0)

; End time averaging
; Height range for plotting
  hl3k = closest_val(3000.,hgtlas_m(1,:))

; END VARIABLE input and calculations
; Open workstation for plotting
  wks = gsn_open_wks(gtype,"UFS_VituralTheta-"+sims)

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
  tres@trXMinF          = 302.
  tres@trXMaxF          = 318.
  tres@trYMaxF          = 3000.
  tres@xyLineColor      = "darkorange1"

; Define ranges for all 3 hour heights
  thtvlas_havg03 = thtvlas_tavg03(0:hl3k(0))
  thtvufs_havg03 = thtvufs_tavg03(0:hl3k(0))
; Define THE height range
  hlas_range    = hgtlas_m(1,0:hl3k(0))

; Plot LASSO 03 hour
  pltlas = gsn_csm_xy(wks,thtvlas_havg03,hlas_range,tres)

; Resources and plot for ufs
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg03,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Resources for potential temperature legends
  genres                    = True
  genres@XPosPercent        = 17.5
  genres@YPosPercent        = 71
  lineres                   = True
  lineres@lgLineColors      = (/ "darkorange1","black" /)
;  lineres@lgDashIndexes     = (/ 0,1 /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "LASSO","UFS" /)

; Draw plots and legend, frame workstation
;  drawNDCGrid(wks)
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 05 hour LASSO
  tres@gsnLeftString    = "(b) 0900-1100 CST"
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 05 hour
  thtvlas_havg05 = thtvlas_tavg05(0:hl3k(0))
  thtvufs_havg05 = thtvufs_tavg05(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg05,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg05,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 07 hour LASSO
  tres@gsnLeftString    = "(c) 1100-1300 CST"
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 07 hour
  thtvlas_havg07 = thtvlas_tavg07(0:hl3k(0))
  thtvufs_havg07 = thtvufs_tavg07(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg07,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg07,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)
; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 09 hour LASSO
  tres@gsnLeftString    = "(d) 1300-1500 CST"
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 09 hour
  thtvlas_havg09 = thtvlas_tavg09(0:hl3k(0))
  thtvufs_havg09 = thtvufs_tavg09(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg09,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg09,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 11 hour LASSO
  tres@gsnLeftString    = "(e) 1500-1700 CST"
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 11 hour
  thtvlas_havg11 = thtvlas_tavg11(0:hl3k(0))
  thtvufs_havg11 = thtvufs_tavg11(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg11,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg11,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 13 hour LASSO
  tres@gsnLeftString    = "(f) 1700-1900 CST"
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 13 hour
  thtvlas_havg13 = thtvlas_tavg13(0:hl3k(0))
  thtvufs_havg13 = thtvufs_tavg13(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg13,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg13,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 15 hour LASSO
  tres@gsnLeftString    = "(g) 1900-2100 CST"
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 15 hour
  thtvlas_havg15 = thtvlas_tavg15(0:hl3k(0))
  thtvufs_havg15 = thtvufs_tavg15(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtvlas_havg15,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtvufs_havg15,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end

