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

  dt = 3 ; Files are currently stored for every third hour, so dt = 3

  ulatn = 206  ; These are ranges in latitude and longitude (n = min, x = max)
  ulatx = 222  ; dimensions that were tested separately (to save in
  ulonn = 1042 ; computation time) for the ARM LASSO lat (36.6N) and lon
  ulonx = 1058 ; (-97.5E or 262.5E). They are +/- 2 in each direction.

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4*atan(1.)

  print("Begin: "+systemfunc("date"))

; Time handling for the UFS files, used for reading in each file individually
; (more code, but more efficient)
  ufs_f = systemfunc("ls "+diru+"gfs.t12z.pgrb2.0p25.f*")
  nuu   = dimsizes(ufs_f)

  time_u = ispan(0,hr_for_comp,dt)
  ntu    = dimsizes(time_u)

  start_date = 0.
  end_date   = 0.

  start_date@units = "hours since "+YYYY+"-"+MM+"-"+DD+" 12:00:00"
  end_date@units   = "hours since "+YYYY+"-"+MM+"-"+(toint(DD)+1)+" 03:00:00"

  end_date_on_start = ut_convert(end_date,start_date@units)

  Time       = time_u
  Time@units = start_date@units

  time_yyyymmddhh = cd_calendar(Time,0)

; Reading the f000 file to have the dimension sizes
  ufs_00 = addfile(diru+"gfs.t12z.pgrb2.0p25.f000","r")

  lat     = ufs_00->lat_0(ulatn:ulatx)
  lon     = ufs_00->lon_0(ulonn:ulonx)
  lv0_00  = ufs_00->lv_ISBL0
  lv6_00  = ufs_00->lv_ISBL6

  lat      = lat(::-1)
  lv_ISBL0 = lv0_00(::-1)
  lv_ISBL6 = lv6_00(::-1)

  nyu  = dimsizes(lat)
  nxu  = dimsizes(lon)
  nzu0 = dimsizes(lv_ISBL0)
  nzu6 = dimsizes(lv_ISBL6)

; Add first surface file to get the static terrain height
  sfc_00 = addfile(diru+"gfs.t12z.sfluxgrbf000.grib2","r")

; Surface lat/lon ranges (the full model is 0.25deg, sfc is ~13 km)
  slatn = 438  ; These are ranges in latitude and longitude (n = min, x = max)
  slatx = 472  ; dimensions that were tested separately (to save in
  slonn = 2223 ; computation time) for the ARM LASSO lat (36.6N) and lon
  slonx = 2257 ; (-97.5E or 262.5E). They are +/- 2 in each direction.

  lats   = sfc_00->lat_0(slatn:slatx)
  lonsfc = sfc_00->lon_0(slonn:slonx)

  latsfc = lats(::-1)

  nys = dimsizes(latsfc)
  nxs = dimsizes(lonsfc)

; Terrain height (static, does not change through simulation)
  HGT = sfc_00->HGT_P0_L1_GGA0(slatn:slatx,slonn:slonx)

  HGT = HGT(::-1,:)

; Add the UFS files and read in the variables into individual arrays
  T        = new((/ ntu,nzu0,nyu,nxu /),float)
  QVAPOR   = new((/ ntu,nzu0,nyu,nxu /),float)
  GEOP_HGT = new((/ ntu,nzu0,nyu,nxu /),float)
  U        = new((/ ntu,nzu0,nyu,nxu /),float)
  V        = new((/ ntu,nzu0,nyu,nxu /),float)
  QCLOUD   = new((/ ntu,nzu6,nyu,nxu /),float)
  QRAIN    = new((/ ntu,nzu6,nyu,nxu /),float)
  QICE     = new((/ ntu,nzu6,nyu,nxu /),float)
  QSNOW    = new((/ ntu,nzu6,nyu,nxu /),float)
  QGRAUP   = new((/ ntu,nzu6,nyu,nxu /),float)
  CLDFRA   = new((/ ntu,nzu6,nyu,nxu /),float)
  W_LS     = new((/ ntu,nzu0,nyu,nxu /),float)
  SH_FLX   = new((/ ntu,nys,nxs /),float)
  LH_FLX   = new((/ ntu,nys,nxs /),float)
  T2       = new((/ ntu,nys,nxs /),float)
  U10      = new((/ ntu,nys,nxs /),float)
  V10      = new((/ ntu,nys,nxs /),float)
  do i=0,ntu-1,1
    um_name = "gfs.t12z.pgrb2.0p25.f"+sprinti("%0.3i",time_u(i))
    uu_name = diru+um_name
    if (isfilepresent(uu_name)) then
      fufs              = addfile(uu_name,"r")
      T(i,:,:,:)        = fufs->TMP_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      QVAPOR(i,:,:,:)   = fufs->SPFH_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      GEOP_HGT(i,:,:,:) = fufs->HGT_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      U(i,:,:,:)        = fufs->UGRD_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      V(i,:,:,:)        = fufs->VGRD_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      QCLOUD(i,:,:,:)   = fufs->CLWMR_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      QRAIN(i,:,:,:)    = fufs->RWMR_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      QICE(i,:,:,:)     = fufs->ICMR_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      QSNOW(i,:,:,:)    = fufs->SNMR_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      QGRAUP(i,:,:,:)   = fufs->GRLE_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      CLDFRA(i,:,:,:)   = fufs->TCDC_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      W_LS(i,:,:,:)     = fufs->DZDT_P0_L100_GLL0(:,ulatn:ulatx,ulonn:ulonx)
      print("Read->"+um_name)
    else
      print(um_name+"-->MISSING")
    end if
    us_name = "gfs.t12z.sfluxgrbf"+sprinti("%0.3i",time_u(i))+".grib2"
    uf_name = diru+us_name
    if (isfilepresent(uf_name)) then
      fuff          = addfile(uf_name,"r")
      SH_FLX(i,:,:) = fuff->SHTFL_P0_L1_GGA0(slatn:slatx,slonn:slonx)
      LH_FLX(i,:,:) = fuff->LHTFL_P0_L1_GGA0(slatn:slatx,slonn:slonx)
      T2(i,:,:)     = fuff->TMP_P0_L103_GGA0(slatn:slatx,slonn:slonx)
      U10(i,:,:)    = fuff->UGRD_P0_L103_GGA0(slatn:slatx,slonn:slonx)
      V10(i,:,:)    = fuff->VGRD_P0_L103_GGA0(slatn:slatx,slonn:slonx)
      print("Read->"+us_name)
    else
      print(us_name+"-->MISSING")
    end if
  end do

  T        = T(:,::-1,::-1,:)
  QVAPOR   = QVAPOR(:,::-1,::-1,:)
  GEOP_HGT = GEOP_HGT(:,::-1,::-1,:)
  U        = U(:,::-1,::-1,:)
  V        = V(:,::-1,::-1,:)
  QCLOUD   = QCLOUD(:,::-1,::-1,:)
  QRAIN    = QRAIN(:,::-1,::-1,:)
  QICE     = QICE(:,::-1,::-1,:)
  QSNOW    = QSNOW(:,::-1,::-1,:)
  QGRAUP   = QGRAUP(:,::-1,::-1,:)
  CLDFRA   = CLDFRA(:,::-1,::-1,:)
  W_LS     = W_LS(:,::-1,::-1,:)
  SH_FLX   = SH_FLX(:,::-1,:)
  LH_FLX   = LH_FLX(:,::-1,:)
  T2       = T2(:,::-1,:)
  U10      = U10(:,::-1,:)
  V10      = V10(:,::-1,:)

  T!0        = "Time"
  QVAPOR!0   = "Time"
  GEOP_HGT!0 = "Time"
  U!0        = "Time"
  V!0        = "Time"
  QCLOUD!0   = "Time"
  QRAIN!0    = "Time"
  QICE!0     = "Time"
  QSNOW!0    = "Time"
  QGRAUP!0   = "Time"
  CLDFRA!0   = "Time"
  W_LS!0     = "Time"
  SH_FLX!0   = "Time"
  LH_FLX!0   = "Time"
  T2!0       = "Time"
  U10!0      = "Time"
  V10!0      = "Time"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")
  fout = "UFS_Selection_"+date+".nc"

  system("/bin/rm -f "+fout)
  fo = addfile(fout,"c")

  fAtt               = True
  fAtt@title         = "Selected UFS Forecast Variables for "+date
  fAtt@creation_date = systemfunc("date")

; Define the dimensions: Time,lat,lon,lv_ISBL0,lv_ISBL6, and surface lat/lon
  dimNames = (/ "Time","lv_ISBL0","lv_ISBL6","lat","lon","latsfc","lonsfc" /)
  dimSizes = (/  ntu,   nzu0,      nzu6,      nyu,  nxu,  nys,    nxs   /)
  dimUnlim = (/  True,  False,     False,     False,False,False,  False  /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"Time",typeof(Time),"Time")
  filevarattdef(fo,"Time",Time)
  fo->Time = (/ Time /)

  filevardef(fo,"lv_ISBL0",typeof(lv_ISBL0),"lv_ISBL0")
  filevarattdef(fo,"lv_ISBL0",lv_ISBL0)
  fo->lv_ISBL0 = (/ lv_ISBL0 /)

  filevardef(fo,"lv_ISBL6",typeof(lv_ISBL6),"lv_ISBL6")
  filevarattdef(fo,"lv_ISBL6",lv_ISBL6)
  fo->lv_ISBL6 = (/ lv_ISBL6 /)

  filevardef(fo,"lat",typeof(lat),"lat")
  filevarattdef(fo,"lat",lat)
  fo->lat = (/ lat /)

  filevardef(fo,"lon",typeof(lon),"lon")
  filevarattdef(fo,"lon",lon)
  fo->lon = (/ lon /)

  filevardef(fo,"latsfc",typeof(latsfc),"latsfc")
  filevarattdef(fo,"latsfc",latsfc)
  fo->latsfc = (/ latsfc /)

  filevardef(fo,"lonsfc",typeof(lonsfc),"lonsfc")
  filevarattdef(fo,"lonsfc",lonsfc)
  fo->lonsfc = (/ lonsfc /)

; Define groups
  grpnames = (/ "Lvl0","Lvl6","Surface" /)
  filegrpdef(fo,grpnames)

  g1 = fo=>/Lvl0
  g2 = fo=>/Lvl6
  g3 = fo=>/Surface

; lv_ISBL0 (Lvl0) variables
  filedimdef(g1,dimNames,dimSizes,dimUnlim)

  filevardef(g1,"GEOP_HGT",typeof(GEOP_HGT),(/ "Time","lv_ISBL0", \
                                               "lat","lon" /))
  filevarattdef(g1,"GEOP_HGT",GEOP_HGT)
  g1->GEOP_HGT = (/ GEOP_HGT /)

  filevardef(g1,"T",typeof(T),(/ "Time","lv_ISBL0","lat","lon" /))
  filevarattdef(g1,"T",T)
  g1->T = (/ T /)

  filevardef(g1,"QVAPOR",typeof(QVAPOR),(/ "Time","lv_ISBL0","lat","lon" /))
  filevarattdef(g1,"QVAPOR",QVAPOR)
  g1->QVAPOR = (/ QVAPOR /)

  filevardef(g1,"U",typeof(U),(/ "Time","lv_ISBL0","lat","lon" /))
  filevarattdef(g1,"U",U)
  g1->U = (/ U /)

  filevardef(g1,"V",typeof(V),(/ "Time","lv_ISBL0","lat","lon" /))
  filevarattdef(g1,"V",V)
  g1->V = (/ V /)

  filevardef(g1,"W_LS",typeof(W_LS),(/ "Time","lv_ISBL0","lat","lon" /))
  filevarattdef(g1,"W_LS",W_LS)
  g1->W_LS = (/ W_LS /)

; lv_ISBL6 (Lvl6) variables
  filedimdef(g2,dimNames,dimSizes,dimUnlim)

  filevardef(g2,"CLDFRA",typeof(CLDFRA),(/ "Time","lv_ISBL6","lat","lon" /))
  filevarattdef(g2,"CLDFRA",CLDFRA)
  g2->CLDFRA = (/ CLDFRA /)

  filevardef(g2,"QCLOUD",typeof(QCLOUD),(/ "Time","lv_ISBL6","lat","lon" /))
  filevarattdef(g2,"QCLOUD",QCLOUD)
  g2->QCLOUD = (/ QCLOUD /)

  filevardef(g2,"QRAIN",typeof(QRAIN),(/ "Time","lv_ISBL6","lat","lon" /))
  filevarattdef(g2,"QRAIN",QRAIN)
  g2->QRAIN = (/ QRAIN /)

  filevardef(g2,"QICE",typeof(QICE),(/ "Time","lv_ISBL6","lat","lon" /))
  filevarattdef(g2,"QICE",QICE)
  g2->QICE = (/ QICE /)

  filevardef(g2,"QSNOW",typeof(QSNOW),(/ "Time","lv_ISBL6","lat","lon" /))
  filevarattdef(g2,"QSNOW",QSNOW)
  g2->QSNOW = (/ QSNOW /)

  filevardef(g2,"QGRAUP",typeof(QGRAUP),(/ "Time","lv_ISBL6","lat","lon" /))
  filevarattdef(g2,"QGRAUP",QGRAUP)
  g2->QGRAUP = (/ QGRAUP /)

; Surface variables
  filedimdef(g3,dimNames,dimSizes,dimUnlim)

  filevardef(g3,"T2",typeof(T2),(/ "Time","latsfc","lonsfc" /))
  filevarattdef(g3,"T2",T2)
  g3->T2 = (/ T2 /)

  filevardef(g3,"SH_FLX",typeof(SH_FLX),(/ "Time","latsfc","lonsfc" /))
  filevarattdef(g3,"SH_FLX",SH_FLX)
  g3->SH_FLX = (/ SH_FLX /)

  filevardef(g3,"LH_FLX",typeof(LH_FLX),(/ "Time","latsfc","lonsfc" /))
  filevarattdef(g3,"LH_FLX",LH_FLX)
  g3->LH_FLX = (/ LH_FLX /)

  filevardef(g3,"U10",typeof(U10),(/ "Time","latsfc","lonsfc" /))
  filevarattdef(g3,"U10",U10)
  g3->U10 = (/ U10 /)

  filevardef(g3,"V10",typeof(V10),(/ "Time","latsfc","lonsfc" /))
  filevarattdef(g3,"V10",V10)
  g3->V10 = (/ V10 /)

  filevardef(g3,"HGT",typeof(HGT),(/ "latsfc","lonsfc" /))
  filevarattdef(g3,"HGT",HGT)
  g3->HGT = (/ HGT /)

  print("Wrote file -> "+fout)
  print("Completed: "+systemfunc("date"))

end

