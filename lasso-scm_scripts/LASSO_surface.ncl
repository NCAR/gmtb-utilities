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
  sims  = "SID"+sn ; "MSDA+UFSsflx","SID"+sn
  phys  = "GFS_v16beta" ; "GFS_v16beta","GSD_v1","csawmg","GFS_v15p2",
;-------> "v16beta_MYNNpbl","v16beta_MYNNrad","v16beta_Thomp","satmedmf"
  sn    = "8"
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

; LASSO variables
  shflas_Wm2 = flas->HFX    ; upward surface heat flux
  lhflas_Wm2 = flas->LH     ; latent heat flux
  t2mlas_K   = flas->T2     ; 2m air temperature

; SCM variables
  shfscm_Wm2 = fscm->shf
  lhfscm_Wm2 = fscm->lhf
  t2mscm_K   = fscm->T_s

; Open workstation for plotting
  wks = gsn_open_wks(gtype,date+"-"+sims+"_Surface")

; Resources for each plot (start with HFX)
  res = True

  res@gsnMaximize      = True
  res@gsnDraw          = False
  res@gsnFrame         = False
  res@xyLineThicknessF = 3.4
  res@xyLineColor      = "black"
  res@gsnRightString   = sims
  res@gsnLeftString    = ""
  res@tiXAxisString    = "US CST"
  res@tiYAxisString    = "SH Flux (W m~S~-2~N~)"
  res@tmXBMode         = "Explicit"
  res@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

  pltscm = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      shfscm_Wm2(1:dimsizes(hwrf)-1,0),res)

  res@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      shflas_Wm2(1:dimsizes(hwrf)-1),res)

  overlay(pltscm,pltlas)

  genres                    = True
  genres@XPosPercent        = 20
  genres@YPosPercent        = 90
  lineres                   = True
  lineres@lgLineColors      = (/ "black","darkorange1" /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "SCM","LASSO" /)

  draw(pltscm)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  res@xyLineColor      = "black"
  res@tiYAxisString    = "LH Flux (W m~S~-2~N~)"

  pltscm = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      lhfscm_Wm2(1:dimsizes(hwrf)-1,0),res)

  res@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      lhflas_Wm2(1:dimsizes(hwrf)-1),res)

  overlay(pltscm,pltlas)

  draw(pltscm)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  res@xyLineColor      = "black"
  res@tiYAxisString     = "2m Air Temp (K)"

  pltscm = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      t2mscm_K(1:dimsizes(hwrf)-1,0),res)
  
  res@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hwrf(1:dimsizes(hwrf)-1), \
                      t2mlas_K(1:dimsizes(hwrf)-1),res)
  
  overlay(pltscm,pltlas)

  genres@XPosPercent        = 22
  genres@YPosPercent        = 89

  draw(pltscm)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end

