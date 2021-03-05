load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area
  YYYY = "2019"
  MM   = "07"
  DD   = "14"
  date = YYYY+MM+DD
  diru = "/glade/u/home/weiweili/my_work/GMTB/TnE_2021/SCM/GFSv16rt/"+ \
         "gfs."+date+"/12/"

  hr_for_comp = 15 ; For this current work, there are 15 hours worth of LASSO
                   ; data (1200-0300UTC). This might change for later studies

  ulatn = 438  ; These are ranges in latitude and longitude (n = min, x = max)
  ulatx = 472  ; dimensions that were tested separately (to save in
  ulonn = 2223 ; computation time) for the ARM LASSO lat (36.6N) and lon
  ulonx = 2257 ; (-97.5E or 262.5E). They are +/- 2 in each direction.

  dt = 3 ; Files are currently stored for every third hour, so dt = 3

; Time handling for the UFS files, used for reading in each file individually
; (more code, but more efficient)
  ufs_f = systemfunc("ls "+diru+"gfs.t12z.sfluxgrbf*.grib2")
  nuu   = dimsizes(ufs_f)

  time_u = ispan(0,hr_for_comp,dt)
  ntu    = dimsizes(time_u)

  start_date = 0.
  end_date   = 0.

  start_date@units = "hours since "+YYYY+"-"+MM+"-"+DD+" 12:00:00"
  end_date@units   = "hours since "+YYYY+"-"+MM+"-"+(toint(DD)+1)+ \
                     " 03:00:00"

  end_date_on_start = ut_convert(end_date,start_date@units)

  Time = time_u
  Time@units = start_date@units

  time_yyyymmddhh = cd_calendar(Time,0)

; Open the first file (f000) and read the lat/lon for your specified
; dimensions
  s00  = diru+"gfs.t12z.sfluxgrbf000.grib2"
  fs00 = addfile(s00,"r")

  lat_u = fs00->lat_0(ulatn:ulatx)
  lon_u = fs00->lon_0(ulonn:ulonx)

  nyu = dimsizes(lat_u)
  nxu = dimsizes(lon_u)
  lat = lat_u(::-1)
  lon = lon_u

; Add the UFS flux files from your selected times and read in latent and
; sensible heat fluxes into arrays
  SH_FLX = new((/ ntu,nyu,nxu /),float)
  LH_FLX = new((/ ntu,nyu,nxu /),float)
  do i=0,ntu-1,1
    us_name = "gfs.t12z.sfluxgrbf"+sprinti("%0.3i",time_u(i))+".grib2"
    uf_name = diru+us_name
    if (isfilepresent(uf_name)) then
      fuff          = addfile(uf_name,"r")
      SH_FLX(i,:,:) = fuff->SHTFL_P0_L1_GGA0(ulatn:ulatx,ulonn:ulonx)
      LH_FLX(i,:,:) = fuff->LHTFL_P0_L1_GGA0(ulatn:ulatx,ulonn:ulonx)
      print("Read->"+us_name)
    else
      print(us_name+"-->MISSING")
    end if
  end do

  SH_FLX = SH_FLX(:,::-1,:)
  LH_FLX = LH_FLX(:,::-1,:)

  SH_FLX!0   = "Time"
  LH_FLX!0   = "Time"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")
  fout = "UFS_sfc_heat_flux_"+date+".nc"

  system("/bin/rm -f "+fout)
  fo = addfile(fout,"c")

  fAtt               = True
  fAtt@title         = "UFS surface heat fluxes from "+date
  fAtt@creation_date = systemfunc("date")

; Define the dimensions: Time,lat,lon
  dimNames = (/ "Time","lat","lon" /)
  dimSizes = (/  ntu,   nyu,  nxu    /)
  dimUnlim = (/  True,  False,False  /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"Time",typeof(Time),"Time")
  filevarattdef(fo,"Time",Time)
  fo->Time = (/ Time /)

  filevardef(fo,"lat",typeof(lat),"lat")
  filevarattdef(fo,"lat",lat)
  fo->lat = (/ lat /)

  filevardef(fo,"lon",typeof(lon),"lon")
  filevarattdef(fo,"lon",lon)
  fo->lon = (/ lon /)

  filevardef(fo,"SH_FLX",typeof(SH_FLX),(/ "Time","lat","lon" /))
  filevarattdef(fo,"SH_FLX",SH_FLX)
  fo->SH_FLX = (/ SH_FLX /)

  filevardef(fo,"LH_FLX",typeof(LH_FLX),(/ "Time","lat","lon" /))
  filevarattdef(fo,"LH_FLX",LH_FLX)
  fo->LH_FLX = (/ LH_FLX /)

  print("Wrote file -> "+fout)
  print("Complete "+systemfunc("date"))

end

