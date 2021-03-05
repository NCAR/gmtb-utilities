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

  cloud_skill = "HI" ; "HI" for high, "MD" for medium, "LO" for low

  topdir = "/glade/work/damico/"

; End User Modification Area
  print("Started: "+systemfunc("date"))
; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)

  lsalls = systemfunc("ls "+topdir+"output_"+cloud_skill+"cloudskill_"+ \
                      LAS+"_"+YYYY)
  ns  = dimsizes(lsalls)

  simID = topdir+"output_"+cloud_skill+"cloudskill_"+LAS+"_"+YYYY+"/"+ \
          lsalls+"/"

  fscm = addfiles(simID+"/output.nc","r")
  ListSetType(fscm,"join")

; Time
  tscm = fscm[0]->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.

  nt = dimsizes(hscm)

; SCM variables
  presscm_Pa = fscm[:]->pres
  psfcscm_Pa = fscm[:]->pres_s
  tmpscm_K   = fscm[:]->T
  tsfcscm_K  = fscm[:]->T_s
  qvscm_kgkg = fscm[:]->qv
  pblhscm_m  = fscm[:]->atmosphere_boundary_layer_thickness

; Find SCM height (not an SCM output variable, use hypsometric equation)
; Start with whole atmosphere virtual temperature
  tv = tmpscm_K
  tv = tmpscm_K * ((1 + (qvscm_kgkg / (R_dry/R_vap))) / \
                  (1 + qvscm_kgkg))

  tv@description = "virtual temperature"

; Surface virtual temperature
  tvs = tsfcscm_K
  tvs = tsfcscm_K *((1 + (qvscm_kgkg(:,:,0,:) / (R_dry/R_vap))) / \
                   (1 + qvscm_kgkg(:,:,0,:)))

  tvs@description = "surface virtual temperature"

; Height of level 0
  z0   = (((R_dry * tvs) / g) * log(psfcscm_Pa / presscm_Pa(:,:,0,:)))
  z0!0 = "ncl_join"
  z0!1 = "time_dim"
  z0!2 = "hor_dim_layer"

; Use hypsometric equation, with height at level 0, to find full model height
  hgtscm_m        = new((/ dimsizes(presscm_Pa(:,:,:,0)) /),float)
  hgtscm_m(:,:,0) = z0(:,:,0)
  do i=1,dimsizes(hgtscm_m(0,0,:))-1,1
    hgtscm_m(:,:,i) = hgtscm_m(:,:,i-1) + (((R_dry * tv(:,:,i,0)) / g) * \
                      log(presscm_Pa(:,:,i-1,0) / presscm_Pa(:,:,i,0)))
  end do
  hgtscm_m!2           = "vert_dim_layer"
  hgtscm_m@description = "model height"
  hgtscm_m@units       = "m"

; SCM temperature to potential temperature
  thtscm_K = tmpscm_K
  thtscm_K = tmpscm_K * ((P00 / presscm_Pa)^(R_dry / c_p))

  thtscm_K@description = "potential temperature"

; 1.5-theta-increase method to determine PBL height (Nielsen-Gammon et al.
; 2008; Hu et al. 2010). Most accurate in a convective boundary layer,
; so when things are very stable and the PBL is shallow, this method
; might not be ideal.
  minthtscm_K = new((/ ns,nt /),float)
  mindimscm   = new((/ ns,nt /),integer)
  thtscm_1_5K = new((/ ns,nt /),float)
  vs1_5       = new((/ ns,nt /),integer)
  pblhscm_md2 = new((/ ns,nt /),float)
  do i=0,ns-1,1
    do j=0,nt-1,1
      minthtscm_K(i,j) = min(thtscm_K(i,j,:,0))
      mindimscm(i,j)   = minind(thtscm_K(i,j,:,0))
      thtscm_1_5K(i,j) = minthtscm_K(i,j) + 1.5
      vs1_5(i,j)       = closest_val(thtscm_1_5K(i,j),thtscm_K(i,j,:,0))
      if (vs1_5(i,j) .lt. mindimscm(i,j)) then
         vs1_5(i,j)    = closest_val(thtscm_1_5K(i,j), \
                                     thtscm_K(i,j,mindimscm(i,j):126,0))
      end if
      pblhscm_md2(i,j) = hgtscm_m(i,j,vs1_5(i,j))
    end do
  end do

; PBLH or MLH anomaly (model calculated minus user calculated)
  pblh_df = pblhscm_m(:,:,0)
  pblh_df = pblhscm_m(:,:,0) - pblhscm_md2  

; Start plotting
  wks = gsn_open_wks(gtype,YYYY+"_MixingLayers_"+cloud_skill+"CS")

  gsn_define_colormap(wks,"MPL_Spectral")

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
  res@gsnRightString           = cloud_skill+" Skill"
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

  res@gsnLeftString            = "1.5-~F33~q~F21~ Increase PBLH (m)"

  plot = gsn_csm_contour(wks,pblhscm_md2,res)

  gsn_define_colormap(wks,"MPL_bwr")

  res@gsnLeftString            = "Model Calc - 1.5-~F33~q~F21~ MLH (m)"
  res@cnLevelSelectionMode     = "ManualLevels"
  res@cnMinLevelValF           = -2800.
  res@cnMaxLevelValF           = 2800.
  res@cnLevelSpacingF          = 50.

  plot = gsn_csm_contour(wks,pblh_df,res)

  print("Complete: "+systemfunc("date"))

end 

