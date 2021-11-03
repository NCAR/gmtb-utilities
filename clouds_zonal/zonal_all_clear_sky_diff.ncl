;*************************************************
; zonal_all_clear_sky_diff.ncl
; This script calculates the zonal averages of differences between All-sky and Clear-sky conditions
; from CERES dataset and multiple GFS global run outputs. Modify as needed.
; Xia Sun, xia.sun@noaa.gov, 2020-2021
;*************************************************

; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************************
begin

setvalues NhlGetWorkspaceObjectId()
    "wsMaximumSize" : 300000000
end setvalues  

model="GFS"                      ; experiment name using GFS model  
year="2020"  
month="01"
ldy="05"                         ; leading day 

expname=str_upper(model)+"16rt2" ; need to change to your experiment name

; CERES data directory
obsdir="/dir/to/your/CERES/"     ; need to change to your CERES data dir

;********Read in Model Output from Different Model Scenarios**********
 fName5= "DIRdate_DY05.txt"
 dir="/dir/to/model/run/one"
 dir1="/dir/to/model/run/two"
 dir2="/dir/to/model/run/three"
 dir3="/dir/to/model/run/four"
 dir4="/dir/to/model/run/five"
   
 date5= systemfunc("cut -c1-10 "+ fName5)
 realdate5=systemfunc("cut -c1-8 "+ fName5)
 init5=systemfunc("cut -c9-10 "+ fName5)

 
 ; fName10= "DIRdate_DY10.txt"
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

; cmd10="find " + dirs10 + seltime10   ; Plcaeholder for read in 10 day forecast
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
; Since I am using the whole dataset to do averaging, I don't need to subset the nc file.
; Modify as you need for your specific case

toadata="CERES_SYN1deg-Day_Terra-Aqua-MODIS_Ed4.1_Subset_20200101-20200131.nc"
a = addfile(obsdir+toadata,"r")

;**************************************************************************************************
; A do loop to read the vars interested, under All-Sky and Clear-Sky conditions
;**************************************************************************************************
obsnames=(/"toa_sw_all_daily","toa_lw_all_daily","ini_sfc_sw_up_all_daily","ini_sfc_sw_down_all_daily","ini_sfc_lw_up_all_daily","ini_sfc_lw_down_all_daily"/)
obs_clr_names=(/"toa_sw_clr_daily","toa_lw_clr_daily","ini_sfc_sw_up_clr_daily","ini_sfc_sw_down_clr_daily","ini_sfc_lw_up_clr_daily","ini_sfc_lw_down_clr_daily"/)
gfsnames=(/"USWRF_topofatmosphere","ULWRF_topofatmosphere","USWRF_surface","DSWRF_surface","ULWRF_surface","DLWRF_surface"/)
gfs_clr_names=(/"CSUSF_topofatmosphere","CSULF_topofatmosphere","CSUSF_surface","CSDSF_surface","CSULF_surface","CSDLF_surface"/)

do i=0,5,1
var=obsnames(i)
var_clr=obs_clr_names(i)
print(var)
gfsvar=gfsnames(i)
gfsvar_clr=gfs_clr_names(i)
obsdata1=a->$var$
obsdata=dim_avg_n_Wrap(obsdata1,0)

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


obsdata_clr1=a->$var_clr$
gfsdata_clr1=f[:]->$gfsvar_clr$
gfsdata_clr511=f51[:]->$gfsvar_clr$
gfsdata_clr521=f52[:]->$gfsvar_clr$
gfsdata_clr531=f53[:]->$gfsvar_clr$
gfsdata_clr541=f54[:]->$gfsvar_clr$


obsdata_clr=dim_avg_n_Wrap(obsdata_clr1,0)
gfsdata_clr=dim_avg_n_Wrap(gfsdata_clr1,0)
gfsdata_clr_51=dim_avg_n_Wrap(gfsdata_clr511,0)
gfsdata_clr_52=dim_avg_n_Wrap(gfsdata_clr521,0)
gfsdata_clr_53=dim_avg_n_Wrap(gfsdata_clr531,0)
gfsdata_clr_54=dim_avg_n_Wrap(gfsdata_clr541,0)


diff_obs=obsdata - obsdata_clr
diff_gfs=gfsdata - gfsdata_clr
diff_gfs1=gfsdata51 - gfsdata_clr_51
diff_gfs2=gfsdata52 - gfsdata_clr_52
diff_gfs3=gfsdata53 - gfsdata_clr_53
diff_gfs4=gfsdata54 - gfsdata_clr_54


zonalmeandata=dim_avg(diff_gfs)
zonalmeandata1=dim_avg(diff_gfs1)
zonalmeandata2=dim_avg(diff_gfs2)
zonalmeandata3=dim_avg(diff_gfs3)
zonalmeandata4=dim_avg(diff_gfs4)
zonalmeanrdata=dim_avg(diff_obs)




;************************************************
; create plot
;************************************************
wks = gsn_open_wks("png","Zonal_Mean_Diff_clearday_"+gfsvar+"_202001.png")  

  
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

res@xyExplicitLegendLabels = (/"CERES","Exp_4","Exp_3","Exp_2","Exp_1","CCPP-based Control"/) ;change legend names

res@lbLabelFontHeightF  = 0.015                    ; label bar font height
res@tiMainString       = "(All-Clr)"+gfsdata@long_name+" at "+gfsdata@level+"~C~ daily mean" 
res@tiMainFontHeightF  = .020    
res@xyDashPatterns=0
res@tmYROn=False
res@tmXTOn=False
res@xyLineThicknesses = (/  4,   4, 4,4,4,4/)       ; make second line thicker
res@xyLineColors      = (/"black","magenta","orange","blue","green","red"/)                    ; change line colors
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
