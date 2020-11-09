load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area, the forcing and directories will vary based on;;;;;;;
; location (for these cases, Sahara and CONUS);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  gtype = "x11"
  force = "NLDAS" ; "GLDAS" for Sahara, "NLDAS" for CONUS
  loc   = "CONUS" ; "Sahara", "CONUS" are currently the regional choices
  dirGL = force+"_2019_"+loc

  YR = "2019" ; GLDAS is only "2019", NLDAS is "2019" or "2020"
  MO = "09"   ; Choices: "08","09","10","11" NLDAS: Those and "12","01","02",
              ;                                     "03"
  DY = "01"   ; Begins on August 04, runs through November 30 (GLDAS)
              ; NLDAS begins Aug 04, runs through March 31
              ; Aug has 31 days, Sept = 30, Oct = 31, Nov = 30, Dec = 31,
              ; Jan = 31, Feb (2020) = 29, March = 31
; End user modification area;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Add first GLDAS or NLDAS file for easier time handling
  if (force .eq. "GLDAS") then
    f00 = addfile("/glade/scratch/damico/"+dirGL+ \
                  "/GLDAS_NOAH025_3H.A20190804.0000.021."+\
                  "nc4.SUB.nc4","r")
    t00 = f00->time
  end if
  if (force .eq. "NLDAS") then
    f00 = addfile("/glade/scratch/damico/"+dirGL+ \
                  "/NLDAS_NOAH0125_H.A20190804.0000.002."+ \
                  "grb.SUB.nc4","r")
    t00 = f00->time
  end if

; Add files from your selected day
  if (force .eq. "GLDAS") then
    day_of_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                    "_NOAH025_3H.A"+YR+MO+DY+".*"
  end if
  if (force .eq. "NLDAS") then
    day_of_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                    "_NOAH0125_H.A"+YR+MO+DY+".*"
  end if

  flist = systemfunc("ls "+day_of_choice)
  gf    = addfiles(flist,"r")
  ListSetType(gf,"cat")

; Gather variables
  time = gf[:]->time
  lat  = gf[0]->lat
  lon  = gf[0]->lon
  if (force .eq. "GLDAS") then
    shf = gf[:]->Qh_tavg
    lhf = gf[:]->Qle_tavg
  end if
  if (force .eq. "NLDAS") then
    shf = gf[:]->SHTFL
    lhf = gf[:]->LHTFL
  end if

  if (force .eq. "GLDAS") then
    tstar       = time
    tstar       = time - t00
    tstar@units = "minutes since 2019-08-04 00:00:00"

    hours       = tstar
    hours       = tstar / 60.
    hours@units = "hours since 2019-08-04 00:00:00"

    pd_time       = time
    pd_time       = time - time(0)
    pd_time@units = "minutes since "+YR+"-"+MO+"-"+DY+" 00:00:00"

    pd_hour       = pd_time
    pd_hour       = pd_time / 60.
    pd_hour@units = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
    pd_hour@_FillValue = 9.969209968386869e+36
  end if
  if (force .eq. "NLDAS") then
    pd_hour       = time
    pd_hour@units = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
    pd_hour@_FillValue = 9.969209968386869e+36
  end if

; Lat and lon limits (the domain does not move)
  maxlat = max(lat)
  minlat = min(lat)
  maxlon = max(lon)
  minlon = min(lon)

; Take spatial averages for entire region (Note: lat/lon regions can also be
; defined to take spatial averages of specific retions within the CONUS or 
; Sahara)
  shf_savg = dim_avg_n_Wrap(shf,(/ 1,2 /))
  lhf_savg = dim_avg_n_Wrap(lhf,(/ 1,2 /))

  shf_savg@long_name = loc+" averaged sensible heat net flux"
  lhf_savg@long_name = loc+" averaged latent heat net flux"

; Area for printing diurnal averages, maxima, and minima to screen (and new
; netCDF file, after the plotting of graphics, commented out at the moment)
  maxday_shf = max(shf)
  minday_shf = min(shf)
  maxday_lhf = max(lhf)
  minday_lhf = min(lhf)

;  maxday_shf@standard_name = shf@standard_name
  maxday_shf@long_name     = "Maximum sensible heat net flux"
  maxday_shf@units         = shf@units
  maxday_shf@_FillValue    = shf@_FillValue
  maxday_shf@missing_value = shf@missing_value
;  maxday_shf@cell_methods  = shf@cell_methods

;  minday_shf@standard_name = shf@standard_name
  minday_shf@long_name     = "Minimum sensible heat net flux"
  minday_shf@units         = shf@units
  minday_shf@_FillValue    = shf@_FillValue
  minday_shf@missing_value = shf@missing_value
;  minday_shf@cell_methods  = shf@cell_methods

;  maxday_lhf@standard_name = lhf@standard_name
  maxday_lhf@long_name     = "Maximum latent heat net flux"
  maxday_lhf@units         = lhf@units
  maxday_lhf@_FillValue    = lhf@_FillValue
  maxday_lhf@missing_value = lhf@missing_value
;  maxday_lhf@cell_methods  = lhf@cell_methods

;  minday_lhf@standard_name = lhf@standard_name
  minday_lhf@long_name     = "Minimum latent heat net flux"
  minday_lhf@units         = lhf@units
  minday_lhf@_FillValue    = lhf@_FillValue
  minday_lhf@missing_value = lhf@missing_value
;  minday_lhf@cell_methods  = lhf@cell_methods

  shdim = dimsizes(shf)
  sh1d  = ndtooned(shf)
  insmx = ind_resolve(maxind(sh1d),shdim)
  insmn = ind_resolve(minind(sh1d),shdim)

  s_time_max = insmx(0,0)
  s_lat_max  = insmx(0,1)
  s_lon_max  = insmx(0,2)

  s_time_min = insmn(0,0)
  s_lat_min  = insmn(0,1)
  s_lon_min  = insmn(0,2)

  shf_t_max    = shf&time(s_time_max)
  shf_time_max = shf_t_max
  shf_time_max = (shf_t_max - time(0)) / 60.
  shf_lat_max  = shf&lat(s_lat_max)
  shf_lon_max  = shf&lon(s_lon_max)

  shf_t_min    = shf&time(s_time_min)
  shf_time_min = shf_t_min
  shf_time_min = (shf_t_min - time(0)) / 60.
  shf_lat_min  = shf&lat(s_lat_min)
  shf_lon_min  = shf&lon(s_lon_min)

  shf_time_max@units     = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
  shf_time_max@long_name = "Time of maximum sensible heat net flux"
  shf_lat_max@long_name  = "Latitude of maximum sensible heat net flux"
  shf_lon_max@long_name  = "Longitude of maximum sensible heat net flux"

  shf_time_min@units     = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
  shf_time_min@long_name = "Time of minimum sensible heat net flux"
  shf_lat_min@long_name  = "Latitude of minimum sensible heat net flux"
  shf_lon_min@long_name  = "Longitude of minimum sensible heat net flux"

  print("Maximum SHF = "+maxday_shf+" W m-2, Time = "+pd_hour(s_time_max)+ \
        " UTC, Lat = "+lat(s_lat_max)+" degN, Lon = "+lon(s_lon_max)+" degE")
  print("Minimum SHF = "+minday_shf+" W m-2, Time = "+pd_hour(s_time_min)+ \
        " UTC, Lat = "+lat(s_lat_min)+" degN, Lon = "+lon(s_lon_min)+" degE")

  lhdim = dimsizes(lhf)
  lh1d  = ndtooned(lhf)
  inlmx = ind_resolve(maxind(lh1d),lhdim)
  inlmn = ind_resolve(minind(lh1d),lhdim)

  l_time_max = inlmx(0,0)
  l_lat_max  = inlmx(0,1)
  l_lon_max  = inlmx(0,2)

  l_time_min = inlmn(0,0)
  l_lat_min  = inlmn(0,1)
  l_lon_min  = inlmn(0,2)

  lhf_time_max = lhf&time(l_time_max)
  lhf_lat_max  = lhf&lat(l_lat_max)
  lhf_lon_max  = lhf&lon(l_lon_max)

  lhf_time_min = lhf&time(l_time_min)
  lhf_lat_min  = lhf&lat(l_lat_min)
  lhf_lon_min  = lhf&lon(l_lon_min)

  print("Maximum LHF = "+maxday_lhf+" W m-2, Time = "+pd_hour(l_time_max)+ \
        " UTC, Lat = "+lat(l_lat_max)+" degN, Lon = "+lon(l_lon_max)+" degE")
  print("Minimum LHF = "+minday_lhf+" W m-2, Time = "+pd_hour(l_time_min)+ \
        " UTC, Lat = "+lat(l_lat_min)+" degN, Lon = "+lon(l_lon_min)+" degE")

  lhf_time_max@units     = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
  lhf_time_max@long_name = "Time of maximum latent heat net flux"
  lhf_lat_max@long_name  = "Latitude of maximum latent heat net flux"
  lhf_lon_max@long_name  = "Longitude of maximum latent heat net flux"

  lhf_time_min@units     = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
  lhf_time_min@long_name = "Time of minimum latent heat net flux"
  lhf_lat_min@long_name  = "Latitude of minimum latent heat net flux"
  lhf_lon_min@long_name  = "Longitude of minimum latent heat net flux"

  if (loc .eq. "Sahara" .and. force .eq. "GLDAS") then
    t09   = closest_val(9,pd_hour)
    t18   = closest_val(18,pd_hour)
    daytm = pd_hour(t09:t18)

    day_shf = shf(t09:t18,:,:)
    day_lhf = lhf(t09:t18,:,:)

    day_shf_avg = dim_avg_n_Wrap(day_shf,0)
    day_lhf_avg = dim_avg_n_Wrap(day_lhf,0)

    ngtex = get1Dindex_Exclude(pd_hour,daytm)

    ngt_shf = shf(ngtex,:,:)
    ngt_lhf = lhf(ngtex,:,:)

    ngt_shf_avg = dim_avg_n_Wrap(ngt_shf,0)
    ngt_lhf_avg = dim_avg_n_Wrap(ngt_lhf,0)
  end if
  if (loc .eq. "CONUS" .and. force .eq. "GLDAS") then
    t03   = closest_val(3,pd_hour)
    t12   = closest_val(12,pd_hour)
    ngttm = pd_hour(t03:t12)

    ngt_shf = shf(t03:t12,:,:)
    ngt_lhf = lhf(t03:t12,:,:)

    ngt_shf_avg = dim_avg_n_Wrap(ngt_shf,0)
    ngt_lhf_avg = dim_avg_n_Wrap(ngt_lhf,0)

    dayex = get1Dindex_Exclude(pd_hour,ngttm)

    day_shf = shf(dayex,:,:)
    day_lhf = lhf(dayex,:,:)

    day_shf_avg = dim_avg_n_Wrap(day_shf,0)
    day_lhf_avg = dim_avg_n_Wrap(day_lhf,0)
  end if
  if (loc .eq. "CONUS" .and. force .eq. "NLDAS") then
    t02   = closest_val(2,pd_hour)
    t13   = closest_val(13,pd_hour)
    ngttm = pd_hour(t02:t13)

    ngt_shf = shf(t02:t13,:,:)
    ngt_lhf = lhf(t02:t13,:,:)

    ngt_shf_avg = dim_avg_n_Wrap(ngt_shf,0)
    ngt_lhf_avg = dim_avg_n_Wrap(ngt_lhf,0)

    dayex = get1Dindex_Exclude(pd_hour,ngttm)

    day_shf = shf(dayex,:,:)
    day_lhf = lhf(dayex,:,:)

    day_shf_avg = dim_avg_n_Wrap(day_shf,0)
    day_lhf_avg = dim_avg_n_Wrap(day_lhf,0)
  end if
  day_shf_avg@long_name = "Daytime averaged sensible heat net flux" 
  ngt_shf_avg@long_name = "Nighttime averaged sensible heat net flux"
  day_lhf_avg@long_name = "Daytime averaged latent heat net flux"
  ngt_lhf_avg@long_name = "Nighttime averaged latent heat net flux"

; Open workstation
  wks = gsn_open_wks(gtype,force+"_SfcFlux_"+YR+"-"+MO+"-"+DY)

; Resources for xy plots
  lres = True

  lres@gsnMaximize      = True
  lres@xyLineThicknessF = 3.4
  lres@gsnLeftString    = YR+"-"+MO+"-"+DY
  lres@gsnRightString   = force+"-"+loc
  lres@tiXAxisString    = pd_hour@units
  lres@tiYAxisString    = "Sensible Heat Net Flux (W m~S~-2~N~)"

; Plotting daily sensible and latent heat averaged over the region
  plot = gsn_csm_xy(wks,pd_hour,shf_savg,lres)

  lres@tiYAxisString    = "Latent Heat Net Flux (W m~S~-2~N~)"

  plot = gsn_csm_xy(wks,pd_hour,lhf_savg,lres)

; Resources for mapping the latent and sensible heat fluxes

  do i=0,dimsizes(time)-1,1

    gsn_define_colormap(wks,"WhiteYellowOrangeRed")

    cres = True

    cres@gsnMaximize           = True
    cres@gsnDraw               = False
    cres@gsnFrame              = False
    cres@gsnAddCyclic          = False
    cres@cnFillOn              = True
    cres@cnLinesOn             = False
    cres@gsnLeftString         = "Sensible Heat Net Flux (W m~S~-2~N~)"
    cres@gsnRightString        = pd_hour(i)+" "+pd_hour@units
    cres@tiMainString          = YR+"-"+MO+"-"+DY
    cres@mpLimitMode           = "LatLon"
    cres@mpMinLatF             = minlat - 1.
    cres@mpMinLonF             = minlon - 1.
    cres@mpMaxLatF             = maxlat + 1.
    cres@mpMaxLonF             = maxlon + 1.
    cres@mpOutlineBoundarySets = "National"
    cres@cnLevelSelectionMode  = "ManualLevels"
    cres@cnMinLevelValF        = -50.
    cres@cnMaxLevelValF        = 500.
    cres@cnLevelSpacingF       = 50.

    plot = gsn_csm_contour_map(wks,shf(i,:,:),cres)

    draw(plot)
    frame(wks)

    gsn_define_colormap(wks,"GMT_drywet")

    cres@cnMinLevelValF       = -50.
    cres@cnMaxLevelValF       = 500.
    cres@cnLevelSpacingF      = 50.
    cres@gsnLeftString        = "Latent Heat Net Flux (W m~S~-2~N~)"

    plot = gsn_csm_contour_map(wks,lhf(i,:,:),cres)

    draw(plot)
    frame(wks)

  end do

  gsn_define_colormap(wks,"WhiteYellowOrangeRed")

  avres = True

  avres@gsnMaximize           = True
  avres@gsnAddCyclic          = False
  avres@cnFillOn              = True
  avres@cnLinesOn             = False
  avres@gsnLeftString         = "Sensible Heat Net Flux (W m~S~-2~N~)"
  avres@gsnRightString        = "Avg Daytime SHF"
  avres@tiMainString          = YR+"-"+MO+"-"+DY
  avres@mpLimitMode           = "LatLon"
  avres@mpMinLatF             = minlat - 1.
  avres@mpMinLonF             = minlon - 1.
  avres@mpMaxLatF             = maxlat + 1.
  avres@mpMaxLonF             = maxlon + 1.
  avres@mpOutlineBoundarySets = "National"
  avres@cnLevelSelectionMode  = "ManualLevels"
  avres@cnMinLevelValF        = -50.
  avres@cnMaxLevelValF        = 350.
  avres@cnLevelSpacingF       = 25.

  plot = gsn_csm_contour_map(wks,day_shf_avg,avres)

  avres@gsnRightString       = "Avg Nighttime SHF"

  plot = gsn_csm_contour_map(wks,ngt_shf_avg,avres)

  gsn_define_colormap(wks,"GMT_drywet")
  avres@gsnLeftString        = "Latent Heat Net Flux (W m~S~-2~N~)"
  avres@gsnRightString       = "Avg Daytime LHF"

  plot = gsn_csm_contour_map(wks,day_lhf_avg,avres)

  avres@gsnRightString       = "Avg Nighttime LHF"

  plot = gsn_csm_contour_map(wks,ngt_lhf_avg,avres)

;; Begin writing netCDF output (note, make sure you uncomment if you want to
;; write the netCDF file, from here until [print(systemfunc("date"))])
;  setfileoption("nc","FileStructure","Advanced")
;  setfileoption("nc","Format","NetCDF4")
;  fout = force+"_TnEDiurnal_"+loc+"_"+YR+MO+DY+".nc"
;
;  system("/bin/rm -f "+fout)
;  fo = addfile(fout,"c")
;
;  fAtt               = True
;  fAtt@title         = "Diurnal SHF/LHF Averages and Maxima/Minima "+ \
;                       "from GLDAS "+YR+"-"+MO+"-"+DY+" for "+loc
;  fAtt@creation_date = systemfunc("date")
;
;; Define the dimensions, time, lat, and lon
;  dimNames = (/ "time","lat","lon" /)
;  dimSizes = (/ dimsizes(time),dimsizes(lat),dimsizes(lon) /)
;  dimUnlim = (/ True,False,False /)
;
;  filedimdef(fo,dimNames,dimSizes,dimUnlim)
;
;  filevardef(fo,"time",typeof(pd_hour),"time")
;  filevarattdef(fo,"time",pd_hour)
;  fo->time = (/ pd_hour /)
;
;  filevardef(fo,"lat",typeof(lat),"lat")
;  filevarattdef(fo,"lat",lat)
;  fo->lat = (/ lat /)
;
;  filevardef(fo,"lon",typeof(lon),"lon")
;  filevarattdef(fo,"lon",lon)
;  fo->lon = (/ lon /)
;
;; Define groups
;  grpnames = (/ "time_averages","spatial_averages","maxima","minima" /)
;  filegrpdef(fo,grpnames)
;
;  g1 = fo=>/time_averages
;  g2 = fo=>/spatial_averages
;  g3 = fo=>/maxima
;  g4 = fo=>/minima
;
;; Time averages
;  filedimdef(g1,dimNames,dimSizes,dimUnlim)
;
;  filevardef(g1,"day_shf_avg",typeof(day_shf_avg),(/ "lat","lon" /))
;  filevarattdef(g1,"day_shf_avg",day_shf_avg)
;  g1->day_shf_avg = (/ day_shf_avg /)
;
;  filevardef(g1,"day_lhf_avg",typeof(day_lhf_avg),(/ "lat","lon" /))
;  filevarattdef(g1,"day_lhf_avg",day_lhf_avg)
;  g1->day_shf_avg = (/ day_lhf_avg /)
;
;  filevardef(g1,"ngt_shf_avg",typeof(ngt_shf_avg),(/ "lat","lon" /))
;  filevarattdef(g1,"ngt_shf_avg",ngt_shf_avg)
;  g1->ngt_shf_avg = (/ ngt_shf_avg /)
;
;  filevardef(g1,"ngt_lhf_avg",typeof(ngt_lhf_avg),(/ "lat","lon" /))
;  filevarattdef(g1,"ngt_lhf_avg",ngt_lhf_avg)
;  g1->ngt_lhf_avg = (/ ngt_lhf_avg /)
;
;; Spatial averages
;  filedimdef(g2,dimNames,dimSizes,dimUnlim)
;
;  filevardef(g2,"shf_savg",typeof(shf_savg),"time")
;  filevarattdef(g2,"shf_savg",shf_savg)
;  g2->shf_savg = (/ shf_savg /)
;
;  filevardef(g2,"lhf_savg",typeof(lhf_savg),"time")
;  filevarattdef(g2,"lhf_savg",lhf_savg)
;  g2->lhf_savg = (/ lhf_savg /)
;
;; Maxima
;  filevardef(g3,"maxday_shf",typeof(maxday_shf),"ncl_scalar")
;  filevarattdef(g3,"maxday_shf",maxday_shf)
;  g3->maxday_shf = (/ maxday_shf /)
;
;  filevardef(g3,"shf_time_max",typeof(shf_time_max),"ncl_scalar")
;  filevarattdef(g3,"shf_time_max",shf_time_max)
;  g3->shf_time_max = (/ shf_time_max /)
;
;  filevardef(g3,"shf_lat_max",typeof(shf_lat_max),"ncl_scalar")
;  filevarattdef(g3,"shf_lat_max",shf_lat_max)
;  g3->shf_lat_max = (/ shf_lat_max /)
;
;  filevardef(g3,"shf_lon_max",typeof(shf_lon_max),"ncl_scalar")
;  filevarattdef(g3,"shf_lon_max",shf_lon_max)
;  g3->shf_lon_max = (/ shf_lon_max /)
;
;  filevardef(g3,"maxday_lhf",typeof(maxday_lhf),"ncl_scalar")
;  filevarattdef(g3,"maxday_lhf",maxday_lhf)
;  g3->maxday_lhf = (/ maxday_lhf /)
;
;  filevardef(g3,"lhf_time_max",typeof(lhf_time_max),"ncl_scalar")
;  filevarattdef(g3,"lhf_time_max",lhf_time_max)
;  g3->lhf_time_max = (/ lhf_time_max /)
;
;  filevardef(g3,"lhf_lat_max",typeof(lhf_lat_max),"ncl_scalar")
;  filevarattdef(g3,"lhf_lat_max",lhf_lat_max)
;  g3->lhf_lat_max = (/ lhf_lat_max /)
;
;  filevardef(g3,"lhf_lon_max",typeof(lhf_lon_max),"ncl_scalar")
;  filevarattdef(g3,"lhf_lon_max",lhf_lon_max)
;  g3->lhf_lon_max = (/ lhf_lon_max /)
;
;; Minima
;  filevardef(g4,"minday_shf",typeof(minday_shf),"ncl_scalar")
;  filevarattdef(g4,"minday_shf",minday_shf)
;  g4->minday_shf = (/ minday_shf /)
;
;  filevardef(g4,"shf_time_min",typeof(shf_time_min),"ncl_scalar")
;  filevarattdef(g4,"shf_time_min",shf_time_min)
;  g4->shf_time_min = (/ shf_time_min /)
;
;  filevardef(g4,"shf_lat_min",typeof(shf_lat_min),"ncl_scalar")
;  filevarattdef(g4,"shf_lat_min",shf_lat_min)
;  g4->shf_lat_min = (/ shf_lat_min /)
;
;  filevardef(g4,"shf_lon_min",typeof(shf_lon_min),"ncl_scalar")
;  filevarattdef(g4,"shf_lon_min",shf_lon_min)
;  g4->shf_lon_min = (/ shf_lon_min /)
;
;  filevardef(g4,"minday_lhf",typeof(minday_lhf),"ncl_scalar")
;  filevarattdef(g4,"minday_lhf",minday_lhf)
;  g4->minday_lhf = (/ minday_lhf /)
;
;  filevardef(g4,"lhf_time_min",typeof(lhf_time_min),"ncl_scalar")
;  filevarattdef(g4,"lhf_time_min",lhf_time_min)
;  g4->shf_time_min = (/ lhf_time_min /)
;
;  filevardef(g4,"lhf_lat_min",typeof(lhf_lat_min),"ncl_scalar")
;  filevarattdef(g4,"lhf_lat_min",lhf_lat_min)
;  g4->lhf_lat_min = (/ lhf_lat_min /)
;
;  filevardef(g4,"lhf_lon_min",typeof(lhf_lon_min),"ncl_scalar")
;  filevarattdef(g4,"lhf_lon_min",lhf_lon_min)
;  g4->lhf_lon_min = (/ lhf_lon_min /)
;
;  print("Created/wrote new file: "+fout)
  print(systemfunc("date"))

end

