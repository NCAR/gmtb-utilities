load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"

begin

; Code was adapted into NCL from Python from the following file::
; gmtb-scm/scm/etc/scripts/lasso1_forcing_file_generator_gjf_msda.py

; User modification area, read in the LASSO files and determine time
; Note: your directories will likely be different; will need to adjust
; based on your personal directory choices.
  topdir = "/glade/work/damico/"
  LAS    = "LASSO"
  date   = "20170630" ; Change to the date of your simulation(s)

; Define constants
  g     = 9.80665 ;gravity (m s-2)
  R_dry = 287.    ;ideal gas dry air constant (J kg-1 K-1)
  R_vap = 461.5   ;gas constant for water vapor
  c_p   = 1004.   ;specific heat at const pressure (J kg-1 K-1)
  P0    = 100000. ;intial pressure (Pa)
  l_v   = 2.5e6   ;latent heat of vaporization (J kg-1)
  l_s   = 2.836e6 ;latent heat of sublimation (J kg-1)
  kappa = R_dry/c_p
  pi    = 4*atan(1.)

  wfname = "wrfinput_d01.nc"
  lfname = "input_ls_forcing.nc"
  sfname = "input_sfc_forcing.nc"

  simID = systemfunc("ls "+topdir+LAS+"_"+date+"/")
  xsim  = max(toint(simID))
  ns    = dimsizes(simID)

; Lat and lon of column, defined in Acknowledgements.txt in Deg,Min,Sec
  lat           = 36.6050 ; degrees north
  lat@long_name = "latitude of column"
  lat@units     = "degrees N"
  lon           = -97.485 ; degrees east
  lon@long_name = "longitude of column"
  lon@units     = "degrees east"

; Add time (should be constant for each individual day, so you only need one)
  sfc0    = addfile(topdir+LAS+"_"+date+"/"+simID(0)+"/config/"+sfname,"r")
  Times   = sfc0->Times
  time_hr = wrf_times_c(Times,0)

  time           = time_hr * 60. * 60. ; convert to seconds since start
  time@long_name = "elapsed time since the beginning of the simulation"
  time@units     = "s"

  nt = dimsizes(time_hr)

; Add a 3D variable at time 0 to make getting dimension sizes easier
  wrf0 = addfile(topdir+LAS+"_"+date+"/"+simID(0)+"/config/"+wfname,"r")
  init = wrf0->PB(0,:,:,:)
  nzI  = dimsizes(init(:,0,0))
  nyI  = dimsizes(init(0,:,0))
  nxI  = dimsizes(init(0,0,:))

; Height in large scale forcing
  ls0  = addfile(topdir+LAS+"_"+date+"/"+simID(0)+"/config/"+lfname,"r")
  z_ls = ls0->Z_LS(0,:)
  nzF  = dimsizes(z_ls)

  delete(sfc0)
  delete(init)
  delete(wrf0)
  delete(ls0)

; Do loop for each of the simulations that will be included for your date,
; start by defining each new variable in the do loop
  ph                     = new((/ ns,nzI+1,nyI,nxI /),float)
  phb                    = new((/ ns,nzI+1,nyI,nxI /),float)
  ph_avg                 = new((/ ns,nzI+1 /),float)
  z_wrf_stag             = new((/ ns,nzI+1 /),float)
  z_wrf_num              = new((/ ns /),integer)
  z_wrf                  = new((/ ns,nzI /),float)
  height                 = new((/ ns,nzI /),float)
  pert_pressure          = new((/ ns,nzI,nyI,nxI /),float)
  base_pressure          = new((/ ns,nzI,nyI,nxI /),float)
  pp_avg                 = new((/ ns,nzI /),float)
  pbs_avg                = new((/ ns,nzI /),float)
  levels                 = new((/ ns,nzI /),float)
  theta_pert             = new((/ ns,nzI,nyI,nxI /),float)
  theta_avg              = new((/ ns,nzI /),float)
  theta                  = new((/ ns,nzI /),float)
  t_air                  = new((/ ns,nzI /),float)
  qv_mr                  = new((/ ns,nzI,nyI,nxI /),float)
  vmr_avg                = new((/ ns,nzI /),float)
  qv                     = new((/ ns,nzI /),float)
  ql_mr                  = new((/ ns,nzI,nyI,nxI /),float)
  lmr_avg                = new((/ ns,nzI /),float)
  ql                     = new((/ ns,nzI /),float)
  qi_mr                  = new((/ ns,nzI,nyI,nxI /),float)
  imr_avg                = new((/ ns,nzI /),float)
  qi                     = new((/ ns,nzI /),float)
  qt                     = new((/ ns,nzI /),float)
  thetail                = new((/ ns,nzI /),float)
  u_wind                 = new((/ ns,nzI,nyI,nxI+1 /),float)
  u                      = new((/ ns,nzI /),float)
  v_wind                 = new((/ ns,nzI,nyI+1,nxI /),float)
  v                      = new((/ ns,nzI /),float)
  T00                    = new((/ ns,nt /),float)
  T_surf                 = new((/ ns,nt /),float)
  p_sfc                  = new((/ ns,nt /),float)
  p_surf                 = new((/ ns,nt /),float)
  sh                     = new((/ ns,nt /),float)
  sh_flux_sfc            = new((/ ns,nt /),float)
  le                     = new((/ ns,nt /),float)
  lh_flux_sfc            = new((/ ns,nt /),float)
  w_ls_force_grid        = new((/ ns,nt,nzF /),float)
  u_ls_force_grid        = new((/ ns,nt,nzF /),float)
  v_ls_force_grid        = new((/ ns,nt,nzF /),float)
  w_ls_r                 = new((/ ns,nt,nzI /),float)
  rho                    = new((/ ns,nzI /),float)
  omega                  = new((/ ns,nzI,nt /),float)
  u_r                    = new((/ ns,nt,nzI /),float)
  v_r                    = new((/ ns,nt,nzI /),float)
  theta_nudge_force_grid = new((/ ns,nt,nzF /),float)
  thil_r                 = new((/ ns,nt,nzI /),float)
  qv_nudge_force_grid    = new((/ ns,nt,nzF /),float)
  qv_nudge_r             = new((/ ns,nt,nzI /),float)
  h_advec_thil_force     = new((/ ns,nt,nzF /),float)
  h_advec_thil_r         = new((/ ns,nt,nzI /),float)
  h_advec_qt_force_grid  = new((/ ns,nt,nzF /),float)
  h_advec_qt_r           = new((/ ns,nt,nzI /),float)
; Do loop to read in the values
  do z=0,ns-1,1
    fulldir = topdir+LAS+"_"+date+"/"+simID(z)+"/config/"
    wf      = fulldir + wfname
    if (isfilepresent(wf)) then
      wrf = addfile(wf,"r")
      ls  = addfile(fulldir+lfname,"r")
      sfc = addfile(fulldir+sfname,"r")
      print("Files for "+date+" SID"+simID(z)+" added")

; All initial profile variables
; Height in WRF initial conditions file
      ph(z,:,:,:)  = wrf->PH(0,:,:,:)
      phb(z,:,:,:) = wrf->PHB(0,:,:,:)

      ph(z,:,:,:)  = ph(z,:,:,:) + phb(z,:,:,:)

      ph_avg(z,:) = dim_avg_n(ph(z,:,:,:),(/ 1,2 /))

      z_wrf_stag(z,:) = ph_avg(z,:) / g
      z_wrf_num(z)    = dimsizes(z_wrf_stag(z,:))
      z_wrf(z,:)      = (z_wrf_stag(z,1:z_wrf_num(z)-1) + \ 
                         z_wrf_stag(z,0:z_wrf_num(z)-2)) * 0.5

      height(z,:) = z_wrf(z,:)

; Pressure levels of WRF initial conditions
      pert_pressure(z,:,:,:) = wrf->P(0,:,:,:)
      pp_avg(z,:)            = dim_avg_n(pert_pressure(z,:,:,:),(/ 1,2 /))
      base_pressure(z,:,:,:) = wrf->PB(0,:,:,:)
      pbs_avg(z,:)           = dim_avg_n(base_pressure(z,:,:,:),(/ 1,2 /))
  
      levels(z,:) = pp_avg(z,:) + pbs_avg(z,:)

; Initial theta
      theta_pert(z,:,:,:) = wrf->T(0,:,:,:)
      theta_avg(z,:)      = dim_avg_n(theta_pert(z,:,:,:),(/ 1,2 /))

      theta(z,:) = theta_avg(z,:) + 300. ;instructions say to add 300 K
                                         ;to theta perturbation

; Air temperature
      t_air(z,:) = theta(z,:) / ((P0 / levels(z,:))^(R_dry/c_p))

; Initial profiles of water mixing ratios, convert to specific humidity
      qv_mr(z,:,:,:) = wrf->QVAPOR(0,:,:,:)
      vmr_avg(z,:)   = dim_avg_n(qv_mr(z,:,:,:),(/ 1,2 /))
      qv(z,:)        = vmr_avg(z,:) / (1. + vmr_avg(z,:)) ; convert from mixing 
                                                          ; ratio to specific 
                                                          ; humidity
      ql_mr(z,:,:,:) = wrf->QCLOUD(0,:,:,:)
      lmr_avg(z,:)   = dim_avg_n(ql_mr(z,:,:,:),(/ 1,2 /))
      ql(z,:)        = lmr_avg(z,:) / (1. + lmr_avg(z,:))

      qi_mr(z,:,:,:) = wrf->QICE(0,:,:,:)
      imr_avg(z,:)   = dim_avg_n(qi_mr(z,:,:,:),(/ 1,2 /))
      qi(z,:)        = imr_avg(z,:) / (1. + imr_avg(z,:))

; Calculate qt (total water specific humidity)
      qt(z,:) = qv(z,:) + ql(z,:) + qi(z,:)

; Calculate theta_il using eqn in gmtb-scm user's guide
      thetail(z,:) = theta(z,:) - ((theta(z,:)/t_air(z,:))* \
                                  (((l_v/c_p)*ql(z,:))+((l_s/c_p)*qi(z,:))))

; Initial profiles of u and v
      u_wind(z,:,:,:) = wrf->U(0,:,:,:)
      u(z,:)          = dim_avg_n(u_wind(z,:,:,:),(/ 1,2 /))

      v_wind(z,:,:,:) = wrf->V(0,:,:,:)
      v(z,:)          = dim_avg_n(v_wind(z,:,:,:),(/ 1,2 /))

; Forcing variables
; Surface temperature
      T00(z,:)    = sfc->PRE_TSK
      T_surf(z,:) = T00(z,:) + 0.

; Surface pressure
;      p_sfc(z,:)   = ls->P_SFC_OPT ; hPa
;      p_surf(z,:)  = p_sfc(z,:) * 100.  ; Convert to Pa 
      p_surf(z,:)  = levels(z,0)

; Latent and sensible heat fluxes at the surface (LASSO);;;;;;;;;;;;;;;;;;;;;;;
      sh(z,:)          = sfc->PRE_SH_FLX ; W m^-2
      sh_flux_sfc(z,:) = sh(z,:)*R_dry*T_surf(z,:) / (c_p*p_surf(z,:)) ;convert
                                                                       ;to 
                                                                       ;K m s-1

      le(z,:)          = sfc->PRE_LH_FLX ; W m^-2
      lh_flux_sfc(z,:) = le(z,:)*R_dry*T_surf(z,:) / (l_v*p_surf(z,:)) ;convert
                                                                       ;to
                                                                       ;kg kg-1
                                                                       ;m s-1
; Geostrophic u and v winds; vertical motion and omega
      w_ls_force_grid(z,:,:) = ls->W_LS
      u_ls_force_grid(z,:,:) = ls->U_LS
      v_ls_force_grid(z,:,:) = ls->V_LS

      w_ls_r(z,:,:) = linint1(z_ls,w_ls_force_grid(z,:,:),False,height(z,:),0)
      w_ls_r!0      = "sim"
      w_ls_r!1      = "time"
      w_ls_r!2      = "levels"

; Find density using ideal gas law to calculate omega
      rho(z,:) = levels(z,:) /(R_dry*t_air(z,:))

      u_r(z,:,:) = linint1(z_ls,u_ls_force_grid(z,:,:),False,height(z,:),0)
      u_r!0      = "sim"
      u_r!1      = "time"
      u_r!2      = "levels"

      v_r(z,:,:) = linint1(z_ls,v_ls_force_grid(z,:,:),False,height(z,:),0)
      v_r!0      = "sim"
      v_r!1      = "time"
      v_r!2      = "levels"

; Nudging variables (theta_il and q_t)
      theta_nudge_force_grid(z,:,:) = ls->TH_RLX

      thil_r(z,:,:) = linint1(z_ls,theta_nudge_force_grid(z,:,:),False, \
                              height(z,:),0)
      thil_r!0      = "sim"
      thil_r!1      = "time"
      thil_r!2      = "levels"

      qv_nudge_force_grid(z,:,:) = ls->QV_RLX

      qv_nudge_r(z,:,:) = linint1(z_ls,qv_nudge_force_grid(z,:,:),False, \
                                  height(z,:),0)
      qv_nudge_r!0      = "sim"
      qv_nudge_r!1      = "time"
      qv_nudge_r!2      = "levels"

; Horizontal advection of theta_il and q_t
      h_advec_thil_force(z,:,:) = ls->TH_ADV

      h_advec_thil_r(z,:,:) = linint1(z_ls,h_advec_thil_force(z,:,:),False, \
                                      height(z,:),0)
      h_advec_thil_r!0      = "sim"
      h_advec_thil_r!1      = "time"
      h_advec_thil_r!2      = "levels"

      h_advec_qt_force_grid(z,:,:) = ls->QV_ADV

      h_advec_qt_r(z,:,:) = linint1(z_ls,h_advec_qt_force_grid(z,:,:),False, \
                                    height(z,:),0)
      h_advec_qt_r!0      = "sim"
      h_advec_qt_r!1      = "time"
      h_advec_qt_r!2      = "levels"

    else
      print("Simulation ID "+(z+1)+" does not exist")
    end if
  end do
  height@long_name          = "physical height at pressure levels"
  height@units              = "m"
  levels@long_name          = "pressure levels"
  levels@units              = "Pa"
  ql@long_name              = "initial profile of liquid water specific " + \
                              "humidity"
  ql@units                  = "kg kg^-1"
  qi@long_name              = "initial profile of ice water specific humidity"
  qi@units                  = "kg kg^-1"
  qt@long_name              = "initial profile of total water specific " + \
                              "humidity"
  qt@units                  = "kg kg^-1"
  thetail@long_name         = "initial profile of ice-liquid water " + \
                              "potential temperature"
  thetail@units             = "K"
  u@long_name               = "initial profile of E-W horizontal wind"
  u@units                   = "m s^-1"
  v@long_name               = "initial profile of N-S horizontal wind"
  v@units                   = "m s^-1"
  T_surf@long_name          = "surface absolute temperature"
  T_surf@units              = "K"
  p_surf@long_name          = "surface pressure"
  p_surf@units              = "Pa"
  sh_flux_sfc@long_name     = "surface sensible heat flux"
  sh_flux_sfc@units         = "K m s^-1"
  lh_flux_sfc@long_name     = "surface latent heat flux"
  lh_flux_sfc@units         = "kg kg^-1 m s^-1"

  w_ls                      = w_ls_r(sim|:,levels|:,time|:)
  w_ls@long_name            = "large scale vertical velocity"
  w_ls@units                = "m s^-1"

  do z=0,ns-1,1
    do i=0,nt-1,1
      omega(z,:,i) = -w_ls(z,:,i)*rho(z,:)*g
    end do
  end do
  omega@long_name           = "large scale pressure vertical velocity"
  omega@units               = "Pa s^-1"

  u_g                       = u_r(sim|:,levels|:,time|:)
  u_g@long_name             = "large scale geostrophic E-W wind"
  u_g@units                 = "m s^-1"

  v_g                       = v_r(sim|:,levels|:,time|:)
  v_g@long_name             = "large scale geostrophic N-S wind"
  v_g@units                 = "m s^-1"

  thil_nudge                = thil_r(sim|:,levels|:,time|:)
  thil_nudge@long_name      = "potential temperature to nudge toward"
  thil_nudge@units          = "K"

  qt_nudge                  = qv_nudge_r(sim|:,levels|:,time|:)
  qt_nudge@long_name        = "q_t to nudge toward"
  qt_nudge@units            = "kg kg^-1"

  h_advec_thetail           = h_advec_thil_r(sim|:,levels|:,time|:)
  h_advec_thetail@long_name = "prescribed theta_il tendency due to "+ \
                              "horizontal advection"
  h_advec_thetail@units     = "K s^-1"

  h_advec_qt                = h_advec_qt_r(sim|:,levels|:,time|:)
  h_advec_qt@long_name      = "prescribed q_t tendency due to horizontal " + \
                              "advection"
  h_advec_qt@units          = "kg kg^-1 s^-1"

; Open ozone file and add ozone data (goes with initial)
  o3f = addfile("~/gmtb-scm/scm/data/raw_case_input/mid_lat_summer_std.nc","r")

  oz_pres = o3f->pressure
  oz_data = o3f->o3

  ozone           = linint1(oz_pres,oz_data,False,levels(0,:),0)
  ozone@long_name = "initial profile of ozone mass mixing ratio"
  ozone@units     = "kg kg^-1"

  delete(o3f)

; No reliable TKE data for input, set to zero (tke is initial)
  tke           = new((/ nzI /),float)
  tke           = 0.
  tke@long_name = "initial profile of turbulence kinetic energy"
  tke@units     = "m^2 s^-2"

  u_nudge           = u_g
  u_nudge@long_name = "E-W wind to nudge toward"
  u_nudge@units     = "m s^-1"

  v_nudge           = v_g
  v_nudge@long_name = "N-S wind to nudge toward"
  v_nudge@units     = "m s^-1"

; Assign values of zero to remaining forcing variables
  dT_dt_rad           = new((/ nzI,nt /),float)
  dT_dt_rad           = 0.
  dT_dt_rad@long_name = "prescribed radiative heating rate"
  dT_dt_rad@units     = "K s^-1"

  T_nudge           = new((/ nzI,nt /),float)
  T_nudge           = 0.
  T_nudge@long_name = "absolute temperature to nudge toward"
  T_nudge@units     = "K"

  v_advec_thetail           = new((/ nzI,nt /),float)
  v_advec_thetail           = 0.
  v_advec_thetail@long_name = "prescribed theta_il tendency due to "+ \
                              "vertical advection"
  v_advec_thetail@units     = "K s^-1"

  v_advec_qt           = new((/ nzI,nt /),float)
  v_advec_qt           = 0.
  v_advec_qt@long_name = "prescribed q_t tendency due to vertical advection"
  v_advec_qt@units     = "kg kg^-1 s^-1"

; Begin writing netCDF output to LASSO_[date of lasso input]_SID[#].nc
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")
; Do loop for each simulation
  do z=0,ns-1,1
    fout = "LASSO_"+date+"_SID"+simID(z)+".nc"
    system("/bin/rm -fv "+fout)
    fo   = addfile(fout,"c")

    fAtt               = True
    fAtt@title         = "GMTB SCM forcing file for LASSO-"+date+" SID"+ \
                         simID(z)
    fAtt@creation_date = systemfunc("date")
    fileattdef(fo,fAtt)

; Define the dimensions, time and levels
    dimNames = (/ "time","levels" /)
    dimSizes = (/ dimsizes(time),dimsizes(levels(z,:)) /)
    dimUnlim = (/ False,True /)

    filedimdef(fo,dimNames,dimSizes,dimUnlim)

    filevardef(fo,"time",typeof(time),"time")
    filevarattdef(fo,"time",time)
    fo->time = (/ time /)

    filevardef(fo,"levels",typeof(levels),"levels")
    filevarattdef(fo,"levels",levels)
    fo->levels = (/ levels(z,:) /)

; Define group names for NetCDF4 file
    grpnames = (/ "scalars","initial","forcing" /)
    filegrpdef(fo,grpnames)

    g1 = fo=>/scalars
    g2 = fo=>/initial
    g3 = fo=>/forcing

; Scalars
    filevardef(g1,"lat",typeof(lat),"ncl_scalar")
    filevarattdef(g1,"lat",lat)
    g1->lat = lat

    filevardef(g1,"lon",typeof(lon),"ncl_scalar")
    filevarattdef(g1,"lon",lon)
    g1->lon = lon

; Initial
    filedimdef(g2,dimNames(1),dimSizes(1),dimUnlim(1))

    filevardef(g2,"height",typeof(height),"levels")
    filevarattdef(g2,"height",height)
    g2->height = (/ height(z,:) /)

    filevardef(g2,"thetail",typeof(thetail),"levels")
    filevarattdef(g2,"thetail",thetail)
    g2->thetail = (/ thetail(z,:) /)

    filevardef(g2,"qt",typeof(qt),"levels")
    filevarattdef(g2,"qt",qt)
    g2->qt = (/ qt(z,:) /)

    filevardef(g2,"ql",typeof(ql),"levels")
    filevarattdef(g2,"ql",ql)
    g2->ql = (/ ql(z,:) /)

    filevardef(g2,"qi",typeof(qi),"levels")
    filevarattdef(g2,"qi",qi)
    g2->qi = (/ qi(z,:) /)

    filevardef(g2,"u",typeof(u),"levels")
    filevarattdef(g2,"u",u)
    g2->u = (/ u(z,:) /)

    filevardef(g2,"v",typeof(v),"levels")
    filevarattdef(g2,"v",v)
    g2->v = (/ v(z,:) /)

    filevardef(g2,"tke",typeof(tke),"levels")
    filevarattdef(g2,"tke",tke)
    g2->tke = (/ tke /)

    filevardef(g2,"ozone",typeof(ozone),"levels")
    filevarattdef(g2,"ozone",ozone)
    g2->ozone = (/ ozone /)

; Forcing
    filedimdef(g3,dimNames,dimSizes,dimUnlim)

    filevardef(g3,"p_surf",typeof(p_surf),"time")
    filevarattdef(g3,"p_surf",p_surf)
    g3->p_surf = (/ p_surf(z,:) /)

    filevardef(g3,"T_surf",typeof(T_surf),"time")
    filevarattdef(g3,"T_surf",T_surf)
    g3->T_surf = (/ T_surf(z,:) /)

    filevardef(g3,"sh_flux_sfc",typeof(sh_flux_sfc),"time")
    filevarattdef(g3,"sh_flux_sfc",sh_flux_sfc)
    g3->sh_flux_sfc = (/ sh_flux_sfc(z,:) /)

    filevardef(g3,"lh_flux_sfc",typeof(lh_flux_sfc),"time")
    filevarattdef(g3,"lh_flux_sfc",lh_flux_sfc)
    g3->lh_flux_sfc = (/ lh_flux_sfc(z,:) /)

    filevardef(g3,"w_ls",typeof(w_ls),(/ "levels","time" /))
    filevarattdef(g3,"w_ls",w_ls)
    g3->w_ls = (/ w_ls(z,:,:) /)

    filevardef(g3,"omega",typeof(omega),(/ "levels","time" /))
    filevarattdef(g3,"omega",omega)
    g3->omega = (/ omega(z,:,:) /)

    filevardef(g3,"u_g",typeof(u_g),(/ "levels","time" /))
    filevarattdef(g3,"u_g",u_g)
    g3->u_g = (/ u_g(z,:,:) /)

    filevardef(g3,"v_g",typeof(v_g),(/ "levels","time" /))
    filevarattdef(g3,"v_g",v_g)
    g3->v_g = (/ v_g(z,:,:) /)

    filevardef(g3,"u_nudge",typeof(u_nudge),(/ "levels","time" /))
    filevarattdef(g3,"u_nudge",u_nudge)
    g3->u_nudge = (/ u_nudge(z,:,:) /)

    filevardef(g3,"v_nudge",typeof(v_nudge),(/ "levels","time" /))
    filevarattdef(g3,"v_nudge",v_nudge)
    g3->v_nudge = (/ v_nudge(z,:,:) /)

    filevardef(g3,"T_nudge",typeof(T_nudge),(/ "levels","time" /))
    filevarattdef(g3,"T_nudge",T_nudge)
    g3->T_nudge = (/ T_nudge /)

    filevardef(g3,"thil_nudge",typeof(thil_nudge),(/ "levels","time" /))
    filevarattdef(g3,"thil_nudge",thil_nudge)
    g3->thil_nudge = (/ thil_nudge(z,:,:) /)

    filevardef(g3,"qt_nudge",typeof(qt_nudge),(/ "levels","time" /))
    filevarattdef(g3,"qt_nudge",qt_nudge)
    g3->qt_nudge = (/ qt_nudge(z,:,:) /)

    filevardef(g3,"dT_dt_rad",typeof(dT_dt_rad),(/ "levels","time" /))
    filevarattdef(g3,"dT_dt_rad",dT_dt_rad)
    g3->dT_dt_rad = (/ dT_dt_rad /)

    filevardef(g3,"h_advec_thetail",typeof(h_advec_thetail), \
              (/ "levels","time" /))
    filevarattdef(g3,"h_advec_thetail",h_advec_thetail)
    g3->h_advec_thetail = (/ h_advec_thetail(z,:,:) /)

    filevardef(g3,"v_advec_thetail",typeof(v_advec_thetail), \
              (/ "levels","time" /))
    filevarattdef(g3,"v_advec_thetail",v_advec_thetail)
    g3->v_advec_thetail = (/ v_advec_thetail /)

    filevardef(g3,"h_advec_qt",typeof(h_advec_qt),(/ "levels","time" /))
    filevarattdef(g3,"h_advec_qt",h_advec_qt)
    g3->h_advec_qt = (/ h_advec_qt(z,:,:) /)

    filevardef(g3,"v_advec_qt",typeof(v_advec_qt),(/ "levels","time" /))
    filevarattdef(g3,"v_advec_qt",v_advec_qt)
    g3->v_advec_qt = (/ v_advec_qt /)

    print("Created/wrote new file: "+fout)
  end do

  print("Program complete at "+systemfunc("date"))

end

