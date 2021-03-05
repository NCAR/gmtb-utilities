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
  sn    = "8"
  sims  = "SID"+sn
  phys  = "GFS_v16beta"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  ctrl = "MSDA+UFSsflx"
  t1   = phys
  t2   = phys+"_MYNN"

  dirlas  = "/glade/work/damico/LASSO_"+date+"_rawmodel/raw_model/"
  dirstop = "/glade/u/home/damico/SCMv4p1_update/gmtb-scm/scm/bin/" ;PSFC/"

  dirc  = "output_LASSO_"+date+"_"+ctrl+"_SCM_"+t1+"/"
  dirt1 = "output_LASSO_"+date+"_"+sims+"_SCM_"+t1+"/"
  dirt2 = "output_LASSO_"+date+"_"+sims+"_SCM_"+t2+"/"

  file_all = "output.nc"

  MYNN_on = False ; Logical, True if MYNN is plotted, False if it is not
                  ; desired

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  c_pv  = 1996.   ; spec heat of water vapor (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  eps   = (R_dry / R_vap)
  pi    = 4.*atan(1.)

  print("Started: "+systemfunc("date"))

; Add LASSO files
  flas = addfile(dirlas+"LASSO_20190714_SUBSET.nc","r")

; Time for LASSO
  hwrf = flas->Time_hr
  twrf = flas->Time_s

; Add SCM files
  fctl = addfile(dirstop+dirc+file_all,"r")
  ft1  = addfile(dirstop+dirt1+file_all,"r")
  ft2  = addfile(dirstop+dirt2+file_all,"r")

; SCM time
  tscm = ft1->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hrs since "+udate

; Variables from LASSO
  thtlas_K   = flas->T      ; potential temperature
  qvlas_kgkg = flas->QVAPOR ; water vapor specific humidity
  qclas_kgkg = flas->QCLOUD ; cloud water mixing ratio
  qrlas_kgkg = flas->QRAIN  ; rain water mixing ratio
;  qilas_kgkg = flas->QICE   ; ice water mixing ratio
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height

; Calculate air temperature for LASSO from potential temperature
  tmplas_K             = thtlas_K
  tmplas_K             = thtlas_K / ((P00 / preslas_Pa)^(R_dry / c_p))
  tmplas_K@description = "AIR TEMPERATURE"

; Calculating LASSO saturation vapor pressure and saturation specific
; humidity
  svplas_hPa = 6.11 * (10^((7.5*(tmplas_K - 273.15)) / (273.3 + \
                          (tmplas_K - 273.15))))
  svplas_Pa  = svplas_hPa * 100.

  qvsatlas_kgkg = 0.622 * (svplas_Pa / preslas_Pa)

; Calculating LASSO relative humidity
  rhlas = (qvlas_kgkg / qvsatlas_kgkg) * 100.

  rhlas@description = "Relative Humidity"
  rhlas@units       = "%"
  rhlas!0           = "Time"
  rhlas!1           = "bottom_top"

; Convert water vapor specific humidity back to water vapor mixing ratio for
; theta-l calculations
  rvlas_kgkg = qvlas_kgkg
  rvlas_kgkg = qvlas_kgkg / (1 - qvlas_kgkg)

; Liquid water mixing ratio
  rllas_kgkg = qclas_kgkg
  rllas_kgkg = qclas_kgkg + qrlas_kgkg

; Total water mixing ratio (vapor+cloud+rain+ice [note, all ice are currently
; zero])
  rtotlas = rvlas_kgkg
  rtotlas = rvlas_kgkg + rllas_kgkg

; Calculate gamma and chi for liquid water potential temperature equation
  gammalas = (rtotlas * R_vap) / (c_p + (rtotlas * c_pv))

  chilas = new((/ dimsizes(qvlas_kgkg) /),float)
  do i=0,dimsizes(hwrf)-1,1
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (rhlas(i,j) .lt. 100.) then
        chilas(i,j) = R_dry / c_p
      else
        chilas(i,j) = (R_dry / c_p) * ((1 + (rvlas_kgkg(i,j) / eps)) / \
                                      (1 + ((rvlas_kgkg(i,j)*c_pv) / \
                                      (c_p))))
      end if
    end do
  end do

; Calculate liquid water potential temperature for LASSO
  thtllas_K = thtlas_K *((((eps + rvlas_kgkg) / (eps + rtotlas))^chilas) * \
                        ((rvlas_kgkg / rtotlas)^(gammalas * -1)) * \
                        exp(((l_v * -1) * rllas_kgkg) / ((c_p + (rtotlas * \
                        c_pv)) * tmplas_K)))

; SCM variables
  presctl_Pa = fctl->pres
  tmpctl_K   = fctl->T
  qvctl_kgkg = fctl->qv
  qcctl_kgkg = fctl->qc
  qcctl_conv = fctl->qc_conv
  qictl_kgkg = fctl->qi
  prest1_Pa  = ft1->pres
  tmpt1_K    = ft1->T
  qvt1_kgkg  = ft1->qv
  qct1_kgkg  = ft1->qc
  qct1_conv  = ft1->qc_conv
  qit1_kgkg  = ft1->qi
  prest2_Pa  = ft2->pres
  tmpt2_K    = ft2->T
  qvt2_kgkg  = ft2->qv
  qct2_kgkg  = ft2->qc
  qct2_conv  = ft2->qc_conv
  qit2_kgkg  = ft2->qi

; Calculating SCM saturation vapor pressure and saturation specific
; humidity
  svpctl_hPa = 6.11 * (10^((7.5*(tmpctl_K - 273.15)) / (273.3 + \
                          (tmpctl_K-273.15))))
  svpctl_Pa  = svpctl_hPa * 100.

  qvsatctl_kgkg = 0.622 * (svpctl_Pa / presctl_Pa)

  svpt1_hPa = 6.11 * (10^((7.5*(tmpt1_K - 273.15)) / (273.3 + \
                          (tmpt1_K-273.15))))
  svpt1_Pa  = svpt1_hPa * 100.

  qvsatt1_kgkg = 0.622 * (svpt1_Pa / prest1_Pa)

  svpt2_hPa = 6.11 * (10^((7.5*(tmpt2_K - 273.15)) / (273.3 + \
                          (tmpt2_K-273.15))))
  svpt2_Pa  = svpt2_hPa * 100.

  qvsatt2_kgkg = 0.622 * (svpt2_Pa / prest2_Pa)

; Calculating SCM relative humidity
  rhctl_127 = (qvctl_kgkg / qvsatctl_kgkg) * 100.

  rhctl_127@description = "Relative Humidity"
  rhctl_127@units       = "%"
  rhctl_127!0           = "Time"
  rhctl_127!1           = "bottom_top"
  rhctl_127!2           = "horiz_dim_layer"

  rht1_127 = (qvt1_kgkg / qvsatt1_kgkg) * 100.

  rht1_127@description = "Relative Humidity"
  rht1_127@units       = "%"
  rht1_127!0           = "Time"
  rht1_127!1           = "bottom_top"
  rht1_127!2           = "horiz_dim_layer"

  rht2_127 = (qvt2_kgkg / qvsatt2_kgkg) * 100.

  rht2_127@description = "Relative Humidity"
  rht2_127@units       = "%"
  rht2_127!0           = "Time"
  rht2_127!1           = "bottom_top"
  rht2_127!2           = "horiz_dim_layer"

; SCM temperature to potential temperature
  thtctl_K = tmpctl_K
  thtctl_K = tmpctl_K * ((P00 / presctl_Pa)^(R_dry / c_p))

  thtt1_K = tmpt1_K
  thtt1_K = tmpt1_K * ((P00 / prest1_Pa)^(R_dry / c_p))

  thtt2_K = tmpt2_K
  thtt2_K = tmpt2_K * ((P00 / prest2_Pa)^(R_dry / c_p))

; Convert specific humidities to mixing ratios for theta-l calculation
  rvctl_kgkg = qvctl_kgkg
  rvctl_kgkg = qvctl_kgkg / (1 - qvctl_kgkg)

  rcctl_kgkg = qcctl_kgkg
  rcctl_kgkg = qcctl_kgkg / (1 - qcctl_kgkg)

  rcctl_conv = qcctl_conv
  rcctl_conv = qcctl_conv / (1 - qcctl_conv)

  rictl_kgkg = qictl_kgkg
  rictl_kgkg = qictl_kgkg / (1 - qictl_kgkg)

  rvt1_kgkg = qvt1_kgkg
  rvt1_kgkg = qvt1_kgkg / (1 - qvt1_kgkg)
  
  rct1_kgkg = qct1_kgkg
  rct1_kgkg = qct1_kgkg / (1 - qct1_kgkg)
  
  rct1_conv = qct1_conv
  rct1_conv = qct1_conv / (1 - qct1_conv)
  
  rit1_kgkg = qit1_kgkg
  rit1_kgkg = qit1_kgkg / (1 - qit1_kgkg)

  rvt2_kgkg = qvt2_kgkg
  rvt2_kgkg = qvt2_kgkg / (1 - qvt2_kgkg)
  
  rct2_kgkg = qct2_kgkg
  rct2_kgkg = qct2_kgkg / (1 - qct2_kgkg)
  
  rct2_conv = qct2_conv
  rct2_conv = qct2_conv / (1 - qct2_conv)
  
  rit2_kgkg = qit2_kgkg
  rit2_kgkg = qit2_kgkg / (1 - qit2_kgkg)

; Liquid water mixing ratio
  rlctl_kgkg = rcctl_kgkg
  rlctl_kgkg = rcctl_kgkg + rcctl_conv

  rlt1_kgkg = rct1_kgkg
  rlt1_kgkg = rct1_kgkg + rct1_conv

  rlt2_kgkg = rct2_kgkg
  rlt2_kgkg = rct2_kgkg + rct2_conv

; Total water mixing ratio (vapor+cloud+cloudconv+ice)
  rtotctl = rvctl_kgkg
  rtotctl = rvctl_kgkg + rlctl_kgkg + rictl_kgkg

  rtott1  = rvt1_kgkg 
  rtott1  = rvt1_kgkg + rlt1_kgkg + rit1_kgkg

  rtott2  = rvt2_kgkg 
  rtott2  = rvt2_kgkg + rlt2_kgkg + rit2_kgkg

; Calculate gamma and chi for liquid water potential temperature equation
  gammactl = (rtotctl * R_vap) / (c_p + (rtotctl * c_pv))
  gammat1  = (rtott1 * R_vap) / (c_p + (rtott1 * c_pv))
  gammat2  = (rtott2 * R_vap) / (c_p + (rtott2 * c_pv))

  chictl = new((/ dimsizes(qvctl_kgkg) /),float)
  chit1  = new((/ dimsizes(qvt1_kgkg) /),float)
  chit2  = new((/ dimsizes(qvt2_kgkg) /),float)
  do i=0,dimsizes(hscm)-1,1
    do j=0,dimsizes(presctl_Pa(0,:,0))-1,1
      if (rhctl_127(i,j,:) .lt. 100.) then
        chictl(i,j,:) = R_dry / c_p
      else
        chictl(i,j,:) = (R_dry / c_p) * ((1 + (rvctl_kgkg(i,j,:) / eps)) / \
                                        (1 + ((rvctl_kgkg(i,j,:)*c_pv) / \
                                        (c_p))))
      end if
      if (rht1_127(i,j,:) .lt. 100.) then
        chit1(i,j,:) = R_dry / c_p
      else
        chit1(i,j,:) = (R_dry / c_p) * ((1 + (rvt1_kgkg(i,j,:) / eps)) / \
                                        (1 + ((rvt1_kgkg(i,j,:)*c_pv) / \
                                        (c_p))))
      end if
      if (rht2_127(i,j,:) .lt. 100.) then
        chit2(i,j,:) = R_dry / c_p      
      else
        chit2(i,j,:) = (R_dry / c_p) * ((1 + (rvt2_kgkg(i,j,:) / eps)) / \
                                        (1 + ((rvt2_kgkg(i,j,:)*c_pv) / \
                                        (c_p))))
      end if 
    end do
  end do

; Calculate liquid water potential temperature for the SCM experiments
  thtlctl_127 = thtctl_K *((((eps + rvctl_kgkg) / (eps + rtotctl))^chictl) * \
                          ((rvctl_kgkg / rtotctl)^(gammactl * -1)) * \
                          exp(((l_v * -1) * rlctl_kgkg) / ((c_p + (rtotctl * \
                          c_pv)) * tmpctl_K)))
  thtlt1_127  = thtt1_K *((((eps + rvt1_kgkg) / (eps + rtott1))^chit1) * \
                         ((rvt1_kgkg / rtott1)^(gammat1 * -1)) * \
                         exp(((l_v * -1) * rlt1_kgkg) / ((c_p + (rtott1 * \
                         c_pv)) * tmpt1_K)))
  thtlt2_127  = thtt2_K *((((eps + rvt2_kgkg) / (eps + rtott2))^chit2) * \
                         ((rvt2_kgkg / rtott2)^(gammat2 * -1)) * \
                         exp(((l_v * -1) * rlt2_kgkg) / ((c_p + (rtott2 * \
                         c_pv)) * tmpt2_K)))

  thtlctl_K = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    thtlctl_K(i,:) = linint1(presctl_Pa(i,:,0),thtlctl_127(i,:,0),False, \
                             preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(thtlctl_K(i,j))) then
        thtlctl_K(i,j) = thtlctl_127(i,j,0)
      end if
    end do
  end do
  thtlctl_K@description = "liquid water potential temperature"
  thtlctl_K@units       = "K"
  thtlctl_K!0           = "Time"
  thtlctl_K!1           = "bottom_top"

  thtlt1_K = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    thtlt1_K(i,:) = linint1(prest1_Pa(i,:,0),thtlt1_127(i,:,0),False, \
                            preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(thtlt1_K(i,j))) then
        thtlt1_K(i,j) = thtlt1_127(i,j,0)
      end if
    end do
  end do
  thtlt1_K@description = "liquid water potential temperature"
  thtlt1_K@units       = "K"
  thtlt1_K!0           = "Time"
  thtlt1_K!1           = "bottom_top"

  thtlt2_K = new((/ dimsizes(preslas_Pa) /),float)
  do i=0,dimsizes(preslas_Pa(:,0))-1,1
    thtlt2_K(i,:) = linint1(prest2_Pa(i,:,0),thtlt2_127(i,:,0),False, \
                            preslas_Pa(i,:),0)
    do j=0,dimsizes(preslas_Pa(0,:))-1,1
      if (ismissing(thtlt2_K(i,j))) then
        thtlt2_K(i,j) = thtlt2_127(i,j,0)
      end if
    end do
  end do
  thtlt2_K@description = "liquid water potential temperature"
  thtlt2_K@units       = "K"
  thtlt2_K!0           = "Time"
  thtlt2_K!1           = "bottom_top"

; Averaging time periods, two hour time averages for 3, 5, 7, 9, 11, 13,
; and 15 hrs.
  thtllas_03 = thtllas_K(closest_val(3600.,twrf):closest_val(10800.,twrf)-1, \
                         :)
  thtlctl_03 = thtlctl_K(closest_val(3600.,tscm):closest_val(10800.,tscm)-1, \
                         :)
  thtlt1_03  = thtlt1_K(closest_val(3600.,tscm):closest_val(10800.,tscm)-1, \
                        :)
  thtlt2_03  = thtlt2_K(closest_val(3600.,tscm):closest_val(10800.,tscm)-1, \
                        :)

  thtllas_tavg03 = dim_avg_n_Wrap(thtllas_03,0)
  thtlctl_tavg03 = dim_avg_n_Wrap(thtlctl_03,0)
  thtlt1_tavg03  = dim_avg_n_Wrap(thtlt1_03,0)
  thtlt2_tavg03  = dim_avg_n_Wrap(thtlt2_03,0)

  thtllas_05 = thtllas_K(closest_val(10800.,twrf):closest_val(18000.,twrf)-1, \
                         :)
  thtlctl_05 = thtlctl_K(closest_val(10800.,tscm):closest_val(18000.,tscm)-1, \
                         :)
  thtlt1_05  = thtlt1_K(closest_val(10800.,tscm):closest_val(18000.,tscm)-1, \
                        :)
  thtlt2_05  = thtlt2_K(closest_val(10800.,tscm):closest_val(18000.,tscm)-1, \
                        :)

  thtllas_tavg05 = dim_avg_n_Wrap(thtllas_05,0)
  thtlctl_tavg05 = dim_avg_n_Wrap(thtlctl_05,0)
  thtlt1_tavg05  = dim_avg_n_Wrap(thtlt1_05,0)
  thtlt2_tavg05  = dim_avg_n_Wrap(thtlt2_05,0)

  thtllas_07 = thtllas_K(closest_val(18000.,twrf):closest_val(25200.,twrf)-1, \
                         :)
  thtlctl_07 = thtlctl_K(closest_val(18000.,tscm):closest_val(25200.,tscm)-1, \
                         :)
  thtlt1_07  = thtlt1_K(closest_val(18000.,tscm):closest_val(25200.,tscm)-1, \
                        :)
  thtlt2_07  = thtlt2_K(closest_val(18000.,tscm):closest_val(25200.,tscm)-1, \
                        :)

  thtllas_tavg07 = dim_avg_n_Wrap(thtllas_07,0)
  thtlctl_tavg07 = dim_avg_n_Wrap(thtlctl_07,0)
  thtlt1_tavg07  = dim_avg_n_Wrap(thtlt1_07,0)
  thtlt2_tavg07  = dim_avg_n_Wrap(thtlt2_07,0)

  thtllas_09 = thtllas_K(closest_val(25200.,twrf):closest_val(32400.,twrf)-1, \
                         :)
  thtlctl_09 = thtlctl_K(closest_val(25200.,tscm):closest_val(32400.,tscm)-1, \
                         :)
  thtlt1_09  = thtlt1_K(closest_val(25200.,tscm):closest_val(32400.,tscm)-1, \
                        :)
  thtlt2_09  = thtlt2_K(closest_val(25200.,tscm):closest_val(32400.,tscm)-1, \
                        :)

  thtllas_tavg09 = dim_avg_n_Wrap(thtllas_09,0)
  thtlctl_tavg09 = dim_avg_n_Wrap(thtlctl_09,0)
  thtlt1_tavg09  = dim_avg_n_Wrap(thtlt1_09,0)
  thtlt2_tavg09  = dim_avg_n_Wrap(thtlt2_09,0)

  thtllas_11 = thtllas_K(closest_val(32400.,twrf):closest_val(39600.,twrf)-1, \
                         :)
  thtlctl_11 = thtlctl_K(closest_val(32400.,tscm):closest_val(39600.,tscm)-1, \
                         :)
  thtlt1_11  = thtlt1_K(closest_val(32400.,tscm):closest_val(39600.,tscm)-1, \
                        :)
  thtlt2_11  = thtlt2_K(closest_val(32400.,tscm):closest_val(39600.,tscm)-1, \
                        :)

  thtllas_tavg11 = dim_avg_n_Wrap(thtllas_11,0)
  thtlctl_tavg11 = dim_avg_n_Wrap(thtlctl_11,0)
  thtlt1_tavg11  = dim_avg_n_Wrap(thtlt1_11,0)
  thtlt2_tavg11  = dim_avg_n_Wrap(thtlt2_11,0)

  thtllas_13 = thtllas_K(closest_val(39600.,twrf):closest_val(46800.,twrf)-1, \
                         :)
  thtlctl_13 = thtlctl_K(closest_val(39600.,tscm):closest_val(46800.,tscm)-1, \
                         :)
  thtlt1_13  = thtlt1_K(closest_val(39600.,tscm):closest_val(46800.,tscm)-1, \
                        :)
  thtlt2_13  = thtlt2_K(closest_val(39600.,tscm):closest_val(46800.,tscm)-1, \
                        :)

  thtllas_tavg13 = dim_avg_n_Wrap(thtllas_13,0)
  thtlctl_tavg13 = dim_avg_n_Wrap(thtlctl_13,0)
  thtlt1_tavg13  = dim_avg_n_Wrap(thtlt1_13,0)
  thtlt2_tavg13  = dim_avg_n_Wrap(thtlt2_13,0)

  thtllas_15 = thtllas_K(closest_val(46800.,twrf):closest_val(54000.,twrf)-1, \
                         :)
  thtlctl_15 = thtlctl_K(closest_val(46800.,tscm):closest_val(54000.,tscm)-1, \
                         :)
  thtlt1_15  = thtlt1_K(closest_val(46800.,tscm):closest_val(54000.,tscm)-1, \
                        :)
  thtlt2_15  = thtlt2_K(closest_val(46800.,tscm):closest_val(54000.,tscm)-1, \
                        :)

  thtllas_tavg15 = dim_avg_n_Wrap(thtllas_15,0)
  thtlctl_tavg15 = dim_avg_n_Wrap(thtlctl_15,0)
  thtlt1_tavg15  = dim_avg_n_Wrap(thtlt1_15,0)
  thtlt2_tavg15  = dim_avg_n_Wrap(thtlt2_15,0)

; End time averaging
; Height range for plotting
  hl3k = closest_val(3000.,hgtlas_m(2,:))

; END VARIABLE input and calculations
; Open workstation for plotting
  if (MYNN_on) then
    wks = gsn_open_wks(gtype,sims+"-"+date+"_Theta-L")
  else
    wks = gsn_open_wks(gtype,sims+"-"+date+"_Theta-L_NOMYNN")
  end if

; Resources for potential temperature plots
  tres = True

  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@gsnLeftString    = "(a) 0700-0900 CST"
  tres@tiXAxisString    = "Liquid Water Potential Temp. (K)"
  tres@tiYAxisString    = "Height (m)"
  tres@vpWidthF         = 0.99
  tres@vpHeightF        = 0.5
  tres@trXMinF          = 300.
  tres@trXMaxF          = 320.
  tres@trYMaxF          = 3000.
  tres@xyLineColor      = "darkorange1"

; Define ranges for all 3 hour heights
  thtllas_havg03 = thtllas_tavg03(0:hl3k(0))
  thtlctl_havg03 = thtlctl_tavg03(0:hl3k(0))
  thtlt1_havg03  = thtlt1_tavg03(0:hl3k(0))
  thtlt2_havg03  = thtlt2_tavg03(0:hl3k(0))
; Define THE height range
  hlas_range    = hgtlas_m(2,0:hl3k(0))

; Plot LASSO 03 hour
  pltlas = gsn_csm_xy(wks,thtllas_havg03,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg03,hlas_range,tres)

; Resources and plot for t1
;  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg03,hlas_range,tres)

; Resources and plot t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2  = gsn_csm_xy(wks,thtlt2_havg03,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Resources for potential temperature legends
  genres                    = True
  genres@XPosPercent        = 18.5
  genres@YPosPercent        = 71
  lineres                   = True
  lineres@lgLineThicknesses = 3.4
  if (MYNN_on) then
    lineres@lgLineColors    = (/ "darkorange1","purple4","black","black" /)
    lineres@lgDashIndexes   = (/ 0,0,0,1 /)
    textres                 = True
    textres@lgLabels        = (/ "LASSO","CTRL","TEST1","TEST2" /)
  else
    lineres@lgLineColors    = (/ "darkorange1","purple4","black" /)
    lineres@lgDashIndexes   = (/ 0,0,0 /)
    textres                 = True
    textres@lgLabels        = (/ "LASSO","CTRL","TEST1" /)
  end if

; Draw plots and legend, frame workstation
;  drawNDCGrid(wks)
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 05 hour LASSO
  tres@gsnLeftString    = "(b) 0900-1100 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 05 hour
  thtllas_havg05 = thtllas_tavg05(0:hl3k(0))
  thtlctl_havg05 = thtlctl_tavg05(0:hl3k(0))
  thtlt1_havg05  = thtlt1_tavg05(0:hl3k(0))
  thtlt2_havg05  = thtlt2_tavg05(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg05,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg05,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg05,hlas_range,tres)

; Resources and plot for t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2 = gsn_csm_xy(wks,thtlt2_havg05,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 07 hour LASSO
  tres@gsnLeftString    = "(c) 1100-1300 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 07 hour
  thtllas_havg07 = thtllas_tavg07(0:hl3k(0))
  thtlctl_havg07 = thtlctl_tavg07(0:hl3k(0))
  thtlt1_havg07  = thtlt1_tavg07(0:hl3k(0))
  thtlt2_havg07  = thtlt2_tavg07(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg07,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg07,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg07,hlas_range,tres)

; Resources and plot for t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2  = gsn_csm_xy(wks,thtlt2_havg07,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 09 hour LASSO
  tres@gsnLeftString    = "(d) 1300-1500 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 09 hour
  thtllas_havg09 = thtllas_tavg09(0:hl3k(0))
  thtlctl_havg09 = thtlctl_tavg09(0:hl3k(0))
  thtlt1_havg09  = thtlt1_tavg09(0:hl3k(0))
  thtlt2_havg09  = thtlt2_tavg09(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg09,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg09,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg09,hlas_range,tres)

; Resources and plot for t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2  = gsn_csm_xy(wks,thtlt2_havg09,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 11 hour LASSO
  tres@gsnLeftString    = "(e) 1500-1700 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 11 hour
  thtllas_havg11 = thtllas_tavg11(0:hl3k(0))
  thtlctl_havg11 = thtlctl_tavg11(0:hl3k(0))
  thtlt1_havg11  = thtlt1_tavg11(0:hl3k(0))
  thtlt2_havg11  = thtlt2_tavg11(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg11,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg11,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg11,hlas_range,tres)

; Resources and plot for t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2  = gsn_csm_xy(wks,thtlt2_havg11,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 13 hour LASSO
  tres@gsnLeftString    = "(f) 1700-1900 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 13 hour
  thtllas_havg13 = thtllas_tavg13(0:hl3k(0))
  thtlctl_havg13 = thtlctl_tavg13(0:hl3k(0))
  thtlt1_havg13  = thtlt1_tavg13(0:hl3k(0))
  thtlt2_havg13  = thtlt2_tavg13(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg13,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg13,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg13,hlas_range,tres)

; Resources and plot for t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2  = gsn_csm_xy(wks,thtlt2_havg13,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

; Resources for 15 hour LASSO
  tres@gsnLeftString    = "(g) 1900-2100 CST"
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "darkorange1"

; Define ranges for 15 hour
  thtllas_havg15 = thtllas_tavg15(0:hl3k(0))
  thtlctl_havg15 = thtlctl_tavg15(0:hl3k(0))
  thtlt1_havg15  = thtlt1_tavg15(0:hl3k(0))
  thtlt2_havg15  = thtlt2_tavg15(0:hl3k(0))

; Plot LASSO
  pltlas = gsn_csm_xy(wks,thtllas_havg15,hlas_range,tres)

; Resources and plot for ctl
  tres@xyLineColor      = "purple4"

  pltctl = gsn_csm_xy(wks,thtlctl_havg15,hlas_range,tres)

; Resources and plot for t1
  tres@xyDashPattern    = 0
  tres@xyLineColor      = "black"

  pltt1  = gsn_csm_xy(wks,thtlt1_havg15,hlas_range,tres)

; Resources and plot for t2
  if (MYNN_on) then
    tres@xyDashPattern  = 1

    pltt2  = gsn_csm_xy(wks,thtlt2_havg15,hlas_range,tres)
  end if

; Overlay plots
  overlay(pltlas,pltctl)
  overlay(pltlas,pltt1)
  if (MYNN_on) then
    overlay(pltlas,pltt2)
  end if

; Draw plots and legend, frame workstation
  draw(pltlas)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

  print("Complete: "+systemfunc("date"))

end

