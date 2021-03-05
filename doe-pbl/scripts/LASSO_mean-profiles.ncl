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
  LAS   = "LASSO"
  YYYY  = "2019"

  topdir = "/glade/work/damico/"

;  month_to_plot = "May" ; "May","June","July","August","September"
;  day           = "09"

;; End user modification area
;  if (month_to_plot .eq. "May") then
;    MM = "05"
;  else if (month_to_plot .eq. "June") then
;    MM = "06"
;  else if (month_to_plot .eq. "July") then
;    MM = "07"
;  else if (month_to_plot .eq. "August") then
;    MM = "08"
;  else if (month_to_plot .eq. "September") then
;    MM = "09"
;  else
;    MM = 0
;  end if
;  end if
;  end if
;  end if
;  end if

  print("Started: "+systemfunc("date"))

  dirHI = topdir+"output_HIcloudskill_"+LAS+"_"+YYYY+"/"
  dirMD = topdir+"output_MDcloudskill_"+LAS+"_"+YYYY+"/"
  dirLO = topdir+"output_LOcloudskill_"+LAS+"_"+YYYY+"/"

  simHI = systemfunc("ls "+dirHI)
  simMD = systemfunc("ls "+dirMD)
  simLO = systemfunc("ls "+dirLO)

  fHI = addfiles(dirHI+simHI+"/output.nc","r")
  fMD = addfiles(dirMD+simMD+"/output.nc","r")
  fLO = addfiles(dirLO+simLO+"/output.nc","r")
  ListSetType(fHI,"join")
  ListSetType(fMD,"join")
  ListSetType(fLO,"join")

  ns = dimsizes(simHI)

  sidHI = str_get_cols(simHI,13,28)
  sidMD = str_get_cols(simMD,13,28)
  sidLO = str_get_cols(simLO,13,28)

  dateSID      = new((/ 3,ns /),string)
  dateSID(0,:) = sidHI
  dateSID(1,:) = sidMD
  dateSID(2,:) = sidLO

  tscm = fHI[0]->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hr"

  nt = dimsizes(tscm)

; SCM variables
  presHI_Pa = fHI[:]->pres
  diffushHI = fHI[:]->atmosphere_heat_diffusivity
  diffusmHI = fHI[:]->atmosphere_momentum_diffusivity
  dT_PBLHI  = fHI[:]->dT_dt_PBL
  thflxHI   = fHI[:]->subgrid_scale_vertical_flux_of_potential_temperature
  qvflxHI   = fHI[:]->subgrid_scale_vertical_flux_of_specific_humidity
  uflxHI    = fHI[:]->subgrid_scale_vertical_flux_of_x_wind
  vflxHI    = fHI[:]->subgrid_scale_vertical_flux_of_y_wind
  tkeHI     = fHI[:]->tke
  tMLHI     = fHI[:]->turbulent_mixing_length
  udflxHI   = fHI[:]->upward_mass_flux_of_air_due_to_subgrid_scale_vertical_mixing

  np = dimsizes(presHI_Pa(0,0,:,0))

  presMD_Pa = fMD[:]->pres
  diffushMD = fMD[:]->atmosphere_heat_diffusivity
  diffusmMD = fMD[:]->atmosphere_momentum_diffusivity
  dT_PBLMD  = fMD[:]->dT_dt_PBL
  thflxMD   = fMD[:]->subgrid_scale_vertical_flux_of_potential_temperature
  qvflxMD   = fMD[:]->subgrid_scale_vertical_flux_of_specific_humidity
  uflxMD    = fMD[:]->subgrid_scale_vertical_flux_of_x_wind
  vflxMD    = fMD[:]->subgrid_scale_vertical_flux_of_y_wind
  tkeMD     = fMD[:]->tke
  tMLMD     = fMD[:]->turbulent_mixing_length
  udflxMD   = fMD[:]->upward_mass_flux_of_air_due_to_subgrid_scale_vertical_mixing

  presLO_Pa = fLO[:]->pres
  diffushLO = fLO[:]->atmosphere_heat_diffusivity
  diffusmLO = fLO[:]->atmosphere_momentum_diffusivity
  dT_PBLLO  = fLO[:]->dT_dt_PBL
  thflxLO   = fLO[:]->subgrid_scale_vertical_flux_of_potential_temperature
  qvflxLO   = fLO[:]->subgrid_scale_vertical_flux_of_specific_humidity
  uflxLO    = fLO[:]->subgrid_scale_vertical_flux_of_x_wind
  vflxLO    = fLO[:]->subgrid_scale_vertical_flux_of_y_wind
  tkeLO     = fLO[:]->tke
  tMLLO     = fLO[:]->turbulent_mixing_length
  udflxLO   = fLO[:]->upward_mass_flux_of_air_due_to_subgrid_scale_vertical_mixing

  presscm_Pa            = new((/ 3,ns,nt,np,1 /),float)
  presscm_Pa(0,:,:,:,:) = presHI_Pa
  presscm_Pa(1,:,:,:,:) = presMD_Pa
  presscm_Pa(2,:,:,:,:) = presLO_Pa

  diffushscm            = new((/ 3,ns,nt,np,1 /),float)
  diffushscm(0,:,:,:,:) = diffushHI
  diffushscm(1,:,:,:,:) = diffushMD
  diffushscm(2,:,:,:,:) = diffushLO

  diffusmscm            = new((/ 3,ns,nt,np,1 /),float)
  diffusmscm(0,:,:,:,:) = diffusmHI
  diffusmscm(1,:,:,:,:) = diffusmMD
  diffusmscm(2,:,:,:,:) = diffusmLO

  dT_PBLscm            = new((/ 3,ns,nt,np,1 /),float)
  dT_PBLscm(0,:,:,:,:) = dT_PBLHI
  dT_PBLscm(1,:,:,:,:) = dT_PBLMD
  dT_PBLscm(2,:,:,:,:) = dT_PBLLO

  thflxscm            = new((/ 3,ns,nt,np,1 /),float)
  thflxscm(0,:,:,:,:) = thflxHI
  thflxscm(1,:,:,:,:) = thflxMD
  thflxscm(2,:,:,:,:) = thflxLO

  qvflxscm            = new((/ 3,ns,nt,np,1 /),float)
  qvflxscm(0,:,:,:,:) = qvflxHI
  qvflxscm(1,:,:,:,:) = qvflxMD
  qvflxscm(2,:,:,:,:) = qvflxLO

  uflxscm            = new((/ 3,ns,nt,np,1 /),float)
  uflxscm(0,:,:,:,:) = uflxHI
  uflxscm(1,:,:,:,:) = uflxMD
  uflxscm(2,:,:,:,:) = uflxLO

  vflxscm            = new((/ 3,ns,nt,np,1 /),float)
  vflxscm(0,:,:,:,:) = vflxHI
  vflxscm(1,:,:,:,:) = vflxMD
  vflxscm(2,:,:,:,:) = vflxLO

  tkescm            = new((/ 3,ns,nt,np,1 /),float)
  tkescm(0,:,:,:,:) = tkeHI
  tkescm(1,:,:,:,:) = tkeMD
  tkescm(2,:,:,:,:) = tkeLO

  tMLscm            = new((/ 3,ns,nt,np,1 /),float)
  tMLscm(0,:,:,:,:) = tMLHI
  tMLscm(1,:,:,:,:) = tMLMD
  tMLscm(2,:,:,:,:) = tMLLO

  udflxscm            = new((/ 3,ns,nt,np,1 /),float)
  udflxscm(0,:,:,:,:) = udflxHI
  udflxscm(1,:,:,:,:) = udflxMD
  udflxscm(2,:,:,:,:) = udflxLO

; Average over the time dimension for each individual simulation
  presscm = dim_avg_n_Wrap(presscm_Pa,2)
  diffush = dim_avg_n_Wrap(diffushscm,2)
  diffusm = dim_avg_n_Wrap(diffusmscm,2)
  dT_PBL  = dim_avg_n_Wrap(dT_PBLscm,2)
  thflx   = dim_avg_n_Wrap(thflxscm,2)
  qvflx   = dim_avg_n_Wrap(qvflxscm,2)
  uflx    = dim_avg_n_Wrap(uflxscm,2)
  vflx    = dim_avg_n_Wrap(vflxscm,2)
  tke     = dim_avg_n_Wrap(tkescm,2)
  tML     = dim_avg_n_Wrap(tMLscm,2)
  udflx   = dim_avg_n_Wrap(udflxscm,2)

; Convert pressure to hPa
  presscm_hPa = presscm
  presscm_hPa = presscm / 100.

  presscm_hPa@units = "hPa"

; Define a pressure minima (height max) to make plots look better
  p65 = closest_val(650.,presscm_hPa(0,0,:,0))

; Choose line colors, need 3 per day
  line_colors = (/ "black","darkorange1","purple4" /)

; Open workstation for plotting
  wks = gsn_open_wks(gtype,YYYY+"-Mean_Profiles")

  res = True

  res@gsnMaximize      = True
  res@gsnDraw          = False
  res@gsnFrame         = False
  res@xyLineThicknessF = 3.4
  res@trYReverse       = True
  res@tiYAxisString    = "Pressure (hPa)"
  res@trYMinF          = 650.

  genres                    = True
  genres@XPosPercent        = 67
  genres@YPosPercent        = 90
  lineres                   = True
  lineres@lgLineColors      = line_colors
  lineres@lgLineThicknesses = 3.4
  textres                   = True

  do i=0,ns-1,1
    res@xyLineColor    = line_colors(0)
    res@tiXAxisString  = "Mean dT_dt_PBL"
    res@gsnLeftString  = dT_PBL@description
    res@gsnRightString = "K s~S~-1~N~"
    res@trXMinF        = min(dT_PBL)
    res@trXMaxF        = max(dT_PBL)
    textres@lgLabels   = dateSID(:,i)

    plot0 = gsn_csm_xy(wks,dT_PBL(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,dT_PBL(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

;    drawNDCGrid(wks)
    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = diffush@description
    res@gsnRightString        = "m~S~2~N~ s~S~-1~N~"
    res@tiXAxisString         = "Mean diffusivity for heat"
    res@trXMinF               = min(diffush)
    res@trXMaxF               = max(diffush)
    res@xyLineColor           = line_colors(0)

   plot0 = gsn_csm_xy(wks,diffush(0,i,0:p65(0),0), \
                      presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,diffush(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    genres@XPosPercent        = 66
    genres@YPosPercent        = 90

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = diffusm@description
    res@gsnRightString        = "m~S~2~N~ s~S~-1~N~"
    res@tiXAxisString         = "Mean diffusivity for momentum"
    res@trXMinF               = min(diffusm)
    res@trXMaxF               = max(diffusm)
    res@xyLineColor           = line_colors(0)

    plot0 = gsn_csm_xy(wks,diffusm(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,diffusm(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = "SGS Vert ~F33~q~F21~ Flux"
    res@gsnRightString        = "K m s~S~-1~N~"
    res@tiXAxisString         = "Mean vert ~F33~q~F21~ flux"
    res@trXMinF               = min(thflx)
    res@trXMaxF               = max(thflx)
    res@xyLineColor           = line_colors(0)

    plot0 = gsn_csm_xy(wks,thflx(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,thflx(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = "SGS Vert q~B~v~N~ Flux"
    res@gsnRightString        = "kg kg~S~-1~N~ m s~S~-1~N~"
    res@tiXAxisString         = "Mean vert q~B~v~N~ flux"
    res@trXMinF               = min(qvflx) 
    res@trXMaxF               = max(qvflx) 
    res@xyLineColor           = line_colors(0)
  
    plot0 = gsn_csm_xy(wks,qvflx(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)
  
    do j=1,2,1
      res@xyLineColor    = line_colors(j)
    
      plot = gsn_csm_xy(wks,qvflx(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)
                      
      overlay(plot0,plot)
    end do

    genres@XPosPercent        = 65
    genres@YPosPercent        = 88

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = "SGS Vert x-wind Flux"
    res@gsnRightString        = "m~S~2~N~ s~S~-2~N~"
    res@tiXAxisString         = "Mean x-wind flux"
    res@trXMinF               = min(uflx)
    res@trXMaxF               = max(uflx)
    res@xyLineColor           = line_colors(0)

    plot0 = gsn_csm_xy(wks,uflx(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,uflx(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    genres@XPosPercent        = 22
    genres@YPosPercent        = 90

;    drawNDCGrid(wks)
    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = "SGS Vert y-wind Flux"
    res@gsnRightString        = "m~S~2~N~ s~S~-2~N~"
    res@tiXAxisString         = "Mean y-wind flux"
    res@trXMinF               = min(vflx)
    res@trXMaxF               = max(vflx)
    res@xyLineColor           = line_colors(0)

    plot0 = gsn_csm_xy(wks,vflx(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,vflx(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    genres@XPosPercent        = 66
    genres@YPosPercent        = 89

    res@gsnLeftString         = "SGS vertical mass flux"
    res@gsnRightString        = "kg m~S~2~N~ s~S~-1~N~"
    res@tiXAxisString         = "Mean SGS vertical mass flux"
    res@trXMinF               = min(udflx)
    res@trXMaxF               = max(udflx)
    res@xyLineColor           = line_colors(0)

    plot0 = gsn_csm_xy(wks,udflx(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,udflx(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@gsnLeftString         = "TKE" 
    res@gsnRightString        = "m~S~2~N~ s~S~-2~N~"
    res@tiXAxisString         = "Mean TKE"
    res@trXMinF               = min(tke)
    res@trXMaxF               = max(tke)
    res@xyLineColor           = line_colors(0)

    if (YYYY .eq. "2017") then
      res@tmXBMode            = "Explicit"
      res@tmXBValues          = (/ 0.5,1.0,1.5,2.0,2.5,3.0 /)
      res@tmXBMinorValues     = (/ 0.1,0.2,0.3,0.4,0.6,0.7,0.8,0.9,1.1,1.2, \
                                   1.3,1.4,1.6,1.7,1.8,1.9,2.1,2.2,2.3,2.4, \
                                   2.6,2.7,2.8,2.9,3.1,3.2,3.3,3.4 /)
      res@tmXBLabels          = (/ "0.5","1.0","1.5","2.0","2.5","3.0" /)
    end if
    if (YYYY .eq. "2019") then
      res@tmXBMode            = "Explicit"
      res@tmXBValues          = (/ 0.0,1.0,2.0,3.0,4.0 /)
      res@tmXBMinorValues     = (/ 0.2,0.4,0.6,0.8,1.2,1.4,1.6,1.8,2.2,2.4, \
                                   2.6,2.8,3.2,3.4,3.6,3.8,4.2,4.4 /)
      res@tmXBLabels          = (/ "0.0","1.0","2.0","3.0","4.0" /)
    end if

    plot0 = gsn_csm_xy(wks,tke(0,i,0:p65(0),0), \
                       presscm_hPa(0,i,0:p65(0),0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,tke(j,i,0:p65(0),0), \
                        presscm_hPa(j,i,0:p65(0),0),res)

      overlay(plot0,plot)
    end do

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)
  end do

  print("Complete: "+systemfunc("date"))

end

