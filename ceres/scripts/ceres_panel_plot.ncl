;*************************************************
; Plots OBAR, FBAR and FBAR-OBAR in panel plot of
; seasonal averages of radiation variables
;************************************************
;
suite=getenv("SUITE")
var=getenv("VAR")
season=getenv("SEASON")
day=getenv("DAY")
obs_file=getenv("obs_file")
fcst_file=getenv("fcst_file")
out_dir=getenv("out_dir")

begin
;************************************************
; read in netCDF files
;************************************************
obs = addfile(obs_file,"r")
fcst = addfile(fcst_file,"r")

if (var .eq. "DSWRF") then
  obar = obs->sfc_sw_down_all_mon_mean
  fbar = fcst->DSWRF
  title="Surface Downward Shortwave"
  cmin = 0.
  cmax = 400.
  cint = 20.
  dmin = -100.
  dmax = 100.
  dint = 10.
else if (var .eq. "USWRF") then
  obar = obs->sfc_sw_up_all_mon_mean
  fbar = fcst->USWRF
  title="Surface Upward Shortwave"
  cmin = 0.
  cmax = 300.
  cint = 10.
  dmin = -100.
  dmax = 100.
  dint = 10.
else if (var .eq. "DLWRF") then
  obar = obs->sfc_lw_down_all_mon_mean
  fbar = fcst->DLWRF
  title="Surface Downward Longwave"
  cmin = 50.
  cmax = 500.
  cint = 20.
  dmin = -50.
  dmax = 50.
  dint = 5.
else if (var .eq. "ULWRF") then
  obar = obs->sfc_lw_up_all_mon_mean
  fbar = fcst->ULWRF
  title="Surface Upward Longwave"
  cmin = 100.
  cmax = 500.
  cint = 20.
  dmin = -50.
  dmax = 50.
  dint = 5.
else if (var .eq. "USWRF_TOA") then
  obar = obs->toa_sw_all_mon_mean
  fbar = fcst->USWRF_TOA
  title="Top of Atmosphere Shortwave"
  cmin = 0.
  cmax = 340.
  cint = 10.
  dmin = -100.
  dmax = 100.
  dint = 10.
else if (var .eq. "ULWRF_TOA") then
  title="Top of Atmosphere Longwave"
  obar = obs->toa_lw_all_mon_mean
  fbar = fcst->ULWRF_TOA
  cmin = 100.
  cmax = 360.
  cint = 10.
  dmin = -100.
  dmax = 100.
  dint = 10.
end if
end if
end if
end if
end if
end if

  diff = fbar-obar
  copy_VarCoords(fbar,diff)

;************************************************
; create plots
;************************************************
  wks = gsn_open_wks("png",out_dir+"/plots/CERES_"+suite+"_"+var+"_"+season+"_"+day)
  plot = new(3,graphic)
  
  res          = True
  res@gsnDraw  = False
  res@gsnFrame = False
  res@cnFillOn = True
  res@cnInfoLabelOn = False
  res@gsnLeftString = "a) CERES"
  res@lbOrientation = "Vertical"
  res@cnLabelBarEndStyle = "ExcludeOuterBoxes"
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = cmin
  res@cnMaxLevelValF       = cmax
  res@cnLevelSpacingF      = cint
  res@cnFillPalette = "BlAqGrYeOrReVi200"

  plot(0) = gsn_csm_contour_map(wks,obar,res)

  res@gsnLeftString = "b) "+suite
  res@gsnRightString = "W m-2"
  res@lbLabelBarOn  = True
  plot(1) = gsn_csm_contour_map(wks,fbar(:,0:358),res) 
 
  res@gsnLeftString = "c) Difference ("+suite+"-CERES)"
  res@cnMinLevelValF = dmin
  res@cnMaxLevelValF = dmax
  res@cnLevelSpacingF = dint
  res@cnFillPalette = "BlAqGrWh2YeOrReVi22"

  plot(2) = gsn_csm_contour_map(wks,diff(:,0:358),res)
;************************************************
; create panel
;************************************************
  resP                    = True
  resP@gsnPanelMainString = title+"~C~          Day "+day+" Mean "+season
  gsn_panel(wks,plot,(/3,1/),resP)
end
