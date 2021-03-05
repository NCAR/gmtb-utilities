load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area, the forcing and directories vary between
; LASSO simulations
  gtype = "x11"
;  force = "VARA"
  sn    = "8"
  sims  = "SID"+sn ;"SID"+sn,"MSDA+UFSsflx"
  phys  = "GFS_v16beta_MYNN" ; "GFS_v16beta","GSD_v1","csawmg","GFS_v15p2",
;-------> "GFS_v16beta_MYNN","v16beta_MYNNrad","v16beta_Thomp","satmedmf"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_"+date+"_rawmodel/raw_model/"

  diro = "/glade/u/home/damico/SCMv4p1_update/gmtb-scm/scm/bin/output_"+ \
         "LASSO_"+date+"_"+sims+"_SCM_"+phys+"/"

; End user modification area
  print("Started: "+systemfunc("date"))

; Constants
  R_dry = 287.    ; ideal gas constant for dry air (J kg^-1 K^-1)
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4.*atan(1.)

; Addfiles
  flas = addfile(rdir+"LASSO_"+date+"_SUBSET.nc","r")
  fscm = addfile(diro+"output.nc","r")

; Times
  twrf = flas->Time_s
  hwrf = flas->Time_hr

  tscm = fscm->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hours since "+udate

; Variables from LASSO
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height
  qclas      = flas->QCLOUD ; cloud water mixing ratio
  qrlas      = flas->QRAIN  ; rain water mixing ratio
  cldfralas  = flas->CLDFRA ; cloud fraction

; Convert qc and qr to g kg-1 (easier to interpret)
  qclas_gkg       = qclas
  qclas_gkg       = qclas * 1000.
  qclas_gkg@units = "g kg-1"

  qrlas_gkg       = qrlas
  qrlas_gkg       = qrlas * 1000.
  qrlas_gkg@units = "g kg-1"

; Total cloud water for LASSO
  totcldlas_gkg = qclas_gkg
  totcldlas_gkg = qclas_gkg + qrlas_gkg

; Variables from SCM
  presscm_Pa  = fscm->pres
  tmpscm_K    = fscm->T
  qvscm_kgkg  = fscm->qv
  qcscm_kgkg  = fscm->qc
  qcconv_kgkg = fscm->qc_conv
  qlscm_kgkg  = fscm->ql
  cldfrascm   = fscm->cldcov
  cldconvscm  = fscm->cldcov_conv

; Totaling cloud variables for SCM (cloud fraction + convective cloud fraction)
  totcldfra_127 = cldfrascm
  totcldfra_127 = cldfrascm + cldconvscm

  totqcscm_127 = qcscm_kgkg
  totqcscm_127 = qcscm_kgkg + qcconv_kgkg

  totwat_127 = totqcscm_127
  totwat_127 = totqcscm_127 + qlscm_kgkg

; Matching the vertical resolution of SCM to LASSO
  totcldfra_scm = new((/ dimsizes(hgtlas_m) /),float)
  do i=0,dimsizes(hgtlas_m(:,0))-1,1
    totcldfra_scm(i,:) = linint1_Wrap(presscm_Pa(i,:,0),totcldfra_127(i,:,0), \
                                      False,preslas_Pa(i,:),0)
  end do
  totcldfra_scm!0 = "time_dim"

  totqcscm_kgkg = new((/ dimsizes(hgtlas_m) /),float)
  do i=0,dimsizes(hgtlas_m(:,0))-1,1
    totqcscm_kgkg(i,:) = linint1_Wrap(presscm_Pa(i,:,0),totqcscm_127(i,:,0), \
                                     False,preslas_Pa(i,:),0)
  end do
  totqcscm_kgkg!0 = "time_dim"

  totwatscm_kgkg = new((/ dimsizes(hgtlas_m) /),float)
  do i=0,dimsizes(hgtlas_m(:,0))-1,1
    totwatscm_kgkg(i,:) = linint1_Wrap(presscm_Pa(i,:,0),totwat_127(i,:,0), \
                          False,preslas_Pa(i,:),0)
  end do
  totwatscm_kgkg!0 = "time_dim"

; Convert to qc and totwat to g kg-1
  totqcscm_gkg       = totqcscm_kgkg
  totqcscm_gkg       = totqcscm_kgkg * 1000.
  totqcscm_gkg@units = "g kg-1"

  totwatscm_gkg       = totwatscm_kgkg
  totwatscm_gkg       = totwatscm_kgkg * 1000.
  totwatscm_gkg@units = "g kg-1"

; Reverse the dimension order to plot time on x and height on y
  totcldfra_rev = totcldfra_scm(bottom_top|:,time_dim|:)
  totqcscm_rev  = totqcscm_gkg(bottom_top|:,time_dim|:)
  totwat_rev    = totwatscm_gkg(bottom_top|:,time_dim|:)
  cldfralas_rev = cldfralas(bottom_top|:,Time_s|:)
  qclas_rev     = qclas_gkg(bottom_top|:,Time_s|:)
  totcldlas_rev = totcldlas_gkg(bottom_top|:,Time_s|:)

; Height ranges
  hl3k = closest_val(3500.,hgtlas_m(1,:))

; Open workstation
  wks = gsn_open_wks(gtype,sims+"-"+phys+"_Clouds41")
  gsn_define_colormap(wks,"CBR_wet")

; Resources for cloud fraction
  fres = True

  fres@gsnMaximize          = True
  fres@cnFillOn             = True
  fres@cnLinesOn            = False
  fres@sfXArray             = hscm(1:dimsizes(tscm)-1)
  fres@sfYArray             = hgtlas_m(1,0:hl3k(0))
  fres@gsnLeftString        = "Cloud Fraction"
  fres@gsnRightString       = phys
  fres@tiYAxisString        = "Height (m)"
  fres@tiXAxisString        = "US CST"
  fres@cnLevelSelectionMode = "ManualLevels"
  fres@cnMinLevelValF       = 0.1
  fres@cnMaxLevelValF       = 0.9
  fres@cnLevelSpacingF      = 0.05
  fres@tmXBMode             = "Explicit"
  fres@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  fres@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  fres@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)

  plot = gsn_csm_contour(wks,totcldfra_rev(0:hl3k(0),1:dimsizes(hscm)-1), \
                         fres)

  fres@gsnRightString       = "LASSO"

  plot = gsn_csm_contour(wks,cldfralas_rev(0:hl3k(0),1:dimsizes(hscm)-1), \
                         fres)

  qcres = True

  qcres@gsnMaximize          = True
  qcres@cnFillOn             = True
  qcres@cnLinesOn            = False
  qcres@sfXArray             = hscm(1:dimsizes(tscm)-1)
  qcres@sfYArray             = hgtlas_m(1,0:hl3k(0))
  qcres@gsnLeftString        = "q~B~c~N~ (g kg~S~-1~N~)"
  qcres@gsnRightString       = phys
  qcres@tiYAxisString        = "Height (m)"
  qcres@tiXAxisString        = "US CST"
  qcres@tmXBMode             = "Explicit"
  qcres@tmXBValues           = (/ 0.,3.,6.,9.,12.,15. /)
  qcres@tmXBMinorValues      = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  qcres@tmXBLabels           = (/ "0600","0900","1200","1500","1800","2100" /)
  qcres@cnLevelSelectionMode = "ManualLevels"
  qcres@cnMinLevelValF       = 0.02
  qcres@cnMaxLevelValF       = 0.4
  qcres@cnLevelSpacingF      = 0.04

  plot = gsn_csm_contour(wks,totqcscm_rev(0:hl3k(0),1:dimsizes(hscm)-1), \
                         qcres)

  qcres@gsnRightString       = "LASSO"

  plot = gsn_csm_contour(wks,qclas_rev(0:hl3k(0),1:dimsizes(hscm)-1), \
                         qcres)

  print("Complete: "+systemfunc("date"))

end
