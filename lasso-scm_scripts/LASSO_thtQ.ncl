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
;  force = "VARA"
  sn    = "8"
  sims  = "SID"+sn ; "SID"+sn,"MSDA+UFSsflx"
  phys  = "GFS_v16beta" ; "GFS_v16beta","GFS_v15p2","GSD_v1","csawmg", \
;-------- "GFS_v16beta_MYNN","v16beta_MYNNrad","v16beta_Thomp","satmedmf"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_20190714_rawmodel/raw_model/"

  diro = "/glade/u/home/damico/SCMv4p1_update/gmtb-scm/scm/bin/"+ \
         "output_LASSO_"+date+"_"+sims+"_SCM_"+phys+"/"

;  diro = "/glade/u/home/damico/SCMv4/gmtb-scm/scm/bin/output_LASSO_"+ \
;         date+"_"+sims+"_SCM_"+phys+"/"

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
  flas = addfile(rdir+"LASSO_20190714_SUBSET.nc","r")
  fscm = addfile(diro+"output.nc","r")

; Times
  hwrf = flas->Time_hr 
  twrf = flas->Time_s

  tscm = fscm->time

  hscm       = tscm
  hscm       = tscm / 60. / 60.
  hscm@units = "hours since "+udate

; LASSO output variables
  thtlas_K   = flas->T      ; perturbation pot temp
  qvlas_kgkg = flas->QVAPOR ; water vapor mixing ratio
  preslas_Pa = flas->P      ; pressure
  hgtlas_m   = flas->height ; height

; SCM output variables
  presscm_Pa = fscm->pres
  tmpscm_127 = fscm->T
  qvscm_127  = fscm->qv

; SCM temperature to potential temperature
  thtscm_127 = tmpscm_127
  thtscm_127 = tmpscm_127 * ((P00 / presscm_Pa)^(R_dry / c_p))

  thtscm_127@description = "potential temperature"

  thtscm_K = new((/ dimsizes(thtlas_K) /),float)
  do i=0,dimsizes(thtlas_K(:,0))-1,1
    thtscm_K(i,:) = linint1(presscm_Pa(i,:,0),thtscm_127(i,:,0),False, \
                            preslas_Pa(i,:),0)
    do j=0,dimsizes(thtlas_K(0,:))-1,1
      if (ismissing(thtscm_K(i,j))) then
        thtscm_K(i,j) = thtscm_127(i,j,0)
      end if
    end do
  end do
  thtscm_K@description = "potential temperature"
  thtscm_K@units       = "K"
  thtscm_K!0           = "Time_s"
  thtscm_K!1           = "bottom_top" 

  qvscm_kgkg = new((/ dimsizes(qvlas_kgkg) /),float)
  do i=0,dimsizes(qvlas_kgkg(:,0))-1,1
    qvscm_kgkg(i,:) = linint1(presscm_Pa(i,:,0),qvscm_127(i,:,0),False, \
                              preslas_Pa(i,:),0)
    do j=0,dimsizes(qvlas_kgkg(0,:))-1,1
      if (ismissing(qvscm_kgkg(i,j))) then
        qvscm_kgkg(i,j) = qvscm_127(i,j,0)
      end if
    end do
  end do
  qvscm_kgkg@description = "water vapor specific humidity"
  qvscm_kgkg@units       = "kg kg-1"
  qvscm_kgkg!0           = "Time_s"
  qvscm_kgkg!1           = "bottom_top"

; Convert all specific humidity to g kg-1 (easier to interpret)
  qvlas_gkg = qvlas_kgkg
  qvlas_gkg = qvlas_kgkg * 1000.
  qvscm_gkg = qvscm_kgkg
  qvscm_gkg = qvscm_kgkg * 1000.

  qvlas_gkg@units = "g kg-1"
  qvscm_gkg@units = "g kg-1"

; Computing differences for plotting
  thts_df   = thtscm_K
  thts_df   = thtscm_K - thtlas_K
  thts_df!0 = "time_dim"

  thts_diff = thts_df(bottom_top|:,time_dim|:)

  qvs_df   = qvscm_gkg
  qvs_df   = qvscm_gkg - qvlas_gkg
  qvs_df!0 = "time_dim"

  qvs_diff = qvs_df(bottom_top|:,time_dim|:)

; Height range for plotting
  hl3k = closest_val(3000.,hgtlas_m(1,:))

; Open workstation
  wks = gsn_open_wks(gtype,sims+"-"+date+"_ThtQ-UpdSfc")

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
  res@sfYArray                 = hgtlas_m(1,0:hl3k(0))
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

  plot = gsn_csm_contour(wks,thts_diff(0:hl3k(0),:),res)

  gsn_reverse_colormap(wks)

  res@gsnLeftString            = "SCM - LASSO q~B~v~N~"
  res@gsnRightString           = "g kg~S~-1~N~"
  res@cnMinLevelValF           = -3.
  res@cnMaxLevelValF           = 3.
  res@cnLevelSpacingF          = 0.5

  plot = gsn_csm_contour(wks,qvs_diff(0:hl3k(0),:),res)

  print("Complete: "+systemfunc("date"))

end

