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
  sn    = "8"
  sims  = "SID"+sn ; "SID"+sn,"MSDA+UFSsflx"
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
  flas  = addfile(rdir+"LASSO_"+date+"_SUBSET.nc","r")
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
  thtlas_K   = flas->T      ; potential temperature
  qvlas_kgkg = flas->QVAPOR ; water vapor mixing ratio

; Variables from SCM
  presscm_Pa = fscm->pres
  tmpscm_K   = fscm->T
  qvscm_kgkg = fscm->qv

; SCM temperature to potential temperature
  thtscm_127 = tmpscm_K
  thtscm_127 = tmpscm_K * ((P00 / presscm_Pa)^(R_dry / c_p))

  thtscm_127@description = "potential temperature"

  thtscm_K = new((/ dimsizes(hgtlas_m) /),float)
  do i=0,dimsizes(tscm)-1,1
    thtscm_K(i,:) = linint1_Wrap(presscm_Pa(i,:,0),thtscm_127(i,:,0), \
                                 False,preslas_Pa(i,:),0)
  end do

; 3000 m height definition (most PBLs won't be higher than 3 km, with some
; exceptions)
  hl3k = closest_val(3000.,hgtlas_m(1,:))

; 1.5-theta-increase method to determine PBL height (Nielsen-Gammon et al.
; 2008; Hu et al. 2010). Most accurate in a convective boundary layer,
; so when things are very stable and the PBL is shallow, this method
; might not be ideal.
  minthtscm_K = new((/ dimsizes(tscm) /),float)
  minthtlas_K = new((/ dimsizes(tscm) /),float)
  mindimscm   = new((/ dimsizes(tscm) /),integer)
  mindimlas   = new((/ dimsizes(tscm) /),integer)
  thtscm_1_5K = new((/ dimsizes(tscm) /),float)
  thtlas_1_5K = new((/ dimsizes(tscm) /),float)
  vs1_5       = new((/ dimsizes(tscm) /),integer)
  vl1_5       = new((/ dimsizes(tscm) /),integer)
  pblhscm_m   = new((/ dimsizes(tscm) /),float)
  pblhlas_m   = new((/ dimsizes(tscm) /),float)
  do i=0,dimsizes(tscm)-1,1
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
    pblhscm_m(i)   = hgtlas_m(i,vs1_5(i))
    pblhlas_m(i)   = hgtlas_m(i,vl1_5(i))
  end do

; Open workstation
  wks = gsn_open_wks(gtype,date+"-"+sims+"_PBLH")

; Resources and plotting
  xyres = True

  xyres@gsnMaximize        = True
  xyres@gsnDraw            = False
  xyres@gsnFrame           = False
  xyres@xyLineThicknessF   = 3.4
  xyres@gsnLeftString      = "1.5-Theta-Increase Method"
  xyres@gsnRightString     = sims
  xyres@tiXAxisString      = "US CST"
  xyres@tiYAxisString      = "PBL Height (m)"
  xyres@trYMaxF            = 2400.
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

  print("Complete: "+systemfunc("date"))

end

