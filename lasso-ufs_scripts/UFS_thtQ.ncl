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
  sims  = "SID8" ; "SID8","MSDA+UFSsflx"
  sn    = "8"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_"+date+"_rawmodel/raw_model/"

; End user modification area
  print("Started: "+systemfunc("date"))

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4*atan(1.)

; Add LASSO subset file
  flas = addfile(rdir+"LASSO_"+date+"_SUBSET.nc","r")

; Add UFS netCDF file
  fufs = addfile("UFS_Selection_"+date+".nc","r")

; Time for LASSO
  hwrf = flas->Time_hr
  twrf = flas->Time_s

  ntw = dimsizes(hwrf)

; Time for UFS
  utim        = fufs->Time
  hrufs       = tofloat(utim)
  hrufs@units = hwrf@units
  hrufs!0     = "Time"

  tufs       = hrufs
  tufs       = hrufs * 60. * 60.
  tufs@units = "seconds since "+udate

; Variables from LASSO
  lat_w      = flas->lat
  lon_w      = flas->lon
  preslas_Pa = flas->P
  hgtlas_m   = flas->height
  thtlas_K   = flas->T
  qvlas_kgkg = flas->QVAPOR

; LASSO longitude conversion to match UFS
  lon_wEE = lon_w
  lon_wEE = lon_w + 360.

; UFS variables
  lat_u      = fufs->lat
  lon_u      = fufs->lon
  hgtufs_u   = fufs->GEOP_HGT
  presufs_Pa = fufs->lv_ISBL0
  tmpufs_u   = fufs->T
  qvufs_u    = fufs->QVAPOR

  ntu = dimsizes(hrufs)
  nzu = dimsizes(presufs_Pa)
  nyu = dimsizes(lat_u)
  nxu = dimsizes(lon_u)

; UFS potential temperature
  thtufs_u = new((/ ntu,nzu,nyu,nxu /),float)
  do i=0,nzu-1,1
    thtufs_u(:,i,:,:) = tmpufs_u(:,i,:,:)
    thtufs_u(:,i,:,:) = tmpufs_u(:,i,:,:) * ((P00 / presufs_Pa(i))^ \
                                            (R_dry / c_p))
  end do

; Horizontal interpolation of UFS area-wide data to the single LASSO point
  thtufs_K_loc   = linint2_points_Wrap(lon_u,lat_u,thtufs_u,False, \
                                       lon_wEE,lat_w,0)
  qvufs_kgkg_loc = linint2_points_Wrap(lon_u,lat_u,qvufs_u,False, \
                                       lon_wEE,lat_w,0)
  hgtufs_m_loc   = linint2_points_Wrap(lon_u,lat_u,hgtufs_u,False, \
                                       lon_wEE,lat_w,0)

; UFS data is hourly, while LASSO is every ten minutes; the times need
; to be the same
  thtufs_K_time   = new((/ dimsizes(twrf),nzu,1 /),float)
  qvufs_kgkg_time = new((/ dimsizes(twrf),nzu,1 /),float)
  hgtufs_m_time   = new((/ dimsizes(twrf),nzu,1 /),float)
  do i=0,nzu-1,1
    thtufs_K_time(:,i,0)   = linint1_Wrap(hrufs,thtufs_K_loc(:,i,0),False, \
                                          hwrf,0)
    qvufs_kgkg_time(:,i,0) = linint1_Wrap(hrufs,qvufs_kgkg_loc(:,i,0),False, \
                                          hwrf,0)
    hgtufs_m_time(:,i,0)   = linint1_Wrap(hrufs,hgtufs_m_loc(:,i,0),False, \
                                          hwrf,0)
  end do

; Potential temperature and qv need the same vertical spacing, both will be
; from LASSO (226 vertical levels)
  thtufs_K   = new((/ ntw,dimsizes(hgtlas_m(0,:)),1 /),float)
  qvufs_kgkg = new((/ ntw,dimsizes(hgtlas_m(0,:)),1 /),float)
  do i=0,ntw-1,1
    thtufs_K(i,:,0)   = linint1_Wrap(presufs_Pa,thtufs_K_time(i,:,0), \
                                     False,preslas_Pa(i,:),0)
    qvufs_kgkg(i,:,0) = linint1_Wrap(presufs_Pa,qvufs_kgkg_time(i,:,0), \
                                     False,preslas_Pa(i,:),0)
  end do

  thtufs_K!0   = "Time"
  thtufs_K!1   = "bottom_top"
  thtufs_K!2   = "pts"
  qvufs_kgkg!0 = "Time"
  qvufs_kgkg!1 = "bottom_top"
  qvufs_kgkg!2 = "pts"

; Convert qv to g kg-1
  qvlas_gkg = qvlas_kgkg
  qvlas_gkg = qvlas_kgkg * 1000.
  qvufs_gkg = qvufs_kgkg
  qvufs_gkg = qvufs_kgkg * 1000.

  qvlas_gkg@units = "g kg-1"
  qvufs_gkg@units = "g kg-1"

; Differences for anomaly plots
  tht_df = thtufs_K(:,:,0)
  tht_df = thtufs_K(:,:,0) - thtlas_K

  tht_diff = tht_df(bottom_top|:,Time|:)

  thl_K = thtlas_K(bottom_top|:,Time_s|:)

  qv_df = qvufs_gkg(:,:,0)
  qv_df = qvufs_gkg(:,:,0) - qvlas_gkg

  qv_diff = qv_df(bottom_top|:,Time|:)

  qvl_gkg = qvlas_gkg(bottom_top|:,Time_s|:)

; Height ranges for plotting
  hl3k = closest_val(3000.,hgtlas_m(0,:))

; Open workstation for plotting
  wks = gsn_open_wks(gtype,"UFSvLASSO_thtQ")

; Create new color table with white actually in the middle
  BlueDarkRed18_WIM = (/ (/ 1.00000,1.00000,1.00000 /), \ ; Foreground (0)
                         (/ 0.00000,0.00000,0.00000 /), \ ; Background (1)
                         (/ 0.14118,0.00000,0.84706 /), \ ; 2
                         (/ 0.09412,0.10980,0.96863 /), \ ; 3
                         (/ 0.15686,0.34118,1.00000 /), \ ; 4
                         (/ 0.23922,0.25941,1.00000 /), \ ; 5
                         (/ 0.33725,0.69020,1.00000 /), \ ; 6
                         (/ 0.45882,0.82745,1.00000 /), \ ; 7
                         (/ 0.60000,0.91765,1.00000 /), \ ; 8
                         (/ 0.73725,0.97647,1.00000 /), \ ; 9
                         (/ 1.00000,1.00000,1.00000 /), \ ; 10
                         (/ 1.00000,1.00000,1.00000 /), \ ; 11
                         (/ 1.00000,0.94510,0.73725 /), \ ; 12
                         (/ 1.00000,0.83922,0.60000 /), \ ; 13
                         (/ 1.00000,0.67451,0.45882 /), \ ; 14
                         (/ 1.00000,0.47059,0.33725 /), \ ; 15
                         (/ 1.00000,0.23922,0.23922 /), \ ; 16
                         (/ 0.96863,0.15294,0.20784 /), \ ; 17
                         (/ 0.84706,0.08235,0.18431 /), \ ; 18
                         (/ 0.64706,0.00000,0.12941 /) /) ; 19

; Resources for anomaly plots (contour plots)
  gsn_define_colormap(wks,BlueDarkRed18_WIM)

  ares = True

  ares@gsnMaximize          = True
  ares@gsnDraw              = False
  ares@gsnFrame             = False
  ares@cnFillOn             = True
  ares@cnLinesOn            = False
  ares@sfXArray             = hwrf
  ares@sfYArray             = hgtlas_m(1,0:hl3k(0))
  ares@tiXAxisString        = "US CST"
  ares@tiYAxisString        = "Height (m)"
  ares@gsnLeftString        = "UFS - LASSO Pot Temp"
  ares@gsnRightString       = tht_diff@units
  ares@cnLevelSelectionMode = "ManualLevels"
  ares@cnMinLevelValF       = -4.
  ares@cnMaxLevelValF       = 4.
  ares@cnLevelSpacingF      = 0.5
  ares@tmXBMode             = "Explicit"
  ares@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  ares@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  ares@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)
  ares@lbTitleOn            = True
  ares@lbTitleString        = "CONTOUR: LASSO ~F33~q~F21~"
  ares@lbTitleFontHeightF   = 0.015

  plot = gsn_csm_contour(wks,tht_diff(0:hl3k(0),:),ares)

  lres = True

  lres@gsnMaximize                  = True
  lres@gsnDraw                      = False
  lres@gsnFrame                     = False
  lres@gsnLeftString                = ""
  lres@gsnRightString               = ""
  lres@sfXArray                     = hwrf
  lres@sfYArray                     = hgtlas_m(1,0:hl3k(0))
  lres@cnLineThicknessF             = 2.
  lres@cnInfoLabelOn                = False
  lres@gsnContourNegLineDashPattern = 1

  pltlas = gsn_csm_contour(wks,thl_K(0:hl3k(0),:),lres)

  overlay(plot,pltlas)

  draw(plot)
  frame(wks)

  gsn_reverse_colormap(wks)

  ares@gsnLeftString        = "UFS - LASSO q~B~v~N~"
  ares@gsnRightString       = "g kg~S~-1~N~"
  ares@cnMinLevelValF       = -7.
  ares@cnMaxLevelValF       = 7.
  ares@cnLevelSpacingF      = 1.
  ares@lbTitleString        = "CONTOUR: LASSO q~B~v~N~"

  plot = gsn_csm_contour(wks,qv_diff(0:hl3k(0),:),ares)

  pltlas = gsn_csm_contour(wks,qvl_gkg(0:hl3k(0),:),lres)

  overlay(plot,pltlas)

  draw(plot)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end

