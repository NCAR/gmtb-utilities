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

; Add file
  f = addfile(dirio+"LASSO_SCM_composite.nc","r")
  f_std = addfile(dirio+"LASSO_SCM_composite_std.nc","r")

; Times
  Time_h     = 24.*(f->Time_s)
  Time_h@units = "hours since init time"

; Variables
  zi_m = f->bottom_top
  wspd_diff = f->wspd_diff
  theta_diff = f->theta_diff
  rv_diff = f->rv_diff
  ttend_scm = transpose(f->t_tend_profile_SCM)
  qtend_scm = transpose(f->q_tend_profile_SCM)
  wspdtend_scm = transpose(f->wspd_tend_profile_SCM)
  qc_scm = f->qc_SCM
  qc_las = f->qc_LAS
  qc_diff = qc_scm-qc_las

  ttend_scm_std = transpose(f_std->t_tend_profile_SCM)
  qtend_scm_std = transpose(f_std->q_tend_profile_SCM)
  wspdtend_scm_std = transpose(f_std->wspd_tend_profile_SCM)

  dims = dimsizes(ttend_scm)
  ntend = dims(0)
  nz = dims(1)

; Define title strings
  profile_times_str = (/"0700-0900 CST","0900-1100 CST","1100-1300 CST", \
                        "1300-1500 CST","1500-1700 CST","1700-1900 CST", \
                        "1900-2100 CST"/)
  ntimes=dimsizes(profile_times_str)

; Resources for physics tendency plots
  tres                  = True
  tres@gsnMaximize      = True
  tres@gsnDraw          = False
  tres@gsnFrame         = False
  tres@xyLineThicknessF = 3.4
  tres@tiXAxisString    = "Temperature Tendency (K/hr)"
  tres@tiYAxisString    = "Height (m)"
  tres@xyDashPattern    = 0
  tres@vpWidthF         = 0.99
  tres@vpHeightF        = 0.5
  tres@trXMinF          = -3.
  tres@trXMaxF          = 3.
  tres@trYMaxF          = 3000.

  colors                = (/"red","orange","blue","purple","magenta",\
                            "aquamarine","tan","brown","black","green"/)
  start_ind             = (/0,1,2,0,1,2,0,1,2,0/) ; offset error bars

  tres@xyLineColors     = colors

; Resources for physics tendency legends
  genres                    = True
  genres@XPosPercent        = 18.5
  genres@YPosPercent        = 70.0
  lineres                   = True
  lineres@lgLineThicknesses = 3.4
  lineres@lgLineColors      = colors
  textres                   = True
  textres@lgLabels          = (/"LWRAD","SWRAD","PBL","DCONV","SCONV",\
                                "MICRO","OGWD","CGWD","TOTAL PHYS","FORCING"/)

; Resources for error bars
  polyres = True
  polyres@gsLineThicknessF = 3.4

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_mean_ttend_profiles")

  do idt=0,ntimes-1

    plterr = new((/ntend,nz/),"graphic")

    tres@gsnLeftString = profile_times_str(idt)

    plttnd = gsn_csm_xy(wks,ttend_scm(:,:,idt),zi_m,tres)

    do itend=0,ntend-1

      polyres@gsLineColor=colors(itend)

      do iz=0,nz-1,5

        lower=ttend_scm(itend,iz,idt)-ttend_scm_std(itend,iz,idt)
        upper=ttend_scm(itend,iz,idt)+ttend_scm_std(itend,iz,idt)
        plterr(itend,iz) = gsn_add_polyline(wks,plttnd,(/lower,upper/),(/zi_m(iz),zi_m(iz)/),polyres)

      end do

    end do

    plttnd@plterr=plterr

    draw(plttnd)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    delete(plttnd)
    delete(plterr)

  end do

  tres@tiXAxisString = "Specific Humidity Tendency (g/kg/hr)"
  tres@trXMinF = -2.
  tres@trXMaxF = 2.

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_mean_qtend_profiles")

  do idt=0,ntimes-1

    plterr = new((/ntend,nz/),"graphic")

    tres@gsnLeftString = profile_times_str(idt)

    plttnd = gsn_csm_xy(wks,qtend_scm(:,:,idt),zi_m,tres)

    do itend=0,ntend-1

      polyres@gsLineColor=colors(itend)

      do iz=0,nz-1,5

        lower=qtend_scm(itend,iz,idt)-qtend_scm_std(itend,iz,idt)
        lower=where(ismissing(lower),0,lower)
        upper=qtend_scm(itend,iz,idt)+qtend_scm_std(itend,iz,idt)
        upper=where(ismissing(upper),0,upper)
        plterr(itend,iz) = gsn_add_polyline(wks,plttnd,(/lower,upper/),(/zi_m(iz),zi_m(iz)/),polyres)

      end do

    end do

    plttnd@plterr=plterr

    draw(plttnd)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    delete(plttnd)
    delete(plterr)

  end do

  tres@tiXAxisString = "Wind Speed Tendency (m/s/hr)"

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_mean_wspdtend_profiles")

  do idt=0,ntimes-1

    plterr = new((/ntend,nz/),"graphic")

    tres@gsnLeftString = profile_times_str(idt) 

    plttnd = gsn_csm_xy(wks,wspdtend_scm(:,:,idt),zi_m,tres)

    do itend=0,ntend-1
      
      polyres@gsLineColor=colors(itend)
      
      do iz=0,nz-1,5
        
        lower=wspdtend_scm(itend,iz,idt)-wspdtend_scm_std(itend,iz,idt)
        lower=where(ismissing(lower),0,lower)
        upper=wspdtend_scm(itend,iz,idt)+wspdtend_scm_std(itend,iz,idt)
        upper=where(ismissing(upper),0,upper)
        plterr(itend,iz) = gsn_add_polyline(wks,plttnd,(/lower,upper/),(/zi_m(iz),zi_m(iz)/),polyres)
      
      end do
    
    end do

    plttnd@plterr=plterr

    draw(plttnd)
    simple_legend_ndc(wks,genres,lineres,textres)
    frame(wks)

    delete(plttnd)
    delete(plterr)

  end do

; Open workstation
  wks = gsn_open_wks(gtype,dirio+phys+"_time_height")

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
  res@sfXArray                 = Time_h
  res@sfYArray                 = zi_m
  res@gsnLeftString            = "SCM - LASSO Pot Temp"
  res@tiXAxisString            = "Local Time (CST)"
  res@tiYAxisString            = "Height (m)"
  res@cnLevelSelectionMode     = "ManualLevels"
  res@cnMinLevelValF           = -1.
  res@cnMaxLevelValF           = 1.
  res@cnLevelSpacingF          = 0.1
  res@gsnYAxisIrregular2Linear = True
  res@tmXBMode                 = "Explicit"
  res@tmXBValues               = (/ 0.,3.,6.,9.,12.,15. /)
  res@tmXBMinorValues          = (/ 1.,2.,4.,5.,7.,8.,10.,11.,13.,14. /)
  res@tmXBLabels               = (/ "0600","0900","1200","1500", \
                                    "1800","2100" /)
  res@trYMaxF                  = 3000.

  plot = gsn_csm_contour(wks,transpose(theta_diff),res)

  gsn_reverse_colormap(wks)

  res@gsnLeftString            = "SCM - LASSO r~B~v~N~"
  res@gsnRightString           = "g kg~S~-1~N~"
  res@cnMinLevelValF           = -1.
  res@cnMaxLevelValF           = 1.
  res@cnLevelSpacingF          = 0.1

  plot = gsn_csm_contour(wks,transpose(rv_diff),res)

  res@gsnLeftString            = "SCM - LASSO wind speed"
  res@gsnRightString           = "m s~S~-1~N~"
  res@cnMinLevelValF           = -2.
  res@cnMaxLevelValF           = 2.
  res@cnLevelSpacingF          = 0.2

  plot = gsn_csm_contour(wks,transpose(wspd_diff),res)

  res@gsnLeftString            = "SCM q~B~cloud~N~"
  res@gsnRightString           = "g kg~S~-1~N~"
  res@cnMinLevelValF           = 0.0
  res@cnMaxLevelValF           = 0.01
  res@cnLevelSpacingF          = 0.001
  res@trYMaxF                  = 12000.

  gsn_define_colormap(wks,"CBR_wet")
  plot = gsn_csm_contour(wks,transpose(qc_scm),res)

  res@gsnLeftString            = "LASSO q~B~cloud~N~"
  res@gsnRightString           = "g kg~S~-1~N~"
  res@cnMinLevelValF           = 0.0
  res@cnMaxLevelValF           = 0.01
  res@cnLevelSpacingF          = 0.001
  res@trYMaxF                  = 12000.

  gsn_define_colormap(wks,"CBR_wet")
  plot = gsn_csm_contour(wks,transpose(qc_las),res)

  res@gsnLeftString            = "SCM - LASSO q~B~cloud~N~"
  res@gsnRightString           = "g kg~S~-1~N~"
  res@cnMinLevelValF           = -0.01
  res@cnMaxLevelValF           = 0.01
  res@cnLevelSpacingF          = 0.001
  res@trYMaxF                  = 12000.

  gsn_define_colormap(wks,BlueDarkRed18_WIM)
  plot = gsn_csm_contour(wks,transpose(qc_diff),res)

end

