load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "scm_press_to_hgt.ncl"

undef("LASSO_wind_wa_subsets")

procedure LASSO_wind_wa_subsets(yyyy,mm,dd,hh)

begin

; User modification area, the forcing and directories vary between
; LASSO simulations
  gtype = "png"

  phys  = "GFS_v16" ; "GFS_v16","GSD_v1","csawmg","GFS_v15p2"

  year  = yyyy
  month = mm
  day   = dd
  hour  = hh

  udate = year+"-"+month+"-"+day+" "+hour+":00:00"
  date  = year+month+day
  cycle = year+month+day+hour

  rdir = "/work/noaa/ufs-phys/ekalina/lasso-les/2018_from_wayne/"

  diro = "/work/noaa/ufs-phys/ekalina/ccpp-scm-20210816/scm/run/"+ \
         "output_LASSO_"+date+"_s02_SCM_GFS_v16/"

  dir_comp = "/work/noaa/ufs-phys/ekalina/lasso-les/comparison_data/" 

; End user modification area
  print("Started: "+systemfunc("date"))

; Constants
  R_dry   = 287.058 ; ideal gas constant for dry air (J kg^-1 K^-1)
  karman  = 0.4     ; von karman constant
  pi      = 4.*atan(1.)

; Read vertical levels to interpolate LASSO and SCM data onto
; Need a consistent height grid so that we can composite multiple cases together.
  data = readAsciiTable("./interp_levs.txt",2,"float",0)
  zi_m = data(:,1)

; Addfiles
  flas = addfile(rdir+"wrfstat_extracted_s02_"+year+"-"+month+"-"+day+"_"+hour+"_00_00.nc","r")
  fscm = addfile(diro+"output.nc","r")

; Times
  Time_s = fscm->time_inst
  Time_s@description = "Model elapsed time"

  hscm       = Time_s
  hscm       = Time_s / 60. / 60.
  hscm@units = "hours since "+udate

; Variables from LASSO
  hgtlas_m    = flas->CSP_Z  ; height
  ulas        = flas->CSP_U  ; x(u)-wind component
  vlas        = flas->CSP_V  ; y(v)-wind component
  ustarlas_ms = flas->CST_UST ; friction velocity

; LASSO wind speed and direction
  wspdlas = ulas
  wspdlas = (ulas^2. + vlas^2.)^0.5

; Calculate 10-m U/V from LASSO.
; Assumes neutral stability.
  d_m = 0. ; displacement height in m (assume zero?)
  ustarlas_ms@_FillValue = 0. ; don't divide by zero
  z0las_m = hgtlas_m(:,0)*exp(-1.0*karman*wspdlas(:,0)/ustarlas_ms) ; Eq. 12 from Krishnamurthy et al. (2021)
  u10las_ms = ulas(:,0)*(log((10.-d_m)/z0las_m)/log((hgtlas_m(:,0)-d_m)/z0las_m))
  v10las_ms = vlas(:,0)*(log((10.-d_m)/z0las_m)/log((hgtlas_m(:,0)-d_m)/z0las_m))

  wspd10las_ms = u10las_ms
  wspd10las_ms = (u10las_ms^2. + v10las_ms^2.)^0.5

  wspd10las_ms@description = "LASSO 10-m wind speed estimate from similarity theory"
  wspd10las_ms@units = "m s-1"

  wveclas_rad   = atan2(ulas,vlas)
  wvec10las_rad = atan2(u10las_ms,v10las_ms)

  wdirlas   = (wveclas_rad * (180. / pi)) + 180.
  wdir10las = (wvec10las_rad * (180. / pi)) + 180.

; Variables from SCM
  presscm_Pa = rm_single_dims(fscm->pres)
  tmpscm_K   = rm_single_dims(fscm->T)
  qscm_kgkg  = rm_single_dims(fscm->qv) ; specific humidity!
  uscm       = rm_single_dims(fscm->u)
  vscm       = rm_single_dims(fscm->v)
  tauuscm    = rm_single_dims(fscm->tau_u)
  tauvscm    = rm_single_dims(fscm->tau_v)
  psfcscm    = rm_single_dims(fscm->pres_s)

; Calculate SCM height.
  hgtscm_m = scm_press_to_hgt(psfcscm,presscm_Pa,tmpscm_K,qscm_kgkg,0.)

; Converting SCM winds from u/v to spd/dir
  wspdscm = uscm
  wspdscm = (uscm^2. + vscm^2.)^0.5

  wvecscm_rad = atan2(uscm,vscm)

  wdirscm_deg = (wvecscm_rad * (180. / pi)) + 180.

; Finding the density of air using the ideal gas law to convert surface tau
; (wind stress) to surface winds
  rhoscm = psfcscm / (tmpscm_K(:,0) * R_dry)

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

; Make sure zi_m (the vertical grid we are interpolating to)
; does not extend beyond the SCM or LASSO vertical grids.
  len_hgtscm   = dimsizes(hgtscm_m(0,:))
  len_hgtlasso = dimsizes(hgtlas_m(0,:))
  len_zi       = dimsizes(zi_m)

  if (zi_m(0) .lt. max(hgtscm_m(1:,0))) then
    print("The target height grid (zi_m) extends below the SCM height grid")
    exit()
  end if
  if (zi_m(0) .lt. max(hgtlas_m(1:,0))) then
    print("The target height grid (zi_m) extends below the LASSO height grid")
    exit()
  end if
  if (zi_m(len_zi-1) .gt. min(hgtscm_m(1:,len_hgtscm-1))) then
    print("The target height grid (zi_m) extends above the SCM height grid")
    exit()
  end if
  if (zi_m(len_zi-1) .gt. min(hgtlas_m(1:,len_hgtlasso-1))) then
    print("The target height grid (zi_m) extends above the LASSO height grid")
    exit()
  end if

; Matching the vertical coordinates of the column u/v winds (SCM to LASSO)
  wspdscm_ms = linint1_n_Wrap(hgtscm_m,wspdscm,False,zi_m,0,1)
  uscm_ms    = linint1_n(hgtscm_m,uscm,False,zi_m,0,1)
  vscm_ms    = linint1_n(hgtscm_m,vscm,False,zi_m,0,1)

  wspdlas_ms = linint1_n_Wrap(hgtlas_m,wspdlas,False,zi_m,0,1)
  ulas_ms    = linint1_n(hgtlas_m,ulas,False,zi_m,0,1)
  vlas_ms    = linint1_n(hgtlas_m,vlas,False,zi_m,0,1)

  wspdscm_ms@description="SCM wind speed"
  wspdscm_ms@units="m s-1"

  wspdlas_ms@description="LASSO wind speed"
  wspdlas_ms@units="m s-1"

  wspdscm_ms!0   = "Time_s"
  uscm_ms!0      = "Time_s"
  vscm_ms!0      = "Time_s"
  wspdscm_ms!1   = "bottom_top"
  uscm_ms!1      = "bottom_top"
  vscm_ms!1      = "bottom_top"
  wspd10scm_ms!0 = "Time_s"
  wdir10scm!0    = "Time"

  wspd10scm_ms@description = "SCM 10-m wind speed"
  wspd10scm_ms@units = "m s-1"

  uscm_ms@description = "x-wind on model layer centers"
  uscm_ms@units       = "m s-1"
  vscm_ms@description = "y-wind on model layer centers"
  vscm_ms@units       = "m s-1"

  wspdlas_ms!0 = "Time_s"
  wspdlas_ms!1 = "bottom_top"
  ulas_ms!0    = "Time_s"
  vlas_ms!0    = "Time_s"
  ulas_ms!1    = "bottom_top"
  vlas_ms!1    = "bottom_top"

; Differences in wind speeds (SCM minus LASSO)
  wspd_df = wspdscm_ms
  wspd_df = wspdscm_ms - wspdlas_ms

  u_df = uscm_ms
  u_df = uscm_ms - ulas_ms

  v_df = vscm_ms
  v_df = vscm_ms - vlas_ms

  wspd_diff = wspd_df
  u_diff    = u_df(bottom_top|:,Time_s|:)
  v_diff    = v_df(bottom_top|:,Time_s|:)

  wspd_diff@description = "Wind speed difference (SCM-LASSO)"
  wspd_diff@units       = "m s-1"

  wspd10_diff = wspd10scm_ms
  wspd10_diff = wspd10scm_ms - wspd10las_ms

  wspd10_diff@description = "10-m wind speed difference (SCM-LASSO)"
  wspd10_diff@units       = "m s-1"

; Open workstation
  wks = gsn_open_wks(gtype,diro+cycle+"_"+phys+"_Wind")

; Resources for xy plots of surface wind speed
  xyres = True

  xyres@gsnMaximize      = True
  xyres@gsnDraw          = False
  xyres@gsnFrame         = False
  xyres@xyLineThicknessF = 3.4
  xyres@gsnLeftString    = "10-m Wind Speed"
;  xyres@gsnRightString   = sims
  xyres@tiXAxisString    = "US CST"
  xyres@tiYAxisString    = "Wind Speed (m s~S~-1~N~)"
  xyres@trYMinF          = -10.0
  xyres@trYMaxF          = 10.0
  xyres@tmXBMode         = "Explicit"
  xyres@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  xyres@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  xyres@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

  pltscm = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      wspd10scm_ms(1:dimsizes(hscm)-1),xyres)

  xyres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      wspd10las_ms(1:dimsizes(hscm)-1),xyres)

  xyres@xyLineColor      = "purple4"
  xyres@xyDashPattern    = 1

  pltdf = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      wspd10_diff(1:dimsizes(hscm)-1),xyres)

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
  ares@sfYArray             = zi_m
  ares@gsnYAxisIrregular2Linear = True
  ares@tiXAxisString        = "US CST"
  ares@tiYAxisString        = "Height (m)"
;  ares@gsnLeftString        = sims+" - LASSO Zonal Wind"
  ares@gsnLeftString        = "LASSO Zonal Wind"
  ares@gsnRightString       = "m s~S~-1~N~"
  ares@cnLevelSelectionMode = "ManualLevels"
  ares@cnMinLevelValF       = -4.
  ares@cnMaxLevelValF       = 4.
  ares@cnLevelSpacingF      = 0.5
  ares@tmXBMode             = "Explicit"
  ares@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  ares@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  ares@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)

  plot = gsn_csm_contour(wks,u_diff,ares)

;  ares@gsnLeftString        = sims+" - LASSO Meridional Wind"
  ares@gsnLeftString        = "LASSO Meridional Wind"

  plot = gsn_csm_contour(wks,v_diff,ares)

  ares@gsnLeftString        = "SCM - LASSO Wind Speed"
  plot = gsn_csm_contour(wks,transpose(wspd_diff),ares)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of relevant variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")
  fout = dir_comp+"LASSO_SCM_comp_"+date+".nc"

  system("/bin/rm -f "+fout)
  fo = addfile(fout,"c")

  fAtt               = True
  fAtt@title         = "Comparison data between LASSO and SCM for "+date
  fAtt@creation_date = systemfunc("date")

; Get dimensions.
  dims = dimsizes(wspd_diff)
  nt = dims(0)
  nz = dims(1)
  bottom_top = zi_m

  bottom_top@description = "Height Above Ground Level"
  bottom_top@units = "m"

; Define the dimensions
  dimNames = (/ "Time_s","bottom_top" /)
  dimSizes = (/ nt,      nz           /)
  dimUnlim = (/ True,    False        /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"Time_s",typeof(Time_s),"Time_s")
  filevarattdef(fo,"Time_s",Time_s)
  fo->Time_s = (/ Time_s /)

  filevardef(fo,"bottom_top",typeof(bottom_top),"bottom_top")
  filevarattdef(fo,"bottom_top",bottom_top)
  fo->bottom_top = (/ bottom_top /)

  filevardef(fo,"wspd_SCM",typeof(wspdscm_ms),(/ "Time_s", "bottom_top" /))
  filevarattdef(fo,"wspd_SCM",wspdscm_ms)
  fo->wspd_SCM = (/ wspdscm_ms /)

  filevardef(fo,"wspd_LAS",typeof(wspdlas_ms),(/ "Time_s", "bottom_top" /))
  filevarattdef(fo,"wspd_LAS",wspdlas_ms)
  fo->wspd_LAS = (/ wspdlas_ms /)

  filevardef(fo,"wspd10_SCM",typeof(wspd10scm_ms),"Time_s")
  filevarattdef(fo,"wspd10_SCM",wspd10scm_ms)
  fo->wspd10_SCM = (/ wspd10scm_ms /)

  filevardef(fo,"wspd10_LAS",typeof(wspd10las_ms),"Time_s")
  filevarattdef(fo,"wspd10_LAS",wspd10las_ms)
  fo->wspd10_LAS = (/ wspd10las_ms /)

  filevardef(fo,"wspd10_diff",typeof(wspd10_diff),"Time_s")
  filevarattdef(fo,"wspd10_diff",wspd10_diff)
  fo->wspd10_diff = (/ wspd10_diff /)

  filevardef(fo,"wspd_diff",typeof(wspd_diff),(/ "Time_s", "bottom_top" /))
  filevarattdef(fo,"wspd_diff",wspd_diff)
  fo->wspd_diff = (/ wspd_diff /)  

  print("Wrote file -> "+fout)
  print("Complete: "+systemfunc("date"))

end

