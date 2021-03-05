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
  phys  = "GFS_v16beta"
  pbl   = "MYNN" ; "satmedmf","YSU","MYNN","ACM","saYSU"
  LAS   = "LASSO"
  YYYY  = "2017"

  cloud_skill = "HI" ; "HI" for high, "MD" for medium, "LO" for low

; End user modification area
  print("Started: "+systemfunc("date"))

  topdir = "/glade/work/damico/"
  obsdir = "/glade/u/home/damico/DOE2021/OBS"+YYYY+"/"

; List all files
  if (pbl .eq. "satmedmf") then
    lsalls = systemfunc("ls "+topdir+"output_"+cloud_skill+"cloudskill_"+ \
                        LAS+"_"+YYYY)
  else
    lsalls = systemfunc("ls "+topdir+pbl+"-output_"+cloud_skill+ \
                        "cloudskill_"+LAS+"_"+YYYY)
  end if

  lsallo = systemfunc("ls "+obsdir)

  ns = dimsizes(lsalls)
  no = dimsizes(lsallo)

; Add files
  if (pbl .eq. "satmedmf") then
    simID = topdir+"output_"+cloud_skill+"cloudskill_"+LAS+"_"+YYYY+"/"+ \
            lsalls+"/"
  else
    simID = topdir+pbl+"-output_"+cloud_skill+"cloudskill_"+LAS+"_"+YYYY+"/"+ \
            lsalls+"/"
  end if

  fscm = addfiles(simID+"/output.nc","r")
  ListSetType(fscm,"join")
  fobs = addfiles(obsdir+lsallo,"r")
  ListSetType(fobs,"join")

; Times
  tscm = fscm[:]->time

  hscm = tscm
  hscm = tscm / 60. / 60.

  hobs = fobs[:]->TIME_ML

  tobs = hobs * 60. * 60.

; Observations cover the entire 24 hours, while the SCM goes from 0600-2100
; LST. Subset the times from the observations.
  obsrn = closest_val(6.,hobs(0,:))
  obsrx = closest_val(21.,hobs(0,:))

; SCM PBL height = mixed layer height
  pblhscm_all = fscm[:]->atmosphere_boundary_layer_thickness

; 2016 has one missing day of LIDAR data (30-May), so only using the dates 
; with data for the SCM
  if (YYYY .eq. "2016") then
    pblhscm_m        = new((/ no,dimsizes(pblhscm_all(0,:,0)), \
                              dimsizes(pblhscm_all(0,0,:)) /),float)
    pblhscm_m(0,:,:) = pblhscm_all(0,:,:)
    do i=1,no-1,1
      pblhscm_m(i,:,:) = pblhscm_all(i+1,:,:)
    end do
  else
    pblhscm_m = pblhscm_all
  end if

; ML Height from LIDAR
  pblhobs_all = fobs[:]->HEIGHT_ML

  pblhobs_km = pblhobs_all(:,obsrn:obsrx)

  pblhobs_m = pblhobs_km
  pblhobs_m = pblhobs_km * 1000. ; Convert to m

; Difference (model - observations)
  pblh_diff = pblhscm_m(:,:,0)
  pblh_diff = pblhscm_m(:,:,0) - tofloat(pblhobs_m)

; Start plotting
  if (pbl .eq. "satmedmf") then
    wks = gsn_open_wks(gtype,YYYY+"-MLH_Diff-"+cloud_skill+"_CS")
  else
    wks = gsn_open_wks(gtype,YYYY+"_"+pbl+"-MLH_Diff-"+cloud_skill+"_CS")
  end if

  gsn_define_colormap(wks,"MPL_bwr")

  res = True

  res@gsnMaximize              = True
  res@cnFillOn                 = True
  res@cnLinesOn                = False
  res@cnFillMode               = "RasterFill"
;  res@cnRasterSmoothingOn      = True
  res@sfXArray                 = hscm(0,:)
  res@tiYAxisString            = "Date ("+YYYY+")"
  res@tiXAxisString            = "CST"
  res@lbOrientation            = "vertical"
  res@lbBoxLinesOn             = False
  if (pbl .eq. "satmedmf") then
    res@gsnLeftString          = str_upper(pbl)+"-SCM - Obs MLH (m)"
  else
    res@gsnLeftString          = pbl+"-SCM - Obs MLH (m)"
  end if
  res@gsnRightString           = cloud_skill+" Skill"
  res@cnLevelSelectionMode     = "ManualLevels"
  res@cnMinLevelValF           = -1750.
  res@cnMaxLevelValF           = 1750.
  res@cnLevelSpacingF          = 25.
  res@tmXBMode                 = "Explicit"
  res@tmXBValues               = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues          = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels               = (/ "0600","0900","1200","1500","1800", \
                                    "2100" /)
  res@tmYLMode                 = "Explicit"
 if (YYYY .eq. "2016") then
    res@tmYLValues             = (/ 0., 1., 2., 3., 4., 5., 6., 7., 8., \
                                    9., 10.,11. /)
    res@tmYLLabels             = (/ "18-May","10-Jun","11-Jun", \
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

  plot = gsn_csm_contour(wks,pblh_diff,res)

  res@cnRasterSmoothingOn      = True
  res@tiMainString             = "SMOOTHED"

  plot = gsn_csm_contour(wks,pblh_diff,res)

  print("Complete: "+systemfunc("date"))

end

