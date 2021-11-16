load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; User modification area

  gtype = "png"

  phys  = "GFS_v16" ; "GFS_v16","GSD_v1","csawmg","GFS_v15p2"

  dirio = "/work/noaa/ufs-phys/ekalina/lasso-les/comparison_data/"

; End user modification area
  print("Started: "+systemfunc("date"))

; Add composite file
  f_mean = addfile(dirio+"LASSO_SCM_composite.nc","r")

; Add case files
  case_list = systemfunc("ls "+dirio+"LASSO_SCM_comp_*.nc")
  f_cases = addfiles(case_list,"r")
  ListSetType(f_cases,"join")

; Times
  Time_h     = 24.*(f_mean->Time_s)
  Time_h@units = "hours since init time"

; Variables
  zi_m        = f_mean->bottom_top

  theta_scm   = f_cases[:]->theta_profile_SCM
  rv_scm      = f_cases[:]->rv_profile_SCM
  wspd_scm    = f_cases[:]->wspd_profile_SCM
  pblh_scm    = f_cases[:]->pblh_SCM
  wspd10_scm  = f_cases[:]->wspd10_SCM

  theta_las   = f_cases[:]->theta_profile_LAS
  rv_las      = f_cases[:]->rv_profile_LAS
  wspd_las    = f_cases[:]->wspd_profile_LAS
  pblh_las    = f_cases[:]->pblh_LAS
  wspd10_las  = f_cases[:]->wspd10_LAS

  wspd10_diff = f_cases[:]->wspd10_diff

  ttend_scm = f_cases[:]->t_tend_profile_SCM
  qtend_scm = f_cases[:]->q_tend_profile_SCM
  wspdtend_scm = f_cases[:]->wspd_tend_profile_SCM

; Calculate the lapse rate of potential temperature.
  dims=dimsizes(theta_las)
      
  gamma_las=new(dims,float)
  gamma_scm=new(dims,float)
  gamma_scm_smoo=new(dims,float)
                                    
  do idx=0,dims(0)-1
    do idt=0,dims(1)-1              
      do idz=1,dims(2)-2
      
      gamma_las(idx,idt,idz)=-1000.*(theta_las(idx,idt,idz+1)-theta_las(idx,idt,idz-1))/\
                                    (zi_m(idz+1)-zi_m(idz-1))
      gamma_scm(idx,idt,idz)=-1000.*(theta_scm(idx,idt,idz+1)-theta_scm(idx,idt,idz-1))/\
                                    (zi_m(idz+1)-zi_m(idz-1))
 
      end do
    end do
  end do

; Trying to smooth out the kinks in the SCM data, since
; they are coarser than the LASSO data and were linearly
; interpolated to the LASSO height grid. Taking the derivative
; creates kinks because the derivative of a line is a 
; constant value. Need to preserve the original structure
; within the surface layer, which requires some tricks.
  gamma_scm_smoo=runave(gamma_scm,8,0)
  gamma_scm_smoo(:,:,1)=gamma_scm(:,:,1)
  gamma_scm_smoo(:,:,2)=dim_avg_n(gamma_scm(:,:,1:3),2)
  gamma_scm_smoo(:,:,3)=dim_avg_n(gamma_scm(:,:,1:5),2)

; Define title strings
  profile_times_str = (/"0700-0900 CST","0900-1100 CST","1100-1300 CST", \
                        "1300-1500 CST","1500-1700 CST","1700-1900 CST", \
                        "1900-2100 CST"/)
  ntimes=dimsizes(profile_times_str)

; Resources for potential temperature plots
  tres = True

  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@tiXAxisString    = "Theta (K)"
  tres@tiYAxisString    = "Height (m)"
  tres@xyLineColor      = "black"
  tres@xyDashPattern    = 0
  tres@vpWidthF         = 0.99
  tres@vpHeightF        = 0.5
  tres@trXMinF          = 290.
  tres@trXMaxF          = 325.
  tres@trYMaxF          = 3000.

; Resources for potential temperature legends
  genres                    = True
  genres@XPosPercent        = 18.5
  genres@YPosPercent        = 70.0
  lineres                   = True
  lineres@lgLineThicknesses = 3.4
  lineres@lgLineColors      = (/ "darkorange1","black" /)
  lineres@lgDashIndexes     = (/ 0,0 /)
  textres                   = True
  textres@lgLabels          = (/ "LASSO","SCM" /)

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_theta_profiles")

  do idt=0,ntimes-1
  
    tres@gsnLeftString = profile_times_str(idt)
    tres@xyLineColor = "darkorange1"
    genres@XPosPercent = 77.5
    pltlas = gsn_csm_xy(wks,theta_las(:,idt,:),zi_m,tres)
    
    tres@xyLineColor = "black"
    pltctl = gsn_csm_xy(wks,theta_scm(:,idt,:),zi_m,tres)
    
    overlay(pltlas,pltctl)
    
    draw(pltlas)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)
    
  end do

  tres@tiXAxisString    = "Water Vapor Mixing Ratio (g/kg)"
  tres@trXMinF          = 0.
  tres@trXMaxF          = 18.

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_rv_profiles")

  do idt=0,ntimes-1

    tres@gsnLeftString = profile_times_str(idt)
    tres@xyLineColor = "darkorange1"
    genres@XPosPercent = 77.5
    pltlas = gsn_csm_xy(wks,rv_las(:,idt,:),zi_m,tres)

    tres@xyLineColor = "black"
    pltctl = gsn_csm_xy(wks,rv_scm(:,idt,:),zi_m,tres)

    overlay(pltlas,pltctl)

    draw(pltlas)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

  tres@tiXAxisString    = "Wind Speed (m/s)"
  tres@trXMinF          = 0.
  tres@trXMaxF          = 22.

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_wspd_profiles")
  
  do idt=0,ntimes-1
  
    tres@gsnLeftString = profile_times_str(idt)
    tres@xyLineColor = "darkorange1"
    genres@XPosPercent = 77.5
    pltlas = gsn_csm_xy(wks,wspd_las(:,idt,:),zi_m,tres)
    
    tres@xyLineColor = "black"
    pltctl = gsn_csm_xy(wks,wspd_scm(:,idt,:),zi_m,tres)
    
    overlay(pltlas,pltctl)
    
    draw(pltlas)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_theta_diff_profiles")

  tres@tiXAxisString    = "Theta Difference (SCM-LASSO, K)"
  tres@tiYAxisString    = "Height (m)"
  tres@xyLineColor      = "black"
  tres@trXMinF          = -5.
  tres@trXMaxF          = 5.

  do idt=0,ntimes-1

    tres@gsnLeftString = profile_times_str(idt)
    pltlas = gsn_csm_xy(wks,theta_scm(:,idt,:)-theta_las(:,idt,:),zi_m,tres)

    draw(pltlas)
    frame(wks)

  end do

  tres@tiXAxisString    = "Mixing Ratio Difference (SCM-LASSO, g/kg)"
  tres@xyLineColor      = "black" 
  tres@trXMinF          = -3.
  tres@trXMaxF          = 3.
  
; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_rv_diff_profiles")
  
  do idt=0,ntimes-1
  
    tres@gsnLeftString = profile_times_str(idt)
    pltlas = gsn_csm_xy(wks,rv_scm(:,idt,:)-rv_las(:,idt,:),zi_m,tres)
    
    draw(pltlas)
    frame(wks)

  end do

  tres@tiXAxisString    = "Wind Speed Difference (SCM-LASSO, m/s)"
  tres@xyLineColor      = "black"
  tres@trXMinF          = -8.
  tres@trXMaxF          = 8.

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_wspd_diff_profiles")

  do idt=0,ntimes-1

    tres@gsnLeftString = profile_times_str(idt)
    pltlas = gsn_csm_xy(wks,wspd_scm(:,idt,:)-wspd_las(:,idt,:),zi_m,tres)

    draw(pltlas)
    frame(wks)

  end do

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_gamma_profiles")

  do idt=0,ntimes-1

    tres@tiXAxisString = "Theta Lapse Rate (K)"
    tres@gsnLeftString = profile_times_str(idt)
    tres@xyLineColor = "darkorange1"
    genres@XPosPercent = 77.5
    pltlas = gsn_csm_xy(wks,gamma_las(:,idt,:),zi_m,tres)

    tres@xyLineColor = "black"
    pltctl = gsn_csm_xy(wks,gamma_scm_smoo(:,idt,:),zi_m,tres)

    overlay(pltlas,pltctl)

    draw(pltlas)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

; Resources for physics tendency plots
  tres@tiXAxisString = "SCM Temperature Tendency (K/hr)"
  tres@trXMinF       = -3.
  tres@trXMaxF       = 3.

; Resources for physics tendency legend

  delete(lineres@lgLineColors)
  delete(lineres@lgDashIndexes)
  delete(textres@lgLabels)

  lineres@lgLineColors      = (/ "red","orange","blue","purple","magenta",\
                                 "aquamarine","tan","brown","black","green" /)
  lineres@lgDashIndexes     = (/ 0,0,0,0,0,0,0,0,0,0 /)
  textres@lgLabels          = (/ "LWRAD","SWRAD","PBL","DCONV","SCONV",\
                                 "MICRO","OGWD","CGWD","TOTAL PHYS","FORCING" /)

  genres@XPosPercent        = 18.5

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_ttend_all")

  do idt=0,ntimes-1

    delete(tres@gsnLeftString)

  ; LWRAD
    tres@xyLineColor = "red"
    pltlwr = gsn_csm_xy(wks,ttend_scm(:,idt,:,0),zi_m,tres)

  ; SWRAD
    tres@xyLineColor = "orange"
    pltswr = gsn_csm_xy(wks,ttend_scm(:,idt,:,1),zi_m,tres) 

  ; PBL    
    tres@xyLineColor = "blue"
    pltpbl = gsn_csm_xy(wks,ttend_scm(:,idt,:,2),zi_m,tres)

  ; DCONV
    tres@xyLineColor = "purple"
    pltdcv = gsn_csm_xy(wks,ttend_scm(:,idt,:,3),zi_m,tres)

  ; SCONV
    tres@xyLineColor = "magenta"
    pltscv = gsn_csm_xy(wks,ttend_scm(:,idt,:,4),zi_m,tres)

  ; MICRO
    tres@xyLineColor = "aquamarine"
    pltmic = gsn_csm_xy(wks,ttend_scm(:,idt,:,5),zi_m,tres)

  ; OGWD
    tres@xyLineColor = "tan"
    pltogw = gsn_csm_xy(wks,ttend_scm(:,idt,:,6),zi_m,tres)

  ; CGWD
    tres@xyLineColor = "brown"
    pltcgw = gsn_csm_xy(wks,ttend_scm(:,idt,:,7),zi_m,tres)

  ; TOTAL PHYSICS
    tres@xyLineColor = "black"
    plttot = gsn_csm_xy(wks,ttend_scm(:,idt,:,8),zi_m,tres)

    tres@gsnLeftString = profile_times_str(idt)

  ; FORCING
    tres@xyLineColor = "green"
    pltfor = gsn_csm_xy(wks,ttend_scm(:,idt,:,9),zi_m,tres)

    overlay(plttot,pltfor)
    overlay(plttot,pltdcv)
    overlay(plttot,pltscv)
    overlay(plttot,pltogw)
    overlay(plttot,pltcgw)
    overlay(plttot,pltmic)
    overlay(plttot,pltlwr)
    overlay(plttot,pltswr)
    overlay(plttot,pltpbl)

    draw(plttot)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

; Resources for physics tendency plots
  tres@tiXAxisString = "SCM Specific Humidity Tendency (g/kg/hr)"
  tres@trXMinF       = -2.
  tres@trXMaxF       = 2.

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_qtend_all")
  
  do idt=0,ntimes-1

    delete(tres@gsnLeftString)

  ; LWRAD
    tres@xyLineColor = "red"
    pltlwr = gsn_csm_xy(wks,qtend_scm(:,idt,:,0),zi_m,tres)
  
  ; SWRAD
    tres@xyLineColor = "orange"
    pltswr = gsn_csm_xy(wks,qtend_scm(:,idt,:,1),zi_m,tres)
  
  ; PBL    
    tres@xyLineColor = "blue"
    pltpbl = gsn_csm_xy(wks,qtend_scm(:,idt,:,2),zi_m,tres)

  ; DCONV
    tres@xyLineColor = "purple"
    pltdcv = gsn_csm_xy(wks,qtend_scm(:,idt,:,3),zi_m,tres)

  ; SCONV
    tres@xyLineColor = "magenta"
    pltscv = gsn_csm_xy(wks,qtend_scm(:,idt,:,4),zi_m,tres)

  ; MICRO
    tres@xyLineColor = "aquamarine"
    pltmic = gsn_csm_xy(wks,qtend_scm(:,idt,:,5),zi_m,tres)

  ; OGWD
    tres@xyLineColor = "tan"
    pltogw = gsn_csm_xy(wks,qtend_scm(:,idt,:,6),zi_m,tres)

  ; CGWD
    tres@xyLineColor = "brown"
    pltcgw = gsn_csm_xy(wks,qtend_scm(:,idt,:,7),zi_m,tres)

  ; TOTAL PHYSICS
    tres@xyLineColor = "black"
    plttot = gsn_csm_xy(wks,qtend_scm(:,idt,:,8),zi_m,tres)
    
    tres@gsnLeftString = profile_times_str(idt)

  ; FORCING
    tres@xyLineColor = "green"
    pltfor = gsn_csm_xy(wks,qtend_scm(:,idt,:,9),zi_m,tres)

    overlay(plttot,pltfor)
    overlay(plttot,pltdcv)
    overlay(plttot,pltscv)
    overlay(plttot,pltogw)
    overlay(plttot,pltcgw)
    overlay(plttot,pltmic)
    overlay(plttot,pltlwr)
    overlay(plttot,pltswr)
    overlay(plttot,pltpbl)

    draw(plttot)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

; Resources for physics tendency plots
  tres@tiXAxisString = "SCM Wind Speed Tendency (m/s/hr)"

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_wspdtend_all")
  
  do idt=0,ntimes-1

    delete(tres@gsnLeftString)

  ; LWRAD
    tres@xyLineColor = "red"
    pltlwr = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,0),zi_m,tres)
  
  ; SWRAD
    tres@xyLineColor = "orange"
    pltswr = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,1),zi_m,tres)
  
  ; PBL    
    tres@xyLineColor = "blue"
    pltpbl = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,2),zi_m,tres)

  ; DCONV
    tres@xyLineColor = "purple"
    pltdcv = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,3),zi_m,tres)

  ; SCONV
    tres@xyLineColor = "magenta"
    pltscv = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,4),zi_m,tres)

  ; MICRO
    tres@xyLineColor = "aquamarine"
    pltmic = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,5),zi_m,tres)

  ; OGWD
    tres@xyLineColor = "tan"
    pltogw = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,6),zi_m,tres)

  ; CGWD
    tres@xyLineColor = "brown"
    pltcgw = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,7),zi_m,tres)

  ; TOTAL PHYSICS
    tres@xyLineColor = "black"
    plttot = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,8),zi_m,tres)

    tres@gsnLeftString = profile_times_str(idt)
    
  ; FORCING
    tres@xyLineColor = "green"
    pltfor = gsn_csm_xy(wks,wspdtend_scm(:,idt,:,9),zi_m,tres)

    overlay(plttot,pltfor)
    overlay(plttot,pltdcv)
    overlay(plttot,pltscv)
    overlay(plttot,pltogw)
    overlay(plttot,pltcgw)
    overlay(plttot,pltmic)
    overlay(plttot,pltlwr)
    overlay(plttot,pltswr)
    overlay(plttot,pltpbl)

    draw(plttot)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

  end do

; TIME SERIES

  xyres = True
  xyres@gsnMaximize        = True
  xyres@gsnDraw            = False
  xyres@gsnFrame           = False
  xyres@xyLineThicknessF   = 3.4
  xyres@gsnLeftString      = "1.5-Theta-Increase Method"
  xyres@tiXAxisString      = "US CST"
  xyres@tiYAxisString      = "PBL Height (m)"
  xyres@trYMaxF            = 3200.
  xyres@tmXBMode           = "Explicit"
  xyres@xyDashPattern      = 0
  xyres@tmXBValues         = (/ 0.,3.,6.,9.,12.,15. /)
  xyres@tmXBMinorValues    = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  xyres@tmXBLabels         = (/ "0600","0900","1200","1500","1800","2100" /)

; Legend resources

  delete(lineres@lgLineColors)
  delete(textres@lgLabels)

  genres                    = True
  genres@XPosPercent        = 22
  genres@YPosPercent        = 89.5
  lineres                   = True
  lineres@lgLineColors      = (/ "black","darkorange1" /)
  lineres@lgLineThicknesses = 3.4
  textres                   = True
  textres@lgLabels          = (/ "SCM","LASSO" /)

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_PBLH_1p5theta_all")

  xyres@xyLineColor      = "black"

  pltscm = gsn_csm_xy(wks,Time_h(1:dimsizes(Time_h)-1), \
                      pblh_scm(:,1:dimsizes(Time_h)-1),xyres)

  xyres@xyLineColor      = "darkorange1"

  pltlas = gsn_csm_xy(wks,Time_h(1:dimsizes(Time_h)-1), \
                      pblh_las(:,1:dimsizes(Time_h)-1),xyres)

  overlay(pltscm,pltlas)

  draw(pltscm)
  simple_legend_ndc(wks,genres,lineres,textres)
  frame(wks)

end

