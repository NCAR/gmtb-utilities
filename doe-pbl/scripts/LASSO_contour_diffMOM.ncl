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

  cloud_skill = "HI" ; "HI" for high skill, "MD" for medium, "LO" for low

  topdir = "/glade/work/damico/"
  scmdir = "output_"+cloud_skill+"cloudskill_"+LAS+"_"+YYYY+"/"

; End user modification area
  print("Started: "+systemfunc("date"))

  sims = systemfunc("ls "+topdir+scmdir)
  ns   = dimsizes(sims)

  fscm = addfiles(topdir+scmdir+sims+"/output.nc","r")
  ListSetType(fscm,"join")

  dateSID = str_get_cols(sims,13,28)

; Time
  tscm = fscm[0]->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hr"

; SCM variables
  presscm_Pa = fscm[:]->pres
  diffMOM    = fscm[:]->atmosphere_momentum_diffusivity

; Convert pressure to hPa
  presscm_hPa = presscm_Pa
  presscm_hPa = presscm_Pa / 100.

  presscm_hPa@units = "hPa"

  dp  = dimsizes(presscm_hPa)
  p1d = ndtooned(presscm_hPa)
  pxi = ind_resolve(maxind(p1d),dp)

  isim = pxi(0,0)
  itim = pxi(0,1)
  iprs = pxi(0,2)
  ihrz = pxi(0,3)

; Reverse the order of the dimensions to plot with pressure on y-axis
  diffMOM_m2s = diffMOM(ncl_join|:,vert_dim_layer|:,time_dim|:, \
                        hor_dim_layer|:)

; Define a pressure minima (height max) to make plots look better
  p65 = closest_val(650.,presscm_hPa(0,0,:,0))

; Open workstation for plotting
  wks = gsn_open_wks(gtype,LAS+"-"+cloud_skill+"_Contour_diffMOM")

  gsn_define_colormap(wks,"precip3_16lev")

  res = True

  res@gsnMaximize          = True
  res@cnFillOn             = True
  res@cnLinesOn            = False
  res@sfYArray             = presscm_hPa(isim,itim,iprs:p65(0),0)
  res@sfXArray             = hscm
  res@trYReverse           = True
  res@tiYAxisString        = "Pressure (hPa)"
  res@tiXAxisString        = "CST"
  res@tiMainString         = cloud_skill+" Cld Skill"
  res@gsnLeftString        = "~F33~m~F21~ (m~S~2~N~ s~S~-1~N~)"
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF       = 15.
  res@cnMaxLevelValF       = 210.
  res@cnLevelSpacingF      = 15.
  res@tmXBMode             = "Explicit"
  res@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)

  do i=0,ns-1,1
    res@gsnRightString = dateSID(i)

    plot = gsn_csm_contour(wks,diffMOM_m2s(i,0:p65(0),:,0),res)
  end do

  print("Complete: "+systemfunc("date"))

end

