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
  phys  = "GFS_v16beta"
  LAS   = "LASSO"
  YYYY  = "2019"

  topdir = "/glade/work/damico/"

; End user modification area
  print("Started: "+systemfunc("date"))

  lsHI = systemfunc("ls "+topdir+"output_HIcloudskill_"+ \
                    LAS+"_"+YYYY)
  lsMD = systemfunc("ls "+topdir+"output_MDcloudskill_"+ \
                    LAS+"_"+YYYY)
  lsLO = systemfunc("ls "+topdir+"output_LOcloudskill_"+ \
                    LAS+"_"+YYYY)

  ns  = dimsizes(lsHI)

  simHI = topdir+"output_HIcloudskill_"+LAS+"_"+YYYY+"/"+lsHI
  simMD = topdir+"output_MDcloudskill_"+LAS+"_"+YYYY+"/"+lsMD
  simLO = topdir+"output_LOcloudskill_"+LAS+"_"+YYYY+"/"+lsLO

  fHI = addfiles(simHI+"/output.nc","r")
  ListSetType(fHI,"join")
  fMD = addfiles(simMD+"/output.nc","r")
  ListSetType(fMD,"join")
  fLO = addfiles(simLO+"/output.nc","r")
  ListSetType(fLO,"join")

  tscm = fHI[0]->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hours since start of simulation"

  pblhHI_m = fHI[:]->atmosphere_boundary_layer_thickness
  pblhMD_m = fMD[:]->atmosphere_boundary_layer_thickness
  pblhLO_m = fLO[:]->atmosphere_boundary_layer_thickness

  pblh_dfMD = pblhMD_m
  pblh_dfMD = pblhMD_m - pblhHI_m
  pblh_dfLO = pblhLO_m
  pblh_dfLO = pblhLO_m - pblhHI_m

; Start plotting
  wks = gsn_open_wks(gtype,YYYY+"-"+LAS+"_MLH_Diff")
  gsn_define_colormap(wks,"MPL_bwr")

  res = True

  res@gsnMaximize              = True
  res@cnFillOn                 = True
  res@cnLinesOn                = False
  res@sfXArray                 = hscm
  res@tiYAxisString            = "Date ("+YYYY+")"
  res@tiXAxisString            = "CST"
  res@lbOrientation            = "vertical"
  res@lbBoxLinesOn             = False
  res@gsnLeftString            = "Mixed Layer Height (m)"
  res@gsnRightString           = "MD - HI"
  res@cnLevelSelectionMode     = "ManualLevels"
  res@cnMinLevelValF           = -2800.
  res@cnMaxLevelValF           = 2800.
  res@cnLevelSpacingF          = 50.
  res@tmXBMode                 = "Explicit"
  res@tmXBValues               = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues          = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels               = (/ "0600","0900","1200","1500","1800", \
                                    "2100" /)
  res@tmYLMode                 = "Explicit"
  if (YYYY .eq. "2016") then
    res@tmYLValues             = (/ 0., 1., 2., 3., 4., 5., 6., 7., 8., \
                                    9., 10.,11.,12. /)
    res@tmYLLabels             = (/ "18-May","30-May","10-Jun","11-Jun", \
                                    "14-Jun","19-Jun","25-Jun","16-Jul", \
                                    "19-Jul","20-Jul","18-Aug","19-Aug", \
                                    "30-Aug" /)
  else if (YYYY .eq. "2017") then
    res@tmYLValues             = (/ 0.,  1., 2., 3., 4., 5., 6., 7., 8., \
                                    9., 10.,11.,12.,13.,14.,15.,16.,17., \
                                    18.,19.,20.,21.,22.,23.,24.,25.,26., \
                                    27. /)
    res@tmYLLabels             = (/ "09-May","24-May","27-May","05-Jun", \
                                    "09-Jun","14-Jun","26-Jun","27-Jun", \
                                    "29-Jun","30-Jun","04-Jul","05-Jul", \
                                    "09-Jul","12-Jul","16-Jul","17-Jul", \
                                    "19-Jul","20-Jul","21-Jul","25-Jul", \
                                    "28-Jul","02-Aug","26-Aug","28-Aug", \
                                    "30-Aug","22-Sep","23-Sep","24-Sep" /)
  else if (YYYY .eq. "2018") then
    res@tmYLValues             = (/ 0.,  1., 2., 3., 4., 5., 6., 7., 8., \
                                    9., 10.,11.,12.,13.,14.,15.,16.,17., \
                                    18.,19.,20.,21.,22.,23.,24.,25.,26., \
                                    27. /)
    res@tmYLLabels             = (/ "14-May","22-May","23-May","29-May", \
                                    "30-May","31-May","06-Jun","18-Jun", \
                                    "19-Jun","04-Jul","05-Jul","07-Jul", \
                                    "09-Jul","10-Jul","11-Jul","12-Jul", \
                                    "31-Jul","05-Aug","09-Aug","11-Aug", \
                                    "01-Sep","02-Sep","09-Sep","11-Sep", \
                                    "14-Sep","16-Sep","17-Sep","18-Sep" /)
  else if (YYYY .eq. "2019") then
    res@tmYLValues             = (/ 0.,  1., 2., 3., 4., 5., 6., 7., 8., \
                                    9., 10.,11.,12.,13.,14. /)
    res@tmYLLabels             = (/ "12-May","17-May","07-Jun","12-Jun", \
                                    "17-Jun","26-Jun","01-Jul","04-Jul", \
                                    "07-Jul","09-Jul","14-Jul","04-Aug", \
                                    "05-Aug","01-Sep","29-Sep" /)
  end if
  end if
  end if
  end if

  plot = gsn_csm_contour(wks,pblh_dfMD(:,:,0),res)

  res@gsnRightString           = "LO - HI"

  plot = gsn_csm_contour(wks,pblh_dfLO(:,:,0),res)

  print("Complete: "+systemfunc("date"))

end

