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
  sims  = "SID"+sn
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_20190714_rawmodel/raw_model/"
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

; Add LASSO files
  wrf_f = systemfunc("ls "+rdir+"wrfout_d01_*.nc")
  flas  = addfiles(wrf_f,"r")
; Adding files in this manner saves code but does slow down the execution
; of the program, so expect relatively long execution times.
  ListSetType(flas,"cat")

; Add UFS netCDF file
  fufs = addfile("UFS_Selection_"+date+".nc","r")

; Time for LASSO
  wtim = flas[:]->Times
  hwrf = wrf_times_c(wtim,0)

  twrf       = hwrf
  twrf       = hwrf * 60. * 60.
  twrf@units = "seconds since "+ldate

; Time for UFS
  utim        = fufs->Time
  hrufs       = tofloat(utim)
  hrufs@units = hwrf@units
  hrufs!0     = "Time"

  tufs       = hrufs
  tufs       = hrufs * 60. * 60.
  tufs@units = "seconds since "+udate

; Variables from LASSO
  lat_w      = wrf_user_getvar(flas[0],"lat",0)
  lon_w      = wrf_user_getvar(flas[0],"lon",0)
  ph         = flas[:]->PH     ; perturbation geopotential
  phb        = flas[:]->PHB    ; base state geopotential
  shflas     = flas[:]->HFX    ; upward surface heat flux
  lhflas     = flas[:]->LH     ; latent heat flux
  t2m        = flas[:]->T2     ; 2m air temperature
  pp         = flas[:]->P      ; perturbation pressure
  pb         = flas[:]->PB     ; base state pressure
  theta_pert = flas[:]->T      ; perturbation potential temperature

; Matching LASSO longitude (degE, west is negative) to UFS longitude (degE,
; west .gt. 180 .and. .lt. 360)
  lon_wEE = lon_w
  lon_wEE = lon_w + 360.

; Converting perturbation and base state height to full height
  ph  = ph + phb

  ph_avg = dim_avg_n(ph,(/ 2,3 /))

  z_wrf_stag = ph_avg / g
  z_wrf_num  = dimsizes(z_wrf_stag(0,:))
  z_wrf      = new((/ dimsizes(twrf),z_wrf_num-1 /),float)
  do i=0,dimsizes(twrf)-1,1
    z_wrf(i,:) = (z_wrf_stag(i,1:z_wrf_num-1) + z_wrf_stag(i,0:z_wrf_num-2)) * \
                 0.5
  end do

  hgtlas_m       = z_wrf
  hgtlas_m@units = "m"

; LASSO potential temperature
  theta_avg = dim_avg_n_Wrap(theta_pert,(/ 2,3 /))

  theta = theta_avg
  theta = theta_avg + 300. ; instructions say to add 300K to tht pert

  thtlas_K = theta

; Converting perturbation and base state pressure to full pressure
  pp_avg = dim_avg_n_Wrap(pp,(/ 2,3 /))
  pb_avg = dim_avg_n_Wrap(pb,(/ 2,3 /))

  preslas_Pa = pb_avg
  preslas_Pa = pb_avg + pp_avg

  preslas_Pa@description = "FULL MODEL PRESSURE"

; Calculate air temperature for LASSO from potential temperature
  tmplas_K             = thtlas_K
  tmplas_K             = thtlas_K / ((P00 / preslas_Pa)^(R_dry / c_p))
  tmplas_K@description = "AIR TEMPERATURE"

; Taking spatial averages of LASSO fluxes
  shflas_avg = dim_avg_n_Wrap(shflas,(/ 1,2 /))
  lhflas_avg = dim_avg_n_Wrap(lhflas,(/ 1,2 /))

  shflas_wm2 = shflas_avg(1:dimsizes(hwrf)-1)
  lhflas_wm2 = lhflas_avg(1:dimsizes(hwrf)-1)

; Averages of LASSO temperatures
  t2mlas_avg = dim_avg_n_Wrap(t2m,(/ 1,2 /))

  t2mlas_K = t2mlas_avg(1:dimsizes(hwrf)-1)

; UFS variables
  lat_at     = fufs->lat
  lon_at     = fufs->lon
  lat_u      = fufs->latsfc
  lon_u      = fufs->lonsfc
  hgtufs_aa  = fufs->GEOP_HGT
  presufs_Pa = fufs->lv_ISBL0
  shfufs_wm2 = fufs->SH_FLX
  lhfufs_wm2 = fufs->LH_FLX
  t2mufs_aa  = fufs->T2

;; Horizontal interpolation of UFS area-wide data to single LASSO point
  hgtufs_m_loc   = linint2_points_Wrap(lon_at,lat_at,hgtufs_aa,False, \
                                       lon_wEE(0,0),lat_w(0,0),0)
  shfufs_wm2_loc = linint2_points_Wrap(lon_u,lat_u,shfufs_wm2,False, \
                                       lon_wEE(0,0),lat_w(0,0),0)
  lhfufs_wm2_loc = linint2_points_Wrap(lon_u,lat_u,lhfufs_wm2,False, \
                                       lon_wEE(0,0),lat_w(0,0),0)
  t2mufs_K_loc   = linint2_points_Wrap(lon_u,lat_u,t2mufs_aa,False, \
                                       lon_wEE(0,0),lat_w(0,0),0)

; UFS data are hourly, while LASSO is every ten minutes; the times need
; to be the same
  shfufs_wm2_time = linint1_Wrap(hrufs,shfufs_wm2_loc(:,0),False, \
                                 hwrf(1:dimsizes(hwrf)-1),0)
  lhfufs_wm2_time = linint1_Wrap(hrufs,lhfufs_wm2_loc(:,0),False, \
                                 hwrf(1:dimsizes(hwrf)-1),0)
  t2mufs_K_time   = linint1_Wrap(hrufs,t2mufs_K_loc(:,0),False, \
                                 hwrf(1:dimsizes(hwrf)-1),0)

; Open workstation, begin plotting
  wks = gsn_open_wks(gtype,"UFSvLASSO_fluxes_"+sims)

; Resources for sensible heat
  hres = True

  hres@gsnMaximize      = True
  hres@gsnDraw          = False
  hres@gsnFrame         = False
  hres@xyLineThicknessF = 3.4
  hres@xyLineColor      = "black"
  hres@gsnRightString   = "UFS vs "+sims
  hres@gsnLeftString    = ""
  hres@tiXAxisString    = "US CST"
  hres@tiYAxisString    = "Sens Heat Flux (W m~S~-2~N~)"
  hres@tmXBMode         = "Explicit"
  hres@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  hres@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  hres@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

; Plotting sensible heat
  pltufs = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1),shfufs_wm2_time,hres)

  hres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1),shflas_wm2,hres)

  overlay(pltufs,pltlas)

; Legend resources
  genres                    = True
  genres@XPosPercent        = 20
  genres@YPosPercent        = 90
  lineres                   = True
  lineres@lgLineColors      = (/ "black","darkorange1" /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "UFS","LASSO" /)

  draw(pltufs)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Latent heat flux resources
  lres= True

  lres@gsnMaximize      = True
  lres@gsnDraw          = False
  lres@gsnFrame         = False
  lres@xyLineThicknessF = 3.4
  lres@xyLineColor      = "black"
  lres@gsnRightString   = "UFS vs "+sims
  lres@gsnLeftString    = ""
  lres@tiXAxisString    = "US CST"
  lres@tiYAxisString    = "Latent Heat Flux (W m~S~-2~N~)"
  lres@tmXBMode         = "Explicit"
  lres@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  lres@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  lres@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

; Plot latent heat
  pltufs = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1),lhfufs_wm2_time,lres)

  lres@xyLineColor      = "orange"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1),lhflas_wm2,lres)

  overlay(pltufs,pltlas)

  draw(pltufs)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 2m air temperature
  tres = True

  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@xyLineColor      = "black"
  tres@gsnRightString   = "UFS vs "+sims
  tres@gsnLeftString    = ""
  tres@tiXAxisString    = "US CST"
  tres@tiYAxisString    = "Air Temp @ 2m ("+t2mlas_K@units+")"
  tres@trYMinF          = 296.
  tres@trYMaxF          = 308.
  tres@tmXBMode         = "Explicit"
  tres@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  tres@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  tres@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

  pltufs = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1),t2mufs_K_time,tres)

  tres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1),t2mlas_K,tres)

  overlay(pltufs,pltlas)

  genres@XPosPercent = 22
  genres@YPosPercent = 89

  draw(pltufs)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end

