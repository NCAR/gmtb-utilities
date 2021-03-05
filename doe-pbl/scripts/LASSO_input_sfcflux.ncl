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
  YYYY  = "2017"

  topdir = "/glade/u/home/damico/DOE2021/netcdf/"+YYYY

; End user modification area
  print("Started: "+systemfunc("date"))

  simHI = systemfunc("ls "+topdir+"HI/")
  simMD = systemfunc("ls "+topdir+"MD/")
  simLO = systemfunc("ls "+topdir+"LO/")

  fHI = addfiles(topdir+"HI/"+simHI,"r")
  fMD = addfiles(topdir+"MD/"+simMD,"r")
  fLO = addfiles(topdir+"LO/"+simLO,"r")
  ListSetType(fHI,"join")
  ListSetType(fMD,"join")
  ListSetType(fLO,"join")

  ns = dimsizes(simHI)

  sidHI = str_get_cols(simHI,6,21)
  sidMD = str_get_cols(simMD,6,21)
  sidLO = str_get_cols(simLO,6,21)

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
  presHI_Pa = fHI[:]->levels
  shfHI     = fHI[:]->sh_flux_sfc
  lhfHI     = fHI[:]->lh_flux_sfc

  np = dimsizes(presHI_Pa(0,:))

  presMD_Pa = fMD[:]->levels
  shfMD     = fMD[:]->sh_flux_sfc
  lhfMD     = fMD[:]->lh_flux_sfc

  presLO_Pa = fLO[:]->levels
  shfLO     = fLO[:]->sh_flux_sfc
  lhfLO     = fLO[:]->lh_flux_sfc

  presscm_Pa        = new((/ 3,ns,np /),float)
  presscm_Pa(0,:,:) = presHI_Pa
  presscm_Pa(1,:,:) = presMD_Pa
  presscm_Pa(2,:,:) = presLO_Pa

  shfscm_Kms        = new((/ 3,ns,nt /),float)
  shfscm_Kms(0,:,:) = shfHI
  shfscm_Kms(1,:,:) = shfMD
  shfscm_Kms(2,:,:) = shfLO

  lhfscm_kgms        = new((/ 3,ns,nt /),float)
  lhfscm_kgms(0,:,:) = lhfHI
  lhfscm_kgms(1,:,:) = lhfMD
  lhfscm_kgms(2,:,:) = lhfLO

; Choose line colors, need 3 per day
  line_colors = (/ "black","darkorange1","purple4" /)

; Open workstation for plotting
  wks = gsn_open_wks(gtype,YYYY+"-HeatFlux_KINEMATIC")

  res = True

  res@gsnMaximize           = True
  res@gsnDraw               = False
  res@gsnFrame              = False
  res@xyLineThicknessF      = 3.4
  res@tiXAxisString         = "Time (CST)"
  res@tmXBMode              = "Explicit"
  res@tmXBValues            = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues       = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels            = (/ "0600","0900","1200","1500","1800","2100" /)

  genres                    = True
  lineres                   = True
  lineres@lgLineColors      = line_colors
  lineres@lgLineThicknesses = 3.4
  textres                   = True

  do i=0,ns-1,1
    textres@lgLabels        = dateSID(:,i)
    genres@XPosPercent      = 65
    genres@YPosPercent      = 90

    res@xyLineColor         = line_colors(0)
    res@tiYAxisString       = "Sens. Heat Flux (K m s~S~-1~N~)"
    res@gsnLeftString       = "Sensible Heat Flux"
    res@gsnRightString      = "K m s~S~-1~N~"
    res@trYMinF             = min(shfscm_Kms)
    res@trYMaxF             = max(shfscm_Kms)

    plot0 = gsn_csm_xy(wks,hscm(1:nt-1),shfscm_Kms(0,i,1:nt-1),res)

    do j=1,2,1
      res@xyLineColor       = line_colors(j)

      plot = gsn_csm_xy(wks,hscm(1:nt-1),shfscm_Kms(j,i,1:nt-1),res)

      overlay(plot0,plot)
    end do

;    drawNDCGrid(wks)
    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    res@xyLineColor         = line_colors(0)
    res@tiYAxisString       = "Lat. Heat Flux (kg kg~S~-1~N~ m s~S~-1~N~)"
    res@gsnLeftString       = "Latent Heat Flux"
    res@gsnRightString      = "kg kg~S~-1~N~ m s~S~-1~N~"
    res@trYMinF             = min(lhfscm_kgms)
    res@trYMaxF             = max(lhfscm_kgms)

    plot0 = gsn_csm_xy(wks,hscm(1:nt-1),lhfscm_kgms(0,i,1:nt-1),res)

    do j=1,2,1
      res@xyLineColor    = line_colors(j)

      plot = gsn_csm_xy(wks,hscm(1:nt-1),lhfscm_kgms(j,i,1:nt-1),res)

      overlay(plot0,plot)
    end do

    genres@XPosPercent      = 65
    genres@YPosPercent      = 85

;    drawNDCGrid(wks)
    draw(plot0)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

  print("Complete: "+systemfunc("date"))

end

