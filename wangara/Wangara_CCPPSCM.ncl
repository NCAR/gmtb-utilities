load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

; User modification area ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  dir   = "../../data/raw_case_input/"
  fname = "Wangara2.nc"

  forcing_free = True  ; Logical, True will have no nudging, False will 
                       ; include nudging

  day_of_choice = 33
; NOTE: Be very careful about your selection of the day. At least a few days 
; have entire soundings of missing data (mainly thermodynamic sounding, but
; some days have a couple of hours missing the momentum data). As of now, there
; are limited warnings coded into this script, so tread very carefully with 
; your selection. Days 33/34 have some missing data, but the numbers are small
; and are corrected for through the script.

; day_of_choice = 1 is NOT recommended due to a plethora of missing data.

  length_of_sim = 48

  f = addfile(dir+fname,"r")

; Time handling. Currently the program is setup to take two days (48 hours)
; of data. Most day 33 studies for testing PBL schemes use Day 33 and 34 
; (although frequently just a portion of day 33 and the early hours of day
; 34, so this can be modified by the user).
  time_hr = f->Time

  time_s       = time_hr
  time_s       = time_hr * 60. * 60.
  time_s@units = "seconds since 1967-07-14 14:00:00"

  day_all = f->day
  day_3hr = f->sounding_day

  rmin = closest_val(day_of_choice,day_all)
  rmax = closest_val(day_of_choice + 2,day_all) - 1

  r3min = closest_val(day_of_choice,day_3hr)
  r3max = closest_val(day_of_choice + 2,day_3hr) - 1

  time           = time_s(rmin:rmax)
  time           = time_s(rmin:rmax) - time(0)
  time@long_name = "elapsed time since the beginning of the simulation"
  time@units     = "s"

; End user modification area ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Define constants
  g     = 9.80665 ;gravity (m s-2)
  R_dry = 287.    ;ideal gas dry air constant (J kg-1 K-1)
  R_vap = 461.5   ;gas constant for water vapor
  c_p   = 1004.   ;specific heat at const pressure (J kg-1 K-1)
  P00   = 100000. ;intial pressure (Pa)
  l_v   = 2.5e6   ;latent heat of vaporization (J kg-1)
  l_s   = 2.836e6 ;latent heat of sublimation (J kg-1)
  kappa = R_dry/c_p
  pi    = 4*atan(1.)

; Latitude and longitude at center of observation site (see the following site:
; http://www.marine.csiro.au/marq/edd_search.Browse_Citation?txtSession=14156)
  lat           = -34.5
  lat@long_name = "latitude of column"
  lat@units     = "degrees N"
  lon           = 144.82
  lon@long_name = "longitude of column"
  lon@units     = "degrees E"

; Initial vertical profiles (only the first time in the selected day)
; Height in meters
  height           = f->height_3hr(0:30)
  height@long_name = "physical height at pressure levels"
  height@units     = "m"

; Pressure (convert from hPa to Pa)
  plev = f->pres(r3min,:)

  levels           = plev(0:dimsizes(plev)-2) * 100.
  levels@long_name = "pressure levels"
  levels@units     = "Pa"

  if (any(ismissing(levels))) then
    print("WARNING: The initial [levels] of day "+day_of_choice+" have " + \
          "missing values. Suggest adjustments to day selection or to" +   \
          "initial time (which can be adjusted by modifying rmin AND r3min)")
  end if

; Initial profile of potential temperature
  t_air = f->tair(r3min,:)

  tk = t_air(0:dimsizes(t_air)-2) + 273.15

  theta = tk * ((P00 / levels)^(R_dry / c_p))

; Water vapor mixing ratio, convert to specific humidity
  rv_gkg = f->rv(r3min,:)

  rv = rv_gkg(0:dimsizes(rv_gkg)-2) / 1000. ; convert to kg kg^-1

  qv = rv / (1. + rv) ; convert from mixing ratio to specific humidity

  ql           = new((/ dimsizes(qv) /),float)
  ql           = 0.
  ql@long_name = "initial profile of liquid water specific humidity"
  ql@units     = "kg kg^-1"

  qi           = new((/ dimsizes(qv) /),float)
  qi           = 0.
  qi@long_name = "initial profile of ice water specific humidity"
  qi@units     = "kg kg^-1"

; Calculate qt (total water specific humidity)
  qt           = qv + ql + qi
  qt@long_name = "initial profile of total water specific humidity"
  qt@units     = "kg kg^-1"

  if (any(ismissing(qt))) then
    print("WARNING: The initial profile of [qt] has missing values.")
  end if

; Calculate theta_il using eqn in ccpp-scm user's guide
  thetail           = theta - ((theta/tk)*(((l_v/c_p)*ql)+((l_s/c_p)*qi)))
  thetail@long_name = "initial profile of ice-liquid water potential " + \
                      "temperature"
  thetail@units     = "K"

  if (any(ismissing(thetail))) then
    print("WARNING: The initial profile of [thetail] has missing values.")
  end if

; Initial profiles of u and v
  wdir_deg     = f->wdir(rmin)
  wdir_rad     = wdir_deg * (pi / 180.)
  sfc_wnd_init = f->U0_5_Sta5(rmin)

  u_cms = f->u(rmin,:)

  u    = new((/ dimsizes(levels) /),float)
  u(0) = (sfc_wnd_init * cos(wdir_rad)) / 100.
  do i=1,dimsizes(levels)-1,1
    u(i) = u_cms(i-1) / 100. ; convert from cm s^-1 to m s^-1
  end do
  u@long_name = "initial profile of E-W horizontal wind"
  u@units     = "m s^-1"

  if (any(ismissing(u))) then
    print("WARNING: The initial profile of [u] has missing values.")
  end if

  v_cms = f->v(rmin,:)

  v    = new((/ dimsizes(levels) /),float)
  v(0) = (sfc_wnd_init * sin(wdir_rad)) / 100.
  do i=1,dimsizes(levels)-1,1
    v(i) = v_cms(i-1) / 100. ; convert from cm s^-1 to m s^-1
  end do
  v@long_name = "initial profile of N-S horizontal wind"
  v@units     = "m s^-1"

  if (any(ismissing(v))) then
    print("WARNING: The initial profile of [v] has missing values.")
  end if

  tke           = new((/ dimsizes(levels) /),float)
  tke           = 0.
  tke@long_name = "initial profile of turbulence kinetic energy"
  tke@units     = "m^2 s^-2"

  ozone           = new((/ dimsizes(levels) /),float)
  ozone           = 0.
  ozone@long_name = "initial profile of ozone mass mixing ratio"
  ozone@units     = "kg kg^-1"

; Forcing variables
; Surface temperature, although it can be solved for using a method following
; Deardorff (1984), the forumla needs the turbulent flux of potential 
; temperature and the viscosity of air, which can be difficult to solve for.
; Rather than using this formula, GLDAS can be utilized to estimate the surface
; skin layer temperature
  gl_dir = "/glade/scratch/damico/GLDAS_Wangara/"
  gl_00  = addfile(gl_dir+"GLDAS_NOAH025_3H.A19670714.0000.020.nc4.SUB.nc4", \
                   "r")

  gl_lat = gl_00->lat
  gl_lon = gl_00->lon

  glny = dimsizes(gl_lat)
  glnx = dimsizes(gl_lon)

  delete(gl_00)

  start_date = 0.
  end_date   = 0.

  start_date@units = "hours since 1967-07-14 15:00:00"
  end_date@units   = "hours since 1967-08-27 21:00:00"
  gldt             = 3

  end_date_on_start = cd_convert(end_date,start_date@units)

  gl_time_hr       = ispan(0,toint(end_date_on_start),gldt)
  gl_time_hr@units = start_date@units

  gl_time       = tofloat(gl_time_hr) * 60. * 60.
  gl_time@units = "seconds since 1967-07-14 15:00:00"

  time_yyyymmddhh = toint(cd_calendar(gl_time,0))

  glt_min = closest_val(time_s(rmin),gl_time)
  glt_max = closest_val(time_s(rmax),gl_time)

  gltime = gl_time(glt_min:glt_max)

  gl_tsurf = new((/ (glt_max-glt_min)+1,glny,glnx /),float)
  do i=glt_min,glt_max,1
    fname = "GLDAS_NOAH025_3H.A" + \
            sprinti("%0.4i",time_yyyymmddhh(i,0)) + \
            sprinti("%0.2i",time_yyyymmddhh(i,1)) + \
            sprinti("%0.2i",time_yyyymmddhh(i,2)) +"."+ \
            sprinti("%0.2i",time_yyyymmddhh(i,3))+ \
            sprinti("%0.2i",time_yyyymmddhh(i,4))+ \
            ".020.nc4.SUB.nc4"
    if (isfilepresent(gl_dir+fname)) then
      gl_ff                   = addfile(gl_dir+fname,"r")
      gl_tsurf(i-glt_min,:,:) = gl_ff->AvgSurfT_inst(0,:,:)
      print("Read->"+fname)
    else
      print(fname+" MISSING")
    end if
  end do

; Interpolate GLDAS to the middle of the Wangara field site (match lat and lon
; with the rest of experiment data)
  tsurf_pt = linint2_points_Wrap(gl_lon,gl_lat,gl_tsurf,False,lon,lat,0)

; Interpolate with time
  T_surf           = linint1(gltime,tsurf_pt(:,0),False,time_s(rmin:rmax),0)
  T_surf@long_name = "surface absolute temperature"
  T_surf@units     = "K"

; Surface pressure
  ps = f->psurf(rmin:rmax)

  p_surf           = ps * 100. ; Convert to Pa
  p_surf@long_name = "surface pressure"
  p_surf@units     = "Pa"

; Missing values of surface pressure are only an issue on Day 1, so if the user
; selected day_of_choice = 1, then the lowest pressure from the first 3-hourly 
; thermodynamic sounding can be used. Using day_of_choice = 1 is, however,
; not recommended.

; Sensible heat flux at the surface
  sh = f->shf_Wm2(rmin:rmax)

; Convert from W m^-2 to K m s^-1
  sh_flux_sfc           = sh * R_dry * T_surf / (c_p * p_surf)
  sh_flux_sfc@long_name = "surface sensible heat flux"
  sh_flux_sfc@units     = "K m s^-1"

; There are not too many missing values of shf_Wm2 in the Wangara data, but a
; few do appear. Take the average around missing values to replace missing
; value.
  do i=0,dimsizes(sh_flux_sfc)-1,1
    if (ismissing(sh_flux_sfc(i))) then
      sh_flux_sfc(i) = (sh_flux_sfc(i-1) + sh_flux_sfc(i+1)) * 0.5
    end if
  end do

; Given in the dataset are sensible heat flux, net radiation, and ground heat
; flux. Using these three, you can solve for latent heat flux.
  ghf_mW = f->ghf_mWcm2(rmin:rmax)

; Start by converting ground heat flux from mW cm^-2 to W m^-2
  ghf = ghf_mW
  ghf = ghf_mW * 10000. / 1000. ; 10000 cm^2 in 1 m^2, 1000 mW in 1 W

  ghf@units = "W m-2"

; Read in net radiation (in W m-2)
  netrad = f->netrad_Wm2(rmin:rmax)

; Solve Rn - G - H - LE = 0 for LE to determine latent heat flux
  lh = netrad - ghf - sh

; Convert from W m^-2 to kg kg^-1 m s^-1
  lh_flux_sfc           = lh * R_dry * T_surf / (l_v * p_surf)
  lh_flux_sfc@long_name = "surface latent heat flux"
  lh_flux_sfc@units     = "kg kg^-1 m s^-1"

; Although the corrected Hicks dataset has nearly complete data for sensible
; heat flux and net radiation (the corrected dataset [wangara2.data.txt]), the
; ground heat flux still has missing values, so LH must be corrected to avoid
; these missing values. Here an average is taken between two present values 
; and the missing value.
  do i=0,dimsizes(lh_flux_sfc)-1,1
    if (ismissing(lh_flux_sfc(i))) then
      lh_flux_sfc(i) = (lh_flux_sfc(i-1) + lh_flux_sfc(i+1)) * 0.5
    end if
  end do

  delete(ghf)
  delete(netrad)

; Begin vertical forcing, all of these arrays will be filled with data, but, if
; forcing_free = True (LINE 15), all nudging variables will be set to 0.
; Vertical motion, w is given in dataset, start with w_ls
  w = f->w(rmin:rmax,:)

  wls = w
  wls = w / 100. ; Convert from cm s^-1 to m s^-1

  ww_ls = wls(height|:,Time|:)

  w_ls      = new((/ dimsizes(levels),dimsizes(time) /),float)
  w_ls(0,:) = 0.
  do i=1,dimsizes(levels)-1,1
    w_ls(i,:) = ww_ls(i-1,:) * 1.
  end do
  w_ls@long_name = "large scale vertical velocity"
  w_ls@units     = "m s^-1"

; This section will probably end up varying day by day, but vertical motion is
; required and CCPP SCM does not work with missing values. 
  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(w_ls(i,j)) .and. i .ne. 0) then
        w_ls(i,j) = w_ls(i-1,j)
      end if
    end do
  end do

; Convert to omega (both are needed for CCPP SCM), start by reading in the 
; arrays of pressure and temperature with time and height.
  if (r3min .gt. 0 .and. r3max .lt. 314) then
    p_tz = f->pres(r3min-1:r3max+1,0:dimsizes(plev)-2)
    T_tz = f->tair(r3min-1:r3max+1,0:dimsizes(t_air)-2)
    t3h  = f->Time_3hr(r3min-1:r3max+1)
  else if (r3min .eq. 0)
    p_tz = f->pres(r3min:r3max+1,0:dimsizes(plev)-2)
    T_tz = f->tair(r3min:r3max+1,0:dimsizes(t_air)-2)
    t3h  = f->Time_3hr(r3min:r3max+1)
  else if (r3max .eq. 314)
    p_tz = f->pres(r3min-1:r3max,0:dimsizes(plev)-2)
    T_tz = f->tair(r3min-1:r3max,0:dimsizes(t_air)-2)
    t3h  = f->Time_3hr(r3min-1:r3max)
  end if
  end if
  end if
  t3 = t3h * 60. * 60.

  do i=0,dimsizes(t3)-1,1
    if (ismissing(t3(i))) then
      t3(i) = (t3(i-1) + t3(i+1)) * 0.5
    end if
  end do

  p_om = new((/ dimsizes(time),dimsizes(levels) /),float)
  T_om = new((/ dimsizes(time),dimsizes(levels) /),float)
  do i=0,dimsizes(levels)-1,1
    p_om(:,i) = linint1(t3,p_tz(:,i),False,time_s(rmin:rmax),0)
    T_om(:,i) = linint1(t3,T_tz(:,i),False,time_s(rmin:rmax),0)
  end do

; Use the full arrays of pressure (convert to Pa) and temperature (convert to
; K) to find the density of air (in kg m^-3)
  rho   = (p_om * 100.) / (R_dry * (T_om + 273.15))
  rho!0 = "Time"
  rho!1 = "height"

  rho_om = rho(height|:,Time|:)

; Convert to omega using omega = -w * rho * g
  omega = w_ls * rho_om * g
  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (.not. ismissing(omega(i,j)) .and. omega(i,j) .ne. 0.) then
        omega(i,j) = omega(i,j) * -1.
      end if
    end do
  end do
  omega@long_name = "large scale pressure vertical velocity"
  omega@units     = "Pa s^-1"

; Still will have missing values of omega where temperature and pressure
; values are missing
  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(omega(i,j)) .and. i .ne. 0) then
        omega(i,j) = omega(i-1,j)
      end if
    end do
  end do

; Geostrophic winds are only given at the surface, with a regression equation
; to 400 m (the authors attribute this zone to the area of frictional turning).
; Beyond this point, assume geostrophic wind is equal to observed wind. This
; section of code is not necessary, as the best option with forcing for CCPP
; SCM would be u and v nudging, rather than geostrophic wind. Below you will 
; see a block of code that is commented out. That block is where the 
; interpolation occurs. Below that block, you will see u_g and v_g set to all
; zero. It is ultimately the choice of the user if s/he wants to use
; geostrophic momentum forcing (if s/he were using forcing at all) and to 
; comment out the sections of code where geostrophic winds are set to zero.
  if (r3min .gt. 0 .and. r3max .lt. 314) then
    u_geo_sfc = f->synoptic_geou(r3min-1:r3max+1)
    v_geo_sfc = f->synoptic_geov(r3min-1:r3max+1)
  else if (r3min .eq. 0)
    u_geo_sfc = f->synoptic_geou(r3min:r3max+1)
    v_geo_sfc = f->synoptic_geov(r3min:r3max+1)
  else if (r3max .eq. 314)
    u_geo_sfc = f->synoptic_geou(r3min-1:r3max)
    v_geo_sfc = f->synoptic_geov(r3min-1:r3max)
  end if
  end if
  end if

  u_geo_time = linint1(t3,u_geo_sfc,False,time_s(rmin:rmax),0)
  v_geo_time = linint1(t3,v_geo_sfc,False,time_s(rmin:rmax),0)

; Regression equations given in Clarke et al. (1971) for geostrophic wind
  u_geo_400 = (1.092 * u_geo_time) + 25.
  v_geo_400 = (1.022 * v_geo_time) - 17.

; All winds at all heights and [selected] times, which will serve as 
; geostrophic above 400 m
  uh = f->u(rmin:rmax,:)
  vh = f->v(rmin:rmax,:)

  sfc_wind    = f->U0_5_Sta5(rmin:rmax)
  sfc_dir_deg = f->wdir(rmin:rmax)
  sfc_dir_rad = sfc_dir_deg * (pi / 180.)

  uha      = new((/ dimsizes(time),dimsizes(levels) /),float)
  vha      = new((/ dimsizes(time),dimsizes(levels) /),float)
  uha(:,0) = sfc_wind * cos(sfc_dir_rad)
  vha(:,0) = sfc_wind * sin(sfc_dir_rad)
  do i=1,dimsizes(levels)-1,1
    uha(:,i) = uh(:,i-1)
    vha(:,i) = vh(:,i-1)
  end do

; Interpolate between the surface and 400 m, and then use the winds above 400 m
; to serve as geostrophic
;  h400 = closest_val(400.,height)
;
;  ug    = new((/ dimsizes(uha) /),float)
;  vg    = new((/ dimsizes(vha) /),float)
;  ghgt  = (/ 0.,400. /)
;  guint = new((/ dimsizes(time),dimsizes(ghgt) /),float)
;  gvint = new((/ dimsizes(time),dimsizes(ghgt) /),float)
;  do i=0,dimsizes(time)-1,1
;    guint(i,:) = (/ u_geo_time(i),u_geo_400(i) /)
;    gvint(i,:) = (/ v_geo_time(i),v_geo_400(i) /)
;    ug(i,:)    = linint1(ghgt,guint(i,:),False,height,0)
;    vg(i,:)    = linint1(ghgt,gvint(i,:),False,height,0)
;  end do
;  do i=h400,dimsizes(levels)-1,1
;    ug(:,i) = uha(:,i)
;    vg(:,i) = vha(:,i)
;  end do
;
;  ug_ms   = ug / 100.
;  vg_ms   = vg / 100.
;  ug_ms!0 = "Time"
;  ug_ms!1 = "height"
;  vg_ms!0 = "Time"
;  vg_ms!1 = "height"
;
;  ugeo = ug_ms(height|:,Time|:)
;  vgeo = vg_ms(height|:,Time|:)
;
;  u_g           = ugeo * 1.
  u_g           = new((/ dimsizes(levels),dimsizes(time) /),float)
  u_g           = 0.
  u_g@long_name = "large scale geostrophic E-W wind"
  u_g@units     = "m s^-1"
;  v_g           = vgeo * 1.
  v_g           = new((/ dimsizes(levels),dimsizes(time) /),float)
  v_g           = 0.
  v_g@long_name = "large scale geostrophic N-S wind"
  v_g@units     = "m s^-1"

; As there is plenty of data available from Wangara, the CCPP SCM nudging
; variables can be used, but if forcing_free = True (LINE 15), then each will 
; equal 0.0
  uha!0 = "Time"
  uha!1 = "height"

  un = uha(height|:,Time|:)

  u_nudge           = un / 100. ; Convert to m s^-1
  u_nudge@long_name = "E-W wind to nudge toward"
  u_nudge@units     = "m s^-1"

; Again, to avoid missing values if you are using nudging (forcing),
; adjustments need to be made. Here if the value is missing, adapt the value
; just below it. Some days do have lots of missing data, so be careful about
; your selection of days. Most of the missing data is near the top of the 
; the measurements.
  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(u_nudge(i,j)) .and. i .ne. 0) then
        u_nudge(i,j) = u_nudge(i-1,j)
      else if (ismissing(u_nudge(i,j)) .and. i .eq. 0)
        u_nudge(i,j) = 0.
      end if
      end if
    end do
  end do

  vha!0 = "Time"
  vha!1 = "height"

  vn = vha(height|:,Time|:)

  v_nudge           = vn / 100. ; Convert to m s^-1
  v_nudge@long_name = "N-S wind to nudge toward"
  v_nudge@units     = "m s^-1"

  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(v_nudge(i,j)) .and. i .ne. 0) then
        v_nudge(i,j) = v_nudge(i-1,j)
      else if (ismissing(v_nudge(i,j)) .and. i .eq. 0) then
        v_nudge(i,j) = 0.
      end if
      end if
    end do
  end do

  T_om!0 = "Time"
  T_om!1 = "height"

  Tn = T_om(height|:,Time|:)

  T_nudge           = Tn + 273.15 ; Covert to K
  T_nudge@long_name = "absolute temperature to nudge toward"
  T_nudge@units     = "K"

  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(T_nudge(i,j)) .and. i .ne. 0) then
        T_nudge(i,j) = T_nudge(i-1,j)
      else if (ismissing(T_nudge(i,j)) .and. i .eq. 0) then
        T_nudge(i,j) = T_nudge(i+1,j)
      end if
      end if
    end do
  end do

  if (r3min .gt. 0 .and. r3max .lt. 314) then
    pfull_3 = f->pres(r3min-1:r3max+1,0:dimsizes(plev)-2)
  else if (r3min .eq. 0)
    pfull_3 = f->pres(r3min:r3max+1,0:dimsizes(plev)-2)
  else if (r3max .eq. 314)
    pfull_3 = f->pres(r3min-1:r3max,0:dimsizes(plev)-2)
  end if
  end if
  end if

  pfull = new((/ dimsizes(time),dimsizes(levels) /),float)
  do i=0,dimsizes(levels)-1,1
    pfull(:,i) = linint1(t3,pfull_3(:,i),False,time_s(rmin:rmax),0)
  end do

  pfull!0 = "Time"
  pfull!1 = "height"

  pfhPa = pfull(height|:,Time|:)

  pfPa = pfhPa * 100.

  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(pfPa(i,j)) .and. i .ne. 0) then
        pfPa(i,j) = pfPa(i-1,j)
      else if (ismissing(pfPa(i,j)) .and. i .eq. 0) then
        pfPa(i,j) = pfPa(i+1,j)
      end if
      end if
    end do
  end do

  thil_nudge           = T_nudge * ((P00 / pfPa)^(R_dry / c_p))
  thil_nudge@long_name = "potential temperature to nudge toward"
  thil_nudge@units     = "K"

  if (r3min .gt. 0 .and. r3max .lt. 314) then
    rvfull_3 = f->rv(r3min-1:r3max+1,0:dimsizes(plev)-2)
  else if (r3min .eq. 0)
    rvfull_3 = f->rv(r3min:r3max+1,0:dimsizes(plev)-2)
  else if (r3max .eq. 314)
    rvfull_3 = f->rv(r3min-1:r3max,0:dimsizes(plev)-2)
  end if
  end if
  end if

  rvfull = new((/ dimsizes(time),dimsizes(levels) /),float)
  do i=0,dimsizes(levels)-1,1
    rvfull(:,i) = linint1(t3,rvfull_3(:,i),False,time_s(rmin:rmax),0)
  end do

  rvfull!0 = "Time"
  rvfull!1 = "height"

  rvf = rvfull(height|:,Time|:)

  qt_nudge           = (rvf / (1. + rvf)) / 1000.
  qt_nudge@long_name = "q_t to nudge toward"
  qt_nudge@units     = "kg kg^-1"

  do i=0,dimsizes(levels)-1,1
    do j=0,dimsizes(time)-1,1
      if (ismissing(qt_nudge(i,j)) .and. i .ne. 0) then
        qt_nudge(i,j) = qt_nudge(i-1,j)
      else if (ismissing(qt_nudge(i,j)) .and. i .eq. 0) then
        qt_nudge(i,j) = qt_nudge(i+1,j)
      end if
      end if
    end do
  end do

  if (forcing_free) then
    u_nudge    = 0.
    v_nudge    = 0.
    T_nudge    = 0.
    thil_nudge = 0.
    qt_nudge   = 0.
  end if

; Remaining variables can be set to zero
  dT_dt_rad           = new((/ dimsizes(levels),dimsizes(time) /),float)
  dT_dt_rad           = 0.
  dT_dt_rad@long_name = "prescribed radiative heating rate"
  dT_dt_rad@units     = "K s^-1"

  h_advec_thetail           = new((/ dimsizes(levels),dimsizes(time) /), \
                              float)
  h_advec_thetail           = 0.
  h_advec_thetail@long_name = "prescribed theta_il tendency due to " + \
                              "horizontal advection"
  h_advec_thetail@units     = "K s^-1"

  v_advec_thetail           = new((/ dimsizes(levels),dimsizes(time) /), \
                              float)
  v_advec_thetail           = 0.
  v_advec_thetail@long_name = "prescribed theta_il tendency due to " + \
                              "vertical advection"
  v_advec_thetail@units     = "K s^-1"

  h_advec_qt           = new((/ dimsizes(levels),dimsizes(time) /),float)
  h_advec_qt           = 0.
  h_advec_qt@long_name = "prescribed q_t tendency due to horizontal "+\
                         "advection"
  h_advec_qt@units     = "kg kg^-1 s^-1"

  v_advec_qt           = new((/ dimsizes(levels),dimsizes(time) /),float)
  v_advec_qt           = 0.
  v_advec_qt@long_name = "prescribed q_t tendency due to vertical "+\
                         "advection"
  v_advec_qt@units     = "kg kg^-1 s^-1"

; Define dimension sizes for file creation
  ntim = dimsizes(time)
  klev = dimsizes(levels)

; Write the netCDF output file, titled "wangara_dayXX.nc" or
; "wangara_dayXX_noForce.nc"
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")

  if (forcing_free) then
    fout = "wangara_day"+day_of_choice+"_noForce.nc"   ; File name of output
    system("/bin/rm -fv "+fout)                        ; If a version already 
                                                       ; exists, delete it.
  else
    fout = "wangara_day"+day_of_choice+".nc"           ; File name of output
    system("/bin/rm -fv "+fout)                        ; If a version already 
                                                       ; exists, delete it.
  end if
  fo = addfile(fout,"c")                               ; Create the netCDF file

  setfileoption(fo,"DefineMode",True) ;Enter define mode
  fAtt               = True           ;Set file attributes to True
  fAtt@title         = "CCPP SCM forcing file for Wangara day "+day_of_choice+ \
                       "-"+(day_of_choice+1)+" case"
  fAtt@creation_date = systemfunc("date")
  fileattdef(fo,fAtt)                 ;Add attibutes to output file

  dimNames = (/ "time","levels" /)
  dimSizes = (/ ntim,klev /)
  dimUnlim = (/ False,True /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"time",typeof(time),"time")
  filevarattdef(fo,"time",time)
  fo->time = (/ time /)

  filevardef(fo,"levels",typeof(levels),"levels")
  filevarattdef(fo,"levels",levels)
  fo->levels = (/ levels /)

; Define group names for netCDF4 file
  grpnames = (/ "scalars","initial","forcing" /)
  filegrpdef(fo,grpnames)

  g1 = fo=>/scalars
  g2 = fo=>/initial
  g3 = fo=>/forcing

; Scalars  --> Lat and Lon
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
  g2->height = (/height/)

  filevardef(g2,"thetail",typeof(thetail),"levels")
  filevarattdef(g2,"thetail",thetail)
  g2->thetail = (/thetail/)

  filevardef(g2,"qt",typeof(qt),"levels")
  filevarattdef(g2,"qt",qt)
  g2->qt = (/qt/)

  filevardef(g2,"ql",typeof(ql),"levels")
  filevarattdef(g2,"ql",ql)
  g2->ql = (/ql/)

  filevardef(g2,"qi",typeof(qi),"levels")
  filevarattdef(g2,"qi",qi)
  g2->qi = (/qi/)

  filevardef(g2,"u",typeof(u),"levels")
  filevarattdef(g2,"u",u)
  g2->u = (/u/)

  filevardef(g2,"v",typeof(v),"levels")
  filevarattdef(g2,"v",v)
  g2->v = (/v/)

  filevardef(g2,"tke",typeof(tke),"levels")
  filevarattdef(g2,"tke",tke)
  g2->tke = (/tke/)

  filevardef(g2,"ozone",typeof(ozone),"levels")
  filevarattdef(g2,"ozone",ozone)
  g2->ozone = (/ozone/)

; Forcing
  filedimdef(g3,dimNames,dimSizes,dimUnlim)

  filevardef(g3,"p_surf",typeof(p_surf),"time")
  filevarattdef(g3,"p_surf",p_surf)
  g3->p_surf = (/ p_surf /)

  filevardef(g3,"T_surf",typeof(T_surf),"time")
  filevarattdef(g3,"T_surf",T_surf)
  g3->T_surf = (/ T_surf /)

  filevardef(g3,"sh_flux_sfc",typeof(sh_flux_sfc),"time")
  filevarattdef(g3,"sh_flux_sfc",sh_flux_sfc)
  g3->sh_flux_sfc = (/ sh_flux_sfc /)

  filevardef(g3,"lh_flux_sfc",typeof(lh_flux_sfc),"time")
  filevarattdef(g3,"lh_flux_sfc",lh_flux_sfc)
  g3->lh_flux_sfc = (/ lh_flux_sfc /)

  filevardef(g3,"w_ls",typeof(w_ls),(/"levels","time"/))
  filevarattdef(g3,"w_ls",w_ls)
  g3->w_ls = (/ w_ls /)

  filevardef(g3,"omega",typeof(omega),(/"levels","time"/))
  filevarattdef(g3,"omega",omega)
  g3->omega = (/ omega /)

  filevardef(g3,"u_g",typeof(u_g),(/"levels","time"/))
  filevarattdef(g3,"u_g",u_g)
  g3->u_g = (/ u_g /)

  filevardef(g3,"v_g",typeof(v_g),(/"levels","time"/))
  filevarattdef(g3,"v_g",v_g)
  g3->v_g = (/ v_g /)

  filevardef(g3,"u_nudge",typeof(u_nudge),(/"levels","time"/))
  filevarattdef(g3,"u_nudge",u_nudge)
  g3->u_nudge = (/ u_nudge /)

  filevardef(g3,"v_nudge",typeof(v_nudge),(/"levels","time"/))
  filevarattdef(g3,"v_nudge",v_nudge)
  g3->v_nudge = (/ v_nudge /)

  filevardef(g3,"T_nudge",typeof(T_nudge),(/"levels","time"/))
  filevarattdef(g3,"T_nudge",T_nudge)
  g3->T_nudge = (/ T_nudge /)

  filevardef(g3,"thil_nudge",typeof(thil_nudge),(/"levels","time"/))
  filevarattdef(g3,"thil_nudge",thil_nudge)
  g3->thil_nudge = (/ thil_nudge /)

  filevardef(g3,"qt_nudge",typeof(qt_nudge),(/"levels","time"/))
  filevarattdef(g3,"qt_nudge",qt_nudge)
  g3->qt_nudge = (/ qt_nudge /)

  filevardef(g3,"dT_dt_rad",typeof(dT_dt_rad),(/"levels","time"/))
  filevarattdef(g3,"dT_dt_rad",dT_dt_rad)
  g3->dT_dt_rad = (/ dT_dt_rad /)

  filevardef(g3,"h_advec_thetail",typeof(h_advec_thetail), \
            (/"levels","time"/))
  filevarattdef(g3,"h_advec_thetail",h_advec_thetail)
  g3->h_advec_thetail = (/ h_advec_thetail /)

  filevardef(g3,"v_advec_thetail",typeof(v_advec_thetail), \
            (/"levels","time"/))
  filevarattdef(g3,"v_advec_thetail",v_advec_thetail)
  g3->v_advec_thetail = (/ v_advec_thetail /)

  filevardef(g3,"h_advec_qt",typeof(h_advec_qt),(/"levels","time"/))
  filevarattdef(g3,"h_advec_qt",h_advec_qt)
  g3->h_advec_qt = (/ h_advec_qt /)

  filevardef(g3,"v_advec_qt",typeof(v_advec_qt),(/"levels","time"/))
  filevarattdef(g3,"v_advec_qt",v_advec_qt)
  g3->v_advec_qt = (/ v_advec_qt /)

  print("No fatal errors, complete at "+systemfunc("date"))
  print("wrote new file: "+fout)

end

