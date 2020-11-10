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
  force = "NLDAS"  ; "GLDAS" for Sahara, "NLDAS" for CONUS
  loc   = "CONUS"  ; "Sahara", "CONUS" are currently the regional choices

  dirGL = force+"_2019_"+loc
  
  season = "FALL" ; Choices right now are "FALL" (SON) or "WINTER" (DJF)
                    ; fall is only 2019, winter is 2019 and 2020
                    ; GLDAS can only be "fall"
; End user modification area;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Simple logic definer for the months in the season
  if (season .eq. "FALL") then
    mo = "SON"
  end if
  if (season .eq. "WINTER") then
    mo = "DJF"
  end if

; Add the first file and get lat/lon (the domain does not move, so there
; is no need to do this for every file in your season). Also add shf and lhf
; to have the attributes when creating your seasonal arrays
  if (force .eq. "NLDAS") then
    date0 = "/glade/scratch/damico/"+dirGL+"/"+force+ \
            "_NOAH0125_H.A20190804.0000.002.grb.SUB.nc4"
    f0000 = addfile(date0,"r")
  end if
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

  if (force .eq. "NLDAS") then
    shf0 = f0000->SHTFL(0,0,0)
    lhf0 = f0000->LHTFL(0,0,0)
  end if
  if (force .eq. "GLDAS") then
    shf0 = f0000->Qh_tavg(0,0,0)
    lhf0 = f0000->Qle_tavg(0,0,0)
  end if

; Creating the seasons for the available set of scenarios
  start_date = 0.
  end_date   = 0.

  if (season .eq. "FALL" .and. force .eq. "NLDAS") then
    sea_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH0125_H.A201909*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH0125_H.A201910*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH0125_H.A201911*.nc4 "
    start_date@units = "hours since 2019-09-01 00:00:00"
    end_date@units   = "hours since 2019-11-30 23:00:00"
    dt               = 1
  end if
  if (season .eq. "WINTER" .and. force .eq. "NLDAS") then
    sea_choice = "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH0125_H.A201912*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH0125_H.A202001*.nc4 "+ \
                 "/glade/scratch/damico/"+dirGL+"/"+force+ \
                 "_NOAH0125_H.A202002*.nc4 "
    start_date@units = "hours since 2019-12-01 00:00:00"
    end_date@units   = "hours since 2020-02-29 23:00:00"
    dt               = 1
  end if
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

  end_date_on_start = ut_convert(end_date,start_date@units)

  time       = ispan(0,doubletointeger(end_date_on_start),dt)
  time@units = start_date@units

  time_yyyymmddhh = floattointeger(cd_calendar(time,0))

  nt = dimsizes(time)

; Define your new (but empty) arrays for sensible and latent heat
  shf   = new((/ nt,nx,ny /),float)
  shf!0 = "time"
  lhf   = new((/ nt,nx,ny /),float)
  lhf!0 = "time"

; Add in the files for your season
  do i=0,nt-1,1
    if (force .eq. "NLDAS") then
      fname = "/glade/scratch/damico/"+dirGL+"/"+force+"_NOAH0125_H.A"+ \
              sprinti("%0.4i",time_yyyymmddhh(i,0))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,1))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,2))+"."+ \
              sprinti("%0.2i",time_yyyymmddhh(i,3))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,4))+ \
              ".002.grb.SUB.nc4"
    end if
    if (force .eq. "GLDAS") then
      fname = "/glade/scratch/damico/"+dirGL+"/"+force+"_NOAH025_3H.A"+ \
              sprinti("%0.4i",time_yyyymmddhh(i,0))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,1))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,2))+"."+ \
              sprinti("%0.2i",time_yyyymmddhh(i,3))+ \
              sprinti("%0.2i",time_yyyymmddhh(i,4))+ \
              ".021.nc4.SUB.nc4"
    end if
;   Fill your shf and lhf arrays
    if (isfilepresent(fname)) then
      das = addfile(fname,"r")
      if (force .eq. "NLDAS") then
        shf(i,:,:) = das->SHTFL(0,:,:)
        lhf(i,:,:) = das->LHTFL(0,:,:)
      end if
      if (force .eq. "GLDAS") then
        shf(i,:,:) = das->Qh_tavg(0,:,:)
        lhf(i,:,:) = das->Qle_tavg(0,:,:)
      end if
      print("Read->"+fname)
    else
      print(fname+" MISSING")
    end if
  end do

; Take the time averages, giving you a seasonal average that can be plotted
; on a map or written to a new file
  shf_tavg = dim_avg_n_Wrap(shf,0)
  lhf_tavg = dim_avg_n_Wrap(lhf,0)

; Open workstation, define colormap
  wks = gsn_open_wks(gtype,force+"_Avg_"+season+"_Flux")
  gsn_define_colormap(wks,"WhiteYellowOrangeRed")

; Resources for making the average sensible heat flux map
  avres = True

  avres@gsnMaximize           = True
  avres@gsnAddCyclic          = False
  avres@cnFillOn              = True
  avres@cnLinesOn             = False
  avres@gsnLeftString         = "Sensible Heat Flux (W m~S~-2~N~)"
  avres@gsnRightString        = "Avg "+season+" SHF"
  avres@tiMainString          = force+" "+mo+" Average"
  avres@mpLimitMode           = "LatLon"
  avres@mpMinLatF             = minlat - 1.
  avres@mpMinLonF             = minlon - 1.
  avres@mpMaxLatF             = maxlat + 1.
  avres@mpMaxLonF             = maxlon + 1.
  avres@mpOutlineBoundarySets = "National"
  avres@cnLevelSelectionMode  = "ManualLevels"
  if (loc .eq. "CONUS") then
    avres@cnMinLevelValF      = -20.
    avres@cnMaxLevelValF      = 100.
    avres@cnLevelSpacingF     = 10.
  end if
  if (loc .eq. "Sahara") then
    avres@cnMinLevelValF      = 10.
    avres@cnMaxLevelValF      = 130.
    avres@cnLevelSpacingF     = 10.
  end if

; Plot seasonal average sensible heat flux
  plot = gsn_csm_contour_map(wks,shf_tavg,avres)

; Resources for average latent heat flux map
  gsn_define_colormap(wks,"GMT_drywet")
  avres@gsnLeftString         = "Latent Heat Flux (W m~S~-2~N~)"
  avres@gsnRightString        = "Avg "+season+" LHF"
  if (loc .eq. "CONUS") then
    avres@cnMinLevelValF      = 0.
    avres@cnMaxLevelValF      = 100.
    avres@cnLevelSpacingF     = 10.
  end if
  if (loc .eq. "Sahara") then
    avres@cnMinLevelValF      = 10.
    avres@cnMaxLevelValF      = 130.
    avres@cnLevelSpacingF     = 10.
  end if

; Plot seasonal average latent heat flux
  plot = gsn_csm_contour_map(wks,lhf_tavg,avres)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Begin writing netCDF output (note, make sure you uncomment if you want to
; write the netCDF file, from here until 
; [print("Complete @ "+(systemfunc("date")))])
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  setfileoption("nc","FileStructure","Advanced")
;  setfileoption("nc","Format","NetCDF4")
;  fout = force+"_"+loc+"_"+season+"_AvgFlux.nc"
;
;  system("/bin/rm -f "+fout)
;  fo = addfile(fout,"c")
;
;  fAtt               = True
;  fAtt@title         = mo+" Averaged SHF/LHF from "+force+" over "+loc
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
;  filevardef(fo,"shf_tavg",typeof(shf_tavg),(/ "lat","lon" /))
;  filevarattdef(fo,"shf_tavg",shf_tavg)
;  fo->shf_tavg = (/ shf_tavg /)
;
;  filevardef(fo,"lhf_tavg",typeof(lhf_tavg),(/ "lat","lon" /))
;  filevarattdef(fo,"lhf_tavg",lhf_tavg)
;  fo->lhf_tavg = (/ lhf_tavg /)
;
;  print("Created/wrote new file: "+fout)

  print("Complete @ "+systemfunc("date"))

end

