;*************************************************
; diff_CERES.ncl
;************************************************
;
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************************
begin
;************************************************
; read in netCDF file
;************************************************
   
   model="gf"   ; experiment name using GFS model  
   year="2016"  
   month="07"
   grid="GCR"   ; plot on CERES-EBAF 1 degree map
   ldy="03"   ; leading day (01,03,05,07,09,11)

; plot variables
   ;VarGFS = "DSWRF_surface"        ;SFC Downward shortwave radiation flux
   ;VarGFS = "DLWRF_surface"       ;SFC Downward longwave radiation flux
   VarGFS = "USWRF_surface"       ;SFC Upward shortwave radiation flux
   ;VarGFS = "ULWRF_surface"       ;SFC Upward longwave radiation flux

   expname=str_upper(model)+"CTRL"

; CERES-EBAF data directory
  obsdir="/scratch4/BMC/gmtb/CERES_EBAF_Edition4.0/"

; CERES_EBAF-TOA_Edition4.0_200003-201709
;  2016 July: 196
;  2016 Jun: 195
   mon=196   
;**************************************************
; DY01: Jul1-Jul31  fcst=(/006,012,018,024/)
; DY03: Jun29-Jul29  fcst=(/054,060,066,072/)
; DY05: Jun27-Jul27  fcst=(/102,108,144,120/)
; DY07: Jun25-Jul25   fcst=(/150,156,162,168/)

 if (ldy .eq. "01") then
     seltime = " -type f \( -name pgrbq006*GCR.nc -o -name pgrbq012*GCR.nc -o -name pgrbq018*GCR.nc -o -name pgrbq024*GCR.nc  \)  "
 else if (ldy .eq. "03") then
     seltime = " -type f \( -name pgrbq054*GCR.nc -o -name pgrbq060*GCR.nc -o -name pgrbq066*GCR.nc -o -name pgrbq072*GCR.nc  \)  "  
 else if (ldy .eq. "05") then
     seltime = " -type f \( -name pgrbq102*GCR.nc -o -name pgrbq108*GCR.nc -o -name pgrbq114*GCR.nc -o -name pgrbq120*GCR.nc  \)  "
 else if (ldy .eq. "07") then
     seltime = " -type f \( -name pgrbq150*GCR.nc -o -name pgrbq156*GCR.nc -o -name pgrbq162*GCR.nc -o -name pgrbq168*GCR.nc  \)  "
 else if (ldy .eq. "09") then
     seltime = " -type f \( -name pgrbq198*GCR.nc -o -name pgrbq204*GCR.nc -o -name pgrbq210*GCR.nc -o -name pgrbq216*GCR.nc  \)  "
 else if (ldy .eq. "11") then
     seltime = " -type f \( -name pgrbq246*GCR.nc -o -name pgrbq252*GCR.nc -o -name pgrbq258*GCR.nc -o -name pgrbq264*GCR.nc  \)  "
 else
     print ("not an valid leading date, exit")
     exit()
 end if 
 end if
 end if 
 end if 
 end if
 end if 
;*************************************************
 fName= "DIRdate_DY"+ldy+".txt"
 dir="/scratch4/BMC/gmtb/Man.Zhang/_CERES/gmtb-tierIII-master/vx_out/"+model
 date= systemfunc("cut -c1-10 "+ fName)
 ;print(date)
 
 cmd= "find "+ dir+"/"+date(0)+"/ "                 \
             + dir+"/"+date(1)+"/ "                 \
             + dir+"/"+date(2)+"/ "                 \
             + dir+"/"+date(3)+"/ "                 \
             + dir+"/"+date(4)+"/ "                 \
             + dir+"/"+date(5)+"/ "                 \
             + dir+"/"+date(6)+"/ "                 \
             + dir+"/"+date(7)+"/ "                 \
             + dir+"/"+date(8)+"/ "                 \
             + dir+"/"+date(9)+"/ "                 \
             + dir+"/"+date(10)+"/ "                \
             + dir+"/"+date(11)+"/ "                \
             + dir+"/"+date(12)+"/ "                \
             + dir+"/"+date(13)+"/ "                \
             + dir+"/"+date(14)+"/ "                \
             + dir+"/"+date(15)+"/ "                \
             + dir+"/"+date(16)+"/ "                \
             + dir+"/"+date(17)+"/ "                \
             + dir+"/"+date(18)+"/ "                \
             + dir+"/"+date(19)+"/ "                \
             + dir+"/"+date(20)+"/ "                \
             + dir+"/"+date(21)+"/ "                \
             + dir+"/"+date(22)+"/ "                \
             + dir+"/"+date(23)+"/ "                \
             + dir+"/"+date(24)+"/ "                \
             + dir+"/"+date(25)+"/ "                \
             + dir+"/"+date(26)+"/ "                \
             + dir+"/"+date(27)+"/ "                \
             + dir+"/"+date(28)+"/ "                \
             + dir+"/"+date(29)+"/ "                \
             + dir+"/"+date(30)+"/ "                \
             + seltime

   fili= systemfunc(cmd)
   nfili=dimsizes(fili)
   print(fili)
   print(ldy)
   print("nfili = "+nfili)

   f    = addfiles(fili,"r") 
   ListSetType(f,"join")

  if (VarGFS .eq. "DSWRF_surface") then
     data = f[:]->DSWRF_surface
  else if (VarGFS .eq. "DLWRF_surface") then
     data = f[:]->DLWRF_surface
  else if (VarGFS .eq. "USWRF_surface") then
     data = f[:]->USWRF_surface
  else if (VarGFS .eq. "ULWRF_surface") then
     data = f[:]->ULWRF_surface
  else
     print ("not an valid Rad variable in GFS, exit")
     exit()
  end if
  end if
  end if
  end if


   printVarSummary(data)
;   printMinMax(data,0)


;*********************************************************
  toadata="CERES_EBAF-Surface_Edition4.0_200003-201706.nc"
  a = addfile(obsdir+toadata,"r")
  if (VarGFS .eq. "DSWRF_surface") then
     rdata=a->sfc_sw_down_all_mon(mon,:,:)        ; surface_downwelling_shortwave_flux_in_air
  else if (VarGFS .eq. "DLWRF_surface") then
     rdata = a->sfc_lw_down_all_mon(mon,:,:)      ; surface_downwelling_longwave_flux_in_air
  else if (VarGFS .eq. "USWRF_surface") then
     rdata = a->sfc_sw_up_all_mon(mon,:,:)        ; surface_upwelling_shortwave_flux_in_air
  else if (VarGFS .eq. "ULWRF_surface") then
     rdata = a->sfc_lw_up_all_mon(mon,:,:)        ; surface_upwelling_longwave_flux_in_air
  else
     print ("not an valid Rad variable in CERES, exit")
     exit()
  end if
  end if
  end if
  end if

  printVarSummary(rdata)
  ;printMinMax(rdata,0)

;************************************************
; create plot
;************************************************
  wks = gsn_open_wks("x11","proj")          ; send graphics to PNG, X11 file


  res                   = True
;  res@mpProjection      = "Mollweide"       ; choose projection
  res@mpGridAndLimbOn   = False              ; turn on lat/lon lines
  res@mpPerimOn         = False             ; turn off box around plot
  res@mpGridLatSpacingF = 30.               ; spacing for lat lines
  res@mpGridLonSpacingF = 30.               ; spacing for lon lines
  res@mpFillOn          = False
  res@mpCenterLonF      = 180
  res@mpGeophysicalLineThicknessF =2
 
  res@cnFillOn          = True              ; color plot desired
  ;res@cnFillPalette     = "WhiteBlueGreenYellowRed"     ; set color map
  ;res@cnFillPalette     = "NCV_bright"     ; set color map
  ;res@cnFillMode     ="RasterFill"
  res@cnLineLabelsOn    = False             ; turn off contour lines
  res@cnLinesOn         = False          
  res@txFontHeightF     = 0.015 

  res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
  res@cnMinLevelValF  = -50.			; set the minimum contour level
  res@cnMaxLevelValF  = 50.			; set the maximum contour level
  res@cnLevelSpacingF = 10.			; set the interval between contours

  res@vpXF            = 0.1                 ; make plot bigger
  res@vpYF            = 0.9         
  res@vpWidthF        = 0.8
  res@vpHeightF       = 0.8

  res@gsnZonalMean    = True                    ; put zonal on side
  res@gsnZonalMeanXMinF = -50.                   ; set minimum X-axis value for zonal mean plot
  res@gsnZonalMeanXMaxF = 50.                 ; set maximum X-axis value for zonal mean plot
  res@gsnZonalMeanYRefLine = 0          ; set reference line X-axis value

  month_mean=dim_avg_n_Wrap(dim_avg_n_Wrap(data,0),0)
  crclim=dim_avg_n_Wrap(dim_avg_n_Wrap(rdata,0),0)
  diff_rad= rdata   ;propagate the attributes to the result 
  diff_rad=(month_mean-rdata)/crclim*100

  diff_rad@units="%"
  diff_rad&lat@units="degrees_north"
  diff_rad&lon@units="degrees_east"
 ; printVarSummary(diff_rad)


  res@lbLabelFontHeightF  = 0.015           ; label bar font height
  res@tiMainString       = "("+expname+"-"+"CERES)/CERES  DY"+ ldy +" 2016-"+month 
  res@tiMainFontHeightF  = .018                               ; font height

  contour = gsn_csm_contour_map(wks,diff_rad,res)  ; create the plot
end
