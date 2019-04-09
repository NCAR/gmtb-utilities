;*************************************************
; Plots OBAR, FBAR and FBAR-OBAR in panel plot of
; seasonal averages of radiation variables
;************************************************
;
suite=getenv("SUITE")
season=getenv("SEASON")
day=getenv("DAY")
obs_file=getenv("obs_file")
fcst_file=getenv("fcst_file")
const_file=getenv("const_file")
out_dir=getenv("out_dir")

begin
;************************************************
; read in netCDF files
;************************************************
  obs = addfile(obs_file,"r")
  fcst = addfile(fcst_file,"r")
  const = addfile(const_file,"r")

  obar = obs->toa_net_all_mon_mean
  lat = obs->lat
  lon = obs->lon
  fbar1 = fcst->USWRF_TOA
  fbar2 = fcst->ULWRF_TOA
  sol = const->solar_mon_mean
  title="Top of Atmosphere Energy Balance"
  cmin = -120.
  cmax = 120.
  cint = 10.
  dmin = -50.
  dmax = 50.
  dint = 5.

  ; Compute NET TOA (SOLAR - (USWRF_TOA+ULWRF_TOA))
  ; Using solar from CERES data since model did not have solar or net toa
  fbar = sol - (fbar1 + fbar2)
  copy_VarCoords(fbar1,fbar)

  ; Compute difference field (fcst-obs)
  diff = fbar-obar
  copy_VarCoords(fbar1,diff)

  ; Compute weighted area averages across globe to be printed on plot
  jlat  = dimsizes( lat )

  rad    = 4.0*atan(1.0)/180.0
  re     = 6371220.0
  rr     = re*rad

  dlon   = abs(lon(2)-lon(1))*rr
  dx     = dlon*cos(lat*rad)

  dy     = new ( jlat, typeof(dx))

  dy(0)  = abs(lat(2)-lat(1))*rr
  dy(1:jlat-2)  = abs(lat(2:jlat-1)-lat(0:jlat-3))*rr*0.5   
  dy(jlat-1)    = abs(lat(jlat-1)-lat(jlat-2))*rr

  area   = dx*dy

  omean=wgt_areaave(obar,area,1.0,0)
  fmean=wgt_areaave(fbar,area,1.0,0)

;************************************************
; create plots
;************************************************
  wks = gsn_open_wks("png",out_dir+"/plots/CERES_"+suite+"_NET_TOA_"+season+"_"+day)
  plot = new(3,graphic)
  
  res          = True
  res@gsnDraw  = False
  res@gsnFrame = False
  res@cnFillOn = True
  res@cnInfoLabelOn = False
  res@gsnLeftString = "a) CERES"+"  (global mean: "+sprintf("%3.2f",omean)+")"
  res@lbOrientation = "Vertical"
  res@cnLabelBarEndStyle = "ExcludeOuterBoxes"
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = cmin
  res@cnMaxLevelValF       = cmax
  res@cnLevelSpacingF      = cint
  res@cnFillPalette = "BlAqGrWh2YeOrReVi22"

  plot(0) = gsn_csm_contour_map(wks,obar,res)

  res@gsnLeftString = "b) "+suite+"  (global mean: "+sprintf("%3.2f",fmean)+")"
  res@gsnRightString = "W m-2"
  res@lbLabelBarOn  = True
  plot(1) = gsn_csm_contour_map(wks,fbar(:,0:358),res) 
 
  res@gsnLeftString = "c) Difference ("+suite+"-CERES)"
  res@cnMinLevelValF = dmin
  res@cnMaxLevelValF = dmax
  res@cnLevelSpacingF = dint

  plot(2) = gsn_csm_contour_map(wks,diff(:,0:358),res)
;************************************************
; create panel
;************************************************
  resP                    = True
  resP@gsnPanelMainString = title+"~C~       Day "+day+" Mean 2016-2017"
  gsn_panel(wks,plot,(/3,1/),resP)
end
