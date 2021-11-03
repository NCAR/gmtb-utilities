;*************************************************
; zonal_radiation_fluxes.ncl
; This script calculates the zonal averages of liquid water path and ice water path
; from CERES dataset and multiple GFS global run outputs. Modify as needed.
; Xia Sun, xia.sun@noaa.gov, 2020-2021
;************************************************
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************************
begin

setvalues NhlGetWorkspaceObjectId()
    "wsMaximumSize" : 300000000
end setvalues  

model="GFS"                           ;experiment name using GFS model  
year="2020"  
month="01"  
ldy="05"                             ;leading day
expname=str_upper(model)+"16rt2"     ;need to change to your experiment name

; CERES data directory
obsdir="/dir/to/your/CERES/"        ;need to change to your CERES data dir


;******************Read in Model Output from Different Model Scenarios*******************************
 fName5= "DIRdate_DY05.txt"
 dir="/dir/to/model/run/one"
 dir1="/dir/to/model/run/two"
 dir2="/dir/to/model/run/three"
 dir3="/dir/to/model/run/four"
 dir4="/dir/to/model/run/five"
   
 date5= systemfunc("cut -c1-10 "+ fName5)
 realdate5=systemfunc("cut -c1-8 "+ fName5)
 init5=systemfunc("cut -c9-10 "+ fName5)
 print(realdate5)
 print(init5)
 
 ; fName10= "DIRdate_DY10.txt"                            ;I am only ploting day 5 forecast here.
 ; date10= systemfunc("cut -c1-10 "+ fName10)
 ; realdate10=systemfunc("cut -c1-8 "+ fName10)
 ; init10=systemfunc("cut -c9-10 "+ fName10)

 i=0
 dirs5=" "
 dirs51 =" "
 dirs52=" "
 dirs53=" "
 dirs54=" "
 ; dirs10=" "

 do while (i.le.6)
  dirs5= dirs5 + dir+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs51= dirs51 + dir1+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs52= dirs52 + dir2+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs53= dirs53 + dir3+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs54= dirs54 + dir4+"/gfs."+realdate5(i)+init5(i)+"/ "
  ; dirs10= dirs10 + dir+"/gfs."+realdate10(i)+init10(i)+"/ "
  i=i+1
 end do

seltime5 = " -type f \( -name gfs.t00z.sfluxgrbf102_radi_Regrid.nc -o -name gfs.t00z.sfluxgrbf108_radi_Regrid.nc -o -name gfs.t00z.sfluxgrbf114_radi_Regrid.nc -o -name gfs.t00z.sfluxgrbf120_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf102_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf108_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf114_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf120_radi_Regrid.nc \)  "
seltime10 = " -type f \( -name gfs.t00z.sfluxgrbf222_radi_Regrid.nc -o -name gfs.t00z.sfluxgrbf228_radi_Regrid.nc -o -name gfs.t00z.sfluxgrbf234_radi_Regrid.nc -o -name gfs.t00z.sfluxgrbf240_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf222_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf228_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf234_radi_Regrid.nc -o -name gfs.t12z.sfluxgrbf240_radi_Regrid.nc \)  "
cmd="find " + dirs5 + seltime5 

fili= systemfunc(cmd)
nfili=dimsizes(fili)

; cmd10="find " + dirs10 + seltime10 
; fili10= systemfunc(cmd10)
; nfili10=dimsizes(fili10)

cmd51="find " + dirs51 + seltime5 
fili51=systemfunc(cmd51)
f51=addfiles(fili51,"r")

cmd52="find " + dirs52 + seltime5 
fili52=systemfunc(cmd52)
f52=addfiles(fili52,"r")

cmd53="find " + dirs53 + seltime5 
fili53=systemfunc(cmd53)
f53=addfiles(fili53,"r")

cmd54="find " + dirs54 + seltime5 
fili54=systemfunc(cmd54)
f54=addfiles(fili54,"r")


; ******************Read in CERES Data***************************************
;Since I am using the whole dataset to do averaging, I don't need to subset the nc file.
;Modify as you need for your specific case

toadata="CERES_SYN1deg-Day_Terra-Aqua-MODIS_Ed4.1_Subset_20200101-20200131.nc"
a = addfile(obsdir+toadata,"r")

; ************************************************
; A do loop to read the vars interested
; ************************************************

 obsnames=(/"cldarea_total_daily","toa_sw_all_daily","toa_lw_all_daily","ini_sfc_sw_up_all_daily","ini_sfc_sw_down_all_daily","ini_sfc_lw_up_all_daily","ini_sfc_lw_down_all_daily"/)
 gfsnames=(/"TCDC_entireatmosphere","USWRF_topofatmosphere","ULWRF_topofatmosphere","USWRF_surface","DSWRF_surface","ULWRF_surface","DLWRF_surface"/)
 
 do i=0,6,1
var=obsnames(i)
print(var)
gfsvar=gfsnames(i)
obsdata1=a->$var$
obsdata=dim_avg_n_Wrap(obsdata1(0:30:5,:,:),0)

gfsdata1=f[:]->$gfsvar$
gfsdata=dim_avg_n_Wrap(gfsdata1,0)


gfsdata511=f51[:]->$gfsvar$
gfsdata51=dim_avg_n_Wrap(gfsdata511,0)

gfsdata521=f52[:]->$gfsvar$
gfsdata52=dim_avg_n_Wrap(gfsdata521,0)

gfsdata531=f53[:]->$gfsvar$
gfsdata53=dim_avg_n_Wrap(gfsdata531,0)

gfsdata541=f54[:]->$gfsvar$
gfsdata54=dim_avg_n_Wrap(gfsdata541,0)

; gfsdata2=f10[:]->$gfsvar$
; gfsdata10=dim_avg_n_Wrap(gfsdata2,0)


;meandata=dim_avg_n_Wrap(gfsdata,0)
zonalmeandata=dim_avg(gfsdata)         ;calculate zonal means for the model outputs from five scenarios
zonalmeandata1=dim_avg(gfsdata51)
zonalmeandata2=dim_avg(gfsdata52)
zonalmeandata3=dim_avg(gfsdata53)
zonalmeandata4=dim_avg(gfsdata54)

;meandata10=dim_avg_n_Wrap(gfsdata10,0) ;place holder for 10 day forecasts
;zonalmeandata10=dim_avg(gfsdata10)
;meanrdata=dim_avg_n_Wrap(obsdata,0)
  
zonalmeanrdata=dim_avg(obsdata)        ;calculate zonal means for CERES data



;************************************************
; create plot
;************************************************

wks = gsn_open_wks("png","Zonal_Mean__"+gfsvar+"_202001.png")  ; Need to change to your desired png name
res                   = True
res@vpXF            = 0.2                          ; make plot bigger
res@vpYF            = 0.9        
res@vpWidthF        = 0.7
res@vpHeightF       = 0.4
res@pmLegendDisplayMode    = "Always"              ; turn on legend
res@pmLegendSide           = "Top"                 ; Change location of 
res@pmLegendParallelPosF   = .84                   ; move units right
res@pmLegendOrthogonalPosF = -0.52                 ; more neg = down 
res@pmLegendWidthF         = 0.12                  ; Change width and
res@pmLegendHeightF        = 0.15                  ; height of legend.
res@lgLabelFontHeightF     = .012                  ; change font height
res@lgPerimOn              = False                 ; no box around
res@xyExplicitLegendLabels = (/"CERES","Exp_4","Exp_3","Exp_2","Exp_1","CCPP-based Control"/) ; change legend names
res@lbLabelFontHeightF  = 0.015                     ; label bar font height
res@tiMainString       = gfsdata@long_name+" at "+gfsdata@level+"~C~ daily mean" 
res@tiMainFontHeightF  = .020    
res@xyDashPatterns=0
res@tmYROn=False
res@tmXTOn=False
res@xyLineThicknesses = (/  4,  4,4, 4, 4,4/)        ; make second line thicker
res@xyLineColors      = (/"black","magenta","orange","blue","green","red"/)                    ; change line color
res1=res
res@tmXTLabelsOn=False
res@tmYRLabelsOn=False

;Construct data array for ploting
totaldata=new((/6,dimsizes(gfsdata1&lat)/),float)
totaldata(0,:)=zonalmeanrdata(:)
totaldata(1,:)=zonalmeandata4(:)
totaldata(2,:)=zonalmeandata3(:)
totaldata(3,:)=zonalmeandata2(:)
totaldata(4,:)=zonalmeandata1(:)
totaldata(5,:)=zonalmeandata(:)


res@tiYAxisString    = gfsdata@short_name+" ("+gfsdata@units+")"    ; y-axis label  
res@tiXAxisString    = "Latitude"                                   ; x-axis label  
res@tiYAxisFontHeightF = 0.02
res@tiXAxisFontHeightF = 0.02
plot=gsn_csm_xy(wks,gfsdata1&lat,totaldata,res)
print(" var: "+gfsvar+" : "+avg(zonalmeanrdata)+" Dy05: "+avg(zonalmeandata))
delete(wks)
end do
end
