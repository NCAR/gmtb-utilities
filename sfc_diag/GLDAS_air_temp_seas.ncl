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
  force = "GLDAS"  ; "GLDAS" for Sahara and CONUS
  loc   = "CONUS"  ; "Sahara", "CONUS" are currently the regional choices
  dirGL = force+"_TAIR_"+loc

  season = "WINTER" ; Choices right now are "FALL" (SON) or "WINTER" (DJF)
                    ; fall is only 2019, winter is 2019 and 2020

  unit_of_choice = "C" ; "K" (Kelvin) or "C" (Celcius)
; End user modification area;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Simple logic definer for the months in the season
  if (season .eq. "FALL") then
    mo = "SON"
  end if
  if (season .eq. "WINTER") then
    mo = "DJF"
  end if

; Add the first file and get lat/lon (the domain does not move, so there
; is no need to do this for every file in your season). Also add temperature
; to have the attributes when creating your seasonal arrays
  if (force .eq. "GLDAS") then
    date0 = "/glade/scratch/damico/"+dirGL+"/"+force+ \
            "_NOAH025_3H.A20190804.0000.021.nc4.SUB.nc4"
    f0000 = addfile(date0,"r")
  end if

  lat = f0000->lat
  lon = f0000->lon

  nx = dimsizes(lat)
  ny = dimsizes(lon)

  minlat = min(lat)
  maxlat = max(lat)
  minlon = min(lon)
  maxlon = max(lon)

  if (force .eq. "GLDAS") then
    T0 = f0000->Tair_f_inst(0,0,0)
  end if

; Creating the seasons for the available set of scenarios
  start_date = 0.
  end_date   = 0.
  if (season .eq. "FALL" .and. force .eq. "GLDAS") then
    sea_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH025_3H.A201909*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH025_3H.A201910*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH025_3H.A201911*.nc4 "
    start_date@units = "hours since 2019-09-01 00:00:00"
    end_date@units   = "hours since 2019-11-30 23:00:00"
    dt               = 3
  end if
  if (season .eq. "WINTER" .and. force .eq. "GLDAS") then
    sea_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH025_3H.A201912*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH025_3H.A202001*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH025_3H.A202002*.nc4 "
    start_date@units = "hours since 2019-12-01 00:00:00"
    end_date@units   = "hours since 2020-02-29 23:00:00"
    dt               = 3
  end if

  end_date_on_start = ut_convert(end_date,start_date@units)

  time       = ispan(0,doubletointeger(end_date_on_start),dt)
  time@units = start_date@units

  time_yyyymmddhh = floattointeger(cd_calendar(time,0))

  nt = dimsizes(time)

; Define your new (but empty) arrays for sensible and latent heat
  tmp   = new((/ nt,nx,ny /),float)
  tmp!0 = "time"

; Add in the files for your season
  do i=0,nt-1,1
    if (force .eq. "GLDAS") then
      fname = "/glade/scratch/damico/"+dirGL+"/"+force+"_NOAH025_3H.A"+ \
              sprinti("%0.4i",time_yyyymmddhh(i,0))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,1))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,2))+"."+ \
              sprinti("%0.2i",time_yyyymmddhh(i,3))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,4))+ \
              ".021.nc4.SUB.nc4"
    end if
;   Fill you temperature arrays
    if (isfilepresent(fname)) then
      das = addfile(fname,"r")
      if (force .eq. "GLDAS") then
        tmp(i,:,:) = das->Tair_f_inst(0,:,:)
      end if
      print("Read->"+fname)
    else
      print(fname+" MISSING")
    end if
  end do
  if (unit_of_choice .eq. "C") then
    tmp       = tmp - 273.15
    tmp@units = unit_of_choice
  end if

; Take the time average, giving you a seasonal average that can be plotted
; on a map or written to a new file
  T_tavg = dim_avg_n_Wrap(tmp,0)

; Open workstation, define colormap
  wks = gsn_open_wks(gtype,force+"_Avg_"+season+"_Tmp")
  gsn_define_colormap(wks,"seaice_2")

; Resources for making the average sensible heat flux map
  avres = True

  avres@gsnMaximize           = True
  avres@gsnAddCyclic          = False
  avres@cnFillOn              = True
  avres@cnLinesOn             = False
  avres@gsnLeftString         = "Air Temperature ("+tmp@units+")"
  avres@gsnRightString        = "Avg "+season+" T"
  avres@tiMainString          = force+" "+mo+" Average"
  avres@mpLimitMode           = "LatLon"
  avres@mpMinLatF             = minlat - 1.
  avres@mpMinLonF             = minlon - 1.
  avres@mpMaxLatF             = maxlat + 1.
  avres@mpMaxLonF             = maxlon + 1.
  avres@cnLevelSelectionMode  = "ManualLevels"
  if (unit_of_choice .eq. "K") then
    avres@cnMinLevelValF      = 260.
    avres@cnMaxLevelValF      = 308.
    avres@cnLevelSpacingF     = 4.
  else
    avres@cnMinLevelValF      = -12.
    avres@cnMaxLevelValF      = 36
    avres@cnLevelSpacingF     = 4.
  end if

; Plot seasonal average sensible heat flux
  plot = gsn_csm_contour_map(wks,T_tavg,avres)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Begin writing netCDF output (note, make sure you uncomment if you want to
; write the netCDF file, from here until
; [print("Complete @ "+(systemfunc("date")))])
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  setfileoption("nc","FileStructure","Advanced")
;  setfileoption("nc","Format","NetCDF4")
;  fout = force+"_"+loc+"_"+season+"_AvgTair.nc"
;
;  system("/bin/rm -f "+fout)
;  fo = addfile(fout,"c")
;
;  fAtt               = True
;  fAtt@title         = mo+" Averaged TAir from "+force+" over "+loc
;  fAtt@creation_date = systemfunc("date")
;
;; Define the dimensions: lat and lon
;  dimNames = (/ "lat","lon" /)
;  dimSizes = (/ dimsizes(lat),dimsizes(lon) /)
;  dimUnlim = (/ False,False /)
;
;  filedimdef(fo,dimNames,dimSizes,dimUnlim)
;
;  filevardef(fo,"lat",typeof(lat),"lat")
;  filevarattdef(fo,"lat",lat)
;  fo->lat = (/ lat /)
;
;  filevardef(fo,"lon",typeof(lon),"lon")
;  filevarattdef(fo,"lon",lon)
;  fo->lon = (/ lon /)
;
;  filevardef(fo,"T_tavg",typeof(T_tavg),(/ "lat","lon" /))
;  filevarattdef(fo,"T_tavg",T_tavg)
;  fo->T_tavg = (/ T_tavg /)
;
;  print("Created/wrote new file: "+fout)

  print("Complete @ "+systemfunc("date"))

end

