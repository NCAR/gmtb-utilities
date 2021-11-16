load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "scm_press_to_hgt.ncl"

undef("LASSO_thtQ_wa_subsets")

procedure LASSO_thtQ_wa_subsets(yyyy,mm,dd,hh)

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
  thtlas_nat_K   = flas->CSP_TH ; pot temp
  rvlas_nat_kgkg = flas->CSP_QV ; water vapor mixing ratio
  hgtlas_m       = flas->CSP_Z  ; height

; SCM output variables
  presscm_Pa     = rm_single_dims(fscm->pres)
  tmpscm_nat_K   = rm_single_dims(fscm->T)
  qvscm_nat_kgkg = rm_single_dims(fscm->qv) ; specific humidity!
  psfcscm        = rm_single_dims(fscm->pres_s)

; Calculate SCM height.
  hgtscm_m = scm_press_to_hgt(psfcscm,presscm_Pa,tmpscm_nat_K,qvscm_nat_kgkg,0.)

; SCM specific humidity to water vapor mixing ratio.
  rvscm_nat_kgkg = qvscm_nat_kgkg/(1.-qvscm_nat_kgkg)

; SCM temperature to potential temperature
  thtscm_nat_K = tmpscm_nat_K
  thtscm_nat_K = tmpscm_nat_K * ((P00 / presscm_Pa)^(R_dry / c_p))

  thtscm_nat_K@description = "potential temperature"

; Matching the vertical coordinates of the column T,q (SCM to LASSO)
  thtscm_K   = linint1_n(hgtscm_m,thtscm_nat_K,False,zi_m,0,1)
  rvscm_kgkg = linint1_n(hgtscm_m,rvscm_nat_kgkg,False,zi_m,0,1)

  thtlas_K   = linint1_n(hgtlas_m,thtlas_nat_K,False,zi_m,0,1)
  rvlas_kgkg = linint1_n(hgtlas_m,rvlas_nat_kgkg,False,zi_m,0,1)

  thtscm_K@description = "SCM potential temperature"
  thtscm_K@units       = "K"
  thtscm_K!0           = "Time_s"
  thtscm_K!1           = "bottom_top" 

  thtlas_K@description = "LASSO potential temperature"
  thtlas_K@units       = "K"
  thtlas_K!0           = "Time_s"
  thtlas_K!1           = "bottom_top"

; Convert all water vapor mixing ratio to g kg-1 (easier to interpret)
  rvlas_gkg = rvlas_kgkg
  rvlas_gkg = rvlas_kgkg * 1000.
  rvscm_gkg = rvscm_kgkg
  rvscm_gkg = rvscm_kgkg * 1000.

  rvlas_gkg@description = "LASSO water vapor mixing ratio"
  rvlas_gkg@units       = "g kg-1"
  rvlas_gkg!0           = "Time_s"
  rvlas_gkg!1           = "bottom_top"

  rvscm_gkg@description = "SCM water vapor mixing ratio"
  rvscm_gkg@units       = "g kg-1"
  rvscm_gkg!0           = "Time_s"
  rvscm_gkg!1           = "bottom_top"

; Computing differences for plotting
  thts_df   = thtscm_K
  thts_df   = thtscm_K - thtlas_K
  thts_df@description = "Potential temperature difference (SCM-LASSO)"
  thts_df@units       = "K"
  thts_df!0 = "time_dim"

  thts_diff = thts_df(bottom_top|:,time_dim|:)

  thts_diff@description = "Potential temperature difference (SCM-LASSO)"
  thts_diff@units       = "K"
  thts_diff!0           = "bottom_top"
  thts_diff!1           = "Time_s"

  rvs_df   = rvscm_gkg
  rvs_df   = rvscm_gkg - rvlas_gkg
  rvs_df@description = "Water vapor mixing ratio difference (SCM-LASSO)"
  rvs_df@units       = "g kg-1"
  rvs_df!0 = "time_dim"

  rvs_diff = rvs_df(bottom_top|:,time_dim|:)

  rvs_diff@description = "Water vapor mixing ratio difference (SCM-LASSO)"
  rvs_diff@units       = "g kg-1"
  rvs_diff!0           = "bottom_top"
  rvs_diff!1           = "Time_s"

; Open workstation
  wks = gsn_open_wks(gtype,diro+cycle+"_"+phys+"_Thtrv")

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

  res = True

  res@gsnMaximize              = True
  res@cnFillOn                 = True
  res@cnLinesOn                = False
  res@sfXArray                 = hscm
  res@sfYArray                 = zi_m
  res@gsnLeftString            = "SCM - LASSO Pot Temp"
  res@gsnRightString           = thts_diff@units
  res@tiXAxisString            = "US CST"
  res@tiYAxisString            = "Height (m)"
  res@cnLevelSelectionMode     = "ManualLevels"
  res@cnMinLevelValF           = -2.
  res@cnMaxLevelValF           = 2.
  res@cnLevelSpacingF          = 0.4
  res@gsnYAxisIrregular2Linear = True
  res@tmXBMode                 = "Explicit"
  res@tmXBValues               = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues          = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels               = (/ "0600","0900","1200","1500", \
                                    "1800","2100" /)
  res@trYMaxF                  = 3000.

  plot = gsn_csm_contour(wks,thts_diff,res)

  gsn_reverse_colormap(wks)

  res@gsnLeftString            = "SCM - LASSO r~B~v~N~"
  res@gsnRightString           = "g kg~S~-1~N~"
  res@cnMinLevelValF           = -3.
  res@cnMaxLevelValF           = 3.
  res@cnLevelSpacingF          = 0.5

  plot = gsn_csm_contour(wks,rvs_diff,res)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of relevant variables
; Appending to existing file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  fout = dir_comp+"LASSO_SCM_comp_"+date+".nc"

  fo = addfile(fout,"w")

  filevardef(fo,"theta_diff",typeof(thts_df),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"theta_diff",thts_df)
  fo->theta_diff = (/ thts_df /)

  filevardef(fo,"rv_diff",typeof(rvs_df),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"rv_diff",rvs_df)
  fo->rv_diff = (/ rvs_df /)

  print("Wrote to file -> "+fout)
  print("Complete: "+systemfunc("date"))

end

