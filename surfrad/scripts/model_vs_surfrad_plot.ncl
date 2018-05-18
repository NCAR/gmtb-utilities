;************************************************
; load required libraries and begin
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;************************************************
; read in command line arguments from driver script 
; (run_model_vs_surfrad_plot.ncl)
;************************************************
; srad_file
if (.not. isvar("srad_file")) then
  print("ERROR: 'srad_file' not set.")
  exit
end if

; ref_file1
if (.not. isvar("ref_file1")) then
  print("ERROR: 'ref_file1' not set.")
  exit
end if

; ref_files_dir
if (.not. isvar("ref_files_dir")) then
  print("ERROR: 'ref_files_dir' not set.")
  exit
end if

; png_file
if (.not. isvar("png_file")) then
  print("ERROR: 'png_file' not set.")
  exit
end if

begin

;************************************************
; Read in SURFRAD observation data
; This data needs to be created using the run_ascii2nc.ksh driver script
;************************************************                               
; Radiation input file
;rad_in       = "/scratch4/BMC/gmtb/harrold/test_surfrad/surfrad/proc/dra/dra_2017092500_SW.nc"
rad_in       = ""+srad_file+""

; Add the file
rin          = addfile(rad_in,"r")
 
; Get the grib code from SURFRAD data file
srad_grib_code = rin->obs_gc(0)

; Check to make sure the grib code passed in from the driver script 
; matches the grib code included in the SURFRAD data. If so, read
; the data.
; 204 = downward shortwave
; 205 = downward longwave
; 211 = upward shortwave
; 212 = upward longwave

; Read SURFRAD data from input file
srad_vals      = rin->obs_val

; Get the station lat/lon from SURFRAD data file
stid_lat       = rin->hdr_lat(0)
stid_lon       = rin->hdr_lon(0)

; Get the station name from SURFRAD data file
station_char = rin->hdr_sid_table(0,:)
station      = charactertostring(station_char)

; Statistics output from processing SURFRAD data needs to be changed 
; in the Ascii2NCConfig. See run_ascii2nc.ksh for details.
; By default the configuration file outputs median, min, and max but 
; this be changed to things like mean, 10th percentile, 90th percentile, etc.
stat_num = 3 
stat_dim = dimsizes(srad_vals)/stat_num

; Create new arrays to store the values for the statistics of interest.
; By default, this will be median, min, and max.
var_stat = new((/stat_dim/),typeof(srad_vals))
var_lowval    = new((/stat_dim/),typeof(srad_vals))
var_highval    = new((/stat_dim/),typeof(srad_vals))

; Read the data into the established arrays.
do i = 0,stat_dim-1
  var_stat(i)   = srad_vals(stat_num*i)
  var_lowval(i) = srad_vals(stat_num*i + 1)
  var_highval(i)    = srad_vals(stat_num*i + 2)
end do

; that contains those values.
var_mnmx   = new((/2,stat_dim/),typeof(srad_vals))
do i = 0,stat_dim-1
  var_mnmx(0,i) = var_lowval(i)
  var_mnmx(1,i) = var_highval(i)
end do

; Read SURFRAD data valid time
srad_times_all_char = rin->hdr_vld_table
srad_times      = charactertostring(srad_times_all_char)

;************************************************
; read in model data
; Because the variable name changes between the first 
; forecast hour (*_avg*) and all other forecast hours (*_avg6h*)
; we need to organize the data into two directories
; and read the data in separately.
; 
;************************************************  

; Read in the first forecast file passed from the driver script
;ref_file1 = "/scratch4/BMC/gmtb/harrold/test_surfrad/gfs.20170925/gfs.t00z.pgrb2.0p50.f006.grib2" ; first fhr input file
ref_file_a       = ""+ref_file1+""
ref_file    = addfile(ref_file_a,"r")

lat                = ref_file->lat_0
lon                = ref_file->lon_0

; Read in variable name depending on grib_code passed in from
; driver script
if (grib_code.eq.204) then
  print("Reading DSWRF*avg from model output")
  ref_var	     = ref_file->DSWRF_P8_L1_GLL0_avg
  ref_intm           = ref_file->DSWRF_P8_L1_GLL0_avg@initial_time
  ref_fcstm          = ref_file->DSWRF_P8_L1_GLL0_avg@forecast_time
  ref_name           = ref_file->DSWRF_P8_L1_GLL0_avg@long_name
else if (grib_code.eq.205) then
  print("Reading DLWRF from model output")
  ref_var	     = ref_file->DLWRF_P8_L1_GLL0_avg
  ref_intm           = ref_file->DLWRF_P8_L1_GLL0_avg@initial_time
  ref_fcstm          = ref_file->DLWRF_P8_L1_GLL0_avg@forecast_time
  ref_name           = ref_file->DLWRF_P8_L1_GLL0_avg@long_name
else
  print("Variable name cannot be defined for this grib_code. Please add it to this list")
  exit
end if
end if

nx = dimsizes(lon)
ny = dimsizes(lat)

lat2d = new((/ny,nx/),float)
lon2d = new((/ny,nx/),float)

do r = 0, ny-1
  lat2d(r,:) = lat(r)
end do
do c = 0, nx-1
  lon2d(:,c) = lon(c)
end do

; using lat lon from surfrad netcdf, get closest x,y points
stid_ij = getind_latlon2d(lat2d,lon2d,stid_lat,stid_lon)
stid_i  = stid_ij(0,0)
stid_j  = stid_ij(0,1)

; Read in the remaining forecast files into another array
;sublist_dir = "/scratch4/BMC/dtc/jwolff/gmtb/gfs.20170925/" ; input directory without first fhr
sublist_dir    = ""+ref_files_dir+""   ; input directory

sublist_all    = systemfunc ("ls "+sublist_dir+"*pgrb2*.grib2") ; file paths

sublist        = addfiles (sublist_all, "r")

ListSetType (sublist, "join")

if (grib_code.eq.204) then
  print("Reading DSWRF*avg6h from model output")
  sublist_var         = sublist[:]->DSWRF_P8_L1_GLL0_avg6h
  intm                = sublist[:]->DSWRF_P8_L1_GLL0_avg6h@initial_time
  fcstm               = sublist[:]->DSWRF_P8_L1_GLL0_avg6h@forecast_time
else if (grib_code.eq.205) then
  print("Reading DLWRF*avg6h from model output")
  sublist_var         = sublist[:]->DLWRF_P8_L1_GLL0_avg6h
  intm                = sublist[:]->DLWRF_P8_L1_GLL0_avg6h@initial_time
  fcstm               = sublist[:]->DLWRF_P8_L1_GLL0_avg6h@forecast_time
else
  print("Variable name cannot be defined for this grib_code. Please add it to this list")
  exit
end if
end if

; Join the first forecast and all other forecast times together
; into a single array
full_intm = array_append_record(ref_intm,intm,0)
full_fcstm = array_append_record(ref_fcstm,fcstm,0)

ref_var3d= new((/1,ny,nx/),float)
ref_varConform = conform (ref_var3d,ref_var,(/1,2/))

; Join the first forecast output and all other forecast file 
; output together into a single array
full_list_var = array_append_record (ref_varConform, sublist_var, 0)

rad_model = new((/dimsizes(full_fcstm)/),float)

; Pull out the model output at the station location for each
; forecast time
do i = 0, dimsizes(full_fcstm)-1
  rad_model(i) = full_list_var(i,stid_i,stid_j)
end do

;************************************************
; build arrays for time and matched data
;************************************************

; Time arry for SURFRAD data (format 20160925_000000)
srad_yyyy = new((/dimsizes(srad_times)/),integer)
srad_mm   = new((/dimsizes(srad_times)/),integer)
srad_dd   = new((/dimsizes(srad_times)/),integer)
srad_hh   = new((/dimsizes(srad_times)/),integer)
srad_min  = new((/dimsizes(srad_times)/),integer)
srad_ss   = new((/dimsizes(srad_times)/),integer)
srad_utc  = new((/dimsizes(srad_times)/),double)
units     = "seconds since 1970-1-1 00:00:0.0"

do i = 0,dimsizes(srad_times)-1
  srad_yyyy(i) = tointeger(getSubString(srad_times(i),0,3))
  srad_mm(i)   = tointeger(getSubString(srad_times(i),4,5))
  srad_dd(i)   = tointeger(getSubString(srad_times(i),6,7))
  srad_hh(i)   = tointeger(getSubString(srad_times(i),9,10))
  srad_min(i)  = tointeger(getSubString(srad_times(i),11,12))
  srad_ss(i)   = tointeger(getSubString(srad_times(i),13,14))
  srad_utc(i)  = ut_inv_calendar(srad_yyyy(i),srad_mm(i),srad_dd(i),srad_hh(i),srad_min(i),srad_ss(i),units,0)
end do

; Time array for model data (format 09/25/2017 (00:00))
year = new((/dimsizes(full_fcstm)/),integer)
mon  = new((/dimsizes(full_fcstm)/),integer)
day  = new((/dimsizes(full_fcstm)/),integer)
hour  = new((/dimsizes(full_fcstm)/),integer)
date = new((/dimsizes(full_fcstm)/),double)
fcst = new((/dimsizes(full_fcstm)/),double)

do i = 0,dimsizes(full_fcstm)-1
  year(i) = stringtointeger(getSubString(full_intm(i),6,9))
  mon(i)  = stringtointeger(getSubString(full_intm(i),0,1))
  day(i)  = stringtointeger(getSubString(full_intm(i),3,4))
  hour(i)  = stringtointeger(getSubString(full_intm(i),12,13))
  time = (/0.0/)
  date(i) = ut_inv_calendar(year(i),mon(i),day(i),hour(i),0,0,units,0)
  fcst(i) = (/date(i) + stringtointeger(full_fcstm(i))*3600/)
  fcst@units = "seconds since 1970-01-01 00:00:0.0"
  utc_date = ut_calendar(fcst, 0)
  year   = floattointeger(utc_date(:,0))    ; Convert to integer for
  month  = floattointeger(utc_date(:,1))    ; use in the sprinti function.
  day    = floattointeger(utc_date(:,2))
  hour   = floattointeger(utc_date(:,3))
  minute = floattointeger(utc_date(:,4))
  second = utc_date(:,5)
  date_str = "Valid " + sprinti("%0.2i/", month) + sprinti("%0.2i/",day) + \
             sprinti("%0.4i", year) + " " + sprinti("%0.2i:00 ", hour) + \
             "UTC"
  ;print(date_str)
end do

; Create new arrays for SURFRAD/model matching times
srad_int_time    = new((/dimsizes(full_fcstm)/),double)
srad_var_stat    = new((/dimsizes(full_fcstm)/),double)
srad_var_lowval  = new((/dimsizes(full_fcstm)/),double)
srad_var_highval = new((/dimsizes(full_fcstm)/),double)

; Fill new arrays for matching times
do i = 0,dimsizes(date)-1

  srad_int_time(i)    = srad_utc(ind(fcst(i).eq.srad_utc))
  srad_var_stat(i)    = var_stat(ind(fcst(i).eq.srad_utc))
  srad_var_lowval(i)  = var_lowval(ind(fcst(i).eq.srad_utc))
  srad_var_highval(i) = var_highval(ind(fcst(i).eq.srad_utc))
end do

; Fill min/max array for matching times
srad_var_mnmx = new((/2,dimsizes(full_fcstm)/),double)
do i = 0,dimsizes(date)-1
  srad_var_mnmx(0,i) = var_lowval(ind(fcst(i).eq.srad_utc))
  srad_var_mnmx(1,i) = var_highval(ind(fcst(i).eq.srad_utc))
end do

; Combine all data (stat, lowval, highval) for matching 
; times into one array 
srad_var      = new((/3,dimsizes(full_fcstm)/),double)
srad_var(0,:) = srad_var_stat
srad_var(1,:) = srad_var_lowval
srad_var(2,:) = srad_var_highval

; common times 
srad_model_time = doubletofloat(srad_int_time)

;************************************************
; Create a plot using the following parameters
;************************************************
wks   = gsn_open_wks("png",""+png_file+"")
gsn_define_colormap(wks,"default")

; ============ plot0 SURFRAD values ============
; general plot specs
res                      = True
;res@tiMainString         = "Model Output vs. SURFRAD"
;res@gsnCenterString      = ""+station+" ("+stid_lat+","+stid_lon+")"
;res@tiMainFontHeightF    = 0.02

res@tiXAxisString        = "Hour of Day (UTC)"
res@tiYAxisString        = ""+ref_name+""
res@tiXAxisFontHeightF   = 0.02
res@tiYAxisFontHeightF   = 0.02
res@xyDashPattern        = 0  ; make all solid lines

res@tmXBMode             = "Explicit"
res@tmXBValues           = (/0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19/)
res@tmXBLabelFontHeightF = 0.015
res@tmYLLabelFontHeightF = 0.015
res@tmXBLabels = (/"06","12", "18", "00", "06", "12", "18", "00", "06", "12", "18", "00", "06", "12", "18", "00", "06", "12", "18", "00"/)
res@trXMaxF              = 19

res@xyLineThicknesses      = (/4.0,4.0/)
res@xyLineColors           = (/4,2/)
res@xyDashPattern          = 5
res@trYMinF                = -50.0
res@trYMaxF                = 1250.0

res@tmYROn                 = False
res@pmLegendDisplayMode    = "Never"   ; Display a legend

res@gsnFrame          = False
res@gsnDraw           = False

; First plot time series for SURFRAD data
plot0 =  gsn_csm_xy(wks,ispan(0,dimsizes(srad_model_time)-1,1),rad_model,res)

; ============ plot1 model stat values ============
delete(res@xyLineColors)
delete(res@xyLineThicknesses)
res@xyMarkLineMode     = "MarkLines"    ; Markers *and* lines
res@xyMarkers          = (/4/)    ; 4 different markers
res@xyMarkerThicknessF = (/4.0/)
res@xyLineColors       = (/27/)
res@xyMarkerColors     = (/27/)
res@xyLineThicknesses  = (/2.0/)
res@xyDashPattern      = 0
res@tiYAxisString        = ""+ref_name+""

plot1 = gsn_csm_xy(wks,ispan(0,dimsizes(srad_model_time)-1,1),srad_var(0,:),res)

; ============ plot2 adds low/high shaded area values ============
; Create a plot with the area between both curves filled in grey.
delete(res@xyLineColors)
delete(res@xyLineThicknesses)
delete(res@xyMarkLineMode)

res@tiMainString        = "Model Output vs. SURFRAD"
res@gsnCenterString     = ""+station+" ("+stid_lat+","+stid_lon+")"
res@tiMainFontHeightF   = 0.02
res@pmLegendDisplayMode = "Never"
res@gsnXYFillColors     = 28
res@xyLineColor         = -1                     ; make the line transparent.
plot2                   = gsn_csm_xy(wks,ispan(0,dimsizes(srad_model_time)-1,1),srad_var_mnmx(0:1,:),res)  ; Create filled XY plot.

overlay(plot2,plot0)
overlay(plot2,plot1)

draw(plot2)

frame(wks)

end
