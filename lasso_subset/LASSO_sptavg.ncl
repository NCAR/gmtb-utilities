load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin
; WARNING: This file takes a very long time to run!!! Recommend running
; this in a queue if using a supercomputing environment. If on 
; cheyenne, recommend use of casper and running this script after
; using the "execdav" command 

; User modification area, the forcing and directories vary between
; LASSO simulations
  sims  = "SID8" ; "SID8","MSDA+UFSsflx"
  phys  = "GFS_v16beta" ; "GFS_v16beta","GFS_v15p2","GSD_v1","csawmg", \
;-------- "v16beta_MYNNpbl","v16beta_MYNNrad","v16beta_Thomp","satmedmf"
  sn    = "8"
  date  = "20190714"
  udate = "2019-07-14 12:00:00"
  ldate = "2019-07-14 0600 CST"

  rdir = "/glade/work/damico/LASSO_20190714_rawmodel/raw_model/"

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
  wrf_f = systemfunc("ls "+rdir+"wrfout_d01_*.nc")
  flas  = addfiles(wrf_f,"r")
; Adding files in this manner saves code but does slow down the execution
; of the program, so expect relatively long execution times.
  ListSetType(flas,"cat")

; Times
  wtim = flas[:]->Times
  Time_hr = wrf_times_c(wtim,0)

  Time_s       = Time_hr
  Time_s       = Time_hr * 60. * 60.
  Time_s@units = "seconds since "+ldate

  nt = dimsizes(Time_s)

; LASSO variables to average for netCDF output
  lat        = wrf_user_getvar(flas[0],"lat",0)
  lon        = wrf_user_getvar(flas[0],"lon",0)
  ph         = flas[:]->PH     ; perturbation geopotential
  phb        = flas[:]->PHB    ; base state geopotential
  theta_pert = flas[:]->T      ; perturbation pot temp
  qv_mr      = flas[:]->QVAPOR ; water vapor mixing ratio
  PP         = flas[:]->P      ; perturbation pressure
  PB         = flas[:]->PB     ; base state pressure
  qclas      = flas[:]->QCLOUD ; cloud water mixing ratio
  qrlas      = flas[:]->QRAIN  ; rain water mixing ratio
  qilas      = flas[:]->QICE   ; ice water mixing ratio
  qslas      = flas[:]->QSNOW  ; snow mixing ratio
  qglas      = flas[:]->QGRAUP ; graupel mixing ratio
  cldfralas  = flas[:]->CLDFRA ; cloud fraction
  shflas     = flas[:]->HFX    ; upward surface heat flux
  lhflas     = flas[:]->LH     ; latent heat flux
  t2m        = flas[:]->T2     ; 2m air temperature
  u_w        = flas[:]->U      ; x(u)-wind component
  v_w        = flas[:]->V      ; y(v)-wind component
  u10_w      = flas[:]->U10    ; 10m u wind
  v10_w      = flas[:]->V10    ; 10m v wind

; LASSO height
  ph  = ph + phb

  ph_avg = dim_avg_n(ph,(/ 2,3 /))

  z_wrf_stag = ph_avg / g
  z_wrf_num  = dimsizes(z_wrf_stag(0,:))
  z_wrf      = new((/ dimsizes(Time_hr),z_wrf_num-1 /),float)
  do i=0,dimsizes(Time_hr)-1,1
    z_wrf(i,:) = (z_wrf_stag(i,1:z_wrf_num-1) + z_wrf_stag(i,0:z_wrf_num-2)) * \
                 0.5
  end do

  height             = z_wrf
  height@units       = "m"
  height@description = "FULL MODEL HEIGHT"
  height!0           = "Time"
  height!1           = "bottom_top"

; LASSO pressure
  pp_avg = dim_avg_n_Wrap(PP,(/ 2,3 /))
  pb_avg = dim_avg_n_Wrap(PB,(/ 2,3 /))

  P = pb_avg
  P = pb_avg + pp_avg

  P@description = "FULL MODEL PRESSURE"

  bottom_top = P(0,:)

  nz = dimsizes(bottom_top)

; LASSO potential temperature
  theta_avg = dim_avg_n_Wrap(theta_pert,(/ 2,3 /))

  theta = theta_avg
  theta = theta_avg + 300. ; instructions say to add 300K to tht pert

  T             = theta
  T@description = "POTENTIAL TEMPERATURE"

; LASSO water vapor mixing ratio, convert to water vapor specific humidity
  vmr_avg = dim_avg_n_Wrap(qv_mr,(/ 2,3 /))
  qvlas   = vmr_avg
  qvlas   = vmr_avg / (1. + vmr_avg)

  QVAPOR             = qvlas
  QVAPOR@description = "WATER VAPOR SPECIFIC HUMIDITY"

; Spatial averages of LASSO clouds
  QCLOUD = dim_avg_n_Wrap(qclas,(/ 2,3 /))
  QRAIN  = dim_avg_n_Wrap(qrlas,(/ 2,3 /))
  QICE   = dim_avg_n_Wrap(qilas,(/ 2,3 /))
  QSNOW  = dim_avg_n_Wrap(qslas,(/ 2,3 /))
  QGRAUP = dim_avg_n_Wrap(qglas,(/ 2,3 /))
  CLDFRA = dim_avg_n_Wrap(cldfralas,(/ 2,3 /))

; Spatial averages of LASSO surface
  HFX = dim_avg_n_Wrap(shflas,(/ 1,2 /))
  LH  = dim_avg_n_Wrap(lhflas,(/ 1,2 /))
  T2  = dim_avg_n_Wrap(t2m,(/ 1,2 /))

; Unstagger u (in E-W) direction and v (in N-S) direction
  us_num = dimsizes(u_w(0,0,0,:))
  vs_num = dimsizes(v_w(0,0,:,0))
  ll_num = dimsizes(u_w(0,0,:,0))
  u_wrf  = new((/ dimsizes(Time_hr),dimsizes(height(0,:)),ll_num,ll_num /), \
               float)
  v_wrf  = new((/ dimsizes(Time_hr),dimsizes(height(0,:)),ll_num,ll_num /), \
               float)
  do i=0,dimsizes(Time_hr)-1,1
    u_wrf(i,:,:,:) = (u_w(i,:,:,1:us_num-1) + u_w(i,:,:,0:us_num-2)) * 0.5
    v_wrf(i,:,:,:) = (v_w(i,:,1:vs_num-1,:) + v_w(i,:,0:vs_num-2,:)) * 0.5
  end do
  u_wrf!0 = "Time"
  u_wrf!1 = "bottom_top"
  u_wrf!2 = "south_north"
  u_wrf!3 = "west_east"
  v_wrf!0 = "Time"
  v_wrf!1 = "bottom_top"
  v_wrf!2 = "south_north"
  v_wrf!3 = "west_east"

; Now unstaggered, take the spatial average of u and v
  U = dim_avg_n_Wrap(u_wrf,(/ 2,3 /))
  V = dim_avg_n_Wrap(v_wrf,(/ 2,3 /))

  U@description = "x-wind component"
  V@description = "y-wind component"

; Surface winds
  U10 = dim_avg_n_Wrap(u10_w,(/ 1,2 /))
  V10 = dim_avg_n_Wrap(v10_w,(/ 1,2 /))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing netCDF output of all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")
  fout = "LASSO_"+date+"_SUBSET.nc"

  system("/bin/rm -f "+fout)
  fo = addfile(fout,"c")

  fAtt               = True
  fAtt@title         = "Subset of spatially averaged LASSO-WRF LES "+ \
                       "for "+date
  fAtt@creation_date = systemfunc("date")

; Define the dimensions
  dimNames = (/ "Time_s","bottom_top" /)
  dimSizes = (/ nt,      nz           /)
  dimUnlim = (/ True,    False        /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"Time_s",typeof(Time_s),"Time_s")
  filevarattdef(fo,"Time_s",Time_s)
  fo->Time_s = (/ Time_s /)

  filevardef(fo,"bottom_top",typeof(bottom_top),"bottom_top")
  filevarattdef(fo,"bottom_top",bottom_top)
  fo->bottom_top = (/ bottom_top /)

  filevardef(fo,"Time_hr",typeof(Time_hr),"Time_s")
  filevarattdef(fo,"Time_hr",Time_hr)
  fo->Time_hr = (/ Time_hr /)

  filevardef(fo,"lat",typeof(lat),"ncl_scalar")
  filevarattdef(fo,"lat",lat)
  fo->lat = (/ lat(0,0) /)

  filevardef(fo,"lon",typeof(lon),"ncl_scalar")
  filevarattdef(fo,"lon",lon)
  fo->lon = (/ lon(0,0) /)

  filevardef(fo,"P",typeof(P),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"P",P)
  fo->P = (/ P /)

  filevardef(fo,"height",typeof(height),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"height",height)
  fo->height = (/ height /)

  filevardef(fo,"T",typeof(T),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"T",T)
  fo->T = (/ T /)

  filevardef(fo,"QVAPOR",typeof(QVAPOR),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"QVAPOR",QVAPOR)
  fo->QVAPOR = (/ QVAPOR /)

  filevardef(fo,"QCLOUD",typeof(QCLOUD),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"QCLOUD",QCLOUD)
  fo->QCLOUD = (/ QCLOUD /)

  filevardef(fo,"QRAIN",typeof(QRAIN),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"QRAIN",QRAIN)
  fo->QRAIN = (/ QRAIN /)

  filevardef(fo,"QICE",typeof(QICE),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"QICE",QICE)
  fo->QICE = (/ QICE /)

  filevardef(fo,"QSNOW",typeof(QSNOW),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"QSNOW",QSNOW)
  fo->QSNOW = (/ QSNOW /)

  filevardef(fo,"QGRAUP",typeof(QGRAUP),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"QGRAUP",QGRAUP)
  fo->QGRAUP = (/ QGRAUP /)

  filevardef(fo,"CLDFRA",typeof(CLDFRA),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"CLDFRA",CLDFRA)
  fo->CLDFRA = (/ CLDFRA /)

  filevardef(fo,"U",typeof(U),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"U",U)
  fo->U = (/ U /)

  filevardef(fo,"V",typeof(V),(/ "Time_s","bottom_top" /))
  filevarattdef(fo,"V",V)
  fo->V = (/ V /)

  filevardef(fo,"T2",typeof(T2),"Time_s")
  filevarattdef(fo,"T2",T2)
  fo->T2 = (/ T2 /)

  filevardef(fo,"HFX",typeof(HFX),"Time_s")
  filevarattdef(fo,"HFX",HFX)
  fo->HFX = (/ HFX /)

  filevardef(fo,"LH",typeof(LH),"Time_s")
  filevarattdef(fo,"LH",LH)
  fo->LH = (/ LH /)

  filevardef(fo,"U10",typeof(U10),"Time_s")
  filevarattdef(fo,"U10",U10)
  fo->U10 = (/ U10 /)

  filevardef(fo,"V10",typeof(V10),"Time_s")
  filevarattdef(fo,"V10",V10)
  fo->V10 = (/ V10 /)

  print("Wrote file -> "+fout)
  print("Complete: "+systemfunc("date"))

end
