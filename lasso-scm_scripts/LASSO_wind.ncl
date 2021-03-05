load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area, the forcing and directories vary between
; LASSO simulations
  gtype = "x11"
  sn    = "8"
  sims  = "SID"+sn ; "SID"+sn,"MDSA+UFSsflx"
  phys  = "GFS_v16beta" ; "GFS_v16beta","GSD_v1","csawmg","GFS_v15p2",
;-------> "GFS_v16beta_MYNN","v16beta_MYNNrad","v16beta_Thomp","satmedmf"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_"+date+"_rawmodel/raw_model/"

  diro = "/glade/u/home/damico/SCMv4p1_update/gmtb-scm/scm/bin/output_"+ \
         "LASSO_"+date+"_"+sims+"_SCM_"+phys+"/"

; End user modification area
  print("Started: "+systemfunc("date"))

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4.*atan(1.)

; Addfiles
  flas  = addfile(rdir+"LASSO_"+date+"_SUBSET.nc","r")

  fscm = addfile(diro+"output.nc","r")

; Times
  twrf = flas->Time_s
  hwrf = flas->Time_hr

  tscm = fscm->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hours since "+udate

; Variables from LASSO
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height
  ulas_ms    = flas->U      ; x(u)-wind component
  vlas_ms    = flas->V      ; y(v)-wind component
  u10las_ms  = flas->U10    ; 10m u wind
  v10las_ms  = flas->V10    ; 10m v wind

; LASSO wind speed and direction
  wspdlas_ms = ulas_ms
  wspdlas_ms = (ulas_ms^2. + vlas_ms^2.)^0.5

  wspd10las_ms = u10las_ms
  wspd10las_ms = (u10las_ms^2. + v10las_ms^2)^0.5

  wveclas_rad   = atan2(ulas_ms,vlas_ms)
  wvec10las_rad = atan2(u10las_ms,v10las_ms)

  wdirlas   = (wveclas_rad * (180. / pi)) + 180.
  wdir10las = (wvec10las_rad * (180. / pi)) + 180.

; Variables from SCM
  presscm_Pa = fscm->pres
  tmpscm_K   = fscm->T
  uscm       = fscm->u
  vscm       = fscm->v
  tauuscm    = fscm->tau_u
  tauvscm    = fscm->tau_v
  psfcscm    = fscm->pres_s

; Converting SCM winds from u/v to spd/dir
  wspdscm = uscm
  wspdscm = (uscm^2. + vscm^2.)^0.5

  wvecscm_rad = atan2(uscm,vscm)

  wdirscm_deg = (wvecscm_rad * (180. / pi)) + 180.

; Finding the density of air using the ideal gas law to convert surface tau
; (wind stress) to surface winds
  rhoscm = psfcscm / (tmpscm_K(:,0,:) * R_dry)

; Converting surface tau to surface winds
  TAUscm     = (tauuscm^2. + tauvscm^2.)^0.5
  tauvec_rad = atan2(tauuscm,tauvscm)
  taudir_deg = (tauvec_rad * (180. / pi)) + 180.

  UV10scm = (TAUscm / (0.01 * rhoscm))^0.5

  u10scm_ms = UV10scm * cos(tauvec_rad)
  v10scm_ms = UV10scm * sin(tauvec_rad)

  wspd10scm_ms = (u10scm_ms^2. + v10scm_ms^2.)^0.5
  wvec10_rad   = atan2(u10scm_ms,v10scm_ms)

  wdir10scm = (wvec10_rad * (180. / pi)) + 180.

; Matching the vertical coordinates of the column u/v winds (SCM to LASSO)
  wspdscm_ms = new((/ dimsizes(preslas_Pa) /),float)
  wdirscm    = new((/ dimsizes(preslas_Pa) /),float)
  uscm_ms    = new((/ dimsizes(preslas_Pa) /),float)
  vscm_ms    = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    wspdscm_ms(i,:) = linint1_Wrap(presscm_Pa(i,:,0),wspdscm(i,:,0),False, \
                                   preslas_Pa(i,:),0)
    wdirscm(i,:)    = linint1_Wrap(presscm_Pa(i,:,0),wdirscm_deg(i,:,0),False, \
                                   preslas_Pa(i,:),0)
    uscm_ms(i,:)    = linint1(presscm_Pa(i,:,0),uscm(i,:,0),False, \
                              preslas_Pa(i,:),0)
    vscm_ms(i,:)    = linint1(presscm_Pa(i,:,0),vscm(i,:,0),False, \
                              preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(uscm_ms(i,j))) then
        uscm_ms(i,j) = uscm(i,j,0)
      end if
      if (ismissing(vscm_ms(i,j))) then
        vscm_ms(i,j) = vscm(i,j,0)
      end if
    end do
  end do
  wspdscm_ms!0   = "Time_s"
  wdirscm!0      = "Time_s"
  uscm_ms!0      = "Time_s"
  vscm_ms!0      = "Time_s"
  uscm_ms!1      = "bottom_top"
  vscm_ms!1      = "bottom_top"
  wspd10scm_ms!0 = "Time"
  wdir10scm!0    = "Time"
  wspd10scm_ms!1 = "horiz_dim_layer"
  wdir10scm!1    = "horiz_dim_layer"

  uscm_ms@description = "x-wind on model layer centers"
  uscm_ms@units       = "m s-1"
  vscm_ms@description = "y-wind on model layer centers"
  vscm_ms@units       = "m s-1"

; Differences in wind speeds (SCM minus LASSO)
  wspd_df = wspdscm_ms
  wspd_df = wspdscm_ms - wspdlas_ms

  u_df = uscm_ms
  u_df = uscm_ms - ulas_ms

  v_df = vscm_ms
  v_df = vscm_ms - vlas_ms

  wspd_diff = wspd_df(bottom_top|:,Time_s|:)
  u_diff    = u_df(bottom_top|:,Time_s|:)
  v_diff    = v_df(bottom_top|:,Time_s|:)

  wspd10_diff = wspd10scm_ms(1:dimsizes(hscm)-1,0)
  wspd10_diff = wspd10scm_ms(1:dimsizes(hscm)-1,0) - \
                wspd10las_ms(1:dimsizes(hscm)-1)

; 3000 m height definition (most PBLs won't be higher than 3 km, with some
; exceptions)
  hl3k = closest_val(3000.,hgtlas_m(1,:))

; Open workstation
  wks = gsn_open_wks(gtype,sims+"-"+phys+"_Wind")

; Resources for xy plots of surface wind speed
  xyres = True

  xyres@gsnMaximize      = True
  xyres@gsnDraw          = False
  xyres@gsnFrame         = False
  xyres@xyLineThicknessF = 3.4
  xyres@gsnLeftString    = "10-m Wind Speed"
  xyres@gsnRightString   = sims
  xyres@tiXAxisString    = "US CST"
  xyres@tiYAxisString    = "Wind Speed (m s~S~-1~N~)"
  xyres@trYMinF          = -1.5
  xyres@trYMaxF          = 3.5
  xyres@tmXBMode         = "Explicit"
  xyres@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  xyres@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  xyres@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

  pltscm = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      wspd10scm_ms(1:dimsizes(hscm)-1,0),xyres)

  xyres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      wspd10las_ms(1:dimsizes(hscm)-1),xyres)

  xyres@xyLineColor      = "purple4"
  xyres@xyDashPattern    = 1

  pltdf = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                     wspd10_diff,xyres)

; Overlay plots
  overlay(pltscm,pltlas)
  overlay(pltscm,pltdf)

; Legend resources
  genres                    = True
  genres@XPosPercent        = 70.5
  genres@YPosPercent        = 23
  lineres                   = True
  lineres@lgLineColors      = (/ "black","darkorange1","purple4" /)
  lineres@lgDashIndexes     = (/ 0,0,1 /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "SCM","LASSO","SCM - LASSO" /)

; Polyline resources for v16beta_MYNNpbl
  plres                  = True
  plres@gsLineThicknessF = 1.

; Draw plots and legend, frame workstation
;  drawNDCGrid(wks)
  draw(pltscm)
  simple_legend_ndc(wks,genres,lineres,textres)
  gsn_polyline(wks,pltscm,(/ 0,15 /),(/ 0,0 /),plres)
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

; Resources for vertical wind speed anomaly plot
  gsn_define_colormap(wks,BlueDarkRed18_WIM)

  ares = True

  ares@gsnMaximize          = True
  ares@cnFillOn             = True
  ares@cnLinesOn            = False
  ares@sfXArray             = hscm
  ares@sfYArray             = hgtlas_m(1,0:hl3k(0))
  ares@tiXAxisString        = "US CST"
  ares@tiYAxisString        = "Height (m)"
  ares@gsnLeftString        = sims+" - LASSO Zonal Wind"
  ares@gsnRightString       = "m s~S~-1~N~"
  ares@cnLevelSelectionMode = "ManualLevels"
  ares@cnMinLevelValF       = -4.
  ares@cnMaxLevelValF       = 4.
  ares@cnLevelSpacingF      = 0.5
  ares@tmXBMode             = "Explicit"
  ares@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  ares@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  ares@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)

  plot = gsn_csm_contour(wks,u_diff(0:hl3k(0),:),ares)

  ares@gsnLeftString        = sims+" - LASSO Meridional Wind"

  plot = gsn_csm_contour(wks,v_diff(0:hl3k(0),:),ares)

  print("Complete: "+systemfunc("date"))

end

