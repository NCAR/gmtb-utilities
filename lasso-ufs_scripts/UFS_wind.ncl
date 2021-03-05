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
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height
  ulas_ms    = flas->U      ; x(u)-wind component
  vlas_ms    = flas->V      ; y(v)-wind component
  u10las_ms  = flas->U10    ; 10m u wind
  v10las_ms  = flas->V10    ; 10m v wind

; LASSO longitude conversion to match UFS
  lon_wEE = lon_w
  lon_wEE = lon_w + 360.

; LASSO wind speed and direction
  wspdlas_ms = ulas_ms
  wspdlas_ms = (ulas_ms^2. + vlas_ms^2.)^0.5

  wspd10las_ms = u10las_ms
  wspd10las_ms = (u10las_ms^2. + v10las_ms^2)^0.5

  wveclas_rad   = atan2(ulas_ms,vlas_ms)
  wvec10las_rad = atan2(u10las_ms,v10las_ms)

  wdirlas   = (wveclas_rad * (180. / pi)) + 180.
  wdir10las = (wvec10las_rad * (180. / pi)) + 180.

; UFS variables
  lat_u      = fufs->lat
  lon_u      = fufs->lon
  latsfc_u   = fufs->latsfc
  lonsfc_u   = fufs->lonsfc
  hgtufs_u   = fufs->GEOP_HGT
  presufs_Pa = fufs->lv_ISBL0
  u_u        = fufs->U
  v_u        = fufs->V
  u10_u      = fufs->U10
  v10_u      = fufs->V10

; Horizontal interpolation of UFS area-wide data to the single LASSO point
  hgtufs_loc = linint2_points_Wrap(lon_u,lat_u,hgtufs_u,False, \
                                   lon_wEE,lat_w,0)
  uufs_loc   = linint2_points_Wrap(lon_u,lat_u,u_u,False, \
                                   lon_wEE,lat_w,0)
  vufs_loc   = linint2_points_Wrap(lon_u,lat_u,v_u,False, \
                                   lon_wEE,lat_w,0)
  u10ufs_loc = linint2_points_Wrap(lonsfc_u,latsfc_u,u10_u,False, \
                                   lon_wEE,lat_w,0)
  v10ufs_loc = linint2_points_Wrap(lonsfc_u,latsfc_u,v10_u,False, \
                                   lon_wEE,lat_w,0)

; UFS data are hourly, LASSO data are every 10 minutes; they need to be equal
  hgtufs_time = new((/ dimsizes(hwrf),dimsizes(presufs_Pa),1 /),float)
  uufs_time   = new((/ dimsizes(hwrf),dimsizes(presufs_Pa),1 /),float)
  vufs_time   = new((/ dimsizes(hwrf),dimsizes(presufs_Pa),1 /),float)
  do i=0,dimsizes(presufs_Pa)-1,1
    hgtufs_time(:,i,0) = linint1_Wrap(hrufs,hgtufs_loc(:,i,0),False, \
                                      hwrf,0)
    uufs_time(:,i,0)   = linint1_Wrap(hrufs,uufs_loc(:,i,0),False, \
                                      hwrf,0)
    vufs_time(:,i,0)   = linint1_Wrap(hrufs,vufs_loc(:,i,0),False, \
                                      hwrf,0)
  end do
  u10ufs_ms = linint1_Wrap(hrufs,u10ufs_loc(:,0),False, \
                           hwrf,0)
  v10ufs_ms = linint1_Wrap(hrufs,v10ufs_loc(:,0),False, \
                           hwrf,0)

; U and V need the same vertical spacing, LASSO has 226 vertical levels,
; UFS has 57
  uufs_ms = new((/ dimsizes(hwrf),dimsizes(hgtlas_m(0,:)),1 /),float)
  vufs_ms = new((/ dimsizes(hwrf),dimsizes(hgtlas_m(0,:)),1 /),float)
  do i=0,dimsizes(hwrf)-1,1
    uufs_ms(i,:,0) = linint1_Wrap(presufs_Pa,uufs_time(i,:,0),False, \
                                  preslas_Pa(i,:),0)
    vufs_ms(i,:,0) = linint1_Wrap(presufs_Pa,vufs_time(i,:,0),False, \
                                  preslas_Pa(i,:),0)
  end do
  uufs_ms!0 = "Time"
  uufs_ms!1 = "bottom_top"
  uufs_ms!2 = "pts"
  vufs_ms!0 = "Time"
  vufs_ms!1 = "bottom_top"
  vufs_ms!2 = "pts"

; Conversion of UFS u and v components to wind speed and direction
  wspdufs_ms = uufs_ms
  wspdufs_ms = (uufs_ms^2. + vufs_ms^2.)^0.5

  wspd10ufs_ms = u10ufs_ms
  wspd10ufs_ms = (u10ufs_ms^2. + v10ufs_ms^2.)^0.5

  wvecufs_rad   = atan2(uufs_ms,vufs_ms)
  wvec10ufs_rad = atan2(u10ufs_ms,v10ufs_ms)

  wdirufs   = (wvecufs_rad * (180. / pi)) + 180.
  wdir10ufs = (wvec10ufs_rad * (180. / pi)) + 180.

; Differences in wind speeds UFS minus LASSO
  wspd_df = wspdufs_ms(:,:,0)
  wspd_df = wspdufs_ms(:,:,0) - wspdlas_ms

  wspd_diff = wspd_df(bottom_top|:,Time|:)

  u_df = uufs_ms(:,:,0)
  u_df = uufs_ms(:,:,0) - ulas_ms
  v_df = vufs_ms(:,:,0)
  v_df = vufs_ms(:,:,0) - vlas_ms

  u_diff = u_df(bottom_top|:,Time|:)
  v_diff = v_df(bottom_top|:,Time|:)

  ul_ms = ulas_ms(bottom_top|:,Time_s|:)
  vl_ms = vlas_ms(bottom_top|:,Time_s|:)

  wspd10_df = wspd10ufs_ms
  wspd10_df = wspd10ufs_ms - wspd10las_ms

; 3000 m height definition (most PBLs won't be higher than 3 km, with some
; exceptions)
  hl3k = closest_val(3000.,hgtlas_m(0,:))

; Open workstation
  wks = gsn_open_wks(gtype,date+"-UFSvLASSO_winds")

; Resources for xy plot of 10 m wind speed
  xyres = True

  xyres@gsnMaximize      = True
  xyres@gsnDraw          = False
  xyres@gsnFrame         = False
  xyres@xyLineThicknessF = 3.4
  xyres@gsnLeftString    = "10-m Wind Speed"
  xyres@gsnRightString   = "UFS & "+sims
  xyres@tiXAxisString    = "US CST"
  xyres@tiYAxisString    = "Wind Speed (m s~S~-1~N~)"
  xyres@trYMinF          = -0.5
  xyres@trYMaxF          = 5.5
  xyres@tmXBMode         = "Explicit"
  xyres@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  xyres@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  xyres@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

; Plotting xy 10 m winds
  pltufs = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      wspd10ufs_ms(1:dimsizes(hwrf)-1),xyres)

  xyres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      wspd10las_ms(1:dimsizes(hwrf)-1),xyres)

  xyres@xyLineColor      = "purple4"
  xyres@xyDashPattern    = 1

  pltdf  = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      wspd10_df(1:dimsizes(hwrf)-1),xyres)

  overlay(pltufs,pltlas)
  overlay(pltufs,pltdf)

; Legend resources
  genres                    = True
  genres@XPosPercent        = 20
  genres@YPosPercent        = 90
  lineres                   = True
  lineres@lgLineColors      = (/ "black","darkorange1","purple4" /)
  lineres@lgDashIndexes     = (/ 0,0,1 /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "UFS","LASSO","UFS - LASSO" /)

; Polyline resources
  plres                  = True
  plres@gsLineThicknessF = 1.

;  drawNDCGrid(wks)
  draw(pltufs)
  gsn_polyline(wks,pltufs,(/ 0,15 /),(/ 0,0 /),plres)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Create new color table with white actually in the middle
  BlueDarkRed18_WIM = (/ (/ 1.00000,1.00000,1.00000 /), \ ; Foreground (0)
                         (/ 0.00000,0.00000,0.00000 /), \ ; Background (1)
                         (/ 0.14118,0.00000,0.84706 /), \ ; 2
                         (/ 0.09412,0.10980,0.96863 /), \ ; 3
                         (/ 0.15686,0.34118,1.00000 /), \ ; 4
                         (/ 0.23922,0.25941,1.00000 /), \ ; 5
                         (/ 0.33725,0.69020,1.00000 /), \ ; 6
                         (/ 0.45882,0.82745,1.00000 /), \ ; 7
                         (/ 0.60000,0.91765,1.00000 /), \ ; 8
                         (/ 0.73725,0.97647,1.00000 /), \ ; 9
                         (/ 1.00000,1.00000,1.00000 /), \ ; 10
                         (/ 1.00000,1.00000,1.00000 /), \ ; 11
                         (/ 1.00000,0.94510,0.73725 /), \ ; 12
                         (/ 1.00000,0.83922,0.60000 /), \ ; 13
                         (/ 1.00000,0.67451,0.45882 /), \ ; 14
                         (/ 1.00000,0.47059,0.33725 /), \ ; 15
                         (/ 1.00000,0.23922,0.23922 /), \ ; 16
                         (/ 0.96863,0.15294,0.20784 /), \ ; 17
                         (/ 0.84706,0.08235,0.18431 /), \ ; 18
                         (/ 0.64706,0.00000,0.12941 /) /) ; 19

; Resources for anomaly plot (contours)
  gsn_define_colormap(wks,BlueDarkRed18_WIM)

  ares = True

  ares@gsnMaximize          = True
  ares@gsnDraw              = False
  ares@gsnFrame             = False
  ares@cnFillOn             = True
  ares@cnLinesOn            = False
  ares@sfXArray             = hwrf
  ares@sfYArray             = hgtlas_m(1,0:hl3k(0))
  ares@tiXAxisString        = "US CST"
  ares@tiYAxisString        = "Height (m)"
  ares@gsnLeftString        = "UFS - LASSO u"
  ares@gsnRightString       = "m s~S~-1~N~"
  ares@cnLevelSelectionMode = "ManualLevels"
  ares@cnMinLevelValF       = -4.
  ares@cnMaxLevelValF       = 4.
  ares@cnLevelSpacingF      = 0.5
  ares@tmXBMode             = "Explicit"
  ares@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  ares@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  ares@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)
  ares@lbTitleOn            = True
  ares@lbTitleString        = "CONTOUR: LASSO u-wind"
  ares@lbTitleFontHeightF   = 0.015

; Plotting anomaly plot
  plot = gsn_csm_contour(wks,u_diff(0:hl3k(0),:),ares)

  lres = True

  lres@gsnMaximize                  = True
  lres@gsnDraw                      = False
  lres@gsnFrame                     = False
  lres@gsnLeftString                = ""
  lres@gsnRightString               = ""
  lres@sfXArray                     = hwrf
  lres@sfYArray                     = hgtlas_m(1,0:hl3k(0))
  lres@cnLineThicknessF             = 2.
  lres@cnInfoLabelOn                = False
  lres@gsnContourNegLineDashPattern = 1
  pltlas = gsn_csm_contour(wks,ul_ms(0:hl3k(0),:),lres)

  overlay(plot,pltlas)

  draw(plot)
  frame(wks)

  ares@gsnLeftString        = "UFS - LASSO v"
  ares@lbTitleString        = "CONTOUR: LASSO v-Wind"

  plot = gsn_csm_contour(wks,v_diff(0:hl3k(0),:),ares)

  pltlas = gsn_csm_contour(wks,vl_ms(0:hl3k(0),:),lres)

  overlay(plot,pltlas)

  draw(plot)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end
