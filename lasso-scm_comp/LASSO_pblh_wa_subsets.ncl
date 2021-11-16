load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "scm_press_to_hgt.ncl"

undef("LASSO_pblh_wa_subsets")

procedure LASSO_pblh_wa_subsets(yyyy,mm,dd,hh)

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

; End user modification area
  print("Started: "+systemfunc("date"))

; Constants
  R_dry = 287.058 ; ideal gas constant for dry air (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)

; Read vertical levels to interpolate LASSO and SCM data onto
; Need a consistent height grid so that we can composite multiple cases together.
  data = readAsciiTable("./interp_levs.txt",2,"float",0)
  zi_m = data(:,1)

; Addfiles
  flas = addfile(rdir+"wrfstat_extracted_s02_"+year+"-"+month+"-"+day+"_"+hour+"_00_00.nc","r")
  fscm = addfile(diro+"output.nc","r")

; Times
  Time_s = fscm->time_inst

  hscm       = Time_s
  hscm       = Time_s / 60. / 60.
  hscm@units = "hours since "+udate

; Variables from LASSO
  hgtlas_m       = flas->CSP_Z  ; height
  thtlas_nat_K   = flas->CSP_TH ; potential temperature

; Variables from SCM
  presscm_Pa     = rm_single_dims(fscm->pres)
  tmpscm_nat_K   = rm_single_dims(fscm->T)
  qvscm_nat_kgkg = rm_single_dims(fscm->qv) ; specific humidity!
  psfcscm        = rm_single_dims(fscm->pres_s)

; Calculate SCM height.
  hgtscm_m = scm_press_to_hgt(psfcscm,presscm_Pa,tmpscm_nat_K,qvscm_nat_kgkg,0.)

; SCM temperature to potential temperature
  thtscm_nat_K = tmpscm_nat_K
  thtscm_nat_K = tmpscm_nat_K * ((P00 / presscm_Pa)^(R_dry / c_p))

  thtscm_nat_K@description = "potential temperature"

  thtscm_K = linint1_n_Wrap(hgtscm_m,thtscm_nat_K,False,zi_m,0,1)
  thtlas_K = linint1_n_Wrap(hgtlas_m,thtlas_nat_K,False,zi_m,0,1)

  hl3k = closest_val(3000.,zi_m)

; 1.5-theta-increase method to determine PBL height (Nielsen-Gammon et al.
; 2008; Hu et al. 2010). Most accurate in a convective boundary layer,
; so when things are very stable and the PBL is shallow, this method
; might not be ideal.
  minthtscm_K = new((/ dimsizes(Time_s) /),float)
  minthtlas_K = new((/ dimsizes(Time_s) /),float)
  mindimscm   = new((/ dimsizes(Time_s) /),integer)
  mindimlas   = new((/ dimsizes(Time_s) /),integer)
  thtscm_1_5K = new((/ dimsizes(Time_s) /),float)
  thtlas_1_5K = new((/ dimsizes(Time_s) /),float)
  vs1_5       = new((/ dimsizes(Time_s) /),integer)
  vl1_5       = new((/ dimsizes(Time_s) /),integer)
  pblhscm_m   = new((/ dimsizes(Time_s) /),float)
  pblhlas_m   = new((/ dimsizes(Time_s) /),float)
  do i=1,dimsizes(Time_s)-1,1
    minthtscm_K(i) = min(thtscm_K(i,0:hl3k(0)))
    minthtlas_K(i) = min(thtlas_K(i,0:hl3k(0)))
    mindimscm(i)   = minind(thtscm_K(i,0:hl3k(0)))
    mindimlas(i)   = minind(thtlas_K(i,0:hl3k(0)))
    thtscm_1_5K(i) = minthtscm_K(i) + 1.5
    thtlas_1_5K(i) = minthtlas_K(i) + 1.5
    vs1_5(i)       = closest_val(thtscm_1_5K(i),thtscm_K(i,:))
    vl1_5(i)       = closest_val(thtlas_1_5K(i),thtlas_K(i,:))
    if (vs1_5(i) .lt. mindimscm(i)) then
       vs1_5(i)      = closest_val(thtscm_1_5K(i), \
                                   thtscm_K(i,mindimscm(i):hl3k(0)))
    end if
    pblhscm_m(i)   = zi_m(vs1_5(i))
    pblhlas_m(i)   = zi_m(vl1_5(i))
  end do

  pblhscm_m@description = "SCM PBL height, 1.5-theta-increase method"
  pblhscm_m@units = "m AGL"

  pblhlas_m@description = "LASSO PBL height, 1.5-theta-increase method"
  pblhlas_m@units = "m AGL"

; Open workstation
  wks = gsn_open_wks(gtype,diro+cycle+"_"+phys+"_PBLH")

; Resources and plotting
  xyres = True

  xyres@gsnMaximize        = True
  xyres@gsnDraw            = False
  xyres@gsnFrame           = False
  xyres@xyLineThicknessF   = 3.4
  xyres@gsnLeftString      = "1.5-Theta-Increase Method"
;  xyres@gsnRightString     = sims
  xyres@tiXAxisString      = "US CST"
  xyres@tiYAxisString      = "PBL Height (m)"
  xyres@trYMaxF            = 3200.
  xyres@tmXBMode           = "Explicit"
  xyres@tmXBValues         = (/ 0.,3.,6.,9.,12.,15. /)
  xyres@tmXBMinorValues    = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  xyres@tmXBLabels         = (/ "0600","0900","1200","1500","1800","2100" /)

  pltscm = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      pblhscm_m(1:dimsizes(hscm)-1),xyres)

  xyres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,hscm(1:dimsizes(hscm)-1), \
                      pblhlas_m(1:dimsizes(hscm)-1),xyres)

  overlay(pltscm,pltlas)

; Legend resources
  genres                    = True
  genres@XPosPercent        = 22
  genres@YPosPercent        = 89.5
  lineres                   = True
  lineres@lgLineColors      = (/ "black","darkorange1" /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "SCM","LASSO" /)

  draw(pltscm)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of relevant variables
; Appending to existing file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  fout = dir_comp+"LASSO_SCM_comp_"+date+".nc"

  fo = addfile(fout,"w")

  filevardef(fo,"pblh_SCM",typeof(pblhscm_m),"Time_s")
  filevarattdef(fo,"pblh_SCM",pblhscm_m)
  fo->pblh_SCM = (/ pblhscm_m /)

  filevardef(fo,"pblh_LAS",typeof(pblhlas_m),"Time_s")
  filevarattdef(fo,"pblh_LAS",pblhlas_m)
  fo->pblh_LAS = (/ pblhlas_m /)

  print("Wrote to file -> "+fout)
  print("Complete: "+systemfunc("date"))

end

