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

  topdir = "/glade/work/damico/"

  if (pbl .eq. "satmedmf") then
    lsalls = systemfunc("ls "+topdir+"output_"+cloud_skill+"cloudskill_"+ \
                        LAS+"_"+YYYY)
  else
    lsalls = systemfunc("ls "+topdir+pbl+"-output_"+cloud_skill+ \
                        "cloudskill_"+LAS+"_"+YYYY)
  end if

  ns  = dimsizes(lsalls)

; OLD, SAVE FOR ALL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  sims    = new((/ (nfall+1)/5 /),string)
;  sims(0) = lsalls(0)
;  do i=1,(nfall/5),1
;    sims(i) = lsalls(i*5)
;  end do
;
;  rid   = ":"
;  repl  = "o"
;  simID = str_sub_str(sims,rid,repl)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  if (pbl .eq. "satmedmf") then
    simID = topdir+"output_"+cloud_skill+"cloudskill_"+LAS+"_"+YYYY+"/"+ \
            lsalls+"/"
  else
    simID = topdir+pbl+"-output_"+cloud_skill+"cloudskill_"+LAS+"_"+YYYY+"/"+ \
            lsalls+"/"
  end if

  fscm = addfiles(simID+"/output.nc","r")
  ListSetType(fscm,"join")

  tscm = fscm[:]->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.

;; SCM variables for height
;  presscm_Pa = fscm[:]->pres
;  psfcscm_Pa = fscm[:]->pres_s
;  tmpscm_K   = fscm[:]->T
;  tsfcscm_K  = fscm[:]->T_s
;  qvscm_kgkg = fscm[:]->qv

  pblhscm_m = fscm[:]->atmosphere_boundary_layer_thickness

; Start plotting
  wks = gsn_open_wks(gtype,YYYY+"-"+pbl+"_MixingLayerHgt_"+cloud_skill+"CS")

  gsn_define_colormap(wks,"MPL_Spectral")

  res = True

  res@gsnMaximize              = True
  res@cnFillOn                 = True
  res@cnLinesOn                = False
  res@sfXArray                 = hscm(0,:)
  res@tiYAxisString            = "Date ("+YYYY+")"
  res@tiXAxisString            = "CST"
  res@lbOrientation            = "vertical"
  res@lbBoxLinesOn             = False
;  res@lbBoxEndCapStyle         = "TriangleHighEnd"
  if (pbl .eq. "satmedmf") then
    res@gsnLeftString          = str_upper(pbl)+" Mixed Layer Height (m)"
  else
    res@gsnLeftString          = pbl+" Mixed Layer Height (m)"
  end if
  res@gsnRightString           = cloud_skill+" Skill"
;  res@vpWidthF                 = 0.99
;  res@vpHeightF                = 0.5
  res@cnLevelSelectionMode     = "ManualLevels"
  res@cnMinLevelValF           = 25.
  res@cnMaxLevelValF           = 3500.
  res@cnLevelSpacingF          = 25.
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
;  res@tmYLMinorValues          = (/ 0., 2., 3., 5., 6., 8., 9., 11.,12., \
;                                    14.,15.,17.,18.,20.,21.,23.,24.,26., \
;                                    27.,29.,30.,32.,33.,35.,36.,38.,39., \
;                                    41.,42.,44.,45.,47.,48.,50.,51.,53., \
;                                    54.,56.,57.,59.,60.,62.,63.,65.,66., \
;                                    68.,69.,71.,72.,74.,75.,77.,78.,80., \
;                                    81.,83. /)
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

  plot = gsn_csm_contour(wks,pblhscm_m(:,:,0),res)

end


