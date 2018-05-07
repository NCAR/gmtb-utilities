;==========================
; apcp_hov.ncl
;==========================
begin

;diri  = ""+in_dir+""
f = addfile(""+in_file+"","r")

apcp = f->$precip_var$(:,:,:)
time=f->time

lat1d=f->lat
lon1d=f->lon

apcp@lat=lat1d
apcp@lon=lon1d

; Set latitude band to average over. Currently set to 5N - 15N.
apcp_subset=apcp(:,{5:15},:)

apcpAvgLat = dim_avg_n(apcp_subset,1)

; Assign dimension names
apcpAvgLat!0="time"
apcpAvgLat!1="lon"

; Define coordinate variables
apcpAvgLat&lon=lon1d

; Assign attributes
apcpAvgLat@lon=lon1d

itime   = doubletointeger(time)
date_str = sprinti("%0.10i", itime)

;==============================================
; create color plot
;=============================================
wks  = gsn_open_wks ("png", ""+out_dir+""+out_file+"" )           ; send graphics to PNG file

res                      = True               ; plot mods desired
res@cnFillOn             = True               ; turn on color fill
res@cnFillPalette        = "WhiteBlueGreenYellowRed"           ; set color map

res@tiMainString         = "Average (5N-15N) "+precip_var+" (mm) valid at 00 UTC"  ; title

;res@cnFillMode           = "RasterFill"
res@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
res@cnMinLevelValF       = 0.	        ; min level
res@cnMaxLevelValF       = 40.               ; max level
res@cnLevelSpacingF      = 2.0                 ; contour level spacing
res@cnLinesOn            = False

res@tmYLMode             = "Explicit"                ; Define own tick mark labels.
res@tmYLValues           = ispan(0,9,1) 
res@tmYLLabels           = date_str 
res@tmYLLabelFontHeightF = 0.012
res@tmXBLabelFontHeightF = 0.012

res@lbTitleOn            = True
res@lbTitleString        = "Precip (mm)"
res@lbLabelFontHeightF   = 0.012 
res@lbTitlePosition      = "Bottom"
res@lbTitleFontHeightF   = 0.015
res@lbTitleOffsetF       = -0.2
res@lbTitleExtentF       = 0.45

res@trYReverse           = True                ; reverse y axis
 
plot = gsn_csm_hov(wks, apcpAvgLat(:,:), res) 
  
end
