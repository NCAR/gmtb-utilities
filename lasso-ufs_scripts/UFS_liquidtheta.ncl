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
  sn    = "8"
  sims  = "SID"+sn ; "SID"+sn,"MSDA+UFSsflx"
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
  c_pv  = 1996.   ; spec heat of water vapor (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  eps   = (R_dry / R_vap)
  pi    = 4.*atan(1.)

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
  thtlas_K   = flas->T      ; potential temperature
  qvlas_kgkg = flas->QVAPOR ; water vapor specific humidity
  qclas_kgkg = flas->QCLOUD ; cloud water mixing ratio
  qrlas_kgkg = flas->QRAIN  ; rain water mixing ratio
;  qilas_kgkg = flas->QICE   ; ice water mixing ratio
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height

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

; Convert water vapor specific humidity back to water vapor mixing ratio for
; theta-l calculations
  rvlas_kgkg = qvlas_kgkg
  rvlas_kgkg = qvlas_kgkg / (1 - qvlas_kgkg)

; Liquid water mixing ratio
  rllas_kgkg = qclas_kgkg
  rllas_kgkg = qclas_kgkg + qrlas_kgkg

; Total water mixing ratio (vapor+cloud+rain+ice [note, all ice are currently
; zero])
  rtotlas = rvlas_kgkg
  rtotlas = rvlas_kgkg + rllas_kgkg

; Calculate gamma and chi for liquid water potential temperature equation
  gammalas = (rtotlas * R_vap) / (c_p + (rtotlas * c_pv))

  chilas = new((/ dimsizes(qvlas_kgkg) /),float)
  do i=0,dimsizes(hwrf)-1,1
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (rhlas(i,j) .lt. 100.) then
        chilas(i,j) = R_dry / c_p
      else
        chilas(i,j) = (R_dry / c_p) * ((1 + (rvlas_kgkg(i,j) / eps)) / \
                                      (1 + ((rvlas_kgkg(i,j)*c_pv) / \
                                      (c_p))))
      end if
    end do
  end do

; Calculate liquid water potential temperature for LASSO
  thtllas_K = thtlas_K *((((eps + rvlas_kgkg) / (eps + rtotlas))^chilas) * \
                        ((rvlas_kgkg / rtotlas)^(gammalas * -1)) * \
                        exp(((l_v * -1) * rllas_kgkg) / ((c_p + (rtotlas * \
                        c_pv)) * tmplas_K)))

; UFS variables
  lat_u      = fufs->lat
  lon_u      = fufs->lon
  hgtufs_u   = fufs->GEOP_HGT
  presufs_Pa = fufs->lv_ISBL0
  prs6ufs_Pa = fufs->lv_ISBL6
  tmpufs_u   = fufs->T
  qvufs_u    = fufs->QVAPOR
  qcufs_u    = fufs->QCLOUD
  qrufs_u    = fufs->QRAIN
  qsufs_u    = fufs->QSNOW
  qiufs_u    = fufs->QICE
  qgufs_u    = fufs->QGRAUP

  ntu  = dimsizes(hrufs)
  nzu0 = dimsizes(presufs_Pa)
  nzu6 = dimsizes(prs6ufs_Pa)
  nyu  = dimsizes(lat_u)
  nxu  = dimsizes(lon_u)

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

; UFS Potential Temperature
  thtufs_u = new((/ dimsizes(tmpufs_u) /),float)
  do i=0,nzu0-1,1
    thtufs_u(:,i,:,:) = tmpufs_u(:,i,:,:) * ((P00 / presufs_Pa(i))^ \
                                            (R_dry / c_p))
  end do

; Water vapor specific humidity to water vapor mixing ratio
  rvufs_u = qvufs_u
  rvufs_u = qvufs_u / (1 - qvufs_u)

; UFS Liquid water mixing ratio
  rlufs_u = qcufs_u
  rlufs_u = qcufs_u + qrufs_u

; Total water mixing ratio (vapor+cloud+rain+ice+snow+graupel)
; qv has 41 vertical levels, the rest of the q variables have 22
  rlufs_kgkg = linint1_n_Wrap(prs6ufs_Pa,rlufs_u,False,presufs_Pa,0,1)
  riufs_kgkg = linint1_n_Wrap(prs6ufs_Pa,qiufs_u,False,presufs_Pa,0,1)
  rsufs_kgkg = linint1_n_Wrap(prs6ufs_Pa,qsufs_u,False,presufs_Pa,0,1)
  rgufs_kgkg = linint1_n_Wrap(prs6ufs_Pa,qgufs_u,False,presufs_Pa,0,1)

  rtotufs = rvufs_u
  rtotufs = rvufs_u + rlufs_kgkg + riufs_kgkg + rsufs_kgkg + rgufs_kgkg

; Calculate gamma and chi for liquid water potential temperature equation
  gammaufs = (rtotufs * R_vap) / (c_p + (rtotufs * c_pv))

  chiufs = new((/ dimsizes(qvufs_u) /),float)
  do i=0,ntu-1,1
    do j=0,nzu0-1,1
      do k=0,nyu-1,1
        do l=0,nxu-1,1
          if (rhufs_u(i,j,k,l) .lt. 100.) then
            chiufs(i,j,k,l) = R_dry / c_p
          else
            chiufs(i,j,k,l) = (R_dry / c_p) * ((1 + (rvufs_u(i,j,k,l) / \
                                              eps)) / (1 + \
                                              ((rvufs_u(i,j,k,l)*c_pv) / \
                                              (c_p))))
          end if
        end do
      end do
    end do
  end do

; Calculate liquid water potential temperature for the UFS
  thtlufs_u = thtufs_u *((((eps + rvufs_u) / (eps + rtotufs))^chiufs) * \
                        ((rvufs_u / rtotufs)^(gammaufs * -1)) * \
                        exp(((l_v * -1) * rlufs_kgkg) / ((c_p + (rtotufs * \
                        c_pv)) * tmpufs_u)))

; Horizontal interpolation of UFS area-wide data to the single LASSO point
  thtlufs_loc = linint2_points_Wrap(lon_u,lat_u,thtlufs_u,False, \
                                    lon_wEE,lat_w,0)

; UFS data is hourly, while LASSO is every ten minutes; the times need
; to be the same


; UFS date  is hourly, while LASSO is every ten minutes; the times need
; to be the same
  thtlufs_time   = new((/ dimsizes(hwrf),nzu0,1 /),float)
  do i=0,nzu0-1,1
    thtlufs_time(:,i,0) = linint1_Wrap(hrufs,thtlufs_loc(:,i,0),False, \
                                       hwrf,0)
  end do

; Matching the vertical spacing (UFS to LASSO)
  thtlufs_K = new((/ dimsizes(hwrf),dimsizes(preslas_Pa(0,:)),1 /),float)
  do i=0,dimsizes(hwrf)-1,1
    thtlufs_K(i,:,0) = linint1_Wrap(presufs_Pa,thtlufs_time(i,:,0), \
                                    False,preslas_Pa(i,:),0)
  end do

  thtlufs_K!0 = "Time_s"
  thtlufs_K!2 = "pts"

; Averaging time periods, two hour time averages for 3, 5, 7, 9, 11, 13,
; and 15 hrs.
  thtllas_03 = thtllas_K(closest_val(3600.,twrf):closest_val(10800.,twrf)-1, \
                         :)
  thtlufs_03 = thtlufs_K(closest_val(3600.,twrf):closest_val(10800.,twrf)-1, \
                         :,0)

  thtllas_tavg03 = dim_avg_n_Wrap(thtllas_03,0)
  thtlufs_tavg03 = dim_avg_n_Wrap(thtlufs_03,0)

  thtllas_05 = thtllas_K(closest_val(10800.,twrf):closest_val(18000.,twrf)-1, \
                         :)
  thtlufs_05 = thtlufs_K(closest_val(10800.,twrf):closest_val(18000.,twrf)-1, \
                         :,0)

  thtllas_tavg05 = dim_avg_n_Wrap(thtllas_05,0)
  thtlufs_tavg05 = dim_avg_n_Wrap(thtlufs_05,0)

  thtllas_07 = thtllas_K(closest_val(18000.,twrf):closest_val(25200.,twrf)-1, \
                         :)
  thtlufs_07 = thtlufs_K(closest_val(18000.,twrf):closest_val(25200.,twrf)-1, \
                         :,0)

  thtllas_tavg07 = dim_avg_n_Wrap(thtllas_07,0)
  thtlufs_tavg07 = dim_avg_n_Wrap(thtlufs_07,0)

  thtllas_09 = thtllas_K(closest_val(25200.,twrf):closest_val(32400.,twrf)-1, \
                         :)
  thtlufs_09 = thtlufs_K(closest_val(25200.,twrf):closest_val(32400.,twrf)-1, \
                         :,0)

  thtllas_tavg09 = dim_avg_n_Wrap(thtllas_09,0)
  thtlufs_tavg09 = dim_avg_n_Wrap(thtlufs_09,0)

  thtllas_11 = thtllas_K(closest_val(32400.,twrf):closest_val(39600.,twrf)-1, \
                         :)
  thtlufs_11 = thtlufs_K(closest_val(32400.,twrf):closest_val(39600.,twrf)-1, \
                         :,0)

  thtllas_tavg11 = dim_avg_n_Wrap(thtllas_11,0)
  thtlufs_tavg11 = dim_avg_n_Wrap(thtlufs_11,0)

  thtllas_13 = thtllas_K(closest_val(39600.,twrf):closest_val(46800.,twrf)-1, \
                         :)
  thtlufs_13 = thtlufs_K(closest_val(39600.,twrf):closest_val(46800.,twrf)-1, \
                         :,0)

  thtllas_tavg13 = dim_avg_n_Wrap(thtllas_13,0)
  thtlufs_tavg13 = dim_avg_n_Wrap(thtlufs_13,0)

  thtllas_15 = thtllas_K(closest_val(46800.,twrf):closest_val(54000.,twrf)-1, \
                         :)
  thtlufs_15 = thtlufs_K(closest_val(46800.,twrf):closest_val(54000.,twrf)-1, \
                         :,0)

  thtllas_tavg15 = dim_avg_n_Wrap(thtllas_15,0)
  thtlufs_tavg15 = dim_avg_n_Wrap(thtlufs_15,0)

; End time averaging
; Height range for plotting
  hl3k = closest_val(3000.,hgtlas_m(1,:))

; END VARIABLE input and calculations
; Open workstation for plotting
  wks = gsn_open_wks(gtype,"UFS-"+date+"_ThetaL")

; Resources for potential temperature plots
  tres = True

  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@gsnLeftString    = "(a) 0700-0900 CST"
  tres@tiXAxisString    = "Liquid Water Potential Temp. (K)"
  tres@tiYAxisString    = "Height (m)"
  tres@vpWidthF         = 0.99
  tres@vpHeightF        = 0.5
  tres@trXMinF          = 300.
  tres@trXMaxF          = 320.
  tres@trYMaxF          = 3000.
  tres@xyLineColor      = "darkorange1"

; Define ranges for all 3 hour heights
  thtllas_havg03 = thtllas_tavg03(0:hl3k(0))
  thtlufs_havg03 = thtlufs_tavg03(0:hl3k(0))
; Define THE height range
  hlas_range    = hgtlas_m(1,0:hl3k(0))

; Plot LASSO 03 hour
  pltlas = gsn_csm_xy(wks,thtllas_havg03,hlas_range,tres)

; Resources and plot for ufs
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg03,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Resources for potential temperature legends
  genres                    = True
  genres@XPosPercent        = 18.5
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
  thtllas_havg05 = thtllas_tavg05(0:hl3k(0))
  thtlufs_havg05 = thtlufs_tavg05(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg05,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg05,hlas_range,tres)

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
  thtllas_havg07 = thtllas_tavg07(0:hl3k(0))
  thtlufs_havg07 = thtlufs_tavg07(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg07,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg07,hlas_range,tres)

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
  thtllas_havg09 = thtllas_tavg09(0:hl3k(0))
  thtlufs_havg09 = thtlufs_tavg09(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg09,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg09,hlas_range,tres)

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
  thtllas_havg11 = thtllas_tavg11(0:hl3k(0))
  thtlufs_havg11 = thtlufs_tavg11(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg11,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg11,hlas_range,tres)

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
  thtllas_havg13 = thtllas_tavg13(0:hl3k(0))
  thtlufs_havg13 = thtlufs_tavg13(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg13,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg13,hlas_range,tres)

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
  thtllas_havg15 = thtllas_tavg15(0:hl3k(0))
  thtlufs_havg15 = thtlufs_tavg15(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg15,hlas_range,tres)

; Resources and plot for UFS
  tres@xyLineColor      = "black"

  pltufs = gsn_csm_xy(wks,thtlufs_havg15,hlas_range,tres)

; Overlay plots
  overlay(pltlas,pltufs)

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end

