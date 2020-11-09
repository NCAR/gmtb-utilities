load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area, the forcing and directories will vary based on;;;;;;;
; location (for these cases, Sahara and CONUS);;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  gtype = "x11"
  force = "GLDAS" ; "GLDAS" for Sahara and CONUS
  loc   = "Sahara" ; "Sahara", "CONUS" are currently the regional choices
  dirGL = force+"_TAIR_"+loc

  YR = "2019" ; GLDAS is only "2019" or "2020"
  MO = "09"   ; Choices: "08","09","10","11","12" (2019)
              ;          "01","02" (2020)                           
  DY = "01"   ; Begins on August 04, runs through February 29 (GLDAS)
              ; Aug has 31 days, Sept = 30, Oct = 31, Nov = 30, Dec = 31,
              ; Jan = 31, Feb (2020) = 29

  unit_of_choice = "C" ; "K" (Kelvin) or "C" (celcius)
; End user modification area;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Add first GLDAS or NLDAS file for easier time handling (NLDAS is not 
; currently being utilized, it has no air temperature variable)
  if (force .eq. "GLDAS") then
    f00 = addfile("/glade/scratch/damico/"+dirGL+ \
                  "/GLDAS_NOAH025_3H.A20190804.0000.021."+\
                  "nc4.SUB.nc4","r")
    t00 = f00->time
  end if

; Add files from your selected day
  if (force .eq. "GLDAS") then
    day_of_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                    "_NOAH025_3H.A"+YR+MO+DY+".*"
  end if

  flist = systemfunc("ls "+day_of_choice)
  gf    = addfiles(flist,"r")
  ListSetType(gf,"cat")

; Gather variables
  time = gf[:]->time
  lat  = gf[0]->lat
  lon  = gf[0]->lon
  if (force .eq. "GLDAS") then
    tmp = gf[:]->Tair_f_inst
    if (unit_of_choice .eq. "C") then
      tmp       = tmp
      tmp       = tmp - 273.15
      tmp@units = unit_of_choice
    end if
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

    pd_hour            = pd_time
    pd_hour            = pd_time / 60.
    pd_hour@units      = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
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
  T_savg           = dim_avg_n_Wrap(tmp,(/ 1,2 /))
  T_savg@long_name = loc+" averaged air temperature"

; Area for printing diurnal averages, maxima, and minima to screen (and new
; netCDF file, after the plotting of graphics, commented out at the moment)
  maxday_T = max(tmp)
  minday_T = min(tmp)

  maxday_T@long_name     = "Maximum air temperature"
  maxday_T@units         = tmp@units
  maxday_T@_FillValue    = tmp@_FillValue
  maxday_T@missing_value = tmp@missing_value

  minday_T@long_name     = "Minimum air temperature"
  minday_T@units         = tmp@units
  minday_T@_FillValue    = tmp@_FillValue
  minday_T@missing_value = tmp@missing_value

  tdim  = dimsizes(tmp)
  t1d   = ndtooned(tmp)
  intmx = ind_resolve(maxind(t1d),tdim)
  intmn = ind_resolve(minind(t1d),tdim)

  tmp_time_max = intmx(0,0)
  tmp_lat_max  = intmx(0,1)
  tmp_lon_max  = intmx(0,2)

  tmp_time_min = intmn(0,0)
  tmp_lat_min  = intmn(0,1)
  tmp_lon_min  = intmn(0,2)

  T_t_max    = tmp&time(tmp_time_max)
  T_time_max = T_t_max
  T_time_max = (T_t_max - time(0)) / 60.
  T_lat_max  = tmp&lat(tmp_lat_max)
  T_lon_max  = tmp&lon(tmp_lon_max)

  T_t_min    = tmp&time(tmp_time_min)
  T_time_min = T_t_min
  T_time_min = (T_t_min - time(0)) / 60.
  T_lat_min  = tmp&lat(tmp_lat_min)
  T_lon_min  = tmp&lon(tmp_lon_min)

  T_time_max@units     = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
  T_time_max@long_name = "Time of maximum air temperature"
  T_lat_max@long_name  = "Latitude of maximum air temperature"
  T_lon_max@long_name  = "Longitude of maximum air temperature"

  T_time_min@units     = "hours since "+YR+"-"+MO+"-"+DY+" 00:00:00"
  T_time_min@long_name = "Time of minimum air temperature"
  T_lat_min@long_name  = "Latitude of minimum air temperature"
  T_lon_min@long_name  = "Longitude of minimum air temperature"

  print("Maximum T = "+maxday_T+" "+tmp@units+", Time = "+ \
        pd_hour(tmp_time_max)+ " UTC, Lat = "+lat(tmp_lat_max)+ \
        " degN, Lon = "+lon(tmp_lon_max)+" degE")
  print("Minimum T = "+minday_T+" "+tmp@units+", Time = "+ \
        pd_hour(tmp_time_min)+" UTC, Lat = "+lat(tmp_lat_min)+ \
        " degN, Lon = "+lon(tmp_lon_min)+" degE")

  if (loc .eq. "Sahara" .and. force .eq. "GLDAS") then
    t09   = closest_val(9,pd_hour)
    t18   = closest_val(18,pd_hour)
    daytm = pd_hour(t09:t18)

    day_T = tmp(t09:t18,:,:)
    day_T = tmp(t09:t18,:,:)

    day_T_avg = dim_avg_n_Wrap(day_T,0)
    day_T_avg = dim_avg_n_Wrap(day_T,0)

    ngtex = get1Dindex_Exclude(pd_hour,daytm)

    ngt_T = tmp(ngtex,:,:)
    ngt_T = tmp(ngtex,:,:)

    ngt_T_avg = dim_avg_n_Wrap(ngt_T,0)
    ngt_T_avg = dim_avg_n_Wrap(ngt_T,0)
  end if
  if (loc .eq. "CONUS" .and. force .eq. "GLDAS") then
    t03   = closest_val(3,pd_hour)
    t12   = closest_val(12,pd_hour)
    ngttm = pd_hour(t03:t12)

    ngt_T = tmp(t03:t12,:,:)
    ngt_T = tmp(t03:t12,:,:)

    ngt_T_avg = dim_avg_n_Wrap(ngt_T,0)
    ngt_T_avg = dim_avg_n_Wrap(ngt_T,0)

    dayex = get1Dindex_Exclude(pd_hour,ngttm)

    day_T = tmp(dayex,:,:)
    day_T = tmp(dayex,:,:)

    day_T_avg = dim_avg_n_Wrap(day_T,0)
    day_T_avg = dim_avg_n_Wrap(day_T,0)
  end if
  day_T_avg@long_name = "Daytime averaged air temperature"
  ngt_T_avg@long_name = "Nighttime averaged air temperature"

; Open workstation
  wks = gsn_open_wks(gtype,force+"_SfcFlux_"+YR+"-"+MO+"-"+DY)

; Resources for xy plots
  lres = True

  lres@gsnMaximize      = True
  lres@xyLineThicknessF = 3.4
  lres@gsnLeftString    = YR+"-"+MO+"-"+DY
  lres@gsnRightString   = force+"-"+loc
  lres@tiXAxisString    = pd_hour@units
  lres@tiYAxisString    = "Air Temperature ("+tmp@units+")"

; Plotting daily temperature averaged over the region
  plot = gsn_csm_xy(wks,pd_hour,T_savg,lres)

; Resources for mapping the latent and sensible heat fluxes
  do i=0,dimsizes(time)-1,1

    gsn_define_colormap(wks,"seaice_2")

    cres = True

    cres@gsnMaximize           = True
    cres@gsnDraw               = False
    cres@gsnFrame              = False
    cres@gsnAddCyclic          = False
    cres@cnFillOn              = True
    cres@cnLinesOn             = False
    cres@gsnLeftString         = "Air Temperature ("+tmp@units+")"
    cres@gsnRightString        = pd_hour(i)+" "+pd_hour@units
    cres@tiMainString          = YR+"-"+MO+"-"+DY
    cres@mpLimitMode           = "LatLon"
    cres@mpMinLatF             = minlat - 1.
    cres@mpMinLonF             = minlon - 1.
    cres@mpMaxLatF             = maxlat + 1.
    cres@mpMaxLonF             = maxlon + 1.
    cres@mpOutlineBoundarySets = "National"
    cres@cnLevelSelectionMode  = "ManualLevels"
    if (unit_of_choice .eq. "K") then
      cres@cnMinLevelValF      = 252.
      cres@cnMaxLevelValF      = 316.
      cres@cnLevelSpacingF     = 6.
    else
      cres@cnMinLevelValF      = -22.
      cres@cnMaxLevelValF      = 42.
      cres@cnLevelSpacingF     = 6.
   end if
;   Plotting temperature every 3 hours
    plot = gsn_csm_contour_map(wks,tmp(i,:,:),cres)

    draw(plot)
    frame(wks)

  end do

; Resources for time average plot
  gsn_define_colormap(wks,"seaice_2")

  avres = True

  avres@gsnMaximize           = True
  avres@gsnAddCyclic          = False
  avres@cnFillOn              = True
  avres@cnLinesOn             = False
  avres@gsnLeftString         = "Air Temperature ("+tmp@units+")"
  avres@gsnRightString        = "Avg Daytime T"
  avres@tiMainString          = YR+"-"+MO+"-"+DY
  avres@mpLimitMode           = "LatLon"
  avres@mpMinLatF             = minlat - 1.
  avres@mpMinLonF             = minlon - 1.
  avres@mpMaxLatF             = maxlat + 1.
  avres@mpMaxLonF             = maxlon + 1.
  avres@mpOutlineBoundarySets = "National"
  avres@cnLevelSelectionMode  = "ManualLevels"
  if (unit_of_choice .eq. "K") then
    avres@cnMinLevelValF      = 252.
    avres@cnMaxLevelValF      = 316.
    avres@cnLevelSpacingF     = 6.
  else
    avres@cnMinLevelValF      = -22.
    avres@cnMaxLevelValF      = 42.
    avres@cnLevelSpacingF     = 6.
  end if

; Plotting daytime average temperature
  plot = gsn_csm_contour_map(wks,day_T_avg,avres)

  avres@gsnRightString        = "Avg Nighttime T"

; Plotting nighttime average temperature
  plot = gsn_csm_contour_map(wks,ngt_T_avg,avres)

;; Begin writing netCDF output (note, make sure you uncomment if you want to
;; write the netCDF file, from here until [print(systemfunc("date"))])
;  setfileoption("nc","FileStructure","Advanced")
;  setfileoption("nc","Format","NetCDF4")
;  fout = force+"_TnETair_"+loc+"_"+YR+MO+DY+".nc"
;
;  system("/bin/rm -f "+fout)
;  fo = addfile(fout,"c")
;
;  fAtt               = True
;  fAtt@title         = "Diurnal T Averages and Maxima/Minima "+ \
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
;  filevardef(g1,"day_T_avg",typeof(day_T_avg),(/ "lat","lon" /))
;  filevarattdef(g1,"day_T_avg",day_T_avg)
;  g1->day_T_avg = (/ day_T_avg /)
;
;  filevardef(g1,"ngt_T_avg",typeof(ngt_T_avg),(/ "lat","lon" /))
;  filevarattdef(g1,"ngt_T_avg",ngt_T_avg)
;  g1->ngt_T_avg = (/ ngt_T_avg /)
;
;; Spatial averages
;  filedimdef(g2,dimNames,dimSizes,dimUnlim)
;
;  filevardef(g2,"T_savg",typeof(T_savg),"time")
;  filevarattdef(g2,"T_savg",T_savg)
;  g2->T_savg = (/ T_savg /)
;
;; Maxima
;  filevardef(g3,"maxday_T",typeof(maxday_T),"ncl_scalar")
;  filevarattdef(g3,"maxday_T",maxday_T)
;  g3->maxday_T = (/ maxday_T /)
;
;  filevardef(g3,"T_time_max",typeof(T_time_max),"ncl_scalar")
;  filevarattdef(g3,"T_time_max",T_time_max)
;  g3->T_time_max = (/ T_time_max /)
;
;  filevardef(g3,"T_lat_max",typeof(T_lat_max),"ncl_scalar")
;  filevarattdef(g3,"T_lat_max",T_lat_max)
;  g3->T_lat_max = (/ T_lat_max /)
;
;  filevardef(g3,"T_lon_max",typeof(T_lon_max),"ncl_scalar")
;  filevarattdef(g3,"T_lon_max",T_lon_max)
;  g3->T_lon_max = (/ T_lon_max /)
;
;; Minima
;  filevardef(g4,"minday_T",typeof(minday_T),"ncl_scalar")
;  filevarattdef(g4,"minday_T",minday_T)
;  g4->minday_T = (/ minday_T /)
;
;  filevardef(g4,"T_time_min",typeof(T_time_min),"ncl_scalar")
;  filevarattdef(g4,"T_time_min",T_time_min)
;  g4->T_time_min = (/ T_time_min /)
;
;  filevardef(g4,"T_lat_min",typeof(T_lat_min),"ncl_scalar")
;  filevarattdef(g4,"T_lat_min",T_lat_min)
;  g4->T_lat_min = (/ T_lat_min /)
;
;  filevardef(g4,"T_lon_min",typeof(T_lon_min),"ncl_scalar")
;  filevarattdef(g4,"T_lon_min",T_lon_min)
;  g4->T_lon_min = (/ T_lon_min /)
;
;  print("Created/wrote new file: "+fout)
  print(systemfunc("date"))

end

