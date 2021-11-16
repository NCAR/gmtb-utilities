load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "scm_press_to_hgt.ncl"

undef("LASSO_cld_wa_subsets")

procedure LASSO_cld_wa_subsets(yyyy,mm,dd,hh)

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
  R_vap = 461.5   ; gas constant for water vapor (J kg^-1 K^-1)
  c_p   = 1004.   ; specific heat at const pressure (J kg^-1 K^-1)
  l_v   = 2.5e6   ; latent heat of vaporization (J kg^-1)
  g     = 9.80665 ; acceleration due tp gravity (m s^-2)
  P00   = 100000. ; initial pressure (Pa)
  pi    = 4.*atan(1.)

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
  hgtlas_m   = flas->CSP_Z  ; height
  qclas      = flas->CSP_QC ; cloud water mixing ratio
  cldfralas  = flas->CST_CLDTOT ; cloud fraction

; Convert qc to g kg-1 (easier to interpret)
  qclas_gkg       = qclas
  qclas_gkg       = qclas * 1000.
  qclas_gkg@units = "g kg-1"

; Variables from SCM
  presscm_Pa  = rm_single_dims(fscm->pres)
  psfcscm     = rm_single_dims(fscm->pres_s)
  tmpscm_K    = rm_single_dims(fscm->T)
  qvscm_kgkg  = rm_single_dims(fscm->qv) ; specific humidity!
  qcscm_kgkg  = rm_single_dims(fscm->qc)
  cldfrascm   = rm_single_dims(fscm->rad_cloud_fraction)

; Calculate SCM height.
  hgtscm_m = scm_press_to_hgt(psfcscm,presscm_Pa,tmpscm_K,qvscm_kgkg,0.)

; Totaling cloud variables for SCM (cloud fraction + convective cloud fraction)
; EAK: no convective cloud fraction or convective qc in SCM output.
  totcldfra_127 = cldfrascm
  totqcscm_127 = qcscm_kgkg

; Matching the vertical resolution of SCM to LASSO
  totcldfra_scm = linint1_n_Wrap(hgtscm_m,totcldfra_127,False,zi_m,0,1)
  totqcscm_kgkg = linint1_n_Wrap(hgtscm_m,totqcscm_127,False,zi_m,0,1)

  ; cldfralas_127 = linint1_n_Wrap(hgtlas_m,cldfralas,False,zi_m,0,1)
  qclas_gkg_127 = linint1_n_Wrap(hgtlas_m,qclas_gkg,False,zi_m,0,1)

  totcldfra_scm!0 = "time_dim"
  totqcscm_kgkg!0 = "time_dim"

; Convert qc to g kg-1
  totqcscm_gkg       = totqcscm_kgkg
  totqcscm_gkg       = totqcscm_kgkg * 1000.
  totqcscm_gkg@units = "g kg-1"

  totcldfra_scm!1 = "bottom_top"
  totqcscm_gkg!1 = "bottom_top"
  ; cldfralas_127!1 = "bottom_top"
  qclas_gkg_127!1 = "bottom_top"
  qclas_gkg_127!0 = "Time_s"

; Reverse the dimension order to plot time on x and height on y
  totcldfra_rev = totcldfra_scm(bottom_top|:,time_dim|:)
  totqcscm_rev  = totqcscm_gkg(bottom_top|:,time_dim|:)
  ; cldfralas_rev = cldfralas_127(bottom_top|:,Time_s|:)
  cldfralas_rev = cldfralas
  qclas_rev     = qclas_gkg_127(bottom_top|:,Time_s|:)

  totcldfra_scm@description = "SCM cloud fraction"
  totcldfra_scm@units = "0-1"

  totqcscm_gkg@description = "SCM cloud water mixing ratio"
  totqcscm_gkg@units = "g kg-1"

  cldfralas_rev@description = "LASSO cloud fraction"
  cldfralas_rev@units = "0-1"

  qclas_gkg_127@description = "LASSO cloud water mixing ratio"
  qclas_gkg_127@units = "g kg-1"

; Open workstation
  wks = gsn_open_wks(gtype,diro+cycle+"_"+phys+"_Clouds")
  gsn_define_colormap(wks,"CBR_wet")

; Resources for cloud fraction
  fres = True

  fres@gsnMaximize          = True
  fres@cnFillOn             = True
  fres@cnLinesOn            = False
  fres@sfXArray             = hscm(1:dimsizes(Time_s)-1)
  fres@sfYArray             = zi_m
  fres@gsnYAxisIrregular2Linear = True
  fres@gsnLeftString        = "Cloud Fraction"
  fres@gsnRightString       = "SCM"
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

  plot = gsn_csm_contour(wks,totcldfra_rev(:,1:dimsizes(hscm)-1),fres)

  fres@gsnRightString       = "LASSO"

  ; plot = gsn_csm_contour(wks,cldfralas_rev(:,1:dimsizes(hscm)-1),fres)

  qcres = True

  qcres@gsnMaximize          = True
  qcres@cnFillOn             = True
  qcres@cnLinesOn            = False
  qcres@sfXArray             = hscm(1:dimsizes(Time_s)-1)
  qcres@sfYArray             = zi_m
  qcres@gsnYAxisIrregular2Linear = True
  qcres@gsnLeftString        = "q~B~c~N~ (g kg~S~-1~N~)"
  qcres@gsnRightString       = "SCM"
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

  plot = gsn_csm_contour(wks,totqcscm_rev(:,1:dimsizes(hscm)-1),qcres)

  qcres@gsnRightString       = "LASSO"

  plot = gsn_csm_contour(wks,qclas_rev(:,1:dimsizes(hscm)-1),qcres)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of relevant variables
; Appending to existing file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  fout = dir_comp+"LASSO_SCM_comp_"+date+".nc"

  fo = addfile(fout,"w")

  filevardef(fo,"cldfra_SCM",typeof(totcldfra_scm),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"cldfra_SCM",totcldfra_scm)
  fo->cldfra_SCM = (/ totcldfra_scm /)

  filevardef(fo,"cldfra_LAS",typeof(cldfralas_rev),"Time_s")
  filevarattdef(fo,"cldfra_LAS",cldfralas_rev)
  fo->cldfra_LAS = (/ cldfralas_rev /)

  filevardef(fo,"qc_SCM",typeof(totqcscm_gkg),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"qc_SCM",totqcscm_gkg)
  fo->qc_SCM = (/ totqcscm_gkg /)

  filevardef(fo,"qc_LAS",typeof(qclas_gkg_127),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"qc_LAS",qclas_gkg_127)
  fo->qc_LAS = (/ qclas_gkg_127 /)

  print("Wrote to file -> "+fout)
  print("Complete: "+systemfunc("date"))

end
