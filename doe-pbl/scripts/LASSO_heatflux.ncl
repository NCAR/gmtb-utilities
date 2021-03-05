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
  YYYY  = "2017"

  topdir = "/glade/work/damico/"

; End user modification area
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
  shfHI     = fHI[:]->shf
  lhfHI     = fHI[:]->lhf

  np = dimsizes(presHI_Pa(0,0,:,0))

  presMD_Pa = fMD[:]->pres
  shfMD     = fMD[:]->shf
  lhfMD     = fMD[:]->lhf

  presLO_Pa = fLO[:]->pres
  shfLO     = fLO[:]->shf
  lhfLO     = fLO[:]->lhf

  presscm_Pa            = new((/ 3,ns,nt,np,1 /),float)
  presscm_Pa(0,:,:,:,:) = presHI_Pa
  presscm_Pa(1,:,:,:,:) = presMD_Pa
  presscm_Pa(2,:,:,:,:) = presLO_Pa

  shfscm_Wm2          = new((/ 3,ns,nt,1 /),float)
  shfscm_Wm2(0,:,:,:) = shfHI
  shfscm_Wm2(1,:,:,:) = shfMD
  shfscm_Wm2(2,:,:,:) = shfLO

  lhfscm_Wm2          = new((/ 3,ns,nt,1 /),float)
  lhfscm_Wm2(0,:,:,:) = lhfHI
  lhfscm_Wm2(1,:,:,:) = lhfMD
  lhfscm_Wm2(2,:,:,:) = lhfLO

; Convert pressure to hPa
  presscm_hPa = presscm_Pa
  presscm_hPa = presscm_Pa / 100.

  presscm_hPa@units = "hPa"

; Define a pressure minima (height max) to make plots look better
  p65 = closest_val(650.,presscm_hPa(0,0,0,:,0))

; Choose line colors, need 3 per day
  line_colors = (/ "black","darkorange1","purple4" /)

; Open workstation for plotting
  wks = gsn_open_wks(gtype,YYYY+"-HeatFlux")

  res = True

  res@gsnMaximize      = True
  res@gsnDraw          = False
  res@gsnFrame         = False
  res@xyLineThicknessF = 3.4
  res@tiXAxisString    = "Time (CST)"
  res@trYMinF          = 650.
  res@tmXBMode         = "Explicit"
  res@tmXBValues       = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues  = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels       = (/ "0600","0900","1200","1500","1800","2100" /)

  genres                    = True
  genres@XPosPercent        = 65
  genres@YPosPercent        = 90
  lineres                   = True
  lineres@lgLineColors      = line_colors
  lineres@lgLineThicknesses = 3.4
  textres                   = True

  do i=0,ns-1,1
    textres@lgLabels        = dateSID(:,i)

    res@xyLineColor    = line_colors(0)
    res@tiYAxisString  = "Sens. Heat Flux (W m~S~-2~N~)"
    res@gsnLeftString  = "Sensible Heat Flux"
    res@gsnRightString = "W m~S~-2~N~"
    res@trYMinF        = min(shfscm_Wm2)
    res@trYMaxF        = max(shfscm_Wm2)

    plot0 = gsn_csm_xy(wks,hscm(1:nt-1),shfscm_Wm2(0,i,1:nt-1,0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,hscm(1:nt-1),shfscm_Wm2(j,i,1:nt-1,0),res)

      overlay(plot0,plot)
    end do

;    drawNDCGrid(wks)
    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@xyLineColor    = line_colors(0)
    res@tiYAxisString  = "Lat. Heat Flux (W m~S~-2~N~)"
    res@gsnLeftString  = "Latent Heat Flux"
    res@gsnRightString = "W m~S~-2~N~"
    res@trYMinF        = 0.   ; min(lhfscm_Wm2)
    res@trYMaxF        = 400. ; max(lhfscm_Wm2)

    plot0 = gsn_csm_xy(wks,hscm(1:nt-1),lhfscm_Wm2(0,i,1:nt-1,0),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,hscm(1:nt-1),lhfscm_Wm2(j,i,1:nt-1,0),res)

      overlay(plot0,plot)
    end do

    genres@XPosPercent      = 65
    genres@YPosPercent      = 89

    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

  print("Complete: "+systemfunc("date"))

end

