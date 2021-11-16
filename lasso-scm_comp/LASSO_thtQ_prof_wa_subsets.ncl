load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "scm_press_to_hgt.ncl"

undef("LASSO_thtQ_prof_wa_subsets")

procedure LASSO_thtQ_prof_wa_subsets(yyyy,mm,dd,hh)

begin

; User modification area, the forcing and directories vary between
; LASSO simulations

  gtype = "png"

  phys  = "GFS_v16" ; "GFS_v16","GSD_v1","csawmg","GFS_v15p2"

  year  = yyyy
  month = mm
  day   = dd
  hour  = hh

  udate = year+"-"+month+"-"+day+" "+hour+":00:00"
  date  = year+month+day
  cycle = year+month+day+hour

  rdir = "/work/noaa/ufs-phys/ekalina/lasso-les/2018_from_wayne/"

  diro = "/work/noaa/ufs-phys/ekalina/ccpp-scm-20210816/scm/run/"+ \
         "output_LASSO_"+date+"_s02_SCM_GFS_v16/"

  dir_comp = "/work/noaa/ufs-phys/ekalina/lasso-les/comparison_data/"

;  dirstop = "/glade/u/home/damico/SCMv4p1_update/gmtb-scm/scm/bin/" ;PSFC/"

;  dirt1 = "output_LASSO_"+date+"_"+sims+"_SCM_"+t1+"/"
;  dirt2 = "output_LASSO_"+date+"_"+sims+"_SCM_"+t2+"/"

  file_all = "output.nc"

; Constants
  R_dry = 287.058 ; ideal gas constant for dry air (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)

  print("Started: "+systemfunc("date"))

; Read vertical levels to interpolate LASSO and SCM data onto
; Need a consistent height grid so that we can composite multiple cases together.
  data = readAsciiTable("./interp_levs.txt",2,"float",0)
  zi_m = data(:,1)

; Add LASSO files
  flas = addfile(rdir+"wrfstat_extracted_s02_"+year+"-"+month+"-"+day+"_"+hour+"_00_00.nc","r")

; Add SCM files
  fctl = addfile(diro+file_all,"r")
;  ft1  = addfile(dirstop+dirt1+file_all,"r")
;  ft2  = addfile(dirstop+dirt2+file_all,"r")

; SCM time
  Time_s = fctl->time_inst

  hscm       = Time_s
  hscm       = Time_s / 60. / 60.
  hscm@units = "hours since "+udate

; Variables from LASSO
  thtlas_nat_K   = flas->CSP_TH ; potential temperature
  rvlas_nat_kgkg = flas->CSP_QV ; water vapor mixing ratio
  ulas           = flas->CSP_U  ; x(u)-wind component
  vlas           = flas->CSP_V  ; y(v)-wind component
  ustarlas_ms    = flas->CST_UST ; friction velocity
  hgtlas_m       = flas->CSP_Z  ; height
  qclas          = flas->CSP_QC ; cloud water

; LASSO wind speed and direction
  wspdlas_nat_ms = (ulas^2. + vlas^2.)^0.5

; SCM output variables
  presctl_Pa     = rm_single_dims(fctl->pres)
  tmpctl_nat_K   = rm_single_dims(fctl->T)
  qvctl_nat_kgkg = rm_single_dims(fctl->qv) ; specific humidity!
  uctl           = rm_single_dims(fctl->u)
  vctl           = rm_single_dims(fctl->v)
  psfcctl        = rm_single_dims(fctl->pres_s)

; Converting SCM winds from u/v to spd/dir
  wspdctl_nat_ms = (uctl^2. + vctl^2.)^0.5

; SCM tendencies
  ntend=10
  tendency_names=(/0,1,2,3,4,5,6,7,8,9/)
  tendency_names@description="tendency identifier: lwrad,swrad,pbl,dconv,sconv,micro,ogwd,cgwd,totphys,force"
  tendency_names@units="none"

  temp_get_dims=fctl->dT_dt_lwrad
  newsize=array_append_record(dimsizes(temp_get_dims),ntend,0)

  ttendctl_Ks=new(newsize,"float")
  qtendctl_kgkgs=new(newsize,"float")
  utendctl_mss=new(newsize,"float")
  vtendctl_mss=new(newsize,"float")

  ttendctl_Ks(:,:,:,0) = fctl->dT_dt_lwrad
  ttendctl_Ks(:,:,:,1) = fctl->dT_dt_swrad
  ttendctl_Ks(:,:,:,2) = fctl->dT_dt_pbl
  ttendctl_Ks(:,:,:,3) = fctl->dT_dt_deepconv
  ttendctl_Ks(:,:,:,4) = fctl->dT_dt_shalconv
  ttendctl_Ks(:,:,:,5) = fctl->dT_dt_micro
  ttendctl_Ks(:,:,:,6) = fctl->dT_dt_ogwd
  ttendctl_Ks(:,:,:,7) = fctl->dT_dt_cgwd
  ttendctl_Ks(:,:,:,8) = fctl->dT_dt_phys
  ttendctl_Ks(:,:,:,9) = (/fctl->T_force_tend/)

  qtendctl_kgkgs(:,:,:,2) = fctl->dq_dt_pbl
  qtendctl_kgkgs(:,:,:,3) = fctl->dq_dt_deepconv
  qtendctl_kgkgs(:,:,:,4) = fctl->dq_dt_shalconv
  qtendctl_kgkgs(:,:,:,5) = fctl->dq_dt_micro
  qtendctl_kgkgs(:,:,:,8) = fctl->dq_dt_phys
  qtendctl_kgkgs(:,:,:,9) = (/fctl->qv_force_tend/)

  utendctl_mss(:,:,:,2) = fctl->du_dt_pbl
  utendctl_mss(:,:,:,3) = fctl->du_dt_deepconv
  utendctl_mss(:,:,:,4) = fctl->du_dt_shalconv
  utendctl_mss(:,:,:,6) = fctl->du_dt_ogwd
  utendctl_mss(:,:,:,7) = fctl->du_dt_cgwd
  utendctl_mss(:,:,:,8) = fctl->du_dt_phys
  utendctl_mss(:,:,:,9) = (/fctl->u_force_tend/)

  vtendctl_mss(:,:,:,2) = fctl->dv_dt_pbl
  vtendctl_mss(:,:,:,3) = fctl->dv_dt_deepconv
  vtendctl_mss(:,:,:,4) = fctl->dv_dt_shalconv
  vtendctl_mss(:,:,:,6) = fctl->dv_dt_ogwd
  vtendctl_mss(:,:,:,7) = fctl->dv_dt_cgwd
  vtendctl_mss(:,:,:,8) = fctl->dv_dt_phys
  vtendctl_mss(:,:,:,9) = (/fctl->v_force_tend/)

; Convert units and remove singleton dimension for tendencies.
; Express tendencies in */hr instead of */s.
; Express moisture tendency in g/kg/hr instead of kg/kg/s.
; Get the wind speed tendency from the separate u/v component tendencies (easier to interpret).
; Is that last one mathematically correct?
  ttendctl_nat_Khr = 3600.*rm_single_dims(ttendctl_Ks)
  qtendctl_nat_gkghr = 1000.*3600.*rm_single_dims(qtendctl_kgkgs)
  wspdtendctl_nat_mshr = 3600.*(rm_single_dims(utendctl_mss)^2.+rm_single_dims(vtendctl_mss)^2.)^0.5

; Calculate SCM height.
  hgtscm_m = scm_press_to_hgt(psfcctl,presctl_Pa,tmpctl_nat_K,qvctl_nat_kgkg,0.)
  hgtscm3d = conform(ttendctl_nat_Khr,hgtscm_m,(/0,1/))

; SCM specific humidity to water vapor mixing ratio.
  rvctl_nat_kgkg = qvctl_nat_kgkg/(1.-qvctl_nat_kgkg)

; SCM temperature to potential temperature
  thtctl_nat_K = tmpctl_nat_K
  thtctl_nat_K = tmpctl_nat_K * ((P00 / presctl_Pa)^(R_dry / c_p))

;  thtt1_K = tmpt1_K
;  thtt1_K = tmpt1_K * ((P00 / prest1_Pa)^(R_dry / c_p))
;
;  thtt2_K = tmpt2_K
;  thtt2_K = tmpt2_K * ((P00 / prest2_Pa)^(R_dry / c_p))

  thtctl_K   = linint1_n(hgtscm_m,thtctl_nat_K,False,zi_m,0,1)
  rvctl_kgkg = linint1_n(hgtscm_m,rvctl_nat_kgkg,False,zi_m,0,1)
  wspdctl_ms = linint1_n(hgtscm_m,wspdctl_nat_ms,False,zi_m,0,1)

  thtlas_K   = linint1_n(hgtlas_m,thtlas_nat_K,False,zi_m,0,1)
  rvlas_kgkg = linint1_n(hgtlas_m,rvlas_nat_kgkg,False,zi_m,0,1)
  wspdlas_ms = linint1_n(hgtlas_m,wspdlas_nat_ms,False,zi_m,0,1)

  ttendctl_Khr = linint1_n(hgtscm3d,ttendctl_nat_Khr,False,zi_m,0,1)
  qtendctl_gkghr = linint1_n(hgtscm3d,qtendctl_nat_gkghr,False,zi_m,0,1)
  wspdtendctl_mshr = linint1_n(hgtscm3d,wspdtendctl_nat_mshr,False,zi_m,0,1)

  thtctl_K@description = "SCM potential temperature"
  thtctl_K@units       = "K"
  thtctl_K!0           = "Time_s"
  thtctl_K!1           = "bottom_top"

  thtlas_K@description = "LASSO potential temperature"
  thtlas_K@units       = "K"
  thtlas_K!0           = "Time_s"
  thtlas_K!1           = "bottom_top"

; Convert all water vapor mixing ratio to g kg-1 (easier to interpret)
  rvlas_gkg = rvlas_kgkg
  rvlas_gkg = rvlas_kgkg * 1000.
  rvctl_gkg = rvctl_kgkg
  rvctl_gkg = rvctl_kgkg * 1000.

  rvlas_gkg@description = "LASSO water vapor mixing ratio"
  rvlas_gkg@units       = "g kg-1"
  rvlas_gkg!0           = "Time_s"
  rvlas_gkg!1           = "bottom_top"

  rvctl_gkg@description = "SCM water vapor mixing ratio"
  rvctl_gkg@units       = "g kg-1"
  rvctl_gkg!0           = "Time_s"
  rvctl_gkg!1           = "bottom_top"

; Averaging time periods, two hour time averages for 3, 5, 7, 9, 11, 13,
; and 15 hrs.

  startend = fspan(3600.,54000.,8)

  thtlas_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m)/),float)
  thtctl_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m)/),float)

  rvlas_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m)/),float)
  rvctl_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m)/),float)

  wspdlas_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m)/),float)
  wspdctl_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m)/),float)

  ttendctl_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m),ntend/),float)
  qtendctl_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m),ntend/),float)
  wspdtendctl_tavg = new((/dimsizes(startend)-1,dimsizes(zi_m),ntend/),float)

  do tdx=0,dimsizes(startend)-2

    good_thtlas = thtlas_K(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:)
    good_thtctl = thtctl_K(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:)

    good_rvlas = rvlas_gkg(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:)
    good_rvctl = rvctl_gkg(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:)

    good_wspdlas = wspdlas_ms(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:)
    good_wspdctl = wspdctl_ms(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:)

    good_ttendctl = ttendctl_Khr(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:,:)
    good_qtendctl = qtendctl_gkghr(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:,:)
    good_wspdtendctl = wspdtendctl_mshr(closest_val(startend(tdx),Time_s):closest_val(startend(tdx+1),Time_s)-1,:,:)

    thtlas_tavg(tdx,:) = dim_avg_n_Wrap(good_thtlas,0)
    thtctl_tavg(tdx,:) = dim_avg_n_Wrap(good_thtctl,0)

    rvlas_tavg(tdx,:) = dim_avg_n_Wrap(good_rvlas,0)
    rvctl_tavg(tdx,:) = dim_avg_n_Wrap(good_rvctl,0)

    wspdlas_tavg(tdx,:) = dim_avg_n_Wrap(good_wspdlas,0)
    wspdctl_tavg(tdx,:) = dim_avg_n_Wrap(good_wspdctl,0)

    ttendctl_tavg(tdx,:,:) = dim_avg_n_Wrap(good_ttendctl,0)
    qtendctl_tavg(tdx,:,:) = dim_avg_n_Wrap(good_qtendctl,0)
    wspdtendctl_tavg(tdx,:,:) = dim_avg_n_Wrap(good_wspdtendctl,0)

    delete(good_thtlas)
    delete(good_thtctl)

    delete(good_rvlas)
    delete(good_rvctl)

    delete(good_ttendctl)
    delete(good_qtendctl)
    delete(good_wspdtendctl)

  end do

  thtlas_tavg@description="Time-averaged vertical profile of LASSO potential temperature"
  thtlas_tavg@units="K"

  thtctl_tavg@description="Time-averaged vertical profile of SCM potential temperature"
  thtctl_tavg@units="K"

  rvlas_tavg@description="Time-averaged vertical profile of LASSO water vapor mixing ratio"
  rvlas_tavg@units="g kg-1"

  rvctl_tavg@description="Time-averaged vertical profile of SCM water vapor mixing ratio"
  rvctl_tavg@units="g kg-1"

  wspdlas_tavg@description="Time-averaged vertical profile of LASSO wind speed"
  wspdlas_tavg@units="m s-1"

  wspdctl_tavg@description="Time-averaged vertical profile of SCM wind speed"
  wspdctl_tavg@units="m s-1"

  ttendctl_tavg@description="Time-averaged vertical profile of SCM temperature tendency"
  ttendctl_tavg@units="K hr-1"

  qtendctl_tavg@description="Time-averaged vertical profile of SCM specific humidity tendency"
  qtendctl_tavg@units="g kg-1 hr-1"

  wspdtendctl_tavg@description="Time-averaged vertical profile of SCM wind speed tendency"
  wspdtendctl_tavg@units="m s-1 hr-1"

; End time averaging
; Open workstation for plotting
  wks = gsn_open_wks(gtype,diro+cycle+"_"+phys+"_Theta")

; Define title strings
  profile_times_str = (/"0700-0900 CST","0900-1100 CST","1100-1300 CST", \
                        "1300-1500 CST","1500-1700 CST","1700-1900 CST", \
                        "1900-2100 CST"/)

  profile_times = (/700,900,1100,1300,1500,1700,1900/)
  profile_times@description="Start of two-hour time-averaging periods for vertical profiles"
  profile_times@units="central standard time"

; Resources for potential temperature plots
  tres = True

  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@tiXAxisString    = "Potential Temp. (K)"
  tres@tiYAxisString    = "Height (m)"
  tres@vpWidthF         = 0.99
  tres@vpHeightF        = 0.5
  tres@trXMinF          = 300.
  tres@trXMaxF          = 315.
  tres@trYMaxF          = 3000.

; Resources for potential temperature legends
  genres                    = True
  genres@XPosPercent        = 18.5
  genres@YPosPercent        = 71
  lineres                   = True
  lineres@lgLineThicknesses = 3.4
  lineres@lgLineColors      = (/ "darkorange1","black" /)
  lineres@lgDashIndexes     = (/ 0,0 /)
  textres                   = True
  textres@lgLabels          = (/ "LASSO","SCM" /)

  do tdx=0,dimsizes(startend)-2

    tres@gsnLeftString = profile_times_str(tdx)
    tres@xyLineColor = "darkorange1"
    pltlas = gsn_csm_xy(wks,thtlas_tavg(tdx,:),zi_m,tres)
    
    tres@xyLineColor = "black"
    pltctl = gsn_csm_xy(wks,thtctl_tavg(tdx,:),zi_m,tres)
    
    overlay(pltlas,pltctl)

    draw(pltlas)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

  tres@trXMinF          = 3.
  tres@trXMaxF          = 18.
  tres@tiXAxisString    = "Water vapor mixing ratio (g/kg)"

  wks = gsn_open_wks(gtype,diro+cycle+"_"+phys+"_rv")

  do tdx=0,dimsizes(startend)-2

    tres@gsnLeftString = profile_times_str(tdx)
    tres@xyLineColor = "darkorange1"
    pltlas = gsn_csm_xy(wks,rvlas_tavg(tdx,:),zi_m,tres)

    tres@xyLineColor = "black"
    pltctl = gsn_csm_xy(wks,rvctl_tavg(tdx,:),zi_m,tres)

    overlay(pltlas,pltctl)

    draw(pltlas)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of relevant variables
; Appending to existing file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  fout = dir_comp+"LASSO_SCM_comp_"+date+".nc"

  fo = addfile(fout,"w")

; Define the dimensions
  dimNames = (/ "profile_times","tendency_names" /)
  dimSizes = (/ dimsizes(profile_times_str),ntend/)
  dimUnlim = (/ False,False /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"profile_times",typeof(profile_times),"profile_times")
  filevarattdef(fo,"profile_times",profile_times)
  fo->profile_times = (/ profile_times /)

  filevardef(fo,"tendency_names",typeof(tendency_names),"tendency_names")
  filevarattdef(fo,"tendency_names",tendency_names)
  fo->tendency_names = (/ tendency_names /)

  filevardef(fo,"theta_profile_LAS",typeof(thtlas_tavg),(/"profile_times","bottom_top"/))
  filevarattdef(fo,"theta_profile_LAS",thtlas_tavg)
  fo->theta_profile_LAS = (/ thtlas_tavg /)

  filevardef(fo,"theta_profile_SCM",typeof(thtctl_tavg),(/"profile_times","bottom_top"/))
  filevarattdef(fo,"theta_profile_SCM",thtctl_tavg)
  fo->theta_profile_SCM = (/ thtctl_tavg /)

  filevardef(fo,"rv_profile_LAS",typeof(rvlas_tavg),(/"profile_times","bottom_top"/))
  filevarattdef(fo,"rv_profile_LAS",rvlas_tavg)
  fo->rv_profile_LAS = (/ rvlas_tavg /)
  
  filevardef(fo,"rv_profile_SCM",typeof(rvctl_tavg),(/"profile_times","bottom_top"/))
  filevarattdef(fo,"rv_profile_SCM",rvctl_tavg)
  fo->rv_profile_SCM = (/ rvctl_tavg /)

  filevardef(fo,"wspd_profile_LAS",typeof(wspdlas_tavg),(/"profile_times","bottom_top"/))
  filevarattdef(fo,"wspd_profile_LAS",wspdlas_tavg)
  fo->wspd_profile_LAS = (/ wspdlas_tavg /)

  filevardef(fo,"wspd_profile_SCM",typeof(wspdctl_tavg),(/"profile_times","bottom_top"/))
  filevarattdef(fo,"wspd_profile_SCM",wspdctl_tavg)
  fo->wspd_profile_SCM = (/ wspdctl_tavg /)

  filevardef(fo,"t_tend_profile_SCM",typeof(ttendctl_tavg),(/"profile_times","bottom_top","tendency_names"/))
  filevarattdef(fo,"t_tend_profile_SCM",ttendctl_tavg)
  fo->t_tend_profile_SCM = (/ ttendctl_tavg /)

  filevardef(fo,"q_tend_profile_SCM",typeof(qtendctl_tavg),(/"profile_times","bottom_top","tendency_names"/))
  filevarattdef(fo,"q_tend_profile_SCM",qtendctl_tavg)
  fo->q_tend_profile_SCM = (/ qtendctl_tavg /)

  filevardef(fo,"wspd_tend_profile_SCM",typeof(wspdtendctl_tavg),(/"profile_times","bottom_top","tendency_names"/))
  filevarattdef(fo,"wspd_tend_profile_SCM",wspdtendctl_tavg)
  fo->wspd_tend_profile_SCM = (/ wspdtendctl_tavg /)

  print("Wrote to file -> "+fout)
  print("Complete: "+systemfunc("date"))

end
